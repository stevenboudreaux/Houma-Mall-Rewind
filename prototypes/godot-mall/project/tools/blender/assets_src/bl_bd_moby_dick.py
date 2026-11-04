"""Moby-Dick, a cloth-bound classics hardcover from B. Dalton Bookseller (1995 map, store s48). Hand item;
item id `bd_moby_dick` (workstream FOOD, Nov 3 2026).

The real title (Herman Melville, 1851: public domain), per Steven. The edition is invented, with no real
publisher's design or logo: a navy book-cloth case, gold-foil stamping (a double-rule border, the title, a
sperm whale breaching over a line of waves, MELVILLE), gilt bands and the title down the spine, a whale
blind-stamped on the back, a red ribbon marker, red-and-gold headbands, cream endpapers and B. Dalton's own
price sticker on the back (the store's name is its own, allowed). Publisher on the spine: "BAYOU CLASSICS"
(invented).
References: none for the object (no photo of B. Dalton's shelves); design/storefronts/b-dalton.md for the
store. Size: a classics hardcover, 150 x 222 mm, 46 mm thick (the novel runs ~600 pages).
Model: tools/blender/assets_src/_book.py "hard" (shared by the B. Dalton books).
Origin: bottom centre, lying flat, front cover up, the top of the book away from the viewer.
"""
import math
import random
from PIL import Image, ImageDraw, ImageFilter
from lib import labels
import _book as B

W, L, T = 0.150, 0.222, 0.046
PPM = 1800 / L
NAVY = (26, 38, 70)
SEED = 51

META = {
    "id": "bl_bd_moby_dick",
    "class": "hand",
    "tex": 2048,
    "ao": 0.35,
    "refs": [],
    "icon_view": (15, 62),         # from above: the cover reads in the inventory
    "item_file": "food.json",
    "item": {"id": "bd_moby_dick", "name": "Moby-Dick", "year": 1995, "store": "B. DALTON BOOKSELLER", "price": 1495},
}


def whale(d, cx, cy, s, fill, bg=(0, 0, 0, 0)):
    """A sperm whale swimming to the right, side on: the long blunt box of a head (a third of its length),
    the narrow underslung jaw, a small eye, the hump and knuckles along the back, the tail stock rising to
    broad flukes; the bushy forward-leaning spout from the blowhole at the front of the head."""
    P = lambda x, y: (cx + x * s, cy + y * s)
    body = [P(0.95, -0.20), P(1.00, -0.12), P(1.00, 0.02), P(0.94, 0.10), P(0.62, 0.15), P(0.30, 0.17),
            P(-0.10, 0.15), P(-0.45, 0.10), P(-0.72, 0.04), P(-0.88, -0.02), P(-0.94, -0.06),
            P(-0.86, -0.10), P(-0.66, -0.12), P(-0.40, -0.17), P(-0.20, -0.20), P(-0.10, -0.25),   # the hump
            P(0.02, -0.21), P(0.30, -0.22), P(0.62, -0.235)]
    d.polygon(body, fill=fill)
    # flukes, spread wide at the end of the tail stock, a notch in the middle
    d.polygon([P(-0.90, -0.04), P(-1.10, -0.26), P(-1.22, -0.30), P(-1.12, -0.08), P(-1.18, 0.12),
               P(-1.08, 0.12), P(-0.92, 0.02)], fill=fill)
    # the jaw line and mouth, the eye, the wrinkled skin: cut back into the foil (background colour)
    w = max(2, int(s * 0.022))
    d.line([P(0.98, 0.07), P(0.62, 0.10), P(0.36, 0.12)], fill=bg, width=w)
    d.ellipse([*P(0.55, -0.04), *P(0.60, 0.00)], fill=bg)
    for k in range(7):
        x = -0.55 + k * 0.12
        d.line([P(x, -0.06), P(x + 0.05, 0.06)], fill=bg, width=max(1, w // 2))
    # flipper
    d.polygon([P(0.42, 0.13), P(0.30, 0.30), P(0.24, 0.29), P(0.32, 0.14)], fill=fill)
    # the spout: a bushy plume leaning forward from the blowhole
    for k in range(9):
        a = math.radians(-125 + k * 8)
        ln = 0.30 + 0.06 * math.sin(k)
        d.line([P(0.92, -0.22), P(0.92 + ln * math.cos(a), -0.22 + ln * math.sin(a))], fill=fill, width=w)
        d.ellipse([*P(0.92 + ln * math.cos(a) - 0.03, -0.22 + ln * math.sin(a) - 0.03),
                   *P(0.92 + ln * math.cos(a) + 0.03, -0.22 + ln * math.sin(a) + 0.03)], fill=fill)


def waves(d, x0, x1, y, s, fill, width):
    x = x0
    while x < x1:
        d.arc((x, y - s * 0.5, x + s, y + s * 0.5), 180, 360, fill=fill, width=width)
        x += s


def front():
    im, d = B.canvas_for(W, L, PPM)
    g, gd = B.canvas_for(W, L, PPM)
    w, h = im.size
    gold = (255, 255, 255, 255)
    gd.rectangle((40, 40, w - 40, h - 40), outline=gold, width=10)
    gd.rectangle((62, 62, w - 62, h - 62), outline=gold, width=4)
    gd.text((w / 2, h * 0.18), "MOBY-DICK", font=B.ff("BodoniModa-Bold.ttf", w * 0.15), fill=gold, anchor="mm")
    gd.text((w / 2, h * 0.27), "or,  THE  WHALE", font=B.ff("BodoniModa-Bold.ttf", w * 0.055), fill=gold, anchor="mm")
    whale(gd, w * 0.50, h * 0.55, w * 0.28, gold)
    waves(gd, w * 0.14, w * 0.86, h * 0.68, w * 0.07, gold, 6)
    gd.text((w / 2, h * 0.84), "HERMAN MELVILLE", font=B.ff("BodoniModa-Bold.ttf", w * 0.07), fill=gold, anchor="mm")
    gm = g.filter(ImageFilter.GaussianBlur(1.0))
    # the cloth colour comes from the material; the front image only carries the rubbed corners
    B.wear(im, random.Random(SEED), 70, (70, 82, 112))
    return labels.save(im, "bd_moby_front"), labels.save(gm, "bd_moby_front_gilt")


def back():
    im, d = B.canvas_for(W, L, PPM)
    w, h = im.size
    blind = (14, 22, 44, 255)                   # blind stamping: darker, pressed in
    whale(d, w * 0.5, h * 0.48, w * 0.20, blind)
    d.rectangle((40, 40, w - 40, h - 40), outline=blind, width=6)
    st = B.price_sticker("$14.95", 330, 165).rotate(4, expand=True, resample=Image.BICUBIC)
    im.paste(st, (int(w * 0.57), int(h * 0.82)), st)
    B.wear(im, random.Random(SEED + 1), 70, (70, 82, 112))
    return labels.save(im, "bd_moby_back")


def spine():
    im, d = B.spine_canvas(L, T, PPM)
    g, gd = B.spine_canvas(L, T, PPM)
    w, h = im.size
    gold = (255, 255, 255, 255)
    for x in (int(w * 0.05), int(w * 0.08), int(w * 0.92), int(w * 0.95)):
        gd.rectangle((x, 6, x + 7, h - 6), fill=gold)
    gd.text((w * 0.40, h * 0.5), "MOBY-DICK", font=B.ff("BodoniModa-Bold.ttf", h * 0.42), fill=gold, anchor="mm")
    gd.text((w * 0.70, h * 0.5), "MELVILLE", font=B.ff("BodoniModa-Bold.ttf", h * 0.30), fill=gold, anchor="mm")
    gd.text((w * 0.86, h * 0.5), "BAYOU CLASSICS", font=B.ff("BodoniModa-Bold.ttf", h * 0.16), fill=gold, anchor="mm")
    # cracks across the spine cloth where it has flexed
    rng = random.Random(SEED + 2)
    for k in range(6):
        x = rng.randint(int(w * 0.12), int(w * 0.88))
        d.line([(x + rng.randint(-5, 5), y) for y in range(0, h + 1, max(1, h // 4))], fill=(60, 72, 104, 255), width=2)
    return labels.save(im, "bd_moby_spine"), labels.save(g.filter(ImageFilter.GaussianBlur(1.0)), "bd_moby_spine_gilt")


def build():
    f, fg = front()
    s, sg = spine()
    B.build_book("hard", W, L, T, f, back(), s, base="#1a2646", rough=0.62, cloth=True,
                 gilt={"front": fg, "spine": sg}, endpaper="#efe4c8", ribbon="#a01820")
