"""Textures for the 2026 "through the glass" fronts (tools/stores/fronts26/), written to tex/f26/.
Finishes read off Steven's Oct 23 2026 footage (design/storefronts/fronts-2026.md); merchandise is
painted as invented generic shapes (IP rule: no real products, logos or artwork).

  python3 tools/stores/fronts26/paint.py   (from the project folder)
"""
import math, os, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "..", "tex", "f26")
os.makedirs(OUT, exist_ok=True)
BOLD = "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf"
SANS = "/usr/share/fonts/truetype/freefont/FreeSans.ttf"
SERIFI = "/usr/share/fonts/truetype/freefont/FreeSerifItalic.ttf"
R = random.Random(2026)
RN = np.random.default_rng(2026)


def save(im, name):
    im.convert("RGB").save(os.path.join(OUT, name + ".png"), optimize=True)


def noise(im, amt=3.0):
    a = np.asarray(im.convert("RGB")).astype(np.float32)
    a += RN.normal(0, amt, a.shape)
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


def jit(c, k=10):
    return tuple(max(0, min(255, v + R.randint(-k, k))) for v in c)


def brick():
    """Spencer's faux red brick, running bond, 21.5 x 6.5 cm with 1 cm mortar. One tile = 0.9 x 0.6 m."""
    W, H = 512, 341
    px = W / 0.9
    im = Image.new("RGB", (W, H), (150, 140, 128))
    d = ImageDraw.Draw(im)
    bw, bh, m = 0.215 * px, 0.065 * px, 0.01 * px
    y = 0.0
    row = 0
    while y < H:
        x = -(bw + m) * 0.5 * (row % 2)
        while x < W:
            base = R.choice([(132, 52, 38), (146, 60, 42), (118, 46, 36), (156, 72, 52), (124, 58, 46), (104, 40, 32)])
            d.rectangle([x + m * 0.5, y + m * 0.5, x + bw, y + bh], fill=jit(base, 8))
            for _ in range(6):
                sx = x + R.random() * bw; sy = y + R.random() * bh
                d.point((sx, sy), fill=jit((90, 34, 26), 10))
            x += bw + m
        y += bh + m
        row += 1
    save(noise(im, 4).filter(ImageFilter.GaussianBlur(0.6)), "brick")


def concrete():
    im = Image.new("RGB", (256, 256), (150, 150, 146))
    save(noise(im, 7).filter(ImageFilter.GaussianBlur(1.2)), "concrete")


def planks():
    """Weathered wood boards running horizontally (Spencer's lintel). One tile = 1.2 x 0.6 m, 6 boards."""
    W, H = 512, 256
    im = Image.new("RGB", (W, H), (80, 54, 36))
    d = ImageDraw.Draw(im)
    for k in range(6):
        c = jit((110, 74, 48), 18)
        d.rectangle([0, k * 42 + 1, W, k * 42 + 40], fill=c)
        for _ in range(40):
            yy = k * 42 + R.randint(3, 38)
            x0 = R.randint(0, W)
            d.line([(x0, yy), (x0 + R.randint(30, 160), yy)], fill=jit((84, 56, 36), 10), width=1)
    save(noise(im, 3), "planks")


def gingham():
    """Bath & Body Works' blue/white gingham surround: 10 cm checks. One tile = 0.4 m."""
    N = 256
    a = np.zeros((N, N, 3), np.float32)
    s = N // 4
    for y in range(N):
        for x in range(N):
            v = ((y // s) % 2) + ((x // s) % 2)
            a[y, x] = [(250, 250, 248), (120, 150, 196), (30, 62, 132)][v]
    save(noise(Image.fromarray(a.astype(np.uint8)), 2), "gingham")


def beadboard():
    """Rainbow's white beadboard: vertical boards 10 cm with a bead groove. One tile = 0.4 m."""
    N = 256
    im = Image.new("RGB", (N, N), (244, 243, 238))
    d = ImageDraw.Draw(im)
    for k in range(4):
        x = k * 64
        d.line([(x, 0), (x, N)], fill=(196, 196, 190), width=3)
        d.line([(x + 4, 0), (x + 4, N)], fill=(255, 255, 252), width=2)
    save(noise(im, 1.5), "beadboard")


def wave():
    """GAC's white 3D wave wall panel: soft horizontal waves. One tile = 1.2 m."""
    N = 512
    y, x = np.mgrid[0:N, 0:N].astype(np.float32)
    ph = (y / N * 2 * math.pi * 10) + np.sin(x / N * 2 * math.pi * 2) * 2.2
    v = 236 + 14 * np.sin(ph)
    a = np.stack([v, v, v + 1], -1)
    save(noise(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)), 1.0), "wave")


def crumple():
    """Claire's silver crumpled-metal trim band."""
    N = 256
    a = RN.normal(0, 1, (N // 8, N // 8))
    im = Image.fromarray(((a - a.min()) / (a.max() - a.min()) * 255).astype(np.uint8)).resize((N, N), Image.BICUBIC)
    g = np.asarray(im).astype(np.float32)
    gx = np.abs(np.gradient(g)[0]) * 3
    v = 150 + 0.35 * (g - 128) + gx
    save(Image.fromarray(np.clip(np.stack([v, v, v + 6], -1), 0, 255).astype(np.uint8)), "crumple")


def travertine():
    N = 256
    im = Image.new("RGB", (N, N), (214, 200, 176))
    d = ImageDraw.Draw(im)
    for _ in range(120):
        y = R.randint(0, N); x = R.randint(0, N)
        d.line([(x, y), (x + R.randint(10, 60), y + R.randint(-2, 2))], fill=jit((190, 174, 148), 8), width=R.randint(1, 3))
    save(noise(im, 3).filter(ImageFilter.GaussianBlur(0.8)), "travertine")


def tees():
    """A wall of T-shirts faced out, 8 x 2 cells (Spencer's darks with bright prints; Aéropostale,
    Rainbow and Lids use rows of plain colours). Each cell 128 x 128: a shirt shape on transparent
    black. Rows: 0 dark printed tees, 1 bright tops."""
    W, H = 1024, 256
    im = Image.new("RGB", (W, H), (24, 24, 26))
    d = ImageDraw.Draw(im)
    for row in range(2):
        for k in range(8):
            x0, y0 = k * 128, row * 128
            if row == 0:
                body = R.choice([(20, 20, 22), (30, 30, 34), (60, 24, 30), (24, 34, 60), (90, 90, 96)])
            else:
                body = R.choice([(230, 60, 90), (60, 150, 220), (250, 200, 60), (240, 240, 236), (120, 200, 120), (180, 90, 200), (250, 130, 60)])
            d.polygon([(x0 + 30, y0 + 20), (x0 + 50, y0 + 12), (x0 + 78, y0 + 12), (x0 + 98, y0 + 20), (x0 + 118, y0 + 42), (x0 + 100, y0 + 52), (x0 + 94, y0 + 44),
                       (x0 + 94, y0 + 120), (x0 + 34, y0 + 120), (x0 + 34, y0 + 44), (x0 + 28, y0 + 52), (x0 + 10, y0 + 42)], fill=body)
            if row == 0:
                pc = R.choice([(240, 60, 60), (250, 220, 60), (80, 220, 240), (240, 240, 240), (200, 80, 240)])
                cx, cy = x0 + 64, y0 + 66
                kind = R.randint(0, 3)
                if kind == 0:
                    d.ellipse([cx - 22, cy - 22, cx + 22, cy + 22], outline=pc, width=5)
                elif kind == 1:
                    d.polygon([(cx, cy - 26), (cx + 24, cy + 18), (cx - 24, cy + 18)], fill=pc)
                elif kind == 2:
                    for j in range(4):
                        d.line([(cx - 22, cy - 16 + j * 10), (cx + 22, cy - 16 + j * 10)], fill=pc, width=4)
                else:
                    d.rectangle([cx - 20, cy - 20, cx + 20, cy + 20], fill=pc)
                    d.ellipse([cx - 10, cy - 10, cx + 10, cy + 10], fill=body)
            else:
                d.line([(x0 + 50, y0 + 14), (x0 + 64, y0 + 26), (x0 + 78, y0 + 14)], fill=tuple(int(v * 0.8) for v in body), width=3)
    # two sheets: both rows dark printed (Spencer's), both rows bright tops (the clothing stores)
    a = np.asarray(im)
    save(noise(Image.fromarray(np.concatenate([a[:128], a[:128][:, ::-1]], 0)), 2), "tees_dark")
    save(noise(Image.fromarray(np.concatenate([a[128:], a[128:][:, ::-1]], 0)), 2), "tees")


def caps():
    """Lids' cap wall: 8 x 4 caps seen from the front (crown, a flat brim under), invented colourways
    with plain shapes on the crowns (no team marks). One tile = 1.6 x 1.0 m."""
    W, H = 1024, 640
    im = Image.new("RGB", (W, H), (36, 40, 52))
    d = ImageDraw.Draw(im)
    for r in range(4):
        for c in range(8):
            x0, y0 = c * 128, r * 160
            col = R.choice([(20, 30, 70), (20, 20, 22), (160, 30, 40), (240, 240, 236), (40, 90, 50), (90, 90, 96), (230, 120, 30), (60, 120, 200)])
            d.chord([x0 + 16, y0 + 30, x0 + 112, y0 + 126], 180, 360, fill=col)
            d.rectangle([x0 + 16, y0 + 76, x0 + 112, y0 + 92], fill=col)
            d.polygon([(x0 + 10, y0 + 92), (x0 + 118, y0 + 92), (x0 + 108, y0 + 106), (x0 + 20, y0 + 106)], fill=tuple(int(v * 0.7) for v in col))
            mc = R.choice([(240, 240, 240), (250, 200, 40), (200, 30, 40), (20, 20, 22)])
            if mc == col:
                mc = (200, 200, 200)
            if R.random() < 0.5:
                d.ellipse([x0 + 50, y0 + 52, x0 + 78, y0 + 80], outline=mc, width=4)
            else:
                d.polygon([(x0 + 64, y0 + 48), (x0 + 78, y0 + 78), (x0 + 50, y0 + 78)], fill=mc)
            d.rectangle([x0 + 8, y0 + 110, x0 + 120, y0 + 114], fill=(200, 200, 204))
    save(noise(im, 2), "caps")


def bottles():
    """Bath & Body Works' shelves: rows of pump and spray bottles in pastels, a lit white shelf edge
    every 0.33 m. One tile = 1.2 x 1.0 m (3 shelves)."""
    W, H = 768, 640
    im = Image.new("RGB", (W, H), (246, 244, 240))
    d = ImageDraw.Draw(im)
    for s in range(3):
        yb = (s + 1) * 213 - 12
        d.rectangle([0, yb, W, yb + 12], fill=(255, 255, 255))
        d.rectangle([0, yb + 12, W, yb + 14], fill=(200, 200, 196))
        x = 6
        while x < W - 30:
            col = R.choice([(240, 160, 190), (170, 210, 240), (250, 220, 150), (200, 170, 230), (160, 220, 180), (250, 190, 150), (255, 255, 255), (120, 60, 120)])
            w = R.randint(26, 36); h = R.randint(90, 140)
            d.rounded_rectangle([x, yb - h, x + w, yb], 6, fill=col, outline=jit(col, 30))
            d.rectangle([x + w * 0.25, yb - h * 0.6, x + w * 0.75, yb - h * 0.3], fill=(255, 255, 255))
            d.rectangle([x + w * 0.35, yb - h - 18, x + w * 0.65, yb - h], fill=(250, 250, 250))
            x += w + 4
    save(noise(im, 2), "bottles")


def accessories():
    """Claire's wall: pegboard of carded accessories, hair clips, earrings, plush keychains; pinks,
    purples and silver. One tile = 1.2 x 1.2 m."""
    N = 768
    im = Image.new("RGB", (N, N), (238, 230, 238))
    d = ImageDraw.Draw(im)
    for r in range(8):
        for c in range(10):
            x0 = c * 76 + 8; y0 = r * 96 + 10
            d.line([(x0 + 30, y0), (x0 + 30, y0 + 10)], fill=(150, 150, 156), width=3)
            col = R.choice([(240, 120, 190), (180, 120, 230), (250, 250, 252), (120, 200, 230), (250, 200, 80), (60, 40, 60), (250, 160, 200)])
            d.rectangle([x0 + 8, y0 + 10, x0 + 52, y0 + 80], fill=(252, 252, 252), outline=(220, 210, 220))
            for j in range(R.randint(2, 4)):
                cx = x0 + 18 + (j % 2) * 22; cy = y0 + 28 + (j // 2) * 26
                d.ellipse([cx - 7, cy - 7, cx + 7, cy + 7], fill=col)
    save(noise(im, 2), "accessories")


def cookies():
    """Top-down cookie trays for the GAC case: 4 x 2 trays per texture, each a tray of round cookies
    (chocolate chip, sugar with sprinkles, double fudge, M-shaped... no: plain invented kinds),
    one texture = 4 trays across."""
    W, H = 1024, 256
    im = Image.new("RGB", (W, H), (200, 200, 204))
    d = ImageDraw.Draw(im)
    kinds = [((206, 150, 84), (70, 40, 20)), ((236, 214, 170), None), ((92, 54, 34), (230, 220, 200)), ((214, 168, 100), (200, 60, 60)),
             ((240, 210, 200), None), ((180, 120, 60), (240, 230, 120)), ((120, 74, 40), (60, 30, 18)), ((230, 196, 130), (90, 170, 70))]
    for t in range(8):
        x0 = (t % 4) * 256; y0 = (t // 4) * 128
        d.rectangle([x0 + 4, y0 + 4, x0 + 252, y0 + 124], fill=(228, 228, 230), outline=(160, 160, 166))
        base, dot = kinds[t]
        for r in range(2):
            for c in range(4):
                cx = x0 + 34 + c * 62 + R.randint(-3, 3); cy = y0 + 34 + r * 58 + R.randint(-3, 3)
                rr = R.randint(24, 27)
                d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=jit(base, 8), outline=jit(tuple(int(v * 0.8) for v in base), 5))
                if dot:
                    for _ in range(9):
                        a = R.random() * 6.28; q = R.random() * rr * 0.75
                        px, py = cx + math.cos(a) * q, cy + math.sin(a) * q
                        d.ellipse([px - 3, py - 3, px + 3, py + 3], fill=jit(dot, 15))
                else:
                    for _ in range(14):
                        a = R.random() * 6.28; q = R.random() * rr * 0.8
                        px, py = cx + math.cos(a) * q, cy + math.sin(a) * q
                        d.line([(px, py), (px + 4, py + 2)], fill=R.choice([(230, 60, 80), (60, 120, 230), (250, 220, 40), (60, 180, 90)]), width=2)
    save(noise(im, 2), "cookies")


def cookie_cakes():
    """The big decorated cookie cakes leaning in the GAC case's sloped lower window: 4 across, each a
    round cookie with an icing border and piped invented lettering. One tile = 4 cakes."""
    W, H = 1024, 256
    im = Image.new("RGB", (W, H), (120, 30, 44))
    d = ImageDraw.Draw(im)
    words = ["Happy Day!", "Congrats", "Go Team", "Love You"]
    for k in range(4):
        cx, cy = k * 256 + 128, 128
        d.ellipse([cx - 112, cy - 112, cx + 112, cy + 112], fill=(214, 168, 100))
        for j in range(36):
            a = j / 36 * 6.28
            px, py = cx + math.cos(a) * 100, cy + math.sin(a) * 100
            d.ellipse([px - 9, py - 9, px + 9, py + 9], fill=R.choice([(250, 250, 250), (40, 40, 40)]) if k % 2 else (250, 250, 250))
        for _ in range(18):
            a = R.random() * 6.28; q = R.random() * 80
            d.ellipse([cx + math.cos(a) * q - 5, cy + math.sin(a) * q - 5, cx + math.cos(a) * q + 5, cy + math.sin(a) * q + 5], fill=(80, 46, 24))
        f = ImageFont.truetype(SERIFI, 34)
        w = d.textlength(words[k], font=f)
        d.text((cx - w / 2, cy - 22), words[k], font=f, fill=R.choice([(40, 80, 200), (200, 30, 60), (30, 140, 60), (120, 40, 160)]))
    save(noise(im, 2), "cookie_cakes")


def menus():
    """Menu boards, 4 across: GAC (purple header, white board), Auntie Anne's (navy), Cakelicious
    (pink), a phone-plan poster (AT&T's back wall, blue). Invented lines."""
    W, H = 1024, 320
    im = Image.new("RGB", (W, H), (240, 240, 240))
    d = ImageDraw.Draw(im)
    heads = [((104, 40, 120), "BAKED FRESH EVERY DAY"), ((24, 40, 84), "FRESH PRETZELS"), ((230, 110, 160), "CAKES & CUPCAKES"), ((20, 110, 200), "NEW PHONES")]
    for k, (hc, ht) in enumerate(heads):
        x0 = k * 256
        d.rectangle([x0 + 4, 4, x0 + 252, 316], fill=(252, 252, 250))
        d.rectangle([x0 + 4, 4, x0 + 252, 56], fill=hc)
        f = ImageFont.truetype(BOLD, 18)
        w = d.textlength(ht, font=f)
        d.text((x0 + 128 - w / 2, 18), ht, font=f, fill=(255, 255, 255))
        for c in range(2):
            for j in range(7):
                y = 74 + j * 30
                d.line([(x0 + 16 + c * 120, y), (x0 + 16 + c * 120 + R.randint(50, 96), y)], fill=(70, 70, 76), width=6)
                d.line([(x0 + 112 + c * 120, y), (x0 + 124 + c * 120, y)], fill=hc, width=6)
        d.rectangle([x0 + 4, 290, x0 + 252, 316], fill=hc)
    save(noise(im, 1.5), "menus")


def posters():
    """Lit poster panels and window graphics, 4 across, abstract invented art: Spencer's stands
    (yellow / purple), a sale banner (Rainbow, Aéropostale), a lifestyle panel (Claire's pink)."""
    W, H = 1024, 512
    im = Image.new("RGB", (W, H), (20, 20, 20))
    d = ImageDraw.Draw(im)
    bgs = [(250, 220, 40), (110, 50, 150), (220, 30, 40), (240, 150, 200)]
    for k in range(4):
        x0 = k * 256
        d.rectangle([x0 + 6, 6, x0 + 250, 506], fill=bgs[k])
        if k < 2:
            d.ellipse([x0 + 60, 120, x0 + 196, 256], fill=(30, 30, 34))
            d.rectangle([x0 + 70, 250, x0 + 186, 420], fill=R.choice([(200, 40, 50), (40, 40, 44)]))
            d.ellipse([x0 + 92, 160, x0 + 112, 180], fill=(250, 250, 250)); d.ellipse([x0 + 144, 160, x0 + 164, 180], fill=(250, 250, 250))
        elif k == 2:
            f = ImageFont.truetype(BOLD, 64)
            for j, t in enumerate(["SALE", "UP TO", "50%"]):
                w = d.textlength(t, font=f)
                d.text((x0 + 128 - w / 2, 120 + j * 90), t, font=f, fill=(255, 255, 255))
        else:
            for j in range(12):
                cx = x0 + R.randint(40, 216); cy = R.randint(60, 460)
                d.ellipse([cx - 22, cy - 22, cx + 22, cy + 22], fill=R.choice([(250, 250, 250), (200, 120, 220), (250, 200, 230)]))
    save(noise(im, 2), "posters")


def graffiti_shutter():
    """Spencer's half-raised roll shutter: horizontal slats under a spray-paint wash of red, pink,
    blue and purple (the store's graffiti sign itself is the Demo 43 spec, built over it)."""
    W, H = 512, 224
    a = np.zeros((H, W, 3), np.float32)
    cols = np.array([(200, 40, 70), (230, 90, 170), (60, 90, 220), (120, 50, 170), (240, 60, 60)], np.float32)
    for _ in range(40):
        cx, cy = R.randint(0, W), R.randint(0, H); r = R.randint(30, 110)
        c = cols[R.randint(0, 4)]
        y, x = np.ogrid[:H, :W]
        m = np.exp(-(((x - cx) ** 2 + (y - cy) ** 2) / (2 * r * r)))[..., None]
        a = a * (1 - m * 0.8) + c * m * 0.8
    for y in range(0, H, 14):
        a[y:y + 2] *= 0.55
    save(noise(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)), 3), "shutter")


def jewelry():
    """DJS' case tops seen through the glass: black velvet trays with rows of gold and silver rings
    and pendants. One tile = 1.2 x 0.5 m."""
    W, H = 768, 320
    im = Image.new("RGB", (W, H), (18, 16, 18))
    d = ImageDraw.Draw(im)
    for r in range(4):
        for c in range(14):
            cx = 30 + c * 52; cy = 40 + r * 76
            col = R.choice([(230, 190, 90), (210, 210, 220), (240, 200, 110)])
            d.ellipse([cx - 12, cy - 12, cx + 12, cy + 12], outline=col, width=4)
            if R.random() < 0.6:
                d.ellipse([cx - 4, cy - 17, cx + 4, cy - 9], fill=(250, 250, 255))
    save(noise(im, 1.5), "jewelry")


def cakes():
    """Cakelicious' case: rows of cakes and cupcakes, front view; pinks, whites, chocolate."""
    W, H = 768, 320
    im = Image.new("RGB", (W, H), (250, 244, 246))
    d = ImageDraw.Draw(im)
    for s in range(2):
        yb = 150 + s * 150
        d.rectangle([0, yb, W, yb + 8], fill=(220, 220, 224))
        x = 10
        while x < W - 60:
            if R.random() < 0.5:
                w = R.randint(80, 110); h = R.randint(60, 90)
                c = R.choice([(250, 200, 220), (250, 250, 250), (110, 60, 40), (250, 230, 180), (200, 150, 220)])
                d.rectangle([x, yb - h, x + w, yb], fill=c)
                d.rectangle([x, yb - h, x + w, yb - h + 10], fill=jit(c, 30))
                for _ in range(5):
                    bx = x + R.randint(5, w - 15)
                    d.ellipse([bx, yb - h - 8, bx + 10, yb - h + 2], fill=(220, 40, 70))
                x += w + 12
            else:
                for k in range(3):
                    c = R.choice([(250, 180, 210), (250, 250, 250), (150, 90, 60), (200, 220, 250)])
                    d.polygon([(x, yb), (x + 34, yb), (x + 30, yb - 30), (x + 4, yb - 30)], fill=(220, 180, 120))
                    d.ellipse([x - 2, yb - 56, x + 36, yb - 24], fill=c)
                    x += 42
                x += 10
    save(noise(im, 2), "cakes")


def pretzels():
    """Auntie Anne's warmer: tiers of twisted pretzels on a gold-lit rack, front view."""
    W, H = 512, 256
    im = Image.new("RGB", (W, H), (250, 220, 150))
    d = ImageDraw.Draw(im)
    for s in range(2):
        cy = 70 + s * 120
        for k in range(6):
            cx = 44 + k * 84
            col = jit((180, 110, 50), 10)
            d.arc([cx - 30, cy - 26, cx + 30, cy + 30], 200, 520, fill=col, width=11)
            d.line([(cx - 20, cy + 22), (cx + 14, cy - 8)], fill=col, width=10)
            d.line([(cx + 20, cy + 22), (cx - 14, cy - 8)], fill=col, width=10)
            for _ in range(10):
                d.point((cx + R.randint(-26, 26), cy + R.randint(-20, 26)), fill=(250, 250, 250))
        d.rectangle([0, cy + 40, W, cy + 46], fill=(200, 160, 80))
    save(noise(im, 2), "pretzels")


def billiard():
    """Pool-table felt (blue) and the APL banner panels (red/white/blue stripes, a star)."""
    im = Image.new("RGB", (128, 128), (36, 90, 170))
    save(noise(im, 5).filter(ImageFilter.GaussianBlur(0.8)), "felt")
    W, H = 512, 256
    im = Image.new("RGB", (W, H), (250, 250, 250))
    d = ImageDraw.Draw(im)
    for k in range(2):
        x0 = k * 256
        d.rectangle([x0 + 6, 6, x0 + 250, 250], fill=(30, 50, 120))
        for j in range(5):
            d.rectangle([x0 + 6, 140 + j * 22, x0 + 250, 150 + j * 22], fill=(200, 30, 40) if j % 2 == 0 else (250, 250, 250))
        cx, cy = x0 + 128, 70
        pts = [(cx + math.cos(math.radians(-90 + i * 36)) * (44 if i % 2 == 0 else 18), cy + math.sin(math.radians(-90 + i * 36)) * (44 if i % 2 == 0 else 18)) for i in range(10)]
        d.polygon(pts, fill=(250, 250, 250))
    save(noise(im, 2), "banners")


def ref_stripe():
    """Foot Locker's referee-stripe header: black and white vertical stripes, 5 cm."""
    im = Image.new("RGB", (128, 64), (245, 245, 245))
    d = ImageDraw.Draw(im)
    for k in range(0, 128, 22):
        d.rectangle([k, 0, k + 10, 64], fill=(18, 18, 20))
    save(im, "ref")


if __name__ == "__main__":
    for f in (brick, concrete, planks, gingham, beadboard, wave, crumple, travertine, tees, caps, bottles, accessories,
              cookies, cookie_cakes, menus, posters, graffiti_shutter, jewelry, cakes, pretzels, billiard, ref_stripe):
        f()
    print("wrote", len(os.listdir(OUT)), "files")
