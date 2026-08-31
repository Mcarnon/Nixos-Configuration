# Clavis Shell — Quickshell desktop shell for niri.
# Builds the native C++ QML modules (Clavis.*, M3Shapes) plus the QML source
# tree / config. The `key` launcher (from key-cli) runs `qs -c clavis`.
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
    libcava # provides libcava.pc / cava.pc for the CMake pkg_check_modules
    fftw # required by libcava.pc's `Requires: fftw3`
  ];

  # QML library modules + config only — no installable app binary to wrap.
  # Without this, qtbase's setup hook fails the build with
  # "depends on qtbase, but no wrapping behavior was specified".
  dontWrapQtApps = true;

  # The fork's core/CMakeLists.txt includes CTest and adds a `tests/`
  # subdirectory; the QML tests need the quickshell engine at runtime, which
  # isn't a build input, so keep them out of the sandbox build.
  doCheck = false;

  # NOTE: 上游 core/CMakeLists.txt 的 install() DESTINATION 都是相对路径
  # (CLAVIS_*_INSTALL_DIR)。在 Nix sandbox 下若 CMAKE_INSTALL_PREFIX 未正确
  # 生效，这些相对路径会被解析到 CMAKE_BINARY_DIR (/build/source/build)，导致
  # 没有任何文件装进 $out，fixupPhase 的 `find $out` 就报
  # "No such file or directory"。因此这里用绝对 $out 路径作为 DESTINATION，
  # 保证安装一定落到 $out。
  cmakeFlags = [
    "-G Ninja"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DBUILD_TESTING=OFF"
    "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
    # Qt 的 qt_add_qml_module() 生成的 *plugin.so 在链接时会把 CMAKE_BINARY_DIR
    # (/build/source/build) 写进 RPATH，Nix 的硬化扫描会因 "forbidden reference
    # to /build/" 拒绝。这里让安装后的库用 $ORIGIN 作为 RPATH（plugin.so 与其
    # 主库 .so 安装在同一目录），并阻止 build 目录进入 RPATH。
    "-DCMAKE_BUILD_WITH_INSTALL_RPATH=ON"
    "-DCMAKE_INSTALL_RPATH=\$ORIGIN"
    "-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=OFF"
    "-DCLAVIS_QML_INSTALL_DIR=${placeholder "out"}/lib/qt6/qml"
    "-DCLAVIS_CONFIG_INSTALL_DIR=${placeholder "out"}/etc/xdg/quickshell/clavis"
    "-DCLAVIS_SYSTEMD_USER_INSTALL_DIR=${placeholder "out"}/lib/systemd/user"
  ];

  # 保证 $out 一定存在（哪怕某个 install 规则落空），fixupPhase 才能通过。
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cmake --install .
    runHook postInstall
  '';

  # 兜底：把任何残留的 /build/ 从 RPATH 中清掉（Qt plugin .so 与其主库同目录，
  # $ORIGIN 即可解析），否则 fixupPhase 的硬化扫描会再次拒绝。
  postFixup = ''
    for so in $(find "$out" -name '*.so'); do
      rpath="$(patchelf --print-rpath "$so" 2>/dev/null || true)"
      if echo "$rpath" | grep -q '/build/'; then
        patchelf --set-rpath '$ORIGIN' "$so"
      fi
    done
  '';

  meta = with lib; {
    description = "Quickshell desktop shell for niri (Clavis)";
    homepage = "https://github.com/StatIndet/quickshell";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
