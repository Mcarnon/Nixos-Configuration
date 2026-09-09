# Locale / input-method / font framework.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.locales;
in
{
  options.locales = {
    defaultLocale = lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
    };

    supportedLocales = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };

    inputMethod.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  imports = [
    ./zh-cn.nix
  ];

  config = {
    i18n = {
      defaultLocale = cfg.defaultLocale;
      supportedLocales = [ "en_US.UTF-8/UTF-8" ] ++ cfg.supportedLocales;

      inputMethod = lib.mkIf cfg.inputMethod.enable {
        enable = true;
        type = "fcitx5";
        fcitx5 = {
          waylandFrontend = true;
          addons = with pkgs; [
            fcitx5-gtk
            qt6Packages.fcitx5-configtool
          ];
        };
      };
    };

    environment.variables = lib.mkIf cfg.inputMethod.enable {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
      SDL_IM_MODULE = "fcitx";
      GLFW_IM_MODULE = "ibus";
      # RIME_USER_DIR 由 home-manager 设置（modules/home/fcitx5.nix，
      # $HOME 形式）；这里不再设 %h 版本（environment.variables 不展开 %h，
      # 字面值会污染 rime 的用户目录查找）。
    };

    services.dbus.packages = lib.mkIf cfg.inputMethod.enable (with pkgs; [ fcitx5 ]);

    environment.systemPackages = lib.mkIf cfg.inputMethod.enable (
      with pkgs;
      [
        fcitx5-gtk
        qt6Packages.fcitx5-chinese-addons
        qt6Packages.fcitx5-qt
        qt6Packages.fcitx5-configtool
      ]
    );

    fonts = {
      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        nerd-fonts.jetbrains-mono
        nerd-fonts.caskaydia-cove
        nerd-fonts.symbols-only
      ];
      fontconfig = {
        enable = true;
        defaultFonts = {
          monospace = [ "JetBrainsMono Nerd Font" ];
        };
      };
    };
  };
}
