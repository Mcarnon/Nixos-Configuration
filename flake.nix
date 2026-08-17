{
  description = "McCarnon's personal NixOS configuration";

  # Settings applied to any `nix` command that uses this flake.
  nixConfig = {
    # TUNA (China) mirror of cache.nixos.org. It mirrors the official store, so
    # the existing cache.nixos.org public keys already trust it (no extra keys).
    extra-substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    ];
  };

  inputs = {
    # Main package repository, pinned to the NixOS 26.05 stable release via the
    # TUNA mirror. Swap back to nixpkgs-unstable if you prefer a rolling release.
    nixpkgs.url = "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/nixos-26.05/nixexprs.tar.xz";

    # Declarative user environment, matched to the NixOS 26.05 release branch.
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Noctalia Wayland desktop shell (bar / launcher / notifications / ...).
    # Its nixpkgs follows the mirrored input above so we reuse the TUNA cache.
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, home-manager, ... }@inputs:
    let
      inherit (nixpkgs) lib;

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = lib.genAttrs systems;

      # Build a NixOS configuration for a host directory under `hosts/`.
      mkHost = name:
        lib.nixosSystem {
          # `inputs` is exposed to every module so they can reach other flakes.
          specialArgs = { inherit inputs; };
          modules = [
            ./modules # shared base configuration
            ./hosts/${name}
            home-manager.nixosModules.home-manager
          ];
        };
    in
    {
      nixosConfigurations = {
        desktop = mkHost "desktop";
        laptop = mkHost "laptop";
        vm = mkHost "vm";
      };

      # `nix fmt` in this repository.
      formatter = forAllSystems (
        system: nixpkgs.legacyPackages.${system}.alejandra
      );

      # Convenient shell for working on this repository.
      devShells = forAllSystems (
        system:
        nixpkgs.legacyPackages.${system}.mkShell {
          packages = with nixpkgs.legacyPackages.${system}; [
            alejandra
            git
          ];
        }
      );
    };
}
