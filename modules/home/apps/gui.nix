# GUI / desktop applications.
{ config, pkgs, ... }:
{
  home.packages = with pkgs; [

    # -- Essentials --
    foot # Wayland terminal emulator
    nautilus # file manager (niri's portal file picker also depends on it)
    zen-browser # browser
    xdg-utils # xdg-open & friends

    # -- Users specific --
    zed-editor # development tool
    obsidian # note-taking
    obs-studio # screen recording
    splayer # netease cloud music player
    hmcl # minecraft launcher

  ];
}
