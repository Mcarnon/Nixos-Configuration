# User environment (Home Manager)
{ config, pkgs, inputs, lib, ... }:
{
  imports = [
    ./niri.nix
    ./noctalia.nix
    ./shell.nix
    ./packages
  ];

  home.stateVersion = "26.11"; # TODO: keep in sync with the host stateVersion

  programs.git = {
    enable = true;
    userName = "Mcarnon";
    userEmail = "3273556124@qq.com";
  };
}
