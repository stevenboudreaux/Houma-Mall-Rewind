"""Great American Cookie Co., 1995 walls (workstream FOOD3D item 2, Nov 8 2026). Steven, Nov 7: the white tile with
scattered red/black/yellow squares is the 2026 look; the 1990s store was "more traditional". Two options were shown
(production/qa/evidence/wsFOOD3D-gac-1990s-options.jpg); Steven picked B (Nov 8), so only B is painted here:
"dark oak and brass" (a period type for a late-1980s mall bakery; no photo of this chain in it): a stained oak
raised-panel wainscot with an oak chair rail and a brass strip, cream plaster above, a thin burgundy pinstripe and
an oak crown. One 1024 px picture of 3.0 m of wall from the floor up (world triplanar, 3.0 m repeat: the floor is
y = 0): tex/gac/wall95_b.png. design/storefronts/great-american-cookie.md "FOOD3D: the 1990s front".
"""
import os
import random
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "..", "tex", "gac")
PX = 1024
M = PX / 3.0          # px per metre


def Y(m):
    """Height in metres -> image row (row 0 = the top, 3.0 m)."""
    return int(round(PX - m * M))


def noise(im, amt, seed=1):
    rnd = random.Random(seed)
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b = px[x, y][:3]
            k = rnd.randint(-amt, amt)
            px[x, y] = (max(0, min(255, r + k)), max(0, min(255, g + k)), max(0, min(255, b + k)))
    return im


def tile(d, y0, y1, base, grout, size=0.15):
    d.rectangle((0, Y(y1), PX, Y(y0)), fill=base)
    s = size * M
    x = 0.0
    while x <= PX:
        d.line((int(x), Y(y1), int(x), Y(y0)), fill=grout, width=2)
        x += s
    yy = y0
    while yy <= y1 + 1e-6:
        d.line((0, Y(yy), PX, Y(yy)), fill=grout, width=2)
        yy += size


def option_b():
    im = Image.new("RGB", (PX, PX), (236, 226, 204))
    d = ImageDraw.Draw(im)
    rnd = random.Random(5)
    # cream plaster with a soft mottle
    for _ in range(900):
        x, y = rnd.randint(0, PX), rnd.randint(0, Y(1.1))
        r = rnd.randint(8, 30)
        c = rnd.randint(-6, 6)
        d.ellipse((x - r, y - r, x + r, y + r), fill=(236 + c, 226 + c, 204 + c))
    im = im.filter(ImageFilter.GaussianBlur(6))
    d = ImageDraw.Draw(im)
    # stained oak wainscot: vertical grain, raised panels 0.5 m wide
    oak = (112, 70, 38)
    d.rectangle((0, Y(1.05), PX, Y(0.0)), fill=oak)
    for x in range(0, PX, 3):
        c = rnd.randint(-14, 10)
        d.line((x, Y(1.05), x + rnd.randint(-2, 2), Y(0.0)), fill=(oak[0] + c, oak[1] + c, oak[2] + c), width=2)
    x = 0.0
    while x < 3.0:
        x0, x1 = int((x + 0.06) * M), int((x + 0.44) * M)
        d.rectangle((x0, Y(0.92), x1, Y(0.2)), outline=(70, 42, 22), width=4)
        d.rectangle((x0 + 5, Y(0.92) + 5, x1 - 5, Y(0.2) - 5), outline=(150, 100, 58), width=2)
        x += 0.5
    d.rectangle((0, Y(0.12), PX, Y(0.0)), fill=(60, 36, 20))
    d.rectangle((0, Y(1.10), PX, Y(1.05)), fill=(92, 56, 30))           # the chair rail
    d.rectangle((0, Y(1.065), PX, Y(1.055)), fill=(196, 156, 66))       # brass strip in it
    d.rectangle((0, Y(2.205), PX, Y(2.19)), fill=(120, 24, 38))         # burgundy pinstripe
    d.rectangle((0, Y(3.0), PX, Y(2.9)), fill=(92, 56, 30))             # oak crown
    return noise(im, 3, 2)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    option_b().save(os.path.join(OUT, "wall95_b.png"), optimize=True)
    print("wrote tex/gac/wall95_b.png")
