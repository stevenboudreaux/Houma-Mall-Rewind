"""A kids' scary-story paperback from B. Dalton Bookseller (1995 map, store s48). Hand item; item id
`bd_chills_book` (workstream FOOD, Nov 3 2026).

INVENTED series, title, author and cover (IP rule): "CHILL HOLLOW #4: The Thing in the Cane Field" by
"Marguerite Breaux": a mass-market paperback with an icy blue frosted series logo, a moonlit sugar-cane field
with a scarecrow-like shape between the rows and a farmhouse light, a "glow" sticker, a blurb, bar code and
B. Dalton's own price sticker on the back. A different series from T2's SHIVERWOOD (bl_bd_paperback), so the
table shows two. Title and blurb are proposals for Steven to change.
References: none. Size: a US mass-market paperback, 106 x 174 mm, 15 mm thick.
Model: _book.py "paper" (wrapped cover, squared spine, scored hinges).
Origin: bottom centre, lying flat, front cover up.
"""
import math
import random
from PIL import Image, ImageDraw, ImageFilter
from lib import labels
import _book as B

W, L, T = 0.106, 0.174, 0.015
PPM = 1800 / L
SERIES = "CHILL HOLLOW"
NUM = "4"
TITLE = ("THE THING IN", "THE CANE FIELD")
AUTHOR = "MARGUERITE BREAUX"
SEED = 71
ICE = (150, 220, 255)

META = {
    "id": "bl_bd_chills_book",
    "class": "hand",
    "tex": 2048,
    "ao": 0.3,
    "refs": [],
    "icon_view": (15, 62),         # from above: the cover reads in the inventory
    "item_file": "food.json",
    "item": {"id": "bd_chills_book", "name": "Chill Hollow #4 paperback", "year": 1995, "store": "B. DALTON BOOKSELLER", "price": 399},
}


def frosty(im, xy, s, font, rng):
    """Icy lettering: a dark outline, pale blue-to-white fill, icicles hanging off the bottoms."""
    w, h = im.size
    mask = Image.new("L", (w, h), 0)
    md = ImageDraw.Draw(mask)
    md.text(xy, s, font=font, fill=255, anchor="mm")
    bb = mask.getbbox()
    if bb:
        px = mask.load()
        x = bb[0] + 6
        while x < bb[2]:
            for y in range(bb[3] - 1, bb[1], -1):
                if px[x, y]:
                    if rng.random() < 0.5:
                        ln = rng.uniform(0.1, 0.45) * font.size
                        md.polygon([(x - font.size * 0.04, y), (x + font.size * 0.04, y), (x, y + ln)], fill=255)
                    break
            x += rng.randint(int(font.size * 0.12), int(font.size * 0.3))
    ol = mask.filter(ImageFilter.MaxFilter(13))
    im.paste(Image.new("RGBA", (w, h), (8, 14, 40, 255)), (0, 0), ol)
    im.paste(B.gradient(w, h, (255, 255, 255), ICE), (0, 0), mask)
    hl = mask.filter(ImageFilter.MinFilter(7))
    im.paste(Image.new("RGBA", (w, h), (255, 255, 255, 255)), (-3, -3), Image.eval(hl, lambda v: v // 2))


def scene(w, h, rng):
    pic = B.gradient(w, h, (30, 46, 96), (10, 14, 34))
    d = ImageDraw.Draw(pic)
    mx, my, mr = w * 0.3, h * 0.22, w * 0.14
    glow = Image.new("L", (w, h), 0)
    ImageDraw.Draw(glow).ellipse((mx - mr * 2.2, my - mr * 2.2, mx + mr * 2.2, my + mr * 2.2), fill=120)
    pic.paste(Image.new("RGBA", (w, h), (170, 210, 255, 255)), (0, 0), glow.filter(ImageFilter.GaussianBlur(mr * 0.7)))
    d.ellipse((mx - mr, my - mr, mx + mr, my + mr), fill=(232, 240, 255, 255))
    # a farmhouse far off with one lit window
    d.polygon([(w * 0.70, h * 0.50), (w * 0.84, h * 0.50), (w * 0.84, h * 0.43), (w * 0.77, h * 0.37), (w * 0.70, h * 0.43)], fill=(6, 8, 18, 255))
    d.rectangle((w * 0.755, h * 0.45, w * 0.775, h * 0.475), fill=(255, 210, 90, 255))
    # rows of cane converging on the horizon
    hz = h * 0.52
    for k in range(-14, 15):
        x0 = w / 2 + k * w * 0.12
        d.line((w / 2 + k * w * 0.02, hz, x0, h), fill=(16, 40, 30, 255), width=3)
    for k in sorted(range(150), key=lambda k: rng.random()):
        x = rng.randint(0, w)
        yb = rng.randint(int(hz), h)
        near = (yb - hz) / (h - hz)
        tall = (yb - hz) * 0.9 + 30
        wd = int(3 + 9 * near)
        d.line((x, yb, x + rng.randint(-6, 6), yb - tall), fill=(18, 44, 30, 255), width=wd)      # stalk
        for j in range(int(4 + 3 * near)):                                                      # long arching leaves
            yy = yb - tall * rng.uniform(0.35, 1.0)
            sx = rng.choice((-1, 1))
            ln = rng.randint(30, 70) * (0.5 + near)
            d.line((x, yy, x + sx * ln * 0.6, yy - ln * 0.3, x + sx * ln, yy + ln * 0.25), fill=(46, 98, 66, 255) if j % 2 else (30, 70, 48, 255),
                   width=max(2, int(wd * 0.6)), joint="curve")
    # the thing: a tall ragged shape between the rows, two cold eyes
    tx, ty = w * 0.52, h * 0.60
    d.polygon([(tx - 40, ty + 160), (tx - 30, ty + 20), (tx - 70, ty - 20), (tx - 24, ty - 30), (tx - 20, ty - 90), (tx + 20, ty - 90),
               (tx + 26, ty - 30), (tx + 72, ty - 12), (tx + 30, ty + 20), (tx + 40, ty + 160)], fill=(4, 6, 12, 255))
    for ex in (-9, 9):
        g = Image.new("L", (w, h), 0)
        ImageDraw.Draw(g).ellipse((tx + ex - 14, ty - 76, tx + ex + 14, ty - 48), fill=200)
        pic.paste(Image.new("RGBA", (w, h), ICE + (255,)), (0, 0), g.filter(ImageFilter.GaussianBlur(5)))
        d.ellipse((tx + ex - 4, ty - 66, tx + ex + 4, ty - 58), fill=(255, 255, 255, 255))
    return pic.filter(ImageFilter.GaussianBlur(1.0))


def front():
    rng = random.Random(SEED)
    im, _ = B.canvas_for(W, L, PPM, (14, 20, 50, 255))
    w, h = im.size
    im.paste(scene(int(w * 0.88), int(h * 0.50), rng), (int(w * 0.06), int(h * 0.25)))
    d = ImageDraw.Draw(im)
    d.rectangle((w * 0.06, h * 0.25, w * 0.94, h * 0.75), outline=ICE + (255,), width=10)
    frosty(im, (w * 0.5, h * 0.10), SERIES, B.ff("TitanOne-Regular.ttf", w * 0.12), rng)
    d = ImageDraw.Draw(im)
    d.ellipse((w * 0.04, h * 0.155, w * 0.18, h * 0.24), fill=ICE + (255,), outline=(8, 14, 40, 255), width=5)
    d.text((w * 0.11, h * 0.2), NUM, font=labels.font("bold", w * 0.08), fill=(8, 14, 40, 255), anchor="mm")
    d.text((w * 0.56, h * 0.2), "STORIES THAT GIVE YOU GOOSEFLESH", font=labels.font("bold", w * 0.032), fill=(255, 255, 255, 255), anchor="mm")
    for i, s in enumerate(TITLE):
        frosty(im, (w * 0.5, h * (0.81 + i * 0.075)), s, B.ff("TitanOne-Regular.ttf", w * 0.085), rng)
    d = ImageDraw.Draw(im)
    d.text((w * 0.5, h * 0.965), AUTHOR, font=labels.font("bold", w * 0.045), fill=(255, 255, 255, 255), anchor="mm")
    # a starburst "GLOWS IN THE DARK!" sticker on the cover picture
    cx, cy, r = w * 0.80, h * 0.33, w * 0.11
    pts = [(cx + (r if k % 2 else r * 0.75) * math.cos(k / 24 * math.tau), cy + (r if k % 2 else r * 0.75) * math.sin(k / 24 * math.tau)) for k in range(24)]
    d.polygon(pts, fill=(250, 230, 40, 255), outline=(8, 14, 40, 255))
    d.text((cx, cy - r * 0.18), "COVER", font=labels.font("bold", r * 0.36), fill=(8, 14, 40, 255), anchor="mm")
    d.text((cx, cy + r * 0.22), "GLOWS!", font=labels.font("bold", r * 0.36), fill=(200, 20, 30, 255), anchor="mm")
    B.wear(im, rng, 140)
    return labels.save(im, "bd_chills_front")


def back():
    rng = random.Random(SEED + 1)
    im, _ = B.canvas_for(W, L, PPM)
    w, h = im.size
    im.paste(B.gradient(w, h, (10, 14, 34), (24, 36, 80)), (0, 0))
    frosty(im, (w * 0.5, h * 0.1), "DON'T GO IN", B.ff("TitanOne-Regular.ttf", w * 0.09), rng)
    frosty(im, (w * 0.5, h * 0.17), "AFTER DARK...", B.ff("TitanOne-Regular.ttf", w * 0.09), rng)
    d = ImageDraw.Draw(im)
    blurb = ["Every fall the cane grows taller than", "Uncle Ti-Boy's truck. And every fall,",
             "something moves between the rows that", "isn't the wind.", "",
             "Nicky Robichaux says it's just a story", "to keep kids out of the field.",
             "Then the scarecrow goes missing."]
    for i, s in enumerate(blurb):
        d.text((w * 0.08, h * (0.30 + i * 0.05)), s, font=labels.font("sans", w * 0.044), fill=(236, 240, 255, 255), anchor="lm")
    d.text((w * 0.5, h * 0.76), "CHILL HOLLOW #" + NUM, font=labels.font("bold", w * 0.06), fill=ICE + (255,), anchor="mm")
    B.barcode(d, (w * 0.56, h * 0.84, w * 0.93, h * 0.96), rng)
    st = B.price_sticker("$3.99", 260, 130).rotate(5, expand=True, resample=Image.BICUBIC)
    im.paste(st, (int(w * 0.07), int(h * 0.84)), st)
    B.wear(im, rng, 140)
    return labels.save(im, "bd_chills_back")


def spine():
    im, d = B.spine_canvas(L, T, PPM, (14, 20, 50, 255))
    w, h = im.size
    d.rectangle((0, 0, w * 0.13, h), fill=ICE + (255,))
    d.text((w * 0.065, h * 0.5), NUM, font=labels.font("bold", h * 0.7), fill=(8, 14, 40, 255), anchor="mm")
    d.text((w * 0.35, h * 0.5), SERIES, font=B.ff("TitanOne-Regular.ttf", h * 0.5), fill=ICE + (255,), anchor="mm")
    d.text((w * 0.74, h * 0.5), " ".join(TITLE), font=labels.font("bold", h * 0.36), fill=(255, 255, 255, 255), anchor="mm")
    rng = random.Random(SEED + 2)
    for k in range(10):                        # reading creases
        x = rng.randint(int(w * 0.16), w - 8)
        d.line([(x + rng.randint(-5, 5), y) for y in range(0, h + 1, max(1, h // 4))], fill=(220, 226, 240, 255), width=rng.choice((2, 3)))
    return labels.save(im, "bd_chills_spine")


def build():
    B.build_book("paper", W, L, T, front(), back(), spine(), base="#0e1432", rough=0.35, page_edge="#c8bc9c")
