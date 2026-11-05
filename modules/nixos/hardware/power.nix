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
  # Blueman：GTK 图形管理器 + org.blueman.Mechanism D-Bus/polkit 后端。
  # 托盘图标在 home/niri/startup.kdl 里 spawn（与 nm-applet 同一套模式）。
  services.blueman.enable = true;

  # Power & hardware abstraction（Clavis 电池/电源面板依赖这些）
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
