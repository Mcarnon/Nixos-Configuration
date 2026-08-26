# Desktop theme — single source of truth shared by Noctalia and niri.
#
# Noctalia reads `font`, `wallpaperDir` and `theme` directly. The `blur`
# values below are consumed by niri's static KDL (home/niri/windowrule.kdl);
# keep the two in sync when you tune blur.

{
  font = "JetBrainsMono Nerd Font";

  wallpaperDir = "~/Pictures/Wallpapers";

  # Noctalia built-in palette. To switch to wallpaper-driven Material You,
  # set source = "wallpaper" and add wallpaper_scheme = "m3-content".
  theme = {
    mode = "dark";
    source = "builtin";
    builtin = "Catppuccin";
  };

  # niri window blur (see home/niri/windowrule.kdl `blur { ... }`).
  blur = {
    passes = 2;
    offset = 3.0;
    noise = 0.03;
    saturation = 1.0;
  };
}
