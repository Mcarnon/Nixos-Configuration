# Hardware HAL: NVIDIA (stub for next host with dGPU)
{ config, pkgs, lib, ... }:
let
  cfg = config.hardware.nvidia;
in
{
  options.hardware.nvidia.enable = lib.mkEnableOption "NVIDIA GPU stack";

  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      open = false;
    };
  };
}
