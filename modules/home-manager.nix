{ config, lib, pkgs, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.${config.my.username} = {
      imports = [ ../home ];
      home.username = config.my.username;
      home.homeDirectory = "/home/${config.my.username}";
      home.stateVersion = config.system.stateVersion;
    };
  };
}
