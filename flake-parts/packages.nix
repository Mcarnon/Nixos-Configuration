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
        # AIRI is built on EOL electron_41; exempt it here too so `.#airi` builds.
        config.permittedInsecurePackages = [ "electron-41.10.6" ];
      };
    in
    {
      packages = {
        inherit (pkgs) miyu airi;
        # Clavis desktop shell stack. `keyCli` is the interesting one: its wrapper
        # is what wires the QML import roots together, so building it catches
        # missing/renamed QML modules and a Clavis install prefix that moved.
        inherit (pkgs) clavisShell keyCli m3shapes;
      };
      formatter = pkgs.nixfmt;
    };
}
