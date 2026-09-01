# Hardware + disk mounts (tmpfs root + plain btrfs subvolumes)
#
#   - The root filesystem "/" is mounted as tmpfs and wiped on every reboot.
#   - /nix /var /etc /home /swap persist on btrfs subvolumes on the root
#     partition. Swap is a swapfile inside the @swap subvolume.
#
# Before first install:
#   1. Partition and format as ESP (vfat) + btrfs (use disko, see disko-fs.nix).
#   2. Find the ROOT / ESP UUIDs with `blkid` and replace <ROOT-UUID> / <ESP-UUID>.
#   3. If you want hibernation, measure the swapfile resume offset (see bottom).
{
  config,
  pkgs,
  lib,
  ...
}:
{
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usb_storage"
    "sd_mod"
    "rtsx_pci" # card reader on some laptops
  ];
  boot.kernelModules = [ "kvm-intel" ];

  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  # ---- tmpfs root + btrfs subvolume mounts (on the root partition) ----

  # Root -> tmpfs (RAM), cleared on reboot
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=8G"
      "mode=755"
    ];
  };

  # All btrfs subvolumes live on the same root partition.
  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/<ROOT-UUID>";
    fsType = "btrfs";
    options = [
      "subvol=@nix"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/var" = {
    device = "/dev/disk/by-uuid/<ROOT-UUID>";
    fsType = "btrfs";
    options = [
      "subvol=@var"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/etc" = {
    device = "/dev/disk/by-uuid/<ROOT-UUID>";
    fsType = "btrfs";
    options = [
      "subvol=@etc"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/<ROOT-UUID>";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/swap" = {
    device = "/dev/disk/by-uuid/<ROOT-UUID>";
    fsType = "btrfs";
    options = [
      "subvol=@swap"
      "noatime"
    ];
  };

  # ESP (EFI system partition; UEFI/GRUB loads the kernel from here)
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/<ESP-UUID>";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  # ---- Swap (swapfile inside the btrfs @swap subvolume) ----
  swapDevices = [ { device = "/swap/swapfile"; } ];

  # ---- Hibernation (optional) ----
  # Resume from the root partition. After the first install, measure the
  # swapfile's resume offset and fill it in, then uncomment both lines:
  #   sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
  # boot.resumeDevice = "/dev/disk/by-uuid/<ROOT-UUID>";
  # boot.kernelParams = [ "resume_offset=<OFFSET>" ];
}
