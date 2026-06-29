------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "DP-1",
    mode     = "3840x2160@160",
    position = "0x0",
    scale    = "1",
})

hl.monitor({
    output   = "HDMI-A-1",
    mode     = "3840x2160@60",
    mirror   = "DP-1",
})

---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local fileManager = "dolphin"
local launcher    = "qs -c \"noctalia-shell\" ipc call launcher toggle"
local texteditor  = "gtk-launch org.xfce.mousepad.desktop"
local exitHyprland = "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"
local screenshot = "file=\"/home/$USER/Pictures/Screenshots/screenshot_$(date +%s).png\"; grimblast --freeze copysave area \"$file\"; if [[ -f \"$file\" ]]; then wl-copy --type image/png < \"$file\"; notify-send --app-name=\"System\" \"Screenshot\" \"Image has been saved and copied to the clipboard\" -i \"$file\"; fi"
local openBuffer = "qs -c \"noctalia-shell\" ipc call plugin:clipboard toggle"
local toolsMenu = "qs -c \"noctalia-shell\" ipc call plugin:screen-toolkit toggle"
local mainMenu  = "qs -c \"noctalia-shell\" ipc call controlCenter toggle"
local switchLocal = "for kb in $(hyprctl devices -j | jq -r \".keyboards[].name\" | grep -vE \"power-button|consumer-control|system-control\"); do hyprctl switchxkblayout \"$kb\" next; done"
local mediaPrev = "qs -c \"noctalia-shell\" ipc call media previous"
local mediaNext = "qs -c \"noctalia-shell\" ipc call media next"
local mediaToggle = "qs -c \"noctalia-shell\" ipc call media playPause"
local taskmng = "missioncenter"
local showInfo = "notify-send \"all is ok\" && ~/.config/hypr/scripts/slider.sh check"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function ()
  hl.exec_cmd("hyprpm reload")
  hl.exec_cmd("pkill -9 wl-paste; wl-paste --watch cliphist store &")
  hl.exec_cmd("qs -c \"noctalia-shell\"")
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
--   hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme \"prefer-dark\"")
--   hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme \"adw-gtk3\"")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- hl.env("GTK_APPLICATION_PREFER_DARK_THEME", "1")
hl.env("GDK_DPI_SCALE", "1")
hl.env("GTK_FONT_NAME", "Manrope ExtraLight Regular 16")
-- hl.env("QT_QPA_PLATFORM", "wayland")
-- hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_MENU_PREFIX", "arch-")
-- hl.env("QT_QPA_PLATFORMTHEME", "kde")
-- hl.env("_JAVA_AWT_WM_NONREPARENTING", "1 x")
-- hl.env("XDG_MENU_PREFIX", "arch- kbuildsycoca6")

--------------------------
---- APPERANCE SCRIPT ----
--------------------------

local apperance_mode = "flat"
local file = io.open(os.getenv("HOME") .. "/.cache/sys_appearance", "r")
if file then
    apperance_mode = file:read("*all"):gsub("%s+", "")
    file:close()
end

local hyprglassenabled = false
local blurenabled = false
local transparentenabled = false
local inactive_opacityvalue = 1.0
local active_bordervalue = {"rgba(eeeeeec0)", "rgba(eeeeee00)", "rgba(eeeeee00)", "rgba(eeeeee60)"}
local inactive_bordervalue = {"rgba(909090c0)", "rgba(90909000)", "rgba(90909000)", "rgba(90909060)"}
local anglevalue = 55
if apperance_mode == "blur" then
    hyprglassenabled = false
    blurenabled = true
    transparentenabled = true
    inactive_opacityvalue = 0.8
    hl.exec_cmd("sed -i 's/^background_opacity.*/background_opacity 0.5/' ~/.config/kitty/kitty.conf")
    hl.exec_cmd("perl -0777 -pi -e 's/(<rect[^>]*?id=\"window-normal\"[^>]*?style=\"[^\"]*?opacity:)[0-9.]*/${1}0.5/s' ~/.config/noctalia/templates/kvantum/noctalia.svg")
    hl.exec_cmd("sed -i -E \"s/(@define-color window_bg_color \\{\\{colors\\.surface\\.default\\.rgba \\| set_alpha )[0-9.]+(\\}\\};)/\\10.5\\2/g\" ~/.config/noctalia/templates/gtk/gtk4.css ")
    hl.exec_cmd("sed -i -E \"s/(@define-color window_bg_color \\{\\{colors\\.surface\\.default\\.rgba \\| set_alpha )[0-9.]+(\\}\\};)/\\10.5\\2/g\" ~/.config/noctalia/templates/gtk/gtk3.css ")
elseif apperance_mode == "liquid" then
    hyprglassenabled = true
    blurenabled = false
    transparentenabled = true
    inactive_opacityvalue = 0.8
    hl.exec_cmd("sed -i 's/^background_opacity.*/background_opacity 0.5/' ~/.config/kitty/kitty.conf")
    hl.exec_cmd("perl -0777 -pi -e 's/(<rect[^>]*?id=\"window-normal\"[^>]*?style=\"[^\"]*?opacity:)[0-9.]*/${1}0.5/s' ~/.config/noctalia/templates/kvantum/noctalia.svg")
    hl.exec_cmd("sed -i -E \"s/(@define-color window_bg_color \\{\\{colors\\.surface\\.default\\.rgba \\| set_alpha )[0-9.]+(\\}\\};)/\\10.5\\2/g\" ~/.config/noctalia/templates/gtk/gtk4.css ")
    hl.exec_cmd("sed -i -E \"s/(@define-color window_bg_color \\{\\{colors\\.surface\\.default\\.rgba \\| set_alpha )[0-9.]+(\\}\\};)/\\10.5\\2/g\" ~/.config/noctalia/templates/gtk/gtk3.css ")
else
    local file = io.open(os.getenv("HOME") .. "/.config/hypr/noctalia/noctalia-colors.conf", "r")
    if file then
        local found_primary, found_surface = nil, nil
        for line in file:lines() do
            local p_match = line:match("%$primary%s*=%s*rgb%((%x+)%)")
            if p_match then
                active_bordervalue = { "rgba(" .. p_match .. "ff)" }
                found_primary = true
            end
            local s_match = line:match("%$surface%s*=%s*rgb%((%x+)%)")
            if s_match then
                inactive_bordervalue = { "rgba(" .. s_match .. "ff)" }
                found_surface = true
            end
            if found_primary and found_surface then
                break
            end
        end
        anglevalue = 0
        file:close()
    end
    hl.exec_cmd("sed -i 's/^background_opacity.*/background_opacity 1.0/' ~/.config/kitty/kitty.conf")
    hl.exec_cmd("perl -0777 -pi -e 's/(<rect[^>]*?id=\"window-normal\"[^>]*?style=\"[^\"]*?opacity:)[0-9.]*/${1}1.0/s' ~/.config/noctalia/templates/kvantum/noctalia.svg")
    hl.exec_cmd("sed -i -E \"s/(@define-color window_bg_color \\{\\{colors\\.surface\\.default\\.rgba \\| set_alpha )[0-9.]+(\\}\\};)/\\11.0\\2/g\" ~/.config/noctalia/templates/gtk/gtk4.css ")
    hl.exec_cmd("sed -i -E \"s/(@define-color window_bg_color \\{\\{colors\\.surface\\.default\\.rgba \\| set_alpha )[0-9.]+(\\}\\};)/\\11.0\\2/g\" ~/.config/noctalia/templates/gtk/gtk3.css ")
end
transparentenabled = false

-----------------
---- PLUGINS ----
-----------------

if hl.plugin.dynamic_cursors then
	hl.config { plugin = { dynamic_cursors = {
	    enabled = true,
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


if hl.plugin.hyprglass then
    local hg = hl.plugin.hyprglass

    hg.config({
        enabled = hyprglassenabled,
        
        default_theme = "dark",
        default_preset = "default",

        brightness = 1.0,
        blur_strength = 2.0,
        blur_iterations = 3,
        chromatic_aberration = 0.1,
        fresnel_strength = 0.3,
        specular_strength = 0.5,
        glass_opacity = 2.4,
        tint_color = 0x00000000,
        contrast = 1.0,
        saturation = 1.0,

        refraction_strength = 10.0,
        lens_distortion = 5.0,
        edge_thickness = 0.05,
    })

    -- Presets
    hg.preset("default", {
        glass_opacity = 1.4,
    })

    hg.preset("clear", {
        glass_opacity = 2.4,
    })

end

-----------------------
---- LOOK AND FEEL ----
-----------------------

if transparentenabled then
    local classes = {"vesktop", "org.telegram.desktop", "codium", "steam", "zen", "anytype"}

    for index, value in ipairs(classes) do
        hl.window_rule({ match = { class = value }, tag = "+hyprglass_preset_clear" })
        hl.window_rule({ match = { class = value }, opacity = "1.0 override 0.5 override" })
    end
end

hl.layer_rule({ match = { namespace = "selection" }, blur = false })


hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,

        border_size = 1,

        col = {
            active_border   = { colors = active_bordervalue, angle = anglevalue },
            inactive_border = { colors = inactive_bordervalue, angle = anglevalue },
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = true,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
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
        enabled = true,
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

-- Default springs
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default"                                   })
hl.animation({ leaf = "border",        enabled = true,  speed = 15,   bezier = "easeOutQuint"                              })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy"            		                   }) -- spring = "easy"
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",    		   style = "popin 87%"     }) -- spring = "easy"
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

        sensitivity = -0.05 , -0.05, 
        accel_profile = "flat",

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    mods = mainMod,
    action = "workspace"
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.05,                 -------------------------------------- touchpad
})

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(screenshot))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(openBuffer))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(toolsMenu))
hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd(mainMenu), {release = true})
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd(texteditor))

hl.bind("SHIFT + ALT + ALT_L", hl.dsp.exec_cmd(switchLocal), {release = true, locked = true, transparent = true})
hl.bind("SHIFT + ALT + SHIFT_L", hl.dsp.exec_cmd(switchLocal), {release = true, locked = true, transparent = true})
hl.bind("SUPER  + TAB", hl.dsp.focus({ workspace = "previous_per_monitor" }))
hl.bind("ALT  + TAB", hl.dsp.focus({ monitor = "+1" }))

hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd(mediaPrev))
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd(mediaNext))
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd(mediaToggle))
hl.bind("CTRL + Control_R", hl.dsp.exec_cmd(showInfo))

hl.bind("CTRL + SHIFT + escape", hl.dsp.exec_cmd(taskmng))

hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })) ---------------------------
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd(exitHyprland))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(launcher))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + A", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + D", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + W", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + S", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + CTRL + A", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + D", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + W", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + S", hl.dsp.window.move({ direction = "down" }))

hl.bind(mainMod .. " + SHIFT + CTRL + A", hl.dsp.workspace.move({ monitor = "left" }))
hl.bind(mainMod .. " + SHIFT + CTRL + D", hl.dsp.workspace.move({ monitor = "right" }))
hl.bind(mainMod .. " + SHIFT + CTRL + W", hl.dsp.workspace.move({ monitor = "up" }))
hl.bind(mainMod .. " + SHIFT + CTRL + S", hl.dsp.workspace.move({ monitor = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd(mediaNext),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(mediaToggle), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd(mediaToggle), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd(mediaPrev),   { locked = true })


hl.bind("CTRL + SHIFT + M", hl.dsp.pass({ window = "class:^(vesktop)$" }))
