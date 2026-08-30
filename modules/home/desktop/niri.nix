# Link niri's KDL config to ~/.config/niri + desktop helper scripts.
# Config layout follows SHORiN's minimal-niri: config/binds/rule/layout
# (+ machine-specific niri-hardware.kdl from the host) + hyprlock + scripts.
#
# Two scripts need Nix store paths (freedesktop sound files). They live as
# plain bash files under home/niri/scripts/ with a @SOUNDS_DIR@ placeholder,
# and are wrapped into real packages here via readFile + replaceStrings —
# this avoids Nix string-interpolation pitfalls with bash `${...}` inside
# `''...''` strings.
{
  config,
  pkgs,
  lib,
  hostPath,
  ...
}:
let
  soundsDir = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop";

  mkSoundScript = name: file:
    pkgs.writeShellScriptBin name (
      builtins.replaceStrings [ "@SOUNDS_DIR@" ] [ soundsDir ] (
        builtins.readFile file
      )
    );

  # Screenshot shutter sound daemon: binds send SIGUSR1 to "arm" it, then it
  # plays a click when a screenshot lands in the clipboard (wl-paste watch).
  screenshotSound = mkSoundScript "screenshot-sound" ../../../home/niri/scripts/screenshot-sound.sh;

  # Force-kill a window by clicking it (SIGKILL, optionally the whole tree).
  forceKillWindow = mkSoundScript "niri-force-kill-window" ../../../home/niri/scripts/niri-force-kill-window;
in
{
  home.packages = [
    pkgs.wlsunset # 护眼模式（toggle-wlsunset 脚本驱动）
    pkgs.libnotify # notify-send（脚本/waybar 通知依赖）
    pkgs.xhost # config.kdl 的 xhost +si:localuser:root（xorg 包集已废弃，用顶层名）
    pkgs.xprop # niri-force-kill-window 处理 XWayland 窗口
    pkgs.swayosd # 音量/亮度 OSD（binds.kdl 里 swayosd-client 的常驻服务）
    pkgs.sound-theme-freedesktop # 截图/杀窗口音效
    pkgs.psmisc # killall（binds 里隐藏 waybar / 壁纸脚本杀进程）
    screenshotSound
    forceKillWindow
  ];

  xdg.configFile = {
    "niri/config.kdl".source = ../../../home/niri/config.kdl;
    "niri/binds.kdl".source = ../../../home/niri/binds.kdl;
    "niri/rule.kdl".source = ../../../home/niri/rule.kdl;
    "niri/layout.kdl".source = ../../../home/niri/layout.kdl;
    "niri/niri-hardware.kdl".source = hostPath + "/niri-hardware.kdl";

    # Pure helper scripts (bind to ~/.config/niri/scripts/... as in Shorin's config)
    "niri/scripts/niri-binds" = {
      source = ../../../home/niri/scripts/niri-binds;
      executable = true;
    };
    "niri/scripts/niri-quick-switch-fuzzel.py" = {
      source = ../../../home/niri/scripts/niri-quick-switch-fuzzel.py;
      executable = true;
    };
    "niri/scripts/niri-pick" = {
      source = ../../../home/niri/scripts/niri-pick;
      executable = true;
    };
    "niri/scripts/toggle-wlsunset" = {
      source = ../../../home/niri/scripts/toggle-wlsunset;
      executable = true;
    };
  };
}
