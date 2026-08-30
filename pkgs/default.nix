# Overlay aggregator for custom packages (performance: single eval path;
# security: all custom binaries audited in one place via `nix flake check`).
# Consumers use `pkgs.miyu`; everything else (quickshell, cliphist, etc.) comes
# straight from nixpkgs.
#
# libcava stays in the overlay because clavis-style Quickshell configs (or
# older community shells) often bundle cava-as-a-library, and nixpkgs'
# `cava` package ships only the executable.
inputs: final: prev:
let
  lib = prev.lib;
in
{
  miyu = prev.callPackage ./miyu { };

  # cava's analysis core as an installable library (cavacore).
  libcava = prev.callPackage ./libcava { };
}
