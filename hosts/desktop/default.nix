# Desktop.
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/desktop.nix
  ];

  networking.hostName = "desktop";

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # TODO: replace hardware-configuration.nix with the desktop's real hardware,
  # and add GPU-specific config here (NVIDIA/AMD) if needed.
}
