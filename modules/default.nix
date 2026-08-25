# Compatibility shim: new code should import via `profiles/*` or per-domain `modules/<domain>/*`.
# This file keeps `imports = [ ../../modules ]` working for any legacy host.
{
  imports = [
    ./system/boot.nix
    ./system/kernel.nix
    ./system/locales.nix
    ./system/nix.nix
    ./system/shell.nix
    ./system/snapshot.nix
    ./packages
    ./services/network.nix
    ./services/openssh.nix
    ./services/niri.nix
    ./services/pipewire.nix
    ./services/laptop.nix
    ./security/secrets.nix
    ./security/hardening.nix
    ./security/firewall.nix
    ./security/sops.nix
    ./hardware/intel.nix
    ./hardware/nvidia.nix
    ./hardware/disko.nix
  ];
}
