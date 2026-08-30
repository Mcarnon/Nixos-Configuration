# Waybar-side helper scripts — wallpaper switching via awww.
# Ported from Sakurafall-arch/nixos-configuration（思路同 SHORiN）。
#
# Wallpaper source convention（同 Shorin 使用文档）: ~/Pictures/Wallpapers/
{ pkgs, ... }:
{
  wallpaper_random = pkgs.writeShellScriptBin "wallpaper_random" ''
    killall dynamic_wallpaper 2>/dev/null || true
    IMG=$(find "$HOME/Pictures/Wallpapers" -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" 2>/dev/null | shuf -n1)
    if [ -n "$IMG" ]; then
      ${pkgs.awww}/bin/awww img "$IMG" --transition-type random
    fi
  '';

  dynamic_wallpaper = pkgs.writeShellScriptBin "dynamic_wallpaper" ''
    while true; do
      IMG=$(find "$HOME/Pictures/Wallpapers" -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" 2>/dev/null | shuf -n1)
      if [ -n "$IMG" ]; then
        ${pkgs.awww}/bin/awww img "$IMG" --transition-type random
      fi
      sleep 120
    done
  '';

  default_wall = pkgs.writeShellScriptBin "default_wall" ''
    killall dynamic_wallpaper 2>/dev/null || true
    IMG=$(find "$HOME/Pictures/Wallpapers" -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" 2>/dev/null | head -1)
    if [ -n "$IMG" ]; then
      ${pkgs.awww}/bin/awww img "$IMG" --transition-type random
    fi
  '';
}
