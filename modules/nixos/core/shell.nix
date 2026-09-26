# System-wide fish shell (root & rescue).
# User-level fish/starship/direnv/proxy config lives in modules/home/shell/.
{ config, pkgs, ... }:
{
  programs.fish.enable = true;
}
