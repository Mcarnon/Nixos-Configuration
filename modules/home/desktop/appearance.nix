# Desktop look & feel: cursor theme + GTK icons/dark mode + 输入法桥接。
# 基础外观走 dconf（DB，没有文件冲突）；仍然【不用】home-manager 的 gtk 模块，
# 因为它会把 gtk.css / settings.ini 做成只读 store 软链，留给按需生成它们的
# 桌面壳更安全。Clavis 的 matugen 模板只覆盖 btop / cava / kitty / yazi /
# quickshell-colors，不写 GTK 配色，所以这份初值就是最终值（深/浅色在 Clavis
# 设置里切 GTK 主题时由 GTK 自己接管）。见 modules/home/desktop/clavis。
{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Wayland 光标：niri 的 `cursor {}` 块（home/niri/config.kdl）为 niri 启动的
  # 进程设置 XCURSOR_THEME/SIZE；这里再同步到 dconf 覆盖 GTK 应用。
  # 对齐 SHORiN：使用 Breeze 光标。
  home.pointerCursor = {
    enable = true;
    name = "breeze_cursors";
    package = pkgs.kdePackages.breeze;
    size = 24;
  };

  # 基础 GTK 外观（主题/图标/深色/输入法）。
  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-system";
        gtk-theme = "adw-gtk3-dark";
        icon-theme = "Papirus-Dark";
        gtk-im-module = "fcitx";
      };
    };
  };

  # 启用 HM 的 fontconfig 支持，确保系统字体和用户 profile 字体都能被应用找到。
  fonts.fontconfig.enable = true;

  # fontconfig 用户级微调（抗锯齿/hinting + monospace 优先 Maple Mono NF）
  xdg.configFile."fontconfig/fonts.conf".source = ../../../home/files/fonts.conf;

  # adw-gtk3（GTK 主题包）+ adwaita-icon-theme（图标回退链：Papirus 找不到的
  # 图标落到 adwaita）+ Papirus-Dark（初始图标主题）由这里安装。
  # 曾经依赖的 Adwaita-Matugen-* 生成主题已随 matugen 一起删除。
  home.packages = with pkgs; [
    adw-gtk3
    papirus-icon-theme
    adwaita-icon-theme
  ];
}