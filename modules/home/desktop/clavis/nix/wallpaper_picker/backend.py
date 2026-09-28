"""
NyxNiri Wallpaper Picker Backend Engine
Applies wallpapers through the Clavis Shell IPC (`key ipc call wallpaper ...`).

Clavis 是唯一的壁纸所有者：
  - 设置壁纸 -> `key ipc call wallpaper set <path>`，由 Clavis 更新
    ~/.config/clavis/config.json、刷新壁纸层并用 matugen 重新生成主题
    （niri/kitty/cava/zsh/keytop/fcitx5/yazi/btop 配色）。
  - 当前壁纸 -> 读同一个 config.json 的 wallpaper.path（Clavis 没有 get IPC）。
  - 视频壁纸 -> 不支持。Noctalia 时代的 mpvpaper 插件随 shell 一起移除了，
    Clavis 的 quickshell/awww 两个后端都只渲染图像；库里的 .mp4/.webm 文件
    保留但不再出现在选择器里（见 config.LIVE_EXTENSIONS）。
"""

import json
import os
import subprocess
import sys

from . import config

CLAVIS_CONFIG_PATH = os.path.expanduser("~/.config/clavis/config.json")
KEY_BIN = "key"


def _key(*args: str, timeout: int = 8) -> subprocess.CompletedProcess:
    return subprocess.run(
        [KEY_BIN, "ipc", "call", *args],
        capture_output=True,
        text=True,
        timeout=timeout,
        check=False,
    )


def shell_available() -> bool:
    """Clavis 是否在跑（IPC 探活）。"""
    try:
        res = subprocess.run(
            [KEY_BIN, "ipc", "show"],
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        )
        return res.returncode == 0
    except Exception:
        return False


def current_wallpaper() -> str:
    """当前壁纸路径（读 Clavis 的 personalization config）。"""
    try:
        with open(CLAVIS_CONFIG_PATH, encoding="utf-8") as f:
            data = json.load(f)
        path = data.get("wallpaper", {}).get("path") or ""
        if path and os.path.isfile(path):
            return os.path.realpath(path)
    except Exception:
        pass
    return ""


def apply_static_wallpaper(path: str) -> bool:
    """通过 Clavis 应用壁纸（含主题重新生成）。"""
    path = os.path.abspath(os.path.expanduser(path))
    if not os.path.isfile(path):
        print(f"Error: wallpaper not found: {path}", file=sys.stderr)
        return False
    try:
        res = _key("wallpaper", "set", path)
    except subprocess.TimeoutExpired:
        print("Error: timeout talking to Clavis (key ipc)", file=sys.stderr)
        return False
    if res.returncode != 0:
        detail = (res.stderr or res.stdout or "").strip()
        print(f"Error applying wallpaper: {detail}", file=sys.stderr)
        return False
    return True


def apply_dynamic_wallpaper(video_path: str, thumb_path: str = None) -> bool:
    """视频壁纸在 Clavis 下不可用（见模块 docstring）。"""
    print(
        f"Error: video wallpapers are not supported by Clavis Shell: {video_path}",
        file=sys.stderr,
    )
    return False


def apply_wallpaper(item) -> bool:
    """Polymorphic wallpaper application dispatcher.

    Clavis 的 quickshell/awww 后端都是图像渲染器，GIF 属于图像，走同一条
    `wallpaper set` 路径即可（选择器里的 Live 分类 = GIF，不是视频）。这里只
    拦真正的视频扩展名，避免选择器/轮换器以外的调用方误用。
    """
    path = os.path.abspath(os.path.expanduser(item.path))
    if os.path.splitext(path)[1].lower() in config.UNSUPPORTED_VIDEO_EXTENSIONS:
        return apply_dynamic_wallpaper(path)
    return apply_static_wallpaper(path)
