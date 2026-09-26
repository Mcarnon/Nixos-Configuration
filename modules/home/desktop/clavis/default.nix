# Clavis Shell — niri 的 Quickshell 桌面外壳（取代 Noctalia v5）。
#
# 本模块负责：
#   - 打包来源：pkgs.clavisShell（Clavis 本体）+ pkgs.keyCli（`key` 命令/IPC）
#     + pkgs.keytop（独立系统监视 TUI），都在 pkgs/default.nix 里聚合。
#   - systemd 用户服务：clavis-shell（外壳）+ clavis-clipboard（剪贴板监听），
#     按上游文档挂在 niri.service 下（本机 niri 由 niri.service 拉起）。
#   - 会话环境兜底：clavis-session-env 等待 Wayland socket 再启动，这是以前
#     "切到 Clavis 直接黑屏"的根因（systemd user 服务拿不到 niri 的
#     WAYLAND_DISPLAY）。home/niri/startup.kdl 里的 import-environment 是第一道，
#     这个 wrapper 是第二道。
#   - 种子配置：~/.config/clavis/{config,ui-preferences}.json。非 force 部署，
#     Clavis 首次启动会自己规范化并回写，之后用户在设置界面里的改动都会被保留。
#   - niri 集成：~/.config/niri/clavis/{colors,effects,cursor}.kdl 由 Clavis 自己
#     生成，主配置里的三行 include 已经在 home/niri/config.kdl 写好，所以 Clavis
#     永远不会去改那个指向 /nix/store 的只读软链。
#   - 壁纸链路：NyxNiri 选择器 / 定时轮换 / scan-tones 色调库，全部改走
#     `key ipc call wallpaper set`。
{
  config,
  pkgs,
  lib,
  ...
}:
let
  home = config.home.homeDirectory;
  wallpaperDir = "${home}/Pictures/Wallpapers";
  wallpaperTonesFile = "${home}/.config/wallpaper-tones.txt";
  scriptsDir = "${home}/.config/niri/scripts";

  # scan-tones.py 的运行时：numpy + pillow（k-means 主色调分析）。
  toneScanPython = pkgs.python3.withPackages (
    ps: with ps; [
      numpy
      pillow
    ]
  );

  # scan-tones 命令：对壁纸库做主色调分析，生成 ~/.config/wallpaper-tones.txt。
  scanTonesBin = pkgs.writeShellScriptBin "scan-tones" ''
    exec ${toneScanPython}/bin/python3 "${scriptsDir}/scan-tones.py" "${wallpaperDir}" "${wallpaperTonesFile}" "$@"
  '';

  # 必须是 writeShellScriptBin（产出带 /bin 的目录）：这脚本进 home.packages，
  # 而 home-manager-path 用 buildEnv 合并 sessionPath，file 类型的 store path
  # 会直接让 buildEnv 报 "is a file and cannot be added to a directory"。
  sessionEnv = pkgs.writeShellScriptBin "clavis-session-env" (builtins.readFile ./bin/clavis-session-env);

  # clavis-theme-sync：把 Clavis 的 theme.mode 同步给 dconf / GTK3 / GTK4 / Kvantum
  # （Clavis 只重画自己的模板，不管这些；见 bin/clavis-theme-sync 头部说明）。
  themeSync = pkgs.writeShellScript "clavis-theme-sync" ''
    # procps 提供脚本里给 kitty/其他客户端发信号用的 pkill。
    export PATH=${lib.makeBinPath [ pkgs.bash pkgs.coreutils pkgs.gnused pkgs.glib pkgs.jq pkgs.procps ]}
    exec ${pkgs.writeShellScript "clavis-theme-sync-script" (builtins.readFile ./bin/clavis-theme-sync)} "$@"
  '';

  # 「首次部署种子、之后永不覆盖」的可写文件。
  # 刻意不用 home.file：它只会把 /nix/store 里的只读文件软链过去，而 Clavis
  # 启动后要回写 config.json（设置中心的 source of truth），qt6ct 在 GUI 里保存
  # 设置也要写自己的 conf —— 指向 store 的软链两者都写不进去。
  seedFile =
    name: src:
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      target="''${HOME:-/home/mccarnon}/${name}"
      if [ ! -e "$target" ]; then
        install -Dm644 ${src} "$target"
        echo "clavis: seeded ${name}"
      fi
    '';

  # Clavis 面板/脚本运行时依赖的外部命令。
  # 前半段沿用 Noctalia 时代的工具清单（控制中心/锁屏/脚本要用的），后半段是
  # Clavis 额外需要的：matugen（按壁纸重生成主题）、录屏三件套、wlogout、
  # ddcutil、playerctl。
  # 不在这里重复的（别处已经有 / 系统级已有）：
  #   qs/ffmpeg/cliphist/wl-clipboard/slurp/gpu-screen-recorder —— pkgs/key-cli
  #     的 wrapper 已经把它们塞进 key 的 PATH，`key` 派生的进程一定找得到；
  #   grim / satty —— modules/home/apps/{media,gui}.nix；
  #   yazi / btop —— modules/home/apps/cli.nix（matugen 模板只写它们的配置文件）；
  #   pactl —— NixOS 系统级（modules/nixos/desktop/audio.nix）；
  #   rfkill —— util-linux 自带。
  clavisTools = with pkgs; [
    # ── 通用 / 脚本 ──
    bash
    coreutils
    gnugrep
    gnused
    gawk
    findutils
    procps
    util-linux
    imagemagick
    xdg-utils
    wget
    jq
    # ── 网络 / 硬件 / 电源 ──
    networkmanager # nmcli
    wireplumber # wpctl
    bluez # bluetoothctl
    power-profiles-daemon
    brightnessctl
    ddcutil # 外接显示器亮度
    pamixer
    playerctl # MPRIS 媒体键
    wtype # 锁屏密码输入
    # ── 剪贴板 ──
    cliphist
    wl-clipboard
    # ── 截图 / 录屏 / 音频录制（key doctor 会逐项检查）──
    gpu-screen-recorder
    slurp
    ffmpeg
    # ── 主题 / 外观 ──
    matugen
    glib.bin # gsettings/dconf
    libnotify
    qt6Packages.qt6ct
    qt6Packages.qtsvg # Qt SVG 图像插件（壁纸/图标里的 .svg）
    # ── Clavis 面板 ──
    wlogout # 注销对话框（Clavis 电源菜单）
    wlsunset # 夜灯/色温
    networkmanagerapplet # nm-applet 托盘（startup.kdl 里拉起）
    zsh # matugen zsh 模板的目标
  ];
in
{
  home.packages = with pkgs; [
    pkgs.clavisShell
    pkgs.keyCli # `key` 启动器 / IPC / 剪贴板 / 录屏
    pkgs.keytop # 独立系统监视 TUI
    gtk3 # NyxNiri 壁纸选择器
    gdk-pixbuf
    gtk-layer-shell
    (python3.withPackages (
      ps: with ps; [
        pygobject3 # gi.repository.Gtk / GdkPixbuf
        pycairo
      ]
    ))
    scanTonesBin # scan-tones —— 壁纸主色调分析 / 生成色调库
    sessionEnv # 启动包装：等 Wayland socket 再 exec
    (writeShellScriptBin "random-anime-wallpaper-clavis" (
      builtins.readFile ./bin/random-anime-wallpaper-clavis
    ))
  ];

  # 种子配置。刻意不加 force：Clavis 启动后会规范化并回写这个文件，用户之后
  # 在设置界面做的选择必须能活过下一次 home-manager switch，所以文件存在就跳过。
  home.activation.clavisSeedConfig = seedFile ".config/clavis/config.json" ./config.json;
  home.activation.clavisSeedUiPreferences = seedFile ".config/clavis/ui-preferences.json" ./ui-preferences.json;
  # qt6ct 设置种子（其他 Qt 桌面应用读这个；用 activation 种成可写副本，
  # 因为 qt6ct 在 GUI 里保存设置时要写同一个文件）。
  home.activation.clavisSeedQt6ct =
    seedFile ".config/qt6ct/qt6ct.conf" ../../../../home/files/qt6ct/qt6ct.conf;
  # kitty.conf include 这个文件；matugen 首次运行前先种一份静态兜底，
  # 否则新开的 kitty 会在 include 缺失时刷警告。
  home.activation.clavisSeedKittyTheme =
    seedFile ".config/kitty/themes/Matugen.conf" ../../../../home/files/kitty/Matugen.conf;

  # 默认壁纸（选择器/轮换脚本能直接看到）+ 用户头像。
  home.file."Pictures/Wallpapers/wallhaven-d88d53.png".source =
    ../../../../wallpapers/wallhaven-d88d53.png;
  home.file.".face".source = ../../../../wallpapers/wallhaven-d88d53.png;

  # NyxNiri 壁纸选择器（Mod+W 唤起，替代 shell 内置选择器）
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

  # Clavis 外壳服务。
  # 生命周期按 Clavis 上游的 config-isolation 文档挂在 niri.service 下
  # （本机 niri 确实由 niri.service 拉起：/proc/<niri>/cgroup 里能看到
  # session.slice/niri.service），于是 niri 起来 -> Clavis 起来，niri 停 ->
  # Clavis 跟着停，不会比合成器活得久。
  # - StartLimitIntervalSec = 0：默认的 10s/5 次会让崩溃循环的服务直接
  #   "start request repeated too quickly" 变成永久 failed —— 那正是黑屏且
  #   没人能自愈的形态。配合 Restart=always 让它一直重试。
  # - clavis-session-env 负责补齐 Wayland 环境（见模块头注释）。
  # - Install 只 enable，不用 --now：启动时机交给 niri.service。
  systemd.user.services.clavis-shell = {
    Unit = {
      Description = "Clavis Shell (niri desktop shell)";
      Documentation = [ "https://github.com/clavis-shell/clavis-shell" ];
      After = [ "niri.service" ];
      Wants = [ "niri.service" ];
      PartOf = [ "niri.service" ];
      Requisite = [ "niri.service" ];
      StartLimitIntervalSec = 0;
    };
    Service = {
      Type = "simple";
      ExecStart = "${sessionEnv}/bin/clavis-session-env ${pkgs.keyCli}/bin/key shell --foreground --no-duplicate";
      Restart = "always";
      RestartSec = 2;
      TimeoutStopSec = 10;
      # QML 崩溃时把日志留在 journal 里（默认就是 stderr，保留显式声明）。
      StandardOutput = "journal";
      StandardError = "journal";
    };
    Install = {
      WantedBy = [ "niri.service" ];
    };
  };

  # 剪贴板监听（Clavis 的剪贴板历史后端：cliphist + wl-copy/wl-paste）。
  systemd.user.services.clavis-clipboard = {
    Unit = {
      Description = "Clavis clipboard watcher";
      After = [ "niri.service" ];
      Wants = [ "niri.service" ];
      PartOf = [ "niri.service" ];
      Requisite = [ "niri.service" ];
      StartLimitIntervalSec = 0;
    };
    Service = {
      Type = "simple";
      ExecStart = "${sessionEnv}/bin/clavis-session-env ${pkgs.keyCli}/bin/key clipboard watch";
      Restart = "always";
      RestartSec = 2;
    };
    Install = {
      WantedBy = [ "niri.service" ];
    };
  };

  # Clavis 设置中心切深/浅色 -> 系统应用。两个入口：
  #   - Install.WantedBy=niri.service：每次登录跑一次；
  #   - systemd.user.paths：Clavis 改写 config.json 时再跑一次（脚本自身幂等，
  #     模式没变就直接退出，所以换壁纸这种无关写入不会反复戳 kitty）。
  systemd.user.services.clavis-theme-sync = {
    Unit = {
      Description = "Sync Clavis theme mode to dconf/GTK/Kvantum";
      After = [ "niri.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${themeSync}/bin/clavis-theme-sync";
    };
    Install = {
      WantedBy = [ "niri.service" ];
    };
  };
  systemd.user.paths.clavis-config = {
    Unit.Description = "Watch Clavis personalization config for theme changes";
    Path = {
      # Clavis 用原子写（临时文件 + rename），PathChanged 靠 inode/mtime 变化触发。
      PathChanged = "${home}/.config/clavis/config.json";
      Unit = "clavis-theme-sync.service";
    };
    Install = {
      # .path 单元不写 Install 就只是躺在磁盘上，永远不会生效。
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # 第二个触发点：Clavis 换壁纸时的顺序是「先写 config.json -> 再跑 matugen」，
  # 所以只盯 config.json 的话，同步脚本会在 matugen 产物落地之前就跑完，
  # 第一次运行只会记下签名却不重载 kitty。盯住 matugen 写的 kitty 主题，
  # 产物落地的瞬间再触发一次，kitty 才能立刻拿到新配色。
  systemd.user.paths.clavis-kitty-theme = {
    Unit.Description = "Watch the matugen kitty theme so running kitty reloads it";
    Path = {
      PathChanged = "${home}/.config/kitty/themes/Matugen.conf";
      Unit = "clavis-theme-sync.service";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # 每半小时自动轮换壁纸，复用 wallpaper_picker 的 backend（key ipc）应用逻辑。
  # 选图按时段色调偏好（每天 03:20 由 scan-tones 服务重扫色调库）。
  systemd.user.services.wallpapers-rotate = {
    Unit = {
      Description = "Clavis wallpaper rotation (tone-aware)";
      # 只排序不拉起：定时器在 niri 没跑的时候触发应该是 no-op，而不是反过来
      # 把 niri 启动起来。
      After = [
        "niri.service"
        "clavis-shell.service"
      ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.python3}/bin/python3 ${scriptsDir}/wallpapers-rotate.py";
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
          ++ [ pkgs.keyCli ]
        )
      }:${home}/.local/bin";
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
      Description = "Regenerate Clavis wallpaper tone library";
      After = [ "niri.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${scanTonesBin}/bin/scan-tones";
      # ffmpeg 用于提取动图/视频中间帧进行分析
      Environment = "PATH=${
        lib.makeBinPath (
          with pkgs; [
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

  # 把工具目录前置进 PATH，让 Clavis 派生的外部命令总能找到。
  # 同时保留用户 PATH（包含 ~/.local/bin）。
  home.sessionPath = [ "${home}/.local/bin" ] ++ map (pkg: "${pkg}/bin") clavisTools;

  # 输入法 / Qt 主题变量（沿用 Noctalia 时代的设置）。
  home.sessionVariables = {
    "QT_QPA_PLATFORM" = "wayland;xcb";
    "QT_QPA_PLATFORMTHEME" = "qt6ct";
    "QT_AUTO_SCREEN_SCALE_FACTOR" = "1";
    "XMODIFIERS" = "@im=fcitx";
    "GTK_IM_MODULE" = "fcitx";
    "QT_IM_MODULE" = "fcitx";
  };
}
