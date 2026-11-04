#!/usr/bin/env python3
"""Labelled stand-in items for the shops (workstream SHOPS, design/godot-shops.md).

Workstream FOOD is modelling the real food, drinks and books in Blender. Until a model lands, a shop
sells a stand-in: a few primitive shapes of about the right size and colour, a small "STAND-IN" tag
over it, and a 256 px icon with a yellow STAND-IN band. Book covers and the RadioShack shelf goods get
a painted front (invented titles and the invented VOLTARO brand: no real product, title art or logo,
except Moby-Dick, which keeps its real title: public domain).

Writes, run from the project folder (python3 tools/shops/make_standins.py):
  models/bl_standin_<key>/<id>.tscn          the model (primitives; in the shared `items` pack, glob models/bl_*)
  models/bl_standin_<key>/<id>_icon.png      the icon
  models/bl_standin_<key>/<id>_front.png     a painted front, where it has one
  data/items/shop_standins.json              the item entries (year 1995, no place: bought, never lying about)
Then `godot --headless --path . --import` once for the PNGs.

When FOOD's model lands: point the shop at FOOD's id in data/story/shops.json and delete the stand-in here.
"""
import json
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SANS = os.path.join(ROOT, "fonts", "sans.otf")
SERIF = os.path.join(ROOT, "fonts", "serif.ttf")
YELLOW = (246, 210, 40)


def font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", size)


def hexc(c):
    c = c.lstrip("#")
    return tuple(int(c[i:i + 2], 16) for i in (0, 2, 4))


# ------------------------------------------------------------------ the stand-ins
# parts: [shape, size, pos, colour, (rot)] in metres, origin at the bottom centre, front +z.
#   box: size [x, y, z]; cyl: size [radius, height]; "rotz": lie a cylinder on its side (along x).
# front: a painted face on the box's +z side: {"w", "h", "y", "z", "kind", ...}.
BOOK = (0.108, 0.175, 0.014)
STANDINS = [
    {"id": "standin_wl_hotdog", "name": "Hot dog", "class": "hand", "store": "WOOLWORTH", "for": "FOOD (Woolworth hot dog)",
     "parts": [["box", [0.19, 0.035, 0.075], [0, 0, 0], "#f4f0e6"], ["cyl", [0.026, 0.16], [0, 0.055, 0], "#d9a25a", "rotz"],
               ["cyl", [0.014, 0.185], [0, 0.072, 0], "#a8442a", "rotz"]],
     "icon": "hotdog"},
    {"id": "standin_wl_hamburger", "name": "Hamburger", "class": "hand", "store": "WOOLWORTH", "for": "FOOD (Woolworth hamburger)",
     "parts": [["cyl", [0.075, 0.01], [0, 0, 0], "#f4f0e6"], ["cyl", [0.05, 0.022], [0, 0.01, 0], "#d9a25a"],
               ["cyl", [0.053, 0.014], [0, 0.032, 0], "#5a3420"], ["cyl", [0.054, 0.004], [0, 0.046, 0], "#e8b830"],
               ["cyl", [0.05, 0.03], [0, 0.05, 0], "#d9a25a"]],
     "icon": "burger"},
    {"id": "standin_wl_fries", "name": "French fries", "class": "hand", "store": "WOOLWORTH", "for": "FOOD (Woolworth French fries)",
     "parts": [["box", [0.075, 0.1, 0.04], [0, 0, 0], "#c81e28"], ["box", [0.065, 0.045, 0.03], [0, 0.1, 0], "#f0c850"]],
     "icon": "fries", "icon_col": "#c81e28"},
    {"id": "standin_wl_coffee", "name": "Coffee", "class": "hand", "store": "WOOLWORTH", "for": "FOOD (Woolworth coffee)",
     "parts": [["cyl", [0.07, 0.01], [0, 0, 0], "#f4f0e6"], ["cyl", [0.04, 0.085], [0, 0.01, 0], "#f4f0e6"],
               ["cyl", [0.036, 0.003], [0, 0.093, 0], "#3a2416"]],
     "icon": "coffee"},
    {"id": "standin_cd7_fries", "name": "Crinkle-cut fries", "class": "hand", "store": "CORN DOG 7", "for": "FOOD (Corn Dog 7 crinkle-cut fries)",
     "parts": [["box", [0.08, 0.1, 0.045], [0, 0, 0], "#1b2466"], ["box", [0.07, 0.05, 0.035], [0, 0.1, 0], "#f2cc44"]],
     "icon": "fries", "icon_col": "#1b2466"},
    {"id": "standin_cd7_lemonade", "name": "Lemonade", "class": "hand", "store": "CORN DOG 7", "for": "FOOD (Corn Dog 7 lemonade)",
     "parts": [["cyl", [0.045, 0.15], [0, 0, 0], "#f6dc2c"], ["cyl", [0.047, 0.008], [0, 0.15, 0], "#f4f4f0"],
               ["cyl", [0.004, 0.09], [0.012, 0.158, 0], "#c81e28"]],
     "icon": "cup"},
    # B. Dalton: Moby-Dick keeps its title; the others are invented stand-ins for the kinds Steven named
    {"id": "standin_bd_moby_dick", "name": "Moby-Dick", "class": "pocket", "store": "B. DALTON BOOKSELLER", "for": "FOOD/books (Moby-Dick)",
     "book": [0.106, 0.172, 0.03], "cover": {"bg": "#1c2c44", "fg": "#f2ead6", "accent": "#7a9cc0", "title": ["MOBY-DICK"], "sub": "or, The Whale",
                                            "author": "HERMAN MELVILLE", "art": "whale"}},
    {"id": "standin_bd_which_way", "name": "Which Way Now? #12: Lost on Bayou Noir", "class": "pocket", "store": "B. DALTON BOOKSELLER",
     "for": "books (a Choose Your Own Adventure-type book; invented series)",
     "book": [0.106, 0.172, 0.01], "cover": {"bg": "#f2f0ea", "fg": "#c81e28", "accent": "#1b5a8a", "title": ["WHICH WAY", "NOW?"], "sub": "#12  LOST ON BAYOU NOIR",
                                             "author": "YOU DECIDE WHAT HAPPENS!", "art": "arrows"}},
    {"id": "standin_bd_jupiter", "name": "Husbands Are from Jupiter, Wives Are from Saturn", "class": "pocket", "store": "B. DALTON BOOKSELLER",
     "for": "books (a Men Are from Mars-type book; invented title)",
     "book": [0.14, 0.215, 0.025], "cover": {"bg": "#1a1438", "fg": "#f6e7b8", "accent": "#e0782a", "title": ["HUSBANDS ARE", "FROM JUPITER,", "WIVES ARE", "FROM SATURN"],
                                            "sub": "A Practical Guide to Talking Again", "author": "DR. LEONARD MARCHAND", "art": "planets"}},
    {"id": "standin_bd_long_hall", "name": "Down a Long, Long Hall and Other Shivery Stories", "class": "pocket", "store": "B. DALTON BOOKSELLER",
     "for": "books (an In a Dark, Dark Room-type book; invented title)",
     "book": [0.15, 0.22, 0.008], "cover": {"bg": "#2a3a2a", "fg": "#f4ecc8", "accent": "#d8c040", "title": ["DOWN A LONG,", "LONG HALL"],
                                           "sub": "and Other Shivery Stories", "author": "RETOLD BY NELL BRISTOW", "art": "hall"}},
    # RadioShack shelf goods (the store's painted shelves; tools/stores/small/paint_rs.py): the invented VOLTARO brand
    {"id": "standin_rs_corded_phone", "name": "Corded telephone", "class": "hand", "store": "RADIO SHACK", "for": "a model (RadioShack shelf: corded phone)",
     "rs": [0.1, 0.07, 0.22, "#ece6da", "phone"]},
    {"id": "standin_rs_answering_machine", "name": "Answering machine", "class": "hand", "store": "RADIO SHACK", "for": "a model (RadioShack shelf: answering machine)",
     "rs": [0.2, 0.06, 0.15, "#2a2a2c", "tape"]},
    {"id": "standin_rs_clock_radio", "name": "Clock radio", "class": "hand", "store": "RADIO SHACK", "for": "a model (RadioShack shelf: clock radio)",
     "rs": [0.24, 0.08, 0.12, "#2a2a2c", "clock"]},
    {"id": "standin_rs_cell_phone", "name": "Cellular phone", "class": "hand", "store": "RADIO SHACK", "for": "a model (RadioShack shelf: cellular phone)",
     "rs": [0.055, 0.17, 0.03, "#1c1c1e", "cell"]},
    {"id": "standin_rs_9v_battery", "name": "9-volt battery", "class": "pocket", "store": "RADIO SHACK", "for": "a model (RadioShack: 9V alkaline)",
     "rs": [0.07, 0.12, 0.02, "#c81e28", "9v"]},
    {"id": "standin_rs_c_batteries", "name": "C batteries, 2-pack", "class": "pocket", "store": "RADIO SHACK", "for": "a model (RadioShack: C/D alkaline 2-pack)",
     "rs": [0.09, 0.14, 0.03, "#c81e28", "c"]},
    {"id": "standin_rs_ic_card", "name": "Timer chip (blister card)", "class": "pocket", "store": "RADIO SHACK", "for": "a model (RadioShack pegboard parts: ICs)",
     "rs": [0.08, 0.12, 0.012, "#f2f2ee", "ic"]},
    {"id": "standin_rs_plug_adapter", "name": "Plug adapter", "class": "pocket", "store": "RADIO SHACK", "for": "a model (RadioShack pegboard parts: plugs and adapters)",
     "rs": [0.08, 0.12, 0.015, "#f2f2ee", "plug"]},
    {"id": "standin_rs_ac_adapter", "name": "AC adapter", "class": "hand", "store": "RADIO SHACK", "for": "a model (RadioShack: AC adapter, boxed)",
     "rs": [0.1, 0.13, 0.07, "#2a2a2c", "ac"]},
    {"id": "standin_rs_speaker_wire", "name": "Speaker wire (spool)", "class": "hand", "store": "RADIO SHACK", "for": "a model (RadioShack wire wall: a spool)",
     "spool": True},
]


def folder(e):
    return "models/bl_standin_" + e["id"][len("standin_"):]


# ------------------------------------------------------------------ painting
def band(im, text="STAND-IN"):
    d = ImageDraw.Draw(im)
    W, H = im.size
    h = H // 7
    d.rectangle([0, H - h, W, H], fill=YELLOW + (255,))
    d.text((W // 2, H - h // 2), text, font=font(SANS, int(h * 0.7)), fill=(20, 20, 20, 255), anchor="mm")


def fit_text(d, xy, text, fpath, size, fill, maxw):
    while size > 8:
        f = font(fpath, size)
        if d.textlength(text, font=f) <= maxw:
            break
        size -= 1
    d.text(xy, text, font=f, fill=fill, anchor="mm")
    return size


def cover(e, W=512):
    c = e["cover"]
    bw, bh, _ = e["book"]
    H = int(W * bh / bw)
    im = Image.new("RGBA", (W, H), hexc(c["bg"]) + (255,))
    d = ImageDraw.Draw(im)
    fg, ac = hexc(c["fg"]), hexc(c["accent"])
    art = c["art"]
    if art == "whale":
        d.rectangle([0, int(H * 0.55), W, H], fill=(34, 58, 88, 255))
        d.ellipse([int(W * 0.15), int(H * 0.5), int(W * 0.85), int(H * 0.72)], fill=(226, 224, 214, 255))
        d.polygon([(int(W * 0.82), int(H * 0.58)), (int(W * 0.97), int(H * 0.5)), (int(W * 0.95), int(H * 0.68))], fill=(226, 224, 214, 255))
        for i in range(6):
            y = int(H * 0.74) + i * 18
            d.arc([-40 + i * 30, y, W // 2 + i * 30, y + 40], 200, 340, fill=ac + (255,), width=3)
    elif art == "arrows":
        d.rectangle([0, 0, W, int(H * 0.08)], fill=ac + (255,))
        d.rectangle([0, int(H * 0.92), W, H], fill=ac + (255,))
        d.rectangle([int(W * 0.12), int(H * 0.45), int(W * 0.88), int(H * 0.82)], fill=(60, 110, 70, 255))
        for k, (x, y) in enumerate([(0.3, 0.55), (0.7, 0.55), (0.5, 0.72)]):
            cx, cy = int(W * x), int(H * y)
            d.polygon([(cx - 30, cy + 20), (cx, cy - 30), (cx + 30, cy + 20)], fill=(246, 210, 40, 255))
    elif art == "planets":
        d.ellipse([int(W * 0.08), int(H * 0.62), int(W * 0.42), int(H * 0.85)], fill=(214, 150, 90, 255))
        for i in range(4):
            y = int(H * (0.67 + i * 0.04))
            d.line([int(W * 0.1), y, int(W * 0.4), y], fill=(170, 100, 60, 255), width=4)
        d.ellipse([int(W * 0.6), int(H * 0.64), int(W * 0.86), int(H * 0.82)], fill=(230, 200, 130, 255))
        d.ellipse([int(W * 0.5), int(H * 0.715), int(W * 0.96), int(H * 0.745)], outline=(240, 220, 170, 255), width=5)
        for x, y in [(0.2, 0.55), (0.8, 0.58), (0.5, 0.9), (0.1, 0.92), (0.9, 0.93)]:
            d.ellipse([int(W * x) - 3, int(H * y) - 3, int(W * x) + 3, int(H * y) + 3], fill=(255, 255, 255, 255))
    elif art == "hall":
        cx, cy = W // 2, int(H * 0.68)
        for i in range(7):
            s = 1.0 - i * 0.13
            w, h = int(W * 0.7 * s), int(H * 0.36 * s)
            d.rectangle([cx - w // 2, cy - h // 2, cx + w // 2, cy + h // 2], outline=ac + (255,), width=3)
        d.rectangle([cx - 14, cy - 22, cx + 14, cy + 22], fill=(250, 240, 180, 255))
    # the title block
    y = int(H * 0.12)
    tsz = int(W * 0.13)
    for line in c["title"]:
        fit_text(d, (W // 2, y), line, SERIF if art in ("whale", "planets") else SANS, tsz, fg + (255,), W * 0.9)
        y += int(tsz * 1.05)
    fit_text(d, (W // 2, y + 6), c["sub"], SERIF, int(W * 0.055), fg + (255,), W * 0.9)
    fit_text(d, (W // 2, int(H * 0.965) if art != "arrows" else int(H * 0.96)), c["author"], SANS, int(W * 0.05),
             (fg if art != "arrows" else (255, 255, 255)) + (255,), W * 0.9)
    return im


def rs_front(e, W=256):
    w, h, dp, col, kind = e["rs"]
    # the face the shopper sees: x by y for flat goods, x by z (top) for desk goods
    tall = h >= w * 0.9
    fw, fh = (w, h) if tall else (w, dp)
    H = int(W * fh / fw)
    base = hexc(col)
    im = Image.new("RGBA", (W, H), base + (255,))
    d = ImageDraw.Draw(im)
    light = base[0] > 180
    ink = (30, 30, 30, 255) if light else (225, 225, 225, 255)
    if kind in ("9v", "c", "ic", "plug"):
        # a blister card: a header strip, the goods under a clear bubble
        d.rectangle([0, 0, W, int(H * 0.22)], fill=(30, 30, 34, 255) if light else (240, 240, 236, 255))
        fit_text(d, (W // 2, int(H * 0.11)), "VOLTARO", SANS, int(W * 0.16), (240, 240, 236, 255) if light else (200, 30, 40, 255), W * 0.85)
        d.rounded_rectangle([int(W * 0.2), int(H * 0.3), int(W * 0.8), int(H * 0.8)], radius=12, fill=(230, 236, 240, 200), outline=(160, 170, 180, 255), width=2)
        if kind in ("9v", "c"):
            n = 1 if kind == "9v" else 2
            for i in range(n):
                x0 = int(W * (0.3 + i * 0.22)) if n == 2 else int(W * 0.36)
                d.rectangle([x0, int(H * 0.35), x0 + int(W * (0.18 if n == 2 else 0.28)), int(H * 0.75)], fill=(40, 40, 40, 255))
                d.rectangle([x0, int(H * 0.35), x0 + int(W * (0.18 if n == 2 else 0.28)), int(H * 0.45)], fill=(200, 160, 40, 255))
        elif kind == "ic":
            d.rectangle([int(W * 0.38), int(H * 0.45), int(W * 0.62), int(H * 0.62)], fill=(30, 30, 30, 255))
            for i in range(4):
                for s in (-1, 1):
                    x = int(W * (0.4 + i * 0.06))
                    d.line([x, int(H * (0.535 + s * 0.085)), x, int(H * (0.535 + s * 0.12))], fill=(190, 190, 190, 255), width=3)
        else:
            d.rectangle([int(W * 0.42), int(H * 0.38), int(W * 0.58), int(H * 0.7)], fill=(30, 30, 30, 255))
            d.rectangle([int(W * 0.47), int(H * 0.32), int(W * 0.53), int(H * 0.4)], fill=(200, 200, 200, 255))
        fit_text(d, (W // 2, int(H * 0.9)), {"9v": "9 VOLT ALKALINE", "c": "C ALKALINE  2 PK", "ic": "TIMER IC", "plug": "PLUG ADAPTER"}[kind],
                 SANS, int(W * 0.09), ink, W * 0.9)
        return im
    fit_text(d, (W // 2, int(H * 0.12) + 10), "VOLTARO", SANS, int(W * 0.12), ink, W * 0.8)
    if kind == "phone":
        d.rounded_rectangle([int(W * 0.15), int(H * 0.3), int(W * 0.85), int(H * 0.55)], radius=20, fill=(214, 206, 192, 255))
        for r in range(4):
            for q in range(3):
                x, y = int(W * (0.32 + q * 0.18)), int(H * (0.62 + r * 0.08))
                d.rectangle([x - 9, y - 6, x + 9, y + 6], fill=(150, 146, 138, 255))
    elif kind == "tape":
        d.rectangle([int(W * 0.1), int(H * 0.35), int(W * 0.55), int(H * 0.8)], fill=(60, 60, 62, 255))
        for x in (0.22, 0.43):
            d.ellipse([int(W * x) - 14, int(H * 0.57) - 14, int(W * x) + 14, int(H * 0.57) + 14], fill=(20, 20, 20, 255))
        d.ellipse([int(W * 0.68), int(H * 0.45), int(W * 0.8), int(H * 0.62)], fill=(200, 30, 30, 255))
    elif kind == "clock":
        d.rectangle([int(W * 0.12), int(H * 0.32), int(W * 0.6), int(H * 0.82)], fill=(10, 10, 10, 255))
        fit_text(d, (int(W * 0.36), int(H * 0.57)), "12:00", SANS, int(H * 0.32), (255, 40, 30, 255), W * 0.45)
        for i in range(8):
            d.line([int(W * 0.66), int(H * (0.35 + i * 0.06)), int(W * 0.9), int(H * (0.35 + i * 0.06))], fill=(80, 80, 80, 255), width=2)
    elif kind == "cell":
        d.rectangle([int(W * 0.2), int(H * 0.15), int(W * 0.8), int(H * 0.3)], fill=(150, 170, 120, 255))
        for r in range(5):
            for q in range(3):
                x, y = int(W * (0.3 + q * 0.2)), int(H * (0.4 + r * 0.1))
                d.ellipse([x - 12, y - 8, x + 12, y + 8], fill=(90, 90, 92, 255))
    elif kind == "ac":
        d.rectangle([int(W * 0.25), int(H * 0.35), int(W * 0.75), int(H * 0.7)], fill=(20, 20, 20, 255))
        fit_text(d, (W // 2, int(H * 0.82)), "AC ADAPTER 9V", SANS, int(W * 0.09), ink, W * 0.9)
    return im


def icon(e):
    W = 256
    im = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    face = None
    if "cover" in e:
        face = cover(e)
    elif "rs" in e:
        face = rs_front(e)
    if face is not None:
        f = face.copy()
        f.thumbnail((int(W * 0.78), int(W * 0.74)))
        im.alpha_composite(f, ((W - f.width) // 2, int(W * 0.06)))
    elif e.get("spool"):
        d.ellipse([48, 40, 208, 200], fill=(70, 70, 74, 255))
        d.ellipse([64, 56, 192, 184], fill=(196, 120, 60, 255))
        for i in range(8):
            d.ellipse([64 + i * 4, 56 + i * 4, 192 - i * 4, 184 - i * 4], outline=(150, 80, 40, 255), width=1)
        d.ellipse([110, 102, 146, 138], fill=(40, 40, 42, 255))
    else:
        k = e["icon"]
        if k == "hotdog":
            d.rounded_rectangle([30, 120, 226, 170], radius=10, fill=(244, 240, 230, 255), outline=(200, 40, 40, 255), width=4)
            d.rounded_rectangle([40, 86, 216, 136], radius=24, fill=(217, 162, 90, 255))
            d.rounded_rectangle([26, 96, 230, 118], radius=11, fill=(168, 68, 42, 255))
            d.line([60, 104, 200, 104], fill=(240, 200, 40, 255), width=4)
        elif k == "burger":
            d.chord([48, 40, 208, 150], 180, 360, fill=(217, 162, 90, 255))
            d.rectangle([44, 112, 212, 124], fill=(232, 184, 48, 255))
            d.rounded_rectangle([40, 124, 216, 146], radius=10, fill=(90, 52, 32, 255))
            d.rounded_rectangle([48, 146, 208, 176], radius=12, fill=(217, 162, 90, 255))
        elif k == "fries":
            col = hexc(e.get("icon_col", "#c81e28"))
            for i in range(9):
                x = 70 + i * 13
                d.rectangle([x, 50 + (i % 3) * 10, x + 9, 130], fill=(240, 200, 80, 255))
            d.polygon([(62, 110), (194, 110), (182, 200), (74, 200)], fill=col + (255,))
        elif k == "coffee":
            d.ellipse([40, 160, 216, 196], fill=(240, 236, 226, 255))
            d.rounded_rectangle([76, 80, 180, 178], radius=14, fill=(244, 240, 230, 255))
            d.ellipse([80, 72, 176, 96], fill=(58, 36, 22, 255))
            d.arc([166, 100, 206, 150], 270, 90, fill=(244, 240, 230, 255), width=10)
        elif k == "cup":
            d.polygon([(82, 60), (174, 60), (164, 200), (92, 200)], fill=(246, 220, 44, 255))
            d.rectangle([78, 52, 178, 64], fill=(244, 244, 240, 255))
            d.line([140, 54, 156, 18], fill=(200, 30, 40, 255), width=6)
    band(im)
    return im


# ------------------------------------------------------------------ the scene (.tscn text)
def _basis_rotz():
    return "0, 1, 0, -1, 0, 0, 0, 0, 1"


def scene(e, res_dir):
    subs, nodes = [], []
    n_sub = [0]

    def sub(kind, body):
        n_sub[0] += 1
        sid = "%s_%d" % (kind, n_sub[0])
        subs.append('[sub_resource type="%s" id="%s"]\n%s\n' % (kind, sid, body))
        return sid

    def mat(col, tex=None):
        body = 'albedo_color = Color(%.4f, %.4f, %.4f, 1)\nroughness = 0.75' % tuple(v / 255 for v in hexc(col))
        if tex:
            body += '\nalbedo_texture = ExtResource("%s")' % tex
        return sub("StandardMaterial3D", body)

    exts = []

    def ext(path):
        eid = "%d_tex" % (len(exts) + 1)
        exts.append('[ext_resource type="Texture2D" path="%s" id="%s"]' % (path, eid))
        return eid

    def box(name, size, pos, col, tex=None):
        m = mat(col if not tex else "#ffffff", tex)
        mid = sub("BoxMesh", "material = SubResource(\"%s\")\nsize = Vector3(%.4f, %.4f, %.4f)" % (m, *size))
        nodes.append('[node name="%s" type="MeshInstance3D" parent="."]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %.4f, %.4f, %.4f)\nmesh = SubResource("%s")\n'
                     % (name, pos[0], pos[1] + size[1] / 2, pos[2], mid))

    def quad(name, w, h, center, tex, back=False):
        m = mat("#ffffff", tex)
        mid = sub("QuadMesh", "material = SubResource(\"%s\")\nsize = Vector2(%.4f, %.4f)" % (m, w, h))
        rot = "-1, 0, 0, 0, 1, 0, 0, 0, -1" if back else "1, 0, 0, 0, 1, 0, 0, 0, 1"
        nodes.append('[node name="%s" type="MeshInstance3D" parent="."]\ntransform = Transform3D(%s, %.4f, %.4f, %.4f)\nmesh = SubResource("%s")\n'
                     % (name, rot, center[0], center[1], center[2], mid))

    def quad_top(name, w, d, y, tex):
        m = mat("#ffffff", tex)
        mid = sub("QuadMesh", "material = SubResource(\"%s\")\nsize = Vector2(%.4f, %.4f)" % (m, w, d))
        # face up (+y), the texture's top toward -z (the back)
        nodes.append('[node name="%s" type="MeshInstance3D" parent="."]\ntransform = Transform3D(1, 0, 0, 0, 0, -1, 0, 1, 0, 0, %.4f, 0)\nmesh = SubResource("%s")\n'
                     % (name, y, mid))

    def cyl(name, r, h, pos, col, rotz=False):
        m = mat(col)
        mid = sub("CylinderMesh", "material = SubResource(\"%s\")\ntop_radius = %.4f\nbottom_radius = %.4f\nheight = %.4f\nradial_segments = 20\nrings = 1" % (m, r, r, h))
        b = _basis_rotz() if rotz else "1, 0, 0, 0, 1, 0, 0, 0, 1"
        y = pos[1] + (r if rotz else h / 2)
        nodes.append('[node name="%s" type="MeshInstance3D" parent="."]\ntransform = Transform3D(%s, %.4f, %.4f, %.4f)\nmesh = SubResource("%s")\n'
                     % (name, b, pos[0], y, pos[2], mid))

    top = 0.0
    if "parts" in e:
        for i, p in enumerate(e["parts"]):
            if p[0] == "box":
                box("Part%d" % i, p[1], p[2], p[3])
                top = max(top, p[2][1] + p[1][1])
            else:
                rz = len(p) > 4 and p[4] == "rotz"
                cyl("Part%d" % i, p[1][0], p[1][1], p[2], p[3], rz)
                top = max(top, p[2][1] + (2 * p[1][0] if rz else p[1][1]))
    elif "book" in e:
        w, h, dp = e["book"]
        # standing up, the cover facing +z
        box("Pages", [w, h, dp], [0, 0, 0], "#f4eedc")
        t = ext("res://%s/%s_front.png" % (res_dir, e["id"]))
        quad("Cover", w + 0.002, h + 0.002, [0, h / 2, dp / 2 + 0.0015], t)
        quad("Back", w + 0.002, h + 0.002, [0, h / 2, -dp / 2 - 0.0015], t, back=True)
        top = h
    elif "rs" in e:
        w, h, dp, col, kind = e["rs"]
        box("Body", [w, h, dp], [0, 0, 0], col)
        t = ext("res://%s/%s_front.png" % (res_dir, e["id"]))
        if h >= w * 0.9:
            quad("Front", w, h, [0, h / 2, dp / 2 + 0.0015], t)
        else:
            quad_top("Front", w, dp, h + 0.0015, t)
        top = h
    elif e.get("spool"):
        cyl("Flange0", 0.05, 0.008, [0, 0, 0], "#46464a")
        cyl("Wire", 0.04, 0.05, [0, 0.008, 0], "#c4783c")
        cyl("Flange1", 0.05, 0.008, [0, 0.058, 0], "#46464a")
        top = 0.066
    # the tag: a small label over it (billboard, no depth test, so it reads in the hand and on the counter)
    nodes.append('[node name="StandInTag" type="Label3D" parent="."]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, %.4f, 0)\n'
                 'billboard = 1\nno_depth_test = true\nfixed_size = false\npixel_size = 0.0004\nmodulate = Color(1, 0.85, 0.15, 1)\n'
                 'outline_size = 8\nfont_size = 48\ntext = "STAND-IN"\n' % (top + 0.03))
    head = '[gd_scene load_steps=%d format=3]\n\n' % (len(subs) + len(exts) + 1)
    root = ('[node name="%s" type="Node3D"]\nmetadata/item_id = "%s"\nmetadata/item_name = "%s"\nmetadata/item_class = "%s"\nmetadata/standin = true\n'
            % (e["id"], e["id"], e["name"].replace('"', '\\"'), e["class"]))
    return head + ("\n".join(exts) + "\n\n" if exts else "") + "\n".join(subs) + "\n" + root + "\n" + "\n".join(nodes)


def main():
    os.chdir(ROOT)
    items = []
    for e in STANDINS:
        d = folder(e)
        os.makedirs(d, exist_ok=True)
        if "cover" in e:
            cover(e).convert("RGB").save(os.path.join(d, e["id"] + "_front.png"), optimize=True)
        elif "rs" in e:
            rs_front(e).convert("RGB").save(os.path.join(d, e["id"] + "_front.png"), optimize=True)
        icon(e).save(os.path.join(d, e["id"] + "_icon.png"), optimize=True)
        with open(os.path.join(d, e["id"] + ".tscn"), "w") as f:
            f.write(scene(e, d))
        items.append({"id": e["id"], "name": e["name"], "class": e["class"], "scene": "res://%s/%s.tscn" % (d, e["id"]),
                      "icon": "res://%s/%s_icon.png" % (d, e["id"]), "year": 1995, "store": e["store"], "standin": True,
                      "standin_for": e["for"]})
    with open("data/items/shop_standins.json", "w") as f:
        json.dump({"_": "Labelled STAND-IN items for the shops (workstream SHOPS, design/godot-shops.md), made by tools/shops/make_standins.py: "
                        "primitive shapes with a STAND-IN tag and a STAND-IN icon until workstream FOOD's (or a later) model lands. Sold at the "
                        "counters (data/story/shops.json); never placed in the world. Book titles other than Moby-Dick are invented.",
                   "items": items}, f, indent=1)
        f.write("\n")
    print("wrote %d stand-ins" % len(items))


if __name__ == "__main__":
    main()
