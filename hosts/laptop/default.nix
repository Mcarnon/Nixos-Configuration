# Laptop host configuration.
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  my = {
    role = "laptop";
    hostName = "laptop";
    timeZone = "Asia/Shanghai";
  };

  # Boot loader (UEFI).
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Laptop-specific hardware/features.
  services.tlp.enable = true; # power management / battery saving
  hardware.bluetooth.enable = true;

  # Touchpad / libinput is configured together with the desktop environment.

  # TODO: enable your desktop environment here, e.g.:
  # services.xserver.enable = true;
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma6.enable = true;

  environment.systemPackages = with pkgs; [
    # ...
  ];
}
