# Modern CLI tools (user-level). Rescue/root tools stay in modules/cli.nix.
{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    bat # cat with syntax highlight
    yazi # TUI file manager
    lazygit # git TUI
    btop # resource monitor (replaces htop for daily use)
    fastfetch # system info banner
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
