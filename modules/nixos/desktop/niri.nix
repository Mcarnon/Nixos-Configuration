# niri compositor (greetd lives in ./greetd.nix)
{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.niri.enable = true;

  # xdg-desktop-portal routing
  xdg.portal = {
    enable = lib.mkDefault true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    config.niri = {
      default = [
        "gnome"
        "gtk"
      ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    };
  };

  # Fix graphical-session.target so systemd user services can use it
  systemd.user.targets.graphical-session = {
    unitConfig = {
      RefuseManualStart = false;
      StopWhenUnneeded = false;
    };
  };

  # polkit authentication agent
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

  # fcitx5 input method — starts with the graphical session
  systemd.user.services.fcitx5 = {
    description = "Fcitx5 input method";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.fcitx5}/bin/fcitx5";
      # Restart always so it survives dbus name conflicts (niri may also start
      # fcitx5 via other means — whichever wins the dbus name keeps running).
      Restart = "always";
      RestartSec = 2;
    };
  };
}
