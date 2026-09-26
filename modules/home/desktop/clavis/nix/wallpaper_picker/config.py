"""
NyxNiri Wallpaper Picker Configuration Engine
Multi-source prioritized wallpaper directory resolver and format definitions.
"""

import os
import sys
import json
import subprocess

# ── File Format Definitions ───────────────────────────────────────────────────
# Clavis 的壁纸层是 Qt 场景图，只能直接渲染静态图和动图：
#   - 静态图 jpg/jpeg/png/webp/jxl/avif/bmp/svg
#   - 动图 .gif（Clavis 走 Qt 图像插件逐帧播放）
# 真正的视频（mp4/webm/mkv/mov）以前靠 Noctalia 的 mpvpaper 插件播放，Clavis
# 没有等价后端（quickshell 与 awww 两个后端都只接受图像），所以视频文件保留
# 在库里但不再进入选择器/轮换池。
STATIC_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".jxl", ".avif", ".bmp", ".svg"}
LIVE_EXTENSIONS = {".gif"}
UNSUPPORTED_VIDEO_EXTENSIONS = {".mp4", ".webm", ".mkv", ".mov"}
ALL_SUPPORTED_EXTENSIONS = STATIC_EXTENSIONS | LIVE_EXTENSIONS

CACHE_DIR = os.path.expanduser("~/.cache/nyxniri/thumbnails")
CLAVIS_CONFIG_PATH = os.path.expanduser("~/.config/clavis/config.json")
USER_DIRS_PATH = os.path.expanduser("~/.config/user-dirs.dirs")


def get_clavis_wallpaper_folder() -> str:
    """读 Clavis 设置里的壁纸目录（personalization config 的 wallpaper.folder）。"""
    try:
        with open(CLAVIS_CONFIG_PATH, encoding="utf-8") as f:
            data = json.load(f)
        folder = data.get("wallpaper", {}).get("folder")
        if folder:
            return os.path.expanduser(folder)
    except Exception:
        pass
    return ""


def get_xdg_pictures_dir() -> str:
    """Resolve the user's Pictures directory (XDG-aware with multilingual fallback)."""
    try:
        res = subprocess.run(["xdg-user-dir", "PICTURES"], capture_output=True, text=True, timeout=1)
        d = res.stdout.strip()
        if d and d != os.path.expanduser("~") and os.path.isdir(d):
            return d
    except Exception:
        pass

    if os.path.isfile(USER_DIRS_PATH):
        try:
            with open(USER_DIRS_PATH, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line.startswith("XDG_PICTURES_DIR="):
                        val = line.split("=", 1)[1].strip('"\'')
                        val = val.replace("$HOME", os.path.expanduser("~"))
                        if os.path.isdir(val):
                            return val
        except Exception:
            pass

    for cand in [
        os.path.expanduser("~/Pictures"),
        os.path.expanduser("~/图片"),
        os.path.expanduser("~/画像"),
        os.path.expanduser("~/Bilder"),
        os.path.expanduser("~/Images"),
    ]:
        if os.path.isdir(cand):
            return cand

    return os.path.expanduser("~/Pictures")


def get_wallpaper_search_roots() -> list:
    """
    Resolve and deduplicate all candidate wallpaper root directories.
    Prioritizes the Clavis wallpaper folder, XDG get_pics_dir, common paths,
    and built-in fallbacks.
    """
    candidates = []

    # Priority 1: Clavis 运行时配置里的壁纸目录
    clavis_folder = get_clavis_wallpaper_folder()
    if clavis_folder:
        candidates.append(clavis_folder)

    # Priority 2: XDG Pictures directory + Wallpapers
    # 仍然扫 Wallpapers/video：那里面的图片照常显示，只是 .mp4/.webm 会被扩展名
    # 过滤掉（Clavis 不渲染视频）。
    pics_dir = get_xdg_pictures_dir()
    candidates.append(os.path.join(pics_dir, "Wallpapers"))
    candidates.append(os.path.join(pics_dir, "Wallpapers", "video"))

    # Priority 3: Multilingual standard paths
    candidates.append(os.path.expanduser("~/图片/Wallpapers"))
    candidates.append(os.path.expanduser("~/Pictures/Wallpapers"))
    candidates.append(os.path.expanduser("~/Wallpapers"))

    # Priority 4: Environment variable override
    env_dir = os.environ.get("NYXNIRI_WALLPAPERS_DIR")
    if env_dir:
        candidates.insert(0, os.path.expanduser(env_dir))

    # Priority 5: Built-in local fallbacks
    candidates.append(os.path.expanduser("~/.config/Wallpapers"))

    resolved_roots = []
    seen_real_paths = set()

    for path in candidates:
        exp_path = os.path.expanduser(os.path.expandvars(path))
        if os.path.isdir(exp_path):
            real_path = os.path.realpath(exp_path)
            if real_path not in seen_real_paths:
                seen_real_paths.add(real_path)
                resolved_roots.append(real_path)

    return resolved_roots
