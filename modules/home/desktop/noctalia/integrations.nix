# Component integration: the "glue" beyond IPC.
#
# Noctalia's IPC is a per-session Unix socket at
# `$XDG_RUNTIME_DIR/noctalia-$WAYLAND_DISPLAY.sock` — not a TCP port, so no
# port conflicts; plugins can register their own `noctalia msg` commands.
{ config, lib, ... }:
{
  programs.noctalia.settings = {
    # Hooks: Noctalia events → arbitrary commands (component wiring hub).
    # Note: the example hooks use `notify-send`; install `libnotify` first if
    # you enable them (they're commented out by default to avoid runtime noise).
    hooks = {
      # wallpaper_changed = "notify-send 'Noctalia' 'Wallpaper changed'";
      # theme_mode_changed = "~/.config/noctalia/theme-sync.sh"; # custom sync
      # battery_under_threshold = "notify-send 'Power' 'Battery low'";
    };

    # Launcher prefix triggers (type `/win`, `/wall`, `/session`).
    shell.launcher.providers = {
      windows = { prefix = "win"; global = false; };
      session = { prefix = "session"; global = false; };
      wallpaper = { prefix = "wall"; global = false; };
    };

    # Custom templates: render the palette into any app config.
    # (niri's config is a store symlink, so the template can't edit it — see
    # docs/DESKTOP.md for the workaround before enabling this.)
    # theme.templates.user.niri_colors = {
    #   input_path  = "~/Nixos-Configuration/home/niri/colors.kdl";
    #   output_path = "~/.config/niri/colors.kdl";
    #   post_hook   = "niri msg action do-screen-transition";
    # };
  };
}
