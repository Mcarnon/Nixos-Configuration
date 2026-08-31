# Desktop look & feel: cursor theme + GTK icons/dark mode + 输入法桥接。
# Shell 颜色由 Clavis/Matugen 运行时生成到 ~/.config/clavis；
# 这里只管外壳之外的 GTK 外观与输入法。
{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Wayland 光标：niri 的 `cursor {}` 块（home/niri/config.kdl）为 niri 启动的
  # 进程设置 XCURSOR_THEME/SIZE；gsettings 覆盖 GTK 应用。
  home.pointerCursor = {
    enable = true;
    name = "volantes_cursors"; # XCursor 主题名（下划线）
    package = pkgs.volantes-cursors; # nixpkgs 属性名（连字符）
    size = 24;
  };

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark"; # M3 风格兜底（Clavis 设置中心不生成 GTK 主题）
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-im-module = "fcitx";
    };

    # 输入法桥接：GTK2/4 走 fcitx（走 extraConfig 避免与 HM gtk 模块
    # 写同一 settings.ini 冲突）
    gtk2.extraConfig = "gtk-im-module=\"fcitx\"";
    gtk4.extraConfig = {
      gtk-im-module = "fcitx";
    };
  };

  # fontconfig 用户级微调（抗锯齿/hinting + monospace 优先 Maple Mono NF）
  xdg.configFile."fontconfig/fonts.conf".source = ../../../home/files/fonts.conf;
}
