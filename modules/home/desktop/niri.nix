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

  # 注意：Clavis 托管的片段（effects / cursor / layer-rules / binds / outputs /
  # minimize-animation）刻意【不】在这里声明。它们由 Clavis 自己写进
  # ~/.config/niri/clavis/，是运行时生成的普通文件；config.kdl 里已经用
  # `include optional=true` 预留了位置。做成 home.file 会让 HM 把它们变成指向
  # /nix/store 的只读软链，Clavis 每次写片段都会失败。
}
