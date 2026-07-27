{ config, pkgs, lib, username, ... }:

{
  # === 引导 ===
  # NixOS 不管理引导，由 Arch 的 GRUB 统一管理
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = false;

  # === 网络 ===
  networking.networkmanager.enable = true;

  # === 时区和语言 ===
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "zh_CN.UTF-8";

  # === 用户 ===
  users.users.mccarnon = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.bash;
  };

  # === 系统包 ===
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
  ];

  # === 音频 (PipeWire) ===
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # === Snapper (Btrfs 快照) ===
  services.snapper = {
    configs.root = {
      SUBVOLUME = "/";
      TIMELINE_CREATE = false;
      TIMELINE_CLEANUP = true;
      TIMELINE_MIN_AGE = "1800";
    };
  };


  # === Nix 设置 ===
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # === 系统版本 ===
  system.stateVersion = "26.05";
}
