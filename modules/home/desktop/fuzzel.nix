# Fuzzel app launcher — the SHORiN minimal-niri launcher (replaces the old
# Clavis "spotlight"). Catppuccin-ish colors to match foot in gui.nix.
{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "foot";
        font = "JetBrainsMono Nerd Font:size=11";
        prompt = "❯ ";
        layer = "overlay";
        width = "45";
        horizontal-pad = "24";
        vertical-pad = "18";
        lines = "12";
      };
      colors = {
        background = "1e1e2eee";
        text = "cdd6f4ff";
        prompt = "89b4faff";
        match = "f5c2e7ff";
        selection = "313244ff";
        selection-text = "cdd6f4ff";
        border = "89b4faff";
      };
      border = {
        width = "2";
        radius = "14";
      };
      dmenu = { };
    };
  };

  # Clipboard history lives here as a tiny picker (bound to Mod+V in
  # home/niri/binds.kdl): cliphist list | fuzzel --dmenu | cliphist decode | wl-copy.
  # cliphist / wl-clipboard themselves come from modules/home/apps/media.nix.
  xdg.configFile."fish/functions/cliphist_pick.fish".text = ''
    function cliphist_pick
      cliphist list | fuzzel --dmenu | cliphist decode | wl-copy
    end
  '';
}
