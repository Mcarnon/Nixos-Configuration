# greetd login manager: ReGreet (GTK4 greeter, fully themeable).
#
# The login background references a file under the repo's `wallpapers/`
# directory (relative path -> store path, readable by the greeter user and
# reproducible). Drop `login.png` (or a `.mp4` — ReGreet bundles GStreamer for
# video/animated backgrounds) there and uncomment `settings.background`.
{
  config,
  pkgs,
  lib,
  ...
}:
{
  # seatd provides the DRM / input seat abstraction that cage (the greeter)
  # and niri both need. Without it the session aborts with
  #   "could not connect to socket /run/seatd.sock: No such file or directory"
  #   "Backend 'seatd' failed to open seat, skipping"
  # and greetd bounces the user back to the login screen. The seatd socket is
  # owned by the `seat` group, so both the session user and the greeter user
  # must be members (session user already is; greeter added below).
  services.seatd.enable = true;

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
        reboot = [
          "systemctl"
          "reboot"
        ];
        poweroff = [
          "systemctl"
          "poweroff"
        ];
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
  users.users.greeter.extraGroups = [
    "video"
    "input"
    "render"
    "seat" # without this cage cannot reach the seatd socket
  ];

  # greetd core: must enable the daemon and define the session command
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # Launch the niri session wrapper (activates graphical-session.target)
        command = "${pkgs.niri}/bin/niri-session";
      };
    };
  };
}
