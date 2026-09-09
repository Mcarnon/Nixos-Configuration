# GUI / desktop applications — 基础桌面工具：
# foot 终端、satty 截图标注、imv 图片查看（mimeapps 默认）。
# 通知/电源菜单由 Noctalia 提供（不再需要 mako/wlogout）。
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
    maple-mono.NF-CN # Maple Mono NF（含中文字形；foot/Noctalia 主字体）
    adwaita-fonts # Adwaita Sans（fontconfig 回退）

    # -- 文件管理器 --
    thunar # 主文件管理器（Mod+E）
    thunar-volman # 移动设备自动挂载
    thunar-archive-plugin # Thunar 右键压缩/解压
    tumbler # Thunar 缩略图服务
    poppler_gi # PDF 缩略图
    libgsf # Office 文档缩略图
    webp-pixbuf-loader # WebP 缩略图
    ffmpegthumbnailer # 视频缩略图
    file-roller # 压缩包管理 GUI
    gnome.gvfs # 回收站 + 远程/可移动挂载（含 SMB/MTP/GPhoto2）
    nautilus # 备用文件管理器（Mod+Alt+E）
    nautilus-open-any-terminal # Nautilus 右键“在此打开终端”
    icoextract # Windows exe 图标缩略图
    python3Packages.pillow # 缩略图/图片处理
    imv # 图片查看器（mimeapps 默认）

    # -- 桌面工具 --
    satty # 截图标注工具（Mod+Shift+S）

    # -- 浏览器 / 工具 --
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default # browser
    xdg-utils # xdg-open & friends
    xwayland-satellite # X11 support (started by spawn-at-startup)
    networkmanagerapplet # nm-applet tray icon
    nwg-look # GTK 主题/图标设置 GUI（Noctalia 配色同步辅助）

    # -- Daily Apps --
    zed-editor # IDE
    obsidian # note-taking
    obs-studio # screen recording
    splayer-next # netease music player
    hmcl # minecraft launcher
  ];

  # 应用配置文件（raw 部署，Shorin 原版或裁剪版）。
  # 注意：foot.ini 与 kitty 的 themes/noctalia.conf、current-theme.conf 都归
  # Noctalia 的模板管（模板会覆写它们），不能做成只读 store 软链；foot.ini 由
  # noctalia 模块激活时以可写副本种子部署。这里只保留不需要被模板改写的文件。
  xdg.configFile = {
    "satty/config.toml".source = ../../../home/files/satty.toml;
    "Thunar/uca.xml".source = ../../../home/files/thunar/uca.xml;
    "Thunar/accels.scm".source = ../../../home/files/thunar/accels.scm;
    "xfce4/xfconf/xfce-perchannel-xml/thunar.xml".source =
      ../../../home/files/thunar/thunar.xml;
    "xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml".source =
      ../../../home/files/thunar/thunar-volman.xml;
    "mimeapps.list".source = ../../../home/files/mimeapps.list;
    # foot.ini 由本配置管理（Noctalia v5 不再生成 foot 模板）
    "foot/foot.ini".source = ../../../home/files/foot.ini;
    # 基配置：Noctalia 模板会生成覆盖物（如 fuzzel/themes/noctalia、
    # kitty/current-theme.conf），只兜底不做挡板
    "fuzzel/fuzzel.ini".source = ../../../home/files/fuzzel.ini;
    "xsettingsd/xsettingsd.conf".source = ../../../home/files/xsettingsd.conf;
  };
}
