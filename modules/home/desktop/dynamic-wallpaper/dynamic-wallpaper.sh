#!/bin/bash
set -euo pipefail

# =============================================================================
# dynamic-wallpaper — 统一管理静态壁纸轮换 + mpvpaper 视频壁纸
#
# 用法:
#   dynamic-wallpaper set <path>       设置壁纸（自动识别图片/视频）
#   dynamic-wallpaper next             下一张壁纸
#   dynamic-wallpaper random           随机壁纸（图片）
#   dynamic-wallpaper toggle-auto      切换自动轮换开关
#   dynamic-wallpaper status           显示当前状态
#   dynamic-wallpaper list-video       列出可用视频壁纸
#   dynamic-wallpaper play-video <path> 播放视频壁纸
#   dynamic-wallpaper stop-video       停止视频壁纸（回到静态）
#
# 依赖: noctalia (IPC), ffmpeg, mpvpaper
# =============================================================================

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
VIDEO_DIR="${WALLPAPER_DIR}/video"
STATE_DIR="${XDG_DATA_HOME:-$HOME/.local/state}/dynamic-wallpaper"
ASSIGNMENTS_FILE="${STATE_DIR}/assignments.json"

# 视频文件扩展名
VIDEO_EXTS="mp4|webm|mkv|mov|avi|gif|apng"

# ===================== 工具函数 =====================

is_video() {
    local file="$1"
    local ext="${file##*.}"
    ext="${ext,,}"  # 转小写
    [[ "$ext" =~ ^($VIDEO_EXTS)$ ]]
}

ensure_dirs() {
    mkdir -p "$STATE_DIR" "$VIDEO_DIR"
}

# 获取当前壁纸（读取 Noctalia 配置）
get_current_wallpaper() {
    noctalia msg wallpaper-get 2>/dev/null || echo ""
}

# 检查 mpvpaper 是否在运行
is_video_playing() {
    pgrep -x mpvpaper > /dev/null 2>&1
}

# 停止 mpvpaper
stop_mpvpaper() {
    if is_video_playing; then
        pkill -x mpvpaper 2>/dev/null || true
        sleep 0.3
        # 清理 assignments
        echo '{"static":null,"dynamic":null}' > "$ASSIGNMENTS_FILE" 2>/dev/null || true
        # 通知 Noctalia 清理插件状态
        noctalia msg plugin clear-all 2>/dev/null || true
    fi
}

# 设置静态壁纸
set_static_wallpaper() {
    local path="$1"
    if [ ! -f "$path" ]; then
        echo "Error: file not found: $path" >&2
        exit 1
    fi
    stop_mpvpaper
    noctalia msg wallpaper-set "$path"
}

# 播放视频壁纸
play_video_wallpaper() {
    local path="$1"
    if [ ! -f "$path" ]; then
        echo "Error: file not found: $path" >&2
        exit 1
    fi
    if ! is_video "$path"; then
        echo "Error: not a video file: $path" >&2
        exit 1
    fi

    stop_mpvpaper

    # 提取第一帧缩略图给 Noctalia 做 Material You 配色
    local thumb_dir="$HOME/.cache/noctalia/mpvpaper"
    mkdir -p "$thumb_dir"
    local thumb_path="${thumb_dir}/current-thumb.jpg"

    if ! ffmpeg -y -ss 00:00:01 -i "$path" -vframes 1 -q:v 2 "$thumb_path" 2>/dev/null; then
        echo "Warning: ffmpeg thumbnail extraction failed" >&2
    else
        # 设置缩略图为 Noctalia 壁纸（触发配色）
        noctalia msg wallpaper-set "$thumb_path"
    fi

    # 写入 assignments.json
    cat > "$ASSIGNMENTS_FILE" <<EOF
{"static":null,"dynamic":"$(realpath "$path")"}
EOF

    # 启动 mpvpaper（后台，循环，无音频，自适应画面）
    mpvpaper \
        --auto-pause \
        -o "config=yes loop-file=inf panscan=1.0 no-audio hwdec=auto script=~/.config/noctalia/mpv-hook.lua" \
        "*" \
        "$(realpath "$path")" &

    echo "Video wallpaper playing: $path"
}

# ===================== 子命令 =====================

cmd_set() {
    local path="$1"
    if is_video "$path"; then
        play_video_wallpaper "$path"
    else
        set_static_wallpaper "$path"
    fi
}

cmd_next() {
    # 如果正在播放视频，先停止
    if is_video_playing; then
        stop_mpvpaper
    fi
    noctalia msg wallpaper-next
}

cmd_random() {
    # 如果正在播放视频，先停止
    if is_video_playing; then
        stop_mpvpaper
    fi
    noctalia msg wallpaper-random
}

cmd_toggle_auto() {
    # 读取当前 automation.enabled 状态并切换
    # 通过 noctalia msg 获取当前配置状态（简化实现：直接调 noctalia msg wallpaper-random 并通知）
    local config_file="$HOME/.config/noctalia/noctalia-config.toml"
    if [ -f "$config_file" ]; then
        local current
        current=$(grep -A1 '\[wallpaper\.automation\]' "$config_file" | grep 'enabled' | head -1)
        if echo "$current" | grep -q 'true'; then
            # 切换为 false
            sed -i '/\[wallpaper\.automation\]/,/\[/{s/enabled *= *true/enabled = false/}' "$config_file"
            noctalia msg config-reload 2>/dev/null || true
            echo "Auto rotation: OFF"
        else
            # 切换为 true
            sed -i '/\[wallpaper\.automation\]/,/\[/{s/enabled *= *false/enabled = true/}' "$config_file"
            noctalia msg config-reload 2>/dev/null || true
            echo "Auto rotation: ON"
        fi
    else
        echo "Error: noctalia config not found" >&2
        exit 1
    fi
}

cmd_status() {
    echo "=== Dynamic Wallpaper Status ==="
    echo ""

    # 自动轮换状态
    local config_file="$HOME/.config/noctalia/noctalia-config.toml"
    if [ -f "$config_file" ]; then
        local auto_status
        auto_status=$(grep -A1 '\[wallpaper\.automation\]' "$config_file" | grep 'enabled' | head -1 | sed 's/.*= *//')
        echo "Auto rotation: ${auto_status:-unknown}"
    fi

    # 视频壁纸状态
    if is_video_playing; then
        echo "Video wallpaper: PLAYING"
        local video_path
        video_path=$(pgrep -a mpvpaper | grep -oP '(?<= )\S+\.(mp4|webm|mkv|mov)$' || echo "unknown")
        echo "Video path: $video_path"
    else
        echo "Video wallpaper: none"
    fi

    # 当前壁纸
    local current
    current=$(get_current_wallpaper)
    if [ -n "$current" ]; then
        echo "Current wallpaper: $current"
    fi

    echo ""
    echo "Wallpaper dir: $WALLPAPER_DIR"
    echo "Video dir:     $VIDEO_DIR"

    # 统计
    local static_count video_count
    static_count=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null | wc -l)
    video_count=$(find "$VIDEO_DIR" -maxdepth 1 -type f \( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \) 2>/dev/null | wc -l)
    echo "Static wallpapers: $static_count"
    echo "Video wallpapers:  $video_count"
}

cmd_list_video() {
    ensure_dirs
    echo "=== Video Wallpapers ==="
    echo "Directory: $VIDEO_DIR"
    echo ""

    if [ ! -d "$VIDEO_DIR" ]; then
        echo "No video directory found."
        return
    fi

    local count=0
    while IFS= read -r -d '' file; do
        echo "  $(basename "$file")"
        count=$((count + 1))
    done < <(find "$VIDEO_DIR" -maxdepth 1 -type f \( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \) -print0 2>/dev/null)

    if [ "$count" -eq 0 ]; then
        echo "  (no video files found)"
    else
        echo ""
        echo "Total: $count video(s)"
    fi
}

cmd_play_video() {
    local path="$1"
    # 如果是相对路径，在视频目录中查找
    if [ ! -f "$path" ] && [ -f "${VIDEO_DIR}/${path}" ]; then
        path="${VIDEO_DIR}/${path}"
    fi
    play_video_wallpaper "$path"
}

cmd_stop_video() {
    if is_video_playing; then
        stop_mpvpaper
        echo "Video wallpaper stopped."
        # 回退到目录中的随机静态壁纸
        noctalia msg wallpaper-random 2>/dev/null || true
    else
        echo "No video wallpaper is playing."
    fi
}

# ===================== 主入口 =====================

ensure_dirs

case "${1:-}" in
    set)
        [ -z "${2:-}" ] && { echo "Usage: dynamic-wallpaper set <path>" >&2; exit 1; }
        cmd_set "$2"
        ;;
    next)
        cmd_next
        ;;
    random)
        cmd_random
        ;;
    toggle-auto)
        cmd_toggle_auto
        ;;
    status)
        cmd_status
        ;;
    list-video)
        cmd_list_video
        ;;
    play-video)
        [ -z "${2:-}" ] && { echo "Usage: dynamic-wallpaper play-video <path>" >&2; exit 1; }
        cmd_play_video "$2"
        ;;
    stop-video)
        cmd_stop_video
        ;;
    *)
        echo "Usage: dynamic-wallpaper <command> [args]"
        echo ""
        echo "Commands:"
        echo "  set <path>        Set wallpaper (auto-detect image/video)"
        echo "  next              Switch to next wallpaper"
        echo "  random            Switch to random wallpaper"
        echo "  toggle-auto       Toggle automatic rotation"
        echo "  status            Show current status"
        echo "  list-video        List available video wallpapers"
        echo "  play-video <path> Play a video wallpaper"
        echo "  stop-video        Stop video wallpaper, return to static"
        exit 1
        ;;
esac
