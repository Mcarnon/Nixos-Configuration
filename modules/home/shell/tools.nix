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
    # SHORiN 原版 starship 配置（含深色 palette）。Clavis 不改它：matugen
    # 模板里没有 starship，这份文件是最终值（按壁纸变色是以前桌面壳的能力）。
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
