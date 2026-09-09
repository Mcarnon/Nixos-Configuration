# This file is the "host manifest": only host-specific choices live here
# (identity, user, locale, stateVersion, session env, Home Manager wiring).
# All reusable "how" lives in ../../modules, imported below.
{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

let
  userName = "mccarnon"; # TODO: your username
in
{
  imports = [
    ./hardware-configuration.nix
    ../../roles/nixos/desktop.nix
  ];

  # Hardware HAL — single toggle per vendor (scale: add `hardware.nvidia.enable` for next host)
  hardware.intel.enable = true;

  # ---- Identity ----
  networking.hostName = "loliconOS"; # TODO: change as needed
  time.timeZone = "Asia/Shanghai";
  system.stateVersion = "26.11"; # pinned at first install; do NOT bump on upgrade

  # ---- Locale / environment ----
  # 系统默认语言为英语（en_US.UTF-8），避免地区特定路径/配置兼容问题。
  # 中文作为可选的扩展语言包：需要时把 defaultLocale 改为 "zh_CN.UTF-8"
  # 并开启 zh-cn.enable = true（会安装 rime 拼音输入法 + CJK 字体）。
  locales = {
    defaultLocale = "en_US.UTF-8";
    zh-cn.enable = false;
  };

  # ---- User ----
  users.users.${userName} = {
    isNormalUser = true;
    description = "Laptop user";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
      "render"
      "dialout"
    ];
    shell = pkgs.fish; # enabled in modules/shell.nix, configured in home/shell.nix
    # First-login password placeholder (plaintext lands in the Nix store —
    # change it right after first login with `passwd`).
    initialPassword = "nixos";
  };

  # ---- Wayland / niri environment variables ----
  environment.sessionVariables = {
    NIXOS_OZONE_WAYLAND = "1";
    XDG_CURRENT_DESKTOP = "niri";
    XMODIFIERS = "@im=fcitx";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
  };

  # ---- Home Manager wired in as a NixOS module ----
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
      hostPath = ./.;
    };
    users.${userName} = {
      imports = [ ../../home ];
    };
  };
}
