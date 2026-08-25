# Firewall — security boundary (default-closed) + perf (no conntrack helpers).
{ config, pkgs, lib, ... }:
{
  networking.firewall = {
    enable = true;
    # Only SSH for sync.sh / remote deploy; host can append more via `networking.firewall.allowedTCPPorts`.
    allowedTCPPorts = [ 22 ];
    autoLoadConntrackHelpers = false;
  };
}
