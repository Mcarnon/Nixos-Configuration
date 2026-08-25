# Miyu: terminal-native AI assistant (https://github.com/SHORiN-KiWATA/Miyu)
#
# Built from source via cargo (avoids Arch glibc 2.43 mismatch).
# On rebuild, bump `version` and update `rev` + `hash` (SRI) from the repo.
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  perl,
  libclang,
  alsa-lib,
  fontconfig,
  freetype,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "miyu";
  version = "0.4.5";

  src = fetchFromGitHub {
    owner = "SHORiN-KiWATA";
    repo = "Miyu";
    rev = "v${finalAttrs.version}";
    hash = "sha256-PEyVg0SEPKf85E14EusgGmNIYOcr5KXOuS9e9QftlPo=";
  };

  cargoLock.lockFile = ./Cargo.lock;

  # Upstream's test suite needs network + external services (fcitx wiki, MCP
  # servers); we only want the binary, so skip `cargo test` in the build.
  doCheck = false;

  nativeBuildInputs = [
    pkg-config
    perl # needed by some crate build scripts
    libclang # for bindgen (alsa-sys)
  ];

  buildInputs = [
    alsa-lib
    fontconfig
    freetype
  ];

  # build.rs embeds prompts and builds tiktoken/jieba indices at compile time.
  # No special flags needed beyond the default cargo build.

  # Install runtime assets (WebUI, knowledge base, resources) to share/miyu
  # so the binary can find them (it probes /usr/share/miyu as fallback).
  postInstall = ''
    mkdir -p $out/share/miyu
    cp -a web $out/share/miyu/web
    cp -a kb $out/share/miyu/kb
    cp -a resources $out/share/miyu/resources
    # assets/ contains build-time inputs (tiktoken, jieba dict) and possibly
    # runtime extras — ship the whole dir to match the Arch package layout.
    cp -a assets $out/share/miyu/assets
  '';

  meta = with lib; {
    description = "Miyu — terminal-native anime AI assistant (shell hook + daemon + WebUI)";
    homepage = "https://github.com/SHORiN-KiWATA/Miyu";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "miyu";
  };
})
