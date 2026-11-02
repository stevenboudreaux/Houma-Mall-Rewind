"""Fabric textures (procedural, tileable, 256 px, grey so the material tint is the colour) and the
piece materials. Every piece has up to three tintable colour regions:
  main    the cloth (fabric texture x tint)
  trim    cuffs, waistbands, collars, hems, soles (rib / same fabric, own tint)
  accent  plackets, buttons, buckles, name tags (plain, own tint)
Base-layer pieces also take a PATTERN (manifest "patterns": solid / stripes / dots / floral /
check), an albedo texture B2 swaps in, still tinted.
UV scale: piece UVs are the body atlas' (about 1.6 m per unit); fab_scale() says how many repeats.
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mh  # noqa: E402

OUT = os.path.join(mh.PROJ, "models", "characters")
S = 256
SCALE = {"knit": 180, "rib": 120, "lace": 40, "satin": 30, "woven": 110, "pique": 150, "oxford": 150, "plaid": 11, "fleece": 120,
         "cable": 28, "denim": 140, "twill": 140, "mesh": 70, "canvas": 110, "leather": 40, "rubber": 60}
PATTERNS = ["solid", "stripes", "dots", "floral", "check"]


def _save(a, name):
    from PIL import Image
    a = np.clip(a, 0, 1)
    if a.ndim == 2:
        a = np.stack([a] * 3, -1)
    Image.fromarray((a * 255 + 0.5).astype(np.uint8)).save(os.path.join(OUT, name), optimize=True)


def _normal(h, k):
    gy, gx = np.gradient(np.pad(h, 1, mode="wrap"))
    gx, gy = gx[1:-1, 1:-1], gy[1:-1, 1:-1]
    n = np.stack([-gx * k, gy * k, np.ones_like(h)], -1)
    return n / np.linalg.norm(n, axis=-1, keepdims=True) * 0.5 + 0.5


def _noise(seed, f):
    rng = np.random.default_rng(seed)
    g = rng.random((f, f))
    from PIL import Image
    im = Image.fromarray((g * 255).astype(np.uint8)).resize((S, S), Image.BICUBIC)
    return np.asarray(im, np.float32) / 255


def heights():
    y, x = np.mgrid[0:S, 0:S] / S * 2 * np.pi
    H = {}
    H["knit"] = 0.5 + 0.5 * np.sin(x * 16 + np.sin(y * 32) * 0.8) * np.abs(np.sin(y * 32))
    H["rib"] = 0.5 + 0.5 * np.sin(x * 12)
    H["pique"] = 0.5 + 0.5 * np.sin(x * 20) * np.sin(y * 20)
    H["oxford"] = 0.5 + 0.25 * np.sin(x * 32) + 0.25 * np.sin(y * 32)
    H["woven"] = 0.5 + 0.25 * np.sin(x * 24) * np.sign(np.sin(y * 24)) + 0.25 * np.sin(y * 24)
    H["twill"] = 0.5 + 0.5 * np.sin((x + y) * 20)
    H["denim"] = 0.5 + 0.4 * np.sin((x * 2 + y) * 14) + 0.1 * (_noise(3, 64) - 0.5)
    H["fleece"] = _noise(5, 96) * 0.7 + _noise(6, 32) * 0.3
    H["cable"] = 0.5 + 0.5 * np.abs(np.sin(x * 4 + np.sin(y * 8) * 0.9)) * (0.6 + 0.4 * np.sin(y * 32))
    H["mesh"] = (np.sin(x * 12) * np.sin(y * 12) > 0.3).astype(float)
    H["canvas"] = 0.5 + 0.25 * np.sin(x * 28) + 0.25 * np.sin(y * 28) + 0.1 * (_noise(8, 64) - 0.5)
    H["leather"] = _noise(9, 48) * 0.5 + _noise(10, 128) * 0.5
    H["rubber"] = 0.5 + 0.5 * np.sign(np.sin(x * 10)) * 0.3
    H["satin"] = 0.5 + 0.05 * np.sin(x * 4)
    lace = np.zeros((S, S))
    for k in range(5):
        cx, cy = (k % 3) * S / 2.5 + 30, (k // 3) * S / 2 + 60
        rr = np.hypot(np.mgrid[0:S, 0:S][1] - cx, np.mgrid[0:S, 0:S][0] - cy)
        lace += (np.abs(np.sin(rr / 6)) > 0.85) * (rr < 50)
    H["lace"] = np.clip(lace + 0.4 * (np.sin(x * 40) * np.sin(y * 40) > 0.6), 0, 1)
    H["plaid"] = 0.5 + 0.05 * np.sin((x + y) * 40)
    return H


def albedo(name, h):
    if name == "plaid":
        y, x = np.mgrid[0:S, 0:S] / S
        bands = lambda t: 0.55 * ((t * 4) % 1 < 0.45) + 0.25 * ((t * 4 + 0.6) % 1 < 0.08) + 0.2 * ((t * 8) % 1 < 0.06)
        a = 1 - 0.55 * np.clip(bands(x) + bands(y) - bands(x) * bands(y), 0, 1)
        return a * (0.92 + 0.08 * h)
    if name == "denim":
        return 0.86 + 0.14 * h
    if name == "lace":
        return 0.75 + 0.25 * h
    return 0.92 + 0.08 * h


def patterns():
    y, x = np.mgrid[0:S, 0:S] / S
    P = {"solid": np.ones((S, S)),
         "stripes": 0.55 + 0.45 * ((y * 6) % 1 < 0.5),
         "dots": 1 - 0.5 * (np.hypot((x * 6) % 1 - 0.5, (y * 6) % 1 - 0.5) < 0.18),
         "check": 1 - 0.45 * (((x * 4) % 1 < 0.5) ^ ((y * 4) % 1 < 0.5))}
    fl = np.ones((S, S))
    rng = np.random.default_rng(12)
    for _ in range(9):
        cx, cy = rng.random(2)
        for px in (-1, 0, 1):
            for py in (-1, 0, 1):
                d = np.hypot(x - cx - px, y - cy - py); a = np.arctan2(y - cy - py, x - cx - px)
                fl -= 0.45 * (d < 0.06 * (0.6 + 0.4 * np.abs(np.cos(a * 2.5))))
                fl -= 0.25 * ((d > 0.075) & (d < 0.085))
    P["floral"] = np.clip(fl, 0.3, 1)
    return P


def textures():
    os.makedirs(OUT, exist_ok=True)
    for n, h in heights().items():
        _save(albedo(n, h), "fab_%s_albedo.png" % n)
        _save(_normal(h, {"satin": 0.5, "leather": 1.2}.get(n, 1.6)), "fab_%s_normal.png" % n)
    for n, p in patterns().items():
        _save(p, "pattern_%s.png" % n)


ROUGH = {"satin": 0.35, "leather": 0.45, "rubber": 0.8, "lace": 0.6, "denim": 0.85, "fleece": 0.95}


def materials(pid, tex, default, trim_tex=None, accent="#d8d4c8"):
    trim_tex = trim_tex or ("rib" if tex in ("knit", "fleece", "cable", "pique") else tex)
    return {
        "main": {"albedo": "fab_%s_albedo.png" % tex, "normal": "fab_%s_normal.png" % tex, "rough": ROUGH.get(tex, 0.8), "double": True,
                 "color": hexc(default), "extras": {"tint": "main", "label": "main colour", "default": default, "uv_scale": SCALE[tex], "fabric": tex}},
        "trim": {"albedo": "fab_%s_albedo.png" % trim_tex, "normal": "fab_%s_normal.png" % trim_tex, "rough": ROUGH.get(trim_tex, 0.8), "double": True,
                 "color": hexc(default), "extras": {"tint": "trim", "label": "trim colour", "default": default, "uv_scale": SCALE[trim_tex], "fabric": trim_tex}},
        "accent": {"rough": 0.5, "color": hexc(accent), "extras": {"tint": "accent", "label": "accent colour", "default": accent}},
    }


def hexc(h):
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c] + [1.0]
