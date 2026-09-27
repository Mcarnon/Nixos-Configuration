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
        # 自建的三个包：Clavis 本体、key 包装（含运行时 wrapper）、M3Shapes
        # 来自上游 flake。Clavis 和 key-cli 上游都没有 flake，所以这里给
        # `nix build` 的入口只能是本仓库 overlay 出来的结果。
        inherit (pkgs) clavisShell keyCli;
        # 上游自带 nix 打包的直接透出，方便单独重建/升级 M3Shapes。
        m3shapes = inputs.m3shapes.packages.${system}.default;
      };
      formatter = pkgs.nixfmt;
    };
}
