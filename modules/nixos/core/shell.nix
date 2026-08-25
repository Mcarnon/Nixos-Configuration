# System-wide fish shell.
# User-level fish/starship/direnv/proxy config lives in home/shell.nix.
{ config, pkgs, ... }:
{
  programs.fish.enable = true;
}
