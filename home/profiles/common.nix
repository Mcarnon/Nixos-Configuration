# Home profile: common — every user on every host gets this (scale: cross-host reuse).
{ config, pkgs, lib, ... }:
{
  imports = [
    ../shell.nix
    ../packages
  ];

  programs.git = {
    enable = true;
    userName = "Mcarnon";
    userEmail = "3273556124@qq.com";
  };
}
