# greetd login manager: ReGreet (GTK4 greeter, fully themeable).
#
# The login background references a file under the repo's `wallpapers/`
# directory (relative path -> store path, readable by the greeter user and
# reproducible). Drop `login.png` (or a `.mp4` — ReGreet bundles GStreamer for
# video/animated backgrounds) there and uncomment `settings.background`.
{ config, pkgs, lib, ... }:
{
  services.displayManager.regreet = {
    enable = true;

    # GTK appearance via the module options (avoids clashing with the
    # module's own `settings.GTK.*` assignments).
    theme = {
      name = "Adwaita";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 16;
      package = pkgs.nerd-fonts.jetbrains-mono;
    };
    cursorTheme = {
      name = "volantes_cursors"; # XCursor 主题名（下划线）
      package = pkgs.volantes-cursors; # nixpkgs 属性名（连字符）
    };

    settings = {
      # TODO: drop a file at wallpapers/login.png and uncomment to use it.
      # background = {
      #   path = ../../../wallpapers/login.png;
      #   fit = "Cover";
      # };
      GTK = {
        application_prefer_dark_theme = true;
      };
      commands = {
        reboot = [ "systemctl" "reboot" ];
        poweroff = [ "systemctl" "poweroff" ];
      };
      appearance.greeting_msg = "Welcome back";
      widget.clock = {
        format = "%H:%M  %a %d %b";
        resolution = "1000ms";
        locale = "zh_CN";
      };
    };

    # GTK4 CSS for the login screen (rounded cards, translucency, accent colors).
    extraCss = ''
      window.regreet-window {
        background-color: transparent;
      }
      box.regreet-outer {
        background-color: alpha(#181825, 0.72);
        border-radius: 20px;
      }
      button {
        border-radius: 12px;
      }
    '';
  };

  # ReGreet runs on cage inside a greetd session; the greeter user needs
  # DRM / GPU / input access. nixpkgs' greetd module does NOT add these.
  users.users.greeter.extraGroups = [ "video" "input" "render" ];
}
