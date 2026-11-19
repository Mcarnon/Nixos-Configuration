# Network / proxy tools.
#
# FlClash is the only proxy GUI (pkgs/flclash, official .deb unpacked). Clash
# Verge Rev used to live here as well; it was dropped once FlClash's privileged
# helper was declared in modules/nixos/desktop/flclash.nix.
#
# The GUI itself is unprivileged. TUN mode goes through the `flclash-helper`
# system service, which runs the Core as root for the account listed there.
#
# TUI usage: fish `proxy_on` / `proxy_off` (modules/home/shell/fish.nix), which
# default to FlClash's mixed port 7890.
{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.flclash ];
}
