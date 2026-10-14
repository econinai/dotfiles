#!/usr/bin/env python3
"""Installs packages and hands the pre_install commands back to the shell.

Usage:
  pkg_install.py --log LOGFILE PACKAGE [PACKAGE ...]
  pkg_install.py --log LOGFILE -f packages.json

Package list mode:
  Installs exactly the given packages. An argument may itself be a
  space-separated list ("bat fish zen"). Nothing is printed to stdout.

JSON mode (-f):
  Installs all packages from the file that are not disabled
  ("enabled": false), finds out which of them are installed afterwards and
  prints their "pre_install" commands to stdout, one per line, so the caller
  can run them in its own shell:

      cmds=$(python3 pkg_install.py --log LOG -f packages.json); rc=$?
      eval "$cmds"

Packages are installed via pacman, then AUR (yay), then flatpak.
stdout carries nothing but shell commands, so it is always safe to eval.
Progress and messages go to stderr, the output of the tools to LOGFILE.

Exit codes: 0 ok; 1 some package failed or was not found, or bad input;
2 the package manager of this system is not supported (nothing installed).
"""
import argparse
import glob
import json
import os
import re
import shutil
import socket
import subprocess
import sys
import time
from pathlib import Path

# English, stable output from the tools we call
ENV = dict(os.environ, LC_ALL="C")

# Package managers we look for, in this order, and the ones we can actually use
MANAGERS = ["pacman", "apt", "dnf", "zypper", "apk"]
SUPPORTED = {"pacman"}


def fail(message):
    print(f"pkg_install.py: {message}", file=sys.stderr)
    sys.exit(1)


def say(message, log=None):
    """Print a progress message to stderr and, if given, to the log."""
    print(message, file=sys.stderr)
    if log is not None:
        log.write(message + "\n")
        log.flush()


# ----------------------------------------------------------------------------
# packages.json
# ----------------------------------------------------------------------------
def load(path):
    """Reads and validates the file. Returns {name: options}."""
    try:
        text = Path(path).read_text(encoding="utf-8")
    except OSError as e:
        fail(f"cannot read {path}: {e}")

    # Allow trailing commas before ] and }.
    # The replacement keeps whitespace and newlines, so error line numbers stay correct.
    text = re.sub(r",(\s*[}\]])", r"\1", text)

    try:
        data = json.loads(text)
    except json.JSONDecodeError as e:
        fail(f"{path}: invalid JSON at line {e.lineno}, column {e.colno}: {e.msg}")

    if not isinstance(data, dict):
        fail(f"{path}: top level must be an object {{name: {{...}}}}")

    packages = {}
    for name, opts in data.items():
        if opts is None:
            opts = {}
        if not isinstance(opts, dict):
            fail(f"{path}: value of package '{name}' must be an object {{...}}")
        if "enabled" in opts and not isinstance(opts["enabled"], bool):
            fail(f"{path}: 'enabled' of package '{name}' must be true or false")

        commands = opts.get("pre_install", [])
        if isinstance(commands, str):
            commands = [commands]
        if not isinstance(commands, list) or not all(isinstance(c, str) for c in commands):
            fail(f"{path}: 'pre_install' of package '{name}' must be a list of strings")
        opts["pre_install"] = [c.strip() for c in commands if c.strip()]

        packages[name] = opts
    return packages


def enabled_packages(packages):
    # a package is enabled by default; only an explicit "enabled": false disables it
    return {n: o for n, o in packages.items() if o.get("enabled", True)}


def pre_install_commands(packages, installed):
    """pre_install commands of enabled, installed packages, in file order."""
    installed = set(installed)
    commands = []
    for name, opts in enabled_packages(packages).items():
        if name in installed:
            commands.extend(opts["pre_install"])
    return commands


# ----------------------------------------------------------------------------
# helpers for running tools
# ----------------------------------------------------------------------------
def detect_manager():
    for name in MANAGERS:
        if shutil.which(name):
            return name
    return None


def succeeds(cmd):
    """True if the command exits with code 0 (its output is discarded)."""
    try:
        return subprocess.call(cmd, stdout=subprocess.DEVNULL,
                               stderr=subprocess.DEVNULL, env=ENV) == 0
    except OSError:
        return False


def run(cmd, log):
    """Run a command, append its output to the log, return the exit code."""
    log.write("$ " + " ".join(cmd) + "\n")
    log.flush()
    try:
        return subprocess.call(cmd, stdout=log, stderr=subprocess.STDOUT, env=ENV)
    except OSError as e:
        log.write(f"{e}\n")
        return 127


def has_network():
    try:
        socket.create_connection(("archlinux.org", 443), timeout=5).close()
        return True
    except OSError:
        return False


def retry(action, log, attempts=3, delay=5):
    for attempt in range(1, attempts + 1):
        if action():
            return True
        if attempt < attempts:
            say(f"  attempt {attempt}/{attempts} failed, retrying in {delay}s...", log)
            time.sleep(delay)
    return False


def install_batch(base_cmd, names, log):
    """Install all names with one command; if that fails, try one by one."""
    if not names:
        return
    if retry(lambda: run(base_cmd + names, log) == 0, log):
        return
    say("  batch install failed, trying packages one by one", log)
    for name in names:
        run(base_cmd + [name], log)


def flatpak_lines(*args):
    try:
        out = subprocess.check_output(["flatpak"] + list(args),
                                      stderr=subprocess.DEVNULL, env=ENV)
    except (OSError, subprocess.CalledProcessError):
        return []
    return out.decode("utf-8", "replace").split()


def find_flatpak(name, app_ids):
    """Match a package name to a flatpak app id.

    Preference: the full id, then the last part of the id (zen ->
    app.zen_browser.zen), then any part of the id (telegram ->
    org.telegram.desktop).
    """
    wanted = name.lower()
    lowered = [(app_id, app_id.lower()) for app_id in app_ids]
    for app_id, low in lowered:
        if low == wanted:
            return app_id
    for app_id, low in lowered:
        if low.rsplit(".", 1)[-1] == wanted:
            return app_id
    for app_id, low in lowered:
        if wanted in low.split("."):
            return app_id
    return None


# ----------------------------------------------------------------------------
# installation
# ----------------------------------------------------------------------------
def install_all(names, online, log):
    """Returns (installed names in input order, failed names, not found names)."""
    installed, failed, notfound = set(), [], []

    # 1. what is already installed via pacman/yay (works offline)
    todo = []
    for name in names:
        if succeeds(["pacman", "-Qq", name]):
            installed.add(name)
        else:
            todo.append(name)

    if online and todo and not glob.glob("/var/lib/pacman/sync/*.db"):
        say("== syncing pacman databases (none found)", log)
        run(["sudo", "pacman", "-Sy"], log)

    # 2. where can the rest be found: pacman repos, then AUR
    repo = [n for n in todo if succeeds(["pacman", "-Si", n])]
    rest = [n for n in todo if n not in repo]
    aur = []
    if online and shutil.which("yay"):
        aur = [n for n in rest if succeeds(["yay", "-Si", n])]
        rest = [n for n in rest if n not in aur]

    # 3. install and verify
    if online:
        if repo:
            say("== pacman: " + " ".join(repo), log)
            install_batch(["sudo", "pacman", "-S", "--needed", "--noconfirm"], repo, log)
        if aur:
            say("== AUR: " + " ".join(aur), log)
            install_batch(["yay", "-S", "--needed", "--noconfirm"], aur, log)
    for name in repo + aur:
        if succeeds(["pacman", "-Qq", name]):
            installed.add(name)
        else:
            failed.append(name)

    # 4. flatpak for everything that pacman and AUR do not have
    local_ids, remote_ids = [], []
    if rest and shutil.which("flatpak"):
        local_ids = flatpak_lines("list", "--app", "--columns=application")
        if online:
            remote_ids = flatpak_lines("remote-ls", "flathub", "--app",
                                       "--columns=application")
    for name in rest:
        if find_flatpak(name, local_ids):
            installed.add(name)
            continue
        if not online:
            failed.append(name)          # cannot know or install while offline
            continue
        app_id = find_flatpak(name, remote_ids)
        if not app_id:
            notfound.append(name)
            continue
        say("== flatpak: " + app_id, log)
        cmd = ["flatpak", "install", "flathub", "-y", "--or-update", app_id]
        retry(lambda: run(cmd, log) == 0, log)
        if succeeds(["flatpak", "info", app_id]):
            installed.add(name)
        else:
            failed.append(name)

    return [n for n in names if n in installed], failed, notfound


# ----------------------------------------------------------------------------
# main
# ----------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("packages", nargs="*",
                        help="packages to install; a single argument may be a "
                             "space-separated list")
    parser.add_argument("-f", "--file", help="packages.json to install from")
    parser.add_argument("--log", required=True, help="log file (appended)")
    args = parser.parse_args()

    # --- decide what to install
    packages = None                       # parsed JSON, only in -f mode
    if args.packages and args.file:
        fail("give either package names or -f, not both")
    if args.packages:
        names = list(dict.fromkeys(n for item in args.packages for n in item.split()))
    elif args.file:
        packages = load(args.file)
        names = list(enabled_packages(packages))
    else:
        fail("nothing to install: give package names or -f packages.json")

    for name in names:
        if name.startswith("-"):
            fail(f"invalid package name: {name!r}")
    if not names:
        return                            # empty list: nothing to do, not an error

    manager = detect_manager()
    if manager not in SUPPORTED:
        print(f"pkg_install.py: package manager '{manager or 'none found'}' is not "
              f"supported, nothing installed", file=sys.stderr)
        sys.exit(2)

    # --- install
    online = has_network()
    try:
        log = open(args.log, "a", encoding="utf-8")
    except OSError as e:
        fail(f"cannot open log file {args.log}: {e}")

    with log:
        if online:
            say("== installing packages", log)
        else:
            say("== NO NETWORK: skipping installation, only checking what is installed", log)
        installed, failed, notfound = install_all(names, online, log)
        say(f"== {len(installed)} of {len(names)} packages installed", log)
        if failed:
            say("FAILED to install: " + " ".join(failed), log)
        if notfound:
            say("NOT FOUND anywhere: " + " ".join(notfound), log)

    # --- hand the pre_install commands back to the shell (stdout only)
    if packages is not None:
        for command in pre_install_commands(packages, installed):
            print(command)

    if failed or notfound:
        sys.exit(1)


if __name__ == "__main__":
    main()
