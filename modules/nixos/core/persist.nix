# Btrfs snapshots via snapper for the persistent subvolumes.
#
# "/" is tmpfs here (see hosts/laptop/hardware-configuration.nix), so only
# /home /etc /var are worth snapshotting. System rollback is already covered
# by NixOS generations: pick an older entry in the GRUB menu or run
# `nixos-rebuild --rollback`.
#
# Usage:
#   sudo snapper -c home list            # list snapshots
#   sudo snapper -c home create          # manual pre-change snapshot
{
  config,
  pkgs,
  lib,
  ...
}:
let
  timeline = {
    TIMELINE_CREATE = true;
    TIMELINE_CLEANUP = true;
    TIMELINE_LIMIT_HOURLY = 10;
    TIMELINE_LIMIT_DAILY = 7;
    TIMELINE_LIMIT_WEEKLY = 4;
    TIMELINE_LIMIT_MONTHLY = 3;
  };
in
{
  services.snapper = {
    snapshotInterval = "hourly";
    cleanupInterval = "1d";
    configs = {
      home = {
        SUBVOLUME = "/home";
        FSTYPE = "btrfs";
      }
      // timeline;
      etc = {
        SUBVOLUME = "/etc";
        FSTYPE = "btrfs";
      }
      // timeline;
      var = {
        SUBVOLUME = "/var";
        FSTYPE = "btrfs";
      }
      // timeline;
    };
  };
}
