# User environment (Home Manager)
{ config, pkgs, inputs, lib, ... }:
{
  imports = [
    ./niri.nix
    ./noctalia.nix
  ];

  home.stateVersion = "26.05"; # TODO: keep in sync with the host stateVersion

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
  };wipefs
