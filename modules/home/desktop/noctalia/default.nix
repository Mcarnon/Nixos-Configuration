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
  };

  # 把配置目录放进 store，其中 settings.json 是上面生成的版本。
  noctaliaConfig = pkgs.runCommand "noctalia-config" { } ''
    mkdir -p $out
    cp -r ${./config}/* $out/
    rm -f $out/settings-base.json
    cp ${pkgs.writeText "settings.json" (builtins.toJSON noctaliaSettings)} $out/settings.json
  '';

  # 等 niri 把 WAYLAND_DISPLAY 写进 systemd user 环境后，再把它读出来并启动 noctalia。
  noctaliaLaunch = pkgs.writeShellScriptBin "noctalia-launch" ''
    PATH="${lib.makeBinPath [ pkgs.systemd pkgs.coreutils pkgs.gnugrep ]}"
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
  home.sessionVariables = {
    "QT_QPA_PLATFORM" = "wayland;xcb";
    "QT_QPA_PLATFORMTHEME" = "qt6ct";
    "QT_AUTO_SCREEN_SCALE_FACTOR" = "1";
  };

  # 默认壁纸（noctalia 壁纸选择器能直接看到）。
  home.file."Pictures/Wallpapers/wallhaven-d88d53.png".source =
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
      Environment = [
        "QT_QPA_PLATFORM=wayland;xcb"
        "QT_QPA_PLATFORMTHEME=qt6ct"
        "QT_AUTO_SCREEN_SCALE_FACTOR=1"
        "XDG_CURRENT_DESKTOP=niri"
      ];
    };
    Install = {
      WantedBy = [ "niri.service" ];
    };
  };
}
