# Noctalia Shell — SHORiN 配置完整迁移到 NixOS。
#
# 包含：
#   - pkgs.noctalia-shell / noctalia-qs（IPC）/ qt6ct
#   - 把 SHORiN 的 ~/.config/noctalia 完整复制进 home
#   - settings.json 由 Nix 生成，替换用户名/壁纸路径/字体/城市等
#   - systemd 用户服务，等 WAYLAND_DISPLAY 就绪后再启动
#   - 随机动漫壁纸脚本 ~/.local/bin/random-anime-wallpaper-noctalia
{
  config,
  pkgs,
  lib,
  ...
}:
let
  home = config.home.homeDirectory;
  wallpaperDir = "${home}/Pictures/Wallpapers";

  # 以 SHORiN 的 settings.json 为底，覆写必须跟本机一致的路径/字体/城市。
  baseSettings = builtins.fromJSON (builtins.readFile ./config/settings-base.json);
  # kitty 兜底主题（激活时复制，运行时会被 Noctalia 的 kitty 模板覆盖）。
  kittyNoctaliaConf = ../../../../home/files/kitty/current-theme.conf;
  # kitty/foot 基配置 + qt6ct 图标主题配置（激活时复制为可写副本；kitty.conf 与
  # foot.ini 会被 Noctalia 的 apply.sh 注入 include，qt6ct 保存设置时需要可写）。
  kittyBaseConf = ../../../../home/files/kitty.conf;
  footBaseConf = ../../../../home/files/foot.ini;
  qt6ctBaseConf = ../../../../home/files/qt6ct/qt6ct.conf;
  noctaliaSettings = lib.recursiveUpdate baseSettings {
    appLauncher.terminalCommand = "foot";
    ui = {
      fontDefault = "LXGW WenKai";
      fontFixed = "Maple Mono NF CN";
    };
    location = {
      name = "Shanghai";
      weatherEnabled = true;
    };
    general.avatarImage = "${home}/.face";
    # 默认开启完整外观与桌面组件，避免登录后只有灰屏。
    noctaliaPerformance = {
      disableWallpaper = false;
      disableDesktopWidgets = false;
    };
    controlCenter.cards = [
      { enabled = true; id = "profile-card"; }
      { enabled = true; id = "shortcuts-card"; }
      { enabled = true; id = "audio-card"; }
      { enabled = true; id = "brightness-card"; }
      { enabled = true; id = "weather-card"; }
      { enabled = true; id = "media-sysmon-card"; }
    ];
    desktopWidgets.enabled = true;
    wallpaper = {
      directory = wallpaperDir;
      monitorDirectories = [
        {
          name = "eDP-1";
          directory = wallpaperDir;
          wallpaper = "";
        }
      ];
    };
    colorSchemes.syncGsettings = true;
    # 启用 Noctalia 内置 foot 模板（输出 ~/.config/foot/themes/noctalia，
    # apply.sh 会往 ~/.config/foot/foot.ini 注入 include），让 foot 与 kitty
    # 一样跟随壁纸动态换色（Shorin 风格）。
    templates.activeTemplates =
      (baseSettings.templates.activeTemplates or [ ])
      ++ [ { enabled = true; id = "foot"; } ];
  };

  # 把配置目录放进 store，其中 settings.json 是上面生成的版本。
  noctaliaConfig = pkgs.runCommand "noctalia-config" { } ''
    mkdir -p $out
    cp -r ${./config}/* $out/
    rm -f $out/settings-base.json
    cp ${pkgs.writeText "settings.json" (builtins.toJSON noctaliaSettings)} $out/settings.json
  '';

  # Noctalia 组件依赖的运行时工具。注意：noctalia-launch 会把它前置到
  # 进程 PATH 最前面，因此这里必须列出 noctalia-shell 运行时所有可能调用
  # 的外部命令，包括原本由 noctalia-shell 的 Qt wrapper 注入 PATH 的
  # runtimeDeps。
  noctaliaTools = with pkgs; [
    systemd                 # systemctl --user
    bash                    # /bin/sh —— Noctalia 内部 QProcess 调用 "sh" 执行脚本
    coreutils               # seq/sleep/df/cat/...
    gnugrep                 # grep
    gnused                  # sed
    gawk                    # awk
    findutils               # find/xargs
    procps                  # ps/free/top —— SystemStat 等系统监控
    networkmanager          # nmcli —— Wi-Fi/以太网面板、连接管理
    wireplumber             # wpctl —— 音量/静音（AudioService 首选控制通道）
    wtype                   # 键盘模拟（锁屏密码框自动输入等）
    util-linux              # rfkill —— 飞行模式开关
    power-profiles-daemon   # powerprofilesctl —— 电源模式面板
    brightnessctl           # 亮度调节
    pamixer                 # 音量/静音（备用音频控制）
    playerctl               # 媒体控制
    cliphist                # 剪贴板历史
    wl-clipboard            # 剪贴板读写
    wlr-randr               # 显示器配置/查询
    bluez                   # bluetoothctl —— 蓝牙面板
    imagemagick             # 壁纸/缩略图处理
    xdg-utils               # xdg-open —— 状态栏点击打开应用/链接
    wlsunset                # 夜灯/色温
    ddcutil                 # 外接显示器 DDC 亮度
    wget                    # 壁纸下载等（noctalia-shell 的 runtimeDeps）
    python3                 # 日历/脚本等（noctalia-shell 的 runtimeDeps）
    matugen                 # 从壁纸生成配色/主题/图标颜色（Noctalia 核心）
    glib.bin                # gsettings/dconf/gio —— GTK 模板 apply.sh 与 recolor.sh 依赖
  ];

  # 等 niri 把 WAYLAND_DISPLAY 写进 systemd user 环境后，再把它读出来并启动 noctalia。
  noctaliaLaunch = pkgs.writeShellScriptBin "noctalia-launch" ''
    # 把 Noctalia 需要的工具前置到 PATH，同时保留原有 PATH（这样
    # noctalia-shell 的 Qt wrapper 后续追加自己的 runtimeDeps 时不会丢失它们）。
    PATH="${lib.makeBinPath noctaliaTools}:$PATH"
    for i in $(seq 1 60); do
      if systemctl --user show-environment 2>/dev/null | grep -q '^WAYLAND_DISPLAY='; then
        eval "$(${pkgs.systemd}/bin/systemctl --user show-environment 2>/dev/null | \
          ${pkgs.gnugrep}/bin/grep -E '^(WAYLAND_DISPLAY|XDG_CURRENT_DESKTOP|XDG_SESSION_TYPE|XDG_RUNTIME_DIR)=' | \
          ${pkgs.coreutils}/bin/sed 's/^/export /')"
        exec ${pkgs.noctalia-shell}/bin/noctalia-shell
      fi
      sleep 0.5
    done
    echo "noctalia-shell: WAYLAND_DISPLAY not found in systemd user environment" >&2
    exit 1
  '';
in
{
  home.packages = with pkgs; [
    noctalia-shell
    noctalia-qs # `qs -c noctalia-shell ipc call ...` 的 IPC 引擎
    qt6Packages.qt6ct
    libnotify # random-anime-wallpaper-noctalia 的 notify-send
    cava      # 对应 activeTemplates 里的 cava
    fuzzel    # 对应 activeTemplates 里的 fuzzel
    kitty     # 对应 activeTemplates 里的 kitty
    (writeShellScriptBin "random-anime-wallpaper-noctalia"
      (builtins.readFile ./bin/random-anime-wallpaper-noctalia)
    )
  ];

  # Qt6 图标/缩放主题；noctalia 本身用 Qt6 渲染。
  # 输入法变量同步写入 session，再通过 niri-session-wrapper 的
  # `systemctl --user import-environment` 导入 systemd 用户环境。
  home.sessionVariables = {
    "QT_QPA_PLATFORM" = "wayland;xcb";
    "QT_QPA_PLATFORMTHEME" = "qt6ct";
    "QT_AUTO_SCREEN_SCALE_FACTOR" = "1";
    "XMODIFIERS" = "@im=fcitx";
    "GTK_IM_MODULE" = "fcitx";
    "QT_IM_MODULE" = "fcitx";
  };

  # 默认壁纸（noctalia 壁纸选择器能直接看到）。
  home.file."Pictures/Wallpapers/wallhaven-d88d53.png".source =
    ../../../../wallpapers/wallhaven-d88d53.png;
  # 用户头像（控制中心 profile-card 需要；指向默认壁纸）。
  home.file.".face".source =
    ../../../../wallpapers/wallhaven-d88d53.png;
  # 把 store 里的 noctalia 配置复制到 ~/.config/noctalia（可写，比软链更适合
  # noctalia 运行时改 settings.json / colors.json / 模板输出）。
  # 每次 rebuild 会重置为基础配置，Noctalia 启动后再按壁纸重新生成衍生文件。
  home.activation.copyNoctaliaConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/.config
    # 如果旧配置是软链（例如 Clavis 时代留下的），先删掉，否则 cp 会写进 store。
    if [ -L ~/.config/noctalia ]; then
      rm -rf ~/.config/noctalia
    fi
    mkdir -p ~/.config/noctalia
    cp -r --no-preserve=mode,ownership ${noctaliaConfig}/. ~/.config/noctalia/
    # 确保 Noctalia 运行时可以改写 settings.json / colors.json / 模板输出。
    chmod -R u+w ~/.config/noctalia
    # 首次给 kitty 种子一个可写的 current-theme.conf（只读 store 软链会阻止
    # Noctalia 的 kitty 模板覆盖它，这里用备份复制解决）。
    mkdir -p ~/.config/kitty
    if [ ! -e ~/.config/kitty/current-theme.conf ]; then
      cp --no-preserve=mode,ownership ${kittyNoctaliaConf} ~/.config/kitty/current-theme.conf
    fi
    # kitty.conf：可写兜底（Noctalia 的 kitty 模板 apply.sh 要注入 include）；
    # 已存在（被 apply.sh 改过或用户改过）则不覆盖。
    if [ ! -e ~/.config/kitty/kitty.conf ]; then
      cp --no-preserve=mode,ownership ${kittyBaseConf} ~/.config/kitty/kitty.conf
    fi
    # foot.ini：可写兜底 + 幂等 include。每次 rebuild 无条件重建：include 置于
    # 首行使 foot 一定加载 Noctalia 配色（themes/noctalia 由 foot 模板 recolor 时
    # 刷新），并顺带修掉旧版 [color-dark] 错字。若要改 foot 配置，改基配置即可。
    mkdir -p ~/.config/foot
    {
      printf 'include=%s/.config/foot/themes/noctalia\n' "${home}"
      cat ${footBaseConf}
    } > ~/.config/foot/foot.ini
    chmod u+w ~/.config/foot/foot.ini
    # qt6ct 图标主题（Qt 应用紫黑棋盘格修复）；qt6ct 保存设置时需要可写。
    mkdir -p ~/.config/qt6ct
    if [ ! -e ~/.config/qt6ct/qt6ct.conf ]; then
      cp --no-preserve=mode,ownership ${qt6ctBaseConf} ~/.config/qt6ct/qt6ct.conf
    fi
  '';

  systemd.user.services.noctalia-shell = {
    Unit = {
      Description = "Noctalia Shell";
      Requisite = [ "niri.service" ];
      PartOf = [ "niri.service" ];
      After = [ "niri.service" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${noctaliaLaunch}/bin/noctalia-launch";
      Restart = "on-failure";
      RestartSec = 3;
      TimeoutStopSec = 10;
      # 输入法与 Qt 主题变量必须显式传入，否则 noctalia-shell 进程内无法切换
      # 输入法，GTK/Qt 应用也可能弹不出候选框。
      Environment = [
        "QT_QPA_PLATFORM=wayland;xcb"
        "QT_QPA_PLATFORMTHEME=qt6ct"
        "QT_AUTO_SCREEN_SCALE_FACTOR=1"
        "XDG_CURRENT_DESKTOP=niri"
        "XMODIFIERS=@im=fcitx"
        "GTK_IM_MODULE=fcitx"
        "QT_IM_MODULE=fcitx"
        "NOCTALIA_PAM_SERVICE=login"
      ];
    };
    Install = {
      WantedBy = [ "niri.service" ];
    };
  };
}
