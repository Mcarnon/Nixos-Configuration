# Desktop look & feel: cursor theme + GTK icons/dark mode + 输入法桥接。
# Noctalia 会按壁纸生成 ~/.config/gtk-{3,4}.0/noctalia.css；这里负责把生成的
# CSS import 进来，并保留光标/图标/字体等基础外观。
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
      name = "adw-gtk3-dark"; # M3 风格兜底
      package = pkgs.adw-gtk3;
    };
    gtk3.extraCss = ''
      @import url("noctalia.css");
    '';
    gtk4.extraCss = ''
      @import url("noctalia.css");
    '';

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

  # 启用 HM 的 fontconfig 支持，确保系统字体和用户 profile 字体都能被应用找到。
  fonts.fontconfig.enable = true;

  # fontconfig 用户级微调（抗锯齿/hinting + monospace 优先 Maple Mono NF）
  xdg.configFile."fontconfig/fonts.conf".source = ../../../home/files/fonts.conf;
}
