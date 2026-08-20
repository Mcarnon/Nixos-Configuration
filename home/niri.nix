# Link niri's KDL config to ~/.config/niri.
# Shared config files are linked individually; the machine-specific output
# config (niri-hardware.kdl) is passed in from the host.
{ config, pkgs, lib, hostPath, ... }:
{
  xdg.configFile = {
    "niri/config.kdl".source = ./niri/config.kdl;
    "niri/binds.kdl".source = ./niri/binds.kdl;
    "niri/startup.kdl".source = ./niri/startup.kdl;
    "niri/windowrule.kdl".source = ./niri/windowrule.kdl;
    "niri/niri-hardware.kdl".source = hostPath + "/niri-hardware.kdl";
  };
}
