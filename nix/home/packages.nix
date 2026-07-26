{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # 基础工具
    neovim
    tmux
    ripgrep
    fd
    bat
    eza
    zoxide
    fzf

    # 开发工具
    nodejs
    python3
    gcc
    cargo
    rustc

    # 应用
    obsidian
    discord
    vlc
  ];
}
