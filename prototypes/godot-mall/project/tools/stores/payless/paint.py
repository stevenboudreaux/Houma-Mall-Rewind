"""Textures for Payless ShoeSource's walk-in store (1995 map, store s4; tools/stores/payless/store.gd), written to
tex/pay/. Read off the 2019 closing-sale video Steven chose (refs/new/payless, design/storefronts/payless.md),
without any of the sale signage. Shoes, boxes, bags and packs are invented generic paintings: no brand
names, no box art from the video (IP rule).

  python3 tools/stores/payless/paint.py   (from the project folder)
"""
import math, os, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "..", "tex", "pay")
os.makedirs(OUT, exist_ok=True)
BOLD = "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf"
R = random.Random(4)
RN = np.random.default_rng(4)


def save(im, name):
    im.convert("RGB").save(os.path.join(OUT, name + ".png"), optimize=True)


def noise(im, amt=3.0):
    a = np.asarray(im.convert("RGB")).astype(np.float32)
    a += RN.normal(0, amt, a.shape)
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


def jit(c, k=10):
    return tuple(max(0, min(255, v + R.randint(-k, k))) for v in c)


# the boxes' looks (gacc... no: payless2019_t000_019-047, 087-145, 173-185): red-and-white, white, black,
# brown kraft, pink, a printed white-and-black one; lids tucked behind
BOXES = [((206, 30, 40), (246, 244, 240)), ((246, 244, 240), (206, 30, 40)), ((30, 30, 32), (206, 30, 40)),
         ((150, 110, 70), (230, 214, 190)), ((236, 110, 160), (246, 244, 240)), ((246, 244, 240), (40, 40, 44)),
         ((180, 200, 120), (246, 244, 240))]
KINDS = {
    "dress": [(20, 20, 22), (120, 70, 40), (230, 210, 180), (200, 30, 50), (190, 190, 196), (240, 200, 190)],
    "sneaker": [(246, 246, 244), (246, 246, 244), (30, 30, 34), (220, 120, 170), (80, 150, 220), (120, 120, 126)],
    "sandal": [(200, 160, 110), (30, 30, 32), (230, 200, 160), (220, 70, 80), (240, 240, 236), (190, 150, 60)],
    "boot": [(60, 40, 26), (30, 30, 32), (160, 120, 80), (120, 110, 100), (90, 60, 40), (200, 180, 150)],
}


def shoe(d, cx, base, w, kind, col):
    """A shoe lying in its box, seen from above and in front (toe to the right)."""
    x0, x1 = cx - w / 2, cx + w / 2
    dk = tuple(int(v * 0.7) for v in col)
    if kind == "dress":
        d.polygon([(x0, base), (x1, base), (x1 - w * 0.05, base - w * 0.18), (x0 + w * 0.35, base - w * 0.12), (x0 + w * 0.1, base - w * 0.42), (x0, base - w * 0.42)], fill=col)
        d.rectangle([x0, base - w * 0.42, x0 + w * 0.08, base], fill=dk)
    elif kind == "sneaker":
        d.rounded_rectangle([x0, base - w * 0.34, x1, base], radius=w * 0.12, fill=col)
        d.rectangle([x0, base - w * 0.08, x1, base], fill=(240, 240, 236))
        for k in range(4):
            d.line([(cx - w * 0.15 + k * w * 0.08, base - w * 0.32), (cx - w * 0.1 + k * w * 0.08, base - w * 0.2)], fill=dk, width=3)
    elif kind == "sandal":
        d.rectangle([x0, base - w * 0.08, x1, base], fill=(200, 170, 120))
        for k in range(3):
            xx = x0 + w * (0.2 + k * 0.28)
            d.arc([xx - w * 0.12, base - w * 0.3, xx + w * 0.12, base], 180, 360, fill=col, width=6)
    else:
        d.polygon([(x0, base), (x1, base), (x1, base - w * 0.2), (x0 + w * 0.45, base - w * 0.25), (x0 + w * 0.42, base - w * 0.7), (x0, base - w * 0.7)], fill=col)
        d.line([(x0 + w * 0.05, base - w * 0.6), (x0 + w * 0.4, base - w * 0.6)], fill=dk, width=3)


def shelves():
    """The sloped shelves of open shoe boxes (019-047, 121, 305): 4 rows (dress, sneaker, sandal, boot),
    each 1.2 m of shelf seen square-on: 5 open boxes, a shoe in each, the lid tucked up behind, the size
    tag on the box end. 1024 x 256 a row."""
    W, H = 1024, 1024
    im = Image.new("RGB", (W, H), (236, 234, 228))
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(BOLD, 18)
    for row, kind in enumerate(["dress", "sneaker", "sandal", "boot"]):
        y0 = row * 256
        d.rectangle([0, y0, W, y0 + 256], fill=(224, 222, 216))
        n = 5
        bw = W / n
        for k in range(n):
            x0 = k * bw
            body, trim = R.choice(BOXES)
            body = jit(body, 6)
            # the lid standing up behind, the box's inside, its front wall with the end label
            d.rectangle([x0 + 6, y0 + 8, x0 + bw - 6, y0 + 70], fill=tuple(int(v * 0.92) for v in body))
            d.rectangle([x0 + 6, y0 + 60, x0 + bw - 6, y0 + 74], fill=trim)
            d.rectangle([x0 + 4, y0 + 74, x0 + bw - 4, y0 + 200], fill=(232, 228, 220) if body[0] > 120 else (70, 66, 62))
            shoe(d, x0 + bw * 0.5, y0 + 190, bw * 0.82, kind, jit(R.choice(KINDS[kind]), 8))
            d.rectangle([x0 + 2, y0 + 196, x0 + bw - 2, y0 + 246], fill=body)
            d.rectangle([x0 + 2, y0 + 196, x0 + bw - 2, y0 + 204], fill=trim)
            d.rectangle([x0 + bw * 0.62, y0 + 212, x0 + bw * 0.9, y0 + 238], fill=(250, 250, 250))
            d.text((x0 + bw * 0.66, y0 + 214), R.choice(["5", "6", "7", "8", "9", "10", "7W", "8M"]), font=f, fill=(20, 20, 20))
        d.rectangle([0, y0 + 246, W, y0 + 256], fill=(246, 246, 244))
    save(noise(im, 2), "shelves")


def wood():
    """The wood-look plank floor at the front (001-009, 189, 307): light honey oak, 1.2 x 0.2 m planks.
    One tile = 2.4 x 1.2 m."""
    W, H = 1024, 512
    im = Image.new("RGB", (W, H), (190, 140, 84))
    d = ImageDraw.Draw(im)
    ph = H / 6
    for j in range(6):
        x = -R.uniform(0, W / 2)
        while x < W:
            pw = W / 2
            base = R.choice([(196, 146, 88), (204, 156, 96), (186, 134, 78), (210, 164, 104)])
            d.rectangle([x, j * ph, x + pw - 2, (j + 1) * ph - 2], fill=base)
            for _ in range(18):
                y = j * ph + R.uniform(3, ph - 5)
                xx = x + R.uniform(0, pw * 0.7)
                d.line([(xx, y), (xx + R.uniform(40, 160), y + R.uniform(-1, 1))], fill=tuple(int(v * R.uniform(0.85, 0.95)) for v in base), width=1)
            x += pw
        d.line([(0, (j + 1) * ph - 1), (W, (j + 1) * ph - 1)], fill=(130, 92, 52), width=2)
    save(noise(im, 2.5).filter(ImageFilter.GaussianBlur(0.4)), "wood")


def carpet():
    """The aisles' loop carpet (017, 161-165, 305): grey-brown with fine darker stripes. One tile = 1 m."""
    W = 256
    im = Image.new("RGB", (W, W), (112, 104, 94))
    d = ImageDraw.Draw(im)
    for x in range(0, W, 6):
        d.line([(x, 0), (x, W)], fill=jit((92, 84, 76), 6), width=2)
    save(noise(im, 9).filter(ImageFilter.GaussianBlur(0.6)), "carpet")


def slatwall():
    """White slatwall (005, 189-251): 3 inch grooves. One tile = 1.2 x 1.2 m."""
    W = 256
    im = Image.new("RGB", (W, W), (244, 242, 236))
    d = ImageDraw.Draw(im)
    step = W / 16
    for k in range(16):
        y = k * step
        d.rectangle([0, y + step - 4, W, y + step - 1], fill=(170, 168, 162))
        d.line([(0, y + step - 5), (W, y + step - 5)], fill=(255, 255, 252))
    save(noise(im, 1.2), "slatwall")


def pegs():
    """Peg goods for the end caps and the accessory wall (005, 205-241), 1995-appropriate and invented:
    socks in 3-packs, knee-highs, shoe polish cards, insoles, laces. 1.2 x 1.2 m."""
    W = 512
    im = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(BOLD, 14)
    for j in range(4):
        for i in range(6):
            x0, y0 = 10 + i * 84, 18 + j * 124
            kind = (i + j) % 5
            if kind == 0:   # socks 3-pack: a header card over folded socks
                for s in range(3):
                    d.rectangle([x0 + s * 6, y0 + 22 + s * 4, x0 + 60 + s * 6, y0 + 100], fill=jit(R.choice([(246, 246, 244), (30, 30, 34), (120, 120, 126)]), 6))
                d.rectangle([x0, y0, x0 + 72, y0 + 26], fill=(40, 90, 180))
                d.text((x0 + 8, y0 + 5), "SOCKS", font=f, fill=(255, 255, 255))
            elif kind == 1:  # knee-highs: a slim box
                d.rectangle([x0 + 8, y0, x0 + 60, y0 + 104], fill=(232, 210, 196))
                d.rectangle([x0 + 8, y0, x0 + 60, y0 + 24], fill=(150, 40, 90))
            elif kind == 2:  # shoe polish on a card
                d.rectangle([x0 + 4, y0, x0 + 68, y0 + 90], fill=(246, 200, 40))
                d.ellipse([x0 + 16, y0 + 34, x0 + 56, y0 + 74], fill=R.choice([(30, 30, 30), (110, 70, 40), (240, 240, 240)]))
            elif kind == 3:  # insoles
                d.rectangle([x0 + 4, y0, x0 + 68, y0 + 108], fill=(220, 236, 246))
                d.ellipse([x0 + 14, y0 + 20, x0 + 34, y0 + 100], fill=(70, 160, 210))
                d.ellipse([x0 + 38, y0 + 20, x0 + 58, y0 + 100], fill=(70, 160, 210))
            else:            # laces
                d.rectangle([x0 + 14, y0, x0 + 58, y0 + 96], fill=(246, 246, 244))
                for k in range(5):
                    d.line([(x0 + 20, y0 + 30 + k * 12), (x0 + 52, y0 + 30 + k * 12)], fill=R.choice([(30, 30, 30), (200, 30, 40), (240, 240, 240)]), width=4)
            d.ellipse([x0 + 32, y0 - 10, x0 + 40, y0 - 2], outline=(120, 120, 120), width=2)
    bg = Image.new("RGB", (W, W), (244, 242, 236))
    sl = Image.open(os.path.join(OUT, "slatwall.png")).resize((W, W))
    bg.paste(sl, (0, 0))
    bg.paste(im, (0, 0), im)
    save(noise(bg, 1.2), "pegs")


def bags():
    """The bags wall (219-289), invented and plain: shoulder bags, totes, backpacks, clutches on the
    slatwall's shelves and hooks. 2.4 x 1.2 m."""
    W, H = 1024, 512
    im = Image.new("RGB", (W, H), (244, 242, 236))
    sl = Image.open(os.path.join(OUT, "slatwall.png")).resize((256, 256))
    for x in range(0, W, 256):
        for y in range(0, H, 256):
            im.paste(sl, (x, y))
    d = ImageDraw.Draw(im)
    cols = [(30, 30, 32), (150, 30, 40), (120, 80, 50), (230, 200, 170), (60, 90, 160), (220, 120, 160), (90, 120, 80)]
    for k in range(7):     # backpacks on hooks, upper row
        x = 30 + k * 140
        c = jit(R.choice(cols), 8)
        d.rounded_rectangle([x, 40, x + 110, 210], radius=30, fill=c)
        d.rounded_rectangle([x + 18, 120, x + 92, 200], radius=14, fill=tuple(int(v * 0.8) for v in c))
        d.arc([x + 30, 10, x + 80, 60], 180, 360, fill=(40, 40, 40), width=6)
    d.rectangle([0, 290, W, 300], fill=(220, 218, 212))
    for k in range(9):     # bags standing on the shelf
        x = 14 + k * 112
        c = jit(R.choice(cols), 8)
        d.rectangle([x, 380, x + 96, 460], fill=c)
        d.arc([x + 18, 320, x + 78, 420], 180, 360, fill=tuple(int(v * 0.7) for v in c), width=8)
        d.rectangle([x, 460, x + 96, 470], fill=(220, 218, 212))
    save(noise(im, 1.5), "bags")


def headers():
    """Category header panels over the wall shelving (invented 1995 look: white letters on red with a
    yellow rule). 4 across: WOMEN, MEN, KIDS, ATHLETIC."""
    W, H = 1024, 128
    im = Image.new("RGB", (W, H), (200, 30, 40))
    d = ImageDraw.Draw(im)
    f = ImageFont.truetype(BOLD, 64)
    for k, t in enumerate(["WOMEN", "MEN", "KIDS", "ATHLETIC"]):
        x0 = k * 256
        d.rectangle([x0, 0, x0 + 255, H], fill=(200, 30, 40))
        d.rectangle([x0, H - 16, x0 + 255, H], fill=(246, 196, 40))
        w = d.textlength(t, font=f) if k != 3 else d.textlength(t, font=ImageFont.truetype(BOLD, 44))
        ff = f if k != 3 else ImageFont.truetype(BOLD, 44)
        d.text((x0 + 128 - w / 2, 22 if k != 3 else 34), t, font=ff, fill=(255, 255, 255))
    save(im, "headers")


def mat():
    """The orange try-on mat (177, 183, 249): an oval of rust orange with rings of darker circles."""
    W, H = 512, 256
    im = Image.new("RGB", (W, H), (0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse([2, 2, W - 2, H - 2], fill=(214, 110, 40))
    d.ellipse([10, 10, W - 10, H - 10], outline=(170, 70, 24), width=6)
    for j in range(5):
        for i in range(11):
            cx, cy = 40 + i * 44 + (22 if j % 2 else 0), 34 + j * 46
            if ((cx - W / 2) / (W / 2 - 24)) ** 2 + ((cy - H / 2) / (H / 2 - 24)) ** 2 < 1.0:
                d.ellipse([cx - 14, cy - 14, cx + 14, cy + 14], outline=(176, 74, 26), width=4)
                d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(176, 74, 26))
    a = Image.new("L", (W, H), 0)
    ImageDraw.Draw(a).ellipse([2, 2, W - 2, H - 2], fill=255)
    im.putalpha(a)
    im.save(os.path.join(OUT, "mat.png"), optimize=True)   # RGBA: the oval cut out (alpha scissor)


if __name__ == "__main__":
    shelves(); wood(); carpet(); slatwall(); pegs(); bags(); headers(); mat()
    print("wrote", sorted(f for f in os.listdir(OUT) if f.endswith(".png")))
