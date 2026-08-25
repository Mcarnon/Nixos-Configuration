# Miyu: terminal-native AI assistant (https://github.com/SHORiN-KiWATA/Miyu)
#
# Built from the upstream Arch prebuilt release (pkg.tar.zst) because the binary
# is not in nixpkgs. Reuses the AUR strategy: unpack and repack for Nix store.
# On rebuild, bump `version` and update `hash` (SRI) from the GitHub release.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  libarchive, # provides bsdtar for unpacking Arch .pkg.tar.zst
  # runtime deps — Miyu is Rust (rustls, bundled sqlite) but dynamically links
  # against common system libs. Keep this list minimal; extend if ldd complains.
  glibc,
  gcc-unwrapped,
  zlib,
  bzip2,
  xz,
  zstd,
  openssl ? null, # not needed with rustls, kept optional for future
  alsa-lib,
  expat,
  fontconfig,
  freetype,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "miyu";
  version = "0.4.5";

  src = fetchurl {
    url = "https://github.com/SHORiN-KiWATA/Miyu/releases/download/v${finalAttrs.version}/miyu-${finalAttrs.version}-1-x86_64.pkg.tar.zst";
    hash = "sha256-TEiUGQxywjzxMmVCTWIrxwlLSWF02mHK4EVqox96yXU=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    libarchive
    zstd
  ];

  buildInputs = [
    glibc
    gcc-unwrapped.lib
    zlib
    bzip2
    xz
    zstd
    alsa-lib
    expat
    fontconfig
    freetype
  ] ++ lib.optional (openssl != null) openssl;

  # The .pkg.tar.zst is an Arch package (bsdtar archive with ./usr hierarchy).
  # Nix's unpackPhase handles zstd transparently; we just rearrange into $out.
  unpackPhase = ''
    runHook preUnpack
    # bsdtar is available in stdenv; explicitly use it for .pkg.tar.zst
    bsdtar -xf $src
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    # Arch package layout: usr/bin/miyu, usr/share/miyu, usr/share/licenses, etc.
    mkdir -p $out
    if [ -d usr ]; then
      cp -a usr/* $out/
      # Normalise: binary at $out/bin/miyu, assets at $out/share/miyu
      mkdir -p $out/bin
      # In case bsdtar placed bin elsewhere, ensure it exists
      if [ ! -f $out/bin/miyu ] && [ -f usr/bin/miyu ]; then
        cp -a usr/bin/miyu $out/bin/miyu
      fi
    else
      echo "unexpected archive layout — no usr/ found; listing:"
      ls -R
      exit 1
    fi

    # Some releases put the binary directly at bin/miyu; ensure executable
    chmod +x $out/bin/miyu

    # Wrap so the binary finds its assets at $out/share/miyu even though it
    # historically probes /usr/share/miyu. The Rust code probes relative to
    # exe + XDG + fallback to /usr/share/miyu; providing MIYU_DATA_DIR is
    # the cleanest bridge if the binary honours env — otherwise the assets
    # are still at the Nix store path and most features work via ~/.miyu/data.
    wrapProgram $out/bin/miyu \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath finalAttrs.buildInputs}"

    runHook postInstall
  '';

  # Let autoPatchelf fix RPATH for the prebuilt ELF
  dontStrip = false;

  meta = with lib; {
    description = "Miyu — terminal-native anime AI assistant (shell hook + daemon + WebUI)";
    homepage = "https://github.com/SHORiN-KiWATA/Miyu";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "miyu";
  };
})
