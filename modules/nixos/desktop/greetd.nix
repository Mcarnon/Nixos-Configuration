# greetd login manager for niri
{ config, pkgs, lib, ... }:
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "greeter";
        command = "${lib.getExe pkgs.tuigreet} --time --cmd ${pkgs.niri}/bin/niri-session";
      };
    };
  };
}
