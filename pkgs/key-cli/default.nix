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
      --prefix QML_IMPORT_PATH : "${clavisShell}/lib/qt6/qml:${qt5compat}/lib/qt6/qml:${qtlottie}/lib/qt6/qml" \
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
