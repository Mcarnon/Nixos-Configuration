# Dynamic wallpaper — mpvpaper 动态壁纸轮换方案
#
# 组件：
#   scan-tones.py    — k-means 聚类分析壁纸色调 (dark/cool/warm/neutral/bright)
#   wallpaper-rotate — 轮换 daemon，根据时段自动切换对应色调池的壁纸
#   wp               — CLI: list / random / set / scan / stop / restart
#   mpv-hook.lua     — mpvpaper 启动时加载（用于 Noctalia 配色同步）
#
# systemd service: wallpaper-rotate.service (开机自启)
# 使用方式:
#   wp list   # 查看色调分布
#   wp random # 按当前时段色调随机选一个
#   wp set <文件名>  # 指定文件
#   wp scan   # 重新扫描 ~/Pictures/Wallpapers/video 的色调
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # 带 numpy/pillow 的 python3 解释器（store 路径在构建时解析）
  pythonWithDeps = pkgs.python3.withPackages (ps: [ ps.numpy ps.pillow ]);
  scanTonesPython = lib.getExe pythonWithDeps;

  # 替换 scan-tones.py 调用为带完整 store 路径的 python
  # wp 和 wallpaper-rotate 都会调用 scan-tones.py，统一替换为带完整解释器路径
  scanTonesCmd = "${scanTonesPython} ${./dynamic-wallpaper/bin/scan-tones.py}";
  wpScriptContent = lib.replaceStrings [ "scan-tones.py" ] [ scanTonesCmd ]
    (builtins.readFile ./dynamic-wallpaper/bin/wp);
  rotateScriptContent = lib.replaceStrings [ "scan-tones.py" ] [ scanTonesCmd ]
    (builtins.readFile ./dynamic-wallpaper/bin/wallpaper-rotate.sh);
in
{
  # ── 依赖 + 脚本 ───────────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    mpvpaper

    (writeShellScriptBin "wallpaper-rotate" rotateScriptContent)
    (writeShellScriptBin "wp" wpScriptContent)
  ];

  # ── mpv Lua hook（mpvpaper 启动时加载，同步 Noctalia 配色）──────────────────
  home.file.".config/noctalia/mpv-hook.lua".source = ./dynamic-wallpaper/mpv-hook.lua;

  # ── systemd user service ────────────────────────────────────────────────────
  systemd.user.services.wallpaper-rotate = {
    Unit = {
      Description = "mpvpaper 动态壁纸轮换 daemon";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "wallpaper-rotate";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };

  # ── 启用用户 systemd 服务自启 ──────────────────────────────────────────────
  systemd.user.startServices = true;
}
