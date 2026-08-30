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
  locales = {
    defaultLocale = "zh_CN.UTF-8";
    zh-cn.enable = true;
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
      "seat"
      "seatd"
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
