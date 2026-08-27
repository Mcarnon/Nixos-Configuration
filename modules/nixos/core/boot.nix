# Boot: GRUB (EFI) + initrd systemd.
# `device = "nodev"` = 不写 MBR，安装到 ESP（/boot，见 hosts/laptop/disko-fs.nix）。
# `boot.initrd.systemd` is required by the tmpfs-root scheme in
# hardware-configuration.nix (root is a tmpfs mounted from the initrd).
# Hibernation resume is host-specific (LUKS mapper + swapfile offset), so it
# lives in hosts/laptop/hardware-configuration.nix.
{
  config,
  pkgs,
  lib,
  ...
}:
{
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    useOSProber = true; # 自动检测其他系统（Windows 等），不需要可删
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "btrfs" ];
  boot.initrd.systemd.enable = true;
}
