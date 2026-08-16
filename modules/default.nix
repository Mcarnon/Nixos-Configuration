# Shared base configuration imported by every host.
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ./options.nix
    ./locale.nix
    ./nix.nix
    ./network.nix
    ./security.nix
    ./users.nix
    ./home-manager.nix
  ];

  # Set this to the NixOS release of your *first* install and leave it alone.
  # It only controls backwards-compatible defaults for stateful services.
  system.stateVersion = "24.11";

  # Include non-free firmware for common Wi-Fi / GPU devices.
  hardware.enableAllFirmware = true;
}
