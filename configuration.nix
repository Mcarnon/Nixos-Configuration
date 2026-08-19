# 主机主配置: 用户 / 引导 / 网络 / Nix 设置 / Home Manager 接线
{ config, pkgs, inputs, lib, ... }:

let
  # TODO: 改成你的用户名
  userName = "alice";
in
{
  imports = [
    ./hardware-configuration.nix
    ./chinese.nix
    ./modules
  ];

  # ---- 引导 ----
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "btrfs" ];
  # tmpfs 根模式需要在 initrd 里启用 systemd (见 hardware-configuration.nix)
  boot.initrd.systemd.enable = true;

  # ---- 网络 / 主机 ----
  networking.hostName = "huawei"; # TODO: 按需修改
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Shanghai";

  # ---- 用户 ----
  users.users.${userName} = {
    isNormalUser = true;
    description = "Huawei laptop user";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
      "render"
      "dialout"
    ];
    # shell = pkgs.fish;
  };

  # ---- Wayland / niri 环境变量 ----
  # Ozone Wayland: Electron/Chromium 应用自动走 Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WAYLAND = "1";
    XDG_CURRENT_DESKTOP = "niri";
  };

  # ---- Home Manager 作为 NixOS 模块接入 ----
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.${userName} = {
      imports = [ ./home ];
    };
  };

  # ---- Nix 设置 ----
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      extra-substituters = [ "https://noctalia.cachix.org" ];
      extra-trusted-public-keys = [
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # TODO: 改成你首次安装时的 NixOS 版本号 (影响后续升级兼容性)
  system.stateVersion = "25.05";

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    rsync
    btrfs-progs
    file
    htop
  ];
}
