# Overlay aggregator for custom packages (performance: single eval path;
# security: all custom binaries audited in one place via `nix flake check`).
# Add custom packages here as `final: prev: { myPkg = prev.callPackage ./myPkg { }; }`.
final: prev: { }
