# User environment (Home Manager)
{ config, pkgs, inputs, lib, ... }:
{
  imports = [
    ./niri.nix
    ./noctalia.nix
  ];

  # Set once at first install and never bump (independent of system.stateVersion).
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    # terminal
    foot
    # file manager (niri's portal file picker also depends on it)
    nautilus
    # screenshots
    grim
    slurp
    # clipboard
    wl-clipboard
    # volume control (fallback; Noctalia has its own OSD)
    pamixer
    # common utilities
    xdg-utils
    tree
  ];

  programs.git = {
    enable = true;
    # userName = "Your Name";
    # userEmail = "you@example.com";
  };
}
