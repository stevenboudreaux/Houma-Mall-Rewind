#!/usr/bin/env python3
"""Textures for the fuller prize counters (workstream PRIZES, Nov 3 2026; design/godot-prize-counter.md
"PRIZES"): Pocket Change 1995 (Option B: more prizes, a third bin width, a hook grid of carded toys) and
games, inc. 2026 (its own counter and wall).

Writes prizes/*.png beside paint_prizes.py's (that script is left alone so its pictures stay the same).
All generic: no brand names, logos, characters or cover art. No words either: scripts/prizes.gd paints
the words over these at load time from scripts/prizes.json / prizes_2026.json "text" and "art", so Steven
can edit them in the game like the price cards. Run from the project folder.
"""
import math
import random
from PIL import Image, ImageDraw, ImageFilter

OUT = "prizes/"
rnd = random.Random(2026)


def save(im, name):
    im.save(OUT + name + ".png")


def grad(d, w, h, top, bot, x0=0, y0=0):
    for y in range(h):
        t = y / max(1, h - 1)
        c = tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3))
        d.line([(x0, y0 + y), (x0 + w, y0 + y)], fill=c)


# --- generic surfaces (tinted per prize by the instance colour) -------------------------------------
def swirl():
    """A swirl for bouncy balls and lollipop heads (white and grey bands; the tint gives the colour)."""
    im = Image.new("RGB", (128, 64), (255, 255, 255))
    d = ImageDraw.Draw(im)
    for k in range(-64, 192, 16):
        d.polygon([(k, 0), (k + 8, 0), (k + 40, 64), (k + 32, 64)], fill=(150, 150, 160))
    save(im, "swirl")


def stripes():
    """Powder straws and pencils: bands round the tube (the tint colours the light bands)."""
    im = Image.new("RGB", (32, 128), (255, 255, 255))
    d = ImageDraw.Draw(im)
    for y in range(0, 128, 16):
        d.rectangle([0, y, 32, y + 6], fill=(185, 185, 190))
    save(im, "stripes")


def wrapper():
    """A twisted candy wrapper: a white band across a tinted body, crimped ends."""
    im = Image.new("RGB", (128, 64), (255, 255, 255))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 128, 64], fill=(215, 215, 220))
    d.rectangle([0, 24, 128, 40], fill=(255, 255, 255))
    for x in range(0, 128, 6):
        d.line([(x, 0), (x, 8)], fill=(170, 170, 175), width=2)
        d.line([(x, 56), (x, 64)], fill=(170, 170, 175), width=2)
    save(im, "wrapper")


def foil():
    """A blind-bag foil: stars and sparkles on silver (tinted)."""
    im = Image.new("RGB", (128, 128), (220, 222, 230))
    d = ImageDraw.Draw(im)
    for i in range(1400):
        x, y = rnd.randrange(128), rnd.randrange(128)
        g = rnd.randrange(170, 256)
        d.point((x, y), fill=(g, g, g))
    for i in range(14):
        cx, cy, r = rnd.randrange(128), rnd.randrange(128), rnd.randrange(5, 11)
        pts = []
        for k in range(10):
            a = k * math.pi / 5 - math.pi / 2
            rr = r if k % 2 == 0 else r * 0.45
            pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
        d.polygon(pts, fill=(255, 255, 255))
    d.ellipse([34, 34, 94, 94], fill=(70, 70, 82))
    d.ellipse([52, 44, 76, 68], outline=(255, 255, 255), width=5)   # a "?" made of shapes, not a word
    d.rectangle([62, 68, 67, 76], fill=(255, 255, 255))
    d.ellipse([60, 80, 69, 89], fill=(255, 255, 255))
    save(im, "foil")


def stickers():
    """A sticker sheet: stars, hearts, smiles, lightning bolts on white (no characters)."""
    im = Image.new("RGB", (128, 192), (250, 250, 246))
    d = ImageDraw.Draw(im)
    cols = [(240, 60, 120), (60, 170, 240), (250, 210, 40), (80, 200, 90), (150, 80, 220), (250, 120, 40)]
    for r in range(4):
        for c in range(3):
            x, y = 22 + c * 42, 26 + r * 46
            col = cols[(r * 3 + c) % len(cols)]
            k = (r + c) % 4
            if k == 0:
                pts = []
                for i in range(10):
                    a = i * math.pi / 5 - math.pi / 2
                    rr = 16 if i % 2 == 0 else 7
                    pts.append((x + rr * math.cos(a), y + rr * math.sin(a)))
                d.polygon(pts, fill=col)
            elif k == 1:
                d.ellipse([x - 15, y - 12, x, y + 3], fill=col); d.ellipse([x, y - 12, x + 15, y + 3], fill=col)
                d.polygon([(x - 15, y - 3), (x + 15, y - 3), (x, y + 15)], fill=col)
            elif k == 2:
                d.ellipse([x - 15, y - 15, x + 15, y + 15], fill=col)
                d.ellipse([x - 7, y - 6, x - 3, y - 1], fill=(20, 20, 20)); d.ellipse([x + 3, y - 6, x + 7, y - 1], fill=(20, 20, 20))
                d.arc([x - 9, y - 6, x + 9, y + 9], 20, 160, fill=(20, 20, 20), width=3)
            else:
                d.polygon([(x + 4, y - 16), (x - 10, y + 2), (x - 1, y + 2), (x - 5, y + 16), (x + 10, y - 3), (x + 1, y - 3)], fill=col)
    d.rectangle([0, 0, 127, 191], outline=(200, 200, 200), width=2)
    save(im, "stickers")


def emoji():
    """A round smiley face for the emoji keychains (yellow; generic face)."""
    im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse([4, 4, 60, 60], fill=(255, 210, 50, 255))
    d.ellipse([18, 20, 26, 32], fill=(40, 30, 20, 255)); d.ellipse([38, 20, 46, 32], fill=(40, 30, 20, 255))
    d.arc([16, 22, 48, 50], 20, 160, fill=(40, 30, 20, 255), width=4)
    save(im, "emoji")


# --- carded and boxed packaging: word-free art, words drawn by prizes.gd ---------------------------
def blister():
    """A blister card back (hook hole, a header band for the words, a burst behind the toy). Tinted."""
    im = Image.new("RGB", (128, 192), (255, 255, 255))
    d = ImageDraw.Draw(im)
    grad(d, 128, 192, (250, 250, 250), (200, 200, 205))
    d.rectangle([0, 0, 128, 40], fill=(255, 255, 255))
    d.rectangle([0, 36, 128, 42], fill=(120, 120, 128))
    d.ellipse([54, 8, 74, 18], fill=(60, 60, 64))
    for k in range(16):
        a = k * math.pi / 8
        d.polygon([(64, 112), (64 + 70 * math.cos(a), 112 + 70 * math.sin(a)), (64 + 70 * math.cos(a + 0.2), 112 + 70 * math.sin(a + 0.2))], fill=(235, 235, 240))
    d.rectangle([0, 0, 127, 191], outline=(150, 150, 155), width=2)
    save(im, "blister")


def _box(name, bg_top, bg_bot, band, draw_item):
    im = Image.new("RGB", (192, 256), bg_top)
    d = ImageDraw.Draw(im)
    grad(d, 192, 256, bg_top, bg_bot)
    d.rectangle([0, 0, 192, 52], fill=band)                 # the word band (prizes.gd writes in it)
    d.rectangle([0, 214, 192, 256], fill=band)              # a second band at the foot
    draw_item(d)
    d.rectangle([0, 0, 191, 255], outline=(30, 30, 34), width=3)
    save(im, name)


def boxes():
    # 1995
    def lcd(d):
        d.rounded_rectangle([46, 66, 146, 206], 14, fill=(70, 74, 86))
        d.rectangle([60, 80, 132, 140], fill=(160, 176, 140))
        for i in range(5):
            d.rectangle([70 + i * 12, 108 - (i % 2) * 8, 78 + i * 12, 128], fill=(40, 52, 40))
        d.ellipse([62, 156, 84, 178], fill=(220, 40, 40)); d.ellipse([108, 150, 130, 172], fill=(220, 40, 40))
        d.rectangle([90, 180, 104, 186], fill=(30, 30, 30))
    _box("box_lcd", (40, 60, 180), (20, 30, 100), (250, 210, 30), lcd)

    def walkie(d):
        for x0 in (44, 104):
            d.rounded_rectangle([x0, 90, x0 + 44, 200], 6, fill=(30, 30, 34))
            d.rectangle([x0 + 30, 58, x0 + 36, 92], fill=(30, 30, 34))
            for y in range(110, 150, 8):
                d.line([(x0 + 8, y), (x0 + 36, y)], fill=(90, 90, 96), width=3)
            d.rectangle([x0 + 10, 160, x0 + 34, 176], fill=(240, 200, 40))
    _box("box_walkie", (230, 120, 20), (180, 60, 10), (30, 30, 34), walkie)

    def cassette(d):
        d.rounded_rectangle([40, 76, 152, 196], 8, fill=(190, 190, 200))
        d.rectangle([52, 92, 140, 146], fill=(40, 40, 46))
        for cx in (78, 114):
            d.ellipse([cx - 12, 106, cx + 12, 130], fill=(220, 220, 228))
        for i in range(5):
            d.rectangle([52 + i * 18, 160, 64 + i * 18, 174], fill=(60, 60, 66))
        d.arc([30, 40, 162, 150], 200, 340, fill=(30, 30, 34), width=6)    # the headphones' band
        d.ellipse([22, 100, 46, 136], fill=(30, 30, 34)); d.ellipse([146, 100, 170, 136], fill=(30, 30, 34))
    _box("box_cassette", (20, 20, 26), (60, 20, 90), (230, 40, 120), cassette)

    def rc(d):
        d.polygon([(30, 170), (50, 128), (130, 120), (166, 150), (166, 176), (30, 182)], fill=(220, 30, 30))
        d.polygon([(70, 130), (120, 126), (136, 146), (64, 150)], fill=(40, 40, 50))
        for cx in (58, 142):
            d.ellipse([cx - 20, 160, cx + 20, 200], fill=(20, 20, 20)); d.ellipse([cx - 9, 171, cx + 9, 189], fill=(200, 200, 200))
        d.line([(150, 124), (176, 64)], fill=(20, 20, 20), width=3)
        for k in range(6):
            d.line([(10, 80 + k * 10), (60, 80 + k * 10)], fill=(250, 230, 60), width=3)   # speed lines
    _box("box_rc", (30, 140, 230), (10, 60, 140), (250, 220, 30), rc)

    # 2026
    def earbuds(d):
        d.rounded_rectangle([56, 104, 136, 180], 30, fill=(245, 245, 248))
        d.line([(64, 140), (128, 140)], fill=(200, 200, 205), width=2)
        for cx in (66, 126):
            d.ellipse([cx - 16, 66, cx + 16, 98], fill=(250, 250, 252)); d.rectangle([cx - 5, 92, cx + 5, 120], fill=(250, 250, 252))
    _box("box_earbuds", (240, 240, 244), (200, 204, 214), (24, 24, 30), earbuds)

    def speaker(d):
        d.rounded_rectangle([40, 92, 152, 196], 40, fill=(30, 100, 200))
        for y in range(104, 186, 7):
            d.line([(56, y), (136, y)], fill=(20, 70, 150), width=3)
        d.rectangle([84, 186, 108, 192], fill=(250, 250, 250))
    _box("box_speaker", (20, 24, 36), (40, 50, 80), (40, 220, 240), speaker)

    def projector(d):
        d.ellipse([46, 90, 146, 190], fill=(40, 30, 90))
        for i in range(40):
            x, y = rnd.randrange(50, 142), rnd.randrange(94, 186)
            d.ellipse([x - 2, y - 2, x + 2, y + 2], fill=(250, 240, 200))
        d.ellipse([86, 130, 106, 150], fill=(150, 220, 255))
    _box("box_projector", (30, 10, 60), (90, 30, 140), (240, 90, 200), projector)

    def headphones(d):
        d.arc([46, 60, 146, 170], 180, 360, fill=(20, 20, 24), width=12)
        d.rounded_rectangle([34, 112, 66, 186], 12, fill=(20, 20, 24)); d.rounded_rectangle([126, 112, 158, 186], 12, fill=(20, 20, 24))
        d.rounded_rectangle([40, 120, 60, 178], 8, fill=(220, 60, 60)); d.rounded_rectangle([132, 120, 152, 178], 8, fill=(220, 60, 60))
    _box("box_headphones", (230, 230, 236), (170, 175, 190), (220, 40, 50), headphones)

    def handheld(d):
        d.rounded_rectangle([22, 104, 170, 176], 18, fill=(30, 30, 36))
        d.rectangle([58, 112, 134, 168], fill=(90, 160, 230))
        d.ellipse([30, 124, 50, 144], fill=(70, 70, 80)); d.ellipse([144, 136, 164, 156], fill=(70, 70, 80))
    _box("box_handheld", (240, 60, 60), (160, 20, 30), (250, 250, 250), handheld)

    def console(d):
        d.polygon([(70, 66), (122, 66), (130, 206), (62, 206)], fill=(245, 245, 248))
        d.polygon([(88, 66), (104, 66), (106, 206), (86, 206)], fill=(30, 30, 36))
        d.rounded_rectangle([118, 170, 176, 200], 10, fill=(245, 245, 248))
    _box("box_console", (14, 30, 90), (10, 14, 40), (250, 250, 250), console)

    def phonestand(d):
        d.polygon([(70, 196), (122, 196), (112, 160), (80, 160)], fill=(200, 200, 210))
        d.rounded_rectangle([72, 70, 120, 168], 8, fill=(30, 30, 36)); d.rectangle([77, 78, 115, 158], fill=(120, 200, 240))
    _box("box_phonestand", (250, 250, 250), (210, 220, 230), (40, 180, 120), phonestand)

    def arcade(d):
        d.polygon([(66, 60), (126, 60), (132, 206), (60, 206)], fill=(220, 40, 120))
        d.rectangle([74, 74, 118, 118], fill=(40, 40, 60)); d.rectangle([78, 78, 114, 114], fill=(90, 220, 140))
        d.polygon([(60, 140), (132, 140), (138, 156), (54, 156)], fill=(30, 30, 36))
        d.ellipse([74, 142, 82, 150], fill=(250, 220, 40)); d.ellipse([100, 142, 108, 150], fill=(60, 160, 250))
    _box("box_arcade", (250, 210, 40), (240, 130, 20), (30, 30, 36), arcade)

    def ledstrip(d):
        d.ellipse([46, 90, 146, 190], outline=(250, 250, 250), width=8)
        for k in range(18):
            a = k * math.tau / 18
            c = [(255, 60, 60), (60, 255, 120), (60, 120, 255), (255, 60, 220)][k % 4]
            d.ellipse([96 + 50 * math.cos(a) - 5, 140 + 50 * math.sin(a) - 5, 96 + 50 * math.cos(a) + 5, 140 + 50 * math.sin(a) + 5], fill=c)
    _box("box_ledstrip", (20, 20, 26), (50, 20, 60), (60, 240, 200), ledstrip)


def gtag():
    """games, inc.'s green shelf tag: white, a green band for TICKETS (words by prizes.gd)."""
    im = Image.new("RGB", (256, 160), (252, 252, 250))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 122, 256, 160], fill=(30, 170, 70))
    d.rectangle([0, 0, 255, 159], outline=(30, 140, 60), width=6)
    save(im, "gtag")


def slatwall():
    """games, inc.'s black slatwall face (grooves every 76 mm) for the prize wall's back between shelves."""
    im = Image.new("RGB", (64, 256), (22, 22, 24))
    d = ImageDraw.Draw(im)
    for y in range(0, 256, 32):
        d.rectangle([0, y, 64, y + 5], fill=(8, 8, 9))
        d.line([(0, y + 6), (64, y + 6)], fill=(46, 46, 50), width=1)
    im.save("tex/gi/slatwall.png")     # a static wall texture (tools/stores/games_inc/machines/counter.gd)


for fn in [swirl, stripes, wrapper, foil, stickers, emoji, blister, boxes, gtag, slatwall]:
    fn()
print("prizes 2 painted")
