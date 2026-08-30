# Waybar status bar — SHORiN minimal-niri 原版配置（config.jsonc + style.css 直挂）。
#
# 以 raw 文件部署（不用 programs.waybar.settings，避免 HM 类型转换），以用户
# systemd 服务挂在 graphical-session.target 下（仓库既有模式），崩溃自动重启。
# 壁纸脚本（wallpaper_random 等）保留为本仓库扩展，供 Mod+F10 使用
# （Shorin 的 minimal-niri 本体不画壁纸按钮，waybar 不列出 custom/wall）。
{
  config,
  pkgs,
  lib,
  ...
}:
let
  sharedScripts = import ./share_scripts.nix { inherit pkgs; };
in
{
  home.packages = [
    pkgs.waybar # 状态栏本体（Mod+F2/F4 绑定按名字调用）
    # Wallpaper scripts (wallpaper_random / default_wall / dynamic_wallpaper)
    sharedScripts.wallpaper_random
    sharedScripts.default_wall
    sharedScripts.dynamic_wallpaper
    # awww 是脚本驱动的壁纸守护进程
    pkgs.awww
    # waybar 图标字体（style.css 引用 FontAwesome + JetBrainsMono NFP）
    pkgs.font-awesome
  ];

  xdg.configFile = {
    "waybar/config.jsonc".source = ./config.jsonc;
    "waybar/style.css".source = ./style.css;
  };

  # 默认壁纸（Shorin 原图）：部署到 ~/Pictures/Wallpapers/，
  # niri config.kdl 启动时用 awww 设置；放自己的图后可 Mod+F10 随机切换。
  home.file."Pictures/Wallpapers/wallhaven-d88d53.png".source =
    ../../../../wallpapers/wallhaven-d88d53.png;

  systemd.user.services.waybar = {
    Unit = {
      Description = "Waybar status bar";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.waybar}/bin/waybar -c %h/.config/waybar/config.jsonc -s %h/.config/waybar/style.css";
      Restart = "on-failure";
      RestartSec = 2;
      TimeoutStopSec = 10;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
