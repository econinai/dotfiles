------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "",
    mode     = "highres highrr",
    position = "auto",
    scale    = "1",
})

---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "ghostty"
local fileManager = "dolphin"
local launcher    = "noctalia msg panel-toggle launcher"
local texteditor  = "gtk-launch org.xfce.mousepad.desktop"
local exitHyprland = "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"
local openBuffer = "noctalia msg panel-toggle clipboard"
local toolkit = "noctalia msg panel-toggle alexander/screen-toolkit:panel"
local windowswitche = "noctalia msg window-switcher"
local mainMenu  = "noctalia msg panel-toggle control-center"
local switchLocal = "cur=$(hyprctl devices -j | jq '[.keyboards[] | select(.main == true)][0].active_layout_index'); hyprctl switchxkblayout all $((1 - cur))"
local mediaPrev = "noctalia msg media previous"
local mediaNext = "noctalia msg media next"
local mediaToggle = "noctalia msg media playPause"
local mediaPlay = "noctalia msg media play"
local mediaPause = "noctalia msg media pause"
local taskmng = "missioncenter"
local help = "noctalia msg panel-toggle blackbartblues/keymap:panel"
local screenshot = [=[file="/home/$USER/Pictures/Screenshots/screenshot_$(date +%s).png"; grimblast --freeze copysave area "$file"; if [[ -f "$file" ]]; then wl-copy --type image/png < "$file"; notify-send --app-name="System" "Screenshot" "Image has been saved and copied to the clipboard" -i "$file"; fi]=]

local showInfo = [=[notify-send -t 8000 -a System "System info" "$(printf '%s\n' "CPU: $(cut -d' ' -f1-3 /proc/loadavg)" "RAM: $(free -h | awk '/^Mem:/{print $3"/"$2}')" "Temp: $(sort -n /sys/class/thermal/thermal_zone*/temp | tail -1 | awk '{print $1/1000}')°C" "Bat: $(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)%" "Up: $(uptime -p | sed 's/^up //')")"]=]

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function ()
  hl.exec_cmd("hyprpm reload")
  hl.exec_cmd("pkill -9 wl-paste; wl-paste --watch cliphist store &")
  hl.exec_cmd("noctalia")
  hl.exec_cmd("easyeffects --hide-window")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("GDK_DPI_SCALE", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_MENU_PREFIX", "arch- kbuildsycoca6")
hl.env("XDG_TERMINAL_SERVICE", "kitty.desktop")
hl.env("SHELL", "/usr/bin/fish")
hl.env("GDK_WAYLAND_DISABLE", "ext_background_effect_manager_v1")

--------------------------
---- APPERANCE SCRIPT ----
--------------------------

-- For Noctalia Color templates
require("noctalia").apply_theme()

local apperance_mode = "flat"
local file = io.open(os.getenv("HOME") .. "/.cache/sys_appearance", "r")
if file then
    apperance_mode = file:read("*all"):gsub("%s+", "")
    file:close()
end

local function bar_opacity(v)
    local t = [=[sed -i '/^[[:space:]]*\[bar\.%s\]/,/[[:space:]]*background_opacity/s/\(background_opacity[[:space:]]*=[[:space:]]*\)[0-9.]\+/\1%s/' ~/.config/noctalia/settings.toml]=]
    return t:format("default", v) .. "\n" .. t:format("bottom", v)
end

local function panel_shadow(b)
    return ([=[sed -i '/^[[:space:]]*\[shell\.panel\]/,/[[:space:]]*shadow/s/\(shadow[[:space:]]*=[[:space:]]*\)\(true\|false\)/\1%s/' ~/.config/noctalia/settings.toml]=]):format(tostring(b))
end

local function shell_animation(b)
    return ([=[sed -i '/^[[:space:]]*\[shell\.animation\]/,/[[:space:]]*enabled/s/\(enabled[[:space:]]*=[[:space:]]*\)\(true\|false\)/\1%s/' ~/.config/noctalia/settings.toml]=]):format(tostring(b))
end

local function kvantum_opacity(v)
    return ([=[perl -0777 -pi -e 's/(<rect[^>]*?id="window-normal"[^>]*?style="[^"]*?opacity:)[0-9.]*/${1}%s/s' ~/.config/noctalia/templates/kvantum/noctalia.svg]=]):format(v)
end

local function gtk_alpha(v)
    local win = [=[sed -i -E 's/(@define-color window_bg_color \{\{colors\.surface\.default\.rgba \| set_alpha )[0-9.]+(\}\};)/\1%s\2/g' ~/.config/noctalia/templates/gtk/%s]=]
    local var = [=[sed -i -E 's/(--window-bg-color: \{\{colors\.surface\.default\.rgba \| set_alpha )[0-9.]+(\}\};)/\1%s\2/g' ~/.config/noctalia/templates/gtk/gtk4.css]=]
    return win:format(v, "gtk4.css") .. "\n" .. win:format(v, "gtk3.css") .. "\n" .. var:format(v)
end

local function ghostty(opacity, anims)
    local f = "~/.config/ghostty/config.ghostty"
    local a = tostring(anims)
    return table.concat({
        ("sed -i 's/^background-opacity =.*/background-opacity = %s/' %s"):format(opacity, f),
        ("sed -i 's/^custom-shader-animation =.*/custom-shader-animation = %s/' %s"):format(a, f),
        ("sed -i 's/^cursor-style-blink =.*/cursor-style-blink = %s/' %s"):format(a, f),
        anims and ("sed -i 's/^#custom-shader = /custom-shader = /' " .. f)
               or ("sed -i 's/^custom-shader = /#custom-shader = /' " .. f),
    }, "\n")
end

local function zed_transparent(on)
    local off = [=[sed -i -E '/"theme": *\{/,/\}/{/"(light|dark)":/s/ Transparent"/"/}' "$HOME/.config/zed/settings.json"]=]
    local add = [=[sed -i -E '/"theme": *\{/,/\}/{/"(light|dark)":/{s/ Transparent"/"/;s/("(light|dark)": *"[^"]*)"/\1 Transparent"/}}' "$HOME/.config/zed/settings.json"]=]
    return on and add or off
end

local ZEN_PROFILES = [=[awk '/^\[Install/ {in_section=1; next} /^\[/ {in_section=0} in_section && /^Default=/ {sub(/^Default=/, ""); print}' "$HOME/.var/app/app.zen_browser.zen/.zen/profiles.ini" | while read -r val; do]=]

local function zen_chrome(enabled)
    if not enabled then
        return ZEN_PROFILES .. [=[

  dir="$HOME/.var/app/app.zen_browser.zen/.zen/$val/chrome"
  rm -f "$dir/userChrome.css" "$dir/userContent.css"
done]=]
    end
    return ZEN_PROFILES .. [=[

  dir="$HOME/.var/app/app.zen_browser.zen/.zen/$val/chrome"
  mkdir -p "$dir"
  printf '@import "%s/.cache/noctalia/zen-browser/zen-userChrome.css";\n' "$HOME" > "$dir/userChrome.css"
  printf '@import "%s/.cache/noctalia/zen-browser/zen-userContent.css";\n' "$HOME" > "$dir/userContent.css"
  flatpak override --user --filesystem="$HOME/.cache/noctalia/zen-browser/zen-userContent.css" app.zen_browser.zen
  flatpak override --user --filesystem="$HOME/.cache/noctalia/zen-browser/zen-userChrome.css" app.zen_browser.zen
done]=]
end

local function apply_appearance(c)
    hl.exec_cmd(table.concat({
        bar_opacity(c.bar),
        panel_shadow(c.shadow),
        shell_animation(c.anims),
        kvantum_opacity(c.kvantum),
        ghostty(c.ghostty, c.anims),
        zed_transparent(c.zed),
        "gsettings set org.gnome.desktop.interface enable-animations " .. tostring(c.anims),
        gtk_alpha(c.gtk),
        zen_chrome(c.zen),
    }, "\n"))
end

local hyprglassenabled = false
local blurenabled = false
local transparentenabled = false
local isneedborder = true
local inactive_opacityvalue = 1.0
local active_bordervalue = {"rgba(eeeeeec0)", "rgba(eeeeee00)", "rgba(eeeeee00)", "rgba(eeeeee60)"}
local inactive_bordervalue = {"rgba(909090c0)", "rgba(90909000)", "rgba(90909000)", "rgba(90909060)"}
local anglevalue = 55
local animationsenabled = true
local dyncursorenabled = true

if apperance_mode == "blur" then
    hyprglassenabled = false
    blurenabled = true
    transparentenabled = true
    inactive_opacityvalue = 0.8
    apply_appearance({ bar = "0.5", shadow = false, anims = true,  kvantum = "0.5",
                       ghostty = "0.5", zed = true,  gtk = "0.5", zen = false })

elseif apperance_mode == "liquid" then
    hyprglassenabled = true
    blurenabled = false
    transparentenabled = true
    inactive_opacityvalue = 0.8
    isneedborder = false
    apply_appearance({ bar = "1.0", shadow = true,  anims = true,  kvantum = "0.5",
                       ghostty = "0.5", zed = true,  gtk = "0.5", zen = false })

elseif apperance_mode == "flat-noanims" then
    isneedborder = false
    animationsenabled = false
    dyncursorenabled = false
    apply_appearance({ bar = "1.0", shadow = true,  anims = false, kvantum = "1.0",
                       ghostty = "1.0", zed = false, gtk = "1.0", zen = true })

else
    isneedborder = false
    apply_appearance({ bar = "1.0", shadow = true,  anims = true,  kvantum = "1.0",
                       ghostty = "1.0", zed = false, gtk = "1.0", zen = true })
end
--transparentenabled = false

-----------------
---- PLUGINS ----
-----------------

if hl.plugin.dynamic_cursors then
	hl.config { plugin = { dynamic_cursors = {
	    enabled = dyncursorenabled,
	    mode = "tilt",
	    threshold = 2,
	    rotate = {
	        length = 20,
	        offset = 0.0,
	    },
	    tilt = {
	        limit = 3000,
	        activation = "negative_quadratic",
	        window = 150,
	    },
	    shake = {
	            enabled = false,
	    },
	    hyprcursor = {
	        nearest = true,
	        enabled = true,
	        resolution = -1,
	        fallback = "clientside",
	    },
	}}}
end

hl.config({
  plugin = {
    overview = {
      autoScroll = false,
      panelHeight = 250,
      panelBorderWidth = 2,
      drawActiveWorkspace = true,
      autoDrag = true,
      exitOnClick = true,
      showSpecialWorkspace = false,
      disableGestures = true,
    },
  },
})

if hl.plugin.hyprglass then
    local hg = hl.plugin.hyprglass

    hg.config({
        enabled = hyprglassenabled,
        manage_window_blur = false,
        skip_opaque_windows = false,
        blur_fold = false,
        xray = 0,
        
        default_theme = "dark",

        brightness = 1.0,
        blur_strength = 2.0,
        blur_iterations = 3,
        chromatic_aberration = 0.1,
        fresnel_strength = 0.3,
        specular_strength = 0.5,
        glass_opacity = 1.0,
        tint_color = 0x00000000,
        contrast = 1.0,
        saturation = 1.0,

        refraction_strength = 10.0,
        lens_distortion = 5.0,
        edge_thickness = 0.05,
    })  
end

-----------------------
---- LOOK AND FEEL ----
-----------------------

if transparentenabled then
    local classes = {"dev.vencord.Vesktop", "org.telegram.desktop", "codium", "steam", "app.zen_browser.zen", "anytype"}

    for index, value in ipairs(classes) do
        hl.window_rule({ match = { class = value }, opacity = "1.0 override 0.5 override" })
    end
end
hl.window_rule({ match = { class = "org.telegram.desktop" }, suppress_event = "activatefocus" })
hl.window_rule({ match = { class = "dev.vencord.Vesktop" }, suppress_event = "activatefocus" })
hl.window_rule({ match = { class = "steam" }, suppress_event = "activatefocus" })
hl.layer_rule({ match = { namespace = "selection" }, blur = false })
hl.layer_rule({ match = { namespace = "noctalia-bar-default" }, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "noctalia-bar-default" }, blur = true })
hl.layer_rule({ match = { namespace = "noctalia-attached-panel" }, blur = true })
hl.layer_rule({ match = { namespace = "noctalia-attached-panel" }, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "wvkbd" }, blur = true })
hl.layer_rule({ match = { namespace = "wvkbd" }, ignore_alpha = 0 })

local function set_natural_scroll(enabled)
    hl.config({ input = { touchpad = { natural_scroll = enabled } } })
end

hl.on("window.active", function(win)
    local class = win and win.class and win.class:lower() or ""
    set_natural_scroll(class ~= "blender")
end)

if isneedborder then
	hl.config({
		general = {
			col = {
            	active_border   = { colors = active_bordervalue, angle = anglevalue },
            	inactive_border = { colors = inactive_bordervalue, angle = anglevalue },
        	},
    	}
	})
end

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,

        border_size = 1,

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = true,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
    	
        rounding       = 20,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = inactive_opacityvalue,

        shadow = {
            enabled      = false,
            range        = 20,
            render_power = 3,
            color        = 0x00000055,
        },

        

        blur = {
            enabled            = blurenabled,
            new_optimizations  = true,
            size               = 3, -- 5 
            passes             = 4, -- 5
            noise              = 0.01,
            contrast           = 1,
            brightness         = 1,
            special            = true,
            popups             = true,
            popups_ignorealpha = 0.0,
            xray               = false,            
            vibrancy           = 0.0,
            vibrancy_darkness  = 0.0,
        },
    },

    animations = {
        enabled = animationsenabled,
    },
})

----------------------
----  Animations  ----
----------------------

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default"                                   })
hl.animation({ leaf = "border",        enabled = true,  speed = 15,   bezier = "easeOutQuint"                              })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, bezier = "easeOutQuint"            		           })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  bezier = "easeOutQuint",     style = "popin 87%"     })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",           style = "popin 87%"     })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear"                              })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear"                              })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick"                                     })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint"                              })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint",     style = "fade"          })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",           style = "fade"          })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear"                              })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear"                              })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear",     style = "fade"          })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 2.21, bezier = "easeInOutCubic",   style = "slidefade 20%" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 2.94, bezier = "easeInOutCubic",   style = "slidefade 20%" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick"                                     })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
    master = {
        new_status = "master",
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})


----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = 1,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
        focus_on_activate = true,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us,ru",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = -0.05, 
        accel_profile = "flat",

        touchpad = {
            natural_scroll = true,
            disable_while_typing = false,
        },
    },
    cursor = {
        zoom_detached_camera = false,
    },
    
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
local TOUCHPAD_SENSITIVITY = 0.15

local function touchpad_names()
    local names, seen = {}, {}
    local f = io.open("/proc/bus/input/devices", "r")
    if not f then return names end
    for line in f:lines() do
        local name = line:match('^N: Name="(.-)"')
        if name then
            local low = name:lower()
            if low:find("touchpad", 1, true) or low:find("trackpad", 1, true) then
                local id = low:gsub(" ", "-")
                if not seen[id] then
                    seen[id] = true
                    table.insert(names, id)
                end
            end
        end
    end
    f:close()
    return names
end

for _, name in ipairs(touchpad_names()) do
    hl.device({ name = name, sensitivity = TOUCHPAD_SENSITIVITY })
end

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "down", action = function() hl.plugin.overview.close() end })
hl.gesture({ fingers = 3, direction = "up",   action = function() hl.plugin.overview.open() end })

hl.gesture({ fingers = 3, direction = "up",    mods = mainMod, action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "down",  mods = mainMod, action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "left",  mods = mainMod, action = function() hl.dispatch(hl.dsp.window.move({ workspace = "-1", follow = true })) end })
hl.gesture({ fingers = 3, direction = "right", mods = mainMod, action = function() hl.dispatch(hl.dsp.window.move({ workspace = "+1", follow = true })) end })

hl.gesture({ fingers = 4, direction = "up",    action = function() hl.exec_cmd(mediaPlay) end })
hl.gesture({ fingers = 4, direction = "down",  action = function() hl.exec_cmd(mediaPause) end })
hl.gesture({ fingers = 4, direction = "right",  action = function() hl.exec_cmd(mediaNext) end })
hl.gesture({ fingers = 4, direction = "left", action = function() hl.exec_cmd(mediaPrev) end })

hl.gesture({ fingers = 4, direction = "up",    mods = mainMod, action = function() hl.exec_cmd(launcher) end })
hl.gesture({ fingers = 4, direction = "down",  mods = mainMod, action = "close" })
--hl.gesture({ fingers = 4, direction = "left",  mods = mainMod, action = function() hl.dispatch(hl.dsp.window.move({ workspace = "-1", follow = true })) end })
--hl.gesture({ fingers = 4, direction = "right", mods = mainMod, action = function() hl.dispatch(hl.dsp.window.move({ workspace = "+1", follow = true })) end })


hl.gesture({ fingers = 2, direction = "pinch", mods = mainMod,
             action = "cursor_zoom", zoom_level = 1, mode = "live" })


hl.bind(mainMod .. " + P", function()
    hl.dispatch(hl.dsp.window.float({ action = "set" }))
    hl.dispatch(hl.dsp.window.pin())
end, { description = "  (float + pin window)" })

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd(help), { description = "󰞋  (Help)" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(screenshot), { description = "󱣛  (Screenshot)" })
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(openBuffer), { description = "  (Clipboard)" })
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(toolkit), { description = "  (Screen toolkit)" })
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd(texteditor), { description = "󱩼  (Text editor)"})


hl.bind("SHIFT + ALT + ALT_L", hl.dsp.exec_cmd(switchLocal), {release = true, locked = true, transparent = true, description = "  (Keyboard)"})
hl.bind("SHIFT + ALT + SHIFT_L", hl.dsp.exec_cmd(switchLocal), {release = true, locked = true, transparent = true, description = "  (Keyboard)"})
hl.bind("SUPER + TAB", hl.dsp.focus({ workspace = "previous_per_monitor" }), { description = "󰦛  (Last workspace)"})
hl.bind("ALT + TAB", hl.dsp.focus({ monitor = "+1" }), { description = "󰍺  (Toggle per monitor)"})

hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd(mediaPrev), { description = "󰒮  (Previous)"})
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd(mediaNext), { description = "󰒭  (Next)"})
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd(mediaToggle), { description = "󰐎  (Play/Pause)"})
hl.bind("CTRL + Control_R", hl.dsp.exec_cmd(showInfo), { description = "Show system info(doesnt work)"})

hl.bind("CTRL + SHIFT + escape", hl.dsp.exec_cmd(taskmng), { description = "  (Task manager)"})

hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), { description = "  (Fullscreen)"})
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal), { description = "  (Terminal)"})
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.close(), { description = "󰱞  (Close window)"})
hl.bind(mainMod .. " + SHIFT + W", function() hl.plugin.overview.toggle() end, { description = "󰨝  (Workspaces overview)" })
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(exitHyprland), { description = "󰈆  (Exit hyprland)"})
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager), { description = "  (File manager)"})
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"), { description = "󰑓  (Reload config)" })
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }), { description = "󰉨  (Float)"})
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(launcher), { description = "󰀻  (Launcher)"})

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + A", hl.dsp.focus({ direction = "left" }), { description = "   (Focus)"})
hl.bind(mainMod .. " + D", hl.dsp.focus({ direction = "right" }), { description = "   (Focus)"})
hl.bind(mainMod .. " + W", hl.dsp.focus({ direction = "up" }), { description = "   (Focus)"})
hl.bind(mainMod .. " + S", hl.dsp.focus({ direction = "down" }), { description = "   (Focus)"})

hl.bind(mainMod .. " + CTRL + A", hl.dsp.window.move({ direction = "left" }), { description = "   (Move)"})
hl.bind(mainMod .. " + CTRL + D", hl.dsp.window.move({ direction = "right" }), { description = "   (Move)"})
hl.bind(mainMod .. " + CTRL + W", hl.dsp.window.move({ direction = "up" }), { description = "   (Move)"})
hl.bind(mainMod .. " + CTRL + S", hl.dsp.window.move({ direction = "down" }), { description = "   (Move)"})

hl.bind(mainMod .. " + SHIFT + CTRL + A", hl.dsp.workspace.move({ monitor = "left" }), { description = "󰍹   (Move)"})
hl.bind(mainMod .. " + SHIFT + CTRL + D", hl.dsp.workspace.move({ monitor = "right" }), { description = "󰍹   (Move)"})
hl.bind(mainMod .. " + SHIFT + CTRL + W", hl.dsp.workspace.move({ monitor = "up" }), { description = "󰍹   (Move)"})
hl.bind(mainMod .. " + SHIFT + CTRL + S", hl.dsp.workspace.move({ monitor = "down" }), { description = "󰍹   (Move)"})

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}), { description = "󱂬   ".. i .. " (Workspace)"})
end
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }), { description = "   " .. i .. " (Move window)"})
end
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + ALT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }),
            { description = "   " .. i .. " (Silent move window)"})
end


-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "󱂬   (Next workspace)"})
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), { description = "󱂬   (Previous workspace)"})

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, description = " 󰆾  (Move)" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = " 󰩨  (Resize)" })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true, description = "󰝞  (Less)" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true, description = "󰝝  (More)" })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true, description = "󰖁  (Mute)" })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true, description = "󰍭  (Volume)" })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true, description = "󰃠  (More)" })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true, description = "󰃞  (Less)" })
hl.bind("XF86TouchpadToggle",   function() hl.plugin.overview.toggle() end,                  { description = "󰨝  (Workspaces overview)" })
hl.bind(mainMod .. " + CTRL + mouse_up",   hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, description = "󰝝  (More)" })
hl.bind(mainMod .. " + CTRL + mouse_down", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, description = "󰝞  (Less)" })
             

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd(mediaNext),   { locked = true, description = "󰒭  (Next)" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(mediaToggle), { locked = true, description = "󰐎  (Play/Pause)" })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd(mediaToggle), { locked = true, description = "󰐎  (Play/Pause)" })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd(mediaPrev),   { locked = true, description = "󰒮  (Previous)" })

hl.bind("CTRL + SHIFT + M", hl.dsp.pass({ window = "class:^(dev.vencord.Vesktop)$" }), { transparent = true, description = "  (Mute)" })

local isneedlidguard = "0"
local file = io.open(os.getenv("HOME") .. "/.cache/lid_guard", "r")
if file then
    isneedlidguard = file:read("*all"):gsub("%s+", "")
    file:close()
end

if isneedlidguard == "0" then
    hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("noctalia msg session lock; systemctl suspend -i"), { locked = true, description = "Suspend" })
end    

hl.bind("switch:on:Lid Switch", function()
                 hl.timer(function()
                   hl.dispatch(hl.dsp.dpms({ action = "disable" }))
                 end, {timeout = 500, type = "oneshot"})
               end, { locked = true, description = "On monitor" })
hl.bind("switch:off:Lid Switch", function()
                 hl.timer(function()
                   hl.dispatch(hl.dsp.dpms({ action = "enable" }))
                 end, {timeout = 500, type = "oneshot"})
               end, { locked = true, description = "Off monitor" })
