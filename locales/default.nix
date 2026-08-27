# Locale / input-method / font framework.
#
# This module owns the bits every region shares: the primary locale, the list
# of generated locales, the Fcitx5 input-method framework, and the base font
# set. Region profiles (imported below) then add their own locale settings,
# input engines and font preferences.
#
# To add a region:
#   1. create `locales/<region>.nix` with `options.locales.<region>.enable`,
#   2. import it below,
#   3. enable it from the host with `locales.<region>.enable = true`.
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
      description = "Primary locale (LANG).";
    };

    supportedLocales = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Extra locales to generate. Region profiles append their own locale
        here. `en_US.UTF-8/UTF-8` is always added as a base.
      '';
    };

    inputMethod.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the Fcitx5 input method framework.";
    };
  };

  imports = [
    ./zh-cn.nix
  ];

  config = {
    i18n = {
      defaultLocale = cfg.defaultLocale;
      # en_US is always generated as a base; regions append via `supportedLocales`.
      supportedLocales = [ "en_US.UTF-8/UTF-8" ] ++ cfg.supportedLocales;

      # Input method framework (one framework for all regions; engines are
      # added per-region via `i18n.inputMethod.fcitx5.addons`).
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

    # Explicit env for apps that don't pick up Wayland IM protocol (foot, some Electron)
    environment.variables = lib.mkIf cfg.inputMethod.enable {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
      SDL_IM_MODULE = "fcitx";
      GLFW_IM_MODULE = "ibus"; # fcitx via ibus bridge for some GLFW apps
    };

    # Ensure fcitx5 + Qt/GTK frontends for Wayland candidate window
    services.dbus.packages = lib.mkIf cfg.inputMethod.enable (with pkgs; [ fcitx5 ]);

    # Qt + GTK frontends ensure the candidate window renders on Wayland
    environment.systemPackages = lib.mkIf cfg.inputMethod.enable (
      with pkgs;
      [
        fcitx5-gtk
        qt6Packages.fcitx5-chinese-addons # 新 nixpkgs 中已从顶层移到 qt6Packages
        qt6Packages.fcitx5-qt
        qt6Packages.fcitx5-configtool
      ]
    );

    # Auto-start fcitx5 daemon on login (NixOS i18n.inputMethod only sets env, not the service)
    # NB: NixOS `systemd.user.services` uses wantedBy/after/serviceConfig (not Unit/Service/Install).
    systemd.user.services.fcitx5 = lib.mkIf cfg.inputMethod.enable {
      description = "Fcitx5 input method";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.fcitx5}/bin/fcitx5";
        Restart = "on-failure";
      };
    };

    # Rime default schema deployed from modules/home/fcitx5.nix (HM module)

    fonts = {
      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans # Source Han Sans (SC/TC/JP/KR)
        noto-fonts-cjk-serif # Source Han Serif
        noto-fonts-color-emoji
        nerd-fonts.jetbrains-mono # monospace + icon font
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
