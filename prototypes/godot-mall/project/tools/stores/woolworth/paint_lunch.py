"""Textures for the Woolworth lunch counter (Steven, Oct 20, 2026: the counter on the right that
wraps toward the front, stools along it, the old drug-store fountain things behind it; his two
reference photos: a wood-fronted counter with chrome stools and a cream tiled back wall under a
strip of menu cards, and a curved-end soda fountain with price signs over the back bar).

- tex/wl/lunch_front.png: 1.2 m x 1.0 m, the counter's front: wood-grain panels between black
  pilasters, a black kick at the floor (tiles along the run).
- tex/wl/tile_stripe.png: 1.0 m x 1.0 m, cream 3 x 6 in. wall tile with two brown stripes.
- tex/wl/price_strip.png: 4.0 m x 0.3 m, the menu cards over the back bar: food pictures and
  1995 prices in red on white cards.
Food and prices are invented, of the period; no brand marks.
  python3 tools/stores/woolworth/paint_lunch.py   (from the project folder)
"""
import os, random
import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "..", "tex", "wl")
FONT = os.path.join(HERE, "RobotoSlab-ExtraBold.ttf")


def wood(w, h, seed):
    rng = np.random.default_rng(seed)
    y = np.arange(h)[:, None]
    x = np.arange(w)[None, :]
    grain = np.sin((x * 0.06 + np.sin(y * 0.013 + x * 0.002) * 6.0 + rng.uniform(0, 6))) * 0.5 + 0.5
    base = np.array([168, 112, 62], np.float32)
    dark = np.array([120, 74, 38], np.float32)
    a = base[None, None, :] * (1 - grain[..., None] * 0.35) + dark[None, None, :] * grain[..., None] * 0.35
    a += rng.normal(0, 4, (h, w, 1))
    return a


def lunch_front():
    W, H = 480, 400
    a = wood(W, H, 7)
    im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 14, H], fill=(18, 18, 20))            # a black pilaster at each panel joint
    d.rectangle([W - 14, 0, W, H], fill=(18, 18, 20))
    d.rectangle([0, H - 52, W, H], fill=(18, 18, 20))         # the kick
    d.rectangle([0, 0, W, 10], fill=(40, 30, 24))             # the top lip shadow
    im.save(os.path.join(OUT, "lunch_front.png"), optimize=True)


def tile_stripe():
    W = H = 256
    im = Image.new("RGB", (W, H), (236, 226, 196))
    d = ImageDraw.Draw(im)
    tw, th = W // 5, H // 10
    for r in range(10):
        off = (tw // 2) if r % 2 else 0
        for c in range(-1, 6):
            x0 = c * tw + off
            d.rectangle([x0, r * th, x0 + tw - 2, r * th + th - 2], fill=(238 - (r * 7 + c * 3) % 9, 228 - (r * 5) % 7, 198))
    for yy in (int(H * 0.3), int(H * 0.7)):
        d.rectangle([0, yy, W, yy + th - 2], fill=(122, 72, 44))
    im.save(os.path.join(OUT, "tile_stripe.png"), optimize=True)


ITEMS = [("CHERRY PIE", "99¢", (190, 40, 50)), ("CLUB SANDWICH", "$3.49", (220, 180, 100)), ("BANANA SPLIT", "$2.99", (240, 220, 120)),
         ("HOT DOG", "$1.29", (200, 110, 60)), ("MALTED MILK", "$1.89", (230, 220, 200)), ("GRILLED CHEESE", "$1.79", (230, 170, 60)),
         ("CHILI", "$1.99", (150, 60, 40)), ("ROOT BEER FLOAT", "$2.00", (120, 70, 40)), ("BLT", "$2.49", (90, 160, 70)),
         ("COFFEE", "59¢", (90, 60, 40)), ("ICE CREAM SODA", "$1.59", (240, 200, 210)), ("TURKEY PLATE", "$3.99", (210, 160, 110))]


def price_strip():
    W, H = 1600, 120
    im = Image.new("RGB", (W, H), (30, 30, 32))
    d = ImageDraw.Draw(im)
    n = len(ITEMS)
    cw = W / n
    fs = ImageFont.truetype(FONT, 10)
    fp = ImageFont.truetype(FONT, 30)
    rng = random.Random(5)
    for i, (name, price, col) in enumerate(ITEMS):
        x0 = int(i * cw) + 4
        x1 = int((i + 1) * cw) - 4
        d.rectangle([x0, 6, x1, H - 6], fill=(246, 244, 236))
        # a food picture at the left, the name and price at the right
        d.rounded_rectangle([x0 + 6, 16, x0 + 50, H - 18], radius=6, fill=(200, 210, 220))
        d.ellipse([x0 + 10, 40, x0 + 46, H - 26], fill=col)
        d.ellipse([x0 + 16, 46, x0 + 34, 62], fill=tuple(min(255, c + 50) for c in col))
        d.text(((x0 + 54 + x1) // 2, 34), name, font=fs, fill=(30, 30, 30), anchor="mm")
        d.text(((x0 + 54 + x1) // 2, 78), price, font=fp, fill=(196, 24, 30), anchor="mm")
    im.save(os.path.join(OUT, "price_strip.png"), optimize=True)


if __name__ == "__main__":
    lunch_front()
    tile_stripe()
    price_strip()
    print("ok")
