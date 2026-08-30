# Modern CLI tools (user-level). Rescue/root tools stay in modules/nixos/core/.
{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    bat # cat with syntax highlight
    yazi # TUI file manager
    lazygit # git TUI
    btop # resource monitor (replaces htop for daily use)
    fastfetch # system info banner
    jq # JSON processing (used by home/files/f.fish waifu fetcher)
    tree # directory tree
  ];
}
