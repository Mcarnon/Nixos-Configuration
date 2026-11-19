# FlClash —— 官方 Linux .deb 的 Nix 打包。
#
# nixpkgs 里的 flclash 已在 2026-08 被移除（“用户少、缺维护”）。从源码重建需要
# 整套 Flutter 3.44 + Go core + Rust API（pubspec/git-hashes 随版本变化），这里
# 改为解包官方 .deb：那是上游 CI 用同一套源码构建出来的产物，升级只需要更新
# version 和 hash。
#
# 升级：
#   nix store prefetch-file --json --hash-type sha256 \
#     https://github.com/chen08209/FlClash/releases/download/v<ver>/FlClash-<ver>-linux-amd64.deb
#   把 version / hash 替换成输出里的值。
{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  gtk3,
  glib,
  pango,
  cairo,
  gdk-pixbuf,
  atk,
  harfbuzz,
  libepoxy,
  fontconfig,
  libGL,
  wayland,
  libxkbcommon,
  libx11,
  libxcursor,
  libxi,
  libxrandr,
  libxinerama,
  libxext,
  keybinder3,
  libayatana-appindicator,
  libsecret,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "flclash";
  version = "0.9.3";

  src = fetchurl {
    url = "https://github.com/chen08209/FlClash/releases/download/v${finalAttrs.version}/FlClash-${finalAttrs.version}-linux-amd64.deb";
    hash = "sha256-QGQlQym7OcYonHQ+FuVyauVrWFPobZ+I4BReKvAyNRs=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    gtk3
    glib
    pango
    cairo
    gdk-pixbuf
    atk
    harfbuzz
    libepoxy
    fontconfig
    libGL
    wayland
    libxkbcommon
    libx11
    libxcursor
    libxi
    libxrandr
    libxinerama
    libxext
    keybinder3
    libayatana-appindicator
    libsecret
    stdenv.cc.cc.lib
  ];

  # Flutter 的插件 .so 和 librust_api.so 都在 opt/FlClash/lib，主程序没有
  # 指向它们的 RPATH；autoPatchelf 需要 RPATH 才能解析这些 bundled 依赖。
  appendRunpaths = [
    "$ORIGIN"
    "$ORIGIN/lib"
  ];

  # libdartjni.so 带着 NEEDED libjvm.so，但 deb 的 Depends 只有
  # libayatana-appindicator3-1 / libsecret-1-0，Linux 版根本不会加载这个
  # JNI 插件（没有 JRE 的 Ubuntu/Fedora 也照常跑）。不要为了一个未使用的
  # .so 把整个 JDK 拖进闭包。
  autoPatchelfIgnoreMissingDeps = [ "libjvm.so" ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt $out/bin $out/share
    cp -r opt/FlClash $out/opt/FlClash

    # deb 的 desktop 文件 Exec=FlClash；wrapper 放到 $out/bin，PATH 里可解析。
    # librust_api.so 由 RustLib.init() dlopen，dlopen 不读 RUNPATH，只认
    # LD_LIBRARY_PATH，所以 wrapper 必须显式带上 lib 目录。
    makeWrapper $out/opt/FlClash/FlClash $out/bin/FlClash \
      --prefix LD_LIBRARY_PATH : "$out/opt/FlClash/lib"

    ln -s FlClash $out/bin/flclash

    install -Dm644 usr/share/applications/FlClash.desktop \
      $out/share/applications/FlClash.desktop
    cp -r usr/share/icons $out/share/

    runHook postInstall
  '';

  meta = {
    description = "Multi-platform proxy client based on ClashMeta";
    homepage = "https://github.com/chen08209/FlClash";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "FlClash";
  };
})
