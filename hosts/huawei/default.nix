# Host main config: user / boot / network / Nix settings / Home Manager wiring
{ config, pkgs, inputs, lib, ... }:

let
  # TODO: change to your username
  userName = "alice";
in
{
  imports = [
    ./hardware-configuration.nix
    ./intel.nix
    ../../modules
    ../../chinese.nix
  ];

  # ---- Boot ----
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "btrfs" ];
  # tmpfs root mode requires systemd in the initrd (see hardware-configuration.nix)
  boot.initrd.systemd.enable = true;

  # ---- Network / host ----
  networking.hostName = "huawei"; # TODO: change as needed
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Shanghai";

  # ---- User ----
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

  # ---- Wayland / niri environment variables ----
  # Ozone Wayland: Electron/Chromium apps automatically use Wayland
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

  # ---- Nix settings ----
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

  # TODO: set to the NixOS version at first install (affects upgrade compatibility)
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
