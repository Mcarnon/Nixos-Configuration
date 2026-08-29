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

  # Wayland session entry point for greetd.
  # Starts systemd --user (if not already running) before launching niri,
  # so that user systemd services (fcitx5, polkit agent, etc.) can start.
  # This is the key fix: greetd sessions don't auto-spawn systemd --user.
  environment.etc."wayland-session".source = pkgs.writeShellScript "init-wayland-session" ''
    # Ensure systemd --user is running (greetd doesn't auto-start it)
    if ! pgrep -x systemd >/dev/null 2>&1; then
      systemctl --user start &
      sleep 2
    fi
    # Launch niri (replacing the shell)
    exec /run/current-system/sw/bin/niri-session
  '';

  # polkit authentication agent
  security.polkit.enable = true;
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome authentication agent";
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

  # fcitx5 input method daemon.
  # Started as a systemd user service so it survives crashes and shares the
  # user's DBus session. Requires systemd --user to be running (see
  # environment.etc."wayland-session" above).
  systemd.user.services.fcitx5 = {
    description = "Fcitx5 input method";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.fcitx5}/bin/fcitx5";
      Restart = "always";
      RestartSec = 2;
    };
  };
}
