# Overlay aggregator for custom packages (performance: single eval path;
# security: all custom binaries audited in one place via `nix flake check`).
# Consumers use `pkgs.clavisShell` / `pkgs.keyCli` instead of ad-hoc
# `callPackage` at call sites.
# Takes `inputs` so the source trees come from pinned flake inputs.
inputs: final: prev:
{
  miyu = prev.callPackage ./miyu { };

  # AIRI 用本仓库 nixpkgs 构建（airi 自带 flake 内部对 electron_41 无 insecure 豁免；
  # 豁免见 modules/nixos/core/nix.nix 的 permittedInsecurePackages）。
  airi = prev.callPackage "${inputs.airi}/nix/package.nix" { };

  # 旧版 SPlayer：解包官方 AppImage（上游 SPlayer-Dev/SPlayer 已归档）。
  # 有意不用 nixpkgs 的 splayer-next —— 后者是上游指定的后继项目，
  # 理由见 pkgs/splayer/default.nix 头部注释。
  splayer = prev.callPackage ./splayer { };

  # cava 的分析核心（cavacore）单独打包成库：Clavis 通过 pkg-config 链接它，
  # 而 nixpkgs 的 `cava` 只构建 autotools 的可执行文件。
  libcava = prev.callPackage ./libcava { };

  # Clavis 的 Material 3 形状 QML 模块（import M3Shapes）。上游把它列为必需
  # 运行时依赖且从不 vendor，所以必须自己打包。
  m3shapes = prev.callPackage ./m3shapes {
    src = inputs.m3shapes;
  };

  clavisShell = prev.callPackage ./clavis-shell {
    src = inputs.clavis-shell;
    # MUST come from `final`, not `prev`: callPackage resolves missing args from
    # `prev`, and prev has no `libcava` — the attribute only exists once this
    # overlay is applied. Left implicit it silently becomes null, and
    # core/CMakeLists.txt's `pkg_check_modules(Cava REQUIRED)` then fails at
    # configure time with a confusing "libcava not found".
    libcava = final.libcava;
  };

  keyCli = prev.callPackage ./key-cli {
    src = inputs.key-cli;
    clavisShell = final.clavisShell;
    m3shapes = final.m3shapes;
    quickshell = final.quickshell;
    qt5compat = final.qt6.qt5compat; # Qt5Compat.GraphicalEffects（Clavis QML 大量使用）
    qtlottie = final.qt6.qtlottie; # Qt.labs.lottieqt（天气动画）
    qtsvg = final.qt6.qtsvg; # Qt SVG 图像插件
    qtimageformats = final.qt6.qtimageformats;
    qtlocation = final.qt6.qtlocation; # QtLocation（天气地图 / 地理位置）
    qtpositioning = final.qt6.qtpositioning; # QtPositioning（GNSS）
    qtwayland = final.qt6.qtwayland; # Clavis.Gamma / wayland platform 插件
    maplibreNativeQt = final.maplibre-native-qt; # QMapLibre + QtLocation 地图插件
    matugen = final.matugen;
    cliphist = final.cliphist;
    wl-clipboard = final.wl-clipboard;
    gpu-screen-recorder = final.gpu-screen-recorder;
    ffmpeg = final.ffmpeg;
    slurp = final.slurp;
    pulseaudio-utils = final.pulseaudio-utils; # pactl（录音声源解析，`key doctor` 依赖）
    qalculate = final.qalculate; # qalc（Spotlight 计算器）
    xdg-terminal-exec = final.xdg-terminal-exec;
    awww = final.awww; # 可选壁纸后端
  };

  # DeepSeek Harness 上游的 overlay（inputs."deepseek-harness".overlays.default）。
  # 两点必须做对，否则下游全是玄学报错：
  #   1. 上游 overlay 返回的是 `{ dsh = <scope>; }`，所以要取 `.dsh`，否则
  #      `pkgs.dsh` 会变成 `{ dsh = scope; }`：homeModules 的
  #      `lib.mkPackageOption pkgs.dsh "dsh"` 会报 “not of type 'package'”，
  #      而 `pkgs.dsh.bundles.*` 直接 attribute missing。
  #   2. 必须把本仓库的 final/prev 传进去（scope 内部靠 `final` 取依赖），
  #      不能自己 `import inputs.nixpkgs` 再套，否则 scope 会退回上游自带的
  #      nixpkgs，flake.nix 里的 follows 就白写了。
  # 消费方：modules/home/apps/dsh.nix 的 programs.dsh。
  # 注意：不要再导入上游 nixosModules.default —— 它会再叠一层同样的 overlay。
  dsh = (inputs."deepseek-harness".overlays.default final prev).dsh;
}
