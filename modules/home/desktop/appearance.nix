# Desktop look & feel: cursor theme + GTK icons/dark mode.
# Bar/launcher colors are Nord (waybar) / Catppuccin (fuzzel) — static, no
# runtime theming.
{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Wayland cursor: niri's `cursor {}` block (home/niri/config.kdl) sets
  # XCURSOR_THEME/SIZE for niri-spawned apps; gsettings covers GTK apps.
  home.pointerCursor = {
    enable = true;
    name = "volantes_cursors"; # XCursor 主题名（下划线）
    package = pkgs.volantes-cursors; # nixpkgs 属性名（连字符）
    size = 24;
  };

  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };
}
