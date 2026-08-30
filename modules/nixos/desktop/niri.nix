# niri compositor (greetd lives in ./greetd.nix)
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Wayland session entry point (replaces the default niri-session).
  #
  # niri-session only activates graphical-session.target when it launches
  # niri.service itself. But under greetd/PAM the session already runs inside a
  # systemd --user manager, so niri-session takes its "already managed" shortcut
  # and execs `niri --session` directly — leaving graphical-session.target
  # inactive, which means every user service `WantedBy=graphical-session.target`
  # (fcitx5, polkit, waybar) never starts. Starting niri.service
  # explicitly fixes this: it BindsTo=graphical-session.target, so the target is
  # activated and pulls in all the user services. `systemctl --wait` keeps this
  # process alive until logout so greetd tracks the session correctly.
  niriSessionWrapperScript = pkgs.writeShellScript "niri-session-wrapper" ''
    systemctl --user reset-failed || true
    systemctl --user import-environment || true
    dbus-update-activation-environment --all 2>/dev/null || true
    exec systemctl --user start --wait niri.service
  '';

  # niri package whose shipped wayland-session .desktop is overridden so
  # ReGreet/Greetd launches the wrapper (which activates graphical-session.target)
  # instead of the bare `niri-session` (which doesn't). Everything else from the
  # niri package (binaries, niri.service, portals) is preserved via symlinkJoin.
  niriWithSessionWrapper =
    (pkgs.symlinkJoin {
      name = "niri-with-session-wrapper";
      paths = [ pkgs.niri ];
      postBuild = ''
        rm -f "$out/share/wayland-sessions/niri.desktop"
        cat > "$out/share/wayland-sessions/niri.desktop" <<EOF
        [Desktop Entry]
        Name=Niri
        Comment=niri + graphical-session.target user services (fcitx5, polkit, ...)
        Exec=${niriSessionWrapperScript}/bin/niri-session-wrapper
        Type=Application
        DesktopNames=niri
        EOF
      '';
    })
    // {
      # The display-manager's `sessionPackages` type requires this metadata;
      # symlinkJoin drops it, so re-attach it from the underlying niri package.
      providedSessions = pkgs.niri.providedSessions or [ "niri" ];
    };
in
{
  programs.niri = {
    enable = true;
    package = niriWithSessionWrapper;
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
  # the niri-session-wrapper Wayland session entry point above).
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
