# Laptop power / bluetooth / firmware management
{ config, pkgs, lib, ... }:
{
  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Power & hardware abstraction (Noctalia's battery/power panel depends on these)
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Intel thermal management
  services.thermald.enable = true;

  # Firmware updates (some laptops ship firmware via fwupd)
  services.fwupd.enable = true;

  # Lid close: suspend. Hibernation is not wired up yet (the swapfile resume
  # offset in hosts/laptop/hardware-configuration.nix is still commented out),
  # so don't use "suspend-then-hibernate" here until resume is configured.
  services.logind.settings = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
  };

  # Time spent suspended before falling through to hibernate. Only relevant
  # once HandleLidSwitch is set back to "suspend-then-hibernate".
  systemd.sleep.settings.Sleep.HibernateDelaySec = "2h";
}
