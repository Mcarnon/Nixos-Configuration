#!/usr/bin/env bash
# mpvpaper-launcher — NyxNiri 方案：直接从壁纸状态启动 mpvpaper 独立进程
# 读取 Noctalia 上次壁纸，若是视频则启动 mpvpaper 播放
set -uo pipefail

STATE_FILE="$HOME/.local/state/noctalia/state.toml"
ASSIGNMENTS_FILE="$HOME/.local/state/noctalia/mpvpaper/assignments.json"
CACHE_DIR="$HOME/.cache/noctalia/mpvpaper"
HOOK_SCRIPT="$HOME/.config/noctalia/mpv-hook.lua"

# 从 state.toml 读取上次壁纸路径（格式: wallpaper = "/path"）
get_last_wallpaper() {
    if [ -f "$STATE_FILE" ]; then
        sed -n 's/^wallpaper\s*=\s*"\?\([^"]*\)"\?/\1/p' "$STATE_FILE" 2>/dev/null | head -1 || true
    fi
}

# 从 assignments.json 读取当前播放的视频
get_current_video() {
    if [ -f "$ASSIGNMENTS_FILE" ]; then
        jq -r '.assignments["*"] // empty' "$ASSIGNMENTS_FILE" 2>/dev/null || true
    fi
}

# 杀掉已有的 mpvpaper 实例
kill_mpvpaper() {
    pkill -x mpvpaper 2>/dev/null || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        if ! pgrep -x mpvpaper >/dev/null 2>&1; then
            break
        fi
        sleep 0.1
    done
}

# 生成缩略图
generate_thumb() {
    local video="$1"
    local thumb_name thumb_path
    thumb_name=$(printf '%s' "$video" | md5sum | awk '{print $1}')
    thumb_path="$CACHE_DIR/${thumb_name}.jpg"
    mkdir -p "$CACHE_DIR"
    if [ ! -f "$thumb_path" ]; then
        timeout 30 ffmpeg -y -i "$video" -ss 00:00:01 -vframes 1 "$thumb_path" 2>/dev/null || true
    fi
    echo "$thumb_path"
}

# 启动 mpvpaper 播放视频
launch_mpvpaper() {
    local video="$1"
    local thumb_path="$2"

    kill_mpvpaper

    # 构建 mpv 选项
    local mpv_opts="config=no load-scripts=no loop-file=inf panscan=1.0 no-audio hwdec=auto"
    if [ -f "$HOOK_SCRIPT" ]; then
        mpv_opts="$mpv_opts --script=$HOOK_SCRIPT"
    fi

    # 写 assignments.json（NyxNiri 方案，使用 jq 安全处理路径）
    mkdir -p "$(dirname "$ASSIGNMENTS_FILE")"
    local video_json
    video_json=$(printf '%s' "$video" | jq -Rs '.')
    jq -n \
        --arg video "$video" \
        '{"assignments":{"*":$video},"launchedAsSystemd":{"*":false}}' \
        > "$ASSIGNMENTS_FILE"

    # 设置缩略图为 Noctalia 壁纸（触发配色）
    if [ -n "$thumb_path" ] && [ -f "$thumb_path" ]; then
        noctalia msg wallpaper-set "$thumb_path" 2>/dev/null || true
    fi

    echo "mpvpaper-launcher: 启动视频壁纸: $video"
    exec mpvpaper --auto-pause -o "$mpv_opts" "*" "$video"
}

# ── 主逻辑 ──────────────────────────────────────────────────────────
mkdir -p "$CACHE_DIR"

# 优先用当前 assignments 中的视频
VIDEO=$(get_current_video)
if [ -z "$VIDEO" ] || [ ! -f "$VIDEO" ]; then
    LAST_WP=$(get_last_wallpaper)
    if [ -n "$LAST_WP" ] && [ -f "$LAST_WP" ] && [[ "$LAST_WP" =~ \.(mp4|webm|mkv|mov|gif)$ ]]; then
        VIDEO="$LAST_WP"
    fi
fi

# 兜底：扫描壁纸目录
if [ -z "$VIDEO" ] || [ ! -f "$VIDEO" ]; then
    VIDEO=$(find "$HOME/Pictures/Wallpapers" -maxdepth 1 -type f \( -name '*.mp4' -o -name '*.webm' -o -name '*.mkv' -o -name '*.gif' \) 2>/dev/null | shuf | head -1)
fi

if [ -z "$VIDEO" ] || [ ! -f "$VIDEO" ]; then
    echo "mpvpaper-launcher: 未找到视频文件，退出"
    exit 0
fi

THUMB=$(generate_thumb "$VIDEO")
launch_mpvpaper "$VIDEO" "$THUMB"
