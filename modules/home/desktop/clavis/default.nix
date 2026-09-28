# Clavis Shell — niri 的 Quickshell 桌面外壳（取代 Noctalia v5）。
#
# 本模块负责：
#   - 打包来源：pkgs.clavisShell（Clavis 本体）+ pkgs.keyCli（`key` 命令/IPC）
#     + pkgs.m3shapes（Clavis 依赖的 M3 形状 QML 模块），都在 pkgs/default.nix
#     里聚合。旧方案里的 pkgs.keytop 已随 Clavis 上游一起退役（Sysmon 面板
#     由 `key sysmon` 原生采样器 + Clavis.Sysmon 提供）。
#   - systemd 用户服务：clavis-shell（外壳）+ clavis-clipboard（剪贴板监听），
#     按上游 packaging/systemd/user/*.service 挂在 niri.service 下。
#   - 会话环境兜底：clavis-session-env 等待 Wayland socket 再启动，这是以前
#     "切到 Clavis 直接黑屏"的根因（systemd user 服务拿不到 niri 的
#     WAYLAND_DISPLAY）。home/niri/startup.kdl 里的 import-environment 是第一道，
#     这个 wrapper 是第二道。
#   - 种子配置：~/.config/clavis/config.json。非 force 部署，Clavis 首次启动
#     会自己规范化并回写，之后用户在设置界面里的改动都会被保留。
#   - niri 集成：~/.config/niri/clavis/{effects,cursor,layer-rules,binds,outputs,
#     minimize-animation}.kdl 由 Clavis 的 scripts/system/niri_config.py 生成，
#     主配置里的 include 全部带 optional=true，Clavis 尚未写出的片段不会让
#     niri 起不来（config.kdl 本身是指向 store 的只读软链，绝不能被追加）。
#   - 壁纸链路：NyxNiri 选择器 / 定时轮换 / scan-tones 色调库，全部改走
#     `key ipc call wallpaper set`（Clavis 写 config.json + 重生成 matugen 主题）。
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

  sessionEnv = pkgs.writeShellScript "clavis-session-env" (builtins.readFile ./bin/clavis-session-env);

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
  # 注意：Clavis 真正的运行时环境由 pkgs.keyCli 的 wrapper 决定（QML_IMPORT_PATH /
  # QT_PLUGIN_PATH / XDG_CONFIG_DIRS / PATH 都从那里注入，`key shell` exec qs 会
  # 继承），所以这里只补「不以 key 为入口」的东西：
  #   - 用户手动敲的命令（niri 键位里的 wallpaper-picker.py、scan-tones、主题同步）
  #   - 只在 HM 激活期/脚本里直接调用、没经过 key wrapper 的东西
  #   - 桌面集成：注销、托盘、字体
  # 已经由 key wrapper 提供的（不要重复）：
  #   qs/quickshell、matugen、cliphist、wl-clipboard、gpu-screen-recorder、slurp、
  #   ffmpeg/ffprobe、pactl、gio、fd、qalculate、jq、sed、grep、find、flock、pkill、
  #   python3、bash、xdg-open、systemctl/busctl、magick、awww、brightnessctl、
  #   ddcutil、hyprpicker、rclone
  # 别处已经有 / 系统级已有：
  #   grim / satty —— modules/home/apps/{media,gui}.nix
  #   yazi / btop / cava —— matugen 只写它们的配置文件（Clavis 自带模板）
  #   pactl / rfkill —— modules/nixos/desktop/audio.nix + util-linux
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
    python3 # wallpaper-picker.py / wallpapers-rotate.py / scan-tones.py
    imagemagick
    xdg-utils
    wget
    jq
    which
    # ── 网络 / 硬件 / 电源 ──
    networkmanager # nmcli
    wireplumber # wpctl
    bluez # bluetoothctl
    upower # Clavis 电源/电池（同时也是 D-Bus 侧 upower.service 的提供方）
    power-profiles-daemon
    brightnessctl
    ddcutil # 外接显示器亮度
    pamixer
    playerctl # MPRIS 媒体键
    # ── 剪贴板 ──
    cliphist
    wl-clipboard
    # ── 截图 / 录屏 / 音频录制（key doctor 会逐项检查；已在 wrapper 里，这里
    #   保证用户在交互式 shell 里也能直接敲）──
    gpu-screen-recorder
    slurp
    ffmpeg
    # ── 主题 / 外观 ──
    matugen
    glib.bin # gsettings/dconf
    libnotify
    # Material Symbols Rounded/Outlined：Clavis 的 Components/MaterialSymbol.qml
    # 按字体族名（Common/Fonts.qml 里写死 "Material Symbols Rounded"）取字形，
    # 缺字形整套图标会变成豆腐块。字体本体由 NixOS 侧 fonts.packages 里的
    # material-symbols 提供，列在这里只会往 PATH 里塞一个不存在的 bin/。
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
    # pkgs.clavisShell / pkgs.m3shapes 不在这里：它们没有 bin/，进不了 PATH，
    # 只通过 pkgs.keyCli 的 wrapper 以 QML_IMPORT_PATH 的形式被引用。
    pkgs.keyCli # `key` 启动器 / IPC / 剪贴板 / 录屏 / sysmon
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
  #
  # 只 seed config.json 一个文件：上游把旧的 ui-preferences.json 合并进了
  # config.json（docs/architecture/config-isolation.md 的迁移说明），
  # 现在再写一个 ui-preferences.json 只会变成没人读的僵尸配置。
  home.activation.clavisSeedConfig = seedFile ".config/clavis/config.json" ./config.json;
  # qt6ct 设置种子（其他 Qt 桌面应用读这个；用 activation 种成可写副本，
  # 因为 qt6ct 在 GUI 里保存设置时要写同一个文件）。
  home.activation.clavisSeedQt6ct =
    seedFile ".config/qt6ct/qt6ct.conf" ../../../../home/files/qt6ct/qt6ct.conf;
  # kitty 配色：Clavis 的 matugen 模板（matugen/config.toml [templates.kitty]）
  # 写 themes/Matugen.conf，然后 post_hook 再把它 cp 成 current-theme.conf，
  # 而 kitty.conf 里的 `include current-theme.conf` 读的正是后者。
  # 两个文件都必须是可写副本：一个是 matugen 的输出目标，另一个是 cp 的目标，
  # 指向 store 的话 matugen 的写入会失败、post_hook 静默跳过。
  # matugen 首次运行前先种一份静态兜底，否则新开的 kitty 会在 include 缺失时刷警告。
  home.activation.clavisSeedKittyMatugen =
    seedFile ".config/kitty/themes/Matugen.conf" ../../../../home/files/kitty/Matugen.conf;
  home.activation.clavisSeedKittyCurrent =
    seedFile ".config/kitty/current-theme.conf" ../../../../home/files/kitty/current-theme.conf;

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
      Documentation = [ "https://github.com/StatIndet/quickshell" ];
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
      # 上游 packaging/systemd/user/clavis-shell.service 的原样设置。
      # thp:never —— Clavis 每帧重建大量 QQuickItem，透明大页会持续被 khugepaged
      #   折叠/拆开，造成周期性卡顿。
      # narenas:4 / dirty_decay_ms:3000 —— Clavis 启动后长期驻留，进程 RSS 会
      #   高于 512MB（glibc 靠 mmap 扩容 arena，arena 一多 glibc malloc 的锁竞争
      #   就开始被感知）。限制 arena 数量并放慢脏页回收可以把空闲 RSS 压住。
      Environment = "MALLOC_CONF=thp:never,narenas:4,dirty_decay_ms:3000";
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
