# GUI / desktop applications.
{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    foot # Wayland terminal emulator
    nautilus # file manager (niri's portal file picker also depends on it)
    firefox # browser
    xdg-utils # xdg-open & friends
  ];
}
