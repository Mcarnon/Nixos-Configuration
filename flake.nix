{
  description = "NixOS + Home Manager: niri + Clavis (Quickshell) on an Intel laptop";

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

    # ── Clavis Shell (Quickshell desktop shell for niri) + companions ──
    # These repos are plain source trees (no flake.nix), so `flake = false`
    # fetches them as source paths consumed by pkgs/{clavis-shell,key-cli,keytop}.
    # Pin to a commit with `nix flake lock --update-input <name>` once verified.
    "clavis-shell" = {
      url = "github:StatIndet/quickshell";
      flake = false;
    };
    "key-cli" = {
      url = "github:StatIndet/key-cli/d512bc1e3607c52c5e1fb4477b9c7f31d9216760";
      flake = false;
    };
    "keytop" = {
      url = "github:StatIndet/keytop/8c2f998d4644403026b7e1f81780d75aa717742d";
      flake = false;
    };

    # age-encrypted secrets (see modules/nixos/security/secrets.nix)
    agenix.url = "github:ryantm/agenix";

    # Zen Browser (firefox fork)
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
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
