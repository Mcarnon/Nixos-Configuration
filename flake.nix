{
  description = "NixOS + Home Manager: niri + Noctalia on an Intel laptop";

  # Noctalia binary cache (without this it will compile locally, slowly).
  # Note: to hit the cache, the noctalia input below must NOT set `follows` on nixpkgs.
  nixConfig = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pin the `cachix` branch: always points to the latest CI-prebuilt commit.
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
  };

  outputs =
    { self, nixpkgs, home-manager, noctalia, ... }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
        inherit system;
        # Pass inputs to all modules so home-manager can reach noctalia's modules
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/laptop
          home-manager.nixosModules.home-manager
        ];
      };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
    };
}
