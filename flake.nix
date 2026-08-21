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
      pkgs = nixpkgs.legacyPackages.${system};
      lib = nixpkgs.lib;
    in
    {
      nixosConfigurations.laptop = lib.nixosSystem {
        inherit system;
        # Pass inputs to all modules so home-manager can reach noctalia's modules
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/laptop
          home-manager.nixosModules.home-manager
        ];
      };

      formatter.${system} = pkgs.nixfmt-rfc-style;
    };
}
