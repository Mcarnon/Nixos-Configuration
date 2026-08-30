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
      };
      formatter = pkgs.nixfmt;
    };
}
