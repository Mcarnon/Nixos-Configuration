# niri compositor (greetd lives in ./greetd.nix)
{ config, pkgs, lib, ... }:
{
  programs.niri.enable = true;

  # xdg-desktop-portal routing: `programs.niri` already enables the portal +
  # GNOME backend (required for screencast); route file dialogs to the GTK
  # backend.
  xdg.portal = {
    enable = lib.mkDefault true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    config.niri = {
      default = [ "gnome" "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
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

  # polkit authentication agent: niri ships no graphical polkit agent, so GUI
  # privilege prompts (system settings, mounting, updates) would silently fail
  # or fall back to the terminal. This provides the password dialog.
  security.polkit.enable = true;
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };
}
