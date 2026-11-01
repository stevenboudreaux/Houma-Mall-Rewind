"""Textures for Wicked Wingz (2026, store s64: the 1995 Chick-fil-A unit), written to tex/ww/*.png.
Read from Steven's Oct 23 2026 footage: IMG_4441 f003-f006 (the counter square on), IMG_4461
f028-f034 (the dining side from the hall). design/storefronts/wicked-wingz-2026.md.

  python3 tools/stores/wingz/paint.py   (from the project folder)

The menu lines and the food pictures are painted here (invented words and generic shapes, not
copied); the brand's own wordmark is fine on the sneeze-guard panels (IP rule: store signs and
tenant wordmarks only).
"""
import math, os, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "..", "tex", "ww")
os.makedirs(OUT, exist_ok=True)
BOLD = "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf"
BOLDI = "/usr/share/fonts/truetype/freefont/FreeSansBoldOblique.ttf"
SANS = "/usr/share/fonts/truetype/freefont/FreeSans.ttf"
R = random.Random(41)
RN = np.random.default_rng(41)
YEL = (245, 195, 15)


def save(im, name):
    im.convert("RGB").save(os.path.join(OUT, name + ".png"), optimize=True)


def font(p, s):
    return ImageFont.truetype(p, s)


def grime(im, amt=3.0, blotch=0.0):
    a = np.asarray(im.convert("RGB")).astype(np.float32)
    a += RN.normal(0, amt, a.shape)
    if blotch > 0:
        h, w = a.shape[:2]
        m = Image.new("L", (w // 16, h // 16))
        m.putdata([int(R.random() * 255) for _ in range((w // 16) * (h // 16))])
        m = np.asarray(m.resize((w, h), Image.BICUBIC).filter(ImageFilter.GaussianBlur(6))).astype(np.float32) / 255.0
        a -= (m[..., None] ** 3) * blotch * np.array([1.0, 1.05, 1.4])
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


def counter_tile():
    """The counter face: white 4-inch (10 cm) glazed tile in a grid, grey grout gone a little
    dingy, one row of small black accent tiles (half a tile wide, a full tile tall) every second
    tile, in the second course from the top (f006). One texture = 1.2 m along x 0.9 m of face
    height (9 courses down to the black kick, which is built separately)."""
    PX = 80          # px per 10 cm tile
    W, H = 12 * PX, 9 * PX
    im = Image.new("RGB", (W, H), (226, 224, 216))
    d = ImageDraw.Draw(im)
    for r in range(9):
        for c in range(12):
            x0, y0 = c * PX + 2, r * PX + 2
            sh = 238 + R.randint(-5, 4)
            d.rectangle([x0, y0, x0 + PX - 5, y0 + PX - 5], fill=(sh, sh, sh - 3))
            # glaze highlight along the top edge
            d.line([(x0 + 3, y0 + 3), (x0 + PX - 9, y0 + 3)], fill=(252, 252, 250), width=2)
    for c in range(0, 12, 2):
        x0 = c * PX + PX // 2 + 6
        d.rectangle([x0, 1 * PX + 8, x0 + PX // 2 - 6, 2 * PX - 4], fill=(22, 22, 24))
    save(grime(im, 2.0, 8), "counter_tile")


def floor_tile():
    """The store floor: light grey 12 x 12 in porcelain with darker grout, a few stains (f006:
    the store's tile stops at the front line, the hall's beige tile in front)."""
    N = 512   # 0.6 m: 2 x 2 tiles
    im = Image.new("RGB", (N, N), (150, 150, 146))
    d = ImageDraw.Draw(im)
    for r in range(2):
        for c in range(2):
            v = 214 + R.randint(-6, 4)
            d.rectangle([c * 256 + 3, r * 256 + 3, c * 256 + 252, r * 256 + 252], fill=(v, v, v - 4))
    save(grime(im, 3.0, 26), "floor")


def menu():
    """The hanging menu band, five lit panels (f006): black boards with a red-orange fire glow
    along the bottom, white lines of invented menu text, a painted food picture on each."""
    PW, H = 400, 220
    im = Image.new("RGB", (PW * 5, H), (14, 12, 12))
    d = ImageDraw.Draw(im)
    titles = [("WINGS", "8 FLAVORS"), ("TENDERS", "& FRIES"), ("BURGERS", "SMASHED"), ("PO-BOYS", "SHRIMP · FISH"), ("CAJUN", "PASTA")]
    for k in range(5):
        x0 = k * PW
        # fire glow at the bottom
        for y in range(H // 2, H):
            t = (y - H / 2) / (H / 2)
            col = (int(14 + 150 * t ** 2), int(12 + 40 * t ** 2.5), 10)
            d.line([(x0, y), (x0 + PW, y)], fill=col)
        for _ in range(60):
            fx = x0 + R.randint(0, PW); fy = H - R.randint(0, 70)
            d.line([(fx, fy), (fx + R.randint(-6, 6), fy - R.randint(8, 30))], fill=(230, 110, 30), width=2)
        # the food picture
        cx, cy = x0 + 110, 115
        if k == 0:
            for j in range(6):
                a = j * 1.1
                ex, ey = cx + math.cos(a) * 35, cy + math.sin(a) * 25
                d.ellipse([ex - 26, ey - 15, ex + 26, ey + 15], fill=(200, 70, 30), outline=(120, 30, 10))
        elif k == 1:
            for j in range(4):
                d.rounded_rectangle([cx - 60 + j * 10, cy - 40 + j * 18, cx + 50 + j * 10, cy - 18 + j * 18], 10, fill=(206, 140, 60), outline=(150, 90, 30))
        elif k == 2:
            d.ellipse([cx - 60, cy - 55, cx + 60, cy - 5], fill=(214, 150, 60))
            d.rectangle([cx - 62, cy - 15, cx + 62, cy + 5], fill=(80, 150, 50))
            d.rectangle([cx - 60, cy + 2, cx + 60, cy + 22], fill=(90, 50, 30))
            d.rectangle([cx - 64, cy + 18, cx + 64, cy + 26], fill=(240, 190, 40))
            d.ellipse([cx - 58, cy + 22, cx + 58, cy + 52], fill=(206, 140, 60))
        elif k == 3:
            d.rounded_rectangle([cx - 80, cy - 30, cx + 80, cy + 30], 28, fill=(222, 170, 90))
            for j in range(7):
                d.ellipse([cx - 66 + j * 19, cy - 22, cx - 44 + j * 19, cy - 2], fill=(230, 120, 60))
        else:
            d.ellipse([cx - 70, cy - 40, cx + 70, cy + 40], fill=(240, 236, 226))
            for j in range(30):
                px = cx + R.randint(-55, 55); py = cy + R.randint(-30, 30)
                d.arc([px - 14, py - 8, px + 14, py + 8], 0, 180, fill=(232, 190, 90), width=4)
            for j in range(8):
                px = cx + R.randint(-45, 45); py = cy + R.randint(-25, 25)
                d.ellipse([px - 6, py - 4, px + 6, py + 4], fill=(220, 100, 70))
        t1, t2 = titles[k]
        d.text((x0 + 210, 40), t1, font=font(BOLDI, 32), fill=(250, 250, 248))
        d.text((x0 + 212, 88), t2, font=font(BOLD, 22), fill=YEL)
        for j in range(3):
            d.line([(x0 + 212, 126 + j * 18), (x0 + 212 + R.randint(90, 150), 126 + j * 18)], fill=(220, 220, 214), width=6)
        d.rectangle([x0, 0, x0 + 4, H], fill=(60, 60, 64))
    save(grime(im, 2.0), "menu")


def wordmark(d, cx, cy, s, wings=True):
    """The brand's two-line wordmark (yellow bold italic) with a pair of feathered wings behind."""
    if wings:
        for side in (-1, 1):
            for j in range(7):
                ang = math.radians(10 + j * 11)
                x1 = cx + side * (s * 1.1 + j * s * 0.12)
                y1 = cy - s * 0.15 - j * s * 0.07
                x2 = x1 + side * s * 0.9 * math.cos(ang)
                y2 = y1 - s * 0.5 * math.sin(ang)
                d.line([(x1, y1), (x2, y2)], fill=(200, 150, 10), width=max(2, int(s * 0.09)))
    f1 = font(BOLDI, int(s * 0.62))
    for txt, dy in (("WICKED", -0.42), ("WINGZ", 0.18)):
        w = d.textlength(txt, font=f1)
        d.text((cx - w / 2 + 2, cy + dy * s + 2), txt, font=f1, fill=(90, 60, 0))
        d.text((cx - w / 2, cy + dy * s), txt, font=f1, fill=YEL)


def guard():
    """The four black sneeze-guard panels (f006, left to right as filmed): COMBO DEALS, the
    wordmark, GET WICKED!, the big wordmark. Fire glow along the bottom."""
    PW, H = 512, 220
    im = Image.new("RGB", (PW * 4, H), (20, 20, 22))
    d = ImageDraw.Draw(im)
    for k in range(4):
        x0 = k * PW
        for y in range(H * 2 // 3, H):
            t = (y - H * 2 / 3) / (H / 3)
            d.line([(x0, y), (x0 + PW, y)], fill=(int(20 + 110 * t ** 2), int(20 + 20 * t ** 2), 18))
        for _ in range(40):
            fx = x0 + R.randint(0, PW); fy = H - R.randint(0, 50)
            d.line([(fx, fy), (fx + R.randint(-5, 5), fy - R.randint(6, 24))], fill=(220, 90, 20), width=2)
        if k in (0, 2):
            txt = "COMBO DEALS" if k == 0 else "GET WICKED!"
            f = font(BOLDI, 54)
            w = d.textlength(txt, font=f)
            d.text((x0 + PW / 2 - w / 2, 70), txt, font=f, fill=(244, 244, 240))
        else:
            wordmark(d, x0 + PW / 2, 100, 80 if k == 1 else 105)
        d.rectangle([x0, 0, x0 + 5, H], fill=(140, 140, 144))
    save(im, "guard")


def aframe():
    """The red sidewalk A-frame's poster (f005): a printed menu on black, invented lines."""
    W, H = 300, 420
    im = Image.new("RGB", (W, H), (16, 16, 18))
    d = ImageDraw.Draw(im)
    d.rectangle([18, 18, W - 18, 300], fill=(236, 232, 222))
    wordmark(d, W / 2, 70, 42, wings=False)
    for j in range(10):
        y = 120 + j * 17
        d.line([(34, y), (34 + R.randint(60, 110), y)], fill=(40, 40, 40), width=5)
        d.line([(W / 2 + 10, y), (W / 2 + 10 + R.randint(50, 100), y)], fill=(40, 40, 40), width=5)
    d.rectangle([34, 108, 140, 116], fill=YEL)
    d.rectangle([W / 2 + 10, 108, W / 2 + 120, 116], fill=YEL)
    save(grime(im, 2.0), "aframe")


def wall():
    """Dining-room walls: white paint gone a little cream, scuffs low down (older than CFA's)."""
    N = 256
    im = Image.new("RGB", (N, N), (236, 234, 226))
    save(grime(im, 2.0, 10), "wall")


def tv():
    """The wall TV's picture: a blurred promo still, generic food on red (not a real ad)."""
    W, H = 320, 180
    im = Image.new("RGB", (W, H), (150, 30, 24))
    d = ImageDraw.Draw(im)
    for j in range(9):
        x = R.randint(40, 280); y = R.randint(50, 150)
        d.ellipse([x - 30, y - 18, x + 30, y + 18], fill=(210, 110, 40))
    d.rectangle([0, 0, W, 34], fill=(20, 20, 20))
    wordmark(d, 70, 18, 22, wings=False)
    save(im.filter(ImageFilter.GaussianBlur(2)), "tv")


def louver():
    """The eggcrate grille strip under the front soffit: a lit white grid (f006)."""
    W, H = 256, 64
    im = Image.new("RGB", (W, H), (60, 60, 60))
    d = ImageDraw.Draw(im)
    for x in range(0, W, 16):
        d.rectangle([x + 2, 2, x + 14, H - 3], fill=(236, 236, 230))
    save(im, "louver")


if __name__ == "__main__":
    counter_tile(); floor_tile(); menu(); guard(); aframe(); wall(); tv(); louver()
    print("wrote", sorted(os.listdir(OUT)))
