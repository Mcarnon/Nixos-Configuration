# Noctalia v5 — SHORiN 外观迁移（原生 C++/TOML）。
#
# Noctalia v5 是全新一代（Quickshell v4 → 原生 C++/OpenGL ES），
# 配置从 JSON 改为 TOML，IPC 从 `qs -c noctalia-shell ipc call` 改为
# `noctalia msg`，随附官方的 Home Manager 模块（programs.noctalia）。
#
# 本模块：
#   - 使用官方 homeModules.default（提供包 + systemd 用户服务）
#   - 以 v4 的 SHORiN 外观为准，用 v5 TOML 复刻（bar/widgets/字体/配色/壁纸）
#   - 把 Noctalia 各面板常用的外部工具放进 PATH（noctalia-launch 旧逻辑已由
#     官方 systemd 服务替代，这里保留工具清单以保证模板/脚本可用）
#   - 随机动漫壁纸脚本 ~/.local/bin/random-anime-wallpaper-noctalia（改为 noctalia msg）
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  home = config.home.homeDirectory;
  wallpaperDir = "${home}/Pictures/Wallpapers";
  wallpaperTonesFile = "${home}/.config/wallpaper-tones.txt";
  system = pkgs.stdenv.hostPlatform.system;
  noctaliaModule = inputs.noctalia.homeModules.default;
  noctaliaPkg = inputs.noctalia.packages."${system}".default;

  # scan-tones.py 的运行时：numpy + pillow（k-means 主色调分析）。
  toneScanPython = pkgs.python3.withPackages (
    ps: with ps; [
      numpy
      pillow
    ]
  );

  # scan-tones 命令：对壁纸库做主色调分析，生成 ~/.config/wallpaper-tones.txt。
  scanTonesBin = pkgs.writeShellScriptBin "scan-tones" ''
    exec ${toneScanPython}/bin/python3 "${home}/.config/niri/scripts/scan-tones.py" "${wallpaperDir}" "${wallpaperTonesFile}" "$@"
  '';

  # v5 TOML 配置（复刻 SHORiN 外观；模板目录引用保持在 config/templates）。
  noctaliaConfig = pkgs.writeText "noctalia-config.toml" (builtins.readFile ./config/config.toml);

  # Noctalia 面板/脚本运行时依赖的外部命令（旧 noctaliaTools 清单的 v5 保留版）。
  noctaliaTools = with pkgs; [
    bash # /bin/sh —— 模板 post_hook 等脚本
    coreutils
    gnugrep
    gnused
    gawk
    findutils
    procps # ps/free/top —— sysmon 等
    networkmanager # nmcli —— Wi-Fi/网络
    wireplumber # wpctl —— 音量/静音
    wtype # 键盘模拟（锁屏）
    util-linux # rfkill
    power-profiles-daemon # powerprofilesctl
    brightnessctl
    pamixer
    playerctl
    cliphist
    wl-clipboard
    wlr-randr
    bluez # bluetoothctl
    imagemagick
    xdg-utils
    wlsunset
    ddcutil
    wget
    glib.bin # gsettings/dconf —— GTK 模板 apply.sh 依赖
    inotify-tools # inotifywait —— mpvpaper-sync.sh 监听视频切换
    jq # jq —— mpvpaper-sync.sh 解析 assignments.json
  ];
in
{
  imports = [ noctaliaModule ];

  home.packages = with pkgs; [
    mpvpaper # 动态壁纸播放器（Noctalia mpvpaper 插件后端）
    ffmpeg # 视频缩略图生成（mpv-hook.lua / wallpaper-hook.sh）
    qt6Packages.qt6ct # 其他 Qt 桌面应用的图标/主题（v4 时代延续；noctalia v5 本身用不到）
    libnotify # random-anime-wallpaper-noctalia 的 notify-send
    (writeShellScriptBin "random-anime-wallpaper-noctalia" (
      builtins.readFile ./bin/random-anime-wallpaper-noctalia
    ))

    # NyxNiri 壁纸选择器依赖
    gtk3
    gdk-pixbuf
    gtk-layer-shell
    (python3.withPackages (
      ps: with ps; [
        pygobject3 # gi.repository.Gtk / GdkPixbuf
        pycairo # 某些主题需要
      ]
    ))
    scanTonesBin # scan-tones —— 壁纸主色调分析 / 生成色调库
  ];

  # 官方模块：启用 Noctalia v5 + systemd 用户服务。
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = noctaliaConfig;
  };

  # 默认壁纸（noctalia 壁纸选择器能直接看到）+ 用户头像。
  home.file."Pictures/Wallpapers/wallhaven-d88d53.png".source =
    ../../../../wallpapers/wallhaven-d88d53.png;
  home.file.".face".source = ../../../../wallpapers/wallhaven-d88d53.png;

  # qt6ct 设置种子（沿用 v4：其他 Qt 桌面应用读这个，需可写副本）。
  home.file.".config/qt6ct/qt6ct.conf".source = ../../../../home/files/qt6ct/qt6ct.conf;

  # 模板输入文件（fitx5 主题、GTK 图标重着色）随配置目录部署为可写副本。
  home.file.".config/noctalia/templates" = {
    source = ./config/templates;
    recursive = true;
  };

  # mpvpaper 动态壁纸脚本
  home.file.".config/noctalia/mpv-hook.lua".source = ./bin/mpv-hook.lua;
  home.file.".config/noctalia/wallpaper-hook.sh" = {
    source = ./bin/wallpaper-hook.sh;
    executable = true;
  };
  home.file.".config/noctalia/mpvpaper-sync.sh" = {
    source = ./bin/mpvpaper-sync.sh;
    executable = true;
  };

  # theme-sync.sh：主题切换调度中枢（GTK 主题跟随的核心）
  home.file.".config/noctalia/theme-sync.sh" = {
    source = ./bin/theme-sync.sh;
    executable = true;
  };

  # NyxNiri 壁纸选择器（Super+W 唤起，替代 Noctalia 内置选择器）
  home.file.".config/niri/scripts/wallpaper-picker.py" = {
    source = ./nix/wallpaper-picker.py;
    executable = true;
  };
  home.file.".config/niri/scripts/wallpaper_picker" = {
    source = ./nix/wallpaper_picker;
    recursive = true;
  };
  home.file.".config/niri/scripts/wallpapers-rotate.py" = {
    source = ./nix/wallpapers-rotate.py;
    executable = true;
  };
  home.file.".config/niri/scripts/scan-tones.py" = {
    source = ./nix/scan-tones.py;
    executable = true;
  };

  # 每半小时自动轮换壁纸（静态图 + 视频/GIF），复用 wallpaper_picker 的
  # backend 应用逻辑；service 由 timer 触发，wants+after 保证图形会话就绪。
  # 选图按时段色调偏好（每天 03:20 由 scan-tones 服务重扫色调库）。
  systemd.user.services.wallpapers-rotate = {
    Unit = {
      Description = "Noctalia wallpaper rotation (static + video)";
      After = [
        "graphical-session.target"
        "noctalia.service"
      ];
      Wants = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.python3}/bin/python3 ${config.home.homeDirectory}/.config/niri/scripts/wallpapers-rotate.py";
      Environment = "PATH=${
        lib.makeBinPath (
          with pkgs;
          [
            coreutils
            gnugrep
            gnused
            findutils
            procps
            util-linux
          ]
          ++ [ noctaliaPkg ]
        )
      }:${config.home.homeDirectory}/.local/bin";
    };
  };
  systemd.user.timers.wallpapers-rotate = {
    Timer = {
      OnCalendar = "*:0/30";
      Persistent = true;
      Unit = "wallpapers-rotate.service";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  # 每日重扫壁纸色调库（scan-tones：主色调 -> dark/cool/warm/neutral/bright）。
  systemd.user.services.scan-tones = {
    Unit = {
      Description = "Regenerate Noctalia wallpaper tone library";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${scanTonesBin}/bin/scan-tones";
      # ffmpeg 用于提取视频中间帧进行分析
      Environment = "PATH=${
        lib.makeBinPath (
          with pkgs;
          [
            ffmpeg
            coreutils
          ]
        )
      }";
    };
  };
  systemd.user.timers.scan-tones = {
    Timer = {
      OnCalendar = "*-*-* 03:20:00";
      Persistent = true;
      Unit = "scan-tones.service";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  # 把工具目录前置进 PATH，让 Noctalia 派生的外部命令总能找到。
  # 同时保留用户 PATH（包含 ~/.local/bin）。
  home.sessionPath = [ "${home}/.local/bin" ] ++ map (pkg: "${pkg}/bin") noctaliaTools;

  # 输入法 / Qt 主题变量（沿用 v4 的设置；noctalia 不再用 Qt6，但桌面其余 Qt
  # 应用仍需要 qt6ct 集成）。
  home.sessionVariables = {
    "QT_QPA_PLATFORM" = "wayland;xcb";
    "QT_QPA_PLATFORMTHEME" = "qt6ct";
    "QT_AUTO_SCREEN_SCALE_FACTOR" = "1";
    "XMODIFIERS" = "@im=fcitx";
    "GTK_IM_MODULE" = "fcitx";
    "QT_IM_MODULE" = "fcitx";
  };
}
