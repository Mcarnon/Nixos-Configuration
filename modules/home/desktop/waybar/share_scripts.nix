# Waybar-side helper scripts, vendored from Sakurafall-arch/nixos-configuration
# (themselves derived from SHORiN's shorin-arch-setup). Each becomes a real
# package on PATH so waybar/niri binds can call them by name.
#
# Wallpaper source convention: drop images into ~/Pictures/wallpaper/ — the
# scripts pick a random one and hand it to awww (Wayland wallpaper daemon).
{ pkgs, ... }:
{
  wallpaper_random = pkgs.writeShellScriptBin "wallpaper_random" ''
    killall dynamic_wallpaper 2>/dev/null || true
    IMG=$(find "$HOME/Pictures/wallpaper" -name "*.png" -o -name "*.jpg" 2>/dev/null | shuf -n1)
    if [ -n "$IMG" ]; then
      ${pkgs.awww}/bin/awww img "$IMG" --transition-type random
    fi
  '';

  dynamic_wallpaper = pkgs.writeShellScriptBin "dynamic_wallpaper" ''
    while true; do
      IMG=$(find "$HOME/Pictures/wallpaper" -name "*.png" -o -name "*.jpg" 2>/dev/null | shuf -n1)
      if [ -n "$IMG" ]; then
        ${pkgs.awww}/bin/awww img "$IMG" --transition-type random
      fi
      sleep 120
    done
  '';

  default_wall = pkgs.writeShellScriptBin "default_wall" ''
    killall dynamic_wallpaper 2>/dev/null || true
    IMG=$(find "$HOME/Pictures/wallpaper" -name "*.png" -o -name "*.jpg" 2>/dev/null | head -1)
    if [ -n "$IMG" ]; then
      ${pkgs.awww}/bin/awww img "$IMG" --transition-type random
    fi
  '';
}
