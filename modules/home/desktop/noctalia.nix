# Noctalia desktop shell (Wayland bar / launcher / control center / lock screen, etc.)
{ config, pkgs, inputs, lib, ... }:
let
  theme = import ./theme.nix;
in
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;

    # Declaratively generate ~/.config/noctalia/config.toml from a Nix attrset
    # (serialized to TOML via pkgs.formats.toml; see also the `validateConfig` note below).
    settings = {
      shell = {
        font_family = theme.font;
        settings_show_advanced = true;

        # Floating panels are translucent ("glass") for the frosted look.
        panel = {
          transparency_mode = "glass";
          launcher_placement = "floating";
          control_center_placement = "floating";
          session_placement = "floating";
          wallpaper_placement = "floating";
          floating_offset = 8;
        };
      };

      theme = theme.theme;

      # Wallpaper + animated transitions + automatic rotation.
      wallpaper = {
        enabled = true;
        fill_mode = "crop";
        transition = [ "fade" "wipe" "disc" "stripes" "zoom" "honeycomb" ];
        transition_duration = 1500;
        directory = theme.wallpaperDir;
      };

      wallpaper.automation = {
        enabled = true;
        interval_seconds = 1800;
        order = "random";
        recursive = true;
      };

      # Lock screen: desktop snapshot + blur + tint.
      lockscreen = {
        enabled = true;
        blurred_desktop = true;
        blur_intensity = 0.5;
        tint_intensity = 0.3;
        fingerprint = true;
        lock_before_suspend = true;
      };

      # Blurred/tinted wallpaper copy behind the niri overview.
      backdrop = {
        enabled = true;
        blur_intensity = 0.5;
        tint_intensity = 0.3;
      };

      # Capsule-style top bar (transparent bar, pill per widget).
      bar = {
        order = [ "default" ];
        default = {
          position = "top";
          thickness = 34;
          background_opacity = 0.0;
          capsule = true;
          capsule_fill = "surface_variant";
          capsule_opacity = 0.79;
          capsule_border = "outline";
          margin_edge = 10;
          start = [ "launcher" "workspaces" ];
          center = [ "clock" ];
          end = [ "media" "tray" "notifications" "volume" "battery" "control-center" "session" ];
        };
      };
    };

    # If config validation fails at build time, temporarily set this to false to debug
    # validateConfig = true;
  };
}
