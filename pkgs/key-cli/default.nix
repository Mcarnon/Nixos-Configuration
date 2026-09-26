# key-cli — the `key` command: Clavis shell lifecycle/IPC, clipboard, recording.
#
# Pure Python (PEP 517, no runtime dependencies). Everything it shells out to
# lives in PATH, so postFixup wraps `key` with the engine (`qs`), Clavis' native
# QML modules and the feature binaries — without those, `key shell` starts qs
# and every QML import fails.
{
  python3Packages,
  makeWrapper,
  clavisShell,
  quickshell,
  qt5compat,
  qtlottie,
  matugen,
  cliphist,
  wl-clipboard,
  gpu-screen-recorder,
  ffmpeg,
  slurp,
  pipewire,
  awww,
  lib,
  src,
  ...
}:
let
  # nixpkgs 的 Qt6 把 QML 模块装在 lib/qt-6/qml（qtbase 的 qtQmlPrefix），
  # 不是 lib/qt6/qml。手写路径拼 QML_IMPORT_PATH 时用错目录的后果是静默的：
  # qs 启动后才报 `module "Qt5Compat.GraphicalEffects" is not installed`，
  # 整机表现就是黑屏（服务起来、外壳一个面板都不画）。
  # 目录名只在这里写一次；刻意不套 lib.makeSearchPathOutput —— 它的参数表在
  # 2025-09 改过（多了 output 首参），跨 nixpkgs 版本写死一种必然踩坑。
  qmlRoots = map (p: "${p}/lib/qt-6/qml") [
    clavisShell # Clavis.* / M3Shapes（clavis-shell 自建）
    qt5compat # Qt5Compat.GraphicalEffects：模糊/阴影等效果
    qtlottie # Qt.labs.lottieqt：天气动画
  ];
  qmlImportPath = lib.concatStringsSep ":" qmlRoots;
  qmlRootsSh = lib.concatStringsSep " " qmlRoots;
in
python3Packages.buildPythonApplication {
  pname = "key-cli";
  version = "0.2.0";

  inherit src;
  format = "pyproject";

  dependencies = [ ];

  nativeBuildInputs = [
    makeWrapper
    python3Packages.setuptools
  ];

  doCheck = false;

  # `key` execs `qs`, which needs:
  #   - clavisShell's native QML modules (Clavis.*, M3Shapes)
  #   - qt5compat  -> Qt5Compat.GraphicalEffects (heavily used by Clavis QML)
  #   - qtlottie   -> Qt.labs.lottieqt (animated weather)
  #   - awww       -> wallpaper backend used by the shell
  # Without qt5compat/qtlottie on QML_IMPORT_PATH the shell dies at load time.
  postFixup = ''
    # 在构建期就断言 QML 模块真的在某个 import 根下：以前这类路径写错只会在
    # 登录后变成"服务活着但全黑"，排查成本极高。
    for d in Clavis Qt5Compat/GraphicalEffects; do
      found=""
      for p in ${qmlRootsSh}; do
        if [ -e "$p/$d" ]; then
          found="$p"
          break
        fi
      done
      if [ -z "$found" ]; then
        echo "key-cli: QML module dir '$d' not under any of: ${qmlRootsSh}" >&2
        exit 1
      fi
    done

    wrapProgram "$out/bin/key" \
      --prefix PATH : "${
        lib.makeBinPath [
          quickshell
          matugen
          cliphist
          wl-clipboard
          gpu-screen-recorder
          ffmpeg
          slurp
          pipewire
          awww
        ]
      }" \
      --prefix QML_IMPORT_PATH : "${qmlImportPath}" \
      --prefix XDG_CONFIG_DIRS : "${clavisShell}/etc/xdg"
  '';

  meta = with lib; {
    description = "Clavis `key` command: shell IPC, lifecycle, clipboard & recording";
    homepage = "https://github.com/xy1092/key-cli";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "key";
  };
}
