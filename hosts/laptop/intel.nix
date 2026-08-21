# Intel CPU + Iris Xe iGPU
{ config, pkgs, lib, ... }:
{
  # Intel CPU microcode updates
  hardware.cpu.intel.updateMicrocode = true;

  # Graphics stack (old name hardware.opengl, new name hardware.graphics)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver # VA-API (iHD driver for Iris Xe)
      # intel-compute-runtime # OpenCL, large, enable on demand
    ];
  };

  environment.sessionVariables = {
    # Force the iHD driver (Iris Xe is Gen12+)
    LIBVA_DRIVER_NAME = "iHD";
  };

  # Debug tools (e.g. intel_gpu_top)
  environment.systemPackages = with pkgs; [
    intel-gpu-tools
  ];
}
