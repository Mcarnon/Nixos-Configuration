# 中文环境: locale / 字体 / Fcitx5 输入法
{ config, pkgs, lib, ... }:
{
  i18n = {
    defaultLocale = "zh_CN.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "zh_CN.UTF-8";
      LC_IDENTIFICATION = "zh_CN.UTF-8";
      LC_MEASUREMENT = "zh_CN.UTF-8";
      LC_MONETARY = "zh_CN.UTF-8";
      LC_NAME = "zh_CN.UTF-8";
      LC_NUMERIC = "zh_CN.UTF-8";
      LC_PAPER = "zh_CN.UTF-8";
      LC_TELEPHONE = "zh_CN.UTF-8";
      LC_TIME = "zh_CN.UTF-8";
    };
    supportedLocales = [ "zh_CN.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];
  };

  # 输入法: Fcitx5 拼音 (如需雾凇拼音 Rime 可换成 fcitx5-rime + rime-ice)
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-chinese-addons       # 拼音
        fcitx5-gtk                  # GTK 输入法模块
        qt6Packages.fcitx5-configtool
      ];
    };
  };

  # 应用输入法环境变量
  environment.variables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
    GLFW_IM_MODULE = "ibus";
  };

  # 中文字体
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans       # 思源黑体
      noto-fonts-cjk-serif      # 思源宋体
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono # 等宽 + 图标字体
      nerd-fonts.symbols-only
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        sansSerif = [ "Noto Sans CJK SC" "Noto Sans" "Noto Color Emoji" ];
        serif = [ "Noto Serif CJK SC" "Noto Serif" "Noto Color Emoji" ];
        monospace = [ "JetBrainsMono Nerd Font" ];
      };
    };
  };
}
