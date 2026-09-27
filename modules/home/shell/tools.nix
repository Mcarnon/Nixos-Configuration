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
    # SHORiN 原版 starship 配置（含深色 palette；iNiR 的 starship 模板会在
    # appearance.wallpaperTheming.terminals.starship 打开时按壁纸覆写它）
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
