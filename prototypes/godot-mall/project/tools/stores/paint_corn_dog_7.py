"""Paints the Corn Dog 7 textures (design/storefronts/corn-dog-7.md) into tex/cd7/.

Every texture is drawn at a known physical size so build_mall.gd's planar UVs
(1 texture repeat per metre unless the material scales it) land the tiles,
courses and lettering where the photos have them.
Run from the project folder: python3 tools/stores/paint_corn_dog_7.py
Needs cairosvg for the sign lettering (the vector traces in cd7_letters.json).
"""
import json, math, os, random
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(PROJ, "tex", "cd7")
os.makedirs(OUT, exist_ok=True)
rnd = random.Random(7)

NAVY = (27, 36, 102)
NAVY_D = (18, 25, 74)
YEL = (246, 220, 44)
YEL_L = (255, 242, 122)
YEL_D = (226, 196, 28)
GROUT = (232, 230, 222)
WHITE = (246, 246, 242)
OAK = (178, 124, 70)
FONT_B = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT_C = "/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf"


def save(im, name):
    im.save(os.path.join(OUT, name), optimize=True)
    print(name, im.size)


def vary(c, k):
    return tuple(max(0, min(255, int(v + rnd.uniform(-k, k)))) for v in c)


def tiles(size_px, tile_m, px_per_m, colour, grout=GROUT, gloss=True, var=6):
    """A square metre (or more) of square ceramic tiles with grout lines."""
    im = Image.new("RGB", (size_px, size_px), grout)
    d = ImageDraw.Draw(im)
    t = tile_m * px_per_m
    g = max(2, int(0.004 * px_per_m))
    n = int(round(size_px / t))
    for j in range(n):
        for i in range(n):
            x0, y0 = i * t, j * t
            c = vary(colour, var)
            d.rectangle([x0 + g, y0 + g, x0 + t - 1, y0 + t - 1], fill=c)
            if gloss:
                # a soft highlight toward the top-left of each tile, a darker bottom edge
                hl = tuple(min(255, int(v * 1.12)) for v in c)
                d.rectangle([x0 + g, y0 + g, x0 + t - 1, y0 + g + t * 0.18], fill=hl)
                d.line([x0 + g, y0 + t - 2, x0 + t - 1, y0 + t - 2], fill=tuple(int(v * 0.8) for v in c), width=2)
    return im


def noise_layer(size, amount):
    n = Image.effect_noise(size, amount).convert("L")
    return n


def floor_basketweave():
    """Wood-look tile in basketweave blocks: a 1.2 m square = 4 x 4 blocks of 30 cm,
    each block three 10 x 30 cm planks, blocks alternating direction."""
    px = 800  # per 1.2 m
    im = Image.new("RGB", (px, px), (74, 48, 30))
    d = ImageDraw.Draw(im)
    b = px / 4
    woods = [(190, 146, 98), (168, 120, 78), (206, 166, 118), (148, 104, 68), (180, 136, 92)]
    g = 3
    for j in range(4):
        for i in range(4):
            x0, y0 = i * b, j * b
            horiz = (i + j) % 2 == 0
            for k in range(3):
                c = vary(woods[rnd.randrange(len(woods))], 10)
                if horiz:
                    d.rectangle([x0 + g, y0 + k * b / 3 + g, x0 + b - g, y0 + (k + 1) * b / 3 - g], fill=c)
                    for s in range(6):
                        yy = y0 + k * b / 3 + g + rnd.uniform(0, b / 3 - 2 * g)
                        d.line([x0 + g, yy, x0 + b - g, yy + rnd.uniform(-2, 2)], fill=vary(c, 18), width=1)
                else:
                    d.rectangle([x0 + k * b / 3 + g, y0 + g, x0 + (k + 1) * b / 3 - g, y0 + b - g], fill=c)
                    for s in range(6):
                        xx = x0 + k * b / 3 + g + rnd.uniform(0, b / 3 - 2 * g)
                        d.line([xx, y0 + g, xx + rnd.uniform(-2, 2), y0 + b - g], fill=vary(c, 18), width=1)
    save(im.filter(ImageFilter.GaussianBlur(0.4)), "floor.png")


def counter_front():
    """1 m x 1 m of counter face (10 x 10 tiles of 10 cm), as the close-up photo has it, from the floor up:
    navy, navy, yellow, yellow, checker x3 (panels 7 tiles wide, 3-tile yellow gaps), yellow, yellow, navy."""
    px = 1000
    base = tiles(px, 0.1, px, YEL)
    d = ImageDraw.Draw(base)
    t = px * 0.1
    g = 4
    def navy_tile(i, row_from_floor):
        j = 9 - row_from_floor          # painted with the floor at the image bottom
        d.rectangle([i * t + g, j * t + g, (i + 1) * t - 1, (j + 1) * t - 1], fill=vary(NAVY, 5))
        d.rectangle([i * t + g, j * t + g, (i + 1) * t - 1, j * t + g + t * 0.18], fill=(44, 56, 130))
    for i in range(10):
        navy_tile(i, 0); navy_tile(i, 1); navy_tile(i, 9)
    for i in range(7):                  # tiles 0..6 of each metre are a checker panel, 7..9 the gap
        for r in (4, 5, 6):
            if (i + r) % 2 == 0:
                navy_tile(i, r)
    save(base, "counter_front.png")


def wall_yellow():
    """2.9 m x 2.9 m of dining-room wall: yellow tile wainscot to 1.5 m with a navy two-tile band, white above.
    Planar UV: v = -y, so y=0 is the image top."""
    px = 1160  # 400 px/m
    m = px / 2.9
    im = Image.new("RGB", (px, px), WHITE)
    tl = tiles(px, 0.1, m, YEL)
    im.paste(tl.crop((0, 0, px, int(1.5 * m))), (0, 0))
    d = ImageDraw.Draw(im)
    t = 0.1 * m
    g = 4
    for i in range(int(2.9 / 0.1) + 1):
        for j in (13, 14):
            d.rectangle([i * t + g, j * t + g, (i + 1) * t - 1, (j + 1) * t - 1], fill=vary(NAVY, 5))
    # painted wall above: a faint texture, and a slight grime line at the tile cap
    n = noise_layer((px, px), 12).point(lambda v: 235 + (v - 128) // 12)
    top = Image.merge("RGB", (n, n, n)).crop((0, int(1.5 * m), px, px))
    im.paste(top, (0, int(1.5 * m)))
    d.line([0, int(1.5 * m), px, int(1.5 * m)], fill=(200, 196, 186), width=3)
    save(im.transpose(Image.FLIP_TOP_BOTTOM), "wall_yellow.png")


def tile_navy():
    save(tiles(800, 0.1, 800, NAVY, var=5), "tile_navy.png")


def oak_slats():
    px = 800
    im = Image.new("RGB", (px, px), OAK)
    d = ImageDraw.Draw(im)
    w = px * 0.09
    x = 0
    while x < px:
        c = vary(OAK, 14)
        d.rectangle([x, 0, x + w - 2, px], fill=c)
        for s in range(14):
            xx = x + rnd.uniform(2, w - 4)
            d.line([xx, 0, xx + rnd.uniform(-6, 6), px], fill=vary(c, 22), width=1)
        d.line([x + w - 2, 0, x + w - 2, px], fill=(96, 62, 30), width=3)
        d.line([x + 1, 0, x + 1, px], fill=(210, 160, 100), width=1)
        x += w
    save(im, "oak_slats.png")


def butcher_block():
    px = 600
    im = Image.new("RGB", (px, px), (214, 176, 118))
    d = ImageDraw.Draw(im)
    w = px * 0.06
    x = 0
    while x < px:
        c = vary((214, 176, 118), 16)
        d.rectangle([x, 0, x + w - 1, px], fill=c)
        for s in range(8):
            xx = x + rnd.uniform(1, w - 2)
            d.line([xx, 0, xx + rnd.uniform(-3, 3), px], fill=vary(c, 20), width=1)
        d.line([x, 0, x, px], fill=(160, 120, 70), width=1)
        x += w
    save(im, "butcher.png")


def steel():
    px = 512
    im = Image.new("RGB", (px, px), (190, 194, 200))
    d = ImageDraw.Draw(im)
    for y in range(px):
        c = 178 + int(22 * math.sin(y * 0.9) ) + rnd.randint(-6, 6)
        d.line([0, y, px, y], fill=(c, c + 3, c + 8))
    save(im, "steel.png")


def ceiling():
    """2.4 m x 2.4 m: four 0.6 x 1.2 m acoustic tiles per row in a white grid."""
    px = 960
    im = Image.new("RGB", (px, px), (222, 222, 216))
    d = ImageDraw.Draw(im)
    n = noise_layer((px, px), 40).point(lambda v: 232 + (v - 128) // 6)
    im = Image.merge("RGB", (n, n, n))
    d = ImageDraw.Draw(im)
    for x in range(0, px + 1, px // 4):
        d.line([x, 0, x, px], fill=(248, 248, 246), width=6)
    for y in range(0, px + 1, px // 2):
        d.line([0, y, px, y], fill=(248, 248, 246), width=6)
    save(im, "ceiling.png")


def troffer():
    """One 0.6 x 1.2 m prismatic lens, lit."""
    im = Image.new("RGB", (600, 1200), (252, 250, 236))
    d = ImageDraw.Draw(im)
    for x in range(0, 600, 12):
        d.line([x, 0, x, 1200], fill=(238, 236, 220), width=2)
    for y in range(0, 1200, 12):
        d.line([0, y, 600, y], fill=(238, 236, 220), width=2)
    d.rectangle([0, 0, 599, 1199], outline=(214, 214, 210), width=10)
    save(im, "troffer.png")


def menu_board():
    """A 1995 backlit menu box panel (the 2024 photos show TVs; in 1995 it was a lightbox): a yellow header
    with the name in navy, a translucent white field with navy items. Prices are guesses for 1995."""
    import cairosvg, io
    W, H = 1280, 720
    im = Image.new("RGB", (W, H), (250, 248, 238))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, W, 150], fill=YEL)
    d.rectangle([0, 150, W, 162], fill=NAVY)
    L = json.load(open(os.path.join(HERE, "cd7_letters.json")))
    t = L["CD7"]["t"]
    hp = 100; wp = int(t["w"] / t["h"] * hp)
    svg = ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %s %s">'
           '<path d="%s" fill="#1b2466" fill-rule="evenodd"/></svg>') % (wp, hp, t["w"], t["h"], t["p"])
    g = Image.open(io.BytesIO(cairosvg.svg2png(bytestring=svg.encode()))).convert("RGBA")
    im.paste(g, ((W - wp) // 2, 25), g)
    fh = ImageFont.truetype(FONT_C, 44)
    fi = ImageFont.truetype(FONT_C, 31)
    cols = [("CORN DOGS", [("Corn Dog", "2.00"), ("Cheese Stick", "1.49"), ("Jumbo Dog", "1.79")]),
            ("FRIES", [("Seasoned Fries", ".99"), ("Large Fries", "1.29"), ("Chili Fries", "1.79")]),
            ("DRINKS", [("Fresh Lemonade", ".99"), ("Lg. Lemonade", "1.39"), ("Soft Drinks", ".89")])]
    for ci, (head, items) in enumerate(cols):
        x = 40 + ci * 415
        d.text((x, 200), head, font=fh, fill=(200, 32, 44))
        for k, (nm, pr) in enumerate(items):
            y = 275 + k * 70
            d.text((x, y), nm, font=fi, fill=NAVY)
            tw = d.textlength(pr, font=fi)
            d.text((x + 370 - tw, y), pr, font=fi, fill=NAVY)
    d.rectangle([0, 600, W, 720], fill=NAVY)
    fb = ImageFont.truetype(FONT_B, 46)
    msg = "COMBO: CORN DOG, FRIES & LEMONADE  2.99"
    d.text(((W - d.textlength(msg, font=fb)) / 2, 630), msg, font=fb, fill=YEL)
    save(im, "menu.png")


def awning():
    """The sign box unwrapped like a photo of its front: u = metres along the sweep (left rounded end,
    front, right rounded end); the image's bottom row is the awning's bottom edge and its top row is where
    the roll meets the wall (profile length PROF_M). Lettering from the vector traces (cd7_letters.json)."""
    import cairosvg, io
    PPM = 400
    # the sweep: the rounded left end, the straight front, the rounded right end (corn_dog_7.gd: the
    # opening 2.4..9.6 m, the awning 0.2 m past each pier, end radius 0.6)
    END = math.pi * 0.5 * 0.6
    PATH_M = END + (9.6 - 2.4 + 0.4 - 1.2) + END
    S0, S1 = 0.55, 0.62    # the navy stripe, metres up from the bottom edge
    PROF_M = 1.10 + 0.85 * math.pi / 2    # face + quarter roll (corn_dog_7.gd)
    W, H = int(PATH_M * PPM), int(PROF_M * PPM)
    row = lambda v: int((PROF_M - v) * PPM)
    im = Image.new("RGB", (W, H), YEL)
    d = ImageDraw.Draw(im)
    # glossy yellow: bright along the roll's crown, darker at the bottom edge and where it meets the wall
    for y in range(H):
        f = (H - y) / H   # fraction up the profile
        if f < 0.4:
            k = 0.94 + 0.06 * f / 0.4
        elif f < 0.62:
            k = 1.0 + 0.1 * (f - 0.4) / 0.22
        else:
            k = 1.1 - 0.22 * (f - 0.62) / 0.38
        c = tuple(min(255, int(v * k)) for v in YEL)
        d.line([0, y, W, y], fill=c)
    # panel seams every 1.3 m along the front
    x = END + 0.55
    while x < PATH_M - END:
        px = int(x * PPM)
        d.line([px, 0, px, H], fill=(206, 176, 20), width=2)
        d.line([px + 2, 0, px + 2, H], fill=(255, 246, 150), width=1)
        x += 1.3
    # the navy pinstripe 0.33 m up from the bottom edge, 7 cm tall
    d.rectangle([0, row(S1), W, row(S0)], fill=NAVY)
    L = json.load(open(os.path.join(HERE, "cd7_letters.json")))

    def letters(obj, height_m, u_m, v_bottom_m, extra=""):
        w, h, p = obj["w"], obj["h"], obj["p"]
        hp = int(height_m * PPM)
        wp = int(w / h * hp)
        svg = ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %s %s">'
               '<path d="%s" fill="#1b2466" fill-rule="evenodd"/>%s</svg>') % (wp, hp, w, h, p, extra)
        png = cairosvg.svg2png(bytestring=svg.encode())
        g = Image.open(io.BytesIO(png)).convert("RGBA")
        im.paste(g, (int(u_m * PPM), row(v_bottom_m) - hp), g)

    stroke = '<path d="%s" fill="none" stroke="#1b2466" stroke-width="2.1" stroke-linecap="round"/>'
    # "seasoned fries": sits on the stripe, left of centre
    # the stripe stops either side of "seasoned fries", which sits across the line (close photo)
    sl = L["CD7O"]["l"]; sw = sl["w"] / sl["h"] * 0.30
    d.rectangle([int((END + 0.78) * PPM), row(S1) - 2, int((END + 0.85 + sw + 0.08) * PPM), row(S0) + 2], fill=YEL)
    letters(L["CD7O"]["l"], 0.30, END + 0.85, (S0 + S1) / 2 - 0.15, stroke % "M-4.2 19.2 Q-1.2 17.5 2.6 10.6")
    # "CORN DOG 7": above the stripe, centre-right
    letters(L["CD7"]["t"], 0.48, END + 3.2, S1 + 0.1)
    # "fresh lemonade": below the stripe at the right end, running onto the rounded end
    letters(L["CD7O"]["r"], 0.24, END + 5.45, S0 - 0.06 - 0.24,
            stroke % "M130.6 15.6 C137.5 14.8 137.2 9.6 133.2 10.2" + stroke % "M132.2 19.4 Q136.5 19.6 140 15.8")
    save(im, "awning.png")


if __name__ == "__main__":
    floor_basketweave()
    counter_front()
    wall_yellow()
    tile_navy()
    oak_slats()
    butcher_block()
    steel()
    ceiling()
    troffer()
    menu_board()
    awning()
