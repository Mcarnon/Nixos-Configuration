# key-cli — the `key` command: Clavis shell lifecycle/IPC, clipboard, recording,
# and the native sysmon sampler.
#
# Two halves:
#   * a pure-Python command dispatcher (setuptools, src layout, evdev+pyudev)
#   * a C++17 CMake project under native/ that builds `key-sysmon` (JSON/JSONL
#     sampler, Qt6::Core only) and `key-cpu-power` (libexec helper, no Qt)
#
# `key shell` is a thin wrapper around `qs -c clavis -n`, so the wrapper has to
# supply everything Quickshell would normally get from a distro install:
#   QML_IMPORT_PATH  Clavis.* native modules + the Qt QML modules Clavis imports
#                    (GraphicalEffects, lottie, svg, Location, Positioning, QMapLibre)
#   QT_PLUGIN_PATH   the same packages' Qt plugin dirs (platforms, imageformats,
#                    geolib/position, wayland)
#   XDG_CONFIG_DIRS  ${clavisShell}/etc/xdg so `qs -c clavis` finds the shell tree
#   PATH             every backend `key` shells out to
# Without any one of these the shell starts and then dies on the first missing
# QML import — the "service is running but the desktop is black" failure mode.
{
  python3Packages,
  lib,
  makeWrapper,
  makeBinaryWrapper,
  cmake,
  ninja,
  pkg-config,
  patchelf,
  systemd,
  glib,
  xdg-utils,
  qt6,
  # nixpkgs keeps the Qt6 add-on modules inside `qt6Packages` only; there is no
  # top-level `qtlocation` / `qtlottie` alias, so asking callPackage for the
  # unprefixed names fails with "attribute ... missing".
  qt6Packages,
  # maplibre-native-qt is threaded in explicitly: pkgs/default.nix overrides it to
  # work around a GCC 16 `-Werror` in the vendored maplibre-native (see the comment
  # there), so the patched derivation must be used instead of the one straight out
  # of qt6Packages.
  maplibreNativeQt,
  clavisShell,
  m3shapes,
  quickshell,
  bash,
  coreutils,
  python3,
  findutils,
  gnugrep,
  gnused,
  jq,
  procps,
  util-linux,
  which,
  imagemagick,
  brightnessctl,
  ddcutil,
  hyprpicker,
  rclone,
  # nixpkgs has no top-level `pulseaudio-utils` / `qalculate`; the derivations
  # that actually ship `pactl` and `qalc` are `libpulseaudio` / `libqalculate`.
  libpulseaudio,
  libqalculate,
  matugen,
  cliphist,
  wl-clipboard,
  gpu-screen-recorder,
  ffmpeg,
  slurp,
  awww,
  fd,
  xdg-terminal-exec,
  src,
  ...
}:
let
  # Packages that ship a Qt QML root and/or Qt plugins. The prefixes come from
  # qtbase's passthru so a Qt version bump that renames lib/qt-6 -> ... is picked
  # up automatically instead of hardcoding it here.
  qtQmlPrefix = qt6.qtbase.qtQmlPrefix; # lib/qt-6/qml
  qtPluginPrefix = qt6.qtbase.qtPluginPrefix; # lib/qt-6/plugins

  # Enumerated from every `import` in the Clavis QML tree, i.e. exactly the
  # roots a QML engine has to resolve for the shell to load at all:
  #   Quickshell.{Io,Wayland,Services.*,Widgets}  -> quickshell itself
  #   Clavis.*                                      -> clavisShell
  #   M3Shapes                                      -> m3shapes      (20 imports)
  #   MapLibre                                      -> maplibreNativeQt
  #   Qt.labs.lottie / Qt5Compat.GraphicalEffects / QtQuick.Shapes
  #   QtLocation / QtPositioning                    -> qt6Packages.*
  # A missing root is a fatal QML load error, which is exactly the "service is
  # running but the desktop is black" failure this wrapper exists to prevent.
  #
  # Clavis is deliberately NOT in this list: upstream CMakeLists.txt pins its
  # private modules to `${CMAKE_INSTALL_LIBDIR}/qt6/qml`, i.e. lib/qt6/qml, not
  # nixpkgs' lib/qt-6/qml. It is added separately below (clavisQmlRoot).
  qtRuntime = [
    quickshell
    m3shapes
    maplibreNativeQt
    qt6.qtbase
    qt6.qtdeclarative
    qt6Packages.qt5compat
    qt6Packages.qtlottie
    qt6Packages.qtsvg
    qt6Packages.qtimageformats
    qt6Packages.qtlocation
    qt6Packages.qtpositioning
    qt6Packages.qtwayland
  ];

  # Clavis' own QML root. `${clavisShell}/etc/xdg` is the shell config tree that
  # `qs -c clavis` resolves by name; the importable `Clavis.*` modules live here.
  clavisQmlRoot = "${clavisShell}/lib/qt6/qml";

  # `key` shells these out to, *and* so does the Clavis process itself: the
  # QML services exec `bash scripts/theme/generate_matugen_colors.sh` and
  # `python3 scripts/system/niri_config.py`, and those scripts in turn need
  # mktemp/timeout/flock/jq/sed/grep/which/pkill. `key shell` execs `qs`, so this
  # PATH is the desktop shell's PATH — anything missing here silently disables a
  # feature (no niri fragment management, no matugen, stale theme).
  keyBackends = [
    # ── interpreter / coreutils for the shell's own scripts ──
    bash
    coreutils
    python3
    findutils
    gnugrep
    gnused
    jq
    procps # matugen post_hooks use pkill
    util-linux # flock for the matugen registry lock
    which

    # ── `key doctor` checklist (src/key_cli/commands/doctor.py) ──
    quickshell # qs   -> shell, ipc
    libqalculate # qalc  -> Spotlight calculator
    glib # gio   -> file open / reveal fallback
    xdg-utils # xdg-open
    xdg-terminal-exec # terminal file-manager launch
    cliphist # clipboard list/store
    wl-clipboard # wl-copy / wl-paste
    gpu-screen-recorder # record
    slurp # record-region
    ffmpeg # audio + record-gif (also provides ffprobe)
    libpulseaudio # pactl (audio source resolution)
    fd # Spotlight find-files
    systemd # systemctl / busctl

    # ── wallpaper / theme pipeline ──
    matugen # theme regeneration on wallpaper change
    imagemagick # magick: overview wallpaper cache (scripts/system/overview.sh)
    awww # optional wallpaper backend
    brightnessctl
    ddcutil
    hyprpicker # color picker
    rclone # keystone cloud upload
  ];
in
python3Packages.buildPythonApplication {
  pname = "key-cli";
  version = lib.removeSuffix "\n" (
    lib.removeSuffix "\r" (builtins.readFile "${src}/src/key_cli/VERSION")
  );

  inherit src;

  format = "pyproject";

  dependencies = with python3Packages; [
    evdev
    pyudev
  ];

  nativeBuildInputs = [
    makeWrapper
    makeBinaryWrapper
    cmake
    ninja
    pkg-config
    patchelf
    qt6.qtbase
    # pypaBuildHook runs the PEP 517 backend out of a venv; without setuptools on
    # PATH it dies with "Backend 'setuptools.build_meta' is not available".
    python3Packages.setuptools
  ];

  buildInputs = [ qt6.qtbase ];

  # The native helpers are plain executables installed by absolute path; the Qt
  # app wrapping hook has nothing to say about them, and `key` itself is a Python
  # script we wrap by hand below.
  dontWrapQtApps = true;
  # CMakeLists.txt lives under native/, not the repo root. preBuild runs the
  # real configure towards native/build, so disable the hook's root-relative
  # `cmake ..` (it would claim "/build/source does not contain CMakeLists.txt").
  dontUseCmakeConfigure = true;
  dontUseCmakeBuild = true;

  doCheck = false;

  # KEY_CPU_POWER_HELPER is baked in as ${out}/libexec/key-cli/key-cpu-power, so
  # the install prefix has to be final at configure time. This is the preBuild
  # *hook*, so it must not call `runHook preBuild` itself.
  preBuild = ''
    cmake -S native -B native/build -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_TESTING=OFF \
      -DCMAKE_INSTALL_PREFIX="$out" \
      -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON
    cmake --build native/build
  '';

  postInstall = ''
    cmake --install native/build
    install -Dm644 systemd/user/clavis-clipboard.service \
      $out/lib/systemd/user/clavis-clipboard.service
  '';

  postFixup = ''
    # python buildPythonApplication also runs fixupPhase on the *-dist output
    # (the wheel). Everything below operates on the real $out, so leave that
    # output untouched instead of wrapping / checking a $out=*-dist layout.
    if [ ! -x "$out/bin/key" ]; then
      exit 0
    fi

    # Nothing may keep a /build reference (Nix hardening rejects it, and it would
    # not exist at runtime anyway). Scrub before wrapping, while the real
    # binaries are still at their install paths.
    for exe in "$out/bin/key-sysmon" "$out/libexec/key-cli/key-cpu-power"; do
      [ -x "$exe" ] || continue
      rpath=$(patchelf --print-rpath "$exe" 2>/dev/null || true)
      if printf '%s' "$rpath" | grep -q '/build'; then
        patchelf --set-rpath "$rpath" --remove-rpath '/build[^:]*' "$exe" 2>/dev/null || \
          patchelf --set-rpath '$ORIGIN' "$exe"
      fi
    done

    # key-sysmon links Qt6::Core and is exec'd by `key sysmon` (not a Qt app, so
    # the qt hook skips it). CMake drops the build RPATH on install, so pin the
    # real library path here — otherwise the sampler dies with a loader error and
    # every Clavis system-metric tile reads "unavailable".
    #
    # NOTE: in this nixpkgs makeWrapper and makeBinaryWrapper are the same
    # function and both take TWO positionals — the real executable and the
    # wrapper destination — followed by flags. The wrapper binary is compiled
    # INTO the destination, so the real executable must be moved aside first
    # (that move is exactly what nixpkgs' wrapProgram does).
    mv "$out/bin/key-sysmon" "$out/libexec/key-cli/key-sysmon-real"
    makeBinaryWrapper "$out/libexec/key-cli/key-sysmon-real" "$out/bin/key-sysmon" \
      --prefix RPATH : "${lib.makeLibraryPath [ qt6.qtbase ]}"

    # Collect the QML roots / plugin dirs that actually exist.
    #
    # Clavis' private modules go in explicitly: upstream installs them to
    # lib/qt6/qml (CMakeLists.txt: CLAVIS_QML_INSTALL_DIR), which is a different
    # path from nixpkgs' ${qtQmlPrefix} (lib/qt-6/qml) that the loop below walks.
    # Relying on the loop alone silently drops the entire `Clavis.*` import tree.
    qml_paths=""
    for d in ${clavisQmlRoot} ${lib.concatStringsSep " " (map (p: "${p}/${qtQmlPrefix}") qtRuntime)}; do
      [ -d "$d" ] && qml_paths="$qml_paths''${qml_paths:+:}$d"
    done
    plugin_paths=""
    for d in ${lib.concatStringsSep " " (map (p: "${p}/${qtPluginPrefix}") qtRuntime)}; do
      [ -d "$d" ] && plugin_paths="$plugin_paths''${plugin_paths:+:}$d"
    done
    # nixpkgs' maplibre-native-qt never sets INSTALL_QMLDIR, so whether the
    # MapLibre module lands under lib/qt-6/qml, lib/qml or lib/qt6/qml is a
    # build-time fact — and `import MapLibre` is used twice by Clavis.
    for d in $(find ${maplibreNativeQt} -maxdepth 4 -type d \( -name qml -o -name plugins \) 2>/dev/null); do
      case "$(basename "$d")" in
        qml) qml_paths="$qml_paths''${qml_paths:+:}$d" ;;
        plugins) plugin_paths="$plugin_paths''${plugin_paths:+:}$d" ;;
      esac
    done

    # Fail the build rather than ship a wrapper that yields a black desktop.
    if [ -z "$qml_paths" ]; then
      echo "key-cli: no QML import roots found; Clavis could not load" >&2
      exit 1
    fi

    # Check for real qmldir files rather than grepping the path list: a store
    # path only contains the *lowercase* derivation name (…-clavis-shell,
    # …-m3shapes, …-quickshell), never the camel-cased QML module directory
    # (Clavis/, M3Shapes/, Quickshell/), and maplibre's root is discovered at
    # runtime so nothing about it can be inferred from a path string.
    #
    # Both layouts have to be accepted. M3Shapes / Quickshell / MapLibre ship a
    # single module with one qmldir, while Clavis registers one
    # `qt_add_qml_module(URI Clavis.<X>)` per native module
    # (core/plugin/*/CMakeLists.txt) and therefore only ever produces
    # Clavis/<Module>/qmldir — there is no top-level Clavis/qmldir.
    require_qml_module() {
      module=$1
      IFS=:
      for root in $qml_paths; do
        if [ -f "$root/$module/qmldir" ]; then
          unset IFS
          return 0
        fi
        # Per-submodule layout (Clavis): at least one Clavis/<Module>/qmldir.
        if [ -n "$(find "$root/$module" -mindepth 2 -maxdepth 2 -name qmldir -print -quit 2>/dev/null)" ]; then
          unset IFS
          return 0
        fi
      done
      unset IFS
      echo "key-cli: no QML import root provides '$module' (searched: $qml_paths)" >&2
      exit 1
    }
    require_qml_module Clavis
    require_qml_module M3Shapes
    require_qml_module Quickshell
    require_qml_module MapLibre

    if [ ! -x "$out/bin/key-sysmon" ]; then
      echo "key-cli: native sysmon sampler missing from \$out" >&2
      exit 1
    fi

    # key-sysmon has now been replaced by a C wrapper at the same path.
    mv "$out/bin/key" "$out/libexec/key-cli/key-real"
    makeWrapper "$out/libexec/key-cli/key-real" "$out/bin/key" \
      --prefix PATH : "${lib.makeBinPath keyBackends}" \
      --prefix QML_IMPORT_PATH : "$qml_paths" \
      --prefix QT_PLUGIN_PATH : "$plugin_paths" \
      --prefix XDG_CONFIG_DIRS : "${clavisShell}/etc/xdg"
  '';

  meta = with lib; {
    description = "Clavis `key` command: shell IPC, lifecycle, clipboard, recording & sysmon";
    homepage = "https://github.com/StatIndet/key-cli";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "key";
  };
}
