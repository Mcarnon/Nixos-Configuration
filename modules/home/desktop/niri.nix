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
    "niri/inir-static.kdl".source = ../../../home/niri/inir-static.kdl;
    "niri/niri-hardware.kdl".source = hostPath + "/niri-hardware.kdl";
  };

  # 刻意不管理任何 iNiR 生成物：外壳的配色/壁纸/状态都写在
  # ~/.local/state/quickshell 和它自己的 template 输出里，niri 侧只有
  # inir-static.kdl（纯静态、只读软链）。
}
