# Lock screen + power/session menu + idle behavior.
# The lock screen is Noctalia's built-in (live desktop snapshot + blur + tint).
{ config, lib, ... }:
{
  programs.noctalia.settings = {
    lockscreen = {
      enabled = true;
      blurred_desktop = true; # background = live desktop snapshot
      blur_intensity = 0.6; # 0.0 - 1.0
      tint_intensity = 0.35; # dark overlay strength
      # wallpaper = "...";    # optional dedicated lock wallpaper
    };

    # Power/session menu entries (also reachable from the lock screen).
    shell.session.actions = [
      {
        action = "lock";
        countdown_seconds = 0;
        enabled = true;
        variant = "default";
      }
      {
        action = "lock_and_suspend";
        countdown_seconds = 5;
        enabled = true;
        variant = "default";
      }
      {
        action = "logout";
        countdown_seconds = 0;
        enabled = true;
        variant = "default";
      }
      {
        action = "reboot";
        countdown_seconds = 5;
        enabled = true;
        variant = "default";
      }
      {
        action = "shutdown";
        countdown_seconds = 5;
        enabled = true;
        variant = "destructive";
      }
    ];

    # Idle: lock after 5 min, blank after 6 min (replaces swayidle).
    idle = {
      pre_action_fade_seconds = 1.0;
      behavior = {
        lock = {
          timeout = 300;
          action = "lock";
          enabled = true;
        };
        screen-off = {
          timeout = 360;
          action = "screen_off";
          enabled = true;
        };
      };
    };
  };
}
