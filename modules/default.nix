# Shared base configuration imported by every host.
{ config, lib, pkgs, ... }:
let
  username = "mccarnon";
in
{
  system.stateVersion = "26.05";

  # Locale & timezone.
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Asia/Shanghai";

  # Nix.
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Network.
  networking.networkmanager.enable = true;

  # Firmware for Wi-Fi / GPU / Bluetooth.
  hardware.enableAllFirmware = true;

  # Primary user account.
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    # First boot: log in with "changeme" then run `passwd` (or use SSH keys).
    initialPassword = "1234";
  };

  # Home-manager for the primary user.
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${username} = {
      imports = [ ../home ];
      home.username = username;
      home.stateVersion = config.system.stateVersion;
    };
  };
}
