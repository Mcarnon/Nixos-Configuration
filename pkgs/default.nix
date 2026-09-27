# Overlay aggregator for custom packages (performance: single eval path;
# security: all custom binaries audited in one place via `nix flake check`).
# Consumers use `pkgs.miyu` instead of ad-hoc `callPackage` at call sites.
# `inputs` is kept in the signature so future source trees can come from
# pinned flake inputs without touching the call sites.
#
# iNiR 桌面壳不再走这里：它自带 flake（NixOS/Home Manager 模块 + 打包），
# 由 modules/home/desktop/inir 直接导入 `inputs.inir.homeManagerModules.default`。
inputs: _final: prev: {
  miyu = prev.callPackage ./miyu { };
}
