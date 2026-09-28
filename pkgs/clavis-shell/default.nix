# Clavis Shell — Quickshell desktop shell for niri.
#
# Builds the native C++ QML modules (Clavis.*) and installs the QML source tree
# (Common/Components/Modules/Services/Widgets/assets/scripts/matugen) as a
# Quickshell configuration under $out/etc/xdg/quickshell/clavis. `key shell`
# (key-cli) then runs `qs -c clavis` against either that tree or the symlink
# Home Manager puts at ~/.config/quickshell/clavis.
#
# Build inputs are derived from upstream packaging/dependencies.json ("build"
# list) plus core/CMakeLists.txt + core/plugin/*/CMakeLists.txt, which is the
# authoritative statement of what is find_package'd / pkg_check_modules'd:
#   Qt6 Core Gui Qml Quick Network ShaderTools LinguistTools  -> qt6.qtbase + qt6.qtdeclarative + qtshadertools + qttools
#   Qt6Keychain                                              -> qt6Packages.qtkeychain
#   Qt6 WaylandClient DBus (Clavis.Gamma)                    -> qt6.qtwayland
#   libudev / libpipewire-0.3 / libcava                     -> systemd / pipewire / libcava
#   xkbcommon (Clavis.Keyboard)                              -> libxkbcommon
#   wayland-client + wayland-protocols>=1.41 + wayland-scanner -> wayland / wayland-protocols (Clavis.WindowPreview)
#
# QtLocation/QtPositioning/maplibre-native-qt are deliberately NOT build inputs:
# Clavis.WeatherMap only links Core/Gui/Qml/Network, the map is a *QML* plugin
# resolved at runtime. They belong on QML_IMPORT_PATH/QT_PLUGIN_PATH, which
# pkgs/key-cli sets up.
{
  stdenv,
  lib,
  cmake,
  ninja,
  pkg-config,
  patchelf,
  python3,
  fetchurl,
  qt6,
  qt6Packages,
  pipewire,
  libcava,
  fftw,
  systemd,
  libxkbcommon,
  wayland,
  wayland-protocols,
  src,
}:
let
  # Top-level CMakeLists.txt does `file(STRINGS .../VERSION)`, so the file is a
  # single trailing-newline-terminated date string. Trim defensively: the
  # version ends up in the store path, and a stray \n there is silent breakage.
  version = lib.removeSuffix "\n" (lib.removeSuffix "\r" (builtins.readFile "${src}/VERSION"));

  # assets/icons/weather/meteocons is gitignored upstream: release.py downloads
  # the two npm tarballs recorded in packaging/dependencies.json. A source build
  # would otherwise ship a shell with no weather icons, so do the same here.
  #
  # The `sha256` fields in packaging/dependencies.json are 48 hex chars (24
  # bytes), which is not a valid SRI sha256, and they do not decode to the real
  # digest either -- copying them verbatim fails evaluation with
  # "invalid SRI hash ... length 48 != expected length 32". These are the true
  # `nix store prefetch-file` hashes for the same URLs.
  meteocons = rec {
    svg = fetchurl {
      url = "https://registry.npmjs.org/@meteocons/svg/-/svg-0.1.0.tgz";
      hash = "sha256-kbSNH4SX2ej07R1bzDLTBqqlBQ3pnDhGfCpY963VpQE=";
    };
    lottie = fetchurl {
      url = "https://registry.npmjs.org/@meteocons/lottie/-/lottie-0.1.0.tgz";
      hash = "sha256-Q+onMqvejkKcT8VqJ7ss79hT+MNKkEtX+GpLWivxoT0=";
    };
  };
in
stdenv.mkDerivation {
  pname = "clavis-shell";
  inherit version;

  inherit src;

  # unpackPhase writes a writable copy to ./source; without an explicit
  # sourceRoot nixpkgs stays in /build and the cmake hook mistakes the build
  # directory for the source tree ("The source directory /build does not appear
  # to contain CMakeLists.txt").
  sourceRoot = "source";

  nativeBuildInputs = [
    # `cmake` in nativeBuildInputs is what supplies the configure/build/install
    # phases (its setup hooks); there is no separate `cmakeHook` attribute to
    # pass in, and asking callPackage for one fails evaluation outright.
    cmake
    ninja
    pkg-config
    patchelf
    # Top-level CMakeLists.txt runs scripts/dev/generate-search-catalog.py to
    # (re)generate Common/generated/SearchCatalog.js.
    python3
    # Clavis.WindowPreview / Clavis.Gamma shell out to wayland-scanner.
    wayland
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtshadertools
    qt6.qttools
    qt6.qtwayland
    qt6Packages.qtkeychain
    pipewire
    libcava # libcava.pc / cava.pc for core/CMakeLists.txt's pkg_check_modules
    fftw # required by libcava.pc's `Requires: fftw3`
    systemd # libudev.pc (headers in the `dev` output, both land on PKG_CONFIG_PATH)
    libxkbcommon
    wayland # wayland-client.pc
    wayland-protocols # wayland-protocols.pc, needs >= 1.41 for the staging capture protocols
  ];

  enableParallelBuilding = true;

  # QML library modules only — there is no app binary to wrap, and qtbase's
  # setup hook errors out with "no wrapping behavior was specified" without this.
  dontWrapQtApps = true;

  # core/CMakeLists.txt includes CTest and adds tests/; the QML tests want the
  # quickshell engine at runtime, which is not a build input.
  doCheck = false;

  # The build writes Common/generated/SearchCatalog.js back *into the source
  # tree* (top-level add_custom_command OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/...).
  # A flake input is read-only in the store, so unpack a writable copy first.
  unpackPhase = ''
    runHook preUnpack
    cp -r --reflink=auto ${src} source
    chmod -R u+w source
    runHook postUnpack
  '';

  # Same reason: the generated catalog is an OUTPUT of a custom command, so if
  # the committed copy happens to be older than its DEPENDS, make would re-run
  # the generator and try to write into the read-only copy again. Generate it
  # once here (the script writes the file itself) so make sees a fresh OUTPUT.
  # This is the preBuild *hook*, so it must not call `runHook preBuild` itself.
  # The build runs out-of-source: configurePhase leaves cwd inside $sourceRoot/build,
  # so use a path relative to that dir (../ walks back to the tree root).
  preBuild = ''
    python3 "$PWD/../scripts/dev/generate-search-catalog.py"
  '';

  postUnpack = ''
    mkdir -p source/assets/icons/weather/meteocons
    tar -xzf ${meteocons.svg} -C source/assets/icons/weather/meteocons
    mv source/assets/icons/weather/meteocons/package source/assets/icons/weather/meteocons/svg
    tar -xzf ${meteocons.lottie} -C source/assets/icons/weather/meteocons
    mv source/assets/icons/weather/meteocons/package source/assets/icons/weather/meteocons/lottie
  '';

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

  # nixpkgs' cmake hooks build out-of-source: configurePhase runs `cmake ..`
  # from $sourceRoot/build, then buildPhase runs `cmake --build build` and
  # installPhase `cmake --install build` (that is why build/ files exist next
  # to the tree and why `-B`/`-S` are not needed). Install destinations are
  # absolute CLAVIS_* paths above, so they cannot fall into the build tree.

  # Sanity checks: a silently empty $out is the failure mode that produced a
  # black screen before (service started, every QML import missing).
  postInstall = ''
    test -f $out/etc/xdg/quickshell/clavis/shell.qml \
      || { echo "clavis: shell.qml missing from $out" >&2; exit 1; }
    test -d $out/lib/qt6/qml/Clavis \
      || { echo "clavis: native QML modules missing from $out" >&2; exit 1; }
    test -x $out/etc/xdg/quickshell/clavis/scripts/theme/generate_matugen_colors.sh \
      || { echo "clavis: theme scripts missing from $out" >&2; exit 1; }
    test -f $out/etc/xdg/quickshell/clavis/matugen/config.toml \
      || { echo "clavis: matugen templates missing from $out" >&2; exit 1; }
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
    homepage = "https://github.com/StatIndet/quickshell";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
