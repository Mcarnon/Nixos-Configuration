# Home profile: common — every user on every host gets this (scale: cross-host reuse).
{ config, pkgs, lib, ... }:
{
  imports = [
    ../shell.nix
    ../packages
  ];

  programs.git = {
    enable = true;
    settings.user = {
      name = "Mcarnon";
      email = "3273556124@qq.com";
    };
  };
}
