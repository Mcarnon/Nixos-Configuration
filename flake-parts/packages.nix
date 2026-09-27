# perSystem packages & formatter (performance: perSystem eval is cached once per system).
{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      # Apply the repo overlay so the custom packages are buildable via `nix build`.
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ (import ../pkgs/default.nix inputs) ];
      };
    in
    {
      packages = {
        inherit (pkgs) miyu;
        # iNiR 自带 flake，直接暴露上游的 package 输出，给 `nix build` 一个入口。
        # 本仓库的 inputs.inir.inputs.nixpkgs.follows = "nixpkgs"，所以这里
        # 和 Home Manager 模块用的其实是同一份 nixpkgs 解析结果。
        inir = inputs.inir.packages.${system}.inir;
      };
      formatter = pkgs.nixfmt;
    };
}
