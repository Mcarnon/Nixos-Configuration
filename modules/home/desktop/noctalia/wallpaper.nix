# Wallpaper: static directory + transitions + scheduled rotation + live video
# wallpaper via the official `mpvpaper` plugin.
{ config, lib, pkgs, ... }:
{
  programs.noctalia.settings = {
    wallpaper = {
      enabled = true;
      directory = "~/Pictures/Wallpapers"; # static images
      fill_mode = "crop";
      transition = [
        "fade"
        "wipe"
        "disc"
        "stripes"
        "zoom"
        "honeycomb"
      ];
      transition_duration = 1500;

      # Scheduled rotation.
      automation = {
        enabled = true;
        interval_seconds = 1800; # every 30 min
        order = "random";
        recursive = true;
      };
    };

    # Live wallpaper: noctalia/mpvpaper (fetched from the built-in official git
    # source on first start; `auto_update = "none"` pins the fetched revision).
    # Manual update: `noctalia msg plugins update official`.
    plugins = {
      enabled = [ "noctalia/mpvpaper" ];
      auto_update = "none";
    };
    plugin_settings."noctalia/mpvpaper" = {
      video_directory = "~/Pictures/Wallpapers/video"; # put .mp4 here
      # mpv_options = "--config=no --load-scripts=no";
    };
  };

  home.packages = with pkgs; [
    mpv    # live wallpaper rendering
    ffmpeg # video frame extraction (live wallpaper color sync)
  ];
}
