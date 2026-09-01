# Link niri's KDL config to ~/.config/niri.
# Shared config files are linked individually; the machine-specific output
# config (niri-hardware.kdl) is passed in from the host.
{
  config,
  pkgs,
  lib,
  hostPath,
  ...
}:
{
  xdg.configFile = {
    "niri/config.kdl".source = ../../../home/niri/config.kdl;
    "niri/binds.kdl".source = ../../../home/niri/binds.kdl;
    "niri/blur.kdl".source = ../../../home/niri/blur.kdl;
    "niri/startup.kdl".source = ../../../home/niri/startup.kdl;
    "niri/windowrule.kdl".source = ../../../home/niri/windowrule.kdl;
    "niri/noctalia-static.kdl".source = ../../../home/niri/noctalia-static.kdl;
    "niri/niri-hardware.kdl".source = hostPath + "/niri-hardware.kdl";
  };
}
