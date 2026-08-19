{
  description = "NixOS + Home Manager: niri + Noctalia on a Huawei Intel laptop";

  # Noctalia 的二进制缓存 (省略此段则本地编译, 会很慢)。
  # 注意: 要命中缓存, 下面的 noctalia input 不能对 nixpkgs 设置 `follows`。
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

    # 锁定 `cachix` 分支: 始终指向最新一个已被 CI 预构建的提交。
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
  };

  outputs =
    { self, nixpkgs, home-manager, noctalia, ... }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.huawei = nixpkgs.lib.nixosSystem {
        inherit system;
        # 把 inputs 传给所有模块, 让 home-manager 能拿到 noctalia 的模块
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
        ];
      };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
    };
}
