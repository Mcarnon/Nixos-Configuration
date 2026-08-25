# GUI / desktop applications.
{ config, pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    # Editors
    zed-editor # Zed (CLI: `zeditor`)

    # Browsers
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Note-taking / knowledge
    obsidian

    # Media
    obs-studio # OBS
    splayer # Netease Cloud Music

    # System
    foot # Wayland terminal emulator
    nautilus # file manager (niri's portal file picker also depends on it)
    xdg-utils # xdg-open & friends
  ];
}
