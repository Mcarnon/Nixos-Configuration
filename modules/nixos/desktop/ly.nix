# ly display manager — SHORiN 的登录方式（arch setup 里 setup_ly 装的就是它）。
#
# 终端风 TUI 登录，极轻量；会话从 /run/current-system/sw/share/wayland-sessions
# 读取（niri 的 .desktop 在 modules/nixos/desktop/niri.nix 里换成了 wrapper，
# 以保证 graphical-session.target 被激活，Clavis/polkit/fcitx5 才会拉起）。
#
# 配色为 Material 3 风格深色（ly 颜色格式 0x00RRGGBB/ARGB）。
{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.displayManager.ly = {
    enable = true;

    settings = {
      # M3 深色色板
      bg = "0x00131318";
      fg = "0x00e4e1e9";
      border_fg = "0x003d4279";
      error_bg = "0x001f1f25";
      error_fg = "0x00ffb4ab";
      # TUI 动画关掉（值必须是 "none" 等 ly 支持的动画名）
      animation = "none";
    };
  };
}
