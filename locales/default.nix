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
<<<<<<< HEAD
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
      SDL_IM_MODULE = "fcitx";
      GLFW_IM_MODULE = "ibus"; # fcitx via ibus bridge for some GLFW apps
      # System-wide rime user data dir. fcitx5-rime seeds it from the shared
      # rime-data (which carries our declarative default.custom.yaml) on first
      # run, so no per-user config is required.
      RIME_USER_DIR = "$HOME/.local/share/fcitx5/rime";
    };

    # Additional fcitx5 wayland configuration
    environment.sessionVariables = lib.mkIf cfg.inputMethod.enable {
      QT_QPA_PLATFORM = "wayland";  # Qt wayland platform
      SDL_VIDEODRIVER = "wayland";  # SDL wayland driver
=======
      GTK_IM_MODULE  = "fcitx";
      QT_IM_MODULE   = "fcitx";
      XMODIFIERS     = "@im=fcitx";
      SDL_IM_MODULE  = "fcitx";
      GLFW_IM_MODULE = "ibus";
      RIME_USER_DIR   = "%h/.config/fcitx5/rime";
>>>>>>> bd5d73f9d86db0d5a599f579bb2a409c21ba59be
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

<<<<<<< HEAD
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

    # Rime default schema is baked into the shared rime-data in locales/zh-cn.nix.

=======
>>>>>>> bd5d73f9d86db0d5a599f579bb2a409c21ba59be
    fonts = {
      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        nerd-fonts.jetbrains-mono
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
