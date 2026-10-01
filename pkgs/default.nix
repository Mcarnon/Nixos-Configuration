# Overlay aggregator for custom packages (performance: single eval path;
# security: all custom binaries audited in one place via `nix flake check`).
# Consumers use `pkgs.clavisShell` / `pkgs.keyCli` instead of ad-hoc
# `callPackage` at call sites.
# Takes `inputs` so the source trees come from pinned flake inputs.
inputs: final: prev: {
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
  dsh =
    let
      upstream = inputs."deepseek-harness".overlays.default final prev;
      scope = upstream.dsh;

      # ---- dsh-TUI 0.12.0 覆盖（上游还没 bump 的临时补丁）----
      #
      # 上游 rev 9f53b70 的版本错位：dsh 内核已被 commit 150be1c 升到
      # 0.2.0-rc.2，而 pkgs/bundles/tui 还钉在 dsh-TUI v0.11.2（10dd3bb），
      # 它的 peerDependencies 只列到 0.2.0-rc.1 —— 组合后 dshBundleCheckHook
      # 在 installCheckPhase 直接判定不兼容并 exit 1（`nix run #presets.tui`
      # 同样坏）。上游 HEAD（2026-10-01）最后一个 bundles.tui 提交仍是 10dd3bb，
      # 没有现成修复可抄。改用 pkgs/dsh-tui/（0.12.0，peer 已含 0.2.0-rc.2），
      # 差异与删除条件都写在那里的文件头。
      #
      # scope 里的 buildDshBundle / copyTree / fetchPnpmDeps / dsh-kernel 是 dsh
      # 打包协议的入口，必须用本仓库 nixpkgs 的 final 构造的那个 —— 传 scope.*。
      tui = import ./dsh-tui {
        inherit (scope)
          buildDshBundle
          copyTree
          dsh-kernel
          fetchPnpmDeps
          ;
        pnpmConfigHook = final.pnpmConfigHook;
        pnpm_11 = final.pnpm_11;
        lib = final.lib;
        fetchFromGitHub = final.fetchFromGitHub;
      };
    in
    # 两处都要改，只改一处会得到「版本冲突」而不是「装上了」：
    #   - `bundles.tui`：让消费方（modules/home/apps/dsh.nix 的 profiles）
    #     拿到 0.12.0。
    #   - `dsh.override { bundles = ... }`：`scope.dsh` 是在 scope 建立时
    #     通过 callPackage 绑定 **原始** bundles 的（overlays/default.nix 的
    #     directoryPackages），overrideScope 事后改 `bundles` 属性不会回溯
    #     改写 dsh 包内部的 `tuiBundle`（pkgs/dsh/package.nix:83）。
    #     profiles.nix 的 profileBundles 会把 needsTui 的 tuiBundle 与 profile
    #     自己声明的 bundles 一起 lib.unique 收集，于是
    #     dsh-profile-*-template 在 dshBundleResolver 阶段报
    #     "conflicting bundle metadata for @deepseek-harness-tui/dsh-tui:
    #      0.11.2 ... vs 0.12.0 ..."。
    scope.overrideScope (
      self: super: {
        bundles = super.bundles.overrideScope (
          _bundlesSelf: bundlesPrev: {
            inherit tui;
          }
        );
        dsh = super.dsh.override { bundles = self.bundles; };
      }
    );
}
