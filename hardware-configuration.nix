# 硬件 + 磁盘挂载 (tmpfs 根 + btrfs 子卷)
#
#   - 根文件系统 "/" 挂载为 tmpfs, 每次重启清空。
#   - /nix /var /etc /home 分别在 btrfs 子卷上持久化。
#
# 首次安装前需要:
#   1. 分区并格式化为 ESP(vfat) + btrfs。
#   2. 在 btrfs 分区上创建子卷 @nix @var @etc @home (见 scripts/setup-btrfs.sh)。
#   3. 用 `blkid` 找到 UUID, 替换下面的 <BTRFS-UUID> / <ESP-UUID>。
{ config, pkgs, lib, ... }:
{
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usb_storage"
    "sd_mod"
    "rtsx_pci" # 部分华为机型读卡器
  ];
  boot.kernelModules = [ "kvm-intel" ];

  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  # ---- tmpfs 根 + btrfs 子卷挂载 ----

  # 根分区 -> tmpfs (内存), 重启后清空
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=8G" "mode=755" ];
  };

  # 下面四个 btrfs 子卷共用同一个分区 UUID (btrfs 分区)
  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/<BTRFS-UUID>";
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd" "noatime" ];
  };

  fileSystems."/var" = {
    device = "/dev/disk/by-uuid/<BTRFS-UUID>";
    fsType = "btrfs";
    options = [ "subvol=@var" "compress=zstd" "noatime" ];
  };

  fileSystems."/etc" = {
    device = "/dev/disk/by-uuid/<BTRFS-UUID>";
    fsType = "btrfs";
    options = [ "subvol=@etc" "compress=zstd" "noatime" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/<BTRFS-UUID>";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd" "noatime" ];
  };

  # ESP (EFI 系统分区)
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/<ESP-UUID>";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  # 可选 swap 分区 (按需取消注释)
  # swapDevices = [ { device = "/dev/disk/by-uuid/<SWAP-UUID>"; } ];
}
