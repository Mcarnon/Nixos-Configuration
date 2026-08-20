# Chinese environment: locale / fonts / Fcitx5 input method
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

  # Input method: Fcitx5 Pinyin (swap to fcitx5-rime + rime-ice for Wusong Pinyin)
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-chinese-addons       # Pinyin
        fcitx5-gtk                  # GTK input method modules
        qt6Packages.fcitx5-configtool
      ];
    };
  };

  # Input method environment variables
  environment.variables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    SDL_IM_MODULE = "fcitx";
    GLFW_IM_MODULE = "ibus";
  };

  # Chinese fonts
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans       # Source Han Sans
      noto-fonts-cjk-serif      # Source Han Serif
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono # monospace + icon font
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
