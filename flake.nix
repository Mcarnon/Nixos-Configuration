{
  description = "NixOS + Home Manager: niri + Noctalia on an Intel laptop";

  # Binary caches: Noctalia + CN mirrors (priority=5 means prefer mirrors
  # over the default cache.nixos.org priority 40).
  nixConfig = {
    extra-substituters = [
      "https://noctalia.cachix.org"
      "https://mirrors.ustc.edu.cn/nix-channels/store?priority=5"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=5"
      "https://mirror.sjtu.edu.cn/nix-channels/store?priority=5"
    ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
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

    # Pin the `cachix` branch: always points to the latest CI-prebuilt commit.
    noctalia.url = "github:noctalia-dev/noctalia/cachix";

    # Zen Browser (Firefox-based, not in nixpkgs; wraps upstream binaries).
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # age-encrypted secrets (see modules/secrets.nix)
    agenix.url = "github:ryantm/agenix";
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
        # Single audit surface for custom packages (security: `git grep pkgs.default.nix` traces all consumers).
        overlays.default = import ./pkgs/default.nix;
      };
    };
}
