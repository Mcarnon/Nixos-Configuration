#!/bin/sh
# wallpaper-hook.sh — Noctalia wallpaper_changed hook
#
# Noctalia 的 mpvpaper 是官方插件，其 [[service]] 独自管理 mpvpaper 生命周期
# （开机从 assignments.json 恢复、通过 noctalia.setWallpaperEnabled 让视频表面
# 透出、用 IPC 切换/停止）。因此本 hook 只用插件原生 IPC，绝不自行 pkill /
# 启动裸 mpvpaper，否则会和插件抢进程导致壁纸不切换。
#
# 执行环境注意：Noctalia 直接 execve 本文件（无 shebang 时回退 /bin/sh）。
# 本机没有 /bin/bash，所以 shebang 必须是 /bin/sh，且全部用 POSIX 语法。
# daemon 环境 PATH 完整，但为稳妥仍加固 PATH。一切失败不得中断（无 set -e）。
set -u

# 加固 PATH（保留原有条目，追加常见 profile 目录）。
export PATH="${PATH:+$PATH:}${HOME:+$HOME/.nix-profile/bin:}/etc/profiles/per-user/${USER:-}/bin:/run/wrappers/bin:/run/current-system/sw/bin"

LOG_DIR="${XDG_STATE_HOME:-${HOME:-}/.local/state}/noctalia"
if [ -d "$LOG_DIR" ]; then :; else mkdir -p "$LOG_DIR" 2>/dev/null || true; fi
LOG_FILE="$LOG_DIR/hook.log"
printf '%s %s\n' "$(date +'%F %T')" "wallpaper_changed hook triggered." >> "$LOG_FILE" 2>/dev/null || true

# 解析 noctalia 可执行文件：先 PATH，再回退常见用户 profile 路径。
NOCTALIA="$(command -v noctalia 2>/dev/null || true)"
if [ -z "$NOCTALIA" ]; then
  for cand in "${HOME:+$HOME/.nix-profile/bin}/noctalia" "/etc/profiles/per-user/${USER:-}/bin/noctalia"; do
    if [ -n "$cand" ] && [ -x "$cand" ]; then
      NOCTALIA="$cand"
      break
    fi
  done
fi
if [ -z "$NOCTALIA" ]; then
  printf 'noctalia binary not found, skipping.\n' >> "$LOG_FILE" 2>/dev/null || true
  exit 0
fi

WP="$("$NOCTALIA" msg wallpaper-get 2>/dev/null || true)"
printf 'WP=%s\n' "$WP" >> "$LOG_FILE" 2>/dev/null || true

CACHE_DIR="${XDG_CACHE_HOME:-${HOME:-}/.cache}/noctalia/mpvpaper"
PLUGIN_STATE="${XDG_STATE_HOME:-${HOME:-}/.local/state}/noctalia/mpvpaper"

# 清理 picker（NyxNiri）直启的、不属于插件的 mpvpaper 实例。插件的实例一定带
# 有其 ipc 套接字路径（STATE_DIR/ipc-<connector>.sock），据此区分，绝不误杀
# 插件进程，避免回到"抢进程"的老问题。static 与 video 分支都会先做这一步。
for d in /proc/[0-9]*; do
  pid="${d#/proc/}"
  if [ -n "${pid:-}" ] && [ "$pid" != "$$" ]; then
    cmd="$(tr '\0' ' ' < "$d/cmdline" 2>/dev/null || true)"
    case "$cmd" in
      *mpvpaper*)
        case "$cmd" in
          *"$PLUGIN_STATE/ipc-"*)
            : ;;
          *)
            printf 'Killing non-plugin mpvpaper pid=%s\n' "$pid" >> "$LOG_FILE" 2>/dev/null || true
            kill "$pid" 2>/dev/null || true
            ;;
        esac
        ;;
    esac
  fi
done

# 1) 插件缓存目录里的静态帧/缩略图（mpvpaper 自己的取色流程产物）→ 跳过。
# 2) 视频/动图扩展名（含 gif）→ 写入插件 assignments 并重启插件服务，让插件
#    原生拉起 mpvpaper（全屏 "*"），避免与插件抢进程。
# 3) 其它 → 视作内置管理器选择的静态图片，通知插件停止所有视频壁纸。
case "$WP" in
  "$CACHE_DIR"/*)
    printf 'Plugin-generated frame detected, skipping.\n' >> "$LOG_FILE" 2>/dev/null || true
    exit 0
    ;;
  *.mp4|*.webm|*.mkv|*.mov|*.gif)
    printf 'Video path set, re-applying via mpvpaper plugin.\n' >> "$LOG_FILE" 2>/dev/null || true
    STATE_DIR="${XDG_STATE_HOME:-${HOME:-}/.local/state}/noctalia"
    MPVP_DIR="$STATE_DIR/mpvpaper"
    if [ -d "$MPVP_DIR" ]; then :; else mkdir -p "$MPVP_DIR" 2>/dev/null || true; fi
    escaped=$(printf '%s' "$WP" | sed 's/\\/\\\\/g; s/"/\\"/g')
    printf '{"assignments":{"*":"%s"},"launchedAsSystemd":{"*":false}}\n' "$escaped" > "$MPVP_DIR/assignments.json.tmp"
    mv -f "$MPVP_DIR/assignments.json.tmp" "$MPVP_DIR/assignments.json" 2>/dev/null || true
    printf 'assignments written: %s\n' "$WP" >> "$LOG_FILE" 2>/dev/null || true
    "$NOCTALIA" msg plugins disable noctalia/mpvpaper 2>/dev/null || true
    "$NOCTALIA" msg plugins enable noctalia/mpvpaper 2>/dev/null || true
    exit 0
    ;;
esac

printf 'Static wallpaper selected, clearing plugin video wallpapers.\n' >> "$LOG_FILE" 2>/dev/null || true
"$NOCTALIA" msg plugin noctalia/mpvpaper:service all clear-all 2>/dev/null || true