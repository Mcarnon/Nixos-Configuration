# Desktop look & feel — SHORiN minimal-niri 风格：
#   * 光标 breeze_cursors（同 niri config.kdl 的 cursor 配置）
#   * GTK 主题 adw-gtk3（深色，flatpak override 同款）
#   * 图标 Papirus-Dark（Shorin 未指定，沿用仓库原有）
#   * gtk-im-module=fcitx（gtk-3.0/4.0 + .gtkrc-2.0）
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
  };

  # 输入法桥接：GTK2/3/4 一律走 fcitx
  xdg.configFile = {
    "gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-im-module=fcitx
    '';
    "gtk-4.0/settings.ini".text = ''
      [Settings]
      gtk-im-module=fcitx
    '';
    ".gtkrc-2.0".text = ''
      gtk-im-module="fcitx"
    '';
    "fontconfig/fonts.conf".source = ../../../home/files/fonts.conf;
  };
}
