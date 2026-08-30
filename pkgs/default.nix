# Overlay aggregator for custom packages (performance: single eval path;
# security: all custom binaries audited in one place via `nix flake check`).
# Consumers use `pkgs.miyu` instead of ad-hoc `callPackage` at call sites.
# Takes `inputs` so source trees can come from pinned flake inputs.
inputs: final: prev:
{
  miyu = prev.callPackage ./miyu { };
}
