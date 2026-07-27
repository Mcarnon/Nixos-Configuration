{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./config.nix
  ];

  # Noctalia Home Manager 配置
  imports = [ inputs.noctalia.homeModules.default ];
  programs.noctalia = {
    enable = true;
    settings = {
      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Catppuccin";
      };
      wallpaper = {
        enabled = true;
      };
    };
  };
}
