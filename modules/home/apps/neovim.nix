# Neovim — text editor + temp IDE (user-level).
# Binary via programs.neovim (HM) — not systemPackages (per previous decision: keep only in home).
# Config: real dotfiles deployed via xdg.configFile. Edit the files under ./nvim/ (init.lua),
# HM just drops them to ~/.config/nvim. No nixvim transpilation — you write plain Lua.
{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    # withNodeJs / withPython3 for LSP-adjacent tools if needed; keep false for minimal
    withNodeJs = false;
    withPython3 = false;
    defaultEditor = true; # sets $EDITOR=nvim
  };

  # Optional: LSP / formatter binaries for temp IDE use — uncomment as needed.
  # Kept separate from neovim package so you can toggle per-language.
  home.packages = with pkgs; [
    # Rust toolchain
    cargo
    rustc
    rustfmt
    clippy
    rust-analyzer
    # Nix
    nil
    nixpkgs-fmt
    # Lua
    lua-language-server
    stylua
  ];

  # Deploy real nvim dotfiles. Source dir is co-located with this module.
  xdg.configFile."nvim".source = ./nvim;
  xdg.configFile."nvim".recursive = true;
}
