# Home-manager configuration for the primary user.
#
# Put user-level programs here (shell, editor, git, terminal tools, etc.).
# System-level services belong in `modules/` or `hosts/<name>/default.nix`.
{ config, pkgs, lib, ... }:
{
  # User-level programs for the niri + Noctalia desktop.
  # (bar / launcher / notifications / lock / media / screenshots / clipboard
  # are all provided by Noctalia, so only a terminal is needed here.)
  home.packages = with pkgs; [
    foot # terminal
    wl-clipboard # wl-copy / wl-paste
  ];

  # Noctalia (Wayland desktop shell) config.
  # Docs: https://docs.noctalia.dev/noctalia/configuration/
  # More settings can be tweaked in the GUI (Settings app), which writes
  # overrides to ~/.local/state/noctalia/settings.toml.
  xdg.configFile."noctalia/config.toml".text = ''
    [theme]
    mode = "dark"
    source = "builtin"
    builtin = "Catppuccin"

    [bar.default]
    position = "top"
  '';

  # niri (scrollable-tiling Wayland compositor) config.
  # Docs: https://niri-wm.github.io/niri/Configuration:-Introduction
  # Noctalia integration: https://docs.noctalia.dev/noctalia/compositor-settings/niri/
  xdg.configFile."niri/config.kdl".text = ''
    // Input devices.
    input {
        keyboard {
            xkb {
                layout "us"
            }
        }

        touchpad {
            tap
            natural-scroll
        }
    }

    // Built-in laptop display. Adjust if niri picks a wrong mode/scale.
    // Run `niri msg outputs` inside a session to list output names and modes.
    /-output "eDP-1" {
        // mode "1920x1080@60"
        // scale 1.0
    }

    layout {
        gaps 16
        center-focused-column "never"
    }

    // Noctalia: rounded corners + clipping for a modern look.
    window-rule {
        geometry-corner-radius 20
        clip-to-geometry true
    }

    // Noctalia: keep its settings window floating with a sane default size.
    window-rule {
        match app-id="dev.noctalia.Noctalia"
        open-floating true
        default-column-width { fixed 1080; }
        default-window-height { fixed 920; }
    }

    debug {
        // Allows notification actions and window activation from Noctalia.
        honor-xdg-activation-with-invalid-serial
    }

    // Start the shell (bar, launcher, notifications, ...).
    spawn-at-startup "noctalia"

    screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

    binds {
        Mod+Shift+Slash { show-hotkey-overlay; }

        // Launch apps.
        Mod+Return { spawn "foot"; }
        Mod+Space { spawn-sh "noctalia msg panel-toggle launcher"; }
        Mod+S { spawn-sh "noctalia msg panel-toggle control-center"; }
        Mod+Comma { spawn-sh "noctalia msg settings-toggle"; }
        Alt+Tab { spawn-sh "noctalia msg window-switcher"; }
        Super+Alt+L { spawn-sh "noctalia msg session lock"; }

        // Volume / media / brightness keys (handled by Noctalia's OSD).
        XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "noctalia msg volume-up"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn-sh "noctalia msg volume-down"; }
        XF86AudioMute        allow-when-locked=true { spawn-sh "noctalia msg volume-mute"; }
        XF86AudioPlay        allow-when-locked=true { spawn-sh "noctalia msg media toggle"; }
        XF86AudioNext        allow-when-locked=true { spawn-sh "noctalia msg media next"; }
        XF86AudioPrev        allow-when-locked=true { spawn-sh "noctalia msg media previous"; }
        XF86MonBrightnessUp   allow-when-locked=true { spawn-sh "noctalia msg brightness-up"; }
        XF86MonBrightnessDown allow-when-locked=true { spawn-sh "noctalia msg brightness-down"; }

        // Close / quit.
        Mod+Q { close-window; }
        Mod+Shift+E { quit; }

        // Focus navigation.
        Mod+Left  { focus-column-left; }
        Mod+Right { focus-column-right; }
        Mod+Down  { focus-window-down; }
        Mod+Up    { focus-window-up; }
        Mod+H     { focus-column-left; }
        Mod+L     { focus-column-right; }
        Mod+J     { focus-window-down; }
        Mod+K     { focus-window-up; }

        // Move windows.
        Mod+Ctrl+Left  { move-column-left; }
        Mod+Ctrl+Right { move-column-right; }
        Mod+Ctrl+Down  { move-window-down; }
        Mod+Ctrl+Up    { move-window-up; }

        // Workspaces.
        Mod+Page_Down { focus-workspace-down; }
        Mod+Page_Up   { focus-workspace-up; }
        Mod+U         { focus-workspace-down; }
        Mod+I         { focus-workspace-up; }
        Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
        Mod+Ctrl+Page_Up   { move-column-to-workspace-up; }

        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+Ctrl+1 { move-column-to-workspace 1; }
        Mod+Ctrl+2 { move-column-to-workspace 2; }
        Mod+Ctrl+3 { move-column-to-workspace 3; }
        Mod+Ctrl+4 { move-column-to-workspace 4; }
        Mod+Ctrl+5 { move-column-to-workspace 5; }
        Mod+Ctrl+6 { move-column-to-workspace 6; }

        // Floating / fullscreen / maximize.
        Mod+V       { toggle-window-floating; }
        Mod+Shift+V { switch-focus-between-floating-and-tiling; }
        Mod+F       { maximize-column; }
        Mod+Shift+F { fullscreen-window; }

        // Column width presets.
        Mod+R { switch-preset-column-width; }

        // Screenshots (niri's built-in).
        Print      { screenshot; }
        Ctrl+Print { screenshot-screen; }
        Alt+Print  { screenshot-window; }

        // Scrollable-tiling: consume / expel windows.
        Mod+BracketLeft  { consume-or-expel-window-left; }
        Mod+BracketRight { consume-or-expel-window-right; }
        Mod+Backslash { consume-window-into-column; }
        Mod+Period    { expel-window-from-column; }
    }
  '';
}
