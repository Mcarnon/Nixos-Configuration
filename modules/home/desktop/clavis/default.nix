# Clavis Shell — Quickshell desktop shell for niri (replaces Noctalia).
#
# Installs the `key` launcher + `keytop`, and starts the shell + clipboard
# watcher as user systemd services under graphical-session.target (ly launches
# a wrapper that starts niri.service, which BindsTo=graphical-session.target,
# so the target is active during the session).
{
  pkgs,
  ...
}:
{
  home.packages = [
    pkgs.keyCli # `key` launcher / IPC / clipboard / recording
    pkgs.keytop # standalone system monitor TUI
    pkgs.awww # 壁纸引擎（Clavis 设置中心 / 壁纸随机都调它）
  ];

  # 默认壁纸：部署到 ~/Pictures/Wallpapers/（Clavis 设置中心从这里选图）；
  # 不放自己的图时至少有一张可用。
  home.file."Pictures/Wallpapers/wallhaven-d88d53.png".source =
    ../../../../wallpapers/wallhaven-d88d53.png;

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
