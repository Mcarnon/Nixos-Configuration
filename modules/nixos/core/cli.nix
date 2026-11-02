# Base CLI tools available system-wide (and to root via sudo).
# Hardware diagnostics live in diagnostics.nix; GUI apps live in home/packages/.
{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    rsync
    btrfs-progs
    file
    htop
    # legacy `arp`/`ifconfig`/`netstat`/`route`; `ip`/`arping` come from
    # iproute2/iputils. Prefer `ip neigh` over `arp`. `sudo arping` for raw ARP.
    net-tools
  ];
}
