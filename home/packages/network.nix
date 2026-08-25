# Network / proxy tools.
{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    # proxy GUI (bundles its own core; add your subscription inside the app).
    # TUI usage: fish `proxy_on` / `proxy_off` (see home/shell.nix)
    clash-verge-rev
  ];
}
