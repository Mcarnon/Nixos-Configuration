# key-cli — the `key` command: Clavis shell IPC / lifecycle, clipboard & recording.
# Pure Python (PEP 517). We wrap the `key` console script so it can find the
# Quickshell engine, Clavis' native QML modules and the feature binaries.
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
  lib,
  src,
  ...
}:
python3Packages.buildPythonApplication {
  pname = "key-cli";
  version = "0.2.0";

  inherit src;
  format = "pyproject";

  # No Python runtime deps are declared upstream; the real deps are external CLIs.
  dependencies = [ ];

  nativeBuildInputs = [
    makeWrapper
    python3Packages.setuptools
  ];

  doCheck = false;

  # `key` execs `qs` and needs Clavis' QML modules + config on the search path.
  # QML_IMPORT_PATH 除了 clavisShell 的原生模块，还要带上 qt5compat
  # （Qt5Compat.GraphicalEffects：clavis 的 SystemBatteryTank/桌面卡片等大量
  # 依赖）和 qtlottie（Qt.labs.lottieqt：天气动画）——否则 QML 加载在
  # "module not installed" 处失败，整个 shell 起不来。
  postFixup = ''
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
        ]
      }" \
      --prefix QML_IMPORT_PATH : "${clavisShell}/lib/qt6/qml:${qt5compat}/lib/qt6/qml:${qtlottie}/lib/qt6/qml" \
      --prefix XDG_CONFIG_DIRS : "${clavisShell}/etc/xdg"
  '';

  meta = with lib; {
    description = "Clavis `key` command: shell IPC, lifecycle, clipboard & recording";
    homepage = "https://github.com/StatIndet/key-cli";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "key";
  };
}
