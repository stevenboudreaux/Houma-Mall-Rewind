"""Textures for Auntie Anne's (2026, store n56; tools/stores/auntie_annes/store.gd), written to tex/aa/.
Read off Steven's footage: refs/derived/frames/IMG_4439 f024-f025 (Southland, Oct 23 2026) and the clip
refs/new/auntie_annes (the warmer, the blue counter front). Menu screens and signs carry invented lines
(IP rule); the pretzel mark on the counter front is the tenant's own sign, simplified.
design/storefronts/auntie-annes.md.

  python3 tools/stores/auntie_annes/paint.py   (from the project folder)
"""
import math, os, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "..", "tex", "aa")
os.makedirs(OUT, exist_ok=True)
BOLD = "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf"
SANS = "/usr/share/fonts/truetype/freefont/FreeSans.ttf"
R = random.Random(56)
RN = np.random.default_rng(56)
NAVY = (28, 42, 110)
ROYAL = (30, 60, 190)
GOLD = (246, 196, 40)
ORANGE = (232, 120, 48)


def save(im, name):
    im.convert("RGB").save(os.path.join(OUT, name + ".png"), optimize=True)


def noise(im, amt=3.0):
    a = np.asarray(im.convert("RGB")).astype(np.float32)
    a += RN.normal(0, amt, a.shape)
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


def oak():
    """The counter's light wood-look boards (f024-f025), horizontal, 15 cm boards. One tile = 1.2 x 0.6 m."""
    W, H = 512, 256
    im = Image.new("RGB", (W, H), (200, 160, 110))
    d = ImageDraw.Draw(im)
    bh = H / 4
    for j in range(4):
        base = R.choice([(204, 164, 112), (196, 154, 102), (210, 172, 122), (190, 148, 98)])
        d.rectangle([0, j * bh, W, (j + 1) * bh - 2], fill=base)
        for _ in range(40):
            y = j * bh + R.uniform(3, bh - 5)
            x0 = R.uniform(-50, W)
            d.line([(x0, y), (x0 + R.uniform(60, 220), y + R.uniform(-1.5, 1.5))], fill=tuple(int(v * R.uniform(0.86, 0.95)) for v in base), width=1)
        d.line([(0, (j + 1) * bh - 1), (W, (j + 1) * bh - 1)], fill=(150, 112, 70), width=2)
    save(noise(im, 2.5).filter(ImageFilter.GaussianBlur(0.5)), "oak")


def subway():
    """White subway tile 7.5 x 15 cm, running bond, light grout (f025's back wall). One tile = 0.6 x 0.6 m."""
    W = 512
    px = W / 0.6
    im = Image.new("RGB", (W, W), (214, 212, 206))
    d = ImageDraw.Draw(im)
    tw, th = 0.15 * px, 0.075 * px
    for j in range(int(W / th) + 1):
        off = (tw / 2) * (j % 2)
        x = -off
        while x < W:
            c = tuple(max(0, min(255, v + R.randint(-3, 3))) for v in (248, 248, 245))
            d.rectangle([x + 1.5, j * th + 1.5, x + tw - 1.5, j * th + th - 1.5], fill=c)
            x += tw
    save(noise(im, 1.2), "subway")


def geo():
    """The band of big geometric shapes over the tile (f025): orange, navy, cream, violet and royal blue
    triangles and bars. One tile = 2.4 x 0.8 m."""
    W, H = 1024, 340
    im = Image.new("RGB", (W, H), (244, 236, 222))
    d = ImageDraw.Draw(im)
    cols = [ORANGE, NAVY, (244, 236, 222), (98, 70, 160), ROYAL, (240, 160, 90)]
    x = 0
    k = 0
    while x < W:
        w = R.randint(110, 190)
        c = cols[k % len(cols)]
        if k % 3 == 0:
            d.polygon([(x, H), (x + w, H), (x + w * 0.6, 0)], fill=c)
        elif k % 3 == 1:
            d.polygon([(x, 0), (x + w, 0), (x + w * 0.3, H)], fill=c)
        else:
            d.polygon([(x, 0), (x + w * 0.5, 0), (x + w, H), (x + w * 0.4, H)], fill=c)
        x += int(w * 0.7)
        k += 1
    d.rectangle([0, H - 10, W, H], fill=(250, 250, 248))
    save(noise(im, 1.5), "geo")


def screens():
    """Three digital menu screens over the opening (f025): royal-blue screens, pictures of pretzels and
    cups, invented lines. 3 across, each 16:9."""
    W, H = 1536, 288
    im = Image.new("RGB", (W, H), (16, 16, 18))
    d = ImageDraw.Draw(im)
    heads = ["PRETZELS", "BITES & NUGGETS", "LEMONADE & MORE"]
    for k in range(3):
        x0 = k * 512
        d.rectangle([x0 + 6, 6, x0 + 506, H - 6], fill=(232, 240, 252))
        d.rectangle([x0 + 6, 6, x0 + 506, 64], fill=ROYAL)
        f = ImageFont.truetype(BOLD, 32)
        w = d.textlength(heads[k], font=f)
        d.text((x0 + 256 - w / 2, 18), heads[k], font=f, fill=(255, 255, 255))
        for j in range(5):
            y = 90 + j * 34
            d.line([(x0 + 24, y), (x0 + 24 + R.randint(110, 200), y)], fill=(40, 40, 60), width=10)
            d.line([(x0 + 250, y), (x0 + 290, y)], fill=NAVY, width=10)
        cx, cy = x0 + 410, 170
        if k == 2:
            d.polygon([(cx - 40, cy - 70), (cx + 40, cy - 70), (cx + 30, cy + 80), (cx - 30, cy + 80)], fill=(250, 226, 90))
            d.rectangle([cx - 38, cy - 80, cx + 38, cy - 68], fill=(250, 250, 250))
        else:
            pretzel(d, cx, cy, 62, (190, 104, 42), 16)
    save(noise(im, 1.0), "screens")


def pretzel(d, cx, cy, r, col, wd):
    """A drawn pretzel: the belly, two lobes, the crossing ends."""
    d.arc([cx - r, cy - r * 0.9, cx + r, cy + r], 160, 380, fill=col, width=wd)
    d.ellipse([cx - r, cy - r * 0.95, cx, cy + r * 0.1], outline=col, width=wd)
    d.ellipse([cx, cy - r * 0.95, cx + r, cy + r * 0.1], outline=col, width=wd)
    d.line([(cx - r * 0.55, cy + r * 0.75), (cx + r * 0.25, cy - r * 0.2)], fill=col, width=wd)
    d.line([(cx + r * 0.55, cy + r * 0.75), (cx - r * 0.25, cy - r * 0.2)], fill=col, width=wd)


def front():
    """The warmer's base front (the clip, aa_t000_001-031; f025): royal blue, the tenant's pretzel mark with its
    halo and ring, a navy strip of invented words over it. 1.5 x 0.85 m, 1024 px wide.
    FOOD3D (Nov 8 2026, Steven: match the sign above): the pretzel is the sign's own traced shape
    (tools/stores/signs/y26/src/auntie_pretzel_mask.png, the channel-letter pretzel on the fascia) in the sign's
    yellow (face #f4b80a, trim #d99f00), with a halo over it in the same yellow, on a navy disc (the fascia's
    #24316b) inside a ring in the letters' blue (#1f3fff, lit edge #2a4bff). The store wordmark is not repeated."""
    W, H = 1024, 580
    SY, ST = (244, 184, 10), (217, 159, 0)
    FASCIA, LBLUE, LGLOW = (36, 49, 107), (31, 63, 255), (42, 75, 255)
    S = 4                                   # paint at 4x, then downsample: clean edges
    im = Image.new("RGB", (W * S, H * S), ROYAL)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, W * S, 86 * S], fill=NAVY)
    f = ImageFont.truetype(BOLD, 46 * S)
    t = "HOT  \u2022  FRESH  \u2022  ROLLED BY HAND"
    w = d.textlength(t, font=f)
    d.text((W * S / 2 - w / 2, 18 * S), t, font=f, fill=(255, 255, 255))
    cx, cy, R0 = W * S / 2, 340 * S, 205 * S
    d.ellipse([cx - R0, cy - R0, cx + R0, cy + R0], fill=LGLOW)
    d.ellipse([cx - R0 + 8 * S, cy - R0 + 8 * S, cx + R0 - 8 * S, cy + R0 - 8 * S], fill=LBLUE)
    d.ellipse([cx - R0 + 26 * S, cy - R0 + 26 * S, cx + R0 - 26 * S, cy + R0 - 26 * S], fill=FASCIA)
    # the sign's pretzel: its traced mask, trim colour grown 3 px under the face colour
    mp = os.path.join(HERE, "..", "signs", "y26", "src", "auntie_pretzel_mask.png")
    mask = Image.open(mp).convert("L")
    bb = mask.getbbox()
    mask = mask.crop(bb)
    ph = int(215 * S)
    pw = int(mask.width * ph / mask.height)
    mask = mask.resize((pw, ph), Image.LANCZOS)
    px, py = int(cx - pw / 2), int(cy - ph / 2 + 30 * S)
    trim = mask.filter(ImageFilter.MaxFilter(2 * 3 * S + 1))
    im.paste(Image.new("RGB", trim.size, ST), (px, py), trim)
    im.paste(Image.new("RGB", mask.size, SY), (px, py), mask)
    # the halo over it, the same yellow and trim
    hw, hh, ht = 170 * S, 46 * S, 9 * S
    hy = py - 34 * S
    d.ellipse([cx - hw / 2 - 3 * S, hy - hh / 2 - 3 * S, cx + hw / 2 + 3 * S, hy + hh / 2 + 3 * S], outline=ST, width=ht + 6 * S)
    d.ellipse([cx - hw / 2, hy - hh / 2, cx + hw / 2, hy + hh / 2], outline=SY, width=ht)
    im = im.resize((W, H), Image.LANCZOS)
    save(noise(im, 1.0), "front")


def rolltop():
    """The rolling counter's top seen from the front: white solid surface, flour dust, dough balls, a few
    rolled ropes, a tray of twisted raw pretzels. 2.4 x 0.6 m."""
    W, H = 1024, 256
    im = Image.new("RGB", (W, H), (240, 238, 232))
    d = ImageDraw.Draw(im)
    for _ in range(600):
        x, y = R.uniform(0, W), R.uniform(0, H)
        d.point((x, y), fill=(252, 250, 244))
    # (Nov 4: darker, bigger dough than the first pass, which vanished against the white top)
    for k in range(8):
        cx, cy = 50 + k * 40, 80 + (k % 2) * 60
        d.ellipse([cx - 22, cy - 20, cx + 22, cy + 20], fill=(224, 196, 148), outline=(176, 146, 100), width=3)
    for k in range(5):
        y = 120 + k * 24
        d.line([(380, y), (650, y + R.uniform(-6, 6))], fill=(218, 186, 136), width=13)
    d.rectangle([700, 30, 1000, 226], fill=(128, 130, 136), outline=(96, 98, 104), width=4)
    for j in range(2):
        for i in range(3):
            pretzel(d, 752 + i * 98, 80 + j * 92, 36, (222, 188, 132), 10)
    save(noise(im, 1.5), "rolltop")


def sign_rolling():
    """A small navy hanging sign: a gold pretzel and FRESH ROLLED (invented words; f025's sign there)."""
    W, H = 512, 96
    im = Image.new("RGB", (W, H), NAVY)
    d = ImageDraw.Draw(im)
    pretzel(d, 56, 46, 30, GOLD, 8)
    f = ImageFont.truetype(BOLD, 44)
    d.text((110, 22), "FRESH ROLLED", font=f, fill=(255, 255, 255))
    save(im, "sign_rolling")


if __name__ == "__main__":
    oak(); subway(); geo(); screens(); front(); rolltop(); sign_rolling()
    print("wrote", sorted(f for f in os.listdir(OUT) if f.endswith(".png")))
