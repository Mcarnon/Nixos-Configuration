# Screenshot / clipboard / volume tools.
{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    grim # screenshot
    slurp # region select for screenshots
    wl-clipboard # Wayland clipboard (wl-copy / wl-paste)
    pamixer # volume control (fallback; Noctalia has its own OSD)
    cliphist # clipboard history store
  ];

  # Feed cliphist from wl-clipboard so history survives across copies.
  systemd.user.services.cliphist = {
    Unit = {
      Description = "Clipboard history store (cliphist)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
