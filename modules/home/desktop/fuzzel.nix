# Fuzzel app launcher — SHORiN minimal-niri 原版 fuzzel.ini（raw 部署）。
# 键位：Mod+Z / Mod+Space 启动；Mod+V 剪贴板（见 binds.kdl）。
{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = [ pkgs.fuzzel ];

  xdg.configFile."fuzzel/fuzzel.ini".source = ../../../home/files/fuzzel.ini;

  # 剪贴板选择辅助函数（终端里手动用；Mod+Alt+V 走 footclient+fuzzel 管线）
  xdg.configFile."fish/functions/cliphist_pick.fish".text = ''
    function cliphist_pick
      cliphist list | fuzzel --dmenu | cliphist decode | wl-copy
    end
  '';
}
