# Link niri's KDL config to ~/.config/niri.
# Shared config files are linked individually; the machine-specific output
# config (niri-hardware.kdl) is passed in from the host.
{
  config,
  pkgs,
  lib,
  hostPath,
  ...
}:
{
  xdg.configFile = {
    "niri/config.kdl".source = ../../../home/niri/config.kdl;
    "niri/binds.kdl".source = ../../../home/niri/binds.kdl;
    "niri/blur.kdl".source = ../../../home/niri/blur.kdl;
    "niri/startup.kdl".source = ../../../home/niri/startup.kdl;
    "niri/windowrule.kdl".source = ../../../home/niri/windowrule.kdl;
    "niri/supertab.kdl".source = ../../../home/niri/supertab.kdl;
    "niri/clavis-static.kdl".source = ../../../home/niri/clavis-static.kdl;
    "niri/niri-hardware.kdl".source = hostPath + "/niri-hardware.kdl";
  };

  # 刻意不管理任何 Clavis 生成物：外壳的配色/壁纸/模糊开关都写在
  # ~/.config/clavis、~/.local/state/clavis 和它自己的 matugen 输出里，
  # niri 侧只有 clavis-static.kdl（纯静态、只读软链）。
  # 另有一段 Clavis 自己写的 ~/.config/niri/clavis/effects.kdl，由
  # home/niri/config.kdl 以 include optional=true 引入。
}
