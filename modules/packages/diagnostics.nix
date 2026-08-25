# Maintenance / diagnostics tools.
#
# These are NOT part of the desktop experience; they exist so `lspci`, `aplay`,
# `smartctl`, etc. are always available when troubleshooting hardware, instead
# of reaching for a one-off `nix-shell -p ...`.
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
