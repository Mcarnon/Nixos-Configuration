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

  # Lid close: suspend first, hibernate after HibernateDelaySec (below).
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend";
  };

  # Time spent suspended before falling through to hibernate.
  systemd.sleep.settings.Sleep.HibernateDelaySec = "2h";
}
