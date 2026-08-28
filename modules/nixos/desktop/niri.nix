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

  # fcitx5 input method — fallback if niri's spawn-at-startup doesn't run.
  # Primary startup is via home/niri/startup.kdl (spawn-at-startup "fcitx5"),
  # which works because niri doesn't auto-activate graphical-session.target.
  # This service stays dormant (RemainAfterExit=no) unless invoked manually.
  systemd.user.services.fcitx5 = {
    description = "Fcitx5 input method (fallback)";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.fcitx5}/bin/fcitx5";
      Restart = "always";
      RestartSec = 2;
    };
  };
}
