# Profile: base — minimal host (no GUI)
# Performance: smallest closure; Security: hardening via security/* + secrets.
{ config, pkgs, lib, ... }:
{
  imports = [
    ../modules/system/boot.nix
    ../modules/system/kernel.nix
    ../modules/system/locales.nix
    ../modules/system/nix.nix
    ../modules/system/shell.nix
    ../modules/system/snapshot.nix
    ../modules/packages
    ../modules/services/network.nix
    ../modules/services/openssh.nix
    ../modules/security/secrets.nix
    ../modules/security/hardening.nix
    ../modules/security/firewall.nix
    ../modules/security/sops.nix
  ];
}
