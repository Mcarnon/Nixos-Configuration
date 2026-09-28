# Clavis Shell — niri 的 Quickshell 桌面外壳。
#
# Clavis 由三个仓库组成，本配置把它们钉死成 flake input 后自己打包：
#   * inputs."clavis-shell"  → pkgs/clavis-shell：原生 Clavis.* QML 插件
#     + $out/etc/xdg/quickshell/clavis 下的 QML 树
#   * inputs."key-cli"       → pkgs.keyCli：`key` 命令。它同时是外壳的入口
#     （`key shell` = `qs -c clavis`）和 wrapper —— PATH / QML_IMPORT_PATH /
#     XDG_CONFIG_DIRS 都在包装里写死，见 pkgs/key-cli 的说明
#   * inputs.m3shapes       → 上游自带 nix 打包（Clavis 不提供 M3Shapes）
#
# 本模块负责「会话侧」的接线：
#   - 两个 systemd user unit（外壳 + 剪贴板 watcher），全部带本仓库的两处
#     加固：ExecStart 走 clavis-session-env 等 wayland socket、并且
#     StartLimitIntervalSec = 0（start-limit 打死后是永久黑屏）；
#   - Qt6/fcitx 环境变量（niri 的 environment {} 只覆盖 niri 拉起的进程，
#     systemd user 服务拿不到）；
#   - 少数「必须可写」的外壳生成物：qt6ct 配置、kitty 主题（Clavis 的
#     matugen post_hook 会覆写它，而 home.file 只会软链到只读 store）；
#   - 默认壁纸和 ~/.face（侧栏头像）。
#
# 【没有 enable 开关】：本仓库的桌面外壳模块一律是「被 import 就生效」的直接
# 配置模块（旧的 inir/default.nix 也是），谁 import 角色谁就得到这套接线。
# 换包就改 pkgs overlay（pkgs.keyCli），别在这里加一层 opt-in —— 上一次
# 留了 programs.clavis.enable 却没有人在任何地方置 true，整个外壳是死的。
# 剪贴板 watcher 想关掉就写 systemd.user.services.clavis-clipboard.Install.WantedBy = [];
#
# 刻意【不】管理的东西：
#   * ~/.config/clavis/**：外壳自己的设置（主题/壁纸目录/布局），首次启动
#     自己生成，之后由用户在设置界面改。声明式接管需要跟着 QML 的设置
#     schema 走，收益不抵成本。
#   * ~/.config/quickshell/clavis：千万不要创建。Quickshell 优先用它，存在
#     但内容不对时 `qs -c clavis` 会加载失败而不是回退 XDG 目录。store 里的
#     $out/etc/xdg/quickshell/clavis 由 XDG_CONFIG_DIRS 提供。
#   * ~/.config/niri/clavis/effects.kdl：Clavis 自己写（模糊/xray 开关），
#     home/niri/config.kdl 只做 `include optional=true`。
{
  config,
  pkgs,
  lib,
  ...
}:
let
  home = config.home.homeDirectory;

  # 必须是 writeShellScriptBin（产出带 /bin 的目录）：这脚本进 home.packages，
  # 而 home-manager-path 用 buildEnv 合并 sessionPath，file 类型的 store path
  # 会直接让 buildEnv 报 "is a file and cannot be added to a directory"。
  sessionEnv = pkgs.writeShellScriptBin "clavis-session-env" (builtins.readFile ./bin/clavis-session-env);

  # 「首次部署种子、之后永不覆盖」的可写文件。
  # 刻意不用 home.file：它只会把 /nix/store 里的只读文件软链过去，而这些文件
  # 都要被应用自己回写（qt6ct 的 GUI 保存、Clavis 的 matugen 配色生成）——
  # 指向 store 的软链两者都写不进去。
  seedFile =
    name: src:
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      target="''${HOME:-${home}}/${name}"
      if [ ! -e "$target" ]; then
        install -Dm644 ${src} "$target"
        echo "clavis: seeded ${name}"
      fi
    '';

  # systemd user 服务的环境。niri 的 `environment {}` 块只影响 niri 拉起的
  # 子进程，user manager 继承的是 ly/pam_systemd 那一套，所以 Qt 平台/主题、
  # fcitx 桥接、图标主题都要在这里重写一遍。
  unitEnvironment = [
    "XDG_CURRENT_DESKTOP=niri"
    "XDG_SESSION_TYPE=wayland"
    "QT_QPA_PLATFORM=wayland"
    # qt6ct：Clavis 是 Qt6 应用，不设就用 Qt 默认样式（和 foot/kitty 里
    # 声明的 qt6ct.conf 对不上）。~/.config/qt6ct/qt6ct.conf 由下面 seed。
    "QT_QPA_PLATFORMTHEME=qt6ct"
    "QT_QPA_PLATFORMTHEME_QT6=qt6ct"
    "QT_AUTO_SCREEN_SCALE_FACTOR=1"
    "QT_IM_MODULE=fcitx"
    "QT_IM_MODULES=wayland;fcitx"
    "XMODIFIERS=@im=fcitx"
    # Quickshell 找不到图标主题时 QIcon 返回空图（紫黑棋盘格）。
    "QS_ICON_THEME=Adwaita"
    # 上游 unit 的 jemalloc 参数。注释说得很清楚：必须赶在 qs 启动前设置，
    # QML 里的 Env pragma 是在分配器初始化之后才跑的。
    "MALLOC_CONF=thp:never,narenas:4,dirty_decay_ms:3000"
  ];

  # 外壳类 unit 的公共部分。session 生命周期归 niri：niri 停，外壳跟着停；
  # 没有合成器时也不必启动外壳。
  #
  # 【schema】本仓库锁定的 home-manager 用的是「systemd 指令」写法：
  #   systemd.user.services.<name> = { Unit = {...}; Service = {...}; Install = {...}; }
  # 旧的 description / serviceConfig / unitConfig 三段式已经没有了（写成那样
  # 报 "A definition for option ...description is not of type attribute set"）。
  mkUnit =
    description: execStart: {
      Unit = {
        Description = description;
        After = [ "niri.service" ];
        # 本仓库对「桌面壳服务」的固定要求：不给 systemd 的 start-limit
        # 打死的机会。unit 自己 Restart=on-failure，这条只是删掉
        # 「30s 内 5 次失败 → 永久不再启动」那个悬崖（那次之后就是黑屏）。
        PartOf = "niri.service";
        Requisite = "niri.service";
        StartLimitIntervalSec = 0;
      };
      Service = {
        Type = "simple";
        ExecStart = execStart;
        Environment = unitEnvironment;
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "niri.service" ];
    };
in
{
  # `key` 要在会话 PATH 里：niri 的 spawn 直连 PATH（不经过 shell），
  # binds.kdl 里的 `key ipc call ...` 靠的就是这个 ~/.local/bin/key。
  # wtype/qt6ct/qtsvg 以前靠旧桌面壳模块的 sessionPath 带进来。
  home.packages = with pkgs; [
    keyCli
    qt6Packages.qt6ct
    qt6Packages.qtsvg # Qt SVG 图像插件（壁纸/图标里的 .svg）
  ];

  # 外壳本体。上游把 unit 装进 $out/lib/systemd/user 并在安装器里
  # systemctl --user link；声明式配置直接写 unit，ExecStart 才有机会
  # 走 clavis-session-env。
  systemd.user.services.clavis-shell = mkUnit
    "Clavis Shell (Quickshell desktop shell for niri)"
    "${sessionEnv}/bin/clavis-session-env ${lib.getExe pkgs.keyCli} shell --foreground --no-duplicate";

  # 剪贴板历史是【独立的 watcher】：Clavis 重启/崩溃时历史要活下来，所以
  # 不能塞进外壳进程里。cliphist + wl-copy/wl-paste 在 key 的 wrapper
  # PATH 里。
  systemd.user.services.clavis-clipboard =
    (mkUnit
      "Clavis clipboard watcher"
      "${sessionEnv}/bin/clavis-session-env ${lib.getExe pkgs.keyCli} clipboard watch")
    // {
      Service.TimeoutStopSec = 5;
    };

  # 会话级 Qt/IM 变量（niri 拉起的进程由 home/niri/config.kdl 的
  # environment {} 覆盖，这里管的是 systemd user 服务和终端/手动启动的
  # Qt 应用）。
  home.sessionVariables = {
    "QT_QPA_PLATFORM" = "wayland;xcb";
    "QT_QPA_PLATFORMTHEME" = "qt6ct";
    "QT_AUTO_SCREEN_SCALE_FACTOR" = "1";
    "QS_ICON_THEME" = "Adwaita";
    "XMODIFIERS" = "@im=fcitx";
    "GTK_IM_MODULE" = "fcitx";
    "QT_IM_MODULE" = "fcitx";
  };

  # qt6ct 的 GUI 会回写这个文件（选字体/样式），qt6Packages.qt6ct 本身
  # 只读。
  home.activation.clavisSeedQt6ct = seedFile ".config/qt6ct/qt6ct.conf" ../../../../home/files/qt6ct/qt6ct.conf;
  # Clavis 的 matugen post_hook 生成 ~/.config/kitty/themes/Matugen.conf 后
  # `cp` 到 ~/.config/kitty/current-theme.conf（kitty.conf include 的就是
  # 这个路径）。必须可写，所以只能种一份可写副本。
  home.activation.clavisSeedKittyTheme = seedFile ".config/kitty/current-theme.conf" ../../../../home/files/kitty/current-theme.conf;

  # 默认壁纸 + 用户头像。
  home.file."Pictures/Wallpapers/wallhaven-d88d53.png".source =
    ../../../../wallpapers/wallhaven-d88d53.png;
  home.file.".face".source = ../../../../wallpapers/wallhaven-d88d53.png;
}
