# User environment (Home Manager)
{ config, pkgs, inputs, lib, ... }:
{
  imports = [
    ./niri.nix
    ./noctalia.nix
    ./shell.nix
    ./cli.nix
  ];

  home.stateVersion = "26.11"; # TODO: keep in sync with the host stateVersion

  home.packages = with pkgs; [
    # terminal
    foot
    # file manager (niri's portal file picker also depends on it)
    nautilus
    # browser
    firefox
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
    # proxy GUI (bundles its own core; add your subscription inside the app).
    # TUI usage: fish `proxy_on` / `proxy_off` (see home/shell.nix)
    clash-verge-rev
  ];

  programs.git = {
    enable = true;
    userName = "Mcarnon";
    userEmail = "3273556124@qq.com";
  };
}
