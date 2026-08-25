# User environment (Home Manager) — thin entry (scale: host picks a profile).
{ config, pkgs, inputs, lib, ... }:
{
  imports = [
    ./profiles/desktop.nix
  ];

  home.stateVersion = "26.11"; # TODO: keep in sync with the host stateVersion
}
