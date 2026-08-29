# keytop — standalone system monitor TUI (Clavis companion).
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
  version = "0.2.0";

  inherit src;

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ];

  buildInputs = [
    qt6.qtbase
    ncurses
  ];

  cmakeFlags = [
    "-G Ninja"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DBUILD_TESTING=OFF"
  ];

  meta = with lib; {
    description = "Standalone system monitor TUI (Clavis companion)";
    homepage = "https://github.com/StatIndet/keytop";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "keytop";
  };
}
