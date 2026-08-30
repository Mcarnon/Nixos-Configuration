# GUI / desktop applications — SHORiN minimal-niri 风格：
# Thunar 主文件管理器（Mod+E），nautilus 保留（Mod+Alt+E / portal 文件选择）。
# foot 终端、satty 截图标注、imv 图片查看（mimeapps 默认）都是 Shorin 同款。
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
    maple-mono # Maple Mono NF（foot/fuzzel/hyprlock 主字体）
    adwaita-fonts # Adwaita Sans（mako 通知字体 / fontconfig 回退）

    # -- 文件管理器 --
    thunar # 主文件管理器（Mod+E）
    thunar-volman # 移动设备自动挂载
    ffmpegthumbnailer # 视频缩略图
    gvfs # 回收站 + 远程/可移动挂载（thunar/nautilus 共用）
    nautilus # 备用文件管理器（Mod+Alt+E）
    imv # 图片查看器（mimeapps 默认）

    # -- 桌面组件 --
    satty # 截图标注工具（Mod+Shift+S）
    mako # 通知守护（配置在 modules/home/desktop/mako.nix）
    wlogout # 电源菜单（Mod+Shift+Ctrl+Q）

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
    # wlogout 电源菜单（niri 适配布局，Mod+Shift+Ctrl+Q）
    "wlogout/layout".source = ../../../home/files/wlogout-layout.json;
    "wlogout/style.css".source = ../../../home/files/wlogout-style.css;
  };
}
