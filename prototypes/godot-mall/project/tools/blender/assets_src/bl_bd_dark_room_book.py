"""A thriller in a dust jacket, from B. Dalton Bookseller (1995 map, store s48). Hand item; item id
`bd_dark_room_book` (workstream FOOD, Nov 3 2026).

INVENTED title, author and cover (IP rule; the obvious title "The Dark Room" is avoided because real books
of that name exist, one of them 1995): "SAFELIGHT" by "Claire Lanoux", a darkroom thriller. Jacket: black,
lit only by a photographic safelight's red, a strip of film negatives curling across it with a face half
appearing in one frame, a print hanging from a line with clothes pins, silver title type; a blurb, invented
quotes, bar code and B. Dalton's own price sticker on the back. Title and blurb are proposals for Steven.
References: none. Size: 156 x 236 mm, 36 mm thick (a 1995 hardcover). Model: _book.py "hard".
Origin: bottom centre, lying flat, front cover up.
"""
import math
import random
from PIL import Image, ImageDraw, ImageFilter
from lib import labels
import _book as B

W, L, T = 0.156, 0.236, 0.036
PPM = 1800 / L
TITLE = "SAFELIGHT"
AUTHOR = "CLAIRE LANOUX"
SEED = 91
RED = (210, 24, 20)

META = {
    "id": "bl_bd_dark_room_book",
    "class": "hand",
    "tex": 2048,
    "ao": 0.35,
    "refs": [],
    "icon_view": (15, 62),         # from above: the cover reads in the inventory
    "item_file": "food.json",
    "item": {"id": "bd_dark_room_book", "name": "Safelight", "year": 1995, "store": "B. DALTON BOOKSELLER", "price": 2195},
}


def silver(im, xy, s, font):
    w, h = im.size
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).text(xy, s, font=font, fill=255, anchor="mm")
    bb = mask.getbbox()
    im.paste(Image.new("RGBA", (w, h), (0, 0, 0, 255)), (4, 5), mask.filter(ImageFilter.GaussianBlur(3)))
    if bb:
        g = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        g.paste(B.gradient(w, bb[3] - bb[1], (250, 250, 250), (140, 140, 146)), (0, bb[1]))
        im.paste(g, (0, 0), mask)


def film_strip(d, x0, y0, x1, y1, frames, rng, face_frame=1):
    """A strip of 35 mm negatives: orange-brown base, sprocket holes, dark frames, one with a pale face."""
    ang = math.atan2(y1 - y0, x1 - x0)
    ln = math.hypot(x1 - x0, y1 - y0)
    hw = 70
    ca, sa = math.cos(ang), math.sin(ang)
    P = lambda u, v: (x0 + u * ca - v * sa, y0 + u * sa + v * ca)
    d.polygon([P(0, -hw), P(ln, -hw), P(ln, hw), P(0, hw)], fill=(120, 60, 30, 255))
    for k in range(int(ln / 22)):
        for v in (-hw + 12, hw - 20):
            u = 8 + k * 22
            d.polygon([P(u, v), P(u + 11, v), P(u + 11, v + 8), P(u, v + 8)], fill=(10, 4, 2, 255))
    fw = ln / frames
    for k in range(frames):
        u0 = k * fw + 10
        d.polygon([P(u0, -hw + 26), P(u0 + fw - 20, -hw + 26), P(u0 + fw - 20, hw - 28), P(u0, hw - 28)], fill=(40, 30, 26, 255))
        if k == face_frame:   # negative: the face is dark on light
            cu, cv = u0 + (fw - 20) / 2, 0
            d.polygon([P(u0, -hw + 26), P(u0 + fw - 20, -hw + 26), P(u0 + fw - 20, hw - 28), P(u0, hw - 28)], fill=(200, 170, 140, 255))
            pts = [P(cu + 26 * math.cos(a), cv + 34 * math.sin(a)) for a in [i / 16 * math.tau for i in range(16)]]
            d.polygon(pts, fill=(60, 40, 30, 255))
            for ex in (-9, 9):
                d.ellipse([*P(cu + ex - 4, -8), *P(cu + ex + 4, -2)], fill=(230, 220, 200, 255))


def front():
    rng = random.Random(SEED)
    im, _ = B.canvas_for(W, L, PPM, (8, 4, 4, 255))
    w, h = im.size
    glow = Image.new("L", (w, h), 0)
    ImageDraw.Draw(glow).ellipse((w * 0.2, -h * 0.25, w * 1.2, h * 0.45), fill=150)
    im.paste(Image.new("RGBA", (w, h), RED + (255,)), (0, 0), glow.filter(ImageFilter.GaussianBlur(w * 0.18)))
    d = ImageDraw.Draw(im)
    # the safelight lamp, top right
    d.rectangle((w * 0.72, h * 0.03, w * 0.9, h * 0.1), fill=(30, 26, 24, 255))
    d.rectangle((w * 0.74, h * 0.1, w * 0.88, h * 0.12), fill=(255, 70, 50, 255))
    # the drying line with a print pinned to it
    d.line((0, h * 0.30, w, h * 0.26), fill=(150, 150, 150, 255), width=3)
    px0, py0 = w * 0.18, h * 0.29
    d.rectangle((px0, py0, px0 + w * 0.34, py0 + w * 0.42), fill=(150, 30, 26, 255), outline=(230, 200, 190, 255), width=8)
    # the print: a dim doorway and a figure standing in it
    d.rectangle((px0 + w * 0.12, py0 + w * 0.10, px0 + w * 0.22, py0 + w * 0.36), fill=(40, 6, 6, 255))
    d.ellipse((px0 + w * 0.155, py0 + w * 0.15, px0 + w * 0.185, py0 + w * 0.185), fill=(110, 16, 14, 255))
    d.polygon([(px0 + w * 0.145, py0 + w * 0.36), (px0 + w * 0.15, py0 + w * 0.19), (px0 + w * 0.19, py0 + w * 0.19), (px0 + w * 0.195, py0 + w * 0.36)], fill=(110, 16, 14, 255))
    for cx in (px0 + w * 0.05, px0 + w * 0.29):
        d.rectangle((cx - 8, py0 - 26, cx + 8, py0 + 14), fill=(196, 160, 110, 255))
    film_strip(d, -w * 0.05, h * 0.70, w * 1.05, h * 0.58, 4, rng)
    silver(im, (w / 2, h * 0.86), TITLE, B.ff("Oswald-Bold.ttf", w * 0.19))
    d = ImageDraw.Draw(im)
    d.text((w / 2, h * 0.955), AUTHOR, font=B.ff("Oswald-Light.ttf", w * 0.07), fill=(236, 220, 214, 255), anchor="mm")
    d.text((w / 2, h * 0.775), "WHAT DEVELOPS IN THE DARK", font=B.ff("Oswald-Light.ttf", w * 0.042), fill=(230, 120, 110, 255), anchor="mm")
    B.wear(im, rng, 90, (60, 50, 50))
    return labels.save(im, "bd_dark_front")


def back():
    rng = random.Random(SEED + 1)
    im, _ = B.canvas_for(W, L, PPM, (10, 6, 6, 255))
    w, h = im.size
    d = ImageDraw.Draw(im)
    d.text((w / 2, h * 0.09), "“I couldn't turn the lights back on.”", font=labels.font("italic", w * 0.05), fill=(230, 120, 110, 255), anchor="mm")
    d.text((w / 2, h * 0.13), "— Gulf Coast Courier", font=labels.font("sans", w * 0.035), fill=(200, 190, 186, 255), anchor="mm")
    blurb = ["Newspaper photographer Josie Arceneaux", "develops a roll of film she doesn't",
             "remember shooting. Every frame shows", "her own front door, from inside the house.", "",
             "The last frame was taken tonight."]
    for i, s in enumerate(blurb):
        d.text((w * 0.09, h * (0.24 + i * 0.05)), s, font=labels.font("sans", w * 0.045), fill=(236, 228, 224, 255), anchor="lm")
    d.text((w / 2, h * 0.62), "A NOVEL OF SUSPENSE", font=B.ff("Oswald-Bold.ttf", w * 0.05), fill=(230, 120, 110, 255), anchor="mm")
    d.text((w / 2, h * 0.69), "“Lanoux keeps you up past midnight.”", font=labels.font("italic", w * 0.042), fill=(236, 228, 224, 255), anchor="mm")
    B.barcode(d, (w * 0.56, h * 0.84, w * 0.92, h * 0.95), rng)
    st = B.price_sticker("$21.95", 300, 150).rotate(3, expand=True, resample=Image.BICUBIC)
    im.paste(st, (int(w * 0.08), int(h * 0.84)), st)
    B.wear(im, rng, 90, (60, 50, 50))
    return labels.save(im, "bd_dark_back")


def spine():
    im, d = B.spine_canvas(L, T, PPM, (10, 6, 6, 255))
    w, h = im.size
    silver(im, (w * 0.38, h * 0.5), TITLE, B.ff("Oswald-Bold.ttf", h * 0.6))
    d = ImageDraw.Draw(im)
    d.text((w * 0.76, h * 0.5), "LANOUX", font=B.ff("Oswald-Light.ttf", h * 0.42), fill=(236, 220, 214, 255), anchor="mm")
    d.rectangle((w * 0.9, h * 0.3, w * 0.94, h * 0.7), fill=RED + (255,))
    return labels.save(im, "bd_dark_spine")


def build():
    B.build_book("hard", W, L, T, front(), back(), spine(), base="#0a0606", rough=0.28, endpaper="#2a1414")
