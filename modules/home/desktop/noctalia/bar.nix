# Status bar: widget list lives in one place; one comment per widget explains
# its role. Built-in widget ids: launcher workspaces clock media tray network
# bluetooth volume brightness battery clipboard notifications control-center
# session wallpaper. Plugins can add widgets via `type = "author/plugin:entry"`.
{ config, lib, ... }:
{
  programs.noctalia.settings = {
    bar = {
      main = {
        position = "top";
        thickness = 34;
        background_opacity = 0.85;
        radius = 12;
        margin_ends = 8;
        margin_edge = 8;
        padding = 12;
        widget_spacing = 8;
        shadow = true;
        auto_hide = false;
        reserve_space = true;

        start = [
          "launcher" # app launcher
          "workspaces" # workspace pill indicator
        ];
        center = [ "clock" ];
        end = [
          "media" # MPRIS media info (hidden when nothing plays)
          "tray" # system tray
          "network" # Wi-Fi / wired
          "bluetooth"
          "volume"
          "brightness"
          "battery"
          "clipboard" # clipboard history panel entry
          "notifications" # notification bell
          "control-center" # control center entry
          "session" # power/session menu
        ];
      };
    };

    # Control-center quick toggles (up to 6).
    control_center = {
      shortcuts = [
        { type = "wifi"; }
        { type = "bluetooth"; }
        { type = "nightlight"; }
        { type = "wallpaper"; }
        { type = "notification"; }
        { type = "session"; }
      ];
    };

    # Tiling WM: no dock.
    dock = {
      enabled = false;
    };

    # Per-widget tweaks (keep one line per widget).
    widget = {
      clock = {
        format = "{:%H:%M}";
        tooltip_format = "{:%A, %d %B %Y}";
      };
      network = {
        show_label = true;
      };
      notifications = {
        hide_when_no_unread = false;
      };
    };
  };
}
