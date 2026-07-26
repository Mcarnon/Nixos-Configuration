{ config, pkgs, lib, username, ... }:

{
  imports = [
    ./packages.nix
    ./programs/git.nix
    ./programs/bash.nix
    ./programs/neovim.nix
    ./programs/alacritty.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "26.05";
  };

  programs.home-manager.enable = true;
}
