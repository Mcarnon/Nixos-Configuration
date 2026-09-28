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

  # --- shell engine + IPC targets -------------------------------------------
  quickshell,
  niri,

  # --- QML runtime modules the Clavis QML tree imports ----------------------
  # Taken from the Qt6 scope (see qt6.* below) on purpose: the bare top-level
  # attrs (qt5compat, qtlottie, ...) are the Qt5 builds in some nixpkgs versions
  # and install their modules under lib/qt-5/qml, where nothing looks for them.
  # NOTE: no MapLibre. Upstream ships Modules/Map/MapFallback.qml for exactly
  # this case, and the weather map degrades to it instead of taking the shell
  # down. Adding maplibre-native-qt here would drag QtLocation + the whole
  # MapLibre C++ core into the closure for a card most people never open.

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
  # nixpkgs' Qt6 installs QML modules under lib/qt-6/qml (qtbase's
  # qtQmlPrefix), not the lib/qt6/qml distros use. Hand-writing the wrong
  # directory here is silent — the wrapper works, the desktop is black — so the
  # directory name is written exactly once, here. (No `|>`: that operator is
  # still behind `experimental-features = pipe-operators`.)
  qmlRoots = map (p: "${p}/${qt6.qtbase.qtQmlPrefix}") [
    clavisShell # Clavis.* native plugins (built by pkgs/clavis-shell)
    m3shapes # M3Shapes (upstream Clavis does not ship it)
    qt6.qt5compat # Qt5Compat.GraphicalEffects (blur/shadow, used everywhere)
    qt6.qtlottie # Qt.labs.lottieqt (animated weather cards)
    qt6.qtlocation # QtLocation (geocoding)
    qt6.qtpositioning # QtPositioning (coordinates)
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
  # pyproject.toml takes the version from src/key_cli/VERSION (dynamic), so this
  # label is only ours; keep it in sync (asserted in postInstall) instead of
  # letting a `nix flake update key-cli` produce a store path that lies.
  version = "2026.9.12";

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
  ];

  # The source root has no CMakeLists.txt (only native/ does) and we invoke
  # cmake by hand below.
  dontUseCmake = true;
  doCheck = false;

  # key-sysmon (metrics sampler) and key-cpu-power (RAPL helper) are plain
  # C++17 + Qt6::Core binaries built from native/.
  postInstall = ''
    cmake -S ./native -B ./native-build -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_TESTING=OFF \
      -DCMAKE_INSTALL_PREFIX="$out"
    cmake --build ./native-build
    cmake --install ./native-build
    runHook postInstall
  '';

  # `key` is a thin dispatcher: `key shell` execs qs, `key ipc`/`key file`/
  # `key tool` are what the Clavis QML shells out to. Everything it needs must
  # therefore be in its environment. The wrapper is a hand-written script
  # instead of makeWrapper on purpose: QML_IMPORT_PATH/XDG_CONFIG_DIRS have to
  # be *appended to* whatever the session already has, and makeWrapper's
  # --prefix colon handling is a well-known footgun.
  postFixup = ''
    if [ -f src/key_cli/VERSION ] && ! grep -qF "$version" src/key_cli/VERSION; then
      echo "key-cli: upstream VERSION is '$(tr -d '\n' < src/key_cli/VERSION)' but this" >&2
      echo "          derivation declares version = $version" >&2
      echo "          -> update version in pkgs/key-cli/default.nix" >&2
      exit 1
    fi

    # Fail the build, not the login: assert the QML modules really exist under
    # one of the import roots we are about to advertise.
    for d in Clavis M3Shapes Qt5Compat/GraphicalEffects Qt/labs/lottieqt; do
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
    exec "$out/bin/key-real" "$@"
    WRAPPER
    chmod +x "$out/bin/key"
  '';

  meta = with lib; {
    description = "Clavis `key` command: shell IPC, lifecycle, clipboard & metrics";
    homepage = "https://github.com/StatIndet/key-cli";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "key";
  };
}
