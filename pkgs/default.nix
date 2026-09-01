# Overlay aggregator for custom packages (performance: single eval path;
# security: all custom binaries audited in one place via `nix flake check`).
# Today only `miyu` is built from source; the desktop shell comes from nixpkgs.
inputs: final: prev:
{
  miyu = prev.callPackage ./miyu { };
}
