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
  lib,
  pkgs,
  ...
}:
let
  # dshBundleCheckHook 用 pty（`script -qefc`）跑 TTY profile，普通 CLI profile
  # 直接跑。分类名单由 pkgs/dsh/package.nix 从 `profiles` 推导，但上游
  # lib/mk-dsh-runtime.nix 给 runtime 包传的 `profiles = { }`
  # （profile 由 profileSeeder 单独物化），于是
  # dshBundleCheckTtyProfiles 为空 —— hook 只能靠扫 $DSH_HOME/profiles/*
  # 自动发现 profile，发现出来的名字在三个名单里都没有，于是被当成普通 CLI
  # 直接 `dsh --profile nix-tui --help`。Ink 拿不到 tty，抛
  # "Raw mode is not supported on the current process.stdin" 并让
  # installCheckPhase 失败。
  # 这里按上游 profileRequiresTty / profileNeedsTui 的同一套判据自己算一遍
  # （profile-options.nix 没有 exposes requiresTui 选项，所以 bundles 的
  # passthru 也要一起看）。
  profileNeedsTty =
    profile:
    (profile.requiresTty or false)
    || (profile.requiresTui or false)
    || lib.any (
      bundle: (bundle.passthru.requiresTty or false) || (bundle.passthru.requiresTui or false)
    ) (profile.bundles or [ ]);

  ttyProfiles = lib.concatStringsSep " " (
    lib.filter (s: s != "") (
      lib.map (profile: if profileNeedsTty profile then profile.materializedName else "") (
        lib.attrValues config.programs.dsh.profiles
      )
    )
  );
in
{
  imports = [ inputs.deepseek-harness.homeModules.default ];

  programs.dsh = {
    enable = true;

    # overrideAttrs 在 mkDshRuntime 的 `.override { ... }` 之后生效（override
    # 只换函数实参，__overrideAttrs 最后才跑），所以能改到最终 derivation 的
    # 环境变量。
    package = pkgs.dsh.dsh.overrideAttrs (_: {
      dshBundleCheckTtyProfiles = ttyProfiles;
    });

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
