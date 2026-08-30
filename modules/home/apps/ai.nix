# AI assistants — Miyu（本仓库主助手，modules/home/services/miyu.nix）
# + opencode（SHORiN 的终端 AI，binds.kdl 里 Mod+Alt+O 启动）。
{
  config,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [ opencode ];
}
