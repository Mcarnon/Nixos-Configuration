# Screenshot / clipboard / volume / media tools.
{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    grim # screenshot
    slurp # region select for screenshots
    wl-clipboard # Wayland clipboard (wl-copy / wl-paste)
    pamixer # volume control (bound to XF86 keys in home/niri/binds.kdl)
    playerctl # MPRIS media keys (bound in home/niri/binds.kdl)
    brightnessctl # brightness CLI (bound to XF86 keys in home/niri/binds.kdl)
    cliphist # clipboard history store (used by key-cli's clipboard backend)
  ];
}
