# shell tools: starship + direnv + fzf + eza + zoxide
{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.starship = {
    enable = true;
    # SHORiN 原版 starship 配置（含 noctalia 配色 palette）
    settings = builtins.fromTOML (builtins.readFile ../../../home/files/starship.toml);
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableFishIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    git = true;
    icons = "auto";
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };
}
