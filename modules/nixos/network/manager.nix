# Network: NetworkManager for Wi-Fi/Ethernet, systemd-resolved for DNS.
# Security: firewall default-closed, only SSH explicitly opened; Performance:
# resolved caching.
{ config, pkgs, ... }:
{
  networking.networkmanager = {
    enable = true;
    # Hand DNS over to systemd-resolved (per-link DNS; more reliable on a
    # laptop that roams between networks than the plain glibc resolver).
    dns = "systemd-resolved";
  };

  services.resolved = {
    enable = true;
    settings.Resolve = {
      Cache = "yes";
      CacheFromLocalhost = "yes";
      FallbackDNS = "223.5.5.5 119.29.29.29"; # AliDNS + DNSPod (space-separated)
    };
  };

  # Firewall is in ../security/firewall.nix (kept separate for security audit).
}
