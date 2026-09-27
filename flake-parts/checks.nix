# CI checks (security + performance regressions surface as `nix flake check`).
{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      miyuTest = pkgs.callPackage ../checks/miyu.nix { inherit inputs; };
    in
    {
      checks = {
        miyu-smoke = miyuTest;
        niri-config = pkgs.callPackage ../checks/niri-config.nix { };
        # 最便宜的一道闸：全仓库 .nix 过 parser + 目录 import 的 default.nix 存在性。
        # 它比整包求值快两三个数量级，语法错误在这里就能看见文件名和行号。
        nix-syntax = pkgs.callPackage ../checks/nix-syntax.nix { };
      };
    };
}
