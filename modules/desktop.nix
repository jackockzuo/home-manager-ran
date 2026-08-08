{ pkgs, ... }:

{
  # 自动挂载 Niri 配置 (KDL)
  xdg.configFile."niri/config.kdl".text = ''
    spawn-at-startup "waybar"
    spawn-at-startup "swaync"
    spawn-at-startup "awww-daemon"
    spawn-at-startup "systemctl" "--user" "start" "hyprpolkitagent"

    layout {
        gaps 14
        geometry-corner-radius 18

        focus-ring {
            width 2
            active-color "#cba6f7"
            inactive-color "#313244"
        }

        shadow {
            on
            softness 30
            spread 5
            offset x=0 y=10
            color "#00000070"
        }
    }

    prefer-no-csd

    binds {
        Mod+Return { spawn "kitty"; }
        Mod+D { spawn "fuzzel"; }
        Mod+Q { close-window; }
        Mod+Shift+E { quit; }

        XF86AudioRaiseVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
        XF86AudioLowerVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
        XF86AudioMute        { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
    }
  '';

  # Waybar 胶囊美化状态栏
  programs.waybar = {
    enable = true;
    settings = [{
      layer = "top";
      position = "top";
      margin-top = 8;
      margin-left = 12;
      margin-right = 12;

      modules-left = [ "niri/workspaces" "niri/window" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "cpu" "memory" ];

      "clock" = { format = " {:%H:%M  󰃭 %Y-%m-%d}"; };
      "pulseaudio" = { format = "{icon} {volume}%"; format-icons = [ "" "" "󰕾" ]; };
    }];

    style = ''
      * {
        border: none;
        font-family: 'Maple Mono NF CN';
        font-size: 13px;
        font-weight: bold;
      }
      window#waybar { background: transparent; }
      .modules-left, .modules-center, .modules-right {
        background: #1e1e2e;
        border: 1px solid #313244;
        border-radius: 12px;
        padding: 2px 10px;
      }
      #clock, #pulseaudio, #network, #cpu, #memory, #workspaces {
        color: #cdd6f4;
        padding: 0 8px;
      }
      #clock { color: #cba6f7; }
    '';
  };
}
