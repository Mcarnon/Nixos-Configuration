# libcava — cava's audio-analysis core (cavacore) as an installable library.
#
# nixpkgs' `cava` package builds the autotools executable only; Clavis links the
# analysis core through pkg-config (`pkg_check_modules(Cava ... libcava)` with a
# `cava` fallback, see clavis-shell/core/CMakeLists.txt). Upstream's CMakeLists
# only ever declares the `cavacore` target, so we build exactly that target and
# install header + archive + a hand-written .pc.
#
# POSITION_INDEPENDENT_CODE matters: Clavis links cavacore into a *shared* Qt
# QML plugin (Clavis/Cava/libClavisCava.so). A non-PIC archive makes that link
# fail with "recompile with -fPIC".
{
  stdenv,
  lib,
  cmake,
  ninja,
  pkg-config,
  fetchFromGitHub,
  fftw,
}:
stdenv.mkDerivation {
  pname = "libcava";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "karlstav";
    repo = "cava";
    tag = "1.0.0";
    hash = "sha256-0vQWobnt9pAZTJc45Lgcfad72BE8DUPGQ5/YwMSmU98=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ];

  buildInputs = [ fftw ];

  cmakeFlags = [
    "-G Ninja"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DBUILD_TESTING=OFF"
    # Consumers link cavacore into shared objects; see header comment.
    "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
  ];

  # Upstream's CMake exposes only the library target (the `cava` binary lives in
  # the autotools build), so building the default target is enough.
  buildPhase = ''
    runHook preBuild
    cmake --build . --target cavacore
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/pkgconfig $out/include/cava

    # cavacore.h must land in include/cava/ so `#include <cava/cavacore.h>`
    # (Clavis' CavaProvider) resolves; keep the flat copy for <cavacore.h> users.
    install -Dm644 $src/cavacore.h $out/include/cava/cavacore.h
    install -Dm644 $src/cavacore.h $out/include/cavacore.h
    install -Dm644 libcavacore.a $out/lib/libcavacore.a

    # Quoted heredoc: bash must leave the pkg-config variable expansions alone,
    # so every literal `$` is written in Nix's escaped two-quote-dollar form and
    # @out@ is substituted afterwards.
    cat > $out/lib/pkgconfig/libcava.pc << 'EOF'
    prefix=@out@
    libdir=''${prefix}/lib
    includedir=''${prefix}/include

    Name: libcava
    Description: cava audio analysis library (cavacore)
    Version: 1.0.0
    Requires: fftw3
    Libs: -L''${libdir} -lcavacore
    Cflags: -I''${includedir}
    EOF
    sed -e "s|@out@|$out|g" -i $out/lib/pkgconfig/libcava.pc
    # Clavis falls back to the `cava` module name; ship both.
    sed 's/^Name: libcava/Name: cava/' $out/lib/pkgconfig/libcava.pc > $out/lib/pkgconfig/cava.pc

    runHook postInstall
  '';

  meta = with lib; {
    description = "cava audio analysis core (cavacore) as a library";
    homepage = "https://github.com/karlstav/cava";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
