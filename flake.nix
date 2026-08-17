{
  description = "McCarnon's NixOS configuration";

  # 国内镜像加速（清华 TUNA 二进制缓存）。
  nixConfig.extra-substituters = [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
  ];

  inputs = {
    # 国内镜像源（滚动版）。想用稳定版把 `nixpkgs-unstable` 换成 `nixos-26.05`。
    nixpkgs.url = "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/nixpkgs-unstable/nixexprs.tar.xz";
  };

  outputs = { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      mkHost = name: nixpkgs.lib.nixosSystem {
        modules = [
          ./modules # 共享基础配置
          ./hosts/${name}
        ];
      };
    in
    {
      nixosConfigurations = {
        desktop = mkHost "desktop";
        laptop = mkHost "laptop";
        vm = mkHost "vm";
      };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          packages = with nixpkgs.legacyPackages.${system}; [
            alejandra
            git
          ];
        };
      });
    };
}
