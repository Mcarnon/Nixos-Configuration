# CI checks (security + performance regressions surface as `nix flake check`).
{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      miyuTest = pkgs.callPackage ../checks/miyu.nix { inherit inputs; };

      # The Clavis derivations are only resolvable *through* the overlay:
      # pkgs.clavisShell takes inputs.clavis-shell as its source and
      # pkgs.libcava (a fake .pc-only package) as a build input, neither of which
      # exists in plain nixpkgs. Evaluating them against `pkgs` directly would
      # either fail on a missing argument or silently pass null.
      overlayPkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ (import ../pkgs/default.nix inputs) ];
      };
    in
    {
      checks = {
        miyu-smoke = miyuTest;
        # Every tracked .nix file must at least parse. Cheap, and it catches the
        # class of edit that would otherwise only fail at nixos-rebuild time.
        nix-syntax = overlayPkgs.callPackage ../checks/nix-syntax.nix { };
        # `niri validate` over home/niri/*.kdl, plus guards that the Clavis
        # managed fragments stay `optional=true` (a required include would break
        # every niri start before Clavis runs) and that binds.kdl keeps calling
        # IPC methods the shell actually registers.
        niri-config = overlayPkgs.callPackage ../checks/niri-config.nix { };
        # The Clavis desktop shell, the `key` CLI (IPC/clipboard/recorder/sysmon)
        # and the M3Shapes QML module it imports. Building these is the only way
        # to prove the QML import roots and plugin paths in the key wrapper are
        # right -- a wrong path here shows up as a blank screen at login, not as
        # a build error.
        clavis-shell = overlayPkgs.clavisShell;
        key-cli = overlayPkgs.keyCli;
        m3shapes = overlayPkgs.m3shapes;
      };
    };
}
