# VM (for testing in QEMU/KVM).
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "nixos-vm";

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # QEMU guest integration.
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # SSH for maintenance from the host.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
}
