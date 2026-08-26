# greetd login manager for niri, using gtkgreet (graphical, CSS-themed) on cage.
{ config, pkgs, lib, ... }:
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "greeter";
        # cage hosts gtkgreet (a Wayland compositor is required for GUI greeters);
        # -s loads the custom CSS, -c is the session started after login.
        command = "${lib.getExe pkgs.cage} -- ${lib.getExe pkgs.gtkgreet} -s /etc/greetd/style.css -c ${pkgs.niri}/bin/niri-session";
      };
    };
  };

  # The greeter user runs a Wayland compositor (cage), so it needs DRM / input / GPU access.
  users.users.greeter.extraGroups = [ "video" "input" "render" ];

  # Catppuccin-Mocha-themed login screen (GTK3 CSS consumed by gtkgreet).
  environment.etc."greetd/style.css".text = ''
    window {
        background-color: #1e1e2e;
    }

    #body {
        background-color: rgba(49, 50, 68, 0.85);
        border-radius: 12px;
        padding: 40px;
    }

    #clock {
        color: #cdd6f4;
        font-size: 48px;
        font-weight: bold;
    }

    #input-field {
        background-color: rgba(24, 24, 37, 0.8);
        border-radius: 8px;
        padding: 10px;
        color: #cdd6f4;
        caret-color: #cdd6f4;
    }

    label {
        color: #cdd6f4;
    }

    button {
        border-radius: 8px;
        padding: 8px 16px;
    }

    button.suggested-action {
        background-color: #89b4fa;
        color: #11111b;
        font-weight: bold;
    }
  '';
}
