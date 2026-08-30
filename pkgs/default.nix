# Overlay aggregator for custom packages (performance: single eval path;
# security: all custom binaries audited in one place via `nix flake check`).
# Consumers use `pkgs.clavisShell` / `pkgs.keyCli` / `pkgs.keytop` instead of
# ad-hoc `callPackage` at call sites.
# Takes `inputs` so the source trees can come from pinned flake inputs.
inputs: final: prev:
let
  lib = prev.lib;
in
{
  miyu = prev.callPackage ./miyu { };

  # cava's analysis core as a library (Clavis links it via pkg-config).
  libcava = prev.callPackage ./libcava { };

  quickshell = prev.callPackage ./quickshell {
    src = inputs."clavis-shell";
  };

  clavisShell = prev.callPackage ./clavis-shell {
    src = inputs."clavis-shell";
  };

  keyCli = prev.callPackage ./key-cli {
    src = inputs."key-cli";
    clavisShell = final.clavisShell;
    quickshell = final.quickshell;
    matugen = final.matugen;
    cliphist = final.cliphist;
    wl-clipboard = final.wl-clipboard;
    gpu-screen-recorder = final.gpu-screen-recorder;
    ffmpeg = final.ffmpeg;
    slurp = final.slurp;
    pipewire = final.pipewire;
  };

  keytop = prev.callPackage ./keytop {
    src = inputs."keytop";
  };
}
