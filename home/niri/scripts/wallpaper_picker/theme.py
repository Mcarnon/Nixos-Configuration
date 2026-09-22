"""
NyxNiri Wallpaper Picker — Material 3 Expressive (M3E) Design System.
"""

import os

# ── M3 Shape Scale ──────────────────────────────────────────────────────
SHAPE = {
    "none": 0, "xs": 4, "s": 8, "m": 12, "l": 16,
    "l_inc": 20, "xl": 28, "xl_inc": 32, "xxl": 48, "full": 9999,
}

# ── M3 Type Scale ───────────────────────────────────────────────────────
TYPE = {
    "display-large": (57, 400), "display-medium": (45, 400), "display-small": (36, 400),
    "headline-large": (32, 400), "headline-medium": (28, 400), "headline-small": (24, 400),
    "title-large": (22, 400), "title-medium": (16, 500), "title-small": (14, 500),
    "body-large": (16, 400), "body-medium": (14, 400), "body-small": (12, 400),
    "label-large": (14, 500), "label-medium": (12, 500), "label-small": (11, 500),
    "display-large-emph": (57, 500), "display-medium-emph": (45, 500), "display-small-emph": (36, 500),
    "headline-large-emph": (32, 500), "headline-medium-emph": (28, 500), "headline-small-emph": (24, 500),
    "title-large-emph": (22, 500), "title-medium-emph": (16, 700), "title-small-emph": (14, 700),
    "body-large-emph": (16, 500), "body-medium-emph": (14, 500), "body-small-emph": (12, 500),
    "label-large-emph": (14, 700), "label-medium-emph": (12, 700), "label-small-emph": (11, 700),
}

# ── M3 Elevation Levels ─────────────────────────────────────────────────
ELEVATION = {
    0: "none",
    1: "0 1px 2px rgba(0,0,0,0.30), 0 1px 3px 1px rgba(0,0,0,0.15)",
    2: "0 1px 2px rgba(0,0,0,0.30), 0 2px 6px 2px rgba(0,0,0,0.15)",
    3: "0 1px 3px rgba(0,0,0,0.30), 0 4px 8px 3px rgba(0,0,0,0.15)",
    4: "0 2px 3px rgba(0,0,0,0.30), 0 6px 10px 4px rgba(0,0,0,0.15)",
    5: "0 4px 4px rgba(0,0,0,0.30), 0 8px 12px 6px rgba(0,0,0,0.15)",
}

# ── M3 State Layer Opacities ────────────────────────────────────────────
STATE_HOVER = 0.08
STATE_PRESSED = 0.10
STATE_FOCUSED = 0.10

# ── M3 Expressive Motion ────────────────────────────────────────────────
EASE_EXPRESSIVE_FAST_EFFECTS = "cubic-bezier(0.31, 0.94, 0.34, 1.00)"
EASE_EXPRESSIVE_DEFAULT_EFFECTS = "cubic-bezier(0.34, 0.80, 0.34, 1.00)"
EASE_EXPRESSIVE_FAST_SPATIAL = "cubic-bezier(0.42, 1.67, 0.21, 0.90)"
DUR_FAST_MS = 150
DUR_DEFAULT_MS = 200
DUR_STATE_MS = 150
DUR_FAST_SPATIAL_MS = 350
DUR_EXIT_MS = 200

STARSHIP_PALETTE_PATH = "~/.cache/noctalia/starship-palette.toml"

_ROLE_SOURCES = {
    "primary": ("blue", "sapphire", "lavender", "primary"),
    "secondary": ("teal", "green", "sky", "secondary"),
    "tertiary": ("pink", "peach", "mauve", "yellow", "tertiary"),
    "surface": ("base", "surface0", "mantle", "crust"),
    "on_surface": ("text", "subtext1", "white"),
    "on_surface_variant": ("subtext0", "overlay2", "overlay1"),
    "outline": ("overlay1", "subtext0", "overlay2"),
    "outline_variant": ("overlay0", "surface2", "surface1"),
    "error": ("red", "maroon", "error"),
}

_FALLBACK = {
    "primary": (0.42, 0.70, 1.00),
    "secondary": (0.38, 0.85, 0.65),
    "tertiary": (1.00, 0.75, 0.35),
    "surface": (0.12, 0.13, 0.18),
    "on_surface": (0.95, 0.96, 0.99),
    "on_surface_variant": (0.68, 0.72, 0.78),
    "outline": (0.80, 0.84, 0.90),
    "outline_variant": (0.45, 0.48, 0.55),
    "error": (0.85, 0.31, 0.32),
}


def hex_to_rgb(hex_str, default=None):
    try:
        s = hex_str.strip().lstrip("#")
        if len(s) == 6:
            return tuple(int(s[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    except Exception:
        pass
    return default


def _mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def _luminance(rgb):
    def chan(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (chan(c) for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def _contrast(a, b):
    la, lb = _luminance(a), _luminance(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def _on_color(rgb):
    black = _contrast(rgb, (0.0, 0.0, 0.0))
    white = _contrast(rgb, (1.0, 1.0, 1.0))
    return (0.0, 0.0, 0.0) if black >= white else (1.0, 1.0, 1.0)


def _rgb(c):
    return "rgb({},{},{})".format(*(int(round(x * 255)) for x in c))


def _sl(base, fg, opacity):
    return _rgb(_mix(base, fg, opacity))


def _load_starship_colors(path=None):
    colors = {}
    p = os.path.expanduser(path or STARSHIP_PALETTE_PATH)
    if not os.path.isfile(p):
        return colors
    try:
        with open(p, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith(("#", "[")) or "=" not in line:
                    continue
                k, v = (x.strip() for x in line.split("=", 1))
                rgb = hex_to_rgb(v.strip("\"'"))
                if rgb:
                    colors[k] = rgb
    except Exception:
        return {}
    return colors


def build_tokens(raw=None):
    if raw is None:
        raw = _load_starship_colors()

    def pick(role):
        for key in _ROLE_SOURCES[role]:
            if key in raw:
                v = raw[key]
                if isinstance(v, str):
                    v = hex_to_rgb(v)
                if v is not None:
                    return v
        return _FALLBACK[role]

    primary = pick("primary")
    secondary = pick("secondary")
    tertiary = pick("tertiary")
    error = pick("error")
    surface = pick("surface")
    on_surface = pick("on_surface")
    is_dark = _luminance(surface) < 0.5

    if is_dark:
        tiers = [_mix(surface, on_surface, t) for t in (0.045, 0.11, 0.145, 0.20, 0.255)]
    else:
        tiers = [_mix(surface, (1.0, 1.0, 1.0), 0.30)]
        tiers += [_mix(surface, on_surface, t) for t in (0.045, 0.075, 0.105, 0.135)]

    container_t = 0.62 if is_dark else 0.80

    return {
        "is_dark": is_dark,
        "primary": primary,
        "on_primary": _on_color(primary),
        "primary_container": _mix(primary, surface, container_t),
        "on_primary_container": _mix(on_surface, primary, 0.14),
        "secondary": secondary,
        "on_secondary": _on_color(secondary),
        "secondary_container": _mix(secondary, surface, container_t),
        "on_secondary_container": _mix(on_surface, secondary, 0.14),
        "tertiary": tertiary,
        "on_tertiary": _on_color(tertiary),
        "tertiary_container": _mix(tertiary, surface, container_t),
        "on_tertiary_container": _mix(on_surface, tertiary, 0.14),
        "surface": surface,
        "on_surface": on_surface,
        "on_surface_variant": pick("on_surface_variant"),
        "surface_container_lowest": tiers[0],
        "surface_container_low": tiers[1],
        "surface_container": tiers[2],
        "surface_container_high": tiers[3],
        "surface_container_highest": tiers[4],
        "outline": pick("outline"),
        "outline_variant": pick("outline_variant"),
        "error": error,
        "on_error": _on_color(error),
    }


def build_css(t, geometry):
    card_w = int(geometry.get("card_w", 334))
    thumb_w = int(geometry.get("thumb_w", card_w - 6))
    thumb_h = int(geometry.get("thumb_h", thumb_w * 9 // 16))
    search_h = int(geometry["search_h"])
    chip_h = int(geometry["chip_h"])

    surface = t["surface"]
    on_surface = t["on_surface"]
    scl = t["surface_container_low"]
    sch = t["surface_container_high"]
    sc = t["secondary_container"]
    osc = t["on_secondary_container"]
    pc = t["primary_container"]
    opc = t["on_primary_container"]
    tc = t.get("tertiary_container", _mix(t["tertiary"], surface, 0.62 if t["is_dark"] else 0.80))
    otc = t.get("on_tertiary_container", _mix(on_surface, t["tertiary"], 0.14))

    full = SHAPE["full"]
    xl = SHAPE["xl"]
    m = SHAPE["m"]
    s = SHAPE["s"]

    tl_e = TYPE["title-large-emph"]
    bm = TYPE["body-medium"]
    bl = TYPE["body-large"]
    ll = TYPE["label-large"]
    ll_e = TYPE["label-large-emph"]
    lm = TYPE["label-medium"]

    return f"""
window.background {{ background-color: transparent; }}

.picker-dialog {{
    font-family: "Inter", "Noto Sans CJK SC", sans-serif;
    background-color: {_rgb(sch)};
    border-radius: {xl}px;
    box-shadow: {ELEVATION[3]};
    padding: 24px;
    opacity: 0;
    transition: opacity {DUR_DEFAULT_MS}ms {EASE_EXPRESSIVE_DEFAULT_EFFECTS};
}}
.picker-dialog.revealed {{ opacity: 1; }}

.scrim {{
    background-color: rgba(0,0,0,0.32);
    opacity: 0;
    transition: opacity {DUR_DEFAULT_MS}ms {EASE_EXPRESSIVE_DEFAULT_EFFECTS};
}}
.scrim.revealed {{ opacity: 1; }}

.appbar-title {{
    color: {_rgb(on_surface)};
    font-size: {tl_e[0]}px;
    font-weight: {tl_e[1]};
}}

.count-label {{
    color: {_rgb(t['on_surface_variant'])};
    font-size: {lm[0]}px;
    font-weight: {lm[1]};
    margin-left: 8px;
}}

.icon-btn {{
    min-width: 48px; min-height: 48px; padding: 0;
    background-color: transparent;
    border: none;
}}
.icon-btn > .icon-btn-face {{
    min-width: 40px; min-height: 40px;
    border-radius: {full}px;
    background-color: transparent;
    color: {_rgb(t['on_surface_variant'])};
    transition: background-color {DUR_STATE_MS}ms {EASE_EXPRESSIVE_FAST_EFFECTS};
}}
.icon-btn:hover > .icon-btn-face {{ background-color: {_sl(sch, on_surface, STATE_HOVER)}; }}
.icon-btn:active > .icon-btn-face {{ background-color: {_sl(sch, on_surface, STATE_PRESSED)}; }}

.search {{
    min-height: {search_h}px;
    border-radius: {full}px;
    background-color: {_rgb(scl)};
    padding: 0 24px;
    color: {_rgb(on_surface)};
    font-size: {bl[0]}px;
    caret-color: {_rgb(t['primary'])};
    border: none;
    box-shadow: {ELEVATION[3]};
    transition: background-color {DUR_STATE_MS}ms {EASE_EXPRESSIVE_FAST_EFFECTS};
}}
.search:hover {{ background-color: {_sl(scl, on_surface, STATE_HOVER)}; }}
.search image {{ color: {_rgb(t['on_surface_variant'])}; }}
.search selection {{ background-color: {_rgb(pc)}; color: {_rgb(opc)}; }}

.chip {{
    min-height: {chip_h}px; padding: 0 8px;
    background-color: transparent;
    border: none;
}}
.chip > .chip-face {{
    min-height: 32px; padding: 0 16px;
    border-radius: {s}px;
    background-color: transparent;
    border: 1px solid {_rgb(t['outline_variant'])};
    color: {_rgb(t['on_surface_variant'])};
    font-size: {ll[0]}px; font-weight: {ll[1]};
    transition: border-radius {DUR_FAST_SPATIAL_MS}ms {EASE_EXPRESSIVE_FAST_SPATIAL},
                background-color {DUR_STATE_MS}ms {EASE_EXPRESSIVE_FAST_EFFECTS},
                border-color {DUR_STATE_MS}ms {EASE_EXPRESSIVE_FAST_EFFECTS},
                color {DUR_STATE_MS}ms {EASE_EXPRESSIVE_FAST_EFFECTS};
}}
.chip:hover > .chip-face {{ background-color: {_sl(sch, on_surface, STATE_HOVER)}; }}
.chip:checked > .chip-face {{
    border-radius: {full}px;
    background-color: {_rgb(sc)};
    border-color: {_rgb(sc)};
    color: {_rgb(osc)};
    font-weight: {ll_e[1]};
}}
.chip > .chip-face image {{ color: {_rgb(t['on_surface_variant'])}; }}
.chip:checked > .chip-face image {{ color: {_rgb(osc)}; }}

flowboxchild {{ padding: 0; margin: 0; outline: none; }}

.card {{
    border-radius: {m}px;
    background-color: {_rgb(scl)};
    border: 3px solid transparent;
    padding: 0;
    margin: 0;
    outline: none;
    box-shadow: {ELEVATION[1]};
    transition: background-color {DUR_STATE_MS}ms {EASE_EXPRESSIVE_FAST_EFFECTS},
                border-color {DUR_STATE_MS}ms {EASE_EXPRESSIVE_FAST_EFFECTS},
                box-shadow {DUR_FAST_MS}ms {EASE_EXPRESSIVE_FAST_EFFECTS};
}}
.card:hover {{
    background-color: {_sl(scl, on_surface, STATE_HOVER)};
    box-shadow: {ELEVATION[2]};
}}
.card.current, .card:selected, .card:focus {{
    border-color: {_rgb(t['primary'])};
}}

.thumb {{
    border-radius: {m - 3}px {m - 3}px 0 0;
    background-color: {_rgb(t['surface_container_highest'])};
    min-width: {thumb_w}px;
    min-height: {thumb_h}px;
}}
.card-inner {{ background-color: transparent; }}
.card-info {{ padding: 10px 16px; }}
.card-title {{
    color: {_rgb(on_surface)};
    font-size: {bm[0]}px;
    font-weight: {bm[1]};
}}

.live {{
    background-color: {_rgb(tc)};
    color: {_rgb(otc)};
    font-size: {lm[0]}px;
    font-weight: {lm[1]};
    border-radius: {full}px;
    min-height: 16px;
    padding: 0 4px;
}}

.grid {{ background-color: transparent; }}
.grid-scroll {{ background-color: transparent; border: none; }}
.grid-scroll undershoot, .grid-scroll overshoot {{ background: none; }}
.grid-scroll scrollbar {{ background-color: transparent; }}
.grid-scroll trough {{ background-color: transparent; }}
.grid-scroll slider {{
    background-color: {_rgb(_mix(t['on_surface_variant'], surface, 0.25))};
    border-radius: {full}px;
    min-width: 6px;
    min-height: 32px;
}}

.empty-title {{
    color: {_rgb(on_surface)};
    font-size: {bl[0]}px;
    font-weight: 400;
}}
.empty-hint {{
    color: {_rgb(t['on_surface_variant'])};
    font-size: {bm[0]}px;
}}
.empty image {{ color: {_rgb(t['on_surface_variant'])}; }}

.chip:focus, .icon-btn:focus, .search:focus {{
    outline-width: 2px;
    outline-style: solid;
    outline-color: {_rgb(t['primary'])};
    outline-offset: 2px;
}}
.card:focus {{ background-color: {_sl(scl, on_surface, STATE_FOCUSED)}; }}
"""
