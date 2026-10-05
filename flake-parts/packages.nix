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
        # Clavis desktop shell stack. `keyCli` is the interesting one: its wrapper
        # is what wires the QML import roots together, so building it catches
        # missing/renamed QML modules and a Clavis install prefix that moved.
        inherit (pkgs) clavisShell keyCli m3shapes;
        # DeepSeek Harness 的裸 CLI（不带 profile 组合）。实际安装的是
        # modules/home/apps/dsh.nix 里按 profile 组合出来的那个；暴露这个是为了
        # `nix build .#dsh` 能单独验证上游打包没坏。
        dsh = pkgs.dsh.dsh;
      };
      formatter = pkgs.nixfmt;
    };
}
