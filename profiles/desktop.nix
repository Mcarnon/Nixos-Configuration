# Profile: desktop — base + graphical stack (niri/noctalia/audio)
# Performance: Wayland-only (no XWayland), hardware accel; Security: polkit agent.
{ config, pkgs, lib, ... }:
{
  imports = [
    ./base.nix
    ../modules/services/niri.nix
    ../modules/services/pipewire.nix
    ../modules/services/laptop.nix
    # Hardware is host-selected; desktop profile does NOT force a GPU vendor.
    # Host enables e.g. `hardware.intel.enable = true` or `hardware.nvidia.enable = true`.
  ];
}
