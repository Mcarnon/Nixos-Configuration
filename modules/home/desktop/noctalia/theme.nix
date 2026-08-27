# Theme: Catppuccin builtin now; flip to wallpaper-driven colors once wallpapers
# are in place (Material You palette).
{ config, lib, ... }:
{
  programs.noctalia.settings = {
    theme = {
      mode = "dark";
      source = "builtin"; # ← switch to "wallpaper" after adding images
      builtin = "Catppuccin";
      # source = "wallpaper";
      # wallpaper_scheme = "m3-tonal-spot";

      # Re-render app themes when the palette changes
      # (builtin ids: `noctalia theme --list-templates`).
      templates = {
        enable_builtin_templates = true;
        builtin_ids = [
          "gtk3"
          "gtk4"
          "qt"
          "foot"
          "starship"
          "btop"
        ];
      };
    };

    # Night light: schedule from `location` below.
    nightlight = {
      enabled = true;
      temperature_day = 6500;
      temperature_night = 4000;
    };

    location = {
      auto_locate = false;
      address = "Shanghai, China"; # TODO: your city (feeds weather + night light)
    };
  };
}
