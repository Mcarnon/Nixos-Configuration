# 笔记本电源 / 蓝牙 / 固件管理
{ config, pkgs, lib, ... }:
{
  # 蓝牙
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # 电源与硬件抽象 (Noctalia 的电池/电源面板依赖这些)
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Intel 温控
  services.thermald.enable = true;

  # 固件升级 (华为部分机型通过 fwupd 下发固件)
  services.fwupd.enable = true;

  # 合盖挂起
  services.logind.lidSwitch = "suspend";
  services.logind.lidSwitchExternalPower = "suspend";
}
