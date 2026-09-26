# Clavis Shell — Quickshell desktop shell for niri.
#
# Builds the native C++ QML modules (Clavis.*, M3Shapes) and installs the QML
# source tree (Common/Components/Modules/Services/Widgets/assets/scripts) as a
# Quickshell configuration under $out/etc/xdg/quickshell/clavis. `key shell`
# (key-cli) then runs `qs -c clavis` against either that tree or the symlink
# Home Manager puts at ~/.config/quickshell/clavis.
{
  stdenv,
  lib,
  cmake,
  ninja,
  pkg-config,
  patchelf,
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
    patchelf
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtshadertools
    qt6.qttools
    qt6Packages.qtkeychain
    pipewire
    libcava # libcava.pc / cava.pc for core/CMakeLists.txt's pkg_check_modules
    fftw # required by libcava.pc's `Requires: fftw3`
  ];

  enableParallelBuilding = true;

  # QML library modules only — there is no app binary to wrap, and qtbase's
  # setup hook errors out with "no wrapping behavior was specified" without this.
  dontWrapQtApps = true;

  # core/CMakeLists.txt includes CTest and adds tests/; the QML tests want the
  # quickshell engine at runtime, which is not a build input.
  doCheck = false;

  cmakeFlags = [
    "-G Ninja"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DBUILD_TESTING=OFF"
    # Upstream installs via *relative* destinations (CLAVIS_*_INSTALL_DIR). If
    # CMAKE_INSTALL_PREFIX is not honoured the files land in the build tree and
    # $out stays empty (fixupPhase then fails on a missing $out), so pin the
    # prefix and pass absolute destinations.
    "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
    # Qt's qt_add_qml_module bakes CMAKE_BINARY_DIR into the plugin RPATH;
    # Nix's hardening scan rejects a surviving /build reference. Install with
    # $ORIGIN instead (plugins sit next to their own .so) and let the nix
    # cc-wrapper add the store paths for real dependencies.
    "-DCMAKE_BUILD_WITH_INSTALL_RPATH=ON"
    "-DCMAKE_INSTALL_RPATH=\$ORIGIN"
    "-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=OFF"
    "-DCLAVIS_QML_INSTALL_DIR=${placeholder "out"}/lib/qt6/qml"
    "-DCLAVIS_CONFIG_INSTALL_DIR=${placeholder "out"}/etc/xdg/quickshell/clavis"
    "-DCLAVIS_SYSTEMD_USER_INSTALL_DIR=${placeholder "out"}/lib/systemd/user"
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cmake --install .
    runHook postInstall
  '';

  # Sanity checks: a silently empty $out is the failure mode that produced a
  # black screen before (service started, every QML import missing).
  postInstall = ''
    test -f $out/etc/xdg/quickshell/clavis/shell.qml \
      || { echo "clavis: shell.qml missing from $out" >&2; exit 1; }
    test -d $out/lib/qt6/qml/Clavis \
      || { echo "clavis: native QML modules missing from $out" >&2; exit 1; }
    test -x $out/etc/xdg/quickshell/clavis/scripts/theme/generate_matugen_colors.sh \
      || { echo "clavis: theme scripts missing from $out" >&2; exit 1; }
  '';

  # Belt and braces: scrub any /build reference that survived the CMake flags.
  postFixup = ''
    for so in $(find "$out" -name '*.so'); do
      rpath="$(patchelf --print-rpath "$so" 2>/dev/null || true)"
      if echo "$rpath" | grep -q '/build/'; then
        patchelf --set-rpath "$rpath" --remove-rpath '/build[^:]*' "$so" 2>/dev/null || \
          patchelf --set-rpath '$ORIGIN' "$so"
      fi
    done
  '';

  meta = with lib; {
    description = "Quickshell desktop shell for niri (Clavis)";
    homepage = "https://github.com/xy1092/clavis-shell";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
