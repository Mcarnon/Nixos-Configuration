{ config, pkgs, lib, ... }:

{
  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "your@email.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };
}
