{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "desktop";

  # Intel Iris Xe 集显
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-compute-runtime
  ];
}
