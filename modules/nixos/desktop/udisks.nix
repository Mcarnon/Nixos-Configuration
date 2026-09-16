# Removable media / USB & mobile device support.
#
# udisks2 is the backend that mounts/unmounts removable drives; gvfs provides
# per-user volume monitors (incl. MTP/AFC for Android/iPhone) that Thunar,
# Nautilus and GTK file pickers talk to. NixOS ships both disabled by default
# outside a full desktop environment, so a bare niri setup must enable them
# explicitly or USB sticks / phones never show up.
{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.udisks2.enable = true;
  services.gvfs.enable = true;
}