"""Radio Shack's standalone items (workstream D, Nov 1 2026; design/storefronts/radio-shack.md):
eight period-correct, generic 1995 electronics that sit on the store's counter as separate nodes
and become inventory items (workstream B+C picks them up; data/items/radioshack.json).

This script paints one hi-res texture atlas per item (items/radioshack/tex/<id>.png, 1024 or
2048 px) and writes tools/stores/radioshack_items/spec.json: the parts of each item (boxes and cylinders in
metres, origin at the bottom centre, the front facing +z) and, for every textured box face, the
atlas rectangle it shows. tools/stores/radioshack_items/make_items.gd builds the meshes, scenes
and icons from it.

IP rule (CLAUDE-CLOUD.md): no real product names, logos or box art. The brand on every item,
VOLTARO, and the product names (Scan-50, Thunderclaw, Chatter 2 ...) are invented.
  python3 tools/stores/radioshack_items/paint_items.py   (from the project folder)
"""
import json, math, os, random
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
OUT = os.path.join(PROJ, "items", "radioshack")
TEX = os.path.join(OUT, "tex")
os.makedirs(TEX, exist_ok=True)
DJ = "/usr/share/fonts/truetype/dejavu/"
LIB = "/usr/share/fonts/truetype/liberation/"
SANS_B = DJ + "DejaVuSans-Bold.ttf"
SANS = DJ + "DejaVuSans.ttf"
COND_B = LIB + "LiberationSansNarrow-Bold.ttf" if os.path.exists(LIB + "LiberationSansNarrow-Bold.ttf") else SANS_B
ITAL_B = LIB + "LiberationSans-BoldItalic.ttf"
MONO_B = DJ + "DejaVuSansMono-Bold.ttf"
BRAND = "VOLTARO"


def font(path, px):
    return ImageFont.truetype(path, max(6, int(px)))


def fit(d, text, path, box, fill, anchor="mm", max_px=400):
    """Largest size of `text` that fits `box` (x0, y0, x1, y1), drawn centred."""
    x0, y0, x1, y1 = box
    px = max_px
    while px > 6:
        f = font(path, px)
        l, t, r, b = d.textbbox((0, 0), text, font=f)
        if r - l <= (x1 - x0) and b - t <= (y1 - y0):
            break
        px -= 2
    d.text(((x0 + x1) / 2, (y0 + y1) / 2), text, font=f, fill=fill, anchor=anchor)


class Atlas:
    """An item's texture: regions are cut left to right in rows; rect() returns uv [u0, v0, u1, v1]."""

    def __init__(self, size):
        self.N = size
        self.im = Image.new("RGB", (size, size), (20, 20, 22))
        self.d = ImageDraw.Draw(self.im)
        self.x = 0
        self.y = 0
        self.row_h = 0

    def region(self, w, h):
        if self.x + w > self.N:
            self.x = 0
            self.y += self.row_h + 4
            self.row_h = 0
        x0, y0 = self.x, self.y
        assert y0 + h <= self.N, "atlas full"
        self.x += w + 4
        self.row_h = max(self.row_h, h)
        return (x0, y0, x0 + w, y0 + h)

    def uv(self, r):
        # a half-pixel inset so mipmaps do not bleed the neighbour in
        return [(r[0] + 1) / self.N, (r[1] + 1) / self.N, (r[2] - 1) / self.N, (r[3] - 1) / self.N]

    def save(self, name):
        p = os.path.join(TEX, name + ".png")
        self.im.save(p, optimize=True)
        return "res://items/radioshack/tex/%s.png" % name


def plastic(A, w, h, col, grain=6, seed=1):
    """A region of textured plastic (fine noise), for sides."""
    r = A.region(w, h)
    rnd = random.Random(seed)
    A.d.rectangle(r, fill=col)
    for _ in range(w * h // 18):
        x = rnd.randint(r[0], r[2] - 1)
        y = rnd.randint(r[1], r[3] - 1)
        v = rnd.randint(-grain, grain)
        A.im.putpixel((x, y), tuple(max(0, min(255, c + v)) for c in col))
    return r


def bevel(d, r, light, dark, w=3):
    x0, y0, x1, y1 = r
    for i in range(w):
        d.line([(x0 + i, y1 - i), (x0 + i, y0 + i), (x1 - i, y0 + i)], fill=light)
        d.line([(x0 + i, y1 - i), (x1 - i, y1 - i), (x1 - i, y0 + i)], fill=dark)


def grille(d, r, col, gap=10, dot=3):
    x0, y0, x1, y1 = r
    for y in range(y0 + gap // 2, y1, gap):
        for x in range(x0 + gap // 2, x1, gap):
            d.ellipse([x - dot, y - dot, x + dot, y + dot], fill=col)


def keypad(d, r, cols, rows, labels, key_col=(58, 58, 62), txt=(235, 235, 230), px=None):
    x0, y0, x1, y1 = r
    kw = (x1 - x0) / cols
    kh = (y1 - y0) / rows
    for j in range(rows):
        for i in range(cols):
            k = j * cols + i
            if k >= len(labels):
                return
            bx = (x0 + i * kw + 3, y0 + j * kh + 3, x0 + (i + 1) * kw - 3, y0 + (j + 1) * kh - 3)
            d.rounded_rectangle(bx, radius=int(min(kw, kh) * 0.18), fill=key_col)
            bevel(d, bx, tuple(min(255, c + 40) for c in key_col), tuple(max(0, c - 30) for c in key_col), 2)
            if labels[k]:
                fit(d, labels[k], SANS_B, (bx[0] + 4, bx[1] + 4, bx[2] - 4, bx[3] - 4), txt, max_px=px or int(kh * 0.5))


def lcd(d, r, text, bg=(150, 168, 120), fg=(30, 36, 28), path=MONO_B):
    d.rectangle(r, fill=(24, 24, 26))
    x0, y0, x1, y1 = r
    inner = (x0 + 8, y0 + 8, x1 - 8, y1 - 8)
    d.rectangle(inner, fill=bg)
    fit(d, text, path, (inner[0] + 8, inner[1] + 6, inner[2] - 8, inner[3] - 6), fg)


# ----------------------------------------------------------------------------- the items
SPEC = {}


def box(c, s, faces=None, mat="tex", default=None):
    return {"type": "box", "c": c, "s": s, "faces": faces or {}, "mat": mat, "default": default}


def cyl(c, r, h, mat, axis="y", r_top=None, seg=16):
    return {"type": "cyl", "c": c, "r": r, "r_top": r if r_top is None else r_top, "h": h, "mat": mat, "axis": axis, "seg": seg}


def scanner():
    A = Atlas(1024)
    body = (36, 36, 40)
    side = A.uv(plastic(A, 128, 340, body, 5, 11))
    # front: 0.065 x 0.17 m at 1024 px... 360 x 940 px
    r = A.region(360, 940)
    d = A.d
    d.rectangle(r, fill=body)
    x0, y0, x1, y1 = r
    bevel(d, r, (70, 70, 76), (14, 14, 16), 6)
    grille(d, (x0 + 40, y0 + 40, x1 - 40, y0 + 230), (12, 12, 14), 18, 5)
    fit(d, BRAND, SANS_B, (x0 + 40, y0 + 245, x1 - 40, y0 + 285), (210, 210, 205))
    fit(d, "SCAN-50", ITAL_B, (x0 + 40, y0 + 290, x1 - 40, y0 + 320), (232, 160, 40))
    fit(d, "50-CHANNEL PROGRAMMABLE SCANNER", SANS, (x0 + 30, y0 + 322, x1 - 30, y0 + 342), (160, 160, 158))
    lcd(d, (x0 + 30, y0 + 355, x1 - 30, y0 + 480), "CH 12  154.430")
    keypad(d, (x0 + 26, y0 + 500, x1 - 26, y0 + 900), 4, 5,
           ["1", "2", "3", "SCAN", "4", "5", "6", "MAN", "7", "8", "9", "PGM", "CLR", "0", ".", "E", "PRI", "LO", "WX", "LIGHT"],
           key_col=(70, 72, 78))
    front = A.uv(r)
    rt = A.region(128, 128)
    d.rectangle(rt, fill=body)
    d.ellipse([rt[0] + 20, rt[1] + 20, rt[0] + 70, rt[1] + 70], fill=(18, 18, 20))
    top = A.uv(rt)
    tex = A.save("scanner")
    W, H, D = 0.065, 0.17, 0.035
    parts = [box([0, H / 2, 0], [W, H, D], {"+z": front, "+y": top, "-z": side, "+x": side, "-x": side, "-y": side}),
             cyl([-0.018, H, -0.002], 0.006, 0.12, "rubber"), cyl([-0.018, H + 0.12, -0.002], 0.008, 0.012, "rubber"),
             cyl([0.016, H, 0.0], 0.008, 0.014, "knob"), cyl([0.002, H, 0.0], 0.007, 0.012, "knob")]
    return tex, parts


def walkie_pair():
    A = Atlas(1024)
    body = (44, 46, 52)
    side = A.uv(plastic(A, 120, 300, body, 5, 21))
    d = A.d
    r = A.region(330, 830)
    x0, y0, x1, y1 = r
    d.rectangle(r, fill=body)
    bevel(d, r, (80, 82, 90), (16, 16, 18), 6)
    grille(d, (x0 + 34, y0 + 40, x1 - 34, y0 + 330), (16, 16, 18), 16, 5)
    d.rounded_rectangle([x0 + 30, y0 + 360, x1 - 30, y0 + 440], radius=12, fill=(232, 120, 30))
    fit(d, BRAND, SANS_B, (x0 + 40, y0 + 365, x1 - 40, y0 + 435), (24, 24, 26))
    fit(d, "CHATTER 2", ITAL_B, (x0 + 30, y0 + 455, x1 - 30, y0 + 495), (230, 230, 225))
    fit(d, "49 MHz  2-WAY RADIO", SANS_B, (x0 + 30, y0 + 500, x1 - 30, y0 + 528), (160, 162, 168))
    d.ellipse([x0 + 140, y0 + 560, x0 + 190, y0 + 610], fill=(200, 30, 30))  # the power LED's lens
    fit(d, "CALL", SANS_B, (x0 + 60, y0 + 650, x1 - 60, y0 + 760), (220, 220, 216), max_px=60)
    d.rounded_rectangle([x0 + 60, y0 + 640, x1 - 60, y0 + 770], radius=16, outline=(140, 140, 146), width=5)
    front = A.uv(r)
    ps = A.region(120, 300)
    d.rectangle(ps, fill=body)
    d.rounded_rectangle([ps[0] + 20, ps[1] + 60, ps[2] - 20, ps[1] + 220], radius=14, fill=(232, 120, 30))
    fit(d, "PTT", SANS_B, (ps[0] + 24, ps[1] + 110, ps[2] - 24, ps[1] + 170), (24, 24, 26))
    ptt = A.uv(ps)
    tex = A.save("walkie_talkies")
    W, H, D = 0.058, 0.145, 0.034
    parts = []
    for sx in [-0.036, 0.036]:
        parts.append(box([sx, H / 2, 0], [W, H, D], {"+z": front, "-x": ptt if sx > 0 else side, "+x": side if sx > 0 else ptt, "-z": side, "+y": side, "-y": side}))
        parts.append(cyl([sx - 0.017, H, 0.0], 0.0045, 0.22, "chrome"))
        parts.append(cyl([sx - 0.017, H + 0.22, 0.0], 0.006, 0.008, "chrome"))
        parts.append(cyl([sx + 0.015, H, 0.0], 0.007, 0.012, "knob"))
    return tex, parts


def monster_truck(d, r, rnd):
    """The invented box-art truck: big black tyres, a red-orange body with yellow flames, a
    chrome roll bar, on a desert-dusk sky with speed lines."""
    x0, y0, x1, y1 = r
    w, h = x1 - x0, y1 - y0
    for i in range(h):
        t = i / h
        col = (int(40 + 180 * t), int(30 + 70 * t), int(110 - 40 * t))
        d.line([(x0, y0 + i), (x1, y0 + i)], fill=col)
    for k in range(14):
        yy = y0 + rnd.randint(int(h * 0.2), int(h * 0.75))
        d.line([(x0, yy), (x0 + rnd.randint(w // 5, w // 2), yy)], fill=(255, 220, 120), width=3)
    gy = y0 + int(h * 0.82)
    d.polygon([(x0, gy), (x1, gy - 40), (x1, y1), (x0, y1)], fill=(150, 96, 52))
    cx = x0 + w * 0.52
    # tyres
    for tx in [cx - w * 0.24, cx + w * 0.24]:
        R = h * 0.2
        ty = gy - R * 0.6
        d.ellipse([tx - R, ty - R, tx + R, ty + R], fill=(18, 18, 20))
        for a in range(0, 360, 20):
            ax = tx + math.cos(math.radians(a)) * R * 0.92
            ay = ty + math.sin(math.radians(a)) * R * 0.92
            d.ellipse([ax - 7, ay - 7, ax + 7, ay + 7], fill=(40, 40, 44))
        d.ellipse([tx - R * 0.45, ty - R * 0.45, tx + R * 0.45, ty + R * 0.45], fill=(200, 200, 205))
        d.ellipse([tx - R * 0.2, ty - R * 0.2, tx + R * 0.2, ty + R * 0.2], fill=(120, 120, 126))
    # body
    by = gy - h * 0.48
    d.polygon([(cx - w * 0.36, by + h * 0.14), (cx - w * 0.3, by), (cx + w * 0.08, by), (cx + w * 0.16, by - h * 0.12),
               (cx + w * 0.3, by - h * 0.12), (cx + w * 0.36, by + h * 0.02), (cx + w * 0.38, by + h * 0.16),
               (cx - w * 0.36, by + h * 0.18)], fill=(220, 52, 30))
    d.polygon([(cx + w * 0.17, by - h * 0.1), (cx + w * 0.29, by - h * 0.1), (cx + w * 0.33, by), (cx + w * 0.17, by)], fill=(150, 200, 230))
    for k in range(5):
        fx = cx - w * 0.3 + k * w * 0.1
        d.polygon([(fx, by + h * 0.16), (fx + w * 0.05, by + h * 0.02), (fx + w * 0.04, by + h * 0.1), (fx + w * 0.1, by + h * 0.04),
                   (fx + w * 0.07, by + h * 0.16)], fill=(250, 210, 40))
    d.line([(cx - w * 0.05, by), (cx - w * 0.02, by - h * 0.12), (cx + w * 0.12, by - h * 0.12)], fill=(220, 220, 226), width=8)


def rc_box():
    A = Atlas(2048)
    d = A.d
    rnd = random.Random(1995)
    blue = (36, 54, 150)
    # front 0.5 x 0.3 m -> 1280 x 768
    r = A.region(1280, 768)
    x0, y0, x1, y1 = r
    d.rectangle(r, fill=blue)
    monster_truck(d, (x0 + 30, y0 + 170, x1 - 30, y1 - 96), rnd)
    d.rectangle([x0, y0, x1, y0 + 160], fill=(20, 26, 70))
    fit(d, "THUNDERCLAW", ITAL_B, (x0 + 50, y0 + 24, x1 - 340, y0 + 140), (255, 214, 40))
    d.rounded_rectangle([x1 - 300, y0 + 32, x1 - 32, y0 + 132], radius=20, fill=(220, 30, 30))
    fit(d, "R/C 1:10", SANS_B, (x1 - 285, y0 + 44, x1 - 48, y0 + 120), (255, 255, 255))
    d.rectangle([x0, y1 - 96, x1, y1], fill=(20, 26, 70))
    fit(d, BRAND + "  RADIO-CONTROLLED 4x4  •  TURBO SPEED  •  27 MHz", SANS_B, (x0 + 30, y1 - 80, x1 - 30, y1 - 16), (240, 240, 235))
    d.ellipse([x1 - 240, y0 + 200, x1 - 48, y0 + 392], fill=(255, 214, 40))
    fit(d, "FULL", SANS_B, (x1 - 216, y0 + 236, x1 - 72, y0 + 292), (200, 20, 20))
    fit(d, "FUNCTION", SANS_B, (x1 - 224, y0 + 292, x1 - 64, y0 + 348), (200, 20, 20))
    front = A.uv(r)
    # side 0.25 x 0.3 -> 640 x 768
    s = A.region(640, 768)
    d.rectangle(s, fill=blue)
    d.rectangle([s[0], s[1], s[2], s[1] + 160], fill=(20, 26, 70))
    fit(d, "THUNDERCLAW", ITAL_B, (s[0] + 30, s[1] + 30, s[2] - 30, s[1] + 130), (255, 214, 40))
    yy = s[1] + 200
    for line in ["• Forward / reverse, left / right", "• Big-foot tyres, coil suspension", "• Runs on 6 AA, controller 9 V", "  (batteries not included)", "• Range up to 60 ft", "• Ages 8 and up"]:
        d.text((s[0] + 30, yy), line, font=font(SANS_B, 30), fill=(235, 235, 230))
        yy += 52
    d.rectangle([s[0] + 40, s[3] - 180, s[0] + 380, s[3] - 40], fill=(255, 255, 255))
    for k in range(40):   # an invented bar code
        bw = rnd.choice([3, 5, 8])
        bx = s[0] + 60 + k * 7.5
        d.rectangle([bx, s[3] - 165, bx + bw * 0.6, s[3] - 70], fill=(10, 10, 10))
    fit(d, "Model 60-4123", SANS, (s[0] + 50, s[3] - 70, s[0] + 370, s[3] - 45), (10, 10, 10))
    side = A.uv(s)
    # top 0.5 x 0.25 -> 1280 x 640
    t = A.region(1280, 640)
    d.rectangle(t, fill=(20, 26, 70))
    fit(d, "THUNDERCLAW", ITAL_B, (t[0] + 60, t[1] + 160, t[2] - 60, t[1] + 420), (255, 214, 40))
    fit(d, BRAND, SANS_B, (t[0] + 240, t[1] + 450, t[2] - 240, t[1] + 540), (240, 240, 235))
    top = A.uv(t)
    # back (repeat the art, smaller detail)
    bk = A.region(640, 384)
    d.rectangle(bk, fill=blue)
    monster_truck(d, (bk[0] + 60, bk[1] + 30, bk[2] - 60, bk[3] - 110), random.Random(7))
    fit(d, "Big wheels. Big jumps. Big fun.", ITAL_B, (bk[0] + 30, bk[3] - 100, bk[2] - 30, bk[3] - 30), (255, 255, 255))
    back = A.uv(bk)
    tex = A.save("rc_car_box")
    W, H, D = 0.5, 0.3, 0.25
    return tex, [box([0, H / 2, 0], [W, H, D], {"+z": front, "-z": back, "+x": side, "-x": side, "+y": top, "-y": side})]


def cordless_phone():
    A = Atlas(2048)
    d = A.d
    ivory = (226, 222, 210)
    side = A.uv(plastic(A, 200, 120, ivory, 4, 31))
    # handset top face: 0.055 x 0.2 m -> 280 x 1000 (v along its length)
    r = A.region(280, 1000)
    x0, y0, x1, y1 = r
    d.rectangle(r, fill=ivory)
    grille(d, (x0 + 60, y0 + 40, x1 - 60, y0 + 170), (120, 118, 110), 16, 4)
    fit(d, BRAND, SANS_B, (x0 + 40, y0 + 190, x1 - 40, y0 + 230), (90, 90, 96))
    d.rounded_rectangle([x0 + 40, y0 + 250, x0 + 130, y0 + 310], radius=10, fill=(40, 150, 70))
    fit(d, "TALK", SANS_B, (x0 + 44, y0 + 256, x0 + 126, y0 + 304), (240, 240, 235))
    d.rounded_rectangle([x1 - 130, y0 + 250, x1 - 40, y0 + 310], radius=10, fill=(170, 60, 50))
    fit(d, "OFF", SANS_B, (x1 - 126, y0 + 256, x1 - 44, y0 + 304), (240, 240, 235))
    keypad(d, (x0 + 30, y0 + 340, x1 - 30, y0 + 820), 3, 5,
           ["1", "2 ABC", "3 DEF", "4 GHI", "5 JKL", "6 MNO", "7 PRS", "8 TUV", "9 WXY", "*", "0", "#", "FLASH", "REDIAL", "MEM"],
           key_col=(200, 196, 184), txt=(40, 40, 44), px=30)
    grille(d, (x0 + 110, y0 + 880, x1 - 110, y0 + 960), (120, 118, 110), 12, 3)
    hand_top = A.uv(r)
    # base front 0.17 x 0.06 -> 680 x 240
    b = A.region(680, 240)
    d.rectangle(b, fill=ivory)
    fit(d, BRAND + "  900 MHz CORDLESS", SANS_B, (b[0] + 30, b[1] + 30, b[2] - 30, b[1] + 80), (90, 90, 96))
    for k, (lbl, c) in enumerate([("IN USE", (220, 40, 30)), ("CHARGE", (240, 170, 30))]):
        lx = b[0] + 120 + k * 260
        d.ellipse([lx, b[1] + 120, lx + 30, b[1] + 150], fill=c)
        d.text((lx + 44, b[1] + 118), lbl, font=font(SANS_B, 30), fill=(90, 90, 96))
    base_front = A.uv(b)
    bt = A.region(680, 800)
    d.rectangle(bt, fill=ivory)
    d.rounded_rectangle([bt[0] + 190, bt[1] + 40, bt[2] - 190, bt[3] - 40], radius=40, fill=(198, 194, 182))   # the cradle
    fit(d, "PAGE", SANS_B, (bt[0] + 40, bt[3] - 120, bt[0] + 170, bt[3] - 60), (90, 90, 96))
    base_top = A.uv(bt)
    tex = A.save("cordless_phone")
    parts = [box([0, 0.03, 0], [0.17, 0.06, 0.2], {"+z": base_front, "+y": base_top, "-z": side, "+x": side, "-x": side, "-y": side}),
             box([0, 0.075, -0.005], [0.055, 0.03, 0.2], {"+y": hand_top, "+z": side, "-z": side, "+x": side, "-x": side, "-y": side}),
             cyl([0.07, 0.06, -0.08], 0.005, 0.11, "black_plastic"), cyl([0.07, 0.17, -0.08], 0.007, 0.01, "black_plastic")]
    return tex, parts


def battery_card():
    A = Atlas(1024)
    d = A.d
    # card 0.1 x 0.16 m -> 600 x 960
    r = A.region(600, 960)
    x0, y0, x1, y1 = r
    d.rectangle(r, fill=(200, 26, 30))
    d.rounded_rectangle([x0 + 230, y0 + 24, x1 - 230, y0 + 70], radius=20, fill=(30, 30, 32))   # the hang hole
    d.rectangle([x0, y0 + 100, x1, y0 + 240], fill=(16, 16, 18))
    fit(d, BRAND, SANS_B, (x0 + 30, y0 + 110, x1 - 30, y0 + 175), (255, 214, 40))
    fit(d, "HEAVY DUTY ALKALINE", SANS_B, (x0 + 30, y0 + 180, x1 - 30, y0 + 228), (240, 240, 235))
    # four AA cells under the blister
    for k in range(4):
        bx = x0 + 70 + k * 120
        d.rounded_rectangle([bx, y0 + 290, bx + 96, y0 + 800], radius=14, fill=(30, 30, 34))
        d.rectangle([bx, y0 + 290, bx + 96, y0 + 470], fill=(200, 160, 40))
        d.rectangle([bx + 34, y0 + 270, bx + 62, y0 + 292], fill=(190, 190, 196))
        fit(d, "AA", SANS_B, (bx + 10, y0 + 560, bx + 86, y0 + 640), (240, 240, 235))
        d.line([(bx + 18, y0 + 300), (bx + 18, y0 + 790)], fill=(255, 255, 255), width=6)   # blister glint
    fit(d, "4 PACK  •  1.5 V", SANS_B, (x0 + 40, y0 + 840, x1 - 40, y0 + 920), (255, 255, 255))
    front = A.uv(r)
    bk = A.region(300, 480)
    d.rectangle(bk, fill=(236, 232, 222))
    yy = bk[1] + 40
    for line in ["Long lasting power for", "toys, games, radios,", "flashlights and more.", "", "Do not recharge.", "Do not dispose of in fire."]:
        d.text((bk[0] + 24, yy), line, font=font(SANS_B, 17), fill=(60, 60, 64))
        yy += 30
    back = A.uv(bk)
    edge = A.uv(plastic(A, 60, 60, (200, 26, 30), 3, 41))
    tex = A.save("battery_card")
    W, H = 0.1, 0.16
    return tex, [box([0, H / 2, 0], [W, H, 0.004], {"+z": front, "-z": back}, default=edge),
                 box([0, 0.068, 0.009], [0.084, 0.088, 0.014], {"+z": A_sub(front, 0.0, 0.29, 1.0, 0.84)}, default=edge)]


def A_sub(uvr, a, b, c, dd):
    """A sub-rectangle of an atlas rect: fractions (a, b) to (c, dd) of it."""
    u0, v0, u1, v1 = uvr
    return [u0 + (u1 - u0) * a, v0 + (v1 - v0) * b, u0 + (u1 - u0) * c, v0 + (v1 - v0) * dd]


def pager():
    A = Atlas(1024)
    d = A.d
    blk = (24, 24, 28)
    side = A.uv(plastic(A, 120, 180, blk, 5, 51))
    # front 0.05 x 0.07 -> 500 x 700
    r = A.region(500, 700)
    x0, y0, x1, y1 = r
    d.rectangle(r, fill=blk)
    bevel(d, r, (60, 60, 66), (8, 8, 10), 5)
    lcd(d, (x0 + 40, y0 + 60, x1 - 40, y0 + 260), "555-0142", bg=(140, 170, 140))
    fit(d, BRAND, SANS_B, (x0 + 80, y0 + 300, x1 - 80, y0 + 350), (180, 180, 184))
    fit(d, "BEEPER 2000", ITAL_B, (x0 + 80, y0 + 360, x1 - 80, y0 + 400), (90, 170, 220))
    for k, lbl in enumerate(["READ", "SELECT"]):
        bx = x0 + 60 + k * 200
        d.rounded_rectangle([bx, y0 + 470, bx + 170, y0 + 560], radius=20, fill=(60, 60, 66))
        fit(d, lbl, SANS_B, (bx + 10, y0 + 490, bx + 160, y0 + 540), (220, 220, 216))
    front = A.uv(r)
    tex = A.save("pager")
    return tex, [box([0, 0.035, 0], [0.05, 0.07, 0.018], {"+z": front, "-z": side, "+x": side, "-x": side, "+y": side, "-y": side}),
                 box([0, 0.042, -0.012], [0.02, 0.05, 0.004], {}, "black_plastic")]


def cb_radio():
    A = Atlas(1024)
    d = A.d
    blk = (30, 30, 34)
    side = A.uv(plastic(A, 400, 120, blk, 5, 61))
    # front 0.16 x 0.05 -> 960 x 300
    r = A.region(960, 300)
    x0, y0, x1, y1 = r
    d.rectangle(r, fill=(52, 52, 56))
    bevel(d, r, (90, 90, 96), (14, 14, 16), 5)
    d.rectangle([x0 + 40, y0 + 60, x0 + 220, y0 + 240], fill=(12, 6, 6))
    fit(d, "19", MONO_B, (x0 + 50, y0 + 70, x0 + 210, y0 + 230), (255, 40, 30))
    d.rectangle([x0 + 250, y0 + 60, x0 + 480, y0 + 200], fill=(230, 220, 180))   # the S/RF meter
    for k in range(9):
        a = math.radians(200 + k * 15)
        cx, cy = x0 + 365, y0 + 230
        d.line([(cx + math.cos(a) * 120, cy + math.sin(a) * 120), (cx + math.cos(a) * 140, cy + math.sin(a) * 140)], fill=(40, 40, 40), width=4)
    d.line([(x0 + 365, y0 + 190), (x0 + 420, y0 + 90)], fill=(200, 30, 30), width=4)
    fit(d, "S / RF", SANS_B, (x0 + 300, y0 + 205, x0 + 430, y0 + 240), (200, 200, 196))
    fit(d, BRAND + "  CB-440", SANS_B, (x0 + 520, y0 + 30, x1 - 40, y0 + 80), (220, 220, 216))
    fit(d, "40 CHANNEL CB", SANS_B, (x0 + 520, y0 + 85, x1 - 40, y0 + 120), (232, 160, 40))
    for k, lbl in enumerate(["VOL", "SQ", "CH"]):
        fit(d, lbl, SANS_B, (x0 + 520 + k * 140, y0 + 250, x0 + 640 + k * 140, y0 + 285), (200, 200, 196))
    d.rectangle([x1 - 120, y0 + 140, x1 - 50, y0 + 200], fill=(20, 20, 22))   # the mic jack
    front = A.uv(r)
    m = A.region(300, 480)
    d.rectangle(m, fill=blk)
    grille(d, (m[0] + 30, m[1] + 30, m[2] - 30, m[1] + 300), (12, 12, 14), 18, 5)
    fit(d, BRAND, SANS_B, (m[0] + 30, m[1] + 330, m[2] - 30, m[1] + 380), (190, 190, 194))
    mic = A.uv(m)
    tex = A.save("cb_radio")
    parts = [box([0, 0.025, 0], [0.16, 0.05, 0.2], {"+z": front, "-z": side, "+x": side, "-x": side, "+y": side, "-y": side})]
    for k in range(3):
        parts.append(cyl([0.002 + k * 0.023, 0.012, 0.103], 0.009, 0.012, "knob", axis="z"))
    parts.append(box([0.11, 0.004, 0.02], [0.05, 0.008, 0.08], {"+y": mic}, "tex", default=side))
    parts.append(box([0.11, 0.0225, 0.02], [0.05, 0.029, 0.08], {"+y": mic}, "black_plastic"))
    return tex, parts


def microcassette():
    A = Atlas(1024)
    d = A.d
    silver = (176, 178, 184)
    side = A.uv(plastic(A, 120, 300, silver, 6, 71))
    # front 0.06 x 0.11 -> 480 x 880
    r = A.region(480, 880)
    x0, y0, x1, y1 = r
    d.rectangle(r, fill=silver)
    bevel(d, r, (220, 222, 228), (110, 112, 118), 6)
    grille(d, (x0 + 60, y0 + 40, x1 - 60, y0 + 200), (90, 92, 98), 16, 4)
    d.rounded_rectangle([x0 + 50, y0 + 260, x1 - 50, y0 + 560], radius=18, fill=(40, 40, 44))   # the cassette door
    d.rectangle([x0 + 90, y0 + 320, x1 - 90, y0 + 500], fill=(30, 26, 22))
    for cx in [x0 + 170, x1 - 170]:
        d.ellipse([cx - 40, y0 + 370, cx + 40, y0 + 450], fill=(230, 230, 226))
        d.ellipse([cx - 16, y0 + 394, cx + 16, y0 + 426], fill=(30, 30, 30))
    fit(d, BRAND, SANS_B, (x0 + 60, y0 + 600, x1 - 60, y0 + 650), (60, 60, 66))
    fit(d, "MICRO-CASSETTE RECORDER", SANS_B, (x0 + 40, y0 + 660, x1 - 40, y0 + 690), (90, 90, 96))
    for k, (lbl, c) in enumerate([("REC", (200, 30, 30)), ("PLAY", (60, 60, 66)), ("STOP", (60, 60, 66))]):
        bx = x0 + 40 + k * 140
        d.rounded_rectangle([bx, y0 + 730, bx + 120, y0 + 820], radius=14, fill=c)
        fit(d, lbl, SANS_B, (bx + 10, y0 + 750, bx + 110, y0 + 800), (240, 240, 235))
    front = A.uv(r)
    tex = A.save("microcassette")
    return tex, [box([0, 0.055, 0], [0.06, 0.11, 0.025], {"+z": front, "-z": side, "+x": side, "-x": side, "+y": side, "-y": side})]


ITEMS = [
    ("scanner", "Scan-50 police scanner", "hand", scanner),
    ("walkie_talkies", "Chatter 2 walkie-talkies (pair)", "hand", walkie_pair),
    ("rc_car_box", "Thunderclaw R/C 4x4 (boxed)", "hand", rc_box),
    ("cordless_phone", "900 MHz cordless phone", "hand", cordless_phone),
    ("battery_card", "AA batteries, 4-pack", "pocket", battery_card),
    ("pager", "Beeper 2000 pager", "pocket", pager),
    ("cb_radio", "CB-440 CB radio", "hand", cb_radio),
    ("microcassette", "Micro-cassette recorder", "pocket", microcassette),
]

if __name__ == "__main__":
    out = {"note": "written by tools/stores/radioshack_items/paint_items.py; read by make_items.gd", "items": []}
    for iid, name, cls, fn in ITEMS:
        tex, parts = fn()
        out["items"].append({"id": "rs_" + iid, "file": iid, "name": name, "class": cls, "tex": tex, "parts": parts})
    json.dump(out, open(os.path.join(HERE, "spec.json"), "w"), indent=1)
    print("wrote", len(ITEMS), "item atlases and tools/stores/radioshack_items/spec.json")
