# Clavis Shell — Quickshell desktop shell for niri（开箱即用：M3 主题 + 壁纸）。
#
# 三个关键点让"裸 clavis"变成"完整外观"：
#   1. matugen —— Clavis 的 M3 色板生成是运行时硬依赖（ThemeService 调
#      scripts/theme/generate_matugen_colors.sh，脚本第一件事就检查 matugen）
#   2. ~/.config/clavis/config.json —— PersonalizationConfig 的持久文件
#      （Paths.configHome = ~/.config/clavis，可被 CLAVIS_CONFIG_HOME 覆盖）。
#      预置默认壁纸 + dark + scheme-tonal-spot，clavis 一启动就带着完整
#      主题渲染；否则默认 wallpaperPath 为空，状态栏/锁屏都是"素颜"。
#   3. ExecStartPre 兜底 —— 首次启动若 colors.json 还没生成（理论上
#      WallpaperService 会在设置壁纸后自动调 ThemeService 生成，这里保底），
#      直接用默认壁纸跑一遍 matugen 生成脚本。
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # 壁纸（默认部署位置）
  wallpaperPath = "${config.home.homeDirectory}/Pictures/Wallpapers/wallhaven-d88d53.png";

  # 首次启动兜底：colors.json 不存在时用默认壁纸生成 M3 色板。
  # 生成后不再重复跑（幂等），用户之后换壁纸由 Clavis 自己重新生成。
  themeBootstrap = pkgs.writeShellScriptBin "clavis-theme-bootstrap" ''
    colors="$HOME/.local/share/clavis/profiles/default/generated/clavis/colors.json"
    if [ ! -f "$colors" ]; then
      bash "$HOME/.config/quickshell/clavis/scripts/theme/generate_matugen_colors.sh" \
        --image "$HOME/Pictures/Wallpapers/wallhaven-d88d53.png" \
        --mode dark --scheme scheme-tonal-spot >/dev/null 2>&1 || true
    fi
  '';
in
{
  home.packages = [
    pkgs.keyCli # `key` launcher / IPC / clipboard / recording
    pkgs.keytop # standalone system monitor TUI
    pkgs.awww # 壁纸引擎（Clavis 设置中心 / 壁纸随机都调它）
    pkgs.matugen # M3 色板生成（Clavis 主题的硬依赖，必须进 PATH）
  ];

  # 默认壁纸：部署到 ~/Pictures/Wallpapers/（Clavis 设置中心从这里选图）。
  home.file."Pictures/Wallpapers/wallhaven-d88d53.png".source =
    ../../../../wallpapers/wallhaven-d88d53.png;

  # PersonalizationConfig 持久文件（~/.config/clavis/config.json）。
  # force = true：声明式外观优先 —— rebuild 会重置为这里的内容；设置中心里
  # 的修改在下次 rebuild 前一直生效。
  home.file."config/clavis/config.json" = {
    text = builtins.toJSON {
      wallpaper = {
        folder = "${config.home.homeDirectory}/Pictures/Wallpapers";
        path = wallpaperPath;
        fillMode = "Fill";
        desktopBackend = "quickshell"; # clavis 自己渲染壁纸，不依赖 awww 常驻
        transition = {
          type = "fade";
          durationMs = 1000;
        };
        awww = {
          transitionType = "fade";
        };
        overview = {
          enabled = true;
          useDesktopWallpaper = true;
        };
        parallax = {
          followWorkspaces = true;
          preferredScale = 1.1;
        };
      };
      theme = {
        matugenScheme = "scheme-tonal-spot";
        matugenTemplates = {
          btop = true;
          cava = true;
          kitty = true;
          fcitx5 = true;
          zsh = true;
          keytop = true;
          niri = true;
          yazi = true;
        };
        mode = "dark";
        cursorSize = 24;
        cursorHideWhenTyping = false;
        cursorHideAfterInactiveMs = 0;
        powerMenuStyle = "grid";
      };
      effects = {
        shellBackgroundOpacity = 1;
        shellBlurEnabled = false;
        shellBlurXray = true;
      };
      keystone = {
        style = "bangs";
        position = "top";
        hideDate = false;
      };
      bar = {
        position = "top";
      };
      sidebar = {
        keepLoaded = true;
      };
    };
    force = true;
  };

  # Clavis QML 源码树（shell.qml/Common/Components/Modules/Services/Widgets/
  # assets/scripts/matugen）——由 clavisShell 包安装到
  # $out/etc/xdg/quickshell/clavis，这里逐文件软链进用户配置目录。
  # 原生 C++ 模块（Clavis.* / M3Shapes）仍在 clavisShell/lib/qt6/qml，
  # 由 key 的 wrapper 通过 QML_IMPORT_PATH 提供给 qs 引擎。
  xdg.configFile."quickshell/clavis".source =
    "${pkgs.clavisShell}/etc/xdg/quickshell/clavis";

  systemd.user.services.clavis-shell = {
    Unit = {
      Description = "Clavis Shell";
      Requisite = [ "niri.service" ];
      PartOf = [ "niri.service" ];
      After = [ "niri.service" ];
    };
    Service = {
      Type = "simple";
      ExecStartPre = "${themeBootstrap}/bin/clavis-theme-bootstrap";
      ExecStart = "${pkgs.keyCli}/bin/key shell --foreground --no-duplicate";
      Restart = "on-failure";
      RestartSec = 2;
      TimeoutStopSec = 10;
    };
    Install = {
      WantedBy = [ "niri.service" ];
    };
  };

  systemd.user.services.clavis-clipboard = {
    Unit = {
      Description = "Clavis clipboard watcher";
      Requisite = [ "niri.service" ];
      PartOf = [ "niri.service" ];
      After = [ "niri.service" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.keyCli}/bin/key clipboard watch";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install = {
      WantedBy = [ "niri.service" ];
    };
  };
}
