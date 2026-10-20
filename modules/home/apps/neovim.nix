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
    gcc # 提供 cc，rustc 链接时需要（否则报 linker `cc` not found）
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

  # 文件管理器里双击文本文件用的条目。上游 nvim.desktop 是 Terminal=true，
  # 启动时由 GLib 自己去找终端（xdg-terminal-exec / gnome-terminal / …）。
  # 在 niri 下不同启动方（Thunar、Clavis 文件选择器）的 PATH 环境不一致，
  # 找不到时就报 “找不到应用程序需要的终端”。这里显式起 foot，
  # Terminal=false，完全绕开 GLib 的终端查找。
  xdg.desktopEntries.foot-nvim = {
    name = "Neovim (foot)";
    genericName = "Text Editor";
    comment = "在 foot 中打开 Neovim";
    exec = "${pkgs.foot}/bin/foot -e ${config.programs.neovim.finalPackage}/bin/nvim %F";
    terminal = false;
    icon = "nvim";
    categories = [ "Utility" "TextEditor" ];
    mimeType = [ "text/plain" "text/x-shellscript" ];
  };
}
