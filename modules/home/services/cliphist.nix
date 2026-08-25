# clipboard history for Wayland (niri + wl-clipboard)
{ config, pkgs, lib, ... }:
{
  services.cliphist = {
    enable = true;
    allowImages = true;
  };
}
