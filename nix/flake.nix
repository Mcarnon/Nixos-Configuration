{
  description = "NixOS multi-host configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      username =
        let
          sudoUser = builtins.getEnv "SUDO_USER";
          envUser  = builtins.getEnv "USERNAME";
        in
        if sudoUser != "" then sudoUser
        else if envUser != "" then envUser
        else "mccarnon";

      hosts = {
        desktop = "desktop";
        laptop  = "laptop";
      };
    in
    {
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

      nixosConfigurations = lib.mapAttrs (hostName: _: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit username inputs; };
        modules = [
          ./hosts/common.nix
          ./hosts/${hostName}/default.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = import ./home/common.nix;
          }
        ];
      }) hosts;
    };
}
