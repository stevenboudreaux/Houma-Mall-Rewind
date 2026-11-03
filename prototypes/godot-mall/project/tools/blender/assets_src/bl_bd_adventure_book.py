"""An adventure novel in a dust jacket, from B. Dalton Bookseller (1995 map, store s48). Hand item; item id
`bd_adventure_book` (workstream FOOD, Nov 3 2026).

INVENTED title, author and cover (IP rule: no real titles, cover art or logos): "THE SUNKEN COMPASS" by
"J. R. Thibodeaux", a treasure hunt through the Gulf marshes. Jacket: a weathered sea chart in sepia and
teal under a big brass compass rose, a pirate schooner on the horizon, embossed-look gold title; a blurb,
an invented quote, bar code and B. Dalton's own price sticker on the back; the spine with title, author
and an invented publisher mark ("Pelican & Oar"). The jacket is printed onto the case (one surface); the
model is _book.py "hard".
Title and blurb are proposals for Steven to change (the constants below).
References: none (no photo of B. Dalton's shelves). Size: 160 x 240 mm, 34 mm thick (a 1995 hardcover).
Origin: bottom centre, lying flat, front cover up.
"""
import math
import random
from PIL import Image, ImageDraw, ImageFilter
from lib import labels
import _book as B

W, L, T = 0.160, 0.240, 0.034
PPM = 1800 / L
TITLE = ("THE SUNKEN", "COMPASS")
AUTHOR = "J. R. THIBODEAUX"
PRICE = "$22.95"
SEED = 61

META = {
    "id": "bl_bd_adventure_book",
    "class": "hand",
    "tex": 2048,
    "ao": 0.35,
    "refs": [],
    "icon_view": (15, 62),         # from above: the cover reads in the inventory
    "item_file": "food.json",
    "item": {"id": "bd_adventure_book", "name": "The Sunken Compass", "year": 1995, "store": "B. DALTON BOOKSELLER", "price": 2295},
}

PAPER = (214, 190, 140)
INK = (70, 44, 22)
TEAL = (40, 110, 116)
GOLD = (232, 190, 80)


def chart(w, h, rng):
    """A sea chart: parchment, a coastline of marsh islands, depth soundings, rhumb lines."""
    im = B.gradient(w, h, (226, 204, 156), (190, 160, 110))
    d = ImageDraw.Draw(im)
    for k in range(9000):                      # parchment fibres
        x, y = rng.randint(0, w), rng.randint(0, h)
        c = rng.randint(-24, 16)
        d.point((x, y), fill=tuple(max(0, min(255, v + c)) for v in PAPER) + (255,))
    # sea in the lower right, land (marsh islands) upper left
    for k in range(22):
        cx, cy = rng.randint(-40, int(w * 0.6)), rng.randint(-40, int(h * 0.55))
        r = rng.randint(30, 110)
        pts = [(cx + r * (0.7 + 0.3 * rng.random()) * math.cos(a), cy + r * (0.6 + 0.4 * rng.random()) * math.sin(a))
               for a in [i / 14 * math.tau for i in range(14)]]
        d.polygon(pts, fill=(180, 168, 110, 255), outline=INK + (255,))
        for j in range(4):
            d.line((cx + rng.randint(-r // 2, r // 2), cy + rng.randint(-r // 2, r // 2), cx + rng.randint(-r // 2, r // 2),
                    cy + rng.randint(-r // 2, r // 2)), fill=(120, 140, 80, 255), width=2)
    sea = Image.new("L", (w, h), 0)
    ImageDraw.Draw(sea).polygon([(w * 0.3, h), (w, h * 0.25), (w, h)], fill=110)
    im.paste(Image.new("RGBA", (w, h), TEAL + (255,)), (0, 0), sea.filter(ImageFilter.GaussianBlur(60)))
    f = labels.font("italic", 22)
    for k in range(60):                         # soundings
        x, y = rng.randint(int(w * 0.35), w - 20), rng.randint(int(h * 0.35), h - 20)
        d.text((x, y), str(rng.randint(2, 19)), font=f, fill=INK + (255,))
    cx, cy = w * 0.55, h * 0.5
    for k in range(16):                         # rhumb lines
        a = k / 16 * math.tau
        d.line((cx, cy, cx + 2 * w * math.cos(a), cy + 2 * w * math.sin(a)), fill=(120, 90, 60, 255), width=2)
    return im


def compass(im, cx, cy, r):
    d = ImageDraw.Draw(im)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=GOLD + (255,), width=8)
    d.ellipse((cx - r * 0.86, cy - r * 0.86, cx + r * 0.86, cy + r * 0.86), outline=GOLD + (255,), width=3)
    for k in range(32):
        a = k / 32 * math.tau
        rr = r * (0.80 if k % 2 else 0.72)
        d.line((cx + rr * math.cos(a), cy + rr * math.sin(a), cx + r * 0.86 * math.cos(a), cy + r * 0.86 * math.sin(a)), fill=GOLD + (255,), width=3)
    for k in range(8):
        a = k / 8 * math.tau - math.pi / 2
        ln = r * (0.78 if k % 2 == 0 else 0.48)
        p = (cx + ln * math.cos(a), cy + ln * math.sin(a))
        q1 = (cx + r * 0.12 * math.cos(a + math.pi / 2), cy + r * 0.12 * math.sin(a + math.pi / 2))
        q2 = (cx + r * 0.12 * math.cos(a - math.pi / 2), cy + r * 0.12 * math.sin(a - math.pi / 2))
        d.polygon([p, q1, (cx, cy)], fill=(250, 220, 120, 255))
        d.polygon([p, q2, (cx, cy)], fill=(160, 112, 40, 255))
    d.text((cx, cy - r * 1.08), "N", font=B.ff("Cinzel-Bold.ttf", r * 0.3), fill=GOLD + (255,), anchor="mb")


def schooner(d, x, y, s):
    d.polygon([(x - s, y), (x + s, y), (x + s * 0.7, y + s * 0.25), (x - s * 0.8, y + s * 0.25)], fill=(40, 26, 16, 255))
    for mx, top in ((x - s * 0.3, 1.5), (x + s * 0.35, 1.3)):
        d.line((mx, y, mx, y - s * top), fill=(40, 26, 16, 255), width=4)
        d.polygon([(mx + 4, y - s * top), (mx + 4, y - 8), (mx + s * 0.55, y - 8)], fill=(236, 222, 190, 255))


def title(im, lines, y0, size):
    d = ImageDraw.Draw(im)
    f = B.ff("Cinzel-Bold.ttf", size)
    for i, s in enumerate(lines):
        y = y0 + i * size * 1.1
        for dx, dy, c in ((5, 6, (30, 18, 8, 200)), (-2, -2, (255, 236, 170, 255)), (0, 0, GOLD + (255,))):
            d.text((im.width / 2 + dx, y + dy), s, font=f, fill=c, anchor="mm")


def front():
    rng = random.Random(SEED)
    im, _ = B.canvas_for(W, L, PPM)
    w, h = im.size
    im.paste(chart(w, h, rng), (0, 0))
    compass(im, w * 0.52, h * 0.53, w * 0.30)
    d = ImageDraw.Draw(im)
    schooner(d, w * 0.80, h * 0.77, w * 0.07)
    band = Image.new("RGBA", (w, int(h * 0.27)), (24, 40, 44, 215))
    im.paste(band, (0, 0), band)
    title(im, TITLE, h * 0.075, w * 0.125)
    d.rectangle((0, h * 0.88, w, h), fill=(24, 40, 44, 230))
    d.text((w / 2, h * 0.94), AUTHOR, font=B.ff("Cinzel-Bold.ttf", w * 0.065), fill=(240, 228, 200, 255), anchor="mm")
    d.text((w / 2, h * 0.86), "A  NOVEL", font=B.ff("Cinzel-Bold.ttf", w * 0.04), fill=(40, 26, 16, 255), anchor="mm")
    B.wear(im, rng, 100)
    return labels.save(im, "bd_adv_front")


def back():
    rng = random.Random(SEED + 1)
    im, _ = B.canvas_for(W, L, PPM)
    w, h = im.size
    im.paste(B.gradient(w, h, (30, 48, 52), (18, 30, 32)), (0, 0))
    d = ImageDraw.Draw(im)
    d.text((w / 2, h * 0.09), "“X marks the spot — if the", font=labels.font("italic", w * 0.05), fill=GOLD + (255,), anchor="mm")
    d.text((w / 2, h * 0.13), "marsh hasn't swallowed it.”", font=labels.font("italic", w * 0.05), fill=GOLD + (255,), anchor="mm")
    blurb = ["When fourteen-year-old Remy finds a", "brass compass in his grandfather's tackle",
             "box, its needle won't point north. It", "points into the marsh, toward a ship that",
             "went down in the 1814 hurricane with a", "pirate's payroll still aboard.", "",
             "Now Remy, his cousin Lise and a borrowed", "pirogue have one summer to follow the",
             "needle before the treasure hunters do."]
    for i, s in enumerate(blurb):
        d.text((w * 0.1, h * (0.22 + i * 0.045)), s, font=labels.font("sans", w * 0.042), fill=(236, 230, 214, 255), anchor="lm")
    d.text((w / 2, h * 0.72), "“A rip-roaring Gulf Coast adventure.”", font=labels.font("italic", w * 0.042), fill=(236, 230, 214, 255), anchor="mm")
    d.text((w / 2, h * 0.76), "— The Bayou Reader", font=labels.font("sans", w * 0.036), fill=(200, 196, 180, 255), anchor="mm")
    B.barcode(d, (w * 0.56, h * 0.84, w * 0.92, h * 0.95), rng)
    st = B.price_sticker(PRICE, 300, 150).rotate(-3, expand=True, resample=Image.BICUBIC)
    im.paste(st, (int(w * 0.08), int(h * 0.84)), st)
    B.wear(im, rng, 100)
    return labels.save(im, "bd_adv_back")


def spine():
    im, d = B.spine_canvas(L, T, PPM, (24, 40, 44, 255))
    w, h = im.size
    d.text((w * 0.40, h * 0.5), " ".join(TITLE), font=B.ff("Cinzel-Bold.ttf", h * 0.36), fill=GOLD + (255,), anchor="mm")
    d.text((w * 0.76, h * 0.5), "THIBODEAUX", font=B.ff("Cinzel-Bold.ttf", h * 0.28), fill=(240, 228, 200, 255), anchor="mm")
    # publisher mark: a pelican's head over two crossed oars (invented)
    x, y = w * 0.92, h * 0.5
    d.line((x - h * 0.25, y - h * 0.25, x + h * 0.25, y + h * 0.25), fill=(240, 228, 200, 255), width=4)
    d.line((x - h * 0.25, y + h * 0.25, x + h * 0.25, y - h * 0.25), fill=(240, 228, 200, 255), width=4)
    d.ellipse((x - h * 0.1, y - h * 0.32, x + h * 0.08, y - h * 0.14), fill=(240, 228, 200, 255))
    d.polygon([(x + h * 0.06, y - h * 0.24), (x + h * 0.3, y - h * 0.18), (x + h * 0.06, y - h * 0.18)], fill=GOLD + (255,))
    B.wear(im, random.Random(SEED + 2), 40)
    return labels.save(im, "bd_adv_spine")


def build():
    B.build_book("hard", W, L, T, front(), back(), spine(), base="#18282c", rough=0.3, endpaper="#d9c9a0")
