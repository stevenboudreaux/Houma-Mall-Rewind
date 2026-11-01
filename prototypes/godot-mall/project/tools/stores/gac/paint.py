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


if __name__ == "__main__":
    F.cookies(); F.cookie_cakes(); F.wave()
    dip(); slush(); menu(); rgb()
    print("wrote", sorted(os.listdir(OUT)))
