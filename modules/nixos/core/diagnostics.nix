# Maintenance / diagnostics tools.
#
# These are NOT part of the desktop experience; they exist so `lspci`, `aplay`,
# `smartctl`, etc. are always available when troubleshooting hardware, instead
# of reaching for a one-off `nix-shell -p ...`. The one exception is gparted:
# partitioning needs root (+ polkit), so it belongs to the system, not to a
# home-manager profile.
{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # bus / device enumeration
    pciutils # lspci
    usbutils # lsusb
    dmidecode # BIOS / board info

    # storage health
    smartmontools # smartctl
    nvme-cli # nvme list / smart-log

    # partitioning (GUI). gparted escalates through polkit itself — the desktop
    # entry just runs it as you and polkit-gnome asks for the password.
    # withAllTools: nixpkgs only bundles dosfstools/e2fsprogs/util-linux by
    # default, which leaves out btrfs-progs (this root is btrfs), ntfs3g,
    # exfatprogs, xfsprogs, cryptsetup (LUKS) and lvm2.
    (gparted.override { withAllTools = true; })

    # audio
    alsa-utils # aplay, amixer, speaker-test
    wireplumber # wpctl (PipeWire session/routing)

    # power / thermal (laptop)
    powertop
    lm_sensors # sensors

    # system overview
    inxi # inxi -F
    lsof
  ];
}
