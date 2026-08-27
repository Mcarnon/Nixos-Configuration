# Hardware HAL: disko template documentation
# Hosts keep disko-fs.nix under hosts/<host>/ (device + LUKS + btrfs subvols).
# This file is a shared reference for the hardware abstraction layer.
{
  config,
  pkgs,
  lib,
  ...
}:
{
  # No options — see hosts/laptop/disko-fs.nix for the concrete layout.
}
