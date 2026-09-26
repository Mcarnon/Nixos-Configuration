# Desktop look & feel: cursor theme + GTK icons/dark mode + 输入法桥接。
# 基础外观走 dconf（DB，没有文件冲突）；仍然【不用】home-manager 的 gtk 模块，
# 因为它会把 gtk.css / settings.ini 做成只读 store 软链，而后者的可写副本由
# clavis-theme-sync 维护（见 modules/home/desktop/clavis/bin/clavis-theme-sync：
# Clavis 设置中心切深/浅色 -> dconf + gtk-3.0/gtk-4.0/settings.ini + Kvantum）。
# 壁纸取色只影响 Clavis 自己的模板输出（niri/kitty/cava/zsh/... ），不再重染
# GTK：Clavis 没有 GTK 模板，硬塞会和我们手改的 gtk.css 抢同一个文件。
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

  # 基础 GTK 外观（主题/图标/深色/输入法）。深浅色跟随由 clavis-theme-sync 覆盖。
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

  # Adwaita 图标主题是 Adwaita-Matugen 的继承源；必须存在，否则生成主题
  # 的图标会显示为缺失/错误图标（紫黑棋盘格）。
  # adw-gtk3（GTK 主题包）与 Papirus-Dark（初始图标主题）也由这里安装。
  home.packages = with pkgs; [
    adw-gtk3
    papirus-icon-theme
    adwaita-icon-theme
  ];
}