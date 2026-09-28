# key — the `key` command for Clavis Shell (github:StatIndet/key-cli).
#
# Pure Python (PEP 517) plus two small native tools it installs itself:
#   $out/bin/key-sysmon        — system metrics sampler (JSON/JSONL protocol v1)
#   $out/libexec/key-cli/key-cpu-power — unprivileged RAPL energy helper
#
# `key shell` execs `qs -c clavis`, so a bare `buildPythonApplication` is not
# enough: without quickshell on PATH the shell cannot start, and without the
# native Clavis.*/M3Shapes/Qt5Compat/Qt5-Lottie QML modules on QML_IMPORT_PATH
# quickshell starts and then dies at load time with
# `module "Qt5Compat.GraphicalEffects" is not installed` — a black screen with
# no error anywhere useful. This derivation therefore ships a `key` wrapper
# that pins PATH, QML_IMPORT_PATH and XDG_CONFIG_DIRS.
{
  lib,
  cmake,
  ninja,
  pkg-config,
  qt6,
  python3Packages,
  clavisShell,
  m3shapes,

  # Weather map. Modules/Map/MapLibreMap.qml and MapLibreWeatherMap.qml do
  # `import MapLibre 3.0`, and packaging/dependencies.json lists
  # maplibre-native-qt with defaultInstall: true. This was previously omitted,
  # which left the weather map permanently on Modules/Map/MapFallback.qml — a
  # supported degradation, but a visible "missing feature". nixpkgs ships
  # maplibre-native-qt 3.0.0, which matches the versioned import exactly.
  maplibre-native-qt,

  # --- shell engine + IPC targets -------------------------------------------
  quickshell,
  niri,

  # --- QML runtime modules the Clavis QML tree imports ----------------------
  # Taken from the Qt6 scope (see qt6.* below) on purpose: the bare top-level
  # attrs (qt5compat, qtlottie, ...) are the Qt5 builds in some nixpkgs versions
  # and install their modules under lib/qt-5/qml, where nothing looks for them.

  # --- shell/runtime helpers (see upstream packaging/dependencies.json) -----
  python3,
  bash,
  coreutils,
  findutils,
  fd,
  gnused,
  gnugrep,
  jq,
  matugen,
  systemd,
  util-linux,
  which,
  xdg-utils,
  glib, # gio
  gvfs, # trash backend for the dock
  libnotify, # notify-send
  cliphist,
  wl-clipboard,
  pipewire, # pw-*
  pulseaudio, # pactl（音频录制/系统音量查询）
  ffmpeg, # ffprobe 也在里面
  slurp,
  grim,
  gpu-screen-recorder,
  brightnessctl,
  ddcutil,
  awww,
  hyprpicker,
  rclone,
  imagemagick,
  xdg-terminal-exec,
  networkmanager, # nmcli
  bluez, # bluetoothctl
  upower,

  src,
}:
let
  # pyproject.toml takes the version from src/key_cli/VERSION (dynamic), so this
  # label is only ours. It lives in a `let` rather than as a derivation attr
  # because the postFixup assert below interpolates it: only stdenv.mkDerivation
  # auto-binds `version` into scope, buildPythonApplication does not.
  #
  # 2026.9.25 is not cosmetic: Clavis' packaging/dependencies.json lists
  # `key-cli>=2026.9.25` as a *runtime* requirement, because the shell drives
  # this binary through `key ipc` / `key sysmon` / `key tool`. Building against
  # 2026.9.12 compiled fine and then failed at click-time, which is the worst
  # possible failure mode for a desktop shell. postFixup asserts the two agree.
  version = "2026.9.25";

  # QML module roots for QML_IMPORT_PATH.
  #
  # Every root is a store path, so these must be listed explicitly — Qt finds
  # *sibling Qt modules* by itself (they are merged under qtbase's own qml dir
  # and picked up from the Qt library path), but these are not siblings of
  # qtbase in any way nixpkgs can infer.
  #
  # `quickshell` is here on purpose: nixpkgs' quickshell sets cmakeFlags
  # INSTALL_QML_PREFIX = qt6.qtbase.qtQmlPrefix, so `Quickshell` lands in
  # $quickshell/lib/qt-6/qml — a store path nothing else points at, and
  # quickshell never adds it to its own import path (src/launch/*.cpp has no
  # import-path handling at all). shell.qml line 5 is `import Quickshell`, so
  # without this the desktop is black. dontWrapQtApps means makeQtWrapper does
  # not contribute it either.
  #
  # Do NOT use lib.makeSearchPathOutput here: it produced one `<pkg>/include`
  # root per input rather than a single merged lib/qt-6/qml, so every module
  # lookup missed. (No `|>` either: still behind experimental-features.)
  qtQmlPrefix = qt6.qtbase.qtQmlPrefix; # "lib/qt-6/qml", written once
  qmlRoots = map (p: "${p}/${qtQmlPrefix}") [
    clavisShell # Clavis.* native plugins (built by pkgs/clavis-shell)
    m3shapes # M3Shapes (upstream Clavis does not ship it)
    quickshell # Quickshell.* — shell.qml line 5
    qt6.qtbase
    # Also the source of QtQuick.Controls / Layouts / Effects:
    # packaging/dependencies.json lists qt6-declarative as Clavis' *only*
    # declarative dependency. There is no `qt6.qtquickcontrols2` attr —
    # referencing it is an eval error, not a missing module.
    qt6.qtdeclarative
    qt6.qt5compat # Qt5Compat.GraphicalEffects (blur/shadow, used everywhere)
    qt6.qtlottie # Qt.labs.lottieqt (animated weather cards)
    qt6.qtlocation # QtLocation (geocoding)
    qt6.qtpositioning # QtPositioning (coordinates)
    maplibre-native-qt # MapLibre — `import MapLibre 3.0` in Modules/Map/*
  ];

  qmlImportPath = lib.concatStringsSep ":" qmlRoots;
  qmlRootsSh = lib.concatStringsSep " " qmlRoots;

  binPath = lib.makeBinPath [
    quickshell
    niri
    python3
    bash
    coreutils
    findutils
    fd
    gnused
    gnugrep
    jq
    matugen
    systemd
    util-linux
    which
    xdg-utils
    glib
    gvfs
    libnotify
    cliphist
    wl-clipboard
    pipewire
    pulseaudio
    ffmpeg
    slurp
    grim
    gpu-screen-recorder
    brightnessctl
    ddcutil
    awww
    hyprpicker
    rclone
    imagemagick
    xdg-terminal-exec
    networkmanager
    bluez
    upower
  ];
in
python3Packages.buildPythonApplication {
  pname = "key-cli";
  inherit version;

  inherit src;
  format = "pyproject";

  dependencies = [
    python3Packages.evdev
    python3Packages.pyudev
  ];

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    qt6.qtbase # native/ links Qt6::Core only
    # PEP 517 build backend. pypaBuildPhase runs
    #   pypa build --no-isolation --outdir dist/ --wheel
    # and --no-isolation means nothing is installed on the fly: without
    # setuptools importable in the build env the wheel build dies with
    # "BackendUnavailable: Cannot import 'setuptools.build_meta'".
    python3Packages.setuptools
  ];

  # The source root has no CMakeLists.txt (only native/ does) and we invoke
  # cmake by hand below. `dontUseCmakeConfigure` is the flag the cmake setup
  # hook actually reads (pkgs/by-name/cm/cmake/setup-hook.sh: the hook only
  # replaces `configurePhase`, and only `if [ -z "$dontUseCmakeConfigure" ]`);
  # plain `dontUseCmake` is legacy and no longer disables anything, so cmake
  # configure ran against the source root and died with "does not appear to
  # contain CMakeLists.txt".
  dontUseCmakeConfigure = true;
  doCheck = false;

  # The Qt bits here are libraries (native/ links Qt6::Core) plus a `key`
  # dispatcher that gets a *hand-written* wrapper in postFixup: PATH,
  # QML_IMPORT_PATH and XDG_CONFIG_DIRS all have to be appended to the session's
  # existing values, which makeWrapper/makeQtApp cannot do. So qtPreHook must not
  # demand wrapQtAppsHook ("this derivation depends on qtbase, but no wrapping
  # behavior was specified").
  dontWrapQtApps = true;

  # key-sysmon (metrics sampler) and key-cpu-power (RAPL helper) are plain
  # C++17 + Qt6::Core binaries built from native/.
  # No `runHook postInstall` here: the generic install phase already ends with
  # it, and calling it from inside the hook itself recurses forever.
  postInstall = ''
    cmake -S ./native -B ./native-build -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_TESTING=OFF \
      -DCMAKE_INSTALL_PREFIX="$out"
    cmake --build ./native-build
    cmake --install ./native-build
  '';

  # `key` is a thin dispatcher: `key shell` execs qs, `key ipc`/`key file`/
  # `key tool` are what the Clavis QML shells out to. Everything it needs must
  # therefore be in its environment. The wrapper is a hand-written script
  # instead of makeWrapper on purpose: QML_IMPORT_PATH/XDG_CONFIG_DIRS have to
  # be *appended to* whatever the session already has, and makeWrapper's
  # --prefix colon handling is a well-known footgun.
  postFixup = ''
    if [ -f src/key_cli/VERSION ] && ! grep -qF "${version}" src/key_cli/VERSION; then
      echo "key-cli: upstream VERSION is '$(tr -d '\n' < src/key_cli/VERSION)' but this" >&2
      echo "          derivation declares version = ${version}" >&2
      echo "          -> update version in pkgs/key-cli/default.nix" >&2
      exit 1
    fi

    # Fail the build, not the login: assert the QML modules really exist under
    # one of the import roots we are about to advertise. `Quickshell` is the one
    # that broke first (shell.qml imports it) and it is the one nothing else
    # puts on the path, so it is asserted explicitly.
    # Asserted on the directory name (`MapLibre`), not the import string
    # (`MapLibre 3.0`): Qt resolves the version from the qmldir/plugin, the
    # directory is just `MapLibre`. If this ever fails, the fix is to correct the
    # install prefix in the `maplibre-native-qt` entry above — do not delete the
    # entry, that silently leaves the weather map on MapFallback.qml forever.
    for d in Quickshell Clavis M3Shapes QtQuick Qt5Compat/GraphicalEffects Qt/labs/lottieqt MapLibre; do
      found=""
      for p in ${qmlRootsSh}; do
        if [ -e "$p/$d" ]; then
          found="$p"
          break
        fi
      done
      if [ -z "$found" ]; then
        echo "key-cli: QML module dir '$d' not under any of: ${qmlRootsSh}" >&2
        exit 1
      fi
    done

    test -x "$out/bin/key-sysmon" || { echo "key-cli: key-sysmon missing" >&2; exit 1; }
    test -x "$out/libexec/key-cli/key-cpu-power" \
      || { echo "key-cli: key-cpu-power missing" >&2; exit 1; }

    # Keyboard LED access for the lock-screen indicator: an ACL on the evdev
    # keyboard nodes, not a root daemon. NixOS wires this up with
    # `services.udev.packages = [ pkgs.keyCli ]`.
    mkdir -p "$out/lib/udev/rules.d"
    install -Dm644 ./packaging/udev/71-clavis-keyboard-leds.rules \
      "$out/lib/udev/rules.d/71-clavis-keyboard-leds.rules"

    install -Dm644 ./completions/key.fish "$out/share/fish/vendor_completions.d/key.fish"

    mv "$out/bin/key" "$out/bin/key-real"
    cat > "$out/bin/key" <<'WRAPPER'
    #!/bin/sh
    # Generated by pkgs/key-cli. Do not edit; see that file for the rationale.
    export PATH="${binPath}:$PATH"
    export QML_IMPORT_PATH="${qmlImportPath}''${QML_IMPORT_PATH:+:''${QML_IMPORT_PATH}}"
    # Quickshell resolves `qs -c clavis` against ~/.config/quickshell/clavis
    # first and XDG_CONFIG_DIRS/quickshell/clavis second. This config lives in
    # the read-only store, so the XDG path is the only one that can work.
    export XDG_CONFIG_DIRS="${clavisShell}/etc/xdg''${XDG_CONFIG_DIRS:+:''${XDG_CONFIG_DIRS}}"
    # XDG_DATA_DIRS is what makes the desktop *icon theme* discoverable, and
    # Clavis resolves a large part of its artwork through the system theme:
    #   Services/ApplicationService.qml:188  Quickshell.iconPath(<desktop Icon=>, ...)
    #   Modules/Dock/DockItem.qml            same, for dock entries
    #   Components/FileThemeIcon.qml         Quickshell.hasThemeIcon(...)
    # On NixOS the themes (adwaita-icon-theme, paprus-icon-theme) are only ever
    # reachable through the system profile — /run/current-system/sw/share/icons
    # and /nix/var/nix/profiles/default/share/icons. Qt's fallback list is
    # /usr/local/share:/usr/share, which do not exist here, so an unset
    # XDG_DATA_DIRS means *no* icon theme at all: every launcher/dock/spotlight
    # entry renders empty. Nothing warns about it.
    # These two roots cover both the current and the pre-22.11 system layouts;
    # only existing ones are prepended, and the session's own value is kept.
    for dir in /run/current-system/sw/share /nix/var/nix/profiles/default/share; do
      if [ -d "$dir" ]; then
        export XDG_DATA_DIRS="$dir''${XDG_DATA_DIRS:+:''${XDG_DATA_DIRS}}"
      fi
    done
    export XDG_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}"
    export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-$HOME/.cache}"
    # key-real lives next to this script, so find it relative to $0 rather than
    # baking a store path. Neither spelling of the store path works here: `out`
    # is a *build-time* env var, not a Nix-level binding (buildPythonApplication
    # does not bind it the way stdenv.mkDerivation does), so ''${out} is an
    # undefined variable at eval time — and a bare $out inside this quoted
    # heredoc survives into the *runtime* script, where nothing exports it, and
    # collapses to /bin/key-real (exit 127 on every restart).
    here=$(dirname "$(readlink -f "$0")")
    exec "$here/key-real" "$@"
    WRAPPER
    chmod +x "$out/bin/key"

    # Guard the trap above: the wrapper must exec its sibling, and that sibling
    # must exist. Checking what the *wrapper* runs keeps this a build error
    # rather than a black desktop after login.
    test -x "$out/bin/key-real" \
      || { echo "key-cli: $out/bin/key-real missing after rename" >&2; exit 1; }
    grep -qF 'exec "$here/key-real" "$@"' "$out/bin/key" \
      || { echo "key-cli: wrapper lost its self-relative exec line" >&2; exit 1; }

    # The same guard for the icon-theme fix. Two failure modes to rule out, both
    # invisible at runtime (blank icons, no log line):
    #   * the export was dropped, or
    #   * it lost its Nix escaping and Nix ate ''${...} at eval time, leaving a
    #     literal `:+:` in the script. grepping the *rendered* wrapper for a
    #     literal `:+` catches that, because the only such line should be inside
    #     a `${...:+...}` expansion.
    grep -qF 'XDG_DATA_DIRS="$dir${XDG_DATA_DIRS:+:${XDG_DATA_DIRS}}"' "$out/bin/key" \
      || { echo "key-cli: wrapper lost the XDG_DATA_DIRS icon-theme export" >&2; exit 1; }
    if grep -F 'XDG_DATA_DIRS' "$out/bin/key" | grep -qF ':+:'; then
      echo "key-cli: XDG_DATA_DIRS expansion lost its Nix escaping (literal ':+:' in wrapper)" >&2
      exit 1
    fi
  '';

  meta = with lib; {
    description = "Clavis `key` command: shell IPC, lifecycle, clipboard & metrics";
    homepage = "https://github.com/StatIndet/key-cli";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "key";
  };
}
