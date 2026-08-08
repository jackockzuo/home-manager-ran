{ pkgs, ... }:

{
  xdg.configFile."niri/config.kdl".text = ''
    spawn-at-startup "dms-shell"
    spawn-at-startup "fcitx5" "-d" "--replace"
    spawn-at-startup "awww-daemon"
    spawn-at-startup "systemctl" "--user" "start" "hyprpolkitagent"

    // 🔴 自启 U盘自动挂载后台
    spawn-at-startup "udiskie" "-t"

    // 🔴 自启 剪贴板历史监听 (保存文本与截图)
    spawn-at-startup "sh" "-c" "wl-paste --type text --watch cliphist store"
    spawn-at-startup "sh" "-c" "wl-paste --type image --watch cliphist store"

    input {
        keyboard { xkb { layout "us"; } repeat-delay 300; repeat-rate 50; }
        touchpad { tap; natural-scroll; accel-speed 0.2; }
        mouse { accel-speed 0.0; }
    }

    output "eDP-1" { scale 1.25; }

    layout {
        gaps 14
        geometry-corner-radius 20
        default-column-width { proportion 0.5; }

        focus-ring {
            width 2
            active-color "#cba6f7"
            inactive-color "#313244"
        }

        shadow {
            on
            softness 35
            spread 5
            offset x=0 y=10
            color "#00000080"
        }
    }

    prefer-no-csd

    window-rule {
        match app-id="kitty"
        clip-to-geometry true
    }

    binds {
        Mod+Return { spawn "kitty"; }
        Mod+Q { close-window; }
        Mod+Shift+E { quit; }

        Mod+Left  { focus-column-left; }
        Mod+Right { focus-column-right; }
        Mod+Up    { focus-window-or-workspace-up; }
        Mod+Down  { focus-window-or-workspace-down; }
        Mod+H     { focus-column-left; }
        Mod+L     { focus-column-right; }

        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }

        Mod+Shift+1 { move-column-to-workspace 1; }
        Mod+Shift+2 { move-column-to-workspace 2; }
        Mod+Shift+3 { move-column-to-workspace 3; }
        Mod+Shift+4 { move-column-to-workspace 4; }

        Mod+R { switch-preset-column-width; }
        Mod+F { maximize-column; }

        // 🔴 快捷唤出剪贴板历史搜索菜单 (Super + V)
        Mod+V { spawn "sh" "-c" "cliphist list | fuzzel -d | cliphist decode | wl-copy"; }

        Mod+Shift+S { spawn "sh" "-c" "grim -g \"$(slurp)\" - | wl-copy"; }

        XF86AudioRaiseVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
        XF86AudioLowerVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
        XF86AudioMute        { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
    }
  '';
}
