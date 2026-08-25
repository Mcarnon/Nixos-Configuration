# Modern CLI tools (user-level). Rescue/root tools stay in modules/packages/.
{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    bat # cat with syntax highlight
    yazi # TUI file manager
    lazygit # git TUI
    btop # resource monitor (replaces htop for daily use)
    fastfetch # system info banner
    tree # directory tree
  ];
}
