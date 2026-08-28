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
      description = "Primary locale (LANG).";
    };

    supportedLocales = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
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

    # IM env vars for apps that don't speak Wayland IM protocol
    environment.variables = lib.mkIf cfg.inputMethod.enable {
      GTK_IM_MODULE  = "fcitx";
      QT_IM_MODULE   = "fcitx";
      XMODIFIERS     = "@im=fcitx";
      SDL_IM_MODULE  = "fcitx";
      GLFW_IM_MODULE = "ibus";
      # Rime user data dir (XDG standard: ~/.config/, not ~/.local/share/)
      RIME_USER_DIR   = "%h/.config/fcitx5/rime";
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

    # fcitx5 is started via niri's startup.kdl (spawn-at-startup "fcitx5").
    # Keep a disabled systemd service here so `systemctl --user stop fcitx5`
    # still works and the fcitx5 module can be toggled cleanly.
    systemd.user.services.fcitx5 = lib.mkIf cfg.inputMethod.enable {
      description = "Fcitx5 input method";
      wantedBy = [ ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.fcitx5}/bin/fcitx5";
        Restart = "on-failure";
      };
    };

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
