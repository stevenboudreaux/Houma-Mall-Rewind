"""Textures for the playable COIN COMET page (play/pusher.html, workstream P, Nov 2026).

Re-encodes the cabinet's own textures (paint_pusher.py, tex/pc/pusher_*.png) so the game page shows the same marquee,
space translite, coin band, coin mechanism, front doors and side panels as the mall's cabinet,
and paints two of its own: a single quarter's faces (heads/tails, generic, no real coin art) for
the physics coins, and a brushed-steel tile for the deck and shelf. Writes play/pusher/*.webp.
Run from the project folder:
    python3 tools/stores/pocket_change/paint_pusher_game.py
"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import paint_pusher as pp

OUT = os.path.abspath(os.path.join(HERE, "..", "..", "..", "..", "play", "pusher"))
os.makedirs(OUT, exist_ok=True)


def save(im, name, colors=0):
    p = os.path.join(OUT, name + ".webp")
    if im.mode not in ("RGB", "RGBA"):
        im = im.convert("RGBA")
    im.save(p, "WEBP", quality=86, method=6)
    print(name, im.size, os.path.getsize(p))


def paint_quarter():
    """A quarter's two faces side by side, 512 x 256: a generic reeded silver coin with a
    laurel-ish wreath on one side and a star ring on the other (no real coin's art). The
    page maps the left half to the top face and the right half to the bottom face."""
    W, H = 512, 256
    S = 2
    w, h = W * S, H * S
    im = Image.new("RGB", (w, h), (120, 122, 128))
    rng = np.random.RandomState(7)
    for k in range(2):
        cx, cy, r = w // 4 + k * w // 2, h // 2, h // 2 - 4
        # a soft radial silver with a brushed grain
        yy, xx = np.mgrid[0:h, 0:w // 2].astype(np.float32)
        d = np.sqrt((xx - w // 4) ** 2 + (yy - cy) ** 2) / r
        base = 196 - 26 * d ** 2 + rng.normal(0, 4, (h, w // 2))
        ang = np.arctan2(yy - cy, xx - w // 4)
        base += 10 * np.cos(ang * 2 + 0.6) * (1 - d)        # a slight specular bias
        a = np.stack([base * 0.99, base, base * 1.03], -1).clip(0, 255)
        face = Image.fromarray(a.astype(np.uint8))
        im.paste(face, (k * w // 2, 0))
        dr = ImageDraw.Draw(im)
        col_d, col_l = (128, 130, 136), (232, 234, 238)
        # rim
        dr.ellipse([cx - r, cy - r, cx + r, cy + r], outline=col_l, width=6)
        dr.ellipse([cx - r + 8, cy - r + 8, cx + r - 8, cy + r - 8], outline=col_d, width=3)
        if k == 0:
            # a wreath: two arcs of small leaves, a bust-like oval in the middle (featureless)
            dr.ellipse([cx - r * 0.26, cy - r * 0.42, cx + r * 0.26, cy + r * 0.36], fill=(176, 178, 184), outline=col_d, width=3)
            dr.ellipse([cx - r * 0.2, cy - r * 0.3, cx + r * 0.2, cy + r * 0.2], fill=(188, 190, 196))
            for side in (-1, 1):
                for i in range(9):
                    t = -0.95 + i * 0.22
                    x = cx + side * r * (0.62 - 0.12 * t * t)
                    y = cy + r * t * 0.72
                    dr.ellipse([x - 16, y - 9, x + 16, y + 9], fill=(170, 172, 178), outline=col_d, width=2)
            for i, y in enumerate((cy - r * 0.8, cy + r * 0.78)):
                dr.rectangle([cx - r * 0.3, y - 7, cx + r * 0.3, y + 7], fill=(172, 174, 180), outline=col_d, width=2)
        else:
            # a ring of 13 stars round a rising comet (the game's own motif) on a plain field
            for i in range(13):
                a0 = -np.pi / 2 + i * 2 * np.pi / 13
                pp.star(dr, cx + r * 0.78 * np.cos(a0), cy + r * 0.78 * np.sin(a0), 14, (170, 172, 178), outline=col_d, width=2)
            dr.ellipse([cx - r * 0.16, cy - r * 0.16, cx + r * 0.16, cy + r * 0.16], fill=(176, 178, 184), outline=col_d, width=3)
            for i in range(3):
                dr.line([cx + 10, cy - 10, cx - r * (0.42 + i * 0.06), cy + r * (0.25 + i * 0.12)], fill=(176, 178, 184), width=max(2, 10 - i * 3))
            dr.rectangle([cx - r * 0.3, cy + r * 0.5 - 7, cx + r * 0.3, cy + r * 0.5 + 7], fill=(172, 174, 180), outline=col_d, width=2)
    im = im.filter(ImageFilter.GaussianBlur(0.9))
    return im.resize((W, H), Image.LANCZOS)


def paint_steel():
    """A brushed-steel tile, 256 x 256, for the deck and the shelf."""
    W = 256
    rng = np.random.RandomState(3)
    a = 150 + rng.normal(0, 3, (W, W)).cumsum(1) * 0.3
    a = a - a.mean(1, keepdims=True) + 150 + rng.normal(0, 2, (W, 1))
    a = np.stack([a * 0.99, a, a * 1.02], -1).clip(0, 255).astype(np.uint8)
    return Image.fromarray(a)


# the cabinet's own textures, re-encoded (as paint_skeeball_game.py does): the painters need
# fonts the cloud lacks, and the mall's copies are the ones the player has already seen
TEX = os.path.join(pp.OUT)
for k in ("marquee", "back", "front", "side", "band", "mech", "inner", "ramp", "perf", "glass", "coins", "edge"):
    save(Image.open(os.path.join(TEX, "pusher_%s.png" % k)), k)
save(paint_quarter(), "quarter")
save(paint_steel(), "steel")
