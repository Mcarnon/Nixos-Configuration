# Clavis Shell — Quickshell desktop shell for niri.
# Builds the native C++ QML modules (Clavis.*, M3Shapes) plus the QML source
# tree / config. The `key` launcher (from key-cli) runs `qs -c clavis`.
{
  stdenv,
  lib,
  cmake,
  ninja,
  pkg-config,
  qt6,
  qt6Packages,
  pipewire,
  libcava,
  fftw,
  src,
}:
stdenv.mkDerivation {
  pname = "clavis-shell";
  version = "0.2.0";

  inherit src;

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtshadertools
    qt6.qttools
    qt6Packages.qtkeychain
    pipewire
    libcava # provides libcava.pc / cava.pc for the CMake pkg_check_modules
    fftw # required by libcava.pc's `Requires: fftw3`
  ];

  # QML library modules + config only — no installable app binary to wrap.
  # Without this, qtbase's setup hook fails the build with
  # "depends on qtbase, but no wrapping behavior was specified".
  dontWrapQtApps = true;

  cmakeFlags = [
    "-G Ninja"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCLAVIS_QML_INSTALL_DIR=lib/qt6/qml"
    "-DCLAVIS_CONFIG_INSTALL_DIR=etc/xdg/quickshell/clavis"
    "-DCLAVIS_SYSTEMD_USER_INSTALL_DIR=lib/systemd/user"
    "-DCMAKE_PREFIX_PATH=$out"
  ];

  meta = with lib; {
    description = "Quickshell desktop shell for niri (Clavis)";
    homepage = "https://github.com/StatIndet/quickshell";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
