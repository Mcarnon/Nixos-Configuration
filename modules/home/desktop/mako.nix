# mako 通知守护 — SHORiN minimal-niri 配置（raw 部署），用户 systemd 服务。
# 其他通知来源：waybar/niri-pick/screenshot 等脚本的 notify-send 都走它。
{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = [ pkgs.mako ];

  xdg.configFile."mako/config".source = ../../../home/files/mako.conf;

  systemd.user.services.mako = {
    Unit = {
      Description = "Mako notification daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.mako}/bin/mako";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
