# Quickshell (nixpkgs) — QtQuick-based desktop shell toolkit that powers our
# bar, launcher, control center, and wallpaper picker.
#
# The shell itself is a Qt QML runtime (`pkgs.quickshell`); we layer on top:
#   * `programs.quickshell` — HM wrapper for managing the daemon via systemctl.
#   * A user systemd service so the shell survives crashes and is pulled in
#     by graphical-session.target (see modules/nixos/desktop/niri.nix).
#   * `home.packages` extras: wayland tools + matugen (palette generation) +
#     cliphist/wl-clipboard (clipboard history, used by the shell's launcher).
#
# Configs (`shell.qml`, bar widgets, colors) are not generated declaratively
# here — Quickshell reads `~/.config/quickshell/shell.qml` and any QML
# modules in `~/.config/quickshell/`. We seed that directory once via
# xdg.configFile from a future `home/quickshell/` tree; for now the default
# config shipped by `pkgs.quickshell` is used.
{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    # The Quickshell runtime (binary: `quickshell`, also exposes `qs`).
    quickshell

    # Wallpaper palette generation (the shell can call `matugen` on every
    # wallpaper change to re-tint GTK/Qt/niri).
    matugen

    # Clipboard history (used by the launcher's clipboard tab).
    cliphist
    wl-clipboard
  ];

  # User systemd service: pull in via graphical-session.target so it
  # starts whenever niri starts (niri-session-wrapper activates the target).
  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell desktop shell";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.quickshell}/bin/quickshell --shell";
      Restart = "on-failure";
      RestartSec = 2;
      TimeoutStopSec = 10;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
