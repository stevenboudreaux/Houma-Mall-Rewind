"""Textures for the 1995 additions (tools/stores/y95/extras.gd), written to tex/y95/: popcorn in four
colours, the Beetle's white body with coloured handprints, and four period-style poster panels for
Gadzooks (invented art after the store's ads: checker, floral, skate, surf; no brand marks).

  python3 tools/stores/y95/paint.py   (from the project folder)
"""
import math, os, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "..", "tex", "y95")
os.makedirs(OUT, exist_ok=True)
R = random.Random(95)
BOLD = "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf"


def save(im, name):
    im.convert("RGB").save(os.path.join(OUT, name + ".png"), optimize=True)


def corn(name, base, hi):
    """Popped kernels, close packed: blobs of `base` with `hi` highlights. 256 px = 0.33 m."""
    N = 256
    im = Image.new("RGB", (N, N), tuple(int(v * 0.6) for v in base))
    d = ImageDraw.Draw(im)
    for _ in range(420):
        x, y = R.randint(-8, N), R.randint(-8, N); r = R.randint(6, 12)
        c = tuple(max(0, min(255, v + R.randint(-20, 20))) for v in base)
        d.ellipse([x - r, y - r, x + r, y + r], fill=c)
        d.ellipse([x - r * 0.4, y - r * 0.5, x + r * 0.2, y], fill=hi)
    save(im.filter(ImageFilter.GaussianBlur(0.6)), name)


def hand(d, cx, cy, s, ang, col):
    """A painted handprint: a palm and five fingers, rotated by ang."""
    ca, sa = math.cos(ang), math.sin(ang)
    def rot(x, y):
        return (cx + (x * ca - y * sa) * s, cy + (x * sa + y * ca) * s)
    palm = [rot(x, y) for x, y in [(-1.0, 0.0), (1.0, 0.0), (1.1, 1.4), (-1.1, 1.4)]]
    d.polygon(palm, fill=col)
    d.ellipse([rot(-1.1, 1.0)[0] - 1.2 * s, rot(-1.1, 1.0)[1] - 1.0 * s, rot(-1.1, 1.0)[0] + 1.2 * s, rot(-1.1, 1.0)[1] + 1.0 * s], fill=col)
    for fx, ln in [(-0.8, 1.6), (-0.25, 1.9), (0.3, 1.8), (0.8, 1.4)]:
        p0 = rot(fx, 0.0); p1 = rot(fx, -ln)
        d.line([p0, p1], fill=col, width=int(0.45 * s))
        d.ellipse([p1[0] - 0.22 * s, p1[1] - 0.22 * s, p1[0] + 0.22 * s, p1[1] + 0.22 * s], fill=col)
    p0 = rot(1.0, 1.0); p1 = rot(2.0, 0.2)
    d.line([p0, p1], fill=col, width=int(0.5 * s))


def beetle():
    """White paint, handprints in red, yellow, blue, purple, green, orange (the photo)."""
    N = 1024
    im = Image.new("RGB", (N, N), (244, 242, 236))
    d = ImageDraw.Draw(im)
    cols = [(200, 40, 50), (240, 200, 40), (50, 90, 200), (150, 90, 200), (60, 160, 80), (240, 140, 40), (90, 160, 220)]
    for _ in range(70):
        hand(d, R.randint(0, N), R.randint(0, N), R.randint(10, 16), R.uniform(0, 6.28), R.choice(cols))
    save(im, "beetle")


def ads():
    """Four poster panels: a black/white checker with a red band, a 70s floral, a skater silhouette
    on orange, a wave on teal; slogan-free, a word each."""
    W, H = 1024, 512
    im = Image.new("RGB", (W, H), (20, 20, 20))
    d = ImageDraw.Draw(im)
    x0 = 0
    for y in range(0, H, 32):
        for x in range(0, 256, 32):
            d.rectangle([x0 + x, y, x0 + x + 31, y + 31], fill=(240, 240, 240) if (x // 32 + y // 32) % 2 == 0 else (20, 20, 20))
    d.rectangle([x0, 200, x0 + 255, 300], fill=(210, 40, 40))
    x0 = 256
    d.rectangle([x0, 0, x0 + 255, H], fill=(250, 220, 120))
    for _ in range(14):
        cx, cy = x0 + R.randint(20, 236), R.randint(20, 490)
        c = R.choice([(230, 80, 140), (250, 140, 40), (140, 200, 60), (90, 120, 220)])
        for k in range(6):
            a = k * math.pi / 3
            d.ellipse([cx + math.cos(a) * 22 - 14, cy + math.sin(a) * 22 - 14, cx + math.cos(a) * 22 + 14, cy + math.sin(a) * 22 + 14], fill=c)
        d.ellipse([cx - 10, cy - 10, cx + 10, cy + 10], fill=(250, 240, 200))
    x0 = 512
    d.rectangle([x0, 0, x0 + 255, H], fill=(240, 120, 30))
    d.polygon([(x0 + 70, 380), (x0 + 190, 380), (x0 + 180, 395), (x0 + 80, 395)], fill=(20, 20, 20))
    d.ellipse([x0 + 110, 120, x0 + 150, 160], fill=(20, 20, 20))
    d.line([(x0 + 130, 160), (x0 + 125, 260)], fill=(20, 20, 20), width=18)
    d.line([(x0 + 125, 260), (x0 + 95, 370)], fill=(20, 20, 20), width=14)
    d.line([(x0 + 125, 260), (x0 + 170, 370)], fill=(20, 20, 20), width=14)
    d.line([(x0 + 128, 190), (x0 + 70, 230)], fill=(20, 20, 20), width=12)
    d.line([(x0 + 128, 190), (x0 + 190, 170)], fill=(20, 20, 20), width=12)
    x0 = 768
    d.rectangle([x0, 0, x0 + 255, H], fill=(40, 170, 180))
    for k in range(5):
        d.arc([x0 - 60 + k * 10, 200 + k * 50, x0 + 300 - k * 10, 500 + k * 50], 180, 360, fill=(240, 250, 250), width=10)
    f = ImageFont.truetype(BOLD, 44)
    for k, word in enumerate(["CHECK", "BLOOM", "SKATE", "SURF"]):
        w = d.textlength(word, font=f)
        d.text((k * 256 + 128 - w / 2, 440), word, font=f, fill=(255, 255, 255), stroke_width=3, stroke_fill=(20, 20, 20))
    save(im, "gz_ads")


if __name__ == "__main__":
    corn("caramel", (196, 120, 40), (240, 180, 90))
    corn("cheese", (236, 140, 30), (250, 190, 70))
    corn("plain", (244, 236, 210), (255, 252, 240))
    corn("red", (200, 40, 60), (240, 110, 120))
    beetle(); ads()
    print("wrote", sorted(os.listdir(OUT)))
