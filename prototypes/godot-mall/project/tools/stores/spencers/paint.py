"""Textures for Spencer's walk-in store (2026 map, store n35; tools/stores/spencers/store.gd), written to
tex/spencers/. Fixtures and finishes from the video Steven chose (refs/new/spencers, design/storefronts/spencers.md);
the merchandise is invented and generic: the video is full of licensed characters, brand logos and
packaging, and none of it is copied (IP rule).

  python3 tools/stores/spencers/paint.py   (from the project folder)
"""
import math, os, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "..", "tex", "spencers")
os.makedirs(OUT, exist_ok=True)
BOLD = "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf"
R = random.Random(35)
RN = np.random.default_rng(35)
NEON = [(240, 60, 120), (60, 220, 120), (250, 220, 40), (60, 170, 250), (170, 80, 240), (250, 130, 40), (245, 245, 240)]


def save(im, name):
    im.convert("RGB").save(os.path.join(OUT, name + ".png"), optimize=True)


def noise(im, amt=3.0):
    a = np.asarray(im.convert("RGB")).astype(np.float32)
    a += RN.normal(0, amt, a.shape)
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


def jit(c, k=10):
    return tuple(max(0, min(255, v + R.randint(-k, k))) for v in c)


def concrete():
    """The stained concrete floor (spencers_t000_011, 049-051, 129-145): mottled amber-brown with darker
    clouds and a sheen. One tile = 4 m."""
    W = 512
    a = RN.normal(0, 1, (W // 16, W // 16)).astype(np.float32)
    im = Image.fromarray(((a - a.min()) / (a.max() - a.min()) * 255).astype(np.uint8)).resize((W, W), Image.BICUBIC)
    m = np.asarray(im).astype(np.float32) / 255.0
    b2 = np.asarray(Image.fromarray(((RN.normal(0, 1, (W // 4, W // 4)) * 40 + 128).clip(0, 255)).astype(np.uint8)).resize((W, W), Image.BICUBIC)).astype(np.float32) / 255.0
    lo = np.array([92, 58, 30], np.float32)
    hi = np.array([176, 120, 64], np.float32)
    t = (m * 0.7 + b2 * 0.3)[..., None]
    rgb = lo + (hi - lo) * t
    out = Image.fromarray(rgb.clip(0, 255).astype(np.uint8))
    d = ImageDraw.Draw(out)
    for _ in range(14):      # saw cuts and hairline cracks
        x0, y0 = R.uniform(0, W), R.uniform(0, W)
        d.line([(x0, y0), (x0 + R.uniform(-80, 80), y0 + R.uniform(-80, 80))], fill=(70, 44, 24), width=1)
    d.line([(0, W - 1), (W, W - 1)], fill=(60, 40, 24), width=2)
    save(noise(out, 3), "concrete")


def tee_grid():
    """The wall of framed tees (027, 257): black frames, a printed tee in each (invented graphics: stars,
    stripes, a skull-ish moon, flames, block words). 4 x 4 frames per 2.4 m x 2.4 m tile."""
    W = 1024
    im = Image.new("RGB", (W, W), (18, 18, 20))
    d = ImageDraw.Draw(im)
    c = W // 4
    words = ["BAYOU", "NOPE", "LOUD", "2026", "GATOR", "STATIC", "GLOW", "WILD"]
    f = ImageFont.truetype(BOLD, 34)
    for j in range(4):
        for i in range(4):
            x0, y0 = i * c, j * c
            d.rectangle([x0 + 8, y0 + 8, x0 + c - 8, y0 + c - 8], fill=(30, 30, 32), outline=(8, 8, 8), width=8)
            tee = jit(R.choice([(20, 20, 22), (20, 20, 22), (240, 240, 236), (200, 40, 60), (60, 70, 160), (90, 140, 80), (240, 170, 200)]), 6)
            cx = x0 + c // 2
            d.polygon([(cx - 70, y0 + 60), (cx - 30, y0 + 44), (cx + 30, y0 + 44), (cx + 70, y0 + 60), (cx + 88, y0 + 96), (cx + 58, y0 + 108),
                       (cx + 58, y0 + c - 34), (cx - 58, y0 + c - 34), (cx - 58, y0 + 108), (cx - 88, y0 + 96)], fill=tee)
            ink = R.choice([n for n in NEON if abs(sum(n) - sum(tee)) > 200] or [(250, 220, 40)])
            k = (i + j * 3) % 5
            if k == 0:
                for s in range(5):
                    a = s / 5 * 6.28 - 1.57
                    d.polygon([(cx + math.cos(a) * 34, y0 + 140 + math.sin(a) * 34), (cx + math.cos(a + 0.6) * 14, y0 + 140 + math.sin(a + 0.6) * 14),
                               (cx + math.cos(a - 0.6) * 14, y0 + 140 + math.sin(a - 0.6) * 14)], fill=ink)
            elif k == 1:
                w = d.textlength(R.choice(words), font=f)
                d.text((cx - 50, y0 + 120), R.choice(words), font=f, fill=ink)
            elif k == 2:
                d.ellipse([cx - 32, y0 + 106, cx + 32, y0 + 170], fill=ink)
                d.ellipse([cx - 18, y0 + 124, cx - 4, y0 + 138], fill=tee)
                d.ellipse([cx + 4, y0 + 124, cx + 18, y0 + 138], fill=tee)
            elif k == 3:
                for s in range(4):
                    d.rectangle([cx - 40, y0 + 108 + s * 16, cx + 40, y0 + 114 + s * 16], fill=ink)
            else:
                for s in range(5):
                    x = cx - 36 + s * 18
                    d.polygon([(x, y0 + 176), (x + 9, y0 + 112 + R.randint(0, 20)), (x + 18, y0 + 176)], fill=ink)
            d.rectangle([x0 + 20, y0 + c - 30, x0 + 70, y0 + c - 16], fill=(250, 250, 250))
    save(noise(im, 2), "tee_grid")


def corrugated():
    """Galvanized corrugated panels with peg hooks of carded goods (063-073): sticker packs, keychains,
    pins, all invented (bright blocks, no characters). 2.4 x 2.4 m."""
    W = 1024
    im = Image.new("RGB", (W, W), (150, 152, 154))
    d = ImageDraw.Draw(im)
    for x in range(0, W, 16):
        d.rectangle([x, 0, x + 7, W], fill=(176, 178, 180))
        d.line([(x + 8, 0), (x + 8, W)], fill=(120, 122, 124), width=2)
    f = ImageFont.truetype(BOLD, 16)
    for j in range(6):
        for i in range(9):
            x0, y0 = 14 + i * 112, 30 + j * 166
            d.line([(x0 + 44, y0 - 18), (x0 + 44, y0 + 6)], fill=(60, 60, 64), width=3)
            for s in range(3):
                col = jit(R.choice(NEON + [(30, 30, 32)]), 8)
                d.rectangle([x0 + s * 4, y0 + s * 10, x0 + 88 + s * 4, y0 + 120 + s * 10], fill=col)
                d.rectangle([x0 + s * 4, y0 + s * 10, x0 + 88 + s * 4, y0 + 26 + s * 10], fill=(20, 20, 22))
            k = (i + j) % 4
            cx, cy = x0 + 52, y0 + 92
            ink = (250, 250, 250)
            if k == 0:
                d.text((x0 + 14, y0 + 30), "STICKER", font=f, fill=ink)
            elif k == 1:
                d.ellipse([cx - 22, cy - 22, cx + 22, cy + 22], outline=ink, width=6)
            elif k == 2:
                d.polygon([(cx, cy - 26), (cx + 24, cy + 18), (cx - 24, cy + 18)], fill=ink)
            else:
                d.rectangle([cx - 20, cy - 16, cx + 20, cy + 16], outline=ink, width=5)
    save(noise(im, 2), "corrugated")


def mugwall():
    """The back of the mug and tumbler shelving: black, with the red shelf-edge strips' labels printed
    white (MUGS, TUMBLERS: 169-185). 1.2 x 0.06 m strip, 4 words across."""
    W, H = 1024, 64
    im = Image.new("RGB", (W, H), (200, 24, 40))
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(BOLD, 34)
    for k, t in enumerate(["MUGS", "TUMBLERS", "MUGS", "GIFTS"]):
        x0 = k * 256
        w = d.textlength(t, font=f)
        d.text((x0 + 128 - w / 2, 12), t, font=f, fill=(255, 255, 255))
    save(im, "strip")


def folded():
    """Folded tees stacked on the gondola and table shelves, seen from the front (019-021, 205-209):
    piles of black, grey, white, red and pastel tees with a printed corner showing. 1.2 x 0.4 m."""
    W, H = 512, 170
    im = Image.new("RGB", (W, H), (40, 30, 22))
    d = ImageDraw.Draw(im)
    x = 4
    while x < W - 40:
        w = R.randint(70, 96)
        y = H
        base = jit(R.choice([(20, 20, 22), (20, 20, 22), (90, 90, 96), (236, 236, 232), (190, 40, 50), (230, 170, 200), (90, 160, 140), (40, 60, 140)]), 6)
        for k in range(R.randint(6, 9)):
            hh = R.randint(14, 18)
            c = jit(base, 5)
            d.rectangle([x, y - hh, x + w, y - 2], fill=c)
            d.line([(x, y - 2), (x + w, y - 2)], fill=tuple(int(v * 0.7) for v in c), width=2)
            if k % 2 == 0:
                d.rectangle([x + w * 0.3, y - hh + 3, x + w * 0.6, y - 5], fill=R.choice(NEON))
            y -= hh
        x += w + R.randint(4, 10)
    save(noise(im, 2), "folded")


if __name__ == "__main__":
    concrete(); tee_grid(); corrugated(); mugwall(); folded()
    print("wrote", sorted(f for f in os.listdir(OUT) if f.endswith(".png")))
