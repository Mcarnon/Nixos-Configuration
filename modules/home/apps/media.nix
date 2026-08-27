# Screenshot / clipboard / volume / media tools.
{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    grim # screenshot
    slurp # region select for screenshots
    wl-clipboard # Wayland clipboard (wl-copy / wl-paste)
    pamixer # volume control (fallback; Noctalia has its own OSD)
    playerctl # MPRIS media keys (bound in home/niri/binds.kdl)
    brightnessctl # brightness CLI (backup; Noctalia has its own backend)
    cliphist # clipboard history store (service in ../services/cliphist.nix)
  ];
}
