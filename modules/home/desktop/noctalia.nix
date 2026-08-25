# Noctalia desktop shell (Wayland bar / launcher / control center / lock screen, etc.)
{ config, pkgs, inputs, lib, ... }:
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;

    # Declaratively generate ~/.config/noctalia/config.toml from a Nix attrset
    # (can also be a raw TOML string or a path to a .toml file)
    settings = {
      shell = {
        font = "JetBrainsMono Nerd Font";
        settings_show_advanced = true;
      };

      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Catppuccin";
      };

      # wallpaper example (the path must exist)
      # wallpaper = {
      #   enabled = true;
      #   default.path = "/home/alice/Pictures/wallpaper.png";
      # };
    };

    # If config validation fails at build time, temporarily set this to false to debug
    # validateConfig = true;
  };
}
