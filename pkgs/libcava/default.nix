# libcava — cava's audio-analysis core (cavacore) as an installable library.
#
# nixpkgs' `cava` package ships only the executable, but Clavis' CMake links
# the analysis library via pkg-config (module `libcava`, falling back to
# `cava`). We build just the cavacore target from cava's CMake (skipping the
# `cava` executable, which would need iniparser/ncurses/SDL) and install the
# static lib + header + pkg-config files.
{
  stdenv,
  lib,
  cmake,
  ninja,
  pkg-config,
  git,
  fetchFromGitHub,
  fftw,
  iniparser,
  ncurses,
}:
stdenv.mkDerivation {
  pname = "libcava";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "karlstav";
    repo = "cava";
    rev = "1.0.0";
    hash = "sha256-0vQWobnt9pAZTJc45Lgcfad72BE8DUPGQ5/YwMSmU98=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    git # cava's CMake calls find_package(Git REQUIRED) during configure
  ];

  buildInputs = [
    fftw # cavacore links against fftw3
    iniparser # configure time: CMake fails without it (cava executable deps)
    ncurses
  ];

  cmakeFlags = [
    "-G Ninja"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DBUILD_TESTING=OFF"
  ];

  # cava's CMake would also build the `cava` executable; only the library
  # target is needed (and buildable without extra audio-input deps).
  buildPhase = ''
    runHook preBuild
    cmake --build build --target cavacore
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm644 cavacore.h $out/include/cavacore.h
    install -Dm644 build/libcavacore.a $out/lib/libcavacore.a

    mkdir -p $out/lib/pkgconfig
    cat > $out/lib/pkgconfig/libcava.pc << EOF
    prefix=$out
    libdir=\${prefix}/lib
    includedir=\${prefix}/include

    Name: libcava
    Description: cava audio analysis library (cavacore)
    Version: ${version}
    Requires: fftw3
    Libs: -L\${libdir} -lcavacore
    Cflags: -I\${includedir}
    EOF
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
