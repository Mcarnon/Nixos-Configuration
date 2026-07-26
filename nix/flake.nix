{
  description = "NixOS multi-host configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      username = builtins.getEnv "USERNAME";
      hosts = {
        desktop = "Desktop";
        laptop = "Laptop";
      };
    in
    if username == ""
    then throw "请设置 USERNAME 环境变量，例如: USERNAME=mccarnon sudo nixos-rebuild switch --flake .#desktop"
    else {
      nixosConfigurations = nixpkgs.lib.mapAttrs (hostName: description: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit username; };
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
