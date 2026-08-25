# Hardware + disk mounts (tmpfs root + LUKS-encrypted btrfs subvolumes)
#
#   - The root filesystem "/" is mounted as tmpfs and wiped on every reboot.
#   - /nix /var /etc /home /swap persist on btrfs subvolumes inside a single
#     LUKS container (one passphrase at boot). Swap is a swapfile, so it is
#     encrypted too.
#
# Before first install:
#   1. Partition and format as ESP (vfat) + LUKS-btrfs (use disko, see
#      disko-fs.nix — you'll be prompted to set the LUKS passphrase).
#   2. Find the LUKS / ESP UUIDs with `blkid` and replace <LUKS-UUID> / <ESP-UUID>.
#   3. If you want hibernation, measure the swapfile resume offset (see bottom).
{ config, pkgs, lib, ... }:
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

  # ---- LUKS unlock (prompted for the passphrase at boot) ----
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/<LUKS-UUID>";
    allowDiscards = true; # SSD TRIM; drop if you prefer stronger security
  };

  # ---- tmpfs root + btrfs subvolume mounts (on the unlocked mapper) ----

  # Root -> tmpfs (RAM), cleared on reboot
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=8G" "mode=755" ];
  };

  # All btrfs subvolumes live on the same unlocked LUKS mapper.
  fileSystems."/nix" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd" "noatime" ];
  };

  fileSystems."/var" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@var" "compress=zstd" "noatime" ];
  };

  fileSystems."/etc" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@etc" "compress=zstd" "noatime" ];
  };

  fileSystems."/home" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd" "noatime" ];
  };

  fileSystems."/swap" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@swap" "noatime" ];
  };

  # ESP (EFI system partition, unencrypted so UEFI/GRUB can load the kernel)
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/<ESP-UUID>";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  # ---- Swap (swapfile inside the encrypted btrfs) ----
  swapDevices = [ { device = "/swap/swapfile"; } ];

  # ---- Hibernation (optional) ----
  # resume from the unlocked mapper. After the first install, measure the
  # swapfile's resume offset and fill it in, then uncomment both lines:
  #   sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
  # boot.resumeDevice = "/dev/mapper/cryptroot";
  # boot.kernelParams = [ "resume_offset=<OFFSET>" ];
}
