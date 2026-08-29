# niri compositor (greetd lives in ./greetd.nix)
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Wayland session entry point (replaces niri-session).
  #
  # niri-session only activates graphical-session.target when it launches
  # niri.service itself. But under greetd/PAM the session already runs inside a
  # systemd --user manager, so niri-session takes its "already managed" shortcut
  # and execs `niri --session` directly — leaving graphical-session.target
  # inactive, which means Clavis (WantedBy=graphical-session.target) never
  # starts. Starting niri.service explicitly fixes this: niri.service is
  # BindsTo=graphical-session.target, so the target is activated and pulls in
  # the Clavis shell + companions. `systemctl --wait` keeps this process alive
  # until logout so greetd tracks the session correctly.
  clavisSessionScript = pkgs.writeShellScript "clavis-session" ''
    systemctl --user reset-failed || true
    systemctl --user import-environment || true
    dbus-update-activation-environment --all 2>/dev/null || true
    exec systemctl --user start --wait niri.service
  '';

  # niri package whose shipped wayland-session .desktop is overridden so
  # ReGreet/Greetd launches the full session (niri + Clavis) instead of a bare
  # niri. Everything else from the package (binaries, niri.service, portals)
  # is preserved via the symlink join.
  niriWithClavisSession = pkgs.symlinkJoin {
    name = "niri-with-clavis-session";
    paths = [ pkgs.niri ];
    postBuild = ''
      rm -f "$out/share/wayland-sessions/niri.desktop"
      cat > "$out/share/wayland-sessions/niri.desktop" <<EOF
      [Desktop Entry]
      Name=Niri
      Comment=niri + Clavis Shell (Quickshell)
      Exec=${clavisSessionScript}/bin/clavis-session
      Type=Application
      DesktopNames=niri
      EOF
    '';
  };
in
{
  programs.niri = {
    enable = true;
    package = niriWithClavisSession;
  };

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
  # user's DBus session. Pulled in by graphical-session.target (activated by
  # the clavis-session Wayland session entry point above).
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
