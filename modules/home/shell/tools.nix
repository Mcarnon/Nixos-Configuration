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
    # SHORiN 版 starship 配置（配色是当初跟着桌面壳一起换的，现在与 Clavis 无关）
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
