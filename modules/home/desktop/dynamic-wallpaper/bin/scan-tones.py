#!/usr/bin/env python3
"""k-means 聚类提取壁纸主色并分类色调
用法: scan-tones.py [壁纸目录] [输出文件]
输出格式: 文件名<TAB>分类 (dark/cool/warm/neutral/bright)
"""
import os
import sys

# 动态 import，避免 shebang 阶段依赖问题
import numpy as np
from PIL import Image

DEFAULT_DIR = os.path.expanduser("~/Pictures/Wallpapers/video")
DEFAULT_OUT = os.path.expanduser("~/.config/wallpaper-tones.txt")

EXTENSIONS = {".gif", ".png", ".jpg", ".jpeg", ".webp", ".bmp", ".mp4", ".webm", ".mkv"}
VIDEO_EXTS = {".mp4", ".webm", ".mkv"}


def load_image(path):
    """打开图片；视频则用 ffmpeg 提取中间帧转成临时 PNG 再分析"""
    import subprocess
    import tempfile

    ext = os.path.splitext(path)[1].lower()
    if ext in VIDEO_EXTS:
        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tmp:
            tmp_path = tmp.name
        try:
            subprocess.run(
                ["ffmpeg", "-y", "-ss", "1", "-i", path, "-frames:v", "1", tmp_path],
                capture_output=True,
                check=True,
            )
            return Image.open(tmp_path)
        finally:
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)
    return Image.open(path)


def kmeans(pixels, k=3, iters=12, seed=42):
    """简单 k-means，返回 (centers, counts)"""
    rng = np.random.default_rng(seed)
    idx = rng.choice(len(pixels), size=k, replace=False)
    centers = pixels[idx].astype(np.float64)

    for _ in range(iters):
        diff = pixels[:, None, :] - centers[None, :, :]
        dist = np.sum(diff * diff, axis=2)
        labels = np.argmin(dist, axis=1)
        new_centers = []
        for i in range(k):
            mask = labels == i
            if np.any(mask):
                new_centers.append(pixels[mask].mean(axis=0))
            else:
                new_centers.append(centers[i])
        centers = np.array(new_centers)

    counts = np.bincount(labels, minlength=k)
    return centers, counts


def classify(centers, counts):
    """根据主色聚类结果判断色调"""
    total = counts.sum()
    if total == 0:
        return "neutral"
    weights = counts / total

    rgb = np.clip(centers / 255.0, 0, 1)
    maxc = rgb.max(axis=1)
    minc = rgb.min(axis=1)
    delta = maxc - minc
    v = maxc
    s = np.where(maxc > 0, delta / np.maximum(maxc, 1e-9), 0)

    h = np.zeros(len(rgb))
    for i in range(len(rgb)):
        if delta[i] == 0:
            h[i] = 0
        elif maxc[i] == rgb[i][0]:
            h[i] = 60 * (((rgb[i][1] - rgb[i][2]) / delta[i]) % 6)
        elif maxc[i] == rgb[i][1]:
            h[i] = 60 * (((rgb[i][2] - rgb[i][0]) / delta[i]) + 2)
        else:
            h[i] = 60 * (((rgb[i][0] - rgb[i][1]) / delta[i]) + 4)
    h = (h + 360) % 360

    wv = float(np.sum(weights * v))
    ws = float(np.sum(weights * s))

    if wv < 0.22:
        return "dark"
    if ws < 0.12:
        return "neutral"

    warm_mass = 0.0
    cool_mass = 0.0
    for i in range(len(h)):
        w = weights[i]
        if w < 0.05:
            continue
        hi = h[i]
        if hi < 60 or hi > 330:
            warm_mass += w
        elif 150 <= hi <= 260:
            cool_mass += w

    if warm_mass > cool_mass + 0.15:
        return "warm"
    if cool_mass > warm_mass + 0.15:
        return "cool"
    if wv > 0.8:
        return "bright"
    return "neutral"


def main():
    wp_dir = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_DIR
    out_file = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_OUT
    tmp_out = out_file + ".tmp"

    files = []
    for root, _, fnames in os.walk(wp_dir):
        for name in sorted(fnames):
            ext = os.path.splitext(name)[1].lower()
            if ext in EXTENSIONS:
                files.append(os.path.join(root, name))
    files.sort()

    stats = {}
    with open(tmp_out, "w", encoding="utf-8") as out:
        for path in files:
            name = os.path.basename(path)
            tone = "neutral"
            try:
                with load_image(path) as img:
                    img.seek(0)
                    img = img.convert("RGB").resize((64, 64), Image.BILINEAR)
                    pixels = np.asarray(img).reshape(-1, 3).astype(np.float64)
                    if len(pixels) > 3000:
                        rng = np.random.default_rng(hash(name) % 2**32)
                        idx = rng.choice(len(pixels), size=3000, replace=False)
                        pixels = pixels[idx]
                    centers, counts = kmeans(pixels)
                    tone = classify(centers, counts)
            except Exception:
                tone = "neutral"
            out.write(f"{name}\t{tone}\n")
            stats[tone] = stats.get(tone, 0) + 1

    os.replace(tmp_out, out_file)
    print(f"完成，共 {len(files)} 个文件")
    for t in ["dark", "cool", "warm", "neutral", "bright"]:
        print(f"{t}: {stats.get(t, 0)}")


if __name__ == "__main__":
    main()
