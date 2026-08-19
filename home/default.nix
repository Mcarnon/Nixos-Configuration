# 用户环境 (Home Manager)
{ config, pkgs, inputs, lib, ... }:
{
  imports = [
    ./niri.nix
    ./noctalia.nix
  ];

  home.stateVersion = "25.05"; # TODO: 与主机 stateVersion 保持一致

  home.packages = with pkgs; [
    # 终端
    foot
    # 文件管理器 (niri 的 portal 文件选择器也依赖它)
    nautilus
    # 截图
    grim
    slurp
    # 剪贴板
    wl-clipboard
    # 音量控制 (备用, Noctalia 自带 OSD)
    pamixer
    # 常用工具
    xdg-utils
    tree
  ];

  programs.git = {
    enable = true;
    # userName = "Your Name";
    # userEmail = "you@example.com";
  };
}
