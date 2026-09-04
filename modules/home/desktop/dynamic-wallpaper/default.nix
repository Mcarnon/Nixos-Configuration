# 动态壁纸模块：统一管理静态壁纸轮换 + mpvpaper 视频壁纸。
#
# 功能：
#   - `dynamic-wallpaper` CLI：set/next/random/toggle-auto/status/list-video
#   - mpvpaper 视频壁纸支持（mp4/webm/mkv/mov）
#   - mpv-hook.lua：视频播放时自动提取第一帧缩略图供 Noctalia Material You 配色
#   - 与 Noctalia 原生壁纸轮换（[wallpaper.automation]）无缝集成
#
# 依赖（NixOS 系统级）：mpvpaper, ffmpeg
# 依赖（用户级）：noctalia
{ config, pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellScriptBin "dynamic-wallpaper"
      (builtins.readFile ./dynamic-wallpaper.sh))
  ];

  # mpvpaper 默认配置（无音频、循环、自适应画面）
  xdg.configFile."mpv/mpvpaper.conf".text = ''
    loop-file=inf
    panscan=1.0
    no-audio
    hwdec=auto
  '';

  # mpvpaper mpv hook 脚本（提取第一帧给 Noctalia 做 Material You 配色）
  xdg.configFile."noctalia/mpv-hook.lua".source = ./mpv-hook.lua;

  # 确保视频壁纸目录存在
  home.file."Pictures/Wallpapers/video/.gitkeep".source = ../../../../wallpapers/video/.gitkeep;

  # 运行时状态目录
  xdg.dataFile."dynamic-wallpaper/.keep".text = "";
}
