#!/usr/bin/env python3
"""
wallpapers-rotate — 定时自动轮换 Noctalia 壁纸（静态图 + 视频/GIF）。

每半小时在壁纸目录里挑一张壁纸，复用 NyxNiri wallpaper_picker 的 backend
（apply_wallpaper 分发逻辑）应用：
  - 静态图 -> 清除 mpvpaper 插件分配 + Noctalia wallpaper-set
  - 视频/GIF -> 写入 mpvpaper 插件 assignments.json 并重启插件

选图带色调偏好（参考 ~/.config/wallpaper-tones.txt，由 scan-tones 生成）：
  - 按时段取目标色调优先级（午夜深色 / 白天清爽 / 傍晚暖色 …），
    从"非空的最高优先级色调池"里随机，排除当前壁纸与上一次。
  - 没有色调库 / 命中为空时，退化为全库随机。

用法:
  scan-tones                                      # 先生成色调库
  wallpapers-rotate            # 按色调轮换一张
  wallpapers-rotate --dry-run  # 只打印会被选中的壁纸，不实际应用
"""

import json
import os
import random
import subprocess
import sys
from datetime import datetime

from wallpaper_picker.backend import (
    ASSIGNMENTS_FILE,
    apply_dynamic_wallpaper,
    apply_static_wallpaper,
)
from wallpaper_picker.config import (
    ALL_SUPPORTED_EXTENSIONS,
    VIDEO_EXTENSIONS,
    get_wallpaper_search_roots,
)

STATE_FILE = os.path.expanduser("~/.local/state/noctalia/wallpapers-rotate.last")
TONES_FILE = os.path.expanduser("~/.config/wallpaper-tones.txt")


class _Item:
    """backend.apply_wallpaper 需要的最小 item 抽象。"""

    def __init__(self, path: str):
        self.path = path
        self.is_video = os.path.splitext(path)[1].lower() in VIDEO_EXTENSIONS


def _real(p: str) -> str:
    try:
        return os.path.realpath(p)
    except Exception:
        return p


def collect_wallpapers() -> list:
    """递归收集所有支持的壁纸，跳过隐藏路径。"""
    seen, found = set(), []
    for root in get_wallpaper_search_roots():
        if not os.path.isdir(root):
            continue
        for dirpath, dirnames, filenames in os.walk(root):
            dirnames[:] = [d for d in dirnames if not d.startswith(".")]
            for fname in filenames:
                if fname.startswith("."):
                    continue
                if os.path.splitext(fname)[1].lower() in ALL_SUPPORTED_EXTENSIONS:
                    p = _real(os.path.join(dirpath, fname))
                    if p not in seen:
                        seen.add(p)
                        found.append(p)
    return found


def current_wallpaper() -> str:
    """当前壁纸（Noctalia 原生 + mpvpaper 视频分配）。"""
    try:
        res = subprocess.run(
            ["noctalia", "msg", "wallpaper-get"],
            capture_output=True, text=True, timeout=5, check=False,
        )
        p = res.stdout.strip()
        if p and os.path.isfile(p):
            return _real(p)
    except Exception:
        pass
    try:
        with open(ASSIGNMENTS_FILE, encoding="utf-8") as f:
            data = json.load(f)
        for v in data.get("assignments", {}).values():
            if isinstance(v, str) and v and os.path.isfile(v):
                return _real(v)
    except Exception:
        pass
    return ""


def last_applied() -> str:
    try:
        with open(STATE_FILE, encoding="utf-8") as f:
            return f.read().strip()
    except OSError:
        return ""


def load_tones() -> dict:
    """basename -> tone；文件缺失/为空时返回空 dict。"""
    tones = {}
    try:
        with open(TONES_FILE, encoding="utf-8") as f:
            for line in f:
                if "\t" not in line:
                    continue
                name, tone = line.rstrip("\n").split("\t", 1)
                name, tone = name.strip(), tone.strip()
                if name and tone:
                    tones[name] = tone
    except OSError:
        return {}
    return tones


def target_tones() -> list:
    """按时段返回目标色调优先级（从高到低）。"""
    h = datetime.now().hour
    if 0 <= h < 6:
        return ["dark", "cool", "neutral"]
    if 6 <= h < 9:
        return ["cool", "neutral", "dark"]
    if 9 <= h < 17:
        return ["cool", "neutral", "bright"]
    if 17 <= h < 20:
        return ["warm", "neutral", "cool"]
    return ["dark", "cool", "neutral"]


def pick_by_tone(candidates: list, tones: dict) -> tuple:
    """按色调优先级挑一张，返回 (path, tone)；无色调库/命中空时退化为随机。"""
    targets = target_tones()
    by_tone = {t: [] for t in targets}
    unknown = []
    for p in candidates:
        tone = tones.get(os.path.basename(p))
        if tone in by_tone:
            by_tone[tone].append(p)
        else:
            unknown.append(p)

    for t in targets:
        if by_tone[t]:
            return random.choice(by_tone[t]), t
    # 兜底：色调库缺失或该时段没有任何命中 -> 全候选随机
    return random.choice(candidates), None


def main() -> int:
    dry_run = "--dry-run" in sys.argv[1:]
    pool = collect_wallpapers()
    if not pool:
        print("wallpapers-rotate: no wallpapers found", file=sys.stderr)
        return 1

    tones = load_tones()
    if not tones:
        print(
            f"wallpapers-rotate: no tone library at {TONES_FILE}; "
            "run 'scan-tones' (falling back to fully random)",
            file=sys.stderr,
        )

    exclude = {current_wallpaper(), last_applied()}
    candidates = [p for p in pool if p not in exclude] or pool

    pick, tone = pick_by_tone(candidates, tones)
    tone_txt = tone or "random"
    print(f"wallpapers-rotate: picked {pick} (tone={tone_txt})")

    if dry_run:
        return 0

    item = _Item(pick)
    ok = apply_dynamic_wallpaper(pick) if item.is_video else apply_static_wallpaper(pick)
    if not ok:
        print(f"wallpapers-rotate: failed to apply {pick}", file=sys.stderr)
        return 1

    try:
        os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
        with open(STATE_FILE, "w", encoding="utf-8") as f:
            f.write(pick + "\n")
    except OSError as e:
        print(f"wallpapers-rotate: cannot write state: {e}", file=sys.stderr)
        return 1

    print(f"wallpapers-rotate: applied ({'video' if item.is_video else 'static'})")
    return 0


if __name__ == "__main__":
    sys.exit(main())