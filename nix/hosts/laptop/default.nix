{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "laptop";

  # Intel Iris Xe 集显
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-compute-runtime
  ];

  # 电源管理
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    };
  };

  # 触控板
  services.xserver.libinput.enable = true;
}
