# Clash Verge Rev — proxy GUI.
#
# The GUI cannot create the TUN device by itself: upstream splits that into a
# privileged helper (`clash-verge-service`). The nixpkgs module is the only
# supported way to install and supervise it, so the package must come from
# here (`environment.systemPackages`) rather than home-manager.
#
# - serviceMode: run `clash-verge-service` as a hardened systemd system
#   service (root) and expose its socket in /run/clash-verge-rev. This is what
#   the app's "install service" prompt is looking for.
# - tunMode: also grant the GUI wrapper CAP_NET_ADMIN/CAP_NET_RAW (needed for
#   Clash's DNS settings under TUN) and relax reverse-path filtering to
#   "loose", which policy routing + systemd-resolved require.
{
  programs.clash-verge = {
    enable = true;
    serviceMode = true;
    tunMode = true;
    # Only this group may talk to the service socket; the desktop user is in
    # wheel (hosts/laptop/default.nix).
    group = "wheel";
  };
}
