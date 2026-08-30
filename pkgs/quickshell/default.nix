# Quickshell engine (qs binary) — built from the quickshell repo source.
# The same source tree also provides Clavis shell QML/config.
{
  stdenv,
  lib,
  cmake,
  ninja,
  pkg-config,
  qt6,
  qt6Packages,
  src,
}:
stdenv.mkDerivation {
  pname = "quickshell";
  version = "0.1.0";
  inherit src;

  nativeBuildInputs = [ cmake ninja pkg-config ];
  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtwayland
  ];

  cmakeFlags = [
    "-G Ninja"
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  meta = with lib; {
    description = "Quickshell desktop shell engine";
    homepage = "https://github.com/StatIndet/quickshell";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
