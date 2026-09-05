#!/bin/bash
# wallpaper-rotate — mpvpaper 动态壁纸轮换 daemon
# 根据时段自动选择对应色调池里的壁纸，按时间间隔轮换。
# systemd user service 方式运行（wallpaper-rotate.service）。

set -euo pipefail

# systemd 环境下没有 WAYLAND_DISPLAY，从 niri 的 socket 动态推导
if [ -z "$WAYLAND_DISPLAY" ]; then
    export WAYLAND_DISPLAY="$(ls /run/user/$(id -u)/niri.wayland-*.sock 2>/dev/null | head -1 | sed 's/.*niri\.//; s/\.[0-9]*\.sock//')"
fi
if [ -z "$WAYLAND_DISPLAY" ]; then
    export WAYLAND_DISPLAY="wayland-1"
fi

WP_DIR="$HOME/Pictures/Wallpapers/video"
TONES_FILE="$HOME/.config/wallpaper-tones.txt"
LAST_WALLPAPER="$HOME/.config/.wallpaper_last"
ROTATE_INTERVAL=1800   # 时段内轮换间隔（秒），30 分钟
MONITOR='*'            # 所有显示器；指定单屏可改成 eDP-1

# 根据当前小时返回目标色调优先级列表（从高到低）
get_target_tones() {
    local hour=$(date +%H)
    if   [ "$hour" -ge 0  ] && [ "$hour" -lt 6  ]; then echo "dark cool neutral"
    elif [ "$hour" -ge 6  ] && [ "$hour" -lt 9  ]; then echo "cool neutral dark"
    elif [ "$hour" -ge 9  ] && [ "$hour" -lt 17 ]; then echo "cool neutral bright"
    elif [ "$hour" -ge 17 ] && [ "$hour" -lt 20 ]; then echo "warm neutral cool"
    else echo "dark cool neutral"
    fi
}

# 从色调池里收集壁纸文件列表
get_pool() {
    local tones="$1"
    local tone
    local files=()
    for tone in $tones; do
        while IFS= read -r line; do
            local name="${line%%#39;\t'*}"
            local t="${line#*#39;\t'}"
            [ "$t" = "$tone" ] && [ -f "$WP_DIR/$name" ] && files+=("$WP_DIR/$name")
        done < "$TONES_FILE"
        # 找到第一个非空色调池就返回
        if [ ${#files[@]} -gt 0 ]; then
            printf '%s\n' "${files[@]}"
            return 0
        fi
    done
    return 1
}

# 随机选一个，排除上次
pick_random() {
    local exclude="$1"
    shift
    local files=("$@")
    if [ ${#files[@]} -eq 0 ]; then
        return 1
    fi
    if [ ${#files[@]} -gt 1 ] && [ -n "$exclude" ]; then
        local candidates=()
        local f
        for f in "${files[@]}"; do
            [ "$f" != "$exclude" ] && candidates+=("$f")
        done
        [ ${#candidates[@]} -gt 0 ] && files=("${candidates[@]}")
    fi
    echo "${files[RANDOM % ${#files[@]}]}"
}

set_wallpaper() {
    # 告诉 Noctalia 的 mpvpaper 插件放弃壁纸层
    noctalia msg plugin noctalia/mpvpaper:service all clear-all 2>/dev/null || true
    pkill mpvpaper 2>/dev/null
    sleep 0.3
    mpvpaper -o "no-audio loop-file=inf hwdec=auto panscan=1.0" "$MONITOR" "$1" > /dev/null 2>&1 &
    echo "$1" > "$LAST_WALLPAPER"
}

# 初始：按时段色调设置
LAST_SET=""
if [ -f "$LAST_WALLPAPER" ] && [ -s "$LAST_WALLPAPER" ]; then
    LAST_SET="$(cat "$LAST_WALLPAPER")"
fi

TARGET_TONES=$(get_target_tones)
POOL=()
while IFS= read -r f; do POOL+=("$f"); done < <(get_pool "$TARGET_TONES")
if [ ${#POOL[@]} -gt 0 ]; then
    if WP=$(pick_random "$LAST_SET" "${POOL[@]}"); then
        set_wallpaper "$WP"
        echo "[$(date '+%H:%M:%S')] 初始设置($TARGET_TONES): $(basename "$WP")"
    fi
else
    # 色调池全空：全库随机兜底
    while IFS= read -r f; do POOL+=("$f"); done < <(find "$WP_DIR" -maxdepth 1 -type f \( -name '*.mp4' -o -name '*.webm' -o -name '*.mkv' -o -name '*.gif' \) 2>/dev/null | sort)
    if WP=$(pick_random "$LAST_SET" "${POOL[@]}"); then
        set_wallpaper "$WP"
        echo "[$(date '+%H:%M:%S')] 初始设置(全库兜底): $(basename "$WP")"
    fi
fi

LAST_SWITCH=$(date +%s)
LAST_HOUR=$(date +%H)

while true; do
    sleep 30

    NOW=$(date +%s)
    ELAPSED=$((NOW - LAST_SWITCH))
    CURRENT_HOUR=$(date +%H)

    # 时段变化：立即按新色调切换
    if [ "$CURRENT_HOUR" != "$LAST_HOUR" ]; then
        TARGET_TONES=$(get_target_tones)
        POOL=()
        while IFS= read -r f; do POOL+=("$f"); done < <(get_pool "$TARGET_TONES")
        if [ ${#POOL[@]} -gt 0 ]; then
            if WP=$(pick_random "$(cat "$LAST_WALLPAPER" 2>/dev/null)" "${POOL[@]}"); then
                set_wallpaper "$WP"
                echo "[$(date '+%H:%M:%S')] 时段切换($TARGET_TONES): $(basename "$WP")"
            fi
        else
            while IFS= read -r f; do POOL+=("$f"); done < <(find "$WP_DIR" -maxdepth 1 -type f \( -name '*.mp4' -o -name '*.webm' -o -name '*.mkv' -o -name '*.gif' \) 2>/dev/null | sort)
            if WP=$(pick_random "$(cat "$LAST_WALLPAPER" 2>/dev/null)" "${POOL[@]}"); then
                set_wallpaper "$WP"
                echo "[$(date '+%H:%M:%S')] 时段切换(全库兜底): $(basename "$WP")"
            fi
        fi
        LAST_SWITCH=$NOW
        LAST_HOUR="$CURRENT_HOUR"
        continue
    fi

    # 时段内轮换
    if [ "$ELAPSED" -ge "$ROTATE_INTERVAL" ]; then
        TARGET_TONES=$(get_target_tones)
        POOL=()
        while IFS= read -r f; do POOL+=("$f"); done < <(get_pool "$TARGET_TONES")
        if [ ${#POOL[@]} -gt 0 ]; then
            if WP=$(pick_random "$(cat "$LAST_WALLPAPER" 2>/dev/null)" "${POOL[@]}"); then
                set_wallpaper "$WP"
                echo "[$(date '+%H:%M:%S')] 轮换($TARGET_TONES): $(basename "$WP")"
            fi
        else
            while IFS= read -r f; do POOL+=("$f"); done < <(find "$WP_DIR" -maxdepth 1 -type f \( -name '*.mp4' -o -name '*.webm' -o -name '*.mkv' -o -name '*.gif' \) 2>/dev/null | sort)
            if WP=$(pick_random "$(cat "$LAST_WALLPAPER" 2>/dev/null)" "${POOL[@]}"); then
                set_wallpaper "$WP"
                echo "[$(date '+%H:%M:%S')] 轮换(全库兜底): $(basename "$WP")"
            fi
        fi
        LAST_SWITCH=$NOW
    fi
done
