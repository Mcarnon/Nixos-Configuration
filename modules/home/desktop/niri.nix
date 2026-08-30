# Link niri's KDL config to ~/.config/niri + desktop helper scripts.
# Config layout follows SHORiN's minimal-niri: config/binds/rule/layout
# (+ machine-specific niri-hardware.kdl from the host) + hyprlock + scripts.
# Scripts that need Nix store paths (sound files) are wrapped as real packages;
# pure scripts are deployed as executable dotfiles under ~/.config/niri/scripts.
{
  config,
  pkgs,
  lib,
  hostPath,
  ...
}:
let
  # Screenshot shutter sound daemon: binds send SIGUSR1 to "arm" it, then it
  # plays a click when a screenshot lands in the clipboard (wl-paste watch).
  screenshotSound = pkgs.writeShellScriptBin "screenshot-sound" ''
    SOUND="${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/camera-shutter.oga"
    TRIGGER_FILE="/dev/shm/niri_screenshot_armed"
    TIMEOUT_SEC=15

    if ! command -v pw-play >/dev/null; then
        notify-send "错误: 未找到 pw-play"
        exit 1
    fi

    arm_trigger() {
        touch "$TRIGGER_FILE"
    }
    trap arm_trigger SIGUSR1

    wl-paste --watch bash -c "
        if wl-paste --list-types 2>/dev/null | grep -q 'image/'; then
            if [ -f \"$TRIGGER_FILE\" ]; then
                NOW=\$(date +%s)
                FILE_TIME=\$(stat -c %Y \"$TRIGGER_FILE\")
                DIFF=\$((NOW - FILE_TIME))
                if [ \$DIFF -lt $TIMEOUT_SEC ]; then
                    pw-play \"$SOUND\" &
                    rm -f \"$TRIGGER_FILE\"
                fi
            fi
        fi
    " &
    WATCHER_PID=$!

    trap "kill $WATCHER_PID; exit" INT TERM EXIT
    while true; do
        sleep infinity & wait $!
    done
  '';

  # Force-kill a window by clicking it (SIGKILL, optionally the whole tree).
  # Same logic as shorin-arch-setup's niri-force-kill-window, with the freedesktop
  # sound path pointed at the nix store.
  forceKillWindow = pkgs.writeShellScriptBin "niri-force-kill-window" ''
    KILL_FAMILY=false
    SHOW_HELP=false
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -f|--family) KILL_FAMILY=true ;;
            -h|--help) SHOW_HELP=true ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
        shift
    done

    if [[ "${LANG}" == zh_* ]]; then
        STR_HELP="用法: niri-force-kill-window [选项]

通过鼠标点击，使用 SIGKILL 强制结束无响应的窗口。
自动兼容 Wayland 原生应用与 XWayland 代理应用。

选项:
  -f, --family   结束该窗口及其关联的整个进程树
  -h, --help     显示此帮助信息并退出"
        STR_ERR_DEP_TITLE="依赖缺失"
        STR_ERR_DEP_MSG="缺少必需命令: %s"
        STR_ERR_INFO_TITLE="获取信息失败"
        STR_ERR_INFO_MSG="无法获取窗口或进程信息。"
        STR_ERR_KILL_TITLE="结束失败"
        STR_ERR_KILL_MSG="无法提取目标真实 PID。"
        STR_SUCC_TITLE="强制结束 (%s)"
        STR_SUCC_MSG_SINGLE="应用: %s\n已终止目标窗口进程 (PID: %s)。"
        STR_SUCC_MSG_FAMILY="应用: %s\n进程树已清理: 成功终止 %s 个相关进程。"
        STR_UNKNOWN_APP="未知应用"
    else
        STR_HELP="Usage: niri-force-kill-window [OPTIONS]

Force kill (SIGKILL) an unresponsive window via mouse click.

Options:
  -f, --family   Kill the entire process tree associated with the window
  -h, --help     Show this help message and exit"
        STR_ERR_DEP_TITLE="Missing Dependency"
        STR_ERR_DEP_MSG="Command not found: %s"
        STR_ERR_INFO_TITLE="Info Error"
        STR_ERR_INFO_MSG="Could not determine window or process information."
        STR_ERR_KILL_TITLE="Kill Failed"
        STR_ERR_KILL_MSG="Could not extract target real PID."
        STR_SUCC_TITLE="Force Killed (%s)"
        STR_SUCC_MSG_SINGLE="App: %s\nTarget window process (PID: %s) terminated."
        STR_SUCC_MSG_FAMILY="App: %s\nProcess tree cleaned: %s processes terminated."
        STR_UNKNOWN_APP="Unknown App"
    fi

    if [[ "$SHOW_HELP" == true ]]; then
        echo -e "$STR_HELP"
        exit 0
    fi

    check_dependency() {
        local cmd="$1"
        if ! command -v "$cmd" &> /dev/null; then
            printf "$STR_ERR_DEP_MSG" "$cmd" >&2
            exit 1
        fi
    }
    check_dependency "niri"
    check_dependency "notify-send"
    check_dependency "xprop"

    notify_and_play() {
        local title="$1" msg="$2"
        notify-send "$title" "$msg" -a "Window Killer" -i application-exit
        if command -v pw-play &> /dev/null; then
            pw-play "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/dialog-error.oga" >/dev/null 2>&1 &
        fi
    }

    if ! output=$(niri msg pick-window 2>/dev/null); then exit 0; fi
    if [[ -z "$output" ]]; then exit 0; fi

    pid=$(grep -oP 'PID:\s*\K\d+' <<< "$output")
    app_id=$(grep -oP 'App ID:\s*"\K[^"]+' <<< "$output")
    app_name="${app_id:-$STR_UNKNOWN_APP}"

    if [[ -z "$pid" ]]; then exit 0; fi
    if [[ ! -f "/proc/$pid/comm" ]]; then
        notify-send "$STR_ERR_INFO_TITLE" "$STR_ERR_INFO_MSG" -a "Window Killer" -i dialog-error
        exit 1
    fi

    process_name=$(<"/proc/$pid/comm")
    process_name_lower="${process_name,,}"

    if [[ "$process_name_lower" == *"xwayland"* ]]; then
        proto_str="XWayland"
        sleep 0.05
        active_wid=$(xprop -root -notype _NET_ACTIVE_WINDOW 2>/dev/null | grep -o '0x[0-9a-fA-F]\+')
        real_pid=$(xprop -id "$active_wid" -notype _NET_WM_PID 2>/dev/null | grep -oP '\d+')
    else
        proto_str="Wayland"
        real_pid="$pid"
    fi

    if [[ -z "$real_pid" ]]; then
        notify-send "$STR_ERR_KILL_TITLE" "$STR_ERR_KILL_MSG" -a "Window Killer" -i dialog-error
        exit 1
    fi

    if [[ "$KILL_FAMILY" == true ]]; then
        app_root=$real_pid
        current=$real_pid
        while true; do
            stat_file="/proc/$current/stat"
            if [[ ! -r "$stat_file" ]]; then break; fi
            stat_content=$(<"$stat_file")
            pname="${stat_content#*(}"
            pname="${pname%)*}"
            rest="${stat_content##*) }"
            read -r _ ppid _ <<< "$rest"
            if [[ -z "$ppid" || "$ppid" == "1" || "$ppid" == "0" ]]; then break; fi
            if [[ "$pname" =~ ^(systemd|niri|bash|zsh|fish|tmux|screen|xwayland.*|sshd|login|init|sway|hyprland)$ ]]; then
                break
            fi
            app_root=$ppid
            current=$ppid
        done
        get_descendants() {
            local p=$1
            echo "$p"
            for c in $(pgrep -P "$p" 2>/dev/null); do
                get_descendants "$c"
            done
        }
        family_pids=$(get_descendants "$app_root")
        pid_count=$(echo "$family_pids" | wc -w)
        kill -9 $family_pids 2>/dev/null
        printf -v final_title "$STR_SUCC_TITLE" "$proto_str"
        printf -v final_msg "$STR_SUCC_MSG_FAMILY" "$app_name" "$pid_count"
    else
        kill -9 "$real_pid" 2>/dev/null
        printf -v final_title "$STR_SUCC_TITLE" "$proto_str"
        printf -v final_msg "$STR_SUCC_MSG_SINGLE" "$app_name" "$real_pid"
    fi

    notify_and_play "$final_title" "$final_msg"
  '';
in
{
  home.packages = [
    pkgs.wlsunset # 护眼模式（toggle-wlsunset 脚本驱动）
    pkgs.libnotify # notify-send（脚本/waybar 通知依赖）
    pkgs.xorg.xhost # config.kdl 的 xhost +si:localuser:root
    pkgs.xorg.xprop # niri-force-kill-window 处理 XWayland 窗口
    pkgs.swayosd # 音量/亮度 OSD（binds.kdl 里 swayosd-client 的常驻服务）
    pkgs.sound-theme-freedesktop # 截图/杀窗口音效
    pkgs.psmisc # killall（binds 里隐藏 waybar / 壁纸脚本杀进程）
    screenshotSound
    forceKillWindow
  ];

  xdg.configFile = {
    "niri/config.kdl".source = ../../../home/niri/config.kdl;
    "niri/binds.kdl".source = ../../../home/niri/binds.kdl;
    "niri/rule.kdl".source = ../../../home/niri/rule.kdl;
    "niri/layout.kdl".source = ../../../home/niri/layout.kdl;
    "niri/niri-hardware.kdl".source = hostPath + "/niri-hardware.kdl";
    "niri/hyprlock.conf".source = ../../../home/niri/hyprlock.conf;
    "niri/hyprlock-colors.conf".source = ../../../home/niri/hyprlock-colors.conf;

    # Pure helper scripts (bind to ~/.config/niri/scripts/... as in Shorin's config)
    "niri/scripts/niri-binds" = {
      source = ../../../home/niri/scripts/niri-binds;
      mode = "0755";
    };
    "niri/scripts/niri-quick-switch-fuzzel.py" = {
      source = ../../../home/niri/scripts/niri-quick-switch-fuzzel.py;
      mode = "0755";
    };
    "niri/scripts/niri-pick" = {
      source = ../../../home/niri/scripts/niri-pick;
      mode = "0755";
    };
    "niri/scripts/toggle-wlsunset" = {
      source = ../../../home/niri/scripts/toggle-wlsunset;
      mode = "0755";
    };
  };
}
