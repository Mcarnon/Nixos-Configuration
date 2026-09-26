# Overlay aggregator for custom packages (performance: single eval path;
# security: all custom binaries audited in one place via `nix flake check`).
# Consumers use `pkgs.clavisShell` / `pkgs.keyCli` / `pkgs.keytop` instead of
# ad-hoc `callPackage` at call sites.
# Takes `inputs` so the source trees come from pinned flake inputs.
inputs: final: prev:
let
  lib = prev.lib;
in
{
  miyu = prev.callPackage ./miyu { };

  # AIRI 用本仓库 nixpkgs 构建（airi 自带 flake 内部对 electron_41 无 insecure 豁免；
  # 豁免见 modules/nixos/core/nix.nix 的 permittedInsecurePackages）。
  airi = prev.callPackage "${inputs.airi}/nix/package.nix" { };

  # cava 的分析核心（cavacore）单独打包成库：Clavis 通过 pkg-config 链接它，
  # 而 nixpkgs 的 `cava` 只构建 autotools 的可执行文件。
  libcava = prev.callPackage ./libcava { };

  clavisShell = prev.callPackage ./clavis-shell {
    src = inputs."clavis-shell";
  };

  keyCli = prev.callPackage ./key-cli {
    src = inputs."key-cli";
    clavisShell = final.clavisShell;
    quickshell = final.quickshell;
    qt5compat = final.qt6.qt5compat; # Qt5Compat.GraphicalEffects（clavis QML 大量使用）
    qtlottie = final.qt6.qtlottie; # Qt.labs.lottieqt（天气动画）
    matugen = final.matugen;
    cliphist = final.cliphist;
    wl-clipboard = final.wl-clipboard;
    gpu-screen-recorder = final.gpu-screen-recorder;
    ffmpeg = final.ffmpeg;
    slurp = final.slurp;
    pipewire = final.pipewire; # pactl（录音声源解析）
    awww = final.awww; # 壁纸后端
  };

  keytop = prev.callPackage ./keytop {
    src = inputs."keytop";
  };
}
