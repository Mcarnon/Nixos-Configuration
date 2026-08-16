# Desktop host configuration.
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  my = {
    role = "desktop";
    hostName = "desktop";
    timeZone = "Asia/Shanghai";
  };

  # Boot loader (UEFI).
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # TODO: enable your desktop environment here, e.g.:
  # services.xserver.enable = true;
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma6.enable = true;

  # System-wide packages (CLI tools, desktop apps, ...).
  environment.systemPackages = with pkgs; [
    # ...
  ];
}
