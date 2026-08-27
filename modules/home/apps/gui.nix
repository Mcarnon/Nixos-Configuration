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
}
