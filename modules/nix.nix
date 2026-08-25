# Nix / store settings: flakes, store optimise, GC, and the Noctalia cache.
{ config, pkgs, lib, ... }:
{
  nixpkgs.config.allowUnfree = true;

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

  # nh: friendlier nixos-rebuild wrapper (`nh os switch`, `nh os boot`, ...).
  programs.nh = {
    enable = true;
    # Where this flake lives on the machine (matches sync.sh's REMOTE_DIR).
    flake = "/home/mccarnon/loliconOS"; # TODO: adjust to your local checkout path
    # nh.clean left off — `nix.gc` above already handles store cleanup.
  };

  # nix-ld: run prebuilt (non-Nix) binaries without "library not found" errors.
  programs.nix-ld.enable = true;
  # When some binary complains about a missing .so, add the providing package:
  # programs.nix-ld.libraries = with pkgs; [ ];
}
