# GUI / desktop applications — 基础桌面工具：
# foot 终端、satty 截图标注、imv 图片查看（mimeapps 默认）。
# 通知/电源菜单由 Clavis 提供（不再需要 mako/wlogout）。
{
  config,
  pkgs,
  inputs,
  ...
}:
{
  home.packages = with pkgs; [

    # -- 终端 / 字体 --
    foot # Wayland 终端（foot.ini 见下方 xdg.configFile）
    maple-mono.NF-CN # Maple Mono NF（含中文字形；foot/Clavis 主字体）
    adwaita-fonts # Adwaita Sans（fontconfig 回退）

    # -- 文件管理器 --
    thunar # 主文件管理器（Mod+E）
    thunar-volman # 移动设备自动挂载
    ffmpegthumbnailer # 视频缩略图
    gvfs # 回收站 + 远程/可移动挂载（thunar/nautilus 共用）
    nautilus # 备用文件管理器（Mod+Alt+E）
    imv # 图片查看器（mimeapps 默认）

    # -- 桌面工具 --
    satty # 截图标注工具（Mod+Shift+S）

    # -- 浏览器 / 工具 --
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default # browser
    xdg-utils # xdg-open & friends
    xwayland-satellite # X11 support (started by spawn-at-startup)
    networkmanagerapplet # nm-applet tray icon

  ];

  # 应用配置文件（raw 部署，Shorin 原版或裁剪版）
  xdg.configFile = {
    "foot/foot.ini".source = ../../../home/files/foot.ini;
    "satty/config.toml".source = ../../../home/files/satty.toml;
    "Thunar/uca.xml".source = ../../../home/files/thunar/uca.xml;
    "Thunar/accels.scm".source = ../../../home/files/thunar/accels.scm;
    "xfce4/xfconf/xfce-perchannel-xml/thunar.xml".source =
      ../../../home/files/thunar/thunar.xml;
    "xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml".source =
      ../../../home/files/thunar/thunar-volman.xml;
    "mimeapps.list".source = ../../../home/files/mimeapps.list;
  };
}
