# keytop — standalone system monitor TUI (Clavis companion).
# Clavis' system cards read keytop's JSON/JSONL metrics stream, so the shell
# expects the binary to be installed.
{
  stdenv,
  lib,
  cmake,
  ninja,
  pkg-config,
  qt6,
  ncurses,
  src,
}:
stdenv.mkDerivation {
  pname = "keytop";
  version = "0.1.0";

  inherit src;

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    ncurses
  ];

  enableParallelBuilding = true;

  cmakeFlags = [
    "-G Ninja"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DBUILD_TESTING=OFF"
    "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
  ];

  doCheck = false;

  meta = with lib; {
    description = "Standalone system monitor TUI (Clavis companion)";
    homepage = "https://github.com/xy1092/keytop";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "keytop";
  };
}
