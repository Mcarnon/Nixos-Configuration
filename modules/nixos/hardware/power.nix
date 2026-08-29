# Laptop power / bluetooth / firmware management
{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Power & hardware abstraction (Clavis' battery/power panel depends on these)
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Intel thermal management
  services.thermald.enable = true;

  # Firmware updates (some laptops ship firmware via fwupd)
  services.fwupd.enable = true;

  # Lid close: suspend. Hibernation is optional on this host and is not
  # configured (no boot.resumeDevice / resume_offset); see
  # hosts/laptop/hardware-configuration.nix if you want to enable it.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
  };
}
