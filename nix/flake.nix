{
  description = "NixOS + Home Manager configuration";

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
      pkgs = nixpkgs.legacyPackages.${system};
      
      # 用户列表
      users = {
        mccarnon = {
          fullName = "Your Name";
          email = "your@email.com";
        };
      };
    in {
      # NixOS 系统配置
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/default.nix
          {
            # 传递用户信息给系统配置
            _module.args = { inherit users; };
          }
        ];
      };

      # Home Manager 用户配置
      homeConfigurations = builtins.mapAttrs (name: userData: 
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ 
            ./home-manager/home.nix
            {
              home.username = name;
              home.homeDirectory = "/home/${name}";
              _module.args = { inherit userData; };
            }
          ];
        }
      ) users;
    };
}
