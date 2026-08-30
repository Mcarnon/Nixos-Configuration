# Waybar status bar — ported from SHORiN's minimal-niri dotfiles via
# Sakurafall-arch/nixos-configuration (Nord palette + awww wallpaper scripts).
#
# Started as an explicit user systemd service under graphical-session.target
# (same pattern the old Clavis shell used), not via niri spawn-at-startup, so
# crashes auto-restart and the bar is guaranteed up once the session is live.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  nord = {
    nord0 = "#2e3440";
    nord1 = "#3b4252";
    nord2 = "#434c5e";
    nord3 = "#4c566a";
    nord4 = "#d8dee9";
    nord5 = "#e5e9f0";
    nord6 = "#eceff4";
    nord7 = "#8fbcbb";
    nord8 = "#88c0d0";
    nord9 = "#81a1c1";
    nord10 = "#5e81ac";
    nord11 = "#bf616a";
    nord12 = "#d08770";
    nord13 = "#ebcb8b";
    nord14 = "#a3be8c";
    nord15 = "#b48ead";
  };

  sharedScripts = import ./share_scripts.nix { inherit pkgs; };
in
{
  home.packages = [
    # Wallpaper scripts (wallpaper_random / default_wall / dynamic_wallpaper).
    sharedScripts.wallpaper_random
    sharedScripts.default_wall
    sharedScripts.dynamic_wallpaper
    # awww is the wallpaper daemon the scripts drive; must be on PATH for them.
    pkgs.awww
  ];

  programs.waybar = {
    enable = true;
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 12pt;
        font-weight: bold;
        border-radius: 0px;
        transition-property: background-color;
        transition-duration: 0.5s;
      }

      @keyframes blink_red {
        to {
          background-color: ${nord.nord11};
          color: ${nord.nord0};
        }
      }

      .warning,
      .critical,
      .urgent {
        animation-name: blink_red;
        animation-duration: 1s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      window#waybar {
        background-color: transparent;
      }

      window > box {
        margin-left: 5px;
        margin-right: 5px;
        margin-top: 5px;
        background-color: ${nord.nord1};
      }

      #workspaces {
        padding-left: 0px;
        padding-right: 4px;
      }

      #workspaces button {
        padding-top: 5px;
        padding-bottom: 5px;
        padding-left: 6px;
        padding-right: 6px;
        color: ${nord.nord4};
      }

      #workspaces button.active {
        background-color: ${nord.nord7};
        color: ${nord.nord0};
      }

      #workspaces button.urgent {
        color: ${nord.nord0};
      }

      #workspaces button:hover {
        background-color: ${nord.nord15};
        color: ${nord.nord0};
      }

      tooltip {
        background: ${nord.nord1};
      }

      tooltip label {
        color: ${nord.nord5};
      }

      #custom-launcher {
        font-size: 20px;
        padding-left: 8px;
        padding-right: 6px;
        color: ${nord.nord8};
      }

      #mode,
      #clock,
      #memory,
      #temperature,
      #cpu,
      #custom-wall,
      #backlight,
      #pulseaudio,
      #network,
      #battery,
      #custom-power,
      #tray {
        padding-left: 10px;
        padding-right: 10px;
      }

      #memory {
        color: ${nord.nord7};
      }

      #cpu {
        color: ${nord.nord15};
      }

      #window {
        color: ${nord.nord4};
        font-weight: normal;
      }

      #clock {
        color: ${nord.nord5};
      }

      #custom-wall {
        color: ${nord.nord15};
      }

      #temperature {
        color: ${nord.nord9};
      }

      #backlight {
        color: ${nord.nord14};
      }

      #pulseaudio {
        color: ${nord.nord13};
      }

      #network {
        color: ${nord.nord14};
      }

      #network.disconnected {
        color: ${nord.nord4};
      }

      #battery.charging,
      #battery.full,
      #battery.discharging {
        color: ${nord.nord12};
      }

      #battery.critical:not(.charging) {
        color: ${nord.nord4};
      }

      #custom-power {
        color: ${nord.nord11};
      }

      #tray {
        padding-right: 8px;
        padding-left: 10px;
      }

      #tray menu {
        background: ${nord.nord1};
        color: ${nord.nord4};
      }
    '';
    settings = [
      {
        layer = "top";
        height = 30;
        spacing = 4;
        modules-left = [
          "custom/launcher"
          "niri/workspaces"
          "niri/window"
          "custom/wall"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "pulseaudio"
          "backlight"
          "network"
          "memory"
          "cpu"
          "temperature"
          "battery"
          "custom/power"
          "tray"
        ];
        "custom/launcher" = {
          format = "  ";
          on-click = "fuzzel";
          tooltip = false;
        };
        "custom/wall" = {
          on-click = "${sharedScripts.wallpaper_random}/bin/wallpaper_random";
          on-click-middle = "${sharedScripts.default_wall}/bin/default_wall";
          on-click-right =
            "killall dynamic_wallpaper || ${sharedScripts.dynamic_wallpaper}/bin/dynamic_wallpaper &";
          format = "  ";
          tooltip = false;
        };
        "niri/workspaces" = {
          format = "{name}";
          on-click = "activate";
          sort-by-number = true;
          active-only = false;
        };
        "niri/window" = {
          format = "{title}";
          max-length = 60;
          rewrite = {
            "" = "Desktop";
          };
        };
        backlight = {
          device = "intel_backlight";
          on-scroll-up = "brightnessctl -d intel_backlight set +5%";
          on-scroll-down = "brightnessctl -d intel_backlight set 5%-";
          format = "{icon} {percent}%";
          format-icons = [
            "󰃝"
            "󰃞"
            "󰃟"
            "󰃠"
          ];
        };
        pulseaudio = {
          scroll-step = 1;
          format = "{icon} {volume}%";
          format-muted = "󰖁 Muted";
          format-icons = {
            default = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];
          };
          on-click = "pamixer -t";
          tooltip = false;
        };
        battery = {
          interval = 10;
          states = {
            warning = 20;
            critical = 10;
          };
          format = "{icon} {capacity}%";
          format-icons = [
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
          format-full = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          tooltip = false;
        };
        clock = {
          interval = 1;
          format = "{:%H:%M  %a %b %d}";
          tooltip = true;
          tooltip-format = "<tt>{calendar}</tt>";
          calendar = {
            mode = "year";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            format = {
              months = "<span color='${nord.nord13}'><b>{}</b></span>";
              days = "<span color='${nord.nord15}'><b>{}</b></span>";
              weeks = "<span color='${nord.nord7}'><b>W{}</b></span>";
              weekdays = "<span color='${nord.nord13}'><b>{}</b></span>";
              today = "<span color='${nord.nord11}'><b><u>{}</u></b></span>";
            };
          };
          actions = {
            on-click-right = "mode";
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
          };
        };
        memory = {
          interval = 1;
          format = "󰍛 {percentage}%";
          states = {
            warning = 85;
          };
        };
        cpu = {
          interval = 1;
          format = "󰻠 {usage}%";
        };
        network = {
          interval = 1;
          format-wifi = "󰖩 {essid} ({ipaddr})";
          format-ethernet = "󰀂 {ifname} ({ipaddr})";
          format-linked = "󰖪 {essid} (No IP)";
          format-disconnected = "󰯡 Disconnected";
          tooltip = false;
        };
        temperature = {
          tooltip = false;
          format = " {temperatureC}°C";
        };
        "custom/power" = {
          format = "⏻";
          tooltip = false;
          menu = "on-click";
          menu-file = "$HOME/.config/waybar/power_menu.xml";
          menu-actions = {
            shutdown = "systemctl poweroff";
            reboot = "systemctl reboot";
            suspend = "systemctl suspend";
            hibernate = "systemctl hibernate";
            lock = "hyprlock";
          };
        };
        tray = {
          icon-size = 15;
          spacing = 5;
        };
      }
    ];
  };

  # power menu XML (deployed next to the config; referenced via menu-file above).
  xdg.configFile."waybar/power_menu.xml".source = ./power_menu.xml;

  systemd.user.services.waybar = {
    Unit = {
      Description = "Waybar status bar";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.waybar}/bin/waybar --log-level error";
      Restart = "on-failure";
      RestartSec = 2;
      TimeoutStopSec = 10;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
