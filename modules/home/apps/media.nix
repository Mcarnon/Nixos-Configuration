# Screenshot / clipboard / volume tools.
{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    grim # screenshot
    slurp # region select for screenshots
    wl-clipboard # Wayland clipboard (wl-copy / wl-paste)
    pamixer # volume control (fallback; Noctalia has its own OSD)
    cliphist # clipboard history store (service in ../services/cliphist.nix)
  ];
}
