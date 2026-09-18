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

  # ---- Audio: temporary legacy HDA pin (Huawei NbDE-WXX9 / MateBook D 15 2022) ----
  # History: the DSDT declares an Everest ES8336 codec at \_SB_.PC00.I2C2.ESSX
  # (ACPI I2C2 = PCI 00:15.2), a controller this board does not expose. The
  # codec is unreachable, but Intel SOF matches by ACPI HID, so it kept picking
  # the unusable `sof-essx8336` machine driver, which then asked for
  # `intel/sof-tplg/sof-tgl-es8336-dmic2ch.tplg` — a name current sof-bin
  # releases no longer ship (only the -ssp0/-ssp1/-ssp2 variants) — and the
  # probe died with -ENOENT: no sound card at all.
  # ./acpi-override.nix now renames that phantom HID away, which lets SOF fall
  # back to the HDA machine driver (`sof-hda-generic-2ch`, incl. the PCH DMIC
  # array). Until that override is verified on a real boot, this pin keeps the
  # legacy HDA driver in charge so audio cannot regress:
  #   dsp_driver = 0 auto / 1 legacy HDA / 2 SST / 3 SOF / 4 AVS
  # Verify the override with `ls /sys/bus/acpi/devices | grep ESSX` (expect
  # ESSX8337:00, no ESSX8336:00) and `journalctl -k -b | grep 'Table Upgrade'`,
  # then delete this block to hand the device back to SOF.
  boot.extraModprobeConfig = ''
    options snd-intel-dspcfg dsp_driver=1
  '';

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
