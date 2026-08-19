# Intel CPU + Iris Xe 核显
{ config, pkgs, lib, ... }:
{
  # Intel CPU 微码更新
  hardware.cpu.intel.updateMicrocode = true;

  # 图形栈 (旧名 hardware.opengl, 新名 hardware.graphics)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver # VA-API (Iris Xe 用 iHD 驱动)
      intel-gpu-tools    # intel_gpu_top 等调试工具
      vaapiVdpau
      libvdpau-va-gl
      # intel-compute-runtime # OpenCL, 体积较大, 按需开启
    ];
  };

  environment.sessionVariables = {
    # 强制使用 iHD 驱动 (Iris Xe 属于 Gen12+)
    LIBVA_DRIVER_NAME = "iHD";
  };
}
