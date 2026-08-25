# Home profile: desktop — common + graphical user env (performance: Wayland-only).
{ config, pkgs, lib, ... }:
{
  imports = [
    ./common.nix
    ../niri.nix
    ../noctalia.nix
  ];
}
