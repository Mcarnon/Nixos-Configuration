# Desktop look & feel — SHORiN minimal-niri 风格：
#   * 光标 breeze_cursors（同 niri config.kdl 的 cursor 配置）
#   * GTK 主题 adw-gtk3（深色，flatpak override 同款）
#   * 图标 Papirus-Dark（Shorin 未指定，沿用仓库原有）
#   * gtk-im-module=fcitx（gtk2/3/4 输入法桥接，走 gtk.extraConfig 避免
#     与 HM gtk 模块写同一 settings.ini 冲突）
#   * fontconfig 用户级微调（抗锯齿/hinting + monospace 优先 Maple Mono NF）
{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.pointerCursor = {
    enable = true;
    name = "breeze_cursors"; # XCursor 主题名（下划线）
    package = pkgs.kdePackages.breeze; # nixpkgs 属性名（Plasma 6 后为 kdePackages）
    size = 30;
  };

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    # 输入法桥接：GTK2/3/4 一律走 fcitx
    gtk2.extraConfig = "gtk-im-module=\"fcitx\"";
    gtk3.extraConfig = {
      gtk-im-module = "fcitx";
    };
    gtk4.extraConfig = {
      gtk-im-module = "fcitx";
    };
  };

  # fontconfig 用户级微调（monospace 优先 Maple Mono NF）
  xdg.configFile."fontconfig/fonts.conf".source = ../../../home/files/fonts.conf;
}
