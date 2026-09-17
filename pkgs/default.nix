# Overlay aggregator for custom packages (performance: single eval path;
# security: all custom binaries audited in one place via `nix flake check`).
# Today only `miyu` is built from source; the desktop shell comes from nixpkgs.
inputs: final: prev:
{
  miyu = prev.callPackage ./miyu { };
  # AIRI 用本仓库 nixpkgs 构建（airi 自带 flake 内部对 electron_41 无 insecure 豁免；
  # 豁免见 modules/nixos/core/nix.nix 的 permittedInsecurePackages）。
  airi = prev.callPackage "${inputs.airi}/nix/package.nix" { };
}
