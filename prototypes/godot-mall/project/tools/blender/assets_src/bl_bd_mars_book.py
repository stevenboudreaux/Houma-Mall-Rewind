"""A science-fiction novel about Mars, a trade paperback from B. Dalton Bookseller (1995 map, store s48).
Hand item; item id `bd_mars_book` (workstream FOOD, Nov 3 2026).

INVENTED title, author and cover (IP rule; real Mars novels of the period are avoided by name): "DUST OVER
THARSIS" by "Dana Okonkwo-Hale": a painted 1990s SF cover: a rust-red Martian plain under a butterscotch
sky, Olympus Mons on the horizon, a domed outpost with lit windows, a six-wheeled rover kicking up dust,
two small moons; chrome-gradient title type; a blurb, invented quotes, bar code and B. Dalton's own price
sticker on the back. Title and blurb are proposals for Steven to change.
References: none. Size: a trade paperback, 138 x 212 mm, 24 mm thick.
Model: _book.py "paper".
Origin: bottom centre, lying flat, front cover up.
"""
import math
import random
from PIL import Image, ImageDraw, ImageFilter
from lib import labels
import _book as B

W, L, T = 0.138, 0.212, 0.024
PPM = 1800 / L
TITLE = ("DUST OVER", "THARSIS")
AUTHOR = "DANA OKONKWO-HALE"
SEED = 81

META = {
    "id": "bl_bd_mars_book",
    "class": "hand",
    "tex": 2048,
    "ao": 0.3,
    "refs": [],
    "icon_view": (15, 62),         # from above: the cover reads in the inventory
    "item_file": "food.json",
    "item": {"id": "bd_mars_book", "name": "Dust Over Tharsis", "year": 1995, "store": "B. DALTON BOOKSELLER", "price": 1295},
}


def chrome(im, xy, s, font):
    w, h = im.size
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).text(xy, s, font=font, fill=255, anchor="mm")
    bb = mask.getbbox()
    ol = mask.filter(ImageFilter.MaxFilter(9))
    im.paste(Image.new("RGBA", (w, h), (20, 10, 6, 255)), (6, 8), ol.filter(ImageFilter.GaussianBlur(4)))
    im.paste(Image.new("RGBA", (w, h), (40, 20, 12, 255)), (0, 0), ol)
    if bb:
        g = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        gg = B.gradient(w, bb[3] - bb[1], (250, 250, 255), (120, 130, 150))
        g2 = B.gradient(w, (bb[3] - bb[1]) // 2 + 1, (255, 200, 120), (250, 240, 220))
        g.paste(gg, (0, bb[1]))
        g.paste(g2, (0, (bb[1] + bb[3]) // 2))
        im.paste(g, (0, 0), mask)


def scene(w, h, rng):
    pic = B.gradient(w, h, (230, 170, 110), (200, 110, 60))
    d = ImageDraw.Draw(pic)
    hz = int(h * 0.55)
    # moons
    for mx, my, r in ((0.22, 0.14, 0.035), (0.70, 0.08, 0.02)):
        d.ellipse((w * mx - w * r, h * my - w * r, w * mx + w * r, h * my + w * r), fill=(240, 220, 200, 255))
    # Olympus Mons: a very wide, low shield volcano on the horizon
    d.polygon([(w * 0.05, hz), (w * 0.30, hz - h * 0.09), (w * 0.42, hz - h * 0.11), (w * 0.58, hz - h * 0.105), (w * 0.95, hz)], fill=(170, 90, 60, 255))
    d.line([(w * 0.30, hz - h * 0.09), (w * 0.42, hz - h * 0.11), (w * 0.58, hz - h * 0.105)], fill=(220, 150, 110, 255), width=4)
    # the plain
    ground = B.gradient(w, h - hz, (178, 82, 40), (110, 40, 20))
    pic.paste(ground, (0, hz))
    for k in range(300):
        x, y = rng.randint(0, w), rng.randint(hz, h)
        r = rng.randint(2, 4) + int((y - hz) / (h - hz) * 14)
        d.ellipse((x - r, y - r * 0.6, x + r, y + r * 0.4), fill=(90, 30, 14, 255))
        d.ellipse((x - r * 0.7, y - r * 0.7, x + r * 0.2, y - r * 0.1), fill=(210, 120, 70, 255))
    # the outpost: two domes and a tower, windows lit
    for cx, r in ((0.72, 0.09), (0.86, 0.06)):
        d.pieslice((w * cx - w * r, hz + h * 0.06 - w * r, w * cx + w * r, hz + h * 0.06 + w * r), 180, 360, fill=(210, 214, 220, 255), outline=(80, 80, 90, 255), width=3)
        for k in range(4):
            a = math.pi + (k + 0.5) / 4 * math.pi
            d.rectangle((w * cx + w * r * 0.7 * math.cos(a) - 4, hz + h * 0.06 + w * r * 0.6 * math.sin(a) - 3,
                         w * cx + w * r * 0.7 * math.cos(a) + 4, hz + h * 0.06 + w * r * 0.6 * math.sin(a) + 3), fill=(255, 220, 120, 255))
    d.rectangle((w * 0.63, hz - h * 0.05, w * 0.645, hz + h * 0.06), fill=(180, 184, 190, 255))
    d.ellipse((w * 0.62, hz - h * 0.065, w * 0.655, hz - h * 0.04), fill=(255, 60, 40, 255))
    # the rover in the foreground with its dust plume
    rx, ry = w * 0.32, h * 0.80
    plume = Image.new("L", (w, h), 0)
    ImageDraw.Draw(plume).ellipse((rx - w * 0.45, ry - h * 0.12, rx - w * 0.02, ry + h * 0.03), fill=170)
    pic.paste(Image.new("RGBA", (w, h), (220, 150, 100, 255)), (0, 0), plume.filter(ImageFilter.GaussianBlur(30)))
    d.rounded_rectangle((rx - w * 0.12, ry - h * 0.07, rx + w * 0.12, ry - h * 0.01), 12, fill=(236, 236, 240, 255), outline=(60, 60, 70, 255), width=3)
    d.rectangle((rx - w * 0.06, ry - h * 0.11, rx + w * 0.07, ry - h * 0.07), fill=(70, 120, 170, 255), outline=(60, 60, 70, 255), width=3)
    d.line((rx + w * 0.09, ry - h * 0.07, rx + w * 0.12, ry - h * 0.15), fill=(60, 60, 70, 255), width=3)
    d.ellipse((rx + w * 0.105, ry - h * 0.165, rx + w * 0.135, ry - h * 0.14), outline=(60, 60, 70, 255), width=3)
    for k in range(3):
        wx = rx - w * 0.09 + k * w * 0.09
        d.ellipse((wx - w * 0.032, ry - h * 0.025, wx + w * 0.032, ry + h * 0.025), fill=(40, 40, 46, 255))
        d.ellipse((wx - w * 0.014, ry - h * 0.011, wx + w * 0.014, ry + h * 0.011), fill=(150, 150, 160, 255))
    return pic.filter(ImageFilter.GaussianBlur(1.1))


def front():
    rng = random.Random(SEED)
    im, _ = B.canvas_for(W, L, PPM, (20, 10, 6, 255))
    w, h = im.size
    im.paste(scene(w, h, rng), (0, 0))
    top = B.gradient(w, int(h * 0.3), (16, 8, 6), (16, 8, 6))
    fade = Image.new("L", (w, int(h * 0.3)))
    ImageDraw.Draw(fade)
    for y in range(int(h * 0.3)):
        ImageDraw.Draw(fade).line((0, y, w, y), fill=int(220 * (1 - y / (h * 0.3))))
    im.paste(top, (0, 0), fade)
    d = ImageDraw.Draw(im)
    d.text((w / 2, h * 0.045), AUTHOR, font=B.ff("Oswald-Bold.ttf", w * 0.055), fill=(250, 220, 170, 255), anchor="mm")
    for i, s in enumerate(TITLE):
        chrome(im, (w / 2, h * (0.13 + i * 0.105)), s, B.ff("Anton-Regular.ttf", w * 0.15))
    d = ImageDraw.Draw(im)
    d.text((w / 2, h * 0.955), "THE FIRST CITY ON MARS HAS A SECRET", font=B.ff("Oswald-Bold.ttf", w * 0.043), fill=(255, 240, 220, 255), anchor="mm")
    B.wear(im, rng, 110)
    return labels.save(im, "bd_mars_front")


def back():
    rng = random.Random(SEED + 1)
    im, _ = B.canvas_for(W, L, PPM)
    w, h = im.size
    im.paste(B.gradient(w, h, (22, 10, 8), (70, 26, 14)), (0, 0))
    d = ImageDraw.Draw(im)
    d.text((w / 2, h * 0.08), "2097. TWELVE HUNDRED SETTLERS.", font=B.ff("Oswald-Bold.ttf", w * 0.05), fill=(250, 200, 140, 255), anchor="mm")
    d.text((w / 2, h * 0.125), "ONE DUST STORM THAT NEVER ENDS.", font=B.ff("Oswald-Bold.ttf", w * 0.05), fill=(250, 200, 140, 255), anchor="mm")
    blurb = ["For forty sols the storm has buried", "Tharsis Station. The rovers are grounded,",
             "the radio is dead, and the colony's", "engineer, Ines Varga, has found tracks",
             "in the dust outside the airlock.", "", "Tracks that lead away from the station.",
             "Tracks that nobody made."]
    for i, s in enumerate(blurb):
        d.text((w * 0.09, h * (0.22 + i * 0.047)), s, font=labels.font("sans", w * 0.043), fill=(244, 232, 220, 255), anchor="lm")
    d.text((w / 2, h * 0.65), "“Hard science, real dread.”", font=labels.font("italic", w * 0.045), fill=(250, 220, 170, 255), anchor="mm")
    d.text((w / 2, h * 0.69), "— Starlane Review", font=labels.font("sans", w * 0.036), fill=(220, 200, 180, 255), anchor="mm")
    d.text((w * 0.1, h * 0.79), "SCIENCE FICTION", font=B.ff("Oswald-Bold.ttf", w * 0.04), fill=(250, 200, 140, 255), anchor="lm")
    B.barcode(d, (w * 0.56, h * 0.84, w * 0.92, h * 0.95), rng)
    st = B.price_sticker("$12.95", 280, 140).rotate(-4, expand=True, resample=Image.BICUBIC)
    im.paste(st, (int(w * 0.08), int(h * 0.84)), st)
    B.wear(im, rng, 110)
    return labels.save(im, "bd_mars_back")


def spine():
    im, d = B.spine_canvas(L, T, PPM, (22, 10, 8, 255))
    w, h = im.size
    d.text((w * 0.32, h * 0.5), " ".join(TITLE), font=B.ff("Anton-Regular.ttf", h * 0.55), fill=(240, 240, 248, 255), anchor="mm")
    d.text((w * 0.74, h * 0.5), "OKONKWO-HALE", font=B.ff("Oswald-Bold.ttf", h * 0.4), fill=(250, 200, 140, 255), anchor="mm")
    d.ellipse((w * 0.92 - h * 0.25, h * 0.25, w * 0.92 + h * 0.25, h * 0.75), outline=(250, 200, 140, 255), width=3)
    d.text((w * 0.92, h * 0.5), "S", font=B.ff("Oswald-Bold.ttf", h * 0.36), fill=(250, 200, 140, 255), anchor="mm")
    rng = random.Random(SEED + 2)
    for k in range(7):
        x = rng.randint(int(w * 0.1), w - 8)
        d.line([(x + rng.randint(-5, 5), y) for y in range(0, h + 1, max(1, h // 4))], fill=(200, 180, 170, 255), width=2)
    return labels.save(im, "bd_mars_spine")


def build():
    B.build_book("paper", W, L, T, front(), back(), spine(), base="#160a06", rough=0.4)
