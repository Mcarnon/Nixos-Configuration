# Network: NetworkManager for Wi-Fi/Ethernet, systemd-resolved for DNS.
{ config, pkgs, ... }:
{
  networking.networkmanager = {
    enable = true;
    # Hand DNS over to systemd-resolved (per-link DNS; more reliable on a
    # laptop that roams between networks than the plain glibc resolver).
    dns = "systemd-resolved";
  };

  services.resolved.enable = true;
  # CN-friendly fallback servers when no DNS is pushed by the network.
  services.resolved.fallbackDns = [
    "223.5.5.5" # AliDNS
    "119.29.29.29" # DNSPod
  ];

  # Allow inbound SSH so scripts/sync.sh and remote deploys work over LAN.
  networking.firewall.allowedTCPPorts = [ 22 ];
}
