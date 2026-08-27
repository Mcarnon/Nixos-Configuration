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
  # Runtime deps (arch PKGBUILD: depends=(alsa-lib chafa gcc-libs glibc ripgrep))
  ripgrep,
  chafa,
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
    ripgrep # runtime dep (miyu uses rg for file search)
    chafa # runtime dep (image display in terminal)
  ];

  # build.rs embeds prompts and builds tiktoken/jieba indices at compile time.
  # No special flags needed beyond the default cargo build.

  # Install runtime assets to share/miyu — NixOS has no /usr/share so the binary
  # looks next to itself at ../share/miyu (relative to $out/bin/miyu).
  postInstall = ''
    mkdir -p $out/share/miyu/{fonts,memes,scripts,default-kb}
    cp -a web $out/share/miyu/web
    cp -a kb $out/share/miyu/kb
    cp -a resources $out/share/miyu/resources
    # assets/ contains build-time inputs (tiktoken, jieba dict) and possibly
    # runtime extras — ship the whole dir to match the Arch package layout.
    cp -a assets $out/share/miyu/assets
    # Fonts (Noto CJK + Emoji + JetBrains) for long-reply image rendering.
    cp -a assets/fonts/* $out/share/miyu/fonts/ 2>/dev/null || true
    # Memes (built-in sticker library; follows default persona).
    cp -a src/memes/* $out/share/miyu/memes/ 2>/dev/null || true
    # System scripts.
    cp -a src/scripts/* $out/share/miyu/scripts/ 2>/dev/null || true
  '';

  meta = with lib; {
    description = "Miyu — terminal-native anime AI assistant (shell hook + daemon + WebUI)";
    homepage = "https://github.com/SHORiN-KiWATA/Miyu";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "miyu";
  };
})
