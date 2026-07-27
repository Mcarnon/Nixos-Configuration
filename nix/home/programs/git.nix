{ config, pkgs, lib, ... }:

{
  programs.git = {
    enable = true;
    userName = "MezaKlaso";
    userEmail = "3273556124@qq.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };
}
