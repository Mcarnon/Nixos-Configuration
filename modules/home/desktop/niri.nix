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

  # ~/.config/niri/clavis/ 是 Clavis 自己的地盘：colors/effects/cursor 三个
  # kdl 片段由 Clavis 运行时生成，配置文件也是它回写。不能做成 store 软链，
  # 所以这里只保证父目录存在（xdg.configFile 建的目录本身就够了，Clavis 也会
  # 自己 mkdir）。
}
