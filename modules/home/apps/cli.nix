# Modern CLI tools (user-level). Rescue/root tools stay in modules/nixos/core/.
{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    bat # cat with syntax highlight
    yazi # TUI file manager
    lazygit # git TUI
    btop # resource monitor (replaces htop for daily use)
    fastfetch # system info banner (config: home/files/fastfetch.jsonc)
    jq # JSON processing (used by home/files/f.fish waifu fetcher)
    imagemagick # magick — Thunar uca 的图片转 png 动作依赖
    tree # directory tree
  ];

  # fastfetch 主题（SHORiN 原版，见 home/files/fastfetch.jsonc）
  xdg.configFile."fastfetch/config.jsonc".source = ../../../home/files/fastfetch.jsonc;
}
