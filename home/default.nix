# User environment (Home Manager) — thin entry (scale: host picks a role).
{ config, pkgs, inputs, lib, ... }:
{
  imports = [
    ../roles/home/desktop.nix
  ];

  home.stateVersion = "26.11"; # TODO: keep in sync with the host stateVersion
}
