# Lock screen — hyprlock，SHORiN minimal-niri 原版配置 + Matugen 生成色板
# （hyprlock-colors.conf 已硬编码，无运行时依赖）。
# 键位：Mod+Alt+L；休眠组合 Mod+Alt+P（先锁后挂，见 binds.kdl）。
{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = [ pkgs.hyprlock ];

  xdg.configFile = {
    "niri/hyprlock.conf".source = ../../../home/niri/hyprlock.conf;
    "niri/hyprlock-colors.conf".source = ../../../home/niri/hyprlock-colors.conf;
  };
}
