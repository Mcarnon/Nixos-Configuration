# Noctalia v5 desktop shell — entry point for the domain-split config.
#
# `programs.noctalia.settings` is a freeform type: each sibling module
# (`theme.nix`, `bar.nix`, ...) deep-merges its own subtree here. The generated
# config.toml is validated at build time (`validateConfig = true`), so a schema
# mistake fails the build rather than breaking the desktop at runtime.
{ config, pkgs, inputs, lib, ... }:
{
  imports = [
    inputs.noctalia.homeModules.default
    ./theme.nix
    ./bar.nix
    ./wallpaper.nix
    ./lockscreen.nix
    ./integrations.nix
  ];

  programs.noctalia = {
    enable = true;
    validateConfig = true;

    settings = {
      # ── Shell: typography / panels / launcher / clipboard / animation ──
      shell = {
        font_family = "JetBrainsMono Nerd Font"; # installed in locales/default.nix
        time_format = "{:%H:%M}";
        date_format = "%A, %x";
        telemetry_enabled = false;
        settings_show_advanced = true;
        clipboard_enabled = true;
        clipboard_auto_paste = "auto";
        corner_radius_scale = 1.0;
        # polkit_agent stays off: the polkit-gnome agent is started from
        # modules/nixos/desktop/niri.nix (two agents would race for prompts).

        animation = {
          enabled = true;
          speed = 1.0;
        };

        shadow = {
          direction = "down";
          alpha = 0.6;
        };

        # Frosted-glass floating panels.
        panel = {
          transparency_mode = "glass";
          borders = true;
          shadow = true;
          launcher_placement = "floating";
          clipboard_placement = "floating";
          control_center_placement = "floating";
          wallpaper_placement = "floating";
          session_placement = "floating";
          launcher_position = "center";
          clipboard_position = "center";
          session_position = "center";
          open_near_click_control_center = true;
        };

        launcher = {
          categories = true;
          show_icons = true;
          app_grid = true;
          sort_by_usage = true;
        };
      };

      # ── Notifications + OSD ──
      notification = {
        enable_daemon = true; # niri has no notification daemon of its own
        layer = "overlay";
        background_opacity = 0.95;
        offset_x = 16;
        offset_y = 12;
      };

      osd = {
        position = "top_right";
        background_opacity = 0.9;
        offset_x = 16;
        offset_y = 12;
      };
    };
  };
}
