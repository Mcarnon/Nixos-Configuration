# Clavis Shell — Quickshell desktop shell for niri.
#
# Upstream (github:StatIndet/quickshell, package name `clavis-shell`) is a
# CMake project with no flake and no nix packaging, so everything below exists
# to make an autotools-free, distro-shaped install survive in the Nix store:
#
#   1. the native Clavis.* QML plugins (core/),
#   2. the QML tree + assets + scripts + matugen templates as a Quickshell
#      configuration under $out/etc/xdg/quickshell/clavis,
#   3. its own systemd user unit (installed for reference; the running unit is
#      declared in modules/home/desktop/clavis so we can harden ExecStart).
#
# `key shell` runs `qs -c clavis`, and Quickshell only finds the configuration
# at ~/.config/quickshell/clavis (user dir) or /etc/xdg/quickshell/clavis —
# the wrapper in pkgs/key-cli points XDG_CONFIG_DIRS at $out/etc/xdg for
# exactly that reason.
{
  stdenv,
  lib,
  cmake,
  ninja,
  pkg-config,
  patchelf,
  python3,
  gnutar, # provides `tar` for the Meteocons unpacking in preBuild
  qt6,
  qt6Packages,
  pam,
  pipewire,
  libcava,
  systemd,
  libxkbcommon,
  wayland,
  wayland-protocols,
  wayland-scanner,
  fetchurl,
  src,
}:
let
  # nixpkgs' Linux-PAM keeps the modules in $out/lib/security and does NOT
  # populate /usr/lib/security, so libpam's bare `pam_unix.so` lookup (what
  # upstream's Modules/Lock/pam/password.conf uses) has to be rewritten to the
  # absolute path. Without it the lock screen accepts no password at all, and
  # there is no error message — just a rejected password. See postInstall.
  pamUnixModule = "${pam}/lib/security/pam_unix.so";

  # Meteocons weather icons/lottie animations. Upstream fetches these two npm
  # tarballs with SHA-256 verification when it prepares a *release* source
  # archive, and explicitly does no runtime download. A plain `git clone` has
  # no icons, so pull them in here — otherwise every weather card renders
  # blank. Layout/directories come from upstream packaging/dependencies.json.
  # Digests verified against the published tarballs. `sha256:<hex>` rather than
  # SRI `sha256-<base32>`: the hex form needs no re-encoding, and Nix's
  # non-SRI fallback parses `algo:value` directly.
  meteoconsSvg = fetchurl {
    url = "https://registry.npmjs.org/@meteocons/svg/-/svg-0.1.0.tgz";
    hash = "sha256:91b48d1f8497d9e8f4ed1d5bcc32d306aaa5050de99c38467c2a58f7add5a501";
  };
  meteoconsLottie = fetchurl {
    url = "https://registry.npmjs.org/@meteocons/lottie/-/lottie-0.1.0.tgz";
    hash = "sha256:43ea2732abde8e429c4fc56a27bb2cefd853f8c34a904b57f86a4b5a2bf1a13d";
  };
in
stdenv.mkDerivation {
  pname = "clavis-shell";
  # Kept in sync with the upstream VERSION file (asserted in preBuild) instead
  # of `git describe`: the flake input is a branch-less source tree, and
  # dependencies.json names VERSION as the canonical versionFile.
  version = "2026.9.12";

  inherit src;

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    patchelf
    python3
    gnutar # nixpkgs 里 tar 的属性名是 gnutar
    wayland-scanner
    pam # only for $out/lib/security/pam_unix.so (see pamUnixModule)
    qt6.wrapQtAppsHook
    meteoconsSvg
    meteoconsLottie
  ];

  buildInputs = [
    qt6.qtbase # Core Gui Network DBus
    qt6.qtdeclarative # Qml Quick
    qt6.qtshadertools # ShaderTools
    qt6.qttools # LinguistTools
    qt6.qtsvg
    qt6.qtwayland # wlr-gamma-control client
    qt6Packages.qtkeychain
    pipewire
    libcava # libcava.pc / cava.pc for core/CMakeLists.txt's pkg_check_modules
    systemd # libudev
    libxkbcommon # shortcut key names
    wayland # single-window capture client
    wayland-protocols
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
    # The top-level CMakeLists runs scripts/dev/generate-search-catalog.py
    # through find_package(Python3 REQUIRED). The cmake setup hook only passes
    # -DPython3_EXECUTABLE when python3 happens to be wired up; be explicit.
    "-DPython3_EXECUTABLE=${lib.getExe python3}"
    # nixpkgs' Qt6 installs QML modules under lib/qt-6/qml (qtbase's
    # qtQmlPrefix), not the lib/qt6/qml upstream defaults to. Getting this
    # wrong is silent: qs starts and then reports
    # `module "Qt5Compat.GraphicalEffects" is not installed` → black screen.
    "-DCLAVIS_QML_INSTALL_DIR=${placeholder "out"}/${qt6.qtbase.qtQmlPrefix}"
    "-DCLAVIS_CONFIG_INSTALL_DIR=${placeholder "out"}/etc/xdg/quickshell/clavis"
    "-DCLAVIS_SYSTEMD_USER_INSTALL_DIR=${placeholder "out"}/lib/systemd/user"
  ];

  preBuild = ''
    # The build tree is a copy of the read-only store checkout, and the search
    # catalog generator writes Common/generated/SearchCatalog.js *into the
    # source tree* (CMakeLists.txt: OUTPUT "$CMAKE_CURRENT_SOURCE_DIR/...").
    # Without this the generator dies on EACCES and the build fails.
    chmod -R u+w .

    # `nix flake update clavis-shell` silently keeps our hand-written version
    # label; make that a build failure instead of a store path that lies.
    if [ -f VERSION ] && ! grep -qF "$version" VERSION; then
      echo "clavis: upstream VERSION is '$(tr -d '\n' < VERSION)' but this" >&2
      echo "        derivation declares version = $version" >&2
      echo "        -> update version in pkgs/clavis-shell/default.nix" >&2
      exit 1
    fi

    # Meteocons assets (see `meteoconsSvg` above). npm tarballs wrap
    # everything in a single `package/` directory, hence --strip-components=1;
    # upstream's manifest expects svg/{fill,flat,line,monochrome} and
    # lottie/fill, which is what the archives contain once stripped.
    mkdir -p assets/icons/weather/meteocons/svg assets/icons/weather/meteocons/lottie
    tar -xzf ${meteoconsSvg} -C assets/icons/weather/meteocons/svg --strip-components=1
    tar -xzf ${meteoconsLottie} -C assets/icons/weather/meteocons/lottie --strip-components=1
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cmake --install .
  '';

  # Sanity checks: a silently empty $out is the failure mode that produced a
  # black screen before (service started, every QML import missing).
  postInstall = ''
    runHook postInstall

    test -f $out/etc/xdg/quickshell/clavis/shell.qml \
      || { echo "clavis: shell.qml missing from $out" >&2; exit 1; }
    test -d "$out/${qt6.qtbase.qtQmlPrefix}/Clavis" \
      || { echo "clavis: native QML modules missing from $out" >&2; exit 1; }
    test -x $out/etc/xdg/quickshell/clavis/scripts/theme/generate_matugen_colors.sh \
      || { echo "clavis: theme scripts missing from $out" >&2; exit 1; }
    test -f $out/etc/xdg/quickshell/clavis/matugen/config.toml \
      || { echo "clavis: matugen templates missing from $out" >&2; exit 1; }

    # Lock screen auth: point upstream's PAM service file at nixpkgs' module.
    test -e ${pamUnixModule} \
      || { echo "clavis: ${pamUnixModule} not found (nixpkgs moved the PAM modules)" >&2; exit 1; }
    substituteInPlace $out/etc/xdg/quickshell/clavis/Modules/Lock/pam/password.conf \
      --replace-fail pam_unix.so ${pamUnixModule}
    grep -qF ${pamUnixModule} $out/etc/xdg/quickshell/clavis/Modules/Lock/pam/password.conf \
      || { echo "clavis: PAM service file was not patched" >&2; exit 1; }
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
