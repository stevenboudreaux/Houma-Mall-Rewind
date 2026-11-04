"""Textures for Great American Cookies' case and 2026 store (tools/stores/gac/case.gd), written to
tex/gac/. Cookies, cookie cakes, the dipping cabinet's cones, the slush machine panels and the
menu screens are invented generic pictures (IP rule); the wave wall is the panel's relief.

  python3 tools/stores/gac/paint.py   (from the project folder)
"""
import importlib.util, math, os, random
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "..", "tex", "gac")
os.makedirs(OUT, exist_ok=True)
spec = importlib.util.spec_from_file_location("f26paint", os.path.join(HERE, "..", "fronts26", "paint.py"))
F = importlib.util.module_from_spec(spec)
spec.loader.exec_module(F)
F.OUT = OUT          # the shared painters write here
F.R.seed(1977)
BOLD = "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf"
R = random.Random(1977)


def save(im, name):
    im.convert("RGB").save(os.path.join(OUT, name + ".png"), optimize=True)


def dip():
    """The dipping cabinet's white front with three painted cones (invented flavours), 1.2 m."""
    W, H = 512, 360
    im = Image.new("RGB", (W, H), (250, 249, 246))
    d = ImageDraw.Draw(im)
    for k in range(3):
        cx = 90 + k * 170
        d.polygon([(cx - 34, 200), (cx + 34, 200), (cx, 330)], fill=(214, 160, 90))
        for j in range(5):
            d.line([(cx - 30 + j * 14, 205), (cx + 2 + j * 6, 320)], fill=(180, 120, 60), width=2)
        for s, c in enumerate([(240, 220, 170), (236, 140, 160), (110, 70, 50)][: 2 + k % 2]):
            d.ellipse([cx - 44, 150 - s * 62, cx + 44, 222 - s * 62], fill=c)
    d.rectangle([0, 0, W, 10], fill=(200, 200, 204))
    save(im, "dip")


def slush():
    """Two slush-machine panels: a lit picture of a frozen drink, 'FROZEN' / 'SLUSH' in white."""
    W, H = 512, 256
    im = Image.new("RGB", (W, H), (30, 60, 150))
    d = ImageDraw.Draw(im)
    for k, (word, c) in enumerate((("FROZEN", (230, 40, 60)), ("SLUSH", (40, 140, 230)))):
        x0 = k * 256
        d.rectangle([x0 + 6, 6, x0 + 250, 250], fill=(240, 244, 250))
        d.polygon([(x0 + 70, 70), (x0 + 130, 70), (x0 + 120, 220), (x0 + 80, 220)], fill=c)
        d.ellipse([x0 + 62, 52, x0 + 138, 88], fill=tuple(min(255, v + 50) for v in c))
        f = ImageFont.truetype(BOLD, 34)
        d.text((x0 + 140, 110), word, font=f, fill=c)
    save(im, "slush")


def menu():
    """Three menu screens: purple header strip, white board, cakes / cookies / treats columns with
    invented lines and small pictures."""
    W, H = 1536, 512
    im = Image.new("RGB", (W, H), (252, 252, 250))
    d = ImageDraw.Draw(im)
    heads = ["BAKED FRESH EVERY DAY", "COOKIE CAKES", "DELICIOUS TREATS"]
    for k in range(3):
        x0 = k * 512
        d.rectangle([x0 + 8, 8, x0 + 504, 504], fill=(250, 250, 250), outline=(60, 60, 60), width=6)
        d.rectangle([x0 + 8, 8, x0 + 504, 80], fill=(104, 40, 120))
        f = ImageFont.truetype(BOLD, 30)
        w = d.textlength(heads[k], font=f)
        d.text((x0 + 256 - w / 2, 26), heads[k], font=f, fill=(255, 255, 255))
        for c in range(2):
            for j in range(8):
                y = 110 + j * 34
                d.line([(x0 + 30 + c * 240, y), (x0 + 30 + c * 240 + R.randint(90, 160), y)], fill=(70, 70, 76), width=8)
                d.line([(x0 + 200 + c * 240, y), (x0 + 225 + c * 240, y)], fill=(104, 40, 120), width=8)
        for j in range(3):
            cx = x0 + 110 + j * 150
            d.ellipse([cx - 50, 400, cx + 50, 480], fill=R.choice([(206, 150, 84), (120, 74, 40), (236, 214, 170)]))
    save(im, "menu")


def rgb():
    """The LED colour box at the front's left corner: soft blobs of red, green, blue, magenta."""
    W, H = 512, 160
    im = Image.new("RGB", (W, H), (20, 20, 30))
    d = ImageDraw.Draw(im)
    for k in range(9):
        c = [(230, 40, 60), (40, 210, 120), (60, 120, 240), (220, 60, 220), (240, 200, 40)][k % 5]
        x = k * 60 + 20
        d.ellipse([x - 40, 20, x + 40, 140], fill=c)
    from PIL import ImageFilter
    save(im.filter(ImageFilter.GaussianBlur(14)), "rgb")


# ------------------------------------------------------------------ ws/interiors (Nov 4): the work-area kit
def tile_sq():
    """The video's wall (refs/new/cookie_co gacc_t000_011-015, 134, 146): white 15 cm glazed tile, grey
    grout, scattered single squares of maroon, black, yellow and green. One tile = 1.2 x 1.2 m."""
    N = 8
    T = 64
    W = N * T
    im = Image.new("RGB", (W, W), (206, 206, 202))
    d = ImageDraw.Draw(im)
    rr = random.Random(415)
    cols = [(122, 24, 44), (122, 24, 44), (30, 28, 34), (236, 196, 40), (32, 86, 58)]
    picks = set()
    while len(picks) < 4:
        picks.add((rr.randrange(N), rr.randrange(N)))
    for j in range(N):
        for i in range(N):
            c = rr.choice(cols) if (i, j) in picks else (246, 246, 242)
            c = tuple(max(0, min(255, v + rr.randint(-4, 4))) for v in c)
            d.rectangle([i * T + 2, j * T + 2, i * T + T - 2, j * T + T - 2], fill=c)
            d.line([(i * T + 6, j * T + 8), (i * T + T - 10, j * T + 6)], fill=tuple(min(255, v + 8) for v in c), width=2)
    save(F.noise(im, 1.5), "tile_sq")


def pics():
    """Four lit menu pictures (gacc 011-015, 146), invented: a stack of cookies, a decorated cookie cake,
    a tray of brownies, a cookie sandwich; a coloured caption band each, no brand. 4 across."""
    W, H = 2048, 552
    im = Image.new("RGB", (W, H), (250, 248, 244))
    d = ImageDraw.Draw(im)
    rr = random.Random(146)
    heads = ["FRESH BAKED", "COOKIE CAKES", "BROWNIES", "SANDWICHES"]
    bgs = [(244, 232, 210), (122, 24, 44), (248, 240, 228), (40, 70, 150)]
    for k in range(4):
        x0 = k * 512
        d.rectangle([x0 + 6, 6, x0 + 506, H - 6], fill=bgs[k])
        cx, cy = x0 + 256, 250
        if k == 0:
            for j in range(5):
                y = cy + 120 - j * 46
                d.ellipse([cx - 130 + j * 6, y - 34, cx + 130 - j * 6, y + 34], fill=(206 - j * 6, 150 - j * 4, 84), outline=(150, 100, 50), width=3)
                for _ in range(10):
                    px = cx + rr.randint(-110, 110); py = y + rr.randint(-14, 14)
                    d.ellipse([px - 6, py - 4, px + 6, py + 4], fill=(70, 40, 20))
        elif k == 1:
            d.ellipse([cx - 190, cy - 170, cx + 190, cy + 170], fill=(214, 168, 100))
            for j in range(48):
                a = j / 48 * 6.28
                px, py = cx + math.cos(a) * 172, cy + math.sin(a) * 152
                d.ellipse([px - 13, py - 13, px + 13, py + 13], fill=(250, 250, 250) if j % 2 else (230, 60, 100))
            f = ImageFont.truetype(F.SERIFI, 64)
            w = d.textlength("Celebrate!", font=f)
            d.text((cx - w / 2, cy - 40), "Celebrate!", font=f, fill=(40, 80, 200))
        elif k == 2:
            for j in range(3):
                for i in range(3):
                    bx, by = cx - 170 + i * 115, cy - 140 + j * 100
                    d.rectangle([bx, by, bx + 105, by + 90], fill=(78, 44, 26), outline=(50, 28, 16), width=4)
                    d.line([(bx + 10, by + 30), (bx + 90, by + 24)], fill=(110, 70, 40), width=5)
        else:
            d.ellipse([cx - 170, cy - 30, cx + 170, cy + 70], fill=(206, 150, 84))
            d.rectangle([cx - 160, cy - 60, cx + 160, cy - 10], fill=(250, 246, 236))
            d.ellipse([cx - 170, cy - 120, cx + 170, cy - 30], fill=(214, 160, 90))
            for _ in range(30):
                px = cx + rr.randint(-150, 150); py = cy + rr.choice([-80, 30]) + rr.randint(-20, 20)
                d.ellipse([px - 6, py - 6, px + 6, py + 6], fill=rr.choice([(230, 60, 80), (60, 120, 230), (250, 220, 40), (60, 180, 90)]))
        band = (122, 24, 44) if k != 1 else (246, 210, 60)
        d.rectangle([x0 + 6, H - 120, x0 + 506, H - 6], fill=band)
        f = ImageFont.truetype(BOLD, 52)
        w = d.textlength(heads[k], font=f)
        d.text((x0 + 256 - w / 2, H - 100), heads[k], font=f, fill=(255, 255, 255) if k != 1 else (122, 24, 44))
    save(F.noise(im, 1.5), "pics")


def cake_top():
    """The sheet cookie cake being piped on the prep table (gacc 071-126): a golden cookie, a
    chocolate-and-white rosette border, piped lettering (invented), a small drawn trophy."""
    W, H = 512, 384
    im = Image.new("RGB", (W, H), (196, 140, 72))
    d = ImageDraw.Draw(im)
    rr = random.Random(98)
    for _ in range(120):
        px = rr.randint(10, W - 10); py = rr.randint(10, H - 10)
        d.ellipse([px - 7, py - 5, px + 7, py + 5], fill=rr.choice([(70, 40, 20), (90, 52, 26), (170, 116, 58)]))
    for j in range(22):
        for (x, y) in ((14 + j * 23, 14), (14 + j * 23, H - 14)):
            d.ellipse([x - 11, y - 11, x + 11, y + 11], fill=(60, 34, 20) if j % 2 else (250, 248, 244))
    for j in range(16):
        for (x, y) in ((14, 14 + j * 23), (W - 14, 14 + j * 23)):
            d.ellipse([x - 11, y - 11, x + 11, y + 11], fill=(60, 34, 20) if j % 2 else (250, 248, 244))
    f = ImageFont.truetype(F.SERIFI, 58)
    d.text((70, 110), "Happy", font=f, fill=(250, 248, 244))
    d.text((90, 190), "Birthday", font=f, fill=(40, 80, 200))
    d.polygon([(390, 140), (450, 140), (440, 210), (400, 210)], fill=(250, 248, 244))
    d.rectangle([405, 210, 435, 250], fill=(240, 200, 40))
    save(F.noise(im, 2), "cake_top")


def fountain():
    """The drink fountain's lit panel: a generic fizzy-drink picture on red, 'ICE COLD' (no brand)."""
    W, H = 512, 256
    im = Image.new("RGB", (W, H), (200, 30, 40))
    d = ImageDraw.Draw(im)
    d.rectangle([12, 12, W - 12, H - 12], outline=(255, 255, 255), width=6)
    d.polygon([(60, 50), (150, 50), (138, 220), (72, 220)], fill=(250, 250, 250))
    d.rectangle([66, 110, 144, 160], fill=(40, 20, 16))
    for k in range(8):
        d.ellipse([90 + k * 5, 80 - k * 3, 98 + k * 5, 88 - k * 3], fill=(255, 255, 255))
    f = ImageFont.truetype(BOLD, 64)
    d.text((190, 70), "ICE", font=f, fill=(255, 255, 255))
    d.text((190, 140), "COLD", font=f, fill=(255, 255, 255))
    save(F.noise(im, 1.5), "fountain")


if __name__ == "__main__":
    F.cookies(); F.cookie_cakes(); F.wave()
    dip(); slush(); menu(); rgb()
    tile_sq(); pics(); cake_top(); fountain()
    print("wrote", sorted(os.listdir(OUT)))
