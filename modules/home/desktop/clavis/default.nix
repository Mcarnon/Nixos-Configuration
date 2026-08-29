# Clavis Shell — Quickshell desktop shell for niri (replaces Noctalia).
#
# Installs the `key` launcher + `keytop`, and starts the shell + clipboard
# watcher as user systemd services under graphical-session.target (niri is
# launched by greetd here, not as a `niri.service` unit, so we can't use the
# upstream `WantedBy=niri.service`).
{
  pkgs,
  ...
}:
{
  home.packages = [
    pkgs.keyCli # `key` launcher / IPC / clipboard / recording
    pkgs.keytop # standalone system monitor TUI
  ];

  # Clavis native QML modules + config live in clavisShell; the wrapped `key`
  # already points QML_IMPORT_PATH / XDG_CONFIG_DIRS at it, so nothing else is
  # needed here for discovery.

  systemd.user.services.clavis-shell = {
    Unit = {
      Description = "Clavis Shell";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.keyCli}/bin/key shell --foreground --no-duplicate";
      Restart = "on-failure";
      RestartSec = 2;
      TimeoutStopSec = 10;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  systemd.user.services.clavis-clipboard = {
    Unit = {
      Description = "Clavis clipboard watcher";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.keyCli}/bin/key clipboard watch";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
