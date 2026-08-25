# Hardware HAL: Intel CPU + Iris Xe iGPU
# Security: microcode updates; Performance: VA-API / GPU tools.
{ config, pkgs, lib, ... }:
let
  cfg = config.hardware.intel;
in
{
  options.hardware.intel.enable = lib.mkEnableOption "Intel CPU microcode + Iris Xe graphics stack";

  config = lib.mkIf cfg.enable {
    hardware.cpu.intel.updateMicrocode = true;

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-gpu-tools
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };

    environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
  };
}
