# M3Shapes — Qt6 QML module (URI `M3Shapes`) for Material 3 Expressive shapes.
#
# Clavis imports M3Shapes 20 times (button/keystone morphing, pressed/toggled
# states) and upstream lists `qt6-m3shapes-git` as a *required* runtime
# dependency: "M3Shapes remains an external QML module and is never built or
# vendored by Clavis" (docs/dependencies.md). A missing import root is a fatal
# QML load error, so this has to be on QML_IMPORT_PATH next to Clavis itself.
#
# Modelled on the derivation the project ships in its own nix/default.nix; the
# fileset there (`root = ./..`) only holds the flake root in-tree, so this
# version just uses the flake input as the source.
{
  lib,
  stdenv,
  cmake,
  ninja,
  qt6,
  src,
}:
stdenv.mkDerivation {
  pname = "m3shapes";
  version = "1.0.0";

  inherit src;

  nativeBuildInputs = [
    cmake
    ninja
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtshadertools
  ];

  # QML library module only, no app binary. The plugin installs its own $ORIGIN
  # rpath back to the backing library (see core CMakeLists.txt).
  dontWrapQtApps = true;

  cmakeFlags = [
    # Upstream's default is ${CMAKE_INSTALL_LIBDIR}/qt6/qml (the Arch path);
    # nixpkgs' Qt lives under lib/qt-6/qml, so the import root has to follow.
    (lib.cmakeFeature "INSTALL_QMLDIR" qt6.qtbase.qtQmlPrefix)
    (lib.cmakeBool "M3SHAPES_BUILD_EXAMPLES" false)
  ];

  cmakeBuildType = "RelWithDebInfo";

  # There is no headless test target: the only test surface upstream ships is the
  # gallery example, which is a QQuickView and is disabled above anyway.
  doCheck = false;

  postInstall = ''
    test -f $out/${qt6.qtbase.qtQmlPrefix}/M3Shapes/qmldir \
      || { echo "m3shapes: qmldir missing from \$$out" >&2; exit 1; }
  '';

  meta = {
    description = "Qt6 QML module implementing Material 3 Expressive shapes";
    homepage = "https://github.com/soramanew/m3shapes";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
