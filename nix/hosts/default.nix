# NixOS 系统配置
{ config, pkgs, lib, users, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # 引导配置
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # 网络
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # 时区和语言
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "zh_CN.UTF-8";

  # 用户配置
  users.users = builtins.mapAttrs (name: userData: {
    isNormalUser = true;
    description = userData.fullName;
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.bash;
  }) users;

  # 系统包
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
    firefox
  ];

  # 启用 flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # 系统版本
  system.stateVersion = "24.05";
}
