# DeepSeek Harness (`dsh`) —— 终端 AI CLI，上游自带 Nix 打包
# (github:moraxyc/deepseek-harness.nix，文档 moraxyc.github.io/deepseek-harness.nix)。
#
# 分工：
#   - 包来自本仓库 overlay 暴露的 `pkgs.dsh`（pkgs/default.nix 转接上游 overlay）
#   - 这里只导入上游的 homeModules.default 并声明 profile；模块自己会把组合好的
#     CLI 放进 home.packages，并在 HM 激活时把 profile 物化到 $DSH_HOME/profiles
#
# 用法：`dsh` 直接进 TUI（defaultProfile 已指向物化名 nix-tui）。
# Profile 是 mutable：Nix 只在 ~/.dsh/profiles/nix-tui 不存在时 seed 一次，
# 之后 `dsh plugin` / Settings UI 的改动都保留，Nix 不再覆盖 —— 想随时
# `rm -rf ~/.dsh` 重新 seed 就删目录再 rebuild。
# 换 API key / 换模型走 dsh 自己的设置（官方 DeepSeek 平台申请：
# https://platform.deepseek.com/api_keys），不要写进本文件。
{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.deepseek-harness.homeModules.default ];

  programs.dsh = {
    enable = true;

    profiles.tui = {
      # 最小组合：交互式终端界面（pkgs.dsh.bundles 是插件式扩展，后面的覆盖前面的）。
      # 想加能力就在这里追加 bundle，例如：
      #   pkgs.dsh.bundles.subscriptions   —— 用 ChatGPT/Claude/Copilot 订阅登录（OAuth，免 API key）
      #   pkgs.dsh.bundles.memento         —— 跨会话记忆（本地 SQLite，审批门控）
      #   pkgs.dsh.bundles.modsearch       —— 内置联网搜索 provider
      bundles = [ pkgs.dsh.bundles.tui ];
      mode = "mutable";
    };

    # 用物化名而不是硬写 "nix-tui"（profile-options.nix 生成的 material 化名）。
    defaultProfile = config.programs.dsh.profiles.tui.materializedName;
  };
}
