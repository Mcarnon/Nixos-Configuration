# Home Manager 用户配置
{ config, pkgs, lib, userData, ... }:

{
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

  # 包列表
  home.packages = with pkgs; [
    # 基础工具
    vim
    neovim
    curl
    wget
    htop
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

  # Git 配置
  programs.git = {
    enable = true;
    userName = userData.fullName;
    userEmail = userData.email;
  };

  # Bash 配置
  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      update = "nix flake update";
      switch = "sudo nixos-rebuild switch --flake /etc/nixos#nixos && home-manager switch --flake /etc/nixos#mccarnon";
    };
  };

  # Neovim 配置
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  # Alacritty 终端配置
  programs.alacritty = {
    enable = true;
    settings = {
      font.size = 12.0;
    };
  };
}
