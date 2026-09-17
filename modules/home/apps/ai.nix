# AI assistants — Miyu（本仓库主助手，modules/home/services/miyu.nix）
# + opencode（SHORiN 的终端 AI，binds.kdl 里 Mod+Alt+O 启动）
# + AIRI（moeru-ai 的 Neuro-sama 式 AI 助手桌面端，flakes 输入 `airi`）。
{
  config,
  pkgs,
  ...
}:
{
  home.packages =
    with pkgs; [
      opencode
      airi
    ];
}
