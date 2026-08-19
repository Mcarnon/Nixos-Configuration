# 链接 niri 的 KDL 配置目录到 ~/.config/niri
# (config.kdl 通过 include 拆分引用同目录下的子文件)
{ config, pkgs, lib, ... }:
{
  xdg.configFile."niri" = {
    source = ./niri;
    recursive = true;
  };
}
