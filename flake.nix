{
  description = "NixOS + Home Manager: niri + Clavis Shell on an Intel laptop";

  # Binary caches: CN mirrors (priority=5 means prefer mirrors
  # over the default cache.nixos.org priority 40).
  nixConfig = {
    extra-substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store?priority=5"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=5"
      "https://mirror.sjtu.edu.cn/nix-channels/store?priority=5"
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
      url = "github:StatIndet/quickshell";
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

    # AIRI — self-hosted Grok/Neuro-sama companion (Electron "tamagotchi" desktop)
    airi = {
      url = "github:moeru-ai/airi";
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
