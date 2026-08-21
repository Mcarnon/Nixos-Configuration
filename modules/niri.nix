# niri (scrollable-tiling Wayland compositor) + login manager
{ config, pkgs, lib, ... }:
{
  # Enable niri (from nixpkgs):
  #   - installs the niri package and niri-session
  #   - configures xdg-desktop-portal (gnome/gtk) and gnome-keyring
  programs.niri.enable = true;

  # Login manager: greetd + tuigreet, starts niri after login
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "greeter";
        # --cmd is the session command run after login (niri-session starts the systemd user session)
        command = "${lib.getExe pkgs.tuigreet} --time --cmd ${pkgs.niri}/bin/niri-session";
      };
    };
  };

  # Known fixes for the niri session + xdg-desktop-portal (see openbit/niri-noctalia)
  # graphical-session.target defaults to RefuseManualStart=yes, which blocks niri
  # and services depending on it from starting; relax it here.
  systemd.user.targets.graphical-session = {
    unitConfig = {
      RefuseManualStart = false;
      StopWhenUnneeded = false;
    };
  };
}
