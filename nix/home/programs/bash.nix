{ config, pkgs, lib, ... }:

{
  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      update = "USERNAME=mccarnon sudo nixos-rebuild switch --flake /etc/nixos#laptop";
    };
  };
}
