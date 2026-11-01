"""Textures for the Cinnamonster counter (2026, store s57: KarmelKorn's corner stall), written to
tex/cm/*.png. Read from Steven's photos IMG_4464-4468 (Oct 23 2026, shot upside down: rotate 180).
design/storefronts/cinnamonster-2026.md.

  python3 tools/stores/cinnamonster/paint.py   (from the project folder)

Posters and menu lines are painted here (generic rolls and cups, invented lines). The co-branded
coffee sign on the back wall is painted as a plain red oval reading COFFEE (third-party logo left
out, IP rule).
"""
import math, os, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "..", "tex", "cm")
os.makedirs(OUT, exist_ok=True)
BOLD = "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf"
SERIFB = "/usr/share/fonts/truetype/freefont/FreeSerifBold.ttf"
SERIFI = "/usr/share/fonts/truetype/freefont/FreeSerifItalic.ttf"
R = random.Random(57)
RN = np.random.default_rng(57)
BURG = (122, 30, 42)
CREAM = (240, 232, 214)


def save(im, name):
    im.convert("RGB").save(os.path.join(OUT, name + ".png"), optimize=True)


def noise(im, amt=2.5):
    a = np.asarray(im.convert("RGB")).astype(np.float32)
    a += RN.normal(0, amt, a.shape)
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


def checker():
    """Burgundy/cream 4" (10 cm) glazed checker, two courses: one texture = 0.4 m x 0.2 m."""
    PX = 64
    im = Image.new("RGB", (4 * PX, 2 * PX), (170, 160, 150))
    d = ImageDraw.Draw(im)
    for r in range(2):
        for c in range(4):
            col = BURG if (r + c) % 2 == 0 else CREAM
            v = R.randint(-6, 6)
            d.rectangle([c * PX + 1, r * PX + 1, c * PX + PX - 2, r * PX + PX - 2], fill=tuple(max(0, min(255, k + v)) for k in col))
            d.line([(c * PX + 3, r * PX + 3), (c * PX + PX - 6, r * PX + 3)], fill=tuple(min(255, k + 25) for k in col), width=2)
    save(noise(im), "checker")


def white_tile():
    """The wainscot under the wall's checker band: white 4" tile. One texture = 0.4 m square."""
    PX = 64
    im = Image.new("RGB", (4 * PX, 4 * PX), (190, 186, 178))
    d = ImageDraw.Draw(im)
    for r in range(4):
        for c in range(4):
            v = 238 + R.randint(-4, 3)
            d.rectangle([c * PX + 1, r * PX + 1, c * PX + PX - 2, r * PX + PX - 2], fill=(v, v - 2, v - 8))
    save(noise(im), "white_tile")


def mahogany():
    """The counter's mahogany laminate: red-brown with a soft vertical grain and a dark panel seam
    at the texture's edge (panels 1.2 m wide). One texture = 1.2 m x 0.8 m."""
    W, H = 512, 340
    a = np.zeros((H, W, 3), np.float32)
    base = np.array([92, 38, 34], np.float32)
    xs = np.arange(W)
    grain = (np.sin(xs * 0.11) * 0.5 + np.sin(xs * 0.031 + 1.0) * 0.8 + RN.normal(0, 0.4, W)) * 5
    a[:] = base
    a += grain[None, :, None] * np.array([1.0, 0.5, 0.4])
    a += RN.normal(0, 2.0, a.shape)
    a[:, :4] = (40, 18, 16)
    # the polished sheen band
    for y in range(H):
        a[y] += 14 * math.exp(-((y - H * 0.35) / (H * 0.18)) ** 2)
    save(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)), "mahogany")


def gold():
    """The fascia's gold/tan paint, a little uneven."""
    im = Image.new("RGB", (256, 256), (214, 185, 138))
    save(noise(im, 3.0).filter(ImageFilter.GaussianBlur(1)), "gold")


def roll(d, cx, cy, r):
    d.ellipse([cx - r, cy - r * 0.8, cx + r, cy + r * 0.8], fill=(196, 128, 62), outline=(120, 70, 30), width=3)
    for k in range(5, 0, -1):
        rr = r * k / 5.5
        d.arc([cx - rr, cy - rr * 0.8, cx + rr, cy + rr * 0.8], 20 * k, 20 * k + 300, fill=(110, 56, 24), width=4)
    for k in range(9):
        x = cx + R.uniform(-r * 0.8, r * 0.8)
        d.line([(x, cy - r * 0.6), (x + R.uniform(-20, 20), cy + r * 0.4)], fill=(250, 246, 236), width=5)


def posters():
    """Three wall posters side by side (0..1/3: the coffee oval on a dark plank backer; 1/3..2/3:
    rolls 'from the oven'; 2/3..1: a big roll, 'Rich & Gooey')."""
    W, H = 1200, 400
    im = Image.new("RGB", (W, H), (60, 40, 30))
    d = ImageDraw.Draw(im)
    # 1: dark planks and the red oval
    for k in range(8):
        v = 50 + R.randint(-8, 8)
        d.rectangle([0, k * 50, 399, k * 50 + 48], fill=(v + 10, v, v - 8))
    d.ellipse([30, 70, 370, 330], fill=(176, 30, 34), outline=(240, 232, 214), width=8)
    f = ImageFont.truetype(SERIFB, 74)
    w = d.textlength("COFFEE", font=f)
    d.text((200 - w / 2, 160), "COFFEE", font=f, fill=(244, 238, 226))
    # 2: rolls on a tray
    d.rectangle([400, 0, 799, H], fill=(40, 30, 26))
    d.rectangle([430, 60, 770, 300], fill=(150, 110, 70))
    for k in range(6):
        roll(d, 480 + (k % 3) * 110, 130 + (k // 3) * 110, 48)
    d.text((620, 330), "From the Oven", font=ImageFont.truetype(SERIFI, 34), fill=(240, 232, 214))
    # 3: one big roll
    d.rectangle([800, 0, 1199, H], fill=(84, 40, 30))
    roll(d, 1000, 170, 150)
    d.text((830, 320), "Rich & Gooey", font=ImageFont.truetype(SERIFI, 44), fill=(244, 238, 226))
    for x in (399, 400, 799, 800):
        d.line([(x, 0), (x, H)], fill=(20, 16, 14), width=3)
    save(noise(im, 2.0), "posters")


def menu():
    """Two hanging menu boards, dark with a burgundy header (Bakery | Smoothies), invented lines and
    small product pictures."""
    W, H = 400, 520
    im = Image.new("RGB", (W, H), (24, 20, 18))
    d = ImageDraw.Draw(im)
    for k, title in enumerate(["Bakery", "Smoothies"]):
        x0 = k * 200
        d.rectangle([x0 + 4, 4, x0 + 196, 60], fill=(120, 28, 38))
        f = ImageFont.truetype(BOLD, 28)
        w = d.textlength(title, font=f)
        d.text((x0 + 100 - w / 2, 16), title, font=f, fill=(244, 238, 226))
        for j in range(5):
            y = 80 + j * 86
            if k == 0:
                roll(d, x0 + 46, y + 34, 28)
            else:
                d.polygon([(x0 + 26, y + 6), (x0 + 66, y + 6), (x0 + 60, y + 70), (x0 + 32, y + 70)], fill=R.choice([(220, 110, 140), (240, 200, 80), (160, 90, 60)]))
            for q in range(3):
                d.line([(x0 + 90, y + 14 + q * 18), (x0 + 90 + R.randint(50, 95), y + 14 + q * 18)], fill=(230, 226, 214), width=6)
        d.rectangle([x0, 0, x0 + 3, H], fill=(10, 8, 8))
    save(noise(im, 1.5), "menu")


if __name__ == "__main__":
    checker(); white_tile(); mahogany(); gold(); posters(); menu()
    print("wrote", sorted(os.listdir(OUT)))
