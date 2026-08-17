# 占位 —— 在真实机器上运行并覆盖本文件：
#
#   sudo nixos-generate-config --show-hardware-config
#
# 生成的内容包含：启动内核模块、文件系统、交换分区、CPU 微码等。
{ config, lib, ... }:
{
  boot.initrd.availableKernelModules = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos"; # TODO: 替换为实际设备
    fsType = "ext4";
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
