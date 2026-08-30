# Lock screen — hyprlock (SHORiN's minimal-niri lockscreen; standalone, works
# on niri). Config lives at home/hyprlock.conf, deployed below. Bound to
# Super+Alt+L and the suspend combo in home/niri/binds.kdl.
{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = [ pkgs.hyprlock ];

  xdg.configFile."hypr/hyprlock.conf".source = ../../../home/hyprlock.conf;
}
