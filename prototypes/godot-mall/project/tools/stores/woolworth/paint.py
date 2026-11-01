"""Textures for Woolworth (tools/stores/woolworth/store.gd), written to tex/wl/*.png, plus
four extra stock sheets for the media kit's stock rows, written to tex/md/stock_*.png.

Front: the Southland facade record (red panel fascia, a white light-box with red slab-serif
letters shadowed in gold). Inside: the 1991 Signal Hill Mall (Statesville, NC) video Steven
chose as "the exact Woolworth layout" (design/storefronts/woolworth.md): glossy off-white
vinyl with a red stripe along the main aisles, a red band of department names high on the
walls, white gondolas, numbered checkout lanes, and the coffee-shop restaurant with orange
vinyl booths, framed food photos, a backlit menu board and lattice wallpaper panels.

All packaging, food photos and menu lines are invented; the only real name is the store's.
  python3 tools/stores/woolworth/paint.py   (from the project folder)
"""
import math, os, random, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "kay_bee"))
sys.path.insert(0, os.path.join(HERE, "..", "media"))
import paint_store as kb   # noqa: E402
import paint as md         # noqa: E402

OUT = os.path.join(HERE, "..", "..", "..", "tex", "wl")
MD_OUT = os.path.join(HERE, "..", "..", "..", "tex", "md")
os.makedirs(OUT, exist_ok=True)
SLAB = os.path.join(HERE, "RobotoSlab-ExtraBold.ttf")
BOLD = kb.BOLD
SS = 2
RED = (196, 22, 32)


def save(im, name, colors=0, out=OUT):
    im = im.convert("RGB")
    if colors:
        im = im.quantize(colors, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    im.save(os.path.join(out, name + ".png"), optimize=True)


# ------------------------------------------------------------------ front
def lightbox():
    """The sign: a white light-box face, 'Woolworth' in red slab-serif letters with a gold
    drop shadow (facade record). 2048 x 384 px = 8 m x 1.5 m."""
    W, H = 2048 * SS // 2, 384 * SS // 2
    W *= 2; H *= 2
    im = Image.new("RGB", (W, H), (250, 250, 246))
    d = ImageDraw.Draw(im)
    size = int(H * 0.78)
    f = ImageFont.truetype(SLAB, size)
    l, t, r, b = d.textbbox((0, 0), "Woolworth", font=f)
    while r - l > W * 0.9:
        size -= 4
        f = ImageFont.truetype(SLAB, size)
        l, t, r, b = d.textbbox((0, 0), "Woolworth", font=f)
    x = (W - (r - l)) / 2 - l
    y = (H - (b - t)) / 2 - t
    sh = max(4, int(size * 0.045))
    d.text((x + sh, y + sh), "Woolworth", font=f, fill=(214, 168, 50))
    d.text((x, y), "Woolworth", font=f, fill=RED)
    d.rectangle([0, 0, W - 1, H - 1], outline=(200, 200, 196), width=8)
    im = im.resize((2048, 384), Image.LANCZOS)
    save(kb.grain(im, 1.0, 3), "lightbox", 48)


def red_panel():
    """The red fascia: enamelled red panels 1.2 m wide with dark joints, 512 x 128 = 2.4 x 0.6 m."""
    W, H = 512, 128
    a = np.zeros((H, W, 3), np.float32) + np.array(RED, np.float32)
    a += kb.noise(W, H, 3, 7, blur=2)[..., None]
    for x in (0, 255):
        a[:, x:x + 2] = [110, 10, 16]
    a[:2] = [230, 60, 66]
    save(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)), "red_panel", 32)


def floor():
    """Glossy off-white vinyl, 1.22 m square (four 2 ft tiles)."""
    N = 256
    a = np.zeros((N, N, 3), np.float32)
    r = np.random.default_rng(9)
    for j in range(2):
        for i in range(2):
            t = np.zeros((N // 2, N // 2, 3), np.float32) + 236 + r.uniform(-4, 4)
            t += kb.noise(N // 2, N // 2, 4, 10 + i + 2 * j, blur=1.5)[..., None]
            a[j * N // 2:(j + 1) * N // 2, i * N // 2:(i + 1) * N // 2] = t
    a[:, :1] -= 26; a[:1, :] -= 26; a[:, N // 2 - 1:N // 2] -= 26; a[N // 2 - 1:N // 2, :] -= 26
    save(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)), "floor", 48)


DEPTS = ["TOYS", "HOUSEWARES", "DOMESTICS", "APPAREL", "HEALTH & BEAUTY", "GREETING CARDS",
         "PARTY GOODS", "SCHOOL SUPPLIES", "LAMPS & DECOR", "CANDY", "HARDWARE", "CRAFTS"]


def dept_band():
    """The red band high on the perimeter walls with white department names (video 3:10,
    5:28): 12 rows of 2048 x 256 px, each a 6 m x 0.75 m stretch. Nov 1, 2026 (workstream D):
    twice the resolution, bigger, heavier letters (caps about 0.36 m) and a white pinstripe
    under the top and over the bottom edge, so the names read from the front of the store."""
    W, H, R = 2048, 3072, 256
    im = Image.new("RGB", (W * SS, H * SS), RED)
    d = ImageDraw.Draw(im)
    for k, word in enumerate(DEPTS):
        y0 = k * R * SS
        d.rectangle([0, y0, W * SS, y0 + 16 * SS], fill=(150, 14, 22))
        d.rectangle([0, y0 + (R - 16) * SS, W * SS, y0 + R * SS], fill=(150, 14, 22))
        d.rectangle([0, y0 + 26 * SS, W * SS, y0 + 31 * SS], fill=(255, 255, 255))
        d.rectangle([0, y0 + (R - 31) * SS, W * SS, y0 + (R - 26) * SS], fill=(255, 255, 255))
        f = ImageFont.truetype(BOLD, 150 * SS)
        l, t, r, b = d.textbbox((0, 0), word, font=f)
        sx = 1.0
        if r - l > (W - 160) * SS:
            sx = (W - 160) * SS / (r - l)
            f = ImageFont.truetype(BOLD, int(150 * SS * sx))
            l, t, r, b = d.textbbox((0, 0), word, font=f)
        d.text(((W * SS - (r - l)) / 2 - l, y0 + (R * SS - (b - t)) / 2 - t), word, font=f, fill=(255, 255, 255),
               stroke_width=2 * SS, stroke_fill=(255, 255, 255))
    im = im.resize((W, H), Image.LANCZOS)
    save(kb.grain(im, 1.2, 4), "dept_band", 32)


def signs():
    """512 x 512, 2 x 2: CUSTOMER SERVICE (red letters on white), a lane number card blank
    corner (unused), 'Restaurant' (red slab letters on white wall), the mall-door's
    'Restaurant' plate (white on red)."""
    N = 512 * SS
    h = N // 2
    im = Image.new("RGB", (N, N), (250, 250, 246))
    d = ImageDraw.Draw(im)
    kb.fit_text(d, "CUSTOMER", (20 * SS, 20 * SS, h - 20 * SS, h * 0.48), BOLD, RED)
    kb.fit_text(d, "SERVICE", (20 * SS, h * 0.52, h - 20 * SS, h - 20 * SS), BOLD, RED)
    d.rectangle([h, 0, N, h], fill=(250, 250, 246))
    d.rectangle([0, h, h, N], fill=(244, 238, 222))
    kb.fit_text(d, "Restaurant", (14 * SS, h + 60 * SS, h - 14 * SS, N - 60 * SS), SLAB, RED)
    d.rectangle([h, h, N, N], fill=RED)
    kb.fit_text(d, "Restaurant", (h + 14 * SS, h + 60 * SS, N - 14 * SS, N - 60 * SS), SLAB, (255, 255, 255))
    im = im.resize((512, 512), Image.LANCZOS)
    save(kb.grain(im, 1.2, 5), "signs", 64)


def lane_numbers():
    """Checkout lane-light faces: white squares with black numbers 1-8, 512 x 64."""
    W, H = 512 * SS, 64 * SS
    im = Image.new("RGB", (W, H), (250, 250, 246))
    d = ImageDraw.Draw(im)
    for k in range(8):
        x0 = k * 64 * SS
        d.rectangle([x0 + 2 * SS, 2 * SS, x0 + 62 * SS, 62 * SS], outline=(60, 60, 60), width=2 * SS)
        kb.fit_text(d, str(k + 1), (x0 + 10 * SS, 8 * SS, x0 + 54 * SS, 56 * SS), BOLD, (20, 20, 20))
    im = im.resize((512, 64), Image.LANCZOS)
    save(im, "lanes", 16)


def counter():
    """A checkout counter's side, 2.4 m x 0.9 m: grey laminate, a red kick stripe."""
    W, H = 1024, 384
    a = np.zeros((H, W, 3), np.float32) + np.array([200, 200, 198], np.float32)
    a += kb.noise(W, H, 2, 21)[..., None]
    a[H - 70:H - 40] = RED
    a[H - 40:] = [40, 40, 42]
    a[:10] = [170, 170, 168]
    save(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)), "counter", 32)


# ------------------------------------------------------------------ the restaurant
def food(d, x0, y0, w, h, rng, kind=None):
    """An invented food photo: a plate on a table, a burger, fries, a sandwich or a pie."""
    d.rectangle([x0, y0, x0 + w, y0 + h], fill=rng.choice([(120, 70, 40), (60, 40, 30), (150, 110, 70)]))
    cx, cy = x0 + w / 2, y0 + h * 0.58
    d.ellipse([cx - w * 0.42, cy - h * 0.3, cx + w * 0.42, cy + h * 0.3], fill=(246, 244, 236))
    kind = kind or rng.choice(["burger", "fries", "sandwich", "pie", "shrimp", "salad"])
    if kind == "burger":
        d.ellipse([cx - w * 0.22, cy - h * 0.22, cx + w * 0.22, cy + h * 0.02], fill=(206, 140, 60))
        d.rectangle([cx - w * 0.23, cy - h * 0.02, cx + w * 0.23, cy + h * 0.04], fill=(90, 160, 60))
        d.rectangle([cx - w * 0.22, cy + h * 0.04, cx + w * 0.22, cy + h * 0.1], fill=(110, 60, 30))
        d.ellipse([cx - w * 0.22, cy + h * 0.06, cx + w * 0.22, cy + h * 0.16], fill=(200, 136, 60))
    elif kind == "fries":
        for k in range(14):
            x = cx - w * 0.25 + k * w * 0.035
            d.line([x, cy + h * 0.1, x + rng.uniform(-6, 6), cy - h * 0.2], fill=(236, 190, 70), width=max(3, int(w * 0.03)))
    elif kind == "sandwich":
        d.polygon([(cx - w * 0.3, cy + h * 0.1), (cx + w * 0.3, cy + h * 0.1), (cx, cy - h * 0.2)], fill=(226, 196, 140))
        d.line([cx - w * 0.28, cy + h * 0.06, cx + w * 0.28, cy + h * 0.06], fill=(90, 160, 60), width=max(3, int(h * 0.04)))
    elif kind == "pie":
        d.pieslice([cx - w * 0.3, cy - h * 0.22, cx + w * 0.3, cy + h * 0.22], 200, 340, fill=(200, 140, 70))
        d.pieslice([cx - w * 0.28, cy - h * 0.2, cx + w * 0.28, cy + h * 0.2], 205, 335, fill=(150, 30, 50))
    elif kind == "shrimp":
        for k in range(5):
            a = k * 0.5
            d.arc([cx - w * 0.2 + k * w * 0.06, cy - h * 0.12, cx - w * 0.05 + k * w * 0.06, cy + h * 0.06], 0, 300, fill=(236, 130, 70), width=max(3, int(w * 0.04)))
    else:
        for k in range(10):
            r = w * 0.06
            px, py = cx + rng.uniform(-w * 0.25, w * 0.25), cy + rng.uniform(-h * 0.15, h * 0.15)
            d.ellipse([px - r, py - r, px + r, py + r], fill=rng.choice([(90, 170, 60), (60, 140, 50), (220, 60, 50), (240, 200, 60)]))
    kb.scribble(d, x0 + w * 0.1, y0 + h * 0.06, w * 0.6, h * 0.1, (250, 240, 200), rng)


def food_photos():
    """Framed food photos for the walls (video 5:46-5:52): 1024 x 256, four 0.5 m frames."""
    W, H = 1024 * SS, 256 * SS
    im = Image.new("RGB", (W, H), (190, 160, 70))
    d = ImageDraw.Draw(im)
    rng = random.Random(30)
    for k in range(4):
        x0 = k * 256 * SS
        d.rectangle([x0, 0, x0 + 256 * SS - 1, H - 1], fill=(200, 168, 80))
        food(d, x0 + 14 * SS, 14 * SS, 228 * SS, 228 * SS, rng, ["burger", "shrimp", "sandwich", "pie"][k])
    im = im.resize((1024, 256), Image.LANCZOS)
    save(kb.grain(im, 2, 31), "food_photos", 96)


def menu_board():
    """The backlit menu board (video 5:43, 6:01): black panels with photos and yellow lines.
    1024 x 256 = 3.2 m x 0.8 m."""
    W, H = 1024 * SS, 256 * SS
    im = Image.new("RGB", (W, H), (14, 14, 16))
    d = ImageDraw.Draw(im)
    rng = random.Random(32)
    f = ImageFont.truetype(BOLD, 15 * SS)
    for k in range(5):
        x0 = k * 204 * SS + 6 * SS
        d.rectangle([x0, 6 * SS, x0 + 192 * SS, 96 * SS], fill=(40, 40, 44))
        food(d, x0 + 4 * SS, 10 * SS, 184 * SS, 82 * SS, rng)
        for j in range(6):
            y = 108 * SS + j * 23 * SS
            kb.scribble(d, x0 + 6 * SS, y + 4 * SS, rng.uniform(90, 130) * SS, 12 * SS, (250, 220, 60), rng)
            d.text((x0 + 150 * SS, y), "%d.%02d" % (rng.randint(1, 4), rng.choice([19, 29, 49, 59, 79, 99])), font=f, fill=(250, 220, 60))
        d.line([x0 + 198 * SS, 0, x0 + 198 * SS, H], fill=(70, 70, 74), width=3 * SS)
    im = im.resize((1024, 256), Image.LANCZOS)
    save(kb.grain(im, 1.5, 33), "menu", 96)


def lattice():
    """Lattice / plaid wallpaper panel inside a wood frame (video 6:10-6:19): 256 x 512 =
    0.6 m x 1.2 m."""
    W, H = 256, 512
    im = Image.new("RGB", (W, H), (210, 190, 140))
    d = ImageDraw.Draw(im)
    for k in range(0, W, 24):
        d.line([k, 0, k, H], fill=(150, 112, 70), width=3)
        d.line([k + 8, 0, k + 8, H], fill=(186, 160, 110), width=1)
    for k in range(0, H, 24):
        d.line([0, k, W, k], fill=(150, 112, 70), width=3)
        d.line([0, k + 8, W, k + 8], fill=(186, 160, 110), width=1)
    d.rectangle([0, 0, W - 1, H - 1], outline=(120, 80, 44), width=14)
    d.rectangle([14, 14, W - 15, H - 15], outline=(170, 130, 80), width=3)
    save(kb.grain(im, 2, 34), "lattice", 32)


def slats():
    """Vertical wood-slat wainscot (video 6:19), 0.6 m square."""
    N = 256
    a = np.zeros((N, N, 3), np.float32) + np.array([150, 104, 60], np.float32)
    a += kb.noise(N, N, 6, 35, blur=1)[..., None] * np.array([1, 0.8, 0.6])
    for k in range(0, N, 16):
        a[:, k:k + 2] = [90, 60, 34]
    save(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)), "slats", 32)


def booth_vinyl():
    """Orange-red vinyl with button tufting rows, 0.5 m square."""
    N = 128
    a = np.zeros((N, N, 3), np.float32) + np.array([132, 42, 34], np.float32)
    a += kb.noise(N, N, 4, 36, blur=2)[..., None]
    for k in range(0, N, 32):
        a[k:k + 2, :] *= 0.75
    save(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)), "vinyl_booth", 32)


def counter_front():
    """The restaurant counter's front with food-photo panels (video 5:43): 1024 x 256 =
    4 m x 1 m."""
    W, H = 1024 * SS, 256 * SS
    im = Image.new("RGB", (W, H), (180, 140, 90))
    d = ImageDraw.Draw(im)
    rng = random.Random(37)
    for k in range(6):
        x0 = k * 170 * SS + 8 * SS
        d.rectangle([x0, 30 * SS, x0 + 154 * SS, 190 * SS], fill=(250, 250, 246))
        food(d, x0 + 6 * SS, 36 * SS, 142 * SS, 148 * SS, rng)
    d.rectangle([0, 214 * SS, W, H], fill=(60, 40, 26))
    im = im.resize((1024, 256), Image.LANCZOS)
    save(kb.grain(im, 2, 38), "rest_counter", 96)


# ------------------------------------------------------------------ stock (media-kit sheets)
def wl_item(d, kind, x0, y0, w, h, rng):
    if kind == "box":
        # small appliances, boxed fans, cookware: a printed carton
        base = rng.choice([(250, 250, 246), (230, 230, 226), (40, 90, 170), (200, 40, 40), (240, 200, 60)])
        d.rectangle([x0, y0, x0 + w, y0 + h], fill=base)
        d.rectangle([x0 + w * 0.08, y0 + h * 0.3, x0 + w * 0.92, y0 + h * 0.86], fill=tuple(min(255, int(c * 0.6 + 90)) for c in base))
        shape = rng.choice(["fan", "pot", "toaster"])
        cx, cy = x0 + w / 2, y0 + h * 0.58
        s = min(w, h) * 0.24
        if shape == "fan":
            d.ellipse([cx - s, cy - s, cx + s, cy + s], outline=(60, 60, 64), width=max(2, int(s * 0.12)))
            for a in range(3):
                ang = a * 2.1
                d.ellipse([cx + math.cos(ang) * s * 0.5 - s * 0.3, cy + math.sin(ang) * s * 0.5 - s * 0.3, cx + math.cos(ang) * s * 0.5 + s * 0.3, cy + math.sin(ang) * s * 0.5 + s * 0.3], fill=(90, 140, 200))
        elif shape == "pot":
            d.rectangle([cx - s, cy - s * 0.4, cx + s, cy + s * 0.7], fill=(150, 150, 156))
            d.rectangle([cx + s, cy - s * 0.2, cx + s * 1.6, cy], fill=(30, 30, 30))
        else:
            d.rounded_rectangle([cx - s, cy - s * 0.6, cx + s, cy + s * 0.7], radius=s * 0.3, fill=(200, 200, 206))
            d.rectangle([cx - s * 0.6, cy - s * 0.6, cx - s * 0.2, cy - s * 0.4], fill=(30, 30, 30)); d.rectangle([cx + s * 0.2, cy - s * 0.6, cx + s * 0.6, cy - s * 0.4], fill=(30, 30, 30))
        kb.scribble(d, x0 + w * 0.08, y0 + h * 0.06, w * 0.8, h * 0.16, (30, 30, 34) if sum(base) > 500 else (250, 250, 250), rng)
    elif kind == "hba":
        # health and beauty: bottles and tubes standing in a row
        x = x0
        while x < x0 + w - 4:
            bw = rng.uniform(0.15, 0.35) * w
            bh = rng.uniform(0.5, 1.0) * h
            col = rng.choice([(250, 250, 246), (60, 140, 220), (240, 200, 60), (220, 90, 140), (90, 180, 90), (230, 120, 40)])
            d.rounded_rectangle([x, y0 + h - bh, x + bw - 2, y0 + h], radius=bw * 0.2, fill=col)
            d.rectangle([x + bw * 0.25, y0 + h - bh - h * 0.06, x + bw * 0.7, y0 + h - bh], fill=(240, 240, 240))
            d.rectangle([x + 2, y0 + h - bh * 0.6, x + bw - 4, y0 + h - bh * 0.35], fill=(250, 250, 250) if sum(col) < 600 else (200, 40, 40))
            x += bw
    elif kind == "linen":
        # folded towels and packaged sheets
        base = rng.choice([(236, 220, 200), (180, 200, 230), (240, 190, 200), (250, 250, 246), (190, 220, 190)])
        n = rng.randint(2, 4)
        for k in range(n):
            ya, yb = y0 + h * k / n, y0 + h * (k + 1) / n
            c = tuple(int(v * (0.92 if k % 2 else 1.0)) for v in base)
            d.rounded_rectangle([x0, ya, x0 + w, yb - 2], radius=(yb - ya) * 0.3, fill=c)
            d.line([x0 + 4, yb - 6, x0 + w - 4, yb - 6], fill=tuple(int(v * 0.8) for v in c), width=2)
    elif kind == "candy":
        base = rng.choice([(200, 30, 40), (240, 200, 40), (60, 120, 200), (120, 60, 30), (240, 120, 30)])
        d.rectangle([x0, y0, x0 + w, y0 + h], fill=base)
        kb.scribble(d, x0 + w * 0.1, y0 + h * 0.2, w * 0.8, h * 0.3, (250, 250, 250), rng)
        d.ellipse([x0 + w * 0.3, y0 + h * 0.55, x0 + w * 0.7, y0 + h * 0.9], fill=(250, 240, 200))
    elif kind == "cards":
        # greeting cards in pocket rows: tops of cards
        x = x0
        while x < x0 + w - 4:
            cw = rng.uniform(0.11, 0.14) * md.PXM * SS
            col = rng.choice([(250, 250, 246), (240, 220, 230), (220, 230, 250), (250, 240, 200), (230, 250, 230)])
            d.rectangle([x, y0, x + cw - 3, y0 + h], fill=col)
            kb.motif(d, rng.choice(["dots", "bear", "ball", "plane"]), x + 4, y0 + h * 0.25, cw - 10, h * 0.6, rng, md.PAL)
            kb.scribble(d, x + 4, y0 + h * 0.05, cw - 12, h * 0.14, rng.choice([(200, 30, 40), (40, 90, 170), (120, 60, 140)]), rng)
            x += cw
        d.rectangle([x0, y0 + h * 0.7, x0 + w, y0 + h], fill=(220, 220, 216))
    elif kind == "party":
        base = rng.choice([(240, 60, 140), (60, 160, 220), (250, 220, 60), (120, 200, 90), (240, 120, 40)])
        d.rectangle([x0, y0, x0 + w, y0 + h], fill=(240, 240, 236))
        d.rectangle([x0, y0, x0 + w, y0 + h * 0.3], fill=base)
        for _ in range(6):
            r = w * 0.08
            px, py = rng.uniform(x0 + r, x0 + w - r), rng.uniform(y0 + h * 0.35, y0 + h - r)
            d.ellipse([px - r, py - r, px + r, py + r], fill=rng.choice(md.PAL))
        kb.scribble(d, x0 + w * 0.1, y0 + h * 0.06, w * 0.8, h * 0.16, (250, 250, 250), rng)


WL_SIZES = {"box": ((0.25, 0.45), (0.22, 0.30)), "hba": ((0.20, 0.30), (0.12, 0.20)), "linen": ((0.30, 0.42), (0.18, 0.29)),
            "candy": ((0.10, 0.16), (0.14, 0.20)), "cards": ((0.40, 0.60), (0.16, 0.18)), "party": ((0.15, 0.22), (0.22, 0.28))}


def wl_stock(sheet, kind, seed):
    rows, rh_m = md.ROWS.get(sheet, (8, 0.305))
    W, H = 512 * SS, 1024 * SS
    rh = H // rows
    rng = random.Random(seed)
    im = Image.new("RGB", (W, H), md.GAP)
    d = ImageDraw.Draw(im)
    for r in range(rows):
        ytop = r * rh
        x = 2 * SS
        while x < W - 30 * SS:
            wr, hr = WL_SIZES[kind]
            w = int(rng.uniform(*wr) * md.PXM * SS)
            h = int(min(rng.uniform(*hr) * md.PXM * SS, rh - 4 * SS))
            s = rng.randint(0, 10 ** 9)
            if x + w > W - 2 * SS:
                w = W - 2 * SS - x   # the last facing squeezed in, as on a full shelf
                if w < 40 * SS:
                    break
            for _ in range(rng.choice([1, 2, 2, 3])):
                if x + w > W - 2 * SS:
                    break
                wl_item(d, kind, x, ytop + rh - h - 2 * SS, w, h, random.Random(s))
                x += w + 3 * SS
    im = im.resize((512, 1024), Image.LANCZOS)
    a = np.asarray(im).astype(np.float32)
    rhp = 1024 // rows
    for r in range(rows):
        y0 = r * rhp
        n = max(6, rhp // 5)
        a[y0:y0 + n] *= np.linspace(0.6, 1.0, n)[:, None, None]
    a += kb.noise(512, 1024, 2.5, seed)[..., None]
    save(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)), "stock_" + sheet, 192, out=MD_OUT)


def garments():
    """Clothes on a round rack seen from outside: hanging shirts and jackets, shoulders on top.
    1024 x 256 = 4 m round x 1 m drop, tiles sideways."""
    W, H = 1024 * SS, 256 * SS
    rng = random.Random(40)
    im = Image.new("RGB", (W, H), (40, 40, 44))
    d = ImageDraw.Draw(im)
    x = 0
    pal = [(60, 160, 170), (200, 40, 70), (40, 60, 120), (240, 240, 236), (230, 190, 60), (120, 80, 140), (60, 130, 80), (210, 120, 150), (90, 90, 96)]
    while x < W:
        w = rng.randint(14, 26) * SS
        col = rng.choice(pal)
        run = rng.randint(3, 8)
        for _ in range(run):
            if x >= W:
                break
            c = tuple(max(0, min(255, int(v + rng.uniform(-12, 12)))) for v in col)
            drop = rng.uniform(0.6, 1.0) * H
            d.rectangle([x, 10 * SS, x + w - 2, drop], fill=c)
            d.line([x, 10 * SS, x + w - 2, 10 * SS], fill=tuple(int(v * 0.7) for v in c), width=4 * SS)
            d.line([x + w - 3, 10 * SS, x + w - 3, drop], fill=tuple(int(v * 0.6) for v in c), width=SS)
            x += w
    im = im.resize((1024, 256), Image.LANCZOS)
    save(kb.grain(im, 2, 41), "garments", 128)


if __name__ == "__main__":
    lightbox(); red_panel(); floor(); dept_band(); signs(); lane_numbers(); counter()
    food_photos(); menu_board(); lattice(); slats(); booth_vinyl(); counter_front(); garments()
    for i, (s, k) in enumerate([("boxes", "box"), ("hba", "hba"), ("linens", "linen"), ("candy", "candy"), ("gcards", "cards"), ("party", "party")]):
        wl_stock(s, k, 500 + i)
    print("wrote tex/wl/*.png and tex/md/stock_{boxes,hba,linens,candy,gcards,party}.png")
