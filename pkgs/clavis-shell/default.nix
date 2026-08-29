# Clavis Shell — Quickshell desktop shell for niri.
# Builds the native C++ QML modules (Clavis.*, M3Shapes) plus the QML source
# tree / config. The `key` launcher (from key-cli) runs `qs -c clavis`.
{
  stdenv,
  lib,
  cmake,
  ninja,
  autoPatchelfHook,
  pkg-config,
  qt6,
  qt6Packages,
  pipewire,
  cava,
  src,
}:
stdenv.mkDerivation {
  pname = "clavis-shell";
  version = "0.2.0";

  inherit src;

  nativeBuildInputs = [
    cmake
    ninja
    autoPatchelfHook
    pkg-config
  ];

  buildInputs = [
    qt6.full
    qt6Packages.qtkeychain
    pipewire
    cava
  ];

  # autoPatchelfHook rewrites the native .so plugins' rpath to the Qt / pipewire
  # / cava store paths so they load at runtime.
  runtimeDependencies = [
    qt6.qtbase
    qt6Packages.qtkeychain
    pipewire
    cava
  ];

  cmakeFlags = [
    "-G Ninja"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCLAVIS_QML_INSTALL_DIR=lib/qt6/qml"
    "-DCLAVIS_CONFIG_INSTALL_DIR=etc/xdg/quickshell/clavis"
    "-DCLAVIS_SYSTEMD_USER_INSTALL_DIR=lib/systemd/user"
  ];

  meta = with lib; {
    description = "Quickshell desktop shell for niri (Clavis)";
    homepage = "https://github.com/StatIndet/quickshell";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
