"""
NyxNiri Wallpaper Picker Backend Engine
Executes wallpaper switching for static images and live video wallpapers.

Design: the noctalia/mpvpaper plugin is the ONLY owner of mpvpaper instances.
- static wallpaper  -> plugin clear-all (stop videos) + noctalia wallpaper-set
- video wallpaper  -> write the plugin's assignments.json (connector "*") then
                      disable+enable the plugin service so it re-boots, reloads
                      the assignment from disk and natively launches mpvpaper
                      (which also hides noctalia's static layer so the video
                      shows animated). No instance is launched directly by us.
"""

import os
import sys
import json
import time
import subprocess

STATE_DIR = os.path.expanduser("~/.local/state/noctalia/mpvpaper")
ASSIGNMENTS_FILE = os.path.join(STATE_DIR, "assignments.json")
PLUGIN_ID = "noctalia/mpvpaper"


def _notify_plugin_clear_all():
    """Ask the noctalia/mpvpaper plugin service to stop every video wallpaper.

    clear-all empties the plugin's in-memory assignments and persists them, so
    subsequent onConfigChanged/onOutputsChanged -> applyAll() calls become no-ops.
    """
    try:
        subprocess.run(
            ["noctalia", "msg", "plugin", "noctalia/mpvpaper:service", "all", "clear-all"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=5, check=False
        )
    except Exception:
        pass


def _restart_plugin():
    """Re-boot the mpvpaper plugin service so it re-reads assignments.json.

    The plugin only loads assignments at service boot; there is no set-video IPC
    reachable from outside the plugin, so disable+enable is the native reload.
    """
    try:
        subprocess.run(["noctalia", "msg", "plugins", "disable", PLUGIN_ID],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=10, check=False)
        time.sleep(0.5)
        subprocess.run(["noctalia", "msg", "plugins", "enable", PLUGIN_ID],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=10, check=False)
    except Exception:
        pass


def _write_mpvpaper_assignments(assignments: dict):
    """Write mpvpaper assignments atomically."""
    try:
        os.makedirs(STATE_DIR, exist_ok=True)
        tmp_file = f"{ASSIGNMENTS_FILE}.tmp.{os.getpid()}"
        data = {
            "assignments": assignments,
            "launchedAsSystemd": {k: False for k in assignments}
        }
        with open(tmp_file, "w", encoding="utf-8") as f:
            json.dump(data, f)
        os.replace(tmp_file, ASSIGNMENTS_FILE)
    except Exception as e:
        print(f"Warning: Failed to update mpvpaper assignments: {e}", file=sys.stderr)


def apply_static_wallpaper(path: str) -> bool:
    """Apply static wallpaper, clear mpvpaper video assignments."""
    try:
        _notify_plugin_clear_all()
        _write_mpvpaper_assignments({})
        subprocess.run(["noctalia", "msg", "wallpaper-set", path],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=5, check=False)
        return True
    except Exception as e:
        print(f"Error applying static wallpaper: {e}", file=sys.stderr)
        return False


def apply_dynamic_wallpaper(video_path: str, thumb_path: str = None) -> bool:
    """Apply dynamic video wallpaper through the mpvpaper plugin."""
    try:
        _notify_plugin_clear_all()
        _write_mpvpaper_assignments({"*": video_path})
        _restart_plugin()
        return True
    except Exception as e:
        print(f"Error applying live wallpaper: {e}", file=sys.stderr)
        return False


def apply_wallpaper(item) -> bool:
    """Polymorphic wallpaper application dispatcher."""
    if item.is_video:
        return apply_dynamic_wallpaper(item.path)
    else:
        return apply_static_wallpaper(item.path)