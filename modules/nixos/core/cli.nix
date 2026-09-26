# Base CLI tools available system-wide (and to root via sudo).
# Hardware diagnostics live in diagnostics.nix; GUI apps live in home/packages/.
{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    rsync
    btrfs-progs
    file
    htop
  ];
}
