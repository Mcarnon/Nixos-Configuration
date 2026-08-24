# Partitioning as code (disko): tmpfs root + btrfs subvolumes.
# Equivalent to the mount scheme in hardware-configuration.nix; replaces manual
# partitioning commands.
#
# Run once from the NixOS installation ISO (wipes signatures + repartitions;
# fresh installs only — no manual `wipefs -a` needed):
#   nix run github:nix-community/disko/latest -- \
#     --mode destroy,format,mount ./hosts/laptop/disko-fs.nix
#
# Note: `--mode disko` is a legacy alias for `destroy,format,mount` (removed in
# disko 2.0). The btrfs `extraArgs = [ "-f" ]` only takes effect if mkfs runs
# against an existing btrfs; the destroy stage wipes signatures first.
#
# Afterwards run `nixos-generate-config --root /mnt` and fill the real UUIDs
# into ./hardware-configuration.nix.
{
  disko.devices = {
    # tmpfs root: matches fileSystems."/" in hardware-configuration.nix
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [ "defaults" "size=8G" "mode=755" ];
    };

    disk.main = {
      type = "disk";
      device = "/dev/nvme0n1"; # TODO: change to your disk, or use /dev/disk/by-id/xxx
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "fmask=0022" "dmask=0022" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ]; # force overwrite of an existing filesystem
              subvolumes = {
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@var" = {
                  mountpoint = "/var";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@etc" = {
                  mountpoint = "/etc";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
              };
            };
          };
          swap = {
            size = "8G";
            content = { type = "swap"; };
          };
        };
      };
    };
  };
}
