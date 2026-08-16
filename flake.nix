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
    # Main package repository (rolling release), fetched from the TUNA mirror.
    # Swap back to "github:NixOS/nixpkgs/nixos-unstable" if you prefer upstream.
    nixpkgs.url = "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/nixpkgs-unstable/nixexprs.tar.xz";

    # Declarative user environment. The repo itself is small, so it stays on
    # GitHub (its nixpkgs follows the mirrored input above).
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add more inputs here as needed, e.g. a stable channel via the mirror:
    #   nixpkgs-stable.url = "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/nixos-24.11/nixexprs.tar.xz";
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
