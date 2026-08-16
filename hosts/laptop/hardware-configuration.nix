# Hardware configuration for the laptop — Intel Tiger Lake ultrabook.
#
# Detected live on 2026-08-17 from a running Arch Linux install:
#   - CPU:     Intel Core i5-1155G7 (11th Gen, Tiger Lake)
#   - GPU:     Intel Iris Xe (i915)
#   - Wi-Fi:   Intel Wi-Fi 6 AX201 (iwlwifi)
#   - Storage: Phison E12 NVMe SSD (nvme0n1)
#   - Disk:    nvme0n1p1 = EFI (vfat), nvme0n1p2 = btrfs (subvol @ and @home)
#   - Swap:    zram (configured in hosts/laptop/default.nix)
#
# You can also regenerate this file from a NixOS live ISO with:
#   sudo nixos-generate-config --show-hardware-config
{ config, lib, pkgs, ... }:
{
  boot.initrd.availableKernelModules = [
    "xhci_pci" # USB 3.2 controller
    "nvme" # NVMe SSD (root device)
    "usbhid" # USB keyboard / mouse
    "usb_storage" # USB mass storage (e.g. installer media)
    "sd_mod" # SD card reader
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Intel microcode updates for the i5-1155G7.
  hardware.cpu.intel.updateMicrocode = true;

  # Root filesystem: btrfs subvolume "@".
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/3a2a875a-c9c2-4191-951e-5b9a4766e4db";
    fsType = "btrfs";
    options = [
      "subvol=@"
      "compress=zstd:3"
      "discard=async"
    ];
  };

  # Home filesystem: btrfs subvolume "@home".
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/3a2a875a-c9c2-4191-951e-5b9a4766e4db";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress=zstd:3"
      "discard=async"
    ];
  };

  # EFI system partition.
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/DD9D-E39B";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # No on-disk swap partitions; zram is enabled in hosts/laptop/default.nix.
  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
