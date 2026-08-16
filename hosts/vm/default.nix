# VM host configuration (for testing the setup in QEMU/KVM, VirtualBox, ...).
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  my = {
    role = "vm";
    hostName = "nixos-vm";
    timeZone = "Asia/Shanghai";
  };

  # Boot loader. Uses UEFI; if your VM is BIOS-only, switch to GRUB instead:
  # boot.loader.grub = {
  #   enable = true;
  #   device = "/dev/vda";
  # };
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # QEMU guest agent + SPICE clipboard/resize support.
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # SSH access so you can rebuild the VM from the host.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  environment.systemPackages = with pkgs; [
    # ...
  ];
}
