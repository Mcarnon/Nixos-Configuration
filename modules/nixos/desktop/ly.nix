# ly display manager — SHORiN 的登录方式（arch setup 里 setup_ly 装的就是它）。
#
# 终端风 TUI 登录，极轻量；会话从 /run/current-system/sw/share/wayland-sessions
# 读取（niri 的 .desktop 在 modules/nixos/desktop/niri.nix 里换成了 wrapper，
# 以保证 graphical-session.target 被激活，waybar/mako/polkit/fcitx5 才会拉起）。
{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.displayManager.ly.enable = true;
}
