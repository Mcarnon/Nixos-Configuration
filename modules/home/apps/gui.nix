# GUI / desktop applications.
{
  config,
  pkgs,
  inputs,
  ...
}:
{
  home.packages = with pkgs; [

    # -- Essentials --
    foot # Wayland terminal emulator
    nautilus # file manager (niri's portal file picker also depends on it)
    gvfs # trash backend + remote/removable mounts support for nautilus
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default # browser
    xdg-utils # xdg-open & friends

    # -- Users specific --
    zed-editor # development tool
    obsidian # note-taking
    obs-studio # screen recording
    splayer # netease cloud music player
    hmcl # minecraft launcher

  ];

  # foot terminal: transparent background so niri's blur shows through.
  # Pair with `xray true` in windowrule.kdl for live dynamic blur.
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "JetBrainsMono Nerd Font:size=11";
        pad = "4x4 center";
      };
      # Background: use a 0-alpha hex so foot draws RGBA and the compositor
      # sees a transparent window surface (required for niri blur to work).
      colors = {
        background = "00000000";
        regular0 = "1e1e2e";
        regular1 = "f38ba8";
        regular2 = "a6e3a1";
        regular3 = "f9e2af";
        regular4 = "89b4fa";
        regular5 = "f5c2e7";
        regular6 = "94e2d5";
        regular7 = "cdd6f4";
        bright0 = "45475a";
        bright1 = "f38ba8";
        bright2 = "a6e3a1";
        bright3 = "f9e2af";
        bright4 = "89b4fa";
        bright5 = "f5c2e7";
        bright6 = "94e2d5";
        bright7 = "ffffff";
      };
    };
  };
}
