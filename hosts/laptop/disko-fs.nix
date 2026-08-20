# Partitioning as code (disko): tmpfs root + btrfs subvolumes.
# Equivalent to the mount scheme in hardware-configuration.nix; replaces manual
# partitioning commands.
#
# Run from the NixOS installation ISO (wipes the target disk; fresh installs only):
#   nix run github:nix-community/disko -- --mode disko ./hosts/laptop/disko-fs.nix
#
# Afterwards you still need `nixos-generate-config --root /mnt` to generate the
# hardware-configuration.nix, then fill in the real UUIDs in ./hardware-configuration.nix.
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
          # Optional swap partition (kept in sync with hardware-configuration.nix; uncomment if needed)
          # swap = {
          #   size = "8G";
          #   content = { type = "swap"; };
          # };
        };
      };
    };
  };
}
