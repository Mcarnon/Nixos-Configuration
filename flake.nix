{
  description = "NixOS + Home Manager: niri + Clavis Shell on an Intel laptop";

  # Binary caches: CN mirrors (priority=5 means prefer mirrors
  # over the default cache.nixos.org priority 40).
  # deepseek-harness 的公开 Cachix 放在最后（默认 priority 40，与 cache.nixos.org
  # 同级）：dsh 的包和 bundle 几乎全部预构建在它上面，源码构建要跑整棵
  # pnpm workspace 的 deploy。channel 镜像沿用 nixpkgs 发布密钥，Cachix 必须自带
  # trusted key（上游 flake.nix 的 nixConfig 给的就是这一对）。
  nixConfig = {
    extra-substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store?priority=5"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=5"
      "https://mirror.sjtu.edu.cn/nix-channels/store?priority=5"
      "https://deepseek-harness-nix.cachix.org"
    ];
    extra-trusted-public-keys = [
      "deepseek-harness-nix.cachix.org-1:5NrkwLN9veNMhiINtU5ZeV4isXFhFsOwn6Ms7J1M+TA="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Standardize entry points (performance: perSystem memoization; scale: one host = one line).
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # age-encrypted secrets (see modules/nixos/security/secrets.nix)
    agenix.url = "github:ryantm/agenix";

    # Zen Browser (firefox fork)
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Clavis Shell（niri 的 Quickshell 桌面壳）及其伴生后端 key-cli。
    # 这两个仓库是纯源码树（无 flake.nix），flake = false 取为 source 路径，
    # 由 pkgs/{clavis-shell,key-cli,libcava} 消费。
    clavis-shell = {
      # 钉在 v2026.9.25 release tag，而不是 main。
      # main 与该 tag 已 diverged：main 领先 20 个提交（bar/keystone/dock/settings
      # 重构），但其中 434d1311f0「feat(bar): simplify controls」把状态栏控件
      # 包进 BarActionButton，并把 onWheel 换成挂在上一层、被内层 MouseArea
      # 截断的 WheelHandler —— 状态栏滚轮调节亮度/音量因此全部失效。
      # v2026.9.25 仍是 MouseArea.onWheel，滚轮可用，故以此 tag 为基线。
      # 回到 main 的前提是上游修复该回归（或本地 patch 三个 Bar/QuickSettings 文件）。
      url = "github:StatIndet/quickshell/v2026.9.25";
      flake = false;
    };

    key-cli = {
      url = "github:StatIndet/key-cli";
      flake = false;
    };

    # M3Shapes — Clavis 的 Material 3 形状 QML 模块。Clavis 全文 import 了 20 次，
    # 且上游明确「不会内置或 vendor」，缺它就是整屏 QML 加载失败（黑屏）。
    # 仓库里没有 flake.nix（只有 nix/ 目录），显式 flake = false 拿纯源码树，
    # 和上面两个 Clavis 输入保持一致。
    m3shapes = {
      url = "github:soramanew/m3shapes";
      flake = false;
    };

    # thyx — SDDM 的 QML 登录主题，2026-10 起取代 ly 当登录界面。
    # 自带 nixosModules.default（负责 sddm.enable/theme/extraPackages + 字体），
    # 上游还有 flake check：NixOS VM 冒烟测试会真在 SDDM 下加载主题。
    # 钉在 v1.1.0 tag：仓库只发 tag 不发 release，且该 tag 就等于 main HEAD。
    thyx.url = "github:rccyx/thyx/v1.1.0";

    # DeepSeek Harness (dsh) — 终端 AI CLI，上游自己维护 Nix 打包：
    # overlay（pkgs.dsh.*）、nixosModules/homeModules（programs.dsh + profile 物化）。
    # 上游是纯打包层（MIT），dsh 本体来自 DeepSeek 官方仓库。
    # 本仓库消费方式：pkgs/default.nix 把它的 overlay 接到 pkgs.dsh（和其余
    # 自定义包同一个审计面），modules/home/apps/dsh.nix 导入它的 homeModules
    # 并声明 tui profile。
    # 不用 follows = home-manager：上游 flake 根本没声明 home-manager 输入
    # （homeModules 是普通路径模块，不经 inputs），加了只会触发 Nix 警告
    # "override for a non-existent input"。
    deepseek-harness = {
      url = "github:moraxyc/deepseek-harness.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Single-system repo today; flake-parts still benefits from perSystem caching
      # and `nix flake check` parallelism. Add aarch64-linux here when you add that host.
      systems = [ "x86_64-linux" ];

      imports = [
        ./flake-parts/hosts.nix
        ./flake-parts/packages.nix
        ./flake-parts/checks.nix
      ];

      flake = {
        # Single audit surface for custom packages (security: `git grep pkgs.miyu` traces all consumers).
        overlays.default = import ./pkgs/default.nix inputs;
      };
    };
}
