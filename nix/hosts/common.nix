{ config, pkgs, lib, username, ... }:

{
  # 引导配置
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # 网络
  networking.networkmanager.enable = true;

  # 时区和语言
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "zh_CN.UTF-8";

  # 用户配置
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.bash;
  };

  # 系统包（最小化，用户环境由 Home Manager 管理）
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
  ];

  # 启用 flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # 系统版本
  system.stateVersion = "24.05";
}
