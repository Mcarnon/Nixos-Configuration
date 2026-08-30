# Screenshot / clipboard / volume / media tools + mpv.
{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    grim # screenshot
    slurp # region select for screenshots
    wl-clipboard # Wayland clipboard (wl-copy / wl-paste)
    pamixer # volume control (bound to XF86 keys in home/niri/binds.kdl)
    playerctl # MPRIS media keys (bound in home/niri/binds.kdl)
    brightnessctl # brightness CLI (bound to XF86 keys in home/niri/binds.kdl)
    cliphist # clipboard history store (picked via fuzzel, bound to Mod+Alt+V)
    pavucontrol # 音量设置 GUI（waybar pulseaudio 模块 on-click）
    mpv # video player (mimeapps 默认；mpv.conf 见下方)
  ];

  xdg.configFile."mpv/config".source = ../../../home/files/mpv.conf;
}
