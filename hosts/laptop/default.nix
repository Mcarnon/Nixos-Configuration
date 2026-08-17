# Laptop (Intel Tiger Lake ultrabook).
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/desktop.nix
  ];

  networking.hostName = "laptop";

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Laptop-specific hardware.
  hardware.bluetooth.enable = true;
  hardware.firmware = [ pkgs.sof-firmware ]; # Intel SOF audio (Tiger Lake)
  zramSwap.enable = true;
  services.thermald.enable = true;
}
