"""Paints the games, inc. (2026) machine atlases: tex/gi/m_<kind>.png, one 1024 x 512 atlas per
machine kind, plus tools/stores/games_inc/machines/atlas.json (every region's pixel rect, read by
kit.gd so the geometry and the paint never drift apart).

Source: Steven's walkthrough IMG_4443 (f001-f058), IMG_4444 (g001-g006) and photo IMG_4445
(design/storefronts/games-inc-2026.md "The machines": the frame for each kind is noted on its painter).
Colours are read off those frames by eye. Cabinet names that are legible in the footage are set as plain
lettering in OFL fonts (the brief allows real cabinet wordmarks as signage); no logo is traced and no
character art is reproduced: where a cabinet carries licensed characters, that area is a generic
abstract translite in the cabinet's colours.

  python3 tools/stores/games_inc/machines/paint.py        (from the project folder; seeded)
"""
import json, math, os, random
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
OUT = os.path.join(PROJ, "tex", "gi")
os.makedirs(OUT, exist_ok=True)
FD = os.path.join(PROJ, "tools", "stores", "signs", "y26", "src", "fonts")
F_LIL = os.path.join(FD, "LilitaOne-Regular.ttf")
F_TIT = os.path.join(FD, "TitanOne-Regular.ttf")
F_ANT = os.path.join(FD, "Anton-Regular.ttf")
F_SAI = os.path.join(FD, "SairaExtraCondensed-Bold.ttf")
F_OSW = os.path.join(FD, "Oswald-Bold.ttf")
F_RUS = os.path.join(PROJ, "fonts", "forza.ttf")

W, H = 1024, 512
REG = {}


class Atlas:
    """A 1024 x 512 canvas with named regions placed by a simple shelf packer."""

    def __init__(self, kind, bg="#202024"):
        self.kind = kind
        self.im = Image.new("RGB", (W, H), bg)
        self.d = ImageDraw.Draw(self.im)
        self.x = 0; self.y = 0; self.row_h = 0
        self.reg = {}

    def slot(self, name, w, h):
        """Skyline packing on a 16 px column grid: the lowest place the w x h region fits."""
        if not hasattr(self, "sky"):
            self.sky = [0] * (W // 16)
        cw = (w + 15) // 16
        best = None
        for c in range(0, len(self.sky) - cw + 1):
            y = max(self.sky[c:c + cw])
            if y + h <= H and (best is None or y < best[1]):
                best = (c, y)
        assert best is not None, "%s: atlas full at %s" % (self.kind, name)
        c, y = best
        for k in range(c, c + cw):
            self.sky[k] = y + h
        r = (c * 16, y, c * 16 + w, y + h)
        self.reg[name] = list(r)
        return r

    def sub(self, r):
        """A fresh RGB image the size of region r, painted then pasted back with put()."""
        return Image.new("RGB", (r[2] - r[0], r[3] - r[1]))

    def put(self, r, im):
        self.im.paste(im.resize((r[2] - r[0], r[3] - r[1])), (r[0], r[1]))

    def save(self):
        p = os.path.join(OUT, "m_%s.png" % self.kind)
        self.im.save(p, optimize=True)
        REG[self.kind] = self.reg
        print("m_%s.png" % self.kind, os.path.getsize(p))


# ------------------------------------------------------------------ drawing helpers
def font(p, s):
    return ImageFont.truetype(p, int(s))


def fit_text(d, box, text, fpath, fill, stroke=0, stroke_fill=None, maxs=400, anchor="mm"):
    """Largest font size that fits text in box (x0, y0, x1, y1); drawn centred."""
    x0, y0, x1, y1 = box
    s = maxs
    while s > 6:
        f = font(fpath, s)
        bb = d.textbbox((0, 0), text, font=f, stroke_width=stroke)
        if bb[2] - bb[0] <= (x1 - x0) and bb[3] - bb[1] <= (y1 - y0):
            break
        s -= 2
    f = font(fpath, s)
    d.text(((x0 + x1) / 2, (y0 + y1) / 2), text, font=f, fill=fill, anchor=anchor, stroke_width=stroke,
           stroke_fill=stroke_fill)


def vgrad(im, top, bot, box=None):
    d = ImageDraw.Draw(im)
    x0, y0, x1, y1 = box or (0, 0, im.width, im.height)
    t = [int(top[1:][i:i + 2], 16) for i in (0, 2, 4)]
    b = [int(bot[1:][i:i + 2], 16) for i in (0, 2, 4)]
    for y in range(y0, y1):
        k = (y - y0) / max(1, (y1 - y0 - 1))
        d.line([x0, y, x1 - 1, y], fill=tuple(int(t[i] + (b[i] - t[i]) * k) for i in range(3)))


def led_dots(d, p0, p1, col, r=3, step=10):
    """A row of LED studs from p0 to p1 (the claws' and crossy road's dotted edge lights)."""
    n = max(1, int(math.dist(p0, p1) / step))
    for i in range(n + 1):
        x = p0[0] + (p1[0] - p0[0]) * i / n
        y = p0[1] + (p1[1] - p0[1]) * i / n
        d.ellipse([x - r, y - r, x + r, y + r], fill=col)


def burst(im, cols, cx=None, cy=None, rays=18, seed=1):
    """A generic abstract translite: radial rays in the cabinet's colours (stands in for licensed art)."""
    rng = random.Random(seed)
    w, h = im.size
    cx = w * 0.5 if cx is None else cx
    cy = h * 0.55 if cy is None else cy
    d = ImageDraw.Draw(im)
    R = math.hypot(w, h)
    for i in range(rays):
        a0 = TAU * i / rays; a1 = TAU * (i + 0.5) / rays
        d.polygon([(cx, cy), (cx + R * math.cos(a0), cy + R * math.sin(a0)), (cx + R * math.cos(a1), cy + R * math.sin(a1))],
                  fill=cols[i % len(cols)])
    for k in range(5):
        rr = (5 - k) * min(w, h) * 0.08
        d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=cols[(k + 1) % len(cols)])
    for _ in range(40):
        x = rng.uniform(0, w); y = rng.uniform(0, h); s = rng.uniform(1, 3)
        d.ellipse([x - s, y - s, x + s, y + s], fill="#ffffff")


TAU = math.tau


def prize_pile(im, seed, cols=None):
    """Plush heaped in a claw / merchandiser window: rounded blobs, no characters."""
    rng = random.Random(seed)
    cols = cols or ["#f6d23a", "#f08a2a", "#5db5e8", "#79c66a", "#e94f6a", "#8e6bd1", "#f3f1e8", "#ff8fc8",
                    "#3fc7c0", "#c44a3a"]
    d = ImageDraw.Draw(im)
    w, h = im.size
    for layer in range(3):
        for _ in range(int(w / 9)):
            x = rng.uniform(-10, w + 10)
            y = h * (0.15 + 0.3 * layer) + rng.uniform(-h * 0.12, h * 0.25)
            r = rng.uniform(h * 0.07, h * 0.14)
            c = rng.choice(cols)
            d.ellipse([x - r, y - r, x + r, y + r * 0.9], fill=c, outline="#00000040")
            d.ellipse([x - r * 0.35, y - r * 0.5, x - r * 0.1, y - r * 0.25], fill="#ffffff")
    return im


def prize_shelves(im, seed, n=4):
    """Merchandiser window: glass shelves of boxed prizes (generic boxes, invented colours)."""
    rng = random.Random(seed)
    d = ImageDraw.Draw(im)
    w, h = im.size
    vgrad(im, "#f6f6fb", "#d9dbe8")
    for k in range(n):
        y = h * (k + 1) / (n + 0.4)
        d.rectangle([0, y, w, y + 3], fill="#b8c4d8")
        x = 6
        while x < w - 20:
            bw = rng.uniform(w * 0.08, w * 0.18); bh = rng.uniform(h * 0.08, h / (n + 0.6) * 0.85)
            c = rng.choice(["#e8423a", "#2c7be5", "#f5b82e", "#25b45a", "#8d4fd8", "#1d1d24", "#ff6fae", "#f2f2f2"])
            d.rectangle([x, y - bh, x + bw, y], fill=c, outline="#00000060")
            d.rectangle([x + bw * 0.2, y - bh * 0.75, x + bw * 0.8, y - bh * 0.45], fill="#ffffff90")
            x += bw + rng.uniform(4, 12)
    return im


def tap_reader(d, cx, cy, s, col="#3cff6a"):
    """The card readers on every 2026 cabinet: a black square with a glowing ring and TAP."""
    d.rounded_rectangle([cx - s, cy - s * 0.75, cx + s, cy + s * 0.75], radius=s * 0.2, fill="#111", outline=col, width=max(2, int(s * 0.18)))
    fit_text(d, (cx - s * 0.6, cy - s * 0.4, cx + s * 0.6, cy + s * 0.4), "TAP", F_OSW, "#e8ffe8")


def panel_noise(im, amt=6, seed=3):
    rng = random.Random(seed)
    px = im.load()
    w, h = im.size
    for _ in range(w * h // 6):
        x = rng.randrange(w); y = rng.randrange(h)
        c = px[x, y]; k = rng.randint(-amt, amt)
        px[x, y] = tuple(max(0, min(255, v + k)) for v in c)
    return im


# ------------------------------------------------------------------ M1/M3: LED claws
CLAW_COLS = [("green", "#33e04a", "#c8ffc8"), ("pink", "#ff4fa8", "#ffd0ea"), ("blue", "#3557ff", "#cdd8ff"),
             ("red", "#ff2b3a", "#ffd0d0"), ("violet", "#a25bff", "#e8d6ff"), ("white", "#e8eef4", "#7fe6ff")]


def claw():
    """The LED claws (f041-f046, f055-f058, g002, IMG_4445): white cabinets, a lit pill marquee with a
    coloured rim, LED-studded front posts, a translucent lower body lit in the cabinet's colour with a
    big white rounded prize door (round chute) and a small card-reader window."""
    A = Atlas("claw", "#f2f2f4")
    for name, col, light in CLAW_COLS:
        r = A.slot("lower_" + name, 160, 220)
        im = Image.new("RGB", (170, 220)); d = ImageDraw.Draw(im)
        vgrad(im, light if name != "white" else "#f4f6f8", col if name != "white" else "#cfd6de")
        # the prize door: a big white rounded square with a round chute, low left
        d.rounded_rectangle([14, 78, 112, 200], radius=26, fill="#ffffff" if name != "white" else "#e4e8ee", outline="#00000030", width=2)
        d.ellipse([34, 104, 92, 162], fill=col if name != "white" else "#9aa6b2")
        d.ellipse([44, 114, 82, 152], fill="#1a1a1e")
        # the card reader, right
        tap_reader(d, 140, 120, 18, "#3cff6a")
        d.rectangle([124, 160, 156, 168], fill="#222")
        A.put(r, im)
    for name, col, light in CLAW_COLS:
        r = A.slot("pill_" + name, 160, 80)
        im = Image.new("RGB", (170, 80)); d = ImageDraw.Draw(im)
        d.rectangle([0, 0, 170, 80], fill="#f4f4f6")
        d.rounded_rectangle([4, 4, 166, 76], radius=36, fill=col if name != "white" else light)
        d.rounded_rectangle([16, 14, 154, 66], radius=26, fill="#fff7d8")
        # a generic round logo (no wordmark legible on these at the footage's distance)
        d.ellipse([60, 18, 110, 62], fill=col if name != "white" else "#1f9fd8")
        d.arc([30, 22, 140, 60], 200, 340, fill="#e4572e", width=5)
        A.put(r, im)
    for name, col, light in CLAW_COLS:
        r = A.slot("side_" + name, 160, 40)
        im = Image.new("RGB", (170, 40)); vgrad(im, light if name != "white" else "#f0f2f4", col if name != "white" else "#cfd6de"); A.put(r, im)
    r = A.slot("post", 64, 172)                     # a white post with LED studs (front edges)
    im = A.sub(r); d = ImageDraw.Draw(im); d.rectangle([0, 0, 64, 172], fill="#f4f4f6")
    A.put(r, im)
    r = A.slot("cab", 256, 172)                     # plain white laminate (sides, header, back)
    im = A.sub(r); im.paste("#eceef2", [0, 0, 256, 172]); panel_noise(im, 4); A.put(r, im)
    r = A.slot("pile", 512, 172)                    # the prize pile seen through the glass
    im = A.sub(r); vgrad(im, "#dfe6f0", "#b9c6d8"); prize_pile(im, 11); A.put(r, im)
    r = A.slot("deck", 192, 172)                    # the control ledge: black with a joystick plate
    im = A.sub(r); d = ImageDraw.Draw(im); d.rectangle([0, 0, 192, 172], fill="#18181c")
    d.ellipse([30, 50, 100, 120], fill="#30303a"); d.ellipse([120, 60, 170, 110], fill="#ff3030")
    A.put(r, im)
    A.save()


# ------------------------------------------------------------------ merchandisers (M2, M14-M16, M26, M3)
MERCH = [("white", "#f2f3f6", "#2a6be0", "SUPER STAR"), ("plain", "#f2f3f6", "#f2f3f6", ""),
         ("yellow", "#ffd02a", "#d6232e", ""), ("push", "#15161c", "#2a52ff", "PUSH"),
         ("purple", "#7a3bd0", "#ff4fb8", "")]


def merch():
    """White prize merchandisers (f052-f053, IMG_4445): a tall white cabinet, a lit window of boxed
    prizes on glass shelves, a lit header (one "SUPER STAR"-type blue marquee in the footage, the rest
    plain), a lower door with a card reader. Variants: the yellow one with the red ring door (f053),
    the black blue-grid "PUSH" one (f052), the purple one at the back (g004)."""
    A = Atlas("merch", "#f2f3f6")
    for name, body, acc, word in MERCH:
        r = A.slot("lower_" + name, 192, 220)
        im = Image.new("RGB", (200, 220)); d = ImageDraw.Draw(im)
        im.paste(body, [0, 0, 200, 220]); panel_noise(im, 4, 7)
        if name == "push":
            for x in range(0, 200, 16):
                d.line([x, 0, x, 220], fill="#2a52ff", width=2)
            for y in range(0, 220, 16):
                d.line([0, y, 200, y], fill="#2a52ff", width=2)
            fit_text(d, (40, 110, 160, 150), "PUSH", F_SAI, "#ffffff")
        if name == "yellow":
            d.ellipse([40, 90, 160, 210], outline="#d6232e", width=14)
        else:
            d.rounded_rectangle([50, 120, 150, 200], radius=8, outline=acc if name != "plain" else "#d84040", width=4)
            d.rectangle([84, 140, 116, 152], fill="#d84040")
        tap_reader(d, 160, 50, 16)
        d.rectangle([30, 36, 110, 60], fill="#1b1b1f")
        A.put(r, im)
    for name, body, acc, word in MERCH:
        r = A.slot("head_" + name, 192, 70)
        im = Image.new("RGB", (200, 70)); d = ImageDraw.Draw(im)
        if name == "white":
            vgrad(im, "#3f86ff", "#1a3fb0")
            d.rounded_rectangle([4, 6, 196, 64], radius=12, outline="#ffd02a", width=4)
            fit_text(d, (14, 10, 186, 60), "SUPER STAR", F_LIL, "#ffd02a", 2, "#7a2a00")
        elif name == "push":
            im.paste("#101016", [0, 0, 200, 70]); fit_text(d, (10, 8, 190, 62), "PUSH", F_SAI, "#4c7bff")
        elif name == "yellow":
            vgrad(im, "#ffe066", "#ffb21a")
        elif name == "purple":
            vgrad(im, "#ff6fd0", "#8a3bd8")
        else:
            vgrad(im, "#ffffff", "#dfe8f6")
        A.put(r, im)
    for name, body, acc, word in MERCH:
        r = A.slot("side_" + name, 192, 100)
        im = Image.new("RGB", (200, 100)); im.paste(body, [0, 0, 200, 100]); d = ImageDraw.Draw(im)
        if name == "push":
            for x in range(0, 200, 16):
                d.line([x, 0, x, 100], fill="#2a52ff", width=2)
            for y in range(0, 100, 16):
                d.line([0, y, 200, y], fill="#2a52ff", width=2)
        A.put(r, im)
    r = A.slot("window", 512, 122)
    im = A.sub(r); prize_shelves(im, 21); A.put(r, im)
    r = A.slot("window2", 512, 100)
    im = A.sub(r); prize_shelves(im, 22, 3); A.put(r, im)
    A.save()


# ------------------------------------------------------------------ M4/M6 two-player coin pushers
def pusher():
    """M4 (f012, f021-f024): a royal-blue two-player coin pusher with red LED edge strips, chrome
    trim, two lit playfield windows and a big topper (superhero art in the footage: here a generic
    burst translite in its colours). M6 (f029-f034): the same format in white/purple with a portrait
    side panel (here an abstract colour field)."""
    A = Atlas("pusher", "#1c2f9a")
    for s, (body, trim, tc) in enumerate([("#1f3aa8", "#c7ccd6", ["#d6282e", "#1f3aa8", "#f4c21a", "#6b2bb0"]),
                                           ("#f2f0f4", "#7a3bd0", ["#7a3bd0", "#ff4fa8", "#2fd6c8", "#1b1b3a"])]):
        r = A.slot("lower%d" % s, 512, 180)        # the two stations' lower fronts (1.95 x 0.85 m)
        im = A.sub(r); d = ImageDraw.Draw(im); im.paste(body, [0, 0, 512, 180]); panel_noise(im, 5, s)
        for k in range(2):
            x0 = 20 + k * 256
            d.rounded_rectangle([x0, 20, x0 + 216, 160], radius=10, outline=trim, width=4)
            d.rectangle([x0 + 70, 34, x0 + 146, 70], fill="#101014")          # the coin/prize tray
            tap_reader(d, x0 + 40, 52, 18)
            d.ellipse([x0 + 160, 34, x0 + 196, 70], fill="#ff2a2a", outline="#ffffff", width=3)
            d.rectangle([x0 + 60, 96, x0 + 156, 140], fill="#0e0e12")         # the ticket mouth
            d.rectangle([x0 + 80, 116, x0 + 136, 122], fill="#ff8a1a")
        A.put(r, im)
    for s, (bg, c1, c2) in enumerate([("#0d1a4a", "#f4c21a", "#ff3b3b"), ("#1b0d3a", "#2fd6c8", "#ff4fa8")]):
        r = A.slot("field%d" % s, 256, 170)        # a playfield window: the shelf heaped with coins
        im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, bg, "#3a3a4a")
        rng = random.Random(30 + s)
        d.rectangle([0, 60, 256, 80], fill=c2)
        for _ in range(260):
            x = rng.uniform(0, 256); y = rng.uniform(85, 170); rr = rng.uniform(5, 9)
            d.ellipse([x - rr, y - rr * 0.55, x + rr, y + rr * 0.55], fill=rng.choice(["#d8b24a", "#c79a32", "#e8c86a", "#b8bcc4"]), outline="#6b5420")
        for k in range(6):
            d.rectangle([20 + k * 40, 20, 40 + k * 40, 50], fill=c1)
        A.put(r, im)
    for s, cols in enumerate([["#d6282e", "#1f3aa8", "#f4c21a", "#ffffff"], ["#7a3bd0", "#ff4fa8", "#2fd6c8", "#f2f0f4"]]):
        r = A.slot("top%d" % s, 512, 160)          # the topper translite (generic: no characters)
        im = A.sub(r); burst(im, cols, seed=40 + s)
        d = ImageDraw.Draw(im); d.rounded_rectangle([2, 2, 509, 157], radius=18, outline="#ffffff", width=5)
        A.put(r, im)
    for s, (a, b2) in enumerate([("#1f3aa8", "#0d1a4a"), ("#c9b8f0", "#3a1b70")]):
        r = A.slot("side%d" % s, 256, 160)         # side panel (M6's portrait -> a colour field)
        im = A.sub(r); vgrad(im, a, b2); d = ImageDraw.Draw(im)
        if s == 1:
            for k in range(7):
                d.ellipse([60 + k * 8, 20 + k * 10, 200 - k * 8, 150 - k * 6], outline=["#ff4fa8", "#2fd6c8"][k % 2], width=3)
        A.put(r, im)
    A.save()


# ------------------------------------------------------------------ M5 dice tower
def dice():
    """M5 (f020, f024, f028-f031): the "MONOPOLY ROLL-N-GO"-type ticket tower: a red header, a 1000
    TICKETS jackpot window, the 10 value window, SWIPE CARD, a big lit die in an open bay low down,
    black side pillars with green readers, a cyan-lit base."""
    A = Atlas("dice", "#151519")
    r = A.slot("front", 256, 512)
    im = A.sub(r); d = ImageDraw.Draw(im)
    vgrad(im, "#ffcf2a", "#ff8a1a")
    d.rectangle([0, 0, 256, 60], fill="#d81f26"); fit_text(d, (10, 6, 246, 34), "MONOPOLY", F_ANT, "#ffffff")
    fit_text(d, (40, 34, 216, 56), "ROLL-N-GO", F_SAI, "#ffe08a")
    d.rectangle([20, 72, 236, 170], fill="#ffd84a", outline="#d81f26", width=6)
    fit_text(d, (30, 80, 226, 104), "BONUS", F_LIL, "#d81f26")
    d.rectangle([40, 108, 216, 150], fill="#1b1b1b"); fit_text(d, (44, 110, 212, 148), "1000", F_ANT, "#ff2a2a")
    fit_text(d, (30, 150, 226, 168), "TICKETS", F_SAI, "#1b1b1b")
    d.rectangle([20, 186, 236, 270], fill="#f4f4f0", outline="#1b1b1b", width=3)
    fit_text(d, (30, 194, 226, 264), "10", F_ANT, "#1b1b1b")
    d.rectangle([20, 284, 236, 312], fill="#d81f26"); fit_text(d, (24, 286, 232, 310), "SWIPE CARD", F_SAI, "#ffffff")
    d.rectangle([20, 322, 236, 492], fill="#0b0b10")             # the die's bay
    A.put(r, im)
    r = A.slot("side", 256, 512)
    im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, "#2a2a30", "#101014")
    d.rectangle([0, 0, 256, 60], fill="#d81f26"); d.rectangle([0, 470, 256, 512], fill="#0b0b10")
    A.put(r, im)
    r = A.slot("die", 256, 256)                   # the die's face: 3 pips, glossy
    im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, "#5d7bff", "#1d36c8")
    for (x, y) in [(64, 64), (128, 128), (192, 192)]:
        d.ellipse([x - 26, y - 26, x + 26, y + 26], fill="#0b0b28")
    d.ellipse([20, 14, 90, 40], fill="#c8d4ff")
    A.put(r, im)
    r = A.slot("pillar", 256, 256)                # black side pillar with a green reader
    im = A.sub(r); d = ImageDraw.Draw(im); im.paste("#121216", [0, 0, 256, 256])
    tap_reader(d, 128, 90, 40); d.rectangle([60, 180, 196, 196], fill="#2fd6c8")
    A.put(r, im)
    A.save()


# ------------------------------------------------------------------ M7 big gun cabinet, M8 racer, M9/M18/M29 uprights
def gunbig():
    """M7 (f031-f033, f035): a big two-player gun cabinet: dark jungle-green body with a red base,
    an arched screen surround edged with a green LED arch, "ARCADE" on the lower side (the dinosaur
    franchise art and topper become generic jungle shapes), two mounted guns."""
    A = Atlas("gunbig", "#1d2a20")
    r = A.slot("front", 512, 512)
    im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, "#2b3a2a", "#141a14")
    d.rounded_rectangle([60, 40, 452, 330], radius=60, fill="#0c0f0c", outline="#3cff6a", width=10)
    d.rectangle([0, 430, 512, 512], fill="#b8161c")
    fit_text(d, (120, 350, 392, 420), "ARCADE", F_ANT, "#e9e2cf", 3, "#5a1010")
    rng = random.Random(7)
    for _ in range(26):
        x = rng.uniform(0, 512); y = rng.uniform(330, 430)
        d.polygon([(x, y), (x + rng.uniform(10, 30), y - rng.uniform(20, 60)), (x + rng.uniform(20, 50), y)], fill=rng.choice(["#3f6b2a", "#2a4d1f", "#5a7f30"]))
    A.put(r, im)
    r = A.slot("side", 256, 512)
    im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, "#2f4a2a", "#101410")
    for k in range(9):
        d.polygon([(0, 300 + k * 20), (256, 200 + k * 30), (256, 220 + k * 30), (0, 320 + k * 20)], fill=["#3f6b2a", "#5a7f30", "#2a4d1f"][k % 3])
    d.rectangle([0, 450, 256, 512], fill="#b8161c")
    fit_text(d, (20, 380, 236, 440), "ARCADE", F_ANT, "#e9e2cf", 2, "#5a1010")
    A.put(r, im)
    r = A.slot("screen", 256, 256)
    im = A.sub(r); vgrad(im, "#2a6b3a", "#0b1a0f"); d = ImageDraw.Draw(im)
    for k in range(12):
        d.line([0, 180 + k * 3, 256, 150 + k * 6], fill="#5a8f3a", width=2)
    d.ellipse([150, 40, 210, 100], fill="#f4e7a0")
    A.put(r, im)
    r = A.slot("top", 256, 256)
    im = A.sub(r); burst(im, ["#3f6b2a", "#b8161c", "#e0a62c", "#1d2a20"], seed=8); A.put(r, im)
    A.save()


def racer():
    """M8 (f035, f037): a twin sit-down racer: red bucket seats on yellow/black bases, two screens in
    a dark hood with a lit marquee; M30 (g005-g006): two sit-on motorbikes, yellow and black with
    chrome engine covers, screens on the wall side."""
    A = Atlas("racer", "#161618")
    r = A.slot("hood", 512, 256)
    im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, "#2a2a30", "#0e0e12")
    for k in range(2):
        d.rectangle([24 + k * 244, 40, 244 + k * 244, 200], fill="#0a1b3a", outline="#c8c8d0", width=4)
        for j in range(10):
            d.line([24 + k * 244, 160 + j * 4, 244 + k * 244, 120 + j * 8], fill="#9aa4b8")
    A.put(r, im)
    r = A.slot("marq", 512, 96)
    im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, "#ff3a2a", "#ffb21a")
    for k in range(10):
        d.line([k * 56, 96, k * 56 + 60, 0], fill="#ffd84a", width=8)
    A.put(r, im)
    r = A.slot("base", 256, 160)
    im = A.sub(r); d = ImageDraw.Draw(im); im.paste("#ffcf1a", [0, 0, 256, 160])
    d.rectangle([0, 110, 256, 160], fill="#151515")
    for k in range(8):
        d.polygon([(k * 40, 0), (k * 40 + 20, 0), (k * 40 - 20, 110), (k * 40 - 40, 110)], fill="#f0a812")
    A.put(r, im)
    r = A.slot("seat", 256, 160)
    im = A.sub(r); vgrad(im, "#e8262e", "#8a0c12"); A.put(r, im)
    r = A.slot("bike", 512, 160)
    im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, "#ffd21a", "#e09a0a")
    d.rectangle([0, 100, 512, 160], fill="#151515")
    for k in range(6):
        d.ellipse([20 + k * 84, 40, 80 + k * 84, 100], fill="#c8ccd2", outline="#6a6e76", width=4)
    A.put(r, im)
    A.save()


UPR = [("nerf", "#d8202a", "#1d3aa8", "NERF"), ("mascot", "#151518", "#c8161c", ""),
       ("music", "#18181c", "#d8202a", ""), ("crossy", "#b9d532", "#151515", "CROSSY ROAD")]


def upright():
    """Uprights: M9 the red "NERF" gun cabinet (f036-f038), M18 the tall black cabinet with a cartoon
    mascot cut-out (f036-f037; the mascot becomes a plain black panel with a red edge), M29 the music
    cabinet with a plush on top (g005-g006), M17 "CROSSY ROAD" (f042-f044: lime/black, a tall screen
    framed in RGB LED studs, a wide control deck; the blocky chicken art becomes plain blocks)."""
    A = Atlas("upright", "#151518")
    for name, body, acc, word in UPR:
        r = A.slot("front_" + name, 128, 256)
        im = A.sub(r); d = ImageDraw.Draw(im); im.paste(body, [0, 0, 128, 256]); panel_noise(im, 4)
        if name == "crossy":
            for k in range(6):
                d.rectangle([10 + k * 18, 150 + (k % 2) * 20, 26 + k * 18, 170 + (k % 2) * 20], fill=["#ffffff", "#2a8a3a", "#ff7a1a"][k % 3])
            fit_text(d, (10, 60, 118, 120), "CROSSY\nROAD", F_ANT, "#151515")
        else:
            d.rectangle([20, 150, 108, 200], fill="#0e0e12")
            tap_reader(d, 64, 110, 16)
            if word:
                fit_text(d, (10, 210, 118, 250), word, F_ANT, "#ffffff", 2, acc)
        A.put(r, im)
    for name, body, acc, word in UPR:
        r = A.slot("side_" + name, 128, 256)
        im = A.sub(r); d = ImageDraw.Draw(im); im.paste(body, [0, 0, 128, 256])
        d.rectangle([0, 0, 6, 256], fill=acc); d.rectangle([122, 0, 128, 256], fill=acc)
        if name == "crossy":
            rng = random.Random(9)
            for _ in range(30):
                x = rng.randrange(0, 120, 12); y = rng.randrange(120, 250, 12)
                d.rectangle([x, y, x + 12, y + 12], fill=rng.choice(["#2a8a3a", "#7ac43a", "#f4f4f0", "#ff7a1a", "#151515"]))
            fit_text(d, (8, 20, 120, 100), "CROSSY\nROAD", F_ANT, "#151515")
        if name == "nerf":
            for k in range(6):
                d.line([0, 40 + k * 30, 128, 10 + k * 30], fill="#ff8a1a", width=6)
        A.put(r, im)
    for name, body, acc, word in UPR:
        r = A.slot("marq_" + name, 128, 64)
        im = A.sub(r); d = ImageDraw.Draw(im)
        if name == "crossy":
            im.paste("#b9d532", [0, 0, 128, 64]); fit_text(d, (6, 4, 122, 60), "CROSSY ROAD", F_ANT, "#151515")
        elif name == "nerf":
            vgrad(im, "#2a5bff", "#0d1a6a"); fit_text(d, (6, 4, 122, 60), "NERF", F_ANT, "#ff8a1a", 2, "#ffffff")
        elif name == "music":
            vgrad(im, "#ff3a2a", "#3a0a0a")
            for k in range(5):
                d.line([10 + k * 24, 50, 30 + k * 24, 10], fill="#ffd84a", width=4)
        else:
            vgrad(im, "#c8161c", "#3a0608")
        A.put(r, im)
    for name, body, acc, word in UPR:
        r = A.slot("screen_" + name, 128, 128)
        im = A.sub(r); d = ImageDraw.Draw(im)
        if name == "crossy":
            # a top-down road-crossing game on the screen: green verges, grey roads, blocks
            for k in range(8):
                d.rectangle([0, k * 16, 128, k * 16 + 16], fill=["#7ac43a", "#5a5a64", "#5a5a64", "#7ac43a", "#3a8ad8", "#7ac43a", "#5a5a64", "#7ac43a"][k])
            rng = random.Random(4)
            for _ in range(14):
                x = rng.randrange(0, 120); y = rng.randrange(0, 8) * 16 + 3
                d.rectangle([x, y, x + 16, y + 10], fill=rng.choice(["#ff3a2a", "#ffd21a", "#ffffff", "#2a8a3a"]))
        else:
            vgrad(im, ["#ff3a2a", "#2a2a3a", "#3a0a5a"][UPR.index((name, body, acc, word)) % 3], "#0a0a12")
            for k in range(6):
                d.line([0, 60 + k * 10, 128, 30 + k * 16], fill="#ffd84a")
        A.put(r, im)
    r = A.slot("deck_crossy", 256, 128)
    im = A.sub(r); d = ImageDraw.Draw(im); im.paste("#151515", [0, 0, 256, 128])
    d.rectangle([0, 0, 256, 20], fill="#b9d532")
    for k, c in enumerate(["#ff2a2a", "#2a6bff"]):
        d.ellipse([60 + k * 110, 50, 100 + k * 110, 90], fill=c, outline="#ffffff", width=3)
    d.rectangle([112, 44, 144, 96], fill="#f4f4f0")
    fit_text(d, (100, 100, 156, 124), "VS", F_ANT, "#b9d532")
    A.put(r, im)
    A.save()


# ------------------------------------------------------------------ M10 deal, M11 hoop
def deal():
    """M10 (f036-f039): "DEAL OR NO DEAL": a tall black cabinet with a yellow-on-black DEAL marquee,
    a screen of case values, a sloped keypad console of lit case buttons, a yellow-lit hexagonal
    floor platform and a chrome stool."""
    A = Atlas("deal", "#151518")
    r = A.slot("marq", 512, 128)
    im = A.sub(r); d = ImageDraw.Draw(im); im.paste("#0c0c0e", [0, 0, 512, 128])
    d.rounded_rectangle([8, 10, 504, 118], radius=14, fill="#ffd21a")
    fit_text(d, (20, 16, 492, 112), "DEAL OR NO DEAL", F_ANT, "#111111")
    A.put(r, im)
    r = A.slot("screen", 256, 256)
    im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, "#1a2a6a", "#0a0f2a")
    for k in range(8):
        y = 20 + k * 28
        d.rectangle([20, y, 118, y + 20], fill="#ffd21a"); d.rectangle([138, y, 236, y + 20], fill="#ffd21a")
    A.put(r, im)
    r = A.slot("keypad", 256, 256)
    im = A.sub(r); d = ImageDraw.Draw(im); im.paste("#18181c", [0, 0, 256, 256])
    for j in range(4):
        for i in range(6):
            x = 20 + i * 38; y = 30 + j * 44
            d.rounded_rectangle([x, y, x + 30, y + 30], radius=6, fill="#f4f0e0", outline="#ffd21a", width=3)
    d.ellipse([100, 210, 156, 250], fill="#ff2a2a", outline="#ffffff", width=3)
    A.put(r, im)
    r = A.slot("hex", 256, 256)                    # the platform top: lit yellow panels in a grid
    im = A.sub(r); d = ImageDraw.Draw(im); im.paste("#ffb800", [0, 0, 256, 256])
    for k in range(1, 4):
        d.line([k * 64, 0, k * 64, 256], fill="#c46a00", width=6); d.line([0, k * 64, 256, k * 64], fill="#c46a00", width=6)
    A.put(r, im)
    r = A.slot("body", 256, 256)
    im = A.sub(r); d = ImageDraw.Draw(im); im.paste("#151518", [0, 0, 256, 256]); panel_noise(im, 4)
    tap_reader(d, 128, 70, 30); d.rectangle([60, 140, 196, 170], fill="#0b0b0e")
    A.put(r, im)
    A.save()


def hoop():
    """M11 (f038-f039): "BASKETBALL PRO" single-player hoop cabinet: a lit backboard marquee, a
    caged net box with a sloped ramp, blue/red side art, red LED score, a ball well."""
    A = Atlas("hoop", "#1d3aa8")
    r = A.slot("marq", 256, 256)
    im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, "#2a7bff", "#0d2a8a")
    fit_text(d, (10, 20, 246, 120), "BASKETBALL", F_ANT, "#ffd21a", 3, "#a8161c")
    fit_text(d, (40, 120, 216, 220), "PRO", F_ANT, "#ffffff", 3, "#a8161c")
    A.put(r, im)
    r = A.slot("side", 512, 256)
    im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, "#2a5bff", "#0b1a6a")
    d.polygon([(0, 256), (512, 120), (512, 256)], fill="#d8202a")
    d.ellipse([360, 30, 470, 140], fill="#f08a1a", outline="#3a1a00", width=4)
    fit_text(d, (20, 150, 300, 230), "BASKETBALL PRO", F_ANT, "#ffffff", 2, "#0b1a6a")
    A.put(r, im)
    r = A.slot("board", 256, 256)
    im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, "#f4f6fa", "#cfd8e8")
    d.rectangle([80, 120, 176, 200], outline="#d8202a", width=8)
    d.rectangle([60, 20, 196, 70], fill="#111"); fit_text(d, (66, 24, 190, 66), "126", F_ANT, "#ff2a2a")
    A.put(r, im)
    r = A.slot("ramp", 256, 256)
    im = A.sub(r); d = ImageDraw.Draw(im); im.paste("#2a2a30", [0, 0, 256, 256])
    for k in range(0, 256, 16):
        d.line([0, k, 256, k], fill="#3a3a44", width=2)
    A.put(r, im)
    A.save()


# ------------------------------------------------------------------ M12/M13 prize towers
def ptower():
    """M13 "DIZZY CHICKEN" (f052): a round acrylic prize tower with a red chicken-head topper, a lit
    blue spiral of prizes, an orange/yellow cartoon-print base; M12 (f039, f052): a similar tower
    with a yellow base and an orange "…ER" topper (name not legible)."""
    A = Atlas("ptower", "#ffb21a")
    for s, (top, base, word) in enumerate([("#e8282a", "#ffcf1a", "DIZZY CHICKEN"), ("#ff8a1a", "#ffe24a", "")]):
        r = A.slot("base%d" % s, 256, 256)
        im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, base, "#f08a1a")
        d.rectangle([0, 0, 256, 70], fill=top)
        if word:
            fit_text(d, (10, 6, 246, 64), word, F_LIL, "#ffffff", 3, "#5a0a0a")
        tap_reader(d, 128, 130, 22)
        d.rectangle([70, 190, 186, 230], fill="#2a1a0a")
        rng = random.Random(s)
        for _ in range(20):
            x = rng.uniform(0, 256); y = rng.uniform(80, 250)
            d.line([x, y, x + rng.uniform(-30, 30), y + rng.uniform(-20, 20)], fill="#c8401a", width=4)
        A.put(r, im)
    for s in range(2):
        r = A.slot("inner%d" % s, 256, 256)        # what shows through the acrylic: a lit spiral of prizes
        im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, "#2a1a5a", "#0d0a2a")
        for k in range(6):
            y = 30 + k * 38
            d.ellipse([20, y, 236, y + 26], outline="#3a7bff", width=5)
        prize_pile(im.crop((0, 0, 256, 256)), 50 + s)
        A.put(r, im)
    r = A.slot("head", 256, 256)                   # the chicken topper's face: generic cartoon bird
    im = A.sub(r); d = ImageDraw.Draw(im); im.paste("#e8282a", [0, 0, 256, 256])
    for x in (80, 150):
        d.ellipse([x - 30, 50, x + 30, 120], fill="#ffffff", outline="#111", width=4); d.ellipse([x - 8, 76, x + 12, 100], fill="#111")
    d.polygon([(110, 130), (170, 150), (110, 175)], fill="#ffcf1a", outline="#8a5a00")
    A.put(r, im)
    r = A.slot("cap", 256, 256)
    im = A.sub(r); vgrad(im, "#ffcf1a", "#e8282a"); A.put(r, im)
    A.save()


# ------------------------------------------------------------------ M19/M20 drop domes, M22 arch
def dome():
    """M19/M20 (f040-f058): the drop-dome ticket game: an octagonal cabinet (hot pink, or blue) with
    grey side panels and a swirl logo, a yellow rim ring round a lit playfield of neon rings and
    chutes under a clear dome, a red LED "100" bonus readout on a post, an instructions panel, a big
    yellow push button and a green-ringed TAP reader."""
    A = Atlas("dome", "#ff2f9a")
    for s, (body, logo) in enumerate([("#ff2f9a", "#3fd0ff"), ("#2a5bff", "#ff4fa8")]):
        r = A.slot("front%d" % s, 256, 256)
        im = A.sub(r); d = ImageDraw.Draw(im); im.paste(body, [0, 0, 256, 256]); panel_noise(im, 5, s)
        d.rectangle([0, 0, 256, 60], fill="#ffd84a")
        d.rectangle([12, 10, 118, 50], fill="#f4f0ff", outline="#5a3ad0", width=3)
        d.ellipse([132, 12, 172, 52], fill="#ffd21a", outline="#8a5a00", width=3)
        d.rectangle([186, 14, 246, 46], fill="#111"); fit_text(d, (190, 16, 242, 44), "100", F_ANT, "#ff2a2a")
        tap_reader(d, 70, 150, 34)
        d.arc([120, 110, 240, 200], 200, 340, fill=logo, width=10)
        fit_text(d, (120, 120, 240, 190), "TICKETS", F_SAI, "#ffffff")
        A.put(r, im)
    for s, body in enumerate(["#c8c8d2", "#c8c8d2"]):
        r = A.slot("side%d" % s, 256, 256)
        im = A.sub(r); d = ImageDraw.Draw(im); im.paste(body, [0, 0, 256, 256])
        d.arc([40, 80, 216, 220], 180, 360, fill=["#ff4fa8", "#2a5bff"][s], width=18)
        d.arc([60, 100, 196, 240], 180, 360, fill="#ffd21a", width=12)
        A.put(r, im)
    r = A.slot("field", 512, 512 - 256)            # the playfield under the dome, seen from above
    im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, "#2a1a4a", "#120a24")
    cx, cy = 256, 128
    for k, c in enumerate(["#ffd21a", "#ff8a1a", "#ffd21a"]):
        rr = 120 - k * 14
        d.ellipse([cx - rr * 2, cy - rr, cx + rr * 2, cy + rr], outline=c, width=10)
    for k in range(24):
        a = TAU * k / 24
        d.rectangle([cx + 210 * math.cos(a) - 6, cy + 105 * math.sin(a) - 4, cx + 210 * math.cos(a) + 6, cy + 105 * math.sin(a) + 4], fill="#ff2a2a")
    for k, c in enumerate(["#3cff6a", "#ff4fa8", "#3fd0ff", "#ff3a2a"]):
        a = TAU * k / 4 + 0.4
        x = cx + 120 * math.cos(a); y = cy + 60 * math.sin(a)
        d.arc([x - 40, y - 30, x + 40, y + 30], 0, 300, fill=c, width=8)
    A.put(r, im)
    r = A.slot("arch", 512, 128)                   # M22's green "...TICKETS" column face
    im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, "#3cff6a", "#1a8a2a")
    fit_text(d, (20, 10, 492, 118), "TICKETS", F_ANT, "#ffffff", 3, "#0a4a14")
    A.put(r, im)
    r = A.slot("archbase", 512, 128)
    im = A.sub(r); d = ImageDraw.Draw(im); im.paste("#c8201a", [0, 0, 512, 128])
    for k in range(8):
        d.ellipse([20 + k * 62, 30, 70 + k * 62, 80], fill="#ffd21a")
    tap_reader(d, 450, 64, 28)
    A.put(r, im)
    A.save()


# ------------------------------------------------------------------ M21 wheel
def wheel():
    """M21 (f046-f051, IMG_4445): a tall wheel ticket game: a big multicolour value wheel (40/30/20 ...)
    in a blue rim with a pointer, on a royal-blue cabinet with "...QUEST" on the base (only the end of
    the name is legible: shown as QUEST)."""
    A = Atlas("wheel", "#1d3aa8")
    r = A.slot("wheel", 512, 512)
    im = A.sub(r); d = ImageDraw.Draw(im); im.paste("#1d3aa8", [0, 0, 512, 512])
    cx = cy = 256
    vals = ["40", "8", "20", "5", "30", "10", "200", "3", "50", "8", "20", "5", "25", "10", "100", "3"]
    cols = ["#ff4fa8", "#ffd21a", "#3fd0ff", "#ff8a1a", "#a25bff", "#3cff6a", "#ff2a2a", "#ffffff"]
    for k, v in enumerate(vals):
        a0 = 360 * k / len(vals); a1 = 360 * (k + 1) / len(vals)
        d.pieslice([16, 16, 496, 496], a0 - 90, a1 - 90, fill=cols[k % len(cols)], outline="#1b1b1b", width=3)
        am = math.radians((a0 + a1) / 2 - 90)
        f = font(F_ANT, 34)
        d.text((cx + 175 * math.cos(am), cy + 175 * math.sin(am)), v, font=f, fill="#111", anchor="mm")
    d.ellipse([196, 196, 316, 316], fill="#ffd21a", outline="#8a5a00", width=6)
    d.ellipse([8, 8, 504, 504], outline="#c8ccd2", width=12)
    A.put(r, im)
    r = A.slot("base", 256, 256)
    im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, "#2a5bff", "#0d1a6a")
    fit_text(d, (14, 100, 242, 170), "QUEST", F_LIL, "#ffd21a", 3, "#8a2a00")
    tap_reader(d, 128, 210, 26)
    A.put(r, im)
    r = A.slot("side", 256, 256)
    im = A.sub(r); vgrad(im, "#1d3aa8", "#0b1440"); A.put(r, im)
    A.save()


# ------------------------------------------------------------------ M23/M24 air hockey
def hockey():
    """M23 (g001-g003, IMG_4445): red/orange air hockey with black rails, flame-print aprons and a
    curved orange overhead score arch; M24: the blue table with a yellow rail (g001-g003)."""
    A = Atlas("hockey", "#d8401a")
    for s, (apron, accent, field) in enumerate([("#d8401a", "#ffb21a", "#1c1c28"), ("#2a5bff", "#ffd21a", "#2a3a8a")]):
        r = A.slot("apron%d" % s, 512, 128)
        im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, apron, "#3a0a0a" if s == 0 else "#0b1a6a")
        rng = random.Random(70 + s)
        for _ in range(16):
            x = rng.uniform(0, 512)
            d.arc([x - 40, 20, x + 40, 160], 180, 300, fill=accent, width=4)
        d.rectangle([220, 30, 292, 100], fill="#f08a1a" if s == 0 else "#ffd21a")
        tap_reader(d, 120, 64, 24)
        A.put(r, im)
        r = A.slot("field%d" % s, 256, 512 - 128 - 0 if False else 256)
        im = A.sub(r); d = ImageDraw.Draw(im); im.paste(field, [0, 0, 256, 256])
        for y in range(0, 256, 8):
            for x in range(4, 256, 8):
                d.point((x, y), fill="#5a5a6a")
        d.line([0, 128, 256, 128], fill="#ff2a2a" if s == 0 else "#ffffff", width=4)
        d.ellipse([88, 88, 168, 168], outline="#ff2a2a" if s == 0 else "#ffffff", width=4)
        d.rectangle([96, 0, 160, 10], fill="#111"); d.rectangle([96, 246, 160, 256], fill="#111")
        A.put(r, im)
    r = A.slot("score", 256, 128)
    im = A.sub(r); d = ImageDraw.Draw(im); im.paste("#f08a1a", [0, 0, 256, 128])
    d.rectangle([60, 30, 196, 98], fill="#111"); fit_text(d, (70, 34, 186, 94), "0   0", F_ANT, "#ff2a2a")
    A.put(r, im)
    A.save()


# ------------------------------------------------------------------ M25 alleys, M27/M28 drop columns
def alley():
    """M25 (g004): two blue alley-roller lanes with orange front panels, red LED scores over the
    targets and green-lit gutters (name not legible); M27 (g005): a big-eyed drop column with 15 / 40 /
    25 value windows; M28 (g005-g006): "QUIK DROP" with its round red marquee."""
    A = Atlas("alley", "#1d3aa8")
    r = A.slot("eyes", 256, 512)                   # M27's tall face
    im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, "#3fb0ff", "#1d3aa8")
    for x in (80, 176):
        d.ellipse([x - 44, 30, x + 44, 130], fill="#ffffff", outline="#111", width=5); d.ellipse([x - 14, 70, x + 18, 110], fill="#111")
    for k, v in enumerate(["15", "40", "25"]):
        y = 170 + k * 90
        d.rectangle([30, y, 226, y + 76], fill=["#b9ff3a", "#ffd21a", "#b9ff3a"][k], outline="#5a3ad0", width=6)
        fit_text(d, (40, y + 4, 216, y + 72), v, F_ANT, "#5a3ad0")
    A.put(r, im)
    r = A.slot("quik", 256, 512)                   # M28's face
    im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, "#3fd0ff", "#1d3aa8")
    d.ellipse([28, 10, 228, 210], fill="#ffffff", outline="#ff2a3a", width=18)
    fit_text(d, (60, 50, 196, 170), "QUIK\nDROP", F_LIL, "#ff2a3a")
    d.rectangle([30, 240, 226, 470], fill="#0d1a4a", outline="#ffffff", width=4)
    for k in range(5):
        d.rectangle([50 + k * 34, 260, 74 + k * 34, 450], fill=["#ff2a3a", "#ffd21a", "#3cff6a", "#ff4fa8", "#3fd0ff"][k])
    A.put(r, im)
    r = A.slot("front", 256, 256)
    im = A.sub(r); d = ImageDraw.Draw(im); im.paste("#1d3aa8", [0, 0, 256, 256])
    d.rectangle([20, 60, 236, 220], fill="#f08a1a", outline="#ffd21a", width=6)
    tap_reader(d, 128, 120, 30); d.rectangle([80, 180, 176, 200], fill="#111")
    A.put(r, im)
    r = A.slot("lane", 256, 256)
    im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, "#d8b07a", "#b88a4a")
    for k in range(0, 256, 20):
        d.line([k, 0, k, 256], fill="#a87a3a")
    A.put(r, im)
    r = A.slot("target", 256, 256)
    im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, "#2a7bff", "#0d2a8a")
    for k, v in enumerate(["10", "20", "30", "50"]):
        d.ellipse([128 - 100 + k * 22, 60 + k * 18, 128 + 100 - k * 22, 220 - k * 18], outline="#ffd21a", width=6)
    d.rectangle([40, 8, 216, 50], fill="#111"); fit_text(d, (50, 10, 206, 48), "88", F_ANT, "#ff2a2a")
    A.put(r, im)
    A.save()


# ------------------------------------------------------------------ the prize counter
def counter():
    """The GALACTIC PRIZE PORTAL counter (f017-f028): LED-edged glass showcases of small prizes, the
    black counter, black slatwall prize shelving with green tags under a row of plush, the neon-on-
    starfield GALACTIC PRIZE PORTAL panel, two wall TVs, two blue-screen card kiosks."""
    A = Atlas("counter", "#151518")
    r = A.slot("prizes", 512, 256)                # the prize wall's shelves (repeats along the wall)
    im = A.sub(r); d = ImageDraw.Draw(im); im.paste("#18181c", [0, 0, 512, 256])
    rng = random.Random(90)
    for k in range(5):
        y = 40 + k * 46
        d.rectangle([0, y, 512, y + 4], fill="#2a2a30")
        x = 4
        while x < 500:
            bw = rng.uniform(14, 40); bh = rng.uniform(18, 38)
            d.rectangle([x, y - bh, x + bw, y], fill=rng.choice(["#e8423a", "#2c7be5", "#f5b82e", "#25b45a", "#8d4fd8", "#ff6fae", "#f2f2f2", "#3fd0ff", "#ff8a1a"]))
            if rng.random() < 0.4:
                d.rectangle([x + 2, y + 6, x + 14, y + 14], fill="#7cff3a")
            x += bw + rng.uniform(2, 6)
    A.put(r, im)
    r = A.slot("case", 256, 128)                  # a showcase's glass front: small prizes inside
    im = A.sub(r); prize_shelves(im, 91, 2); A.put(r, im)
    r = A.slot("sign", 256, 128)                  # GALACTIC PRIZE PORTAL
    im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, "#0a1a3a", "#06081a")
    rng = random.Random(92)
    for _ in range(60):
        x = rng.uniform(0, 256); y = rng.uniform(0, 128); d.point((x, y), fill="#ffffff")
    fit_text(d, (10, 6, 246, 64), "GALACTIC", F_RUS, "#5cff8a", 2, "#0a6a3a")
    fit_text(d, (10, 64, 246, 122), "PRIZE PORTAL", F_RUS, "#5cff8a", 2, "#0a6a3a")
    A.put(r, im)
    r = A.slot("tv", 256, 128)
    im = A.sub(r); d = ImageDraw.Draw(im); im.paste("#08080c", [0, 0, 256, 128])
    fit_text(d, (10, 6, 246, 30), "TOP 5 PLAYERS BY TICKETS", F_SAI, "#ffd21a")
    for k in range(5):
        d.rectangle([20, 40 + k * 16, 20 + random.Random(k).randint(80, 220), 48 + k * 16], fill="#e8e8f0")
    A.put(r, im)
    r = A.slot("kiosk", 128, 128)
    im = A.sub(r); vgrad(im, "#3a8aff", "#0d2a8a"); d = ImageDraw.Draw(im)
    d.rectangle([20, 40, 108, 60], fill="#ffffff"); d.rectangle([20, 70, 108, 90], fill="#ffffff")
    A.put(r, im)
    r = A.slot("black", 128, 128)
    im = A.sub(r); im.paste("#121216", [0, 0, 128, 128]); panel_noise(im, 5); A.put(r, im)
    r = A.slot("plush_row", 512, 128)             # the top shelf's plush row, painted (generic)
    im = A.sub(r); im.paste("#e8732a", [0, 0, 512, 128]); prize_pile(im, 93, ["#f6d23a", "#5db5e8", "#79c66a", "#ff8fc8", "#8e6bd1", "#f3f1e8", "#f08a2a", "#3cc7b0"])
    A.put(r, im)
    A.save()


# ------------------------------------------------------------------ room parts (the store's own)
def room():
    """Room pieces painted from the frames: the CLAW MANIA mural (f021-f023: navy, a synthwave grid
    horizon, claws, UFOs and aliens as plain shapes), the front's inside header (IMG_4445), the A-frame
    posters (f012-f017), the 2x2 nine-cell parabolic troffer (f019-f028), the tan slatwall (f038, g004)."""
    A = Atlas("room", "#18204a")
    r = A.slot("mural", 512, 256)
    im = Image.new("RGB", (512, 288)); d = ImageDraw.Draw(im); vgrad(im, "#141a44", "#2a1a5a", (0, 0, 512, 170)); vgrad(im, "#2a1a5a", "#0b0d24", (0, 170, 512, 288))
    d.line([0, 170, 512, 170], fill="#2fe8ff", width=4)
    for k in range(-10, 11):
        d.line([256 + k * 18, 172, 256 + k * 70, 288], fill="#2fb8ff", width=1)
    for k in range(6):
        y = 172 + (k * k + 2) * 3.2
        d.line([0, y, 512, y], fill="#2fb8ff", width=1)
    fit_text(d, (90, 20, 422, 74), "games, inc.", F_LIL, "#9fd8ff", 2, "#1b2a6a")
    fit_text(d, (130, 74, 382, 112), "CLAW MANIA", F_SAI, "#4aa8ff")
    rng = random.Random(100)
    for _ in range(12):
        x = rng.uniform(20, 492); y = rng.uniform(120, 270)
        kind = rng.randrange(3)
        if kind == 0:     # a claw
            d.line([x, y - 18, x, y], fill="#c8ccd2", width=2); d.arc([x - 10, y - 4, x + 10, y + 14], 200, 340, fill="#c8ccd2", width=3)
        elif kind == 1:   # a UFO
            d.ellipse([x - 14, y - 4, x + 14, y + 6], fill="#9aa4b8"); d.ellipse([x - 6, y - 10, x + 6, y], fill="#7cff8a")
        else:             # an alien head
            d.ellipse([x - 7, y - 9, x + 7, y + 9], fill="#7cff3a"); d.ellipse([x - 5, y - 3, x - 1, y + 2], fill="#111"); d.ellipse([x + 1, y - 3, x + 5, y + 2], fill="#111")
    A.put(r, im)
    r = A.slot("header", 512, 96)
    im = A.sub(r); d = ImageDraw.Draw(im); vgrad(im, "#141a44", "#0b0d24")
    fit_text(d, (20, 8, 492, 88), "CLAW MANIA", F_SAI, "#4cd88a")
    A.put(r, im)
    for s in range(2):
        r = A.slot("aframe%d" % s, 128, 288)
        im = A.sub(r); d = ImageDraw.Draw(im); im.paste("#0b0b10", [0, 0, 128, 288])
        fit_text(d, (8, 8, 120, 40), ["LEVEL UP", "games, inc."][s], F_SAI, "#4cd8ff")
        rng = random.Random(110 + s)
        for k in range(10):
            y = 50 + k * 22
            d.rectangle([12, y, 12 + rng.randint(40, 100), y + 10], fill=rng.choice(["#4cd8ff", "#7cff3a", "#ff4fa8", "#ffd21a", "#e8e8f0"]))
        d.rounded_rectangle([4, 4, 124, 284], radius=6, outline="#7cff3a", width=3)
        A.put(r, im)
    r = A.slot("troffer", 256, 256)
    im = A.sub(r); d = ImageDraw.Draw(im); im.paste("#d8dce4", [0, 0, 256, 256])
    for i in range(3):
        for j in range(3):
            x0 = 14 + i * 78; y0 = 14 + j * 78
            for k in range(10):
                c = 255 - k * 9
                d.rectangle([x0 + k * 3, y0 + k * 3, x0 + 72 - k * 3, y0 + 72 - k * 3], outline=(c, c, min(255, c + 6)))
            d.rectangle([x0 + 30, y0 + 30, x0 + 42, y0 + 42], fill="#ffffff")
    d.rectangle([0, 0, 255, 255], outline="#b8bcc4", width=6)
    A.put(r, im)
    r = A.slot("slat_tan", 256, 256)
    im = A.sub(r); d = ImageDraw.Draw(im); im.paste("#d6c6a6", [0, 0, 256, 256])
    for k in range(8):
        y = int(k * 32 + 16)
        d.rectangle([0, y - 4, 256, y + 4], fill="#a8977a"); d.line([0, y + 4, 256, y + 4], fill="#e8dcc4")
    A.put(r, im)
    r = A.slot("diffuser", 128, 128)
    im = A.sub(r); d = ImageDraw.Draw(im); im.paste("#eceef2", [0, 0, 128, 128])
    for k in range(5):
        d.rectangle([8 + k * 11, 8 + k * 11, 120 - k * 11, 120 - k * 11], outline="#9aa0aa", width=3)
    A.put(r, im)
    r = A.slot("grille", 128, 128)
    im = A.sub(r); d = ImageDraw.Draw(im); im.paste("#e4e6ea", [0, 0, 128, 128])
    for k in range(4, 124, 8):
        d.line([4, k, 124, k], fill="#7a7e88", width=3)
    A.put(r, im)
    A.save()


if __name__ == "__main__":
    claw(); merch(); pusher(); dice(); gunbig(); racer(); upright(); deal(); hoop(); ptower(); dome(); wheel()
    hockey(); alley(); counter(); room()
    with open(os.path.join(HERE, "atlas.json"), "w") as fh:
        json.dump(REG, fh, indent=1, sort_keys=True)
    print("atlas.json", len(REG), "atlases")
