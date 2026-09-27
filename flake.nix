{
  description = "NixOS + Home Manager: niri + Clavis shell on an Intel laptop";

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

    # Clavis Shell — niri 的 Quickshell 桌面外壳（QML + Qt6 + 自建 C++ plugin）。
    # 上游【没有 flake.nix】，所以 flake = false 取成纯源码树，由
    # pkgs/clavis-shell 消费（自己决定 QML 模块/QML 树的安装路径）。
    "clavis-shell" = {
      url = "github:StatIndet/quickshell";
      flake = false;
    };

    # key — Clavis 的生命周期/IPC/剪贴板/系统指标 CLI（PEP 517，纯 Python +
    # 两个原生小工具 key-sysmon / key-cpu-power）。同样是纯源码树，由
    # pkgs/key-cli 消费。
    "key-cli" = {
      url = "github:StatIndet/key-cli";
      flake = false;
    };

    # M3Shapes — Clavis 的 QML 里有 `import M3Shapes`，但上游明确不打包它
    # （见它 AGENTS.md：外部 QML 运行时模块），Arch 上是 AUR 包。这里用
    # M3Shapes 自带的 nix 打包（inputs.m3shapes.packages.<system>.default）。
    m3shapes = {
      url = "github:soramanew/m3shapes";
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
