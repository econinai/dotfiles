if status is-interactive
    # Commands to run in interactive sessions can go here
end

alias ls='eza -a --icons=always'
alias ll='eza -al --icons=always'
alias grep='grep --color=auto'
alias cat='bat'

set -gx SUDO_PROMPT "Password for %u user: "

set -g __fish_git_prompt_showdirtystate 1
set -g __fish_git_prompt_showuntrackedfiles 1
set -g __fish_git_prompt_showstashstate 1
set -g __fish_git_prompt_showupstream "auto"
set -g __fish_git_prompt_color_branch red
set -g fish_greeting ""

function fish_prompt
    set -l USERSIGNGLYPH " "
    set_color green
    set -l HOSTSIGNGLYPH "󰍹 "
    if test (id -u) -eq 0
        set_color red
        set USERSIGNGLYPH " "
    end
    if test -f /sys/class/dmi/id/chassis_type
        set -l chassis (cat /sys/class/dmi/id/chassis_type 2>/dev/null)
        if test "$chassis" = "9" -o "$chassis" = "10" -o "$chassis" = "14"
            set HOSTSIGNGLYPH " "
        end
    end
    if set -q SSH_CONNECTION; or set -q SSH_CLIENT; or set -q SSH_TTY; or string match -r '/dev/tty[0-9]+$' (tty) >/dev/null
        echo -n "$USERSIGNGLYPH$USER "
        set_color brblack
        echo -n "$HOSTSIGNGLYPH"(hostnamectl hostname)" "
    else
        echo -n "$USERSIGNGLYPH"
    end

    set_color blue        
    set -g fish_prompt_pwd_dir_length 0
    echo -n " "(prompt_pwd)

    set_color red
    if fish_git_prompt >/dev/null
        echo -n " 󰊢 "(fish_git_prompt | string trim -c '() ')
    end
    set_color normal
    echo -n "  "
end
