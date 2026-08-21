# Host main config: user / boot / network / Nix settings / Home Manager wiring
{ config, pkgs, inputs, lib, ... }:

let
  # TODO: change to your username
  userName = "mccarnon";
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
  networking.hostName = "nixos"; # TODO: change as needed
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Shanghai";

  # ---- User ----
  users.users.${userName} = {
    isNormalUser = true;
    description = "Laptop user";
    # Only applied when the user account is first created; change it after first login
    initialPassword = "1234";
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
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Set once at first install and never bump (it controls upgrade compatibility).
  system.stateVersion = "26.05";

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
