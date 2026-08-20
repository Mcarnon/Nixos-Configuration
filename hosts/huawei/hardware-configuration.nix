# Hardware + disk mounts (tmpfs root + btrfs subvolumes)
#
#   - The root filesystem "/" is mounted as tmpfs and wiped on every reboot.
#   - /nix /var /etc /home persist on dedicated btrfs subvolumes.
#
# Before first install:
#   1. Partition and format as ESP (vfat) + btrfs (use disko, see disko-fs.nix).
#   2. Create subvolumes @nix @var @etc @home on the btrfs partition.
#   3. Find the UUIDs with `blkid` and replace <BTRFS-UUID> / <ESP-UUID> below.
{ config, pkgs, lib, ... }:
{
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usb_storage"
    "sd_mod"
    "rtsx_pci" # card reader on some Huawei models
  ];
  boot.kernelModules = [ "kvm-intel" ];

  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  # ---- tmpfs root + btrfs subvolume mounts ----

  # Root -> tmpfs (RAM), cleared on reboot
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=8G" "mode=755" ];
  };

  # All four btrfs subvolumes share the same partition UUID (the btrfs partition)
  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/<BTRFS-UUID>";
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd" "noatime" ];
  };

  fileSystems."/var" = {
    device = "/dev/disk/by-uuid/<BTRFS-UUID>";
    fsType = "btrfs";
    options = [ "subvol=@var" "compress=zstd" "noatime" ];
  };

  fileSystems."/etc" = {
    device = "/dev/disk/by-uuid/<BTRFS-UUID>";
    fsType = "btrfs";
    options = [ "subvol=@etc" "compress=zstd" "noatime" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/<BTRFS-UUID>";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd" "noatime" ];
  };

  # ESP (EFI system partition)
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/<ESP-UUID>";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  # Optional swap partition (uncomment if needed)
  # swapDevices = [ { device = "/dev/disk/by-uuid/<SWAP-UUID>"; } ];
}
