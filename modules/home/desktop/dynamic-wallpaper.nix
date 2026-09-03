# Dynamic Wallpaper with mpvpaper + matugen theme sync
#
# Features:
#   - mpvpaper for video/gif wallpaper playback
<<<<<<< HEAD
#   - swaybg for static image wallpaper
=======
>>>>>>> 70cfd8ce67cee51cc752c7f7d1dc9387c313637c
#   - Wallpaper rotation timer (runs every 30 min)
#   - Time-aware selection: bright wallpapers for day (7:00-19:00), dark for night
#   - Only switches wallpaper when time period changes, not every 30 min
#   - Dominant color detection for accurate brightness classification
#   - matugen integration for theme sync on wallpaper change
#   - Replaces Noctalia wallpaper when enabled
{
  config,
  pkgs,
  lib,
  ...
}:
let
  home = config.home.homeDirectory;
  wallpaperDir = "${home}/Pictures/Wallpapers";
<<<<<<< HEAD
  videoDir = "${home}/Pictures/Wallpapers/video"; # 动态壁纸目录

  # 脚本自包含 PATH，避免依赖调用时的外部环境
  scriptPath = lib.makeBinPath [
    pkgs.coreutils
    pkgs.findutils
    pkgs.gnugrep
    pkgs.gnused
    pkgs.gawk
    pkgs.imagemagick
    pkgs.systemd
    pkgs.matugen
  ];
=======
  videoDir = "${home}/Pictures/Wallpapers/video";  # 动态壁纸目录
>>>>>>> 70cfd8ce67cee51cc752c7f7d1dc9387c313637c

  # 壁纸轮换脚本：基于时间选择壁纸，只在时间段变化时切换
  wallpaperRotationScript = pkgs.writeShellScriptBin "wallpaper-rotate" ''
    set -euo pipefail
<<<<<<< HEAD
    export PATH="${scriptPath}:$PATH"
=======
>>>>>>> 70cfd8ce67cee51cc752c7f7d1dc9387c313637c

    WALLPAPER_DIR="${wallpaperDir}"
    VIDEO_DIR="${videoDir}"
    CURRENT_FILE="$HOME/.current_wallpaper"
    STATE_FILE="$HOME/.wallpaper_time_mode"  # 记录上次选择的时间模式

    # ====== 时间判断 ======
    HOUR=$(date +%-H)
    DAY_START=7
    DAY_END=19

    if [ "$HOUR" -ge "$DAY_START" ] && [ "$HOUR" -lt "$DAY_END" ]; then
      TIME_MODE="day"
    else
      TIME_MODE="night"
    fi
    echo "Current time: $(date '+%H:%M'), mode: $TIME_MODE"

    # ====== 读取上次模式 ======
    LAST_MODE=""
    if [ -f "$STATE_FILE" ]; then
      LAST_MODE=$(cat "$STATE_FILE")
      echo "Last wallpaper mode: $LAST_MODE"
    fi

    # ====== 如果时间段没变，不换壁纸 ======
    if [ "$TIME_MODE" = "$LAST_MODE" ]; then
      echo "Time period unchanged ($TIME_MODE), skipping wallpaper change"
      CURRENT=$(cat "$CURRENT_FILE" 2>/dev/null || echo "")
      if [ -n "$CURRENT" ] && [ -f "$CURRENT" ]; then
        if [ -x "$HOME/.config/scripts/matugen-wallpaper.sh" ]; then
          "$HOME/.config/scripts/matugen-wallpaper.sh" "$CURRENT" &
        fi
      fi
      exit 0
    fi

    echo "Time period changed: $LAST_MODE → $TIME_MODE, selecting new wallpaper"

    # ====== 主色调亮度计算 ======
    # 使用 convert 缩小到 1x1 提取主色调（比平均亮度更准确）
    get_dominant_brightness() {
      local img="$1"
      # 缩小到 1x1 获取主色，输出 RGB 值
      local rgb
      rgb=$(convert "$img" -resize 1x1! -format "%[pixel:u]" info: 2>/dev/null)
      if [ -z "$rgb" ]; then
        echo "50"
        return
      fi

      # 解析 rgb(R,G,B) 格式
      local r g b
      r=$(echo "$rgb" | sed 's/rgb(\([0-9]*\),.*/\1/')
      g=$(echo "$rgb" | sed 's/rgb([0-9]*,\([0-9]*\),.*/\1/')
      b=$(echo "$rgb" | sed 's/rgb([0-9]*,[0-9]*,\([0-9]*\)).*/\1/')

      # 计算感知亮度 (ITU-R BT.709)
      # L = 0.2126*R + 0.7152*G + 0.0722*B (归一化到 0-255)
      local brightness
      brightness=$(awk "BEGIN { printf \"%.0f\", ($r * 0.2126 + $g * 0.7152 + $b * 0.0722) / 255 * 100 }")
      echo "$brightness"
    }

    # ====== 壁纸分类 ======
    STATIC=$(find "$WALLPAPER_DIR" -maxdepth 1 \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null || true)
    DYNAMIC=$(find "$VIDEO_DIR" -maxdepth 1 \( -iname "*.mp4" -o -iname "*.gif" -o -iname "*.webm" -o -iname "*.mkv" \) 2>/dev/null || true)

    ALL=$(echo -e "$STATIC\n$DYNAMIC" | grep -v '^$' || true)

    BRIGHT_WALLPAPERS=""
    DARK_WALLPAPERS=""

    for wp in $ALL; do
      filename=$(basename "$wp")

      # 检测命名后缀（优先级最高）
      case "$filename" in
        *_bright.*|*_day.*|*_light.*|*_bright_*.*|*_day_*.*|*_light_*.*)
          BRIGHT_WALLPAPERS="$BRIGHT_WALLPAPERS$wp"$'\n'
          echo "  $filename: classified by name (bright)"
          continue
          ;;
        *_dark.*|*_night.*|*_dark_*.*|*_night_*.*)
          DARK_WALLPAPERS="$DARK_WALLPAPERS$wp"$'\n'
          echo "  $filename: classified by name (dark)"
          continue
          ;;
      esac

      # 无后缀：提取主色调判断
      brightness=$(get_dominant_brightness "$wp")
      echo "  $filename: dominant brightness=$brightness%"

      if [ "$brightness" -ge 50 ]; then
        BRIGHT_WALLPAPERS="$BRIGHT_WALLPAPERS$wp"$'\n'
      else
        DARK_WALLPAPERS="$DARK_WALLPAPERS$wp"$'\n'
      fi
    done

    # ====== 根据时间选择池 ======
    if [ "$TIME_MODE" = "day" ]; then
      POOL="$BRIGHT_WALLPAPERS"
      [ -z "$POOL" ] && POOL="$DARK_WALLPAPERS"
    else
      POOL="$DARK_WALLPAPERS"
      [ -z "$POOL" ] && POOL="$BRIGHT_WALLPAPERS"
    fi

    if [ -z "$POOL" ]; then
      echo "No wallpapers found" >&2
      exit 1
    fi

    # 排除当前壁纸，确保随机性
    CURRENT_WP=""
    if [ -f "$CURRENT_FILE" ]; then
      CURRENT_WP=$(cat "$CURRENT_FILE")
    fi

    if [ -n "$CURRENT_WP" ]; then
      POOL=$(echo "$POOL" | grep -v "^$CURRENT_WP$" || echo "$POOL")
    fi

    # 如果排除后池空了（只剩一张壁纸），用原池
    if [ -z "$POOL" ]; then
      POOL=$(echo -e "$BRIGHT_WALLPAPERS$DARK_WALLPAPERS" | grep -v '^$')
    fi

    SELECTED=$(echo "$POOL" | grep -v '^$' | shuf -n 1)

    if [ -z "$SELECTED" ]; then
      echo "Failed to select wallpaper" >&2
      exit 1
    fi

    echo "Setting wallpaper: $SELECTED"

    # 写入当前壁纸路径
    echo "$SELECTED" > "$CURRENT_FILE"
    echo "$TIME_MODE" > "$STATE_FILE"

<<<<<<< HEAD
    # 重启壁纸服务（mpvpaper/swaybg 二合一）
=======
    # 重启 mpvpaper
>>>>>>> 70cfd8ce67cee51cc752c7f7d1dc9387c313637c
    systemctl --user restart mpvpaper.service || true

    # 触发 matugen
    if [ -x "$HOME/.config/scripts/matugen-wallpaper.sh" ]; then
      "$HOME/.config/scripts/matugen-wallpaper.sh" "$SELECTED" &
    fi

    echo "Wallpaper set to: $SELECTED"
  '';

  # matugen 壁纸同步脚本
  matugenWallpaperHook = pkgs.writeShellScriptBin "matugen-wallpaper" ''
    set -euo pipefail

    WALLPAPER="$1"

    if [ ! -f "$WALLPAPER" ]; then
      echo "Wallpaper not found: $WALLPAPER" >&2
      exit 1
    fi

    echo "Generating theme from: $WALLPAPER"

    if ${pkgs.matugen}/bin/matugen -m dark -i "$WALLPAPER"; then
      echo "Theme generated successfully"
    else
      echo "matugen failed, skipping" >&2
    fi

    if command -v qs &>/dev/null; then
      qs -c noctalia-shell ipc call colorScheme generate 2>/dev/null || true
    fi

    echo "Theme updated from: $WALLPAPER"
  '';

<<<<<<< HEAD
  # 壁纸服务执行脚本：视频走 mpvpaper，静态图走 swaybg
  wallpaperServiceScript = pkgs.writeShellScriptBin "wallpaper-service" ''
    set -euo pipefail
    export PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.systemd pkgs.mpvpaper pkgs.swaybg ]}:$PATH"
    export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    export HOME="${home}"

    # 从 systemd 用户环境获取 WAYLAND_DISPLAY
    for i in $(seq 1 30); do
      if systemctl --user show-environment 2>/dev/null | grep -q '^WAYLAND_DISPLAY='; then
        eval "$(systemctl --user show-environment 2>/dev/null | grep -E '^(WAYLAND_DISPLAY|XDG_CURRENT_DESKTOP)=' | sed 's/^/export /')"
        break
      fi
      sleep 0.5
    done

    # 兜底
    WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-wayland-0}"

    for i in $(seq 1 30); do
      if [ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]; then
        break
      fi
      sleep 0.5
    done

    CURRENT_WALLPAPER_FILE="$HOME/.current_wallpaper"
    if [ -f "$CURRENT_WALLPAPER_FILE" ]; then
      CURRENT=$(cat "$CURRENT_WALLPAPER_FILE")
    else
      CURRENT="${wallpaperDir}/wallhaven-d88d53.png"
    fi

    # 确保文件存在
    if [ ! -f "$CURRENT" ]; then
      echo "Wallpaper file not found: $CURRENT" >&2
      CURRENT="${wallpaperDir}/wallhaven-d88d53.png"
    fi

    case "$CURRENT" in
      *.mp4|*.gif|*.webm|*.mkv)
        echo "Starting mpvpaper for video: $CURRENT"
        exec mpvpaper -o "--no-audio --loop-file=inf --profile=wallpaper" ALL "$CURRENT"
        ;;
      *)
        echo "Starting swaybg for static image: $CURRENT"
        exec swaybg -m fill -i "$CURRENT"
        ;;
    esac
  '';
in
{
  home.packages = [
    wallpaperRotationScript
    matugenWallpaperHook
  ];

=======
in
{
>>>>>>> 70cfd8ce67cee51cc752c7f7d1dc9387c313637c
  home.file.".config/mpv/wallpaper.conf".source = ../../../home/files/mpv-wallpaper.conf;

  home.activation.setupDynamicWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ~/.config/scripts
    mkdir -p "${videoDir}"

    # 删除旧文件（确保更新）
    rm -f ~/.config/scripts/matugen-wallpaper.sh
    rm -f ~/.local/bin/wp
    rm -f ~/.local/bin/wallpaper-rotate

    cp ${matugenWallpaperHook}/bin/matugen-wallpaper ~/.config/scripts/matugen-wallpaper.sh
    chmod +x ~/.config/scripts/matugen-wallpaper.sh

<<<<<<< HEAD
=======
    cp ${wallpaperRotationScript}/bin/wallpaper-rotate ~/.local/bin/wallpaper-rotate

>>>>>>> 70cfd8ce67cee51cc752c7f7d1dc9387c313637c
    if [ ! -f "$HOME/.current_wallpaper" ]; then
      echo "${wallpaperDir}/wallhaven-d88d53.png" > "$HOME/.current_wallpaper"
    fi
  '';

  systemd.user.services = {
    mpvpaper = {
      Unit = {
<<<<<<< HEAD
        Description = "Dynamic wallpaper (mpvpaper / swaybg)";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${wallpaperServiceScript}/bin/wallpaper-service";
=======
        Description = "mpvpaper dynamic wallpaper";
        Requisite = [ "niri.service" ];
        PartOf = [ "niri.service" ];
        After = [ "niri.service" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.writeShellScriptBin "mpvpaper-service" ''
          export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
          export HOME="${home}"

          # 从 systemd 用户环境获取 WAYLAND_DISPLAY
          for i in $(seq 1 30); do
            if systemctl --user show-environment 2>/dev/null | grep -q '^WAYLAND_DISPLAY='; then
              eval "$(systemctl --user show-environment 2>/dev/null | grep -E '^(WAYLAND_DISPLAY|XDG_CURRENT_DESKTOP)=' | sed 's/^/export /')"
              break
            fi
            sleep 0.5
          done

          # 兜底
          WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-wayland-0}"

          for i in $(seq 1 30); do
            if [ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]; then
              break
            fi
            sleep 0.5
          done

          CURRENT_WALLPAPER_FILE="$HOME/.current_wallpaper"
          if [ -f "$CURRENT_WALLPAPER_FILE" ]; then
            CURRENT=$(cat "$CURRENT_WALLPAPER_FILE")
          else
            CURRENT="${wallpaperDir}/wallhaven-d88d53.png"
          fi

          case "$CURRENT" in
            *.mp4|*.gif|*.webm|*.mkv)
              exec ${pkgs.mpvpaper}/bin/mpvpaper -o "no-audio loop" "$WAYLAND_DISPLAY" "$CURRENT"
              ;;
            *)
              echo "Static wallpaper detected, exiting mpvpaper"
              exec sleep infinity
              ;;
          esac
        ''}/bin/mpvpaper-service";
>>>>>>> 70cfd8ce67cee51cc752c7f7d1dc9387c313637c
        Restart = "always";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
      Install = {
<<<<<<< HEAD
        WantedBy = [ "graphical-session.target" ];
      };
    };

    # 壁纸轮换服务（由 timer 触发）
    "wallpaper-rotate" = {
      Unit = {
=======
        WantedBy = [ "niri.service" ];
      };
    };

    "wallpaper-rotate" = {
      Unit = {
        Description = "Wallpaper rotation timer (check every 30 min)";
      };
      Timer = {
        OnActiveSec = 60;
        OnUnitActiveSec = 1800;
        Persistent = true;
      };
      Install = {
        WantedBy = [ "niri.service" ];
      };
    };

    "wallpaper-rotate-service" = {
      Unit = {
>>>>>>> 70cfd8ce67cee51cc752c7f7d1dc9387c313637c
        Description = "Rotate wallpaper based on time of day";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${wallpaperRotationScript}/bin/wallpaper-rotate";
      };
    };
  };
<<<<<<< HEAD

  systemd.user.timers = {
    "wallpaper-rotate" = {
      Unit = {
        Description = "Trigger wallpaper rotation every 30 min";
      };
      Timer = {
        OnActiveSec = 60;
        OnUnitActiveSec = 1800;
        Persistent = true;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
=======
>>>>>>> 70cfd8ce67cee51cc752c7f7d1dc9387c313637c
}
