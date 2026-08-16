# ==============================================================================
#  HARDWARE CONFIGURATION — REPLACE THIS FILE
# ==============================================================================
#  This is only a placeholder so the configuration still evaluates.
#
#  On the real machine run:
#
#      sudo nixos-generate-config --show-hardware-config
#
#  and paste its output into this file. It contains the correct kernel modules,
#  filesystem layout, swap devices and CPU microcode for your hardware.
# ==============================================================================
{ config, lib, pkgs, ... }:
{
  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
