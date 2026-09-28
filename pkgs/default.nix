# Overlay aggregator for custom packages (performance: single eval path;
# security: all custom binaries audited in one place via `nix flake check`).
# Consumers use `pkgs.miyu` / `pkgs.clavisShell` / `pkgs.keyCli` instead of
# ad-hoc `callPackage` at call sites.
#
# `inputs` is kept in the signature so the source trees come from pinned flake
# inputs without touching the call sites.
#
# The desktop shell is Clavis Shell. Both of its repositories ship no
# `flake.nix`, so they enter the flake as plain source trees
# (`flake = false`) and are packaged here:
#   * pkgs/clavis-shell  — native Clavis.* QML plugins + the QML tree
#   * pkgs/key-cli       — the `key` command (`key shell`, IPC, clipboard,
#                          sysmon); the wrapper that pins qs/QML_IMPORT_PATH
#                          also lives there, so the shell is self-contained.
# Everything else (quickshell, m3shapes, libcava, matugen, ...) comes straight
# from this flake's nixpkgs.
inputs: final: prev: {
  miyu = prev.callPackage ./miyu { };

  clavisShell = prev.callPackage ./clavis-shell {
    src = inputs."clavis-shell";
  };

  keyCli = prev.callPackage ./key-cli {
    src = inputs."key-cli";
    clavisShell = final.clavisShell;
    m3shapes = inputs.m3shapes.packages.${final.stdenv.hostPlatform.system}.default;
  };
}
