"""A mid-90s kids' horror paperback on B. Dalton Bookseller's table of new titles (1995 map, store s48).
Pocket item.

Steven asked for "a Goosebumps book" (Nov 1, 2026). The IP rule (CLAUDE-CLOUD.md: no real product titles,
cover art or logos inside stores) rules out the real series, so this is an INVENTED series in that spirit:
SHIVERWOOD #7, "The Bayou Babysitter", by an invented author (Celeste Marchand). Everything printed on it is
drawn here with PIL: a purple cover with a lime drippy title, a moonlit swamp with glowing eyes, a series
band, a white price sticker ($3.99), a cracked spine and a blurb and bar code on the back.

References: none for the object (no photo of B. Dalton's tables); design/storefronts/b-dalton.md (the table
of new titles by the door). Size: a US mass-market kids' paperback, ~108 x 175 mm, ~12 mm thick (about 130
pages). Guessed: everything printed; the wear (whitened spine creases, a softened corner).
Origin: bottom centre, lying flat with the cover up; the top of the cover points away from the reader in
front of it (Blender +Y = Godot -Z), so it reads from the hall.
"""
import math
import random
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from lib import core, parts, mats, labels

W, L, T = 0.108, 0.175, 0.0122      # width (X), length (Y), thickness (Z)
CV = 0.0007                         # cover board thickness
OVER = 0.0012                       # the covers overhang the page block
PX = 1600 / L                       # artwork px per metre
SEED = 7
PURPLE = (74, 24, 120)
PURPLE2 = (38, 10, 70)
LIME = (166, 238, 42)
LIME_D = (60, 110, 10)
FONTS = "tools/stores/signs/y26/src/fonts/"

META = {
    "id": "bl_bd_paperback",
    "class": "pocket",
    "tex": 1024,
    "ao": 0.3,
    "refs": [],
    "item_file": "blender_props_2.json",
    "item": {"name": "Shiverwood #7 paperback", "year": 1995, "store": "B. DALTON BOOKSELLER",
             # three copies face-up on the front half of the table of new titles (store2.gd dalton():
             # tc = P(W/2, 0, 2.2) = (-106, 0, 45.8), 1.8 x 0.9 m, top 0.76; the spines along its back edge)
             "display": {"wing": 2, "year": 1995, "pos": [-105.42, 0.76, 45.98], "yaw": 6, "runtime": True},
             "copies": [
                 {"id": "bl_bd_paperback_b", "display": {"wing": 2, "year": 1995, "pos": [-105.62, 0.76, 45.95], "yaw": -4, "runtime": True}},
                 {"id": "bl_bd_paperback_c", "display": {"wing": 2, "year": 1995, "pos": [-105.82, 0.76, 45.99], "yaw": 3, "runtime": True}},
             ]},
}


def F(name, px):
    import os
    return ImageFont.truetype(os.path.join(labels.PROJ, FONTS + name), int(px))


def gradient(w, h, top, bottom):
    im = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(im)
    for y in range(h):
        t = y / max(1, h - 1)
        d.line([(0, y), (w, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(top, bottom)) + (255,))
    return im


def drippy(im, xy, s, font, fill, outline, rng, drip=1.0, stroke=10):
    """Lettering with slime running off it: the text, then drips hanging from the bottoms of the strokes."""
    w, h = im.size
    mask = Image.new("L", (w, h), 0)
    md = ImageDraw.Draw(mask)
    md.text(xy, s, font=font, fill=255, anchor="mm")
    px = mask.load()
    bbox = mask.getbbox()
    if bbox:
        x = bbox[0] + rng.randint(4, 20)
        while x < bbox[2]:
            bottom = None
            for y in range(bbox[3] - 1, bbox[1], -1):
                if px[x, y]:
                    bottom = y
                    break
            if bottom is not None and rng.random() < 0.55:
                r = rng.randint(5, 10) * font.size / 120
                ln = rng.uniform(0.15, 0.8) * font.size * drip
                md.rounded_rectangle((x - r, bottom - r, x + r, bottom + ln), radius=r, fill=255)
                md.ellipse((x - r * 1.5, bottom + ln - r * 1.2, x + r * 1.5, bottom + ln + r * 1.8), fill=255)
            x += rng.randint(int(font.size * 0.18), int(font.size * 0.45))
    ol = mask.filter(ImageFilter.MaxFilter(stroke * 2 + 1))
    shadow = ol.filter(ImageFilter.GaussianBlur(6))
    im.paste(Image.new("RGBA", (w, h), (0, 0, 0, 200)), (8, 10), shadow)
    im.paste(Image.new("RGBA", (w, h), outline + (255,)), (0, 0), ol)
    # the slime: a light top, darker toward the drips
    grad = gradient(w, h, (215, 255, 110), fill)
    im.paste(grad, (0, 0), mask)
    # a highlight glint on each stroke
    hl = mask.filter(ImageFilter.MinFilter(9))
    hl = Image.eval(hl, lambda v: v // 3)
    im.paste(Image.new("RGBA", (w, h), (255, 255, 230, 255)), (-4, -5), hl)


def swamp(im, box, rng):
    """The cover picture: a full moon over cypress trees, black water and two pairs of glowing eyes, and a
    clawed green hand coming up out of the water toward a porch light. Drawn, invented."""
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    pic = gradient(w, h, (40, 120, 90), (14, 30, 40))
    d = ImageDraw.Draw(pic)
    # moon with a halo
    mx, my, mr = int(w * 0.68), int(h * 0.26), int(w * 0.17)
    halo = Image.new("L", (w, h), 0)
    ImageDraw.Draw(halo).ellipse((mx - mr * 2, my - mr * 2, mx + mr * 2, my + mr * 2), fill=110)
    halo = halo.filter(ImageFilter.GaussianBlur(mr * 0.6))
    pic.paste(Image.new("RGBA", (w, h), (230, 255, 170, 255)), (0, 0), halo)
    d.ellipse((mx - mr, my - mr, mx + mr, my + mr), fill=(236, 250, 190, 255))
    for k in range(6):
        cx, cy, cr = mx + rng.randint(-mr // 2, mr // 2), my + rng.randint(-mr // 2, mr // 2), rng.randint(mr // 10, mr // 4)
        d.ellipse((cx - cr, cy - cr, cx + cr, cy + cr), fill=(206, 226, 160, 255))
    # cypress trees: trunks flaring at the base, ragged crowns, hanging moss
    for tx, th, tw in ((0.08, 0.80, 0.11), (0.30, 0.62, 0.08), (0.93, 0.74, 0.10), (0.52, 0.45, 0.05)):
        bx = int(w * tx)
        top = int(h * (0.82 - th))
        base = int(h * 0.80)
        d.polygon([(bx - int(w * tw * 0.25), base), (bx - int(w * 0.012), top + 40), (bx + int(w * 0.012), top + 40),
                   (bx + int(w * tw * 0.25), base)], fill=(8, 14, 16, 255))
        for k in range(9):
            cx = bx + rng.randint(-int(w * tw), int(w * tw))
            cy = top + rng.randint(0, int(h * 0.12))
            rr = rng.randint(int(w * tw * 0.35), int(w * tw * 0.7))
            d.ellipse((cx - rr, cy - rr * 0.5, cx + rr, cy + rr * 0.5), fill=(8, 14, 16, 255))
            for j in range(3):
                mxx = cx + rng.randint(-rr, rr)
                d.line([(mxx, cy), (mxx + rng.randint(-8, 8), cy + rng.randint(40, 120))], fill=(30, 60, 40, 255), width=5)
    # water with moon glints
    d.rectangle((0, int(h * 0.80), w, h), fill=(6, 16, 20, 255))
    for k in range(40):
        gx = mx + rng.randint(-mr, mr)
        gy = rng.randint(int(h * 0.81), h - 4)
        d.line([(gx - rng.randint(10, 40), gy), (gx + rng.randint(10, 40), gy)], fill=(140, 190, 120, 255), width=3)
    # glowing eyes in the water and the trees
    for ex, ey, s in ((0.22, 0.86, 1.0), (0.42, 0.66, 0.6), (0.80, 0.90, 0.8)):
        for side in (-1, 1):
            cx, cy, r = int(w * ex) + side * int(26 * s), int(h * ey), int(13 * s)
            g = Image.new("L", (w, h), 0)
            ImageDraw.Draw(g).ellipse((cx - r * 3, cy - r * 3, cx + r * 3, cy + r * 3), fill=160)
            g = g.filter(ImageFilter.GaussianBlur(r * 1.2))
            pic.paste(Image.new("RGBA", (w, h), (255, 230, 40, 255)), (0, 0), g)
            d.ellipse((cx - r, cy - r * 0.6, cx + r, cy + r * 0.6), fill=(255, 250, 120, 255))
            d.ellipse((cx - r * 0.25, cy - r * 0.55, cx + r * 0.25, cy + r * 0.55), fill=(20, 10, 0, 255))
    # the clawed hand coming out of the water (bottom right), lit from the moon
    hx, hy = int(w * 0.62), int(h * 0.98)
    arm = [(hx - 60, h), (hx - 40, hy - 160), (hx + 40, hy - 170), (hx + 70, h)]
    d.polygon(arm, fill=(70, 130, 40, 255))
    palm = (hx - 70, hy - 300, hx + 80, hy - 140)
    d.ellipse(palm, fill=(80, 150, 46, 255))
    skin, lit = (80, 150, 46, 255), (150, 210, 90, 255)
    for k, (fx, ang, ln, bend) in enumerate(((-62, -128, 160, 0.35), (-26, -104, 205, 0.25), (14, -86, 215, 0.15),
                                             (50, -66, 190, 0.05), (80, -24, 120, -0.3))):
        # two knobbly joints per finger, bent toward the moon, tapering to a hooked claw
        a = math.radians(ang)
        p0 = (hx + fx, hy - 250)
        p1 = (p0[0] + ln * 0.55 * math.cos(a), p0[1] + ln * 0.55 * math.sin(a))
        a2 = a + bend
        p2 = (p1[0] + ln * 0.5 * math.cos(a2), p1[1] + ln * 0.5 * math.sin(a2))
        for (qa, qb, w0, w1) in ((p0, p1, 40, 32), (p1, p2, 32, 20)):
            dx, dy = qb[0] - qa[0], qb[1] - qa[1]
            n = math.hypot(dx, dy) or 1
            nx, ny = -dy / n, dx / n
            d.polygon([(qa[0] + nx * w0 / 2, qa[1] + ny * w0 / 2), (qb[0] + nx * w1 / 2, qb[1] + ny * w1 / 2),
                       (qb[0] - nx * w1 / 2, qb[1] - ny * w1 / 2), (qa[0] - nx * w0 / 2, qa[1] - ny * w0 / 2)], fill=skin)
            d.line([(qa[0] + nx * w0 * 0.3, qa[1] + ny * w0 * 0.3), (qb[0] + nx * w1 * 0.3, qb[1] + ny * w1 * 0.3)], fill=lit, width=5)
        d.ellipse((p1[0] - 19, p1[1] - 19, p1[0] + 19, p1[1] + 19), fill=skin)    # the knuckle
        d.ellipse((p2[0] - 11, p2[1] - 11, p2[0] + 11, p2[1] + 11), fill=skin)
        ca = a2 + 0.7
        d.polygon([(p2[0] - 10 * math.sin(a2), p2[1] + 10 * math.cos(a2)), (p2[0] + 10 * math.sin(a2), p2[1] - 10 * math.cos(a2)),
                   (p2[0] + 40 * math.cos(ca), p2[1] + 40 * math.sin(ca))], fill=(240, 236, 210, 255))
    for k in range(10):   # warts
        wx, wy = rng.randint(palm[0] + 20, palm[2] - 20), rng.randint(palm[1] + 20, palm[3] - 10)
        d.ellipse((wx - 7, wy - 7, wx + 7, wy + 7), fill=(50, 100, 30, 255))
    pic = pic.filter(ImageFilter.GaussianBlur(1.2))    # painted, not vector-sharp
    im.paste(pic, (x0, y0))
    # a lime frame round the picture (the series' look), with a drip or two
    dd = ImageDraw.Draw(im)
    dd.rectangle(box, outline=LIME + (255,), width=14)


def cover():
    rng = random.Random(SEED)
    cw, ch = int(W * PX), int(L * PX)
    im = gradient(cw, ch, PURPLE, PURPLE2)
    d = ImageDraw.Draw(im)
    # a bubbly texture on the purple
    for k in range(260):
        x, y, r = rng.randint(0, cw), rng.randint(0, ch), rng.randint(6, 30)
        d.ellipse((x - r, y - r, x + r, y + r), outline=(100, 50, 150, 255), width=3)
    # the series band: SHIVERWOOD in drippy lime across the top
    drippy(im, (cw * 0.5, ch * 0.085), "SHIVERWOOD", F("TitanOne-Regular.ttf", 124), LIME, (20, 6, 40), rng, 0.9)
    # the number in a lime splat, top left
    d = ImageDraw.Draw(im)
    sx, sy = int(cw * 0.12), int(ch * 0.205)
    pts = []
    for k in range(18):
        a = k / 18 * math.tau
        r = (78 if k % 2 else 56) + rng.randint(-6, 6)
        pts.append((sx + r * math.cos(a), sy + r * math.sin(a)))
    d.polygon(pts, fill=LIME + (255,), outline=(20, 6, 40, 255))
    labels.text(d, (sx, sy + 6), "7", "bold", 96, (40, 10, 70, 255))
    labels.text(d, (cw * 0.56, ch * 0.195), "SCARY STORIES FOR KIDS WHO DARE", "bold", 40, (255, 255, 255, 255))
    # the picture
    swamp(im, (int(cw * 0.08), int(ch * 0.24), int(cw * 0.92), int(ch * 0.72)), rng)
    # the title in two drippy lines under the picture
    drippy(im, (cw * 0.5, ch * 0.765), "THE BAYOU", F("TitanOne-Regular.ttf", 120), LIME, (20, 6, 40), rng, 0.35)
    drippy(im, (cw * 0.5, ch * 0.872), "BABYSITTER", F("TitanOne-Regular.ttf", 120), LIME, (20, 6, 40), rng, 0.45)
    d = ImageDraw.Draw(im)
    labels.text(d, (cw * 0.5, ch * 0.955), "CELESTE MARCHAND", "bold", 50, (255, 255, 255, 255))
    # the price sticker: a white oval-cornered label, bottom right, a little crooked
    st = Image.new("RGBA", (300, 150), (0, 0, 0, 0))
    sd = ImageDraw.Draw(st)
    sd.rounded_rectangle((4, 4, 296, 146), 22, fill=(250, 248, 240, 255), outline=(200, 196, 186, 255), width=3)
    sd.text((150, 52), "$3.99", font=labels.font("bold", 84), fill=(200, 20, 30, 255), anchor="mm")
    sd.text((150, 118), "0590 4 47215 7", font=labels.font("sans", 26), fill=(40, 40, 40, 255), anchor="mm")
    st = st.rotate(-7, expand=True, resample=Image.BICUBIC)
    im.paste(st, (int(cw * 0.66), int(ch * 0.29)), st)
    # wear: a whitened scuff along the edges and a soft crease across the bottom corner
    wear = Image.new("L", (cw, ch), 0)
    wd = ImageDraw.Draw(wear)
    for k in range(120):
        e = rng.choice(("l", "r", "t", "b"))
        x = rng.randint(0, cw) if e in "tb" else (rng.randint(0, 10) if e == "l" else cw - rng.randint(0, 10))
        y = rng.randint(0, ch) if e in "lr" else (rng.randint(0, 10) if e == "t" else ch - rng.randint(0, 10))
        wd.ellipse((x - 6, y - 6, x + 6, y + 6), fill=rng.randint(80, 200))
    wd.line([(int(cw * 0.78), ch), (cw, int(ch * 0.9))], fill=150, width=5)
    im.paste(Image.new("RGBA", (cw, ch), (236, 230, 240, 255)), (0, 0), wear.filter(ImageFilter.GaussianBlur(1.5)))
    return labels.save(im, "bd_paperback_cover")


def back():
    rng = random.Random(SEED + 1)
    cw, ch = int(W * PX), int(L * PX)
    im = gradient(cw, ch, PURPLE2, PURPLE)
    d = ImageDraw.Draw(im)
    drippy(im, (cw * 0.5, ch * 0.11), "WHO'S WATCHING", F("TitanOne-Regular.ttf", 84), LIME, (20, 6, 40), rng, 0.5, 7)
    drippy(im, (cw * 0.5, ch * 0.18), "THE KIDS?", F("TitanOne-Regular.ttf", 84), LIME, (20, 6, 40), rng, 0.5, 7)
    d = ImageDraw.Draw(im)
    blurb = ["Mom and Dad said Miss Odile was the", "best babysitter on the bayou. She never", "burns the popcorn. She knows every",
             "old story. And she never, ever goes", "near the water after dark.", "", "So why are there wet footprints on",
             "the porch every morning? And why", "does her rocking chair keep rocking", "when nobody's in it?"]
    for i, line in enumerate(blurb):
        labels.text(d, (cw * 0.08, ch * (0.28 + i * 0.045)), line, "sans", 42, (255, 255, 255, 255), "lm")
    labels.text(d, (cw * 0.5, ch * 0.78), "SHIVERWOOD #7", "bold", 64, LIME + (255,))
    labels.text(d, (cw * 0.5, ch * 0.83), "Collect them all... if you dare!", "italic", 40, (230, 220, 250, 255))
    d.rectangle((cw * 0.56, ch * 0.87, cw * 0.93, ch * 0.97), fill=(255, 255, 255, 255))
    for i in range(36):
        x = cw * 0.575 + i * cw * 0.0092
        d.rectangle((x, ch * 0.88, x + (3 if i % 3 else 7), ch * 0.95), fill=(0, 0, 0, 255))
    labels.text(d, (cw * 0.2, ch * 0.92), "$3.50 U.S.", "bold", 44, (255, 255, 255, 255))
    return labels.save(im, "bd_paperback_back")


def spine():
    """The spine runs the book's length (along Y), the words top to bottom; white crease lines where it has
    been read open (the cracked spine)."""
    rng = random.Random(SEED + 2)
    sw, sh = int(L * PX), int(T * PX * 1.0) + 1
    sh = max(sh, 120)
    im = Image.new("RGBA", (sw, sh), PURPLE + (255,))
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, int(sw * 0.14), sh), fill=LIME + (255,))
    labels.text(d, (int(sw * 0.07), sh // 2), "7", "bold", sh * 0.75, (40, 10, 70, 255))
    labels.text(d, (int(sw * 0.36), sh // 2), "SHIVERWOOD", "bold", sh * 0.55, LIME + (255,))
    labels.text(d, (int(sw * 0.74), sh // 2), "THE BAYOU BABYSITTER", "bold", sh * 0.4, (255, 255, 255, 255))
    for k in range(9):    # creases across the spine, whitened where the ink cracked
        x = rng.randint(int(sw * 0.18), sw - 10)
        pts = [(x + rng.randint(-6, 6), y) for y in range(0, sh + 1, max(1, sh // 5))]
        d.line(pts, fill=(226, 220, 232, 255), width=rng.choice((2, 3, 4)))
    return labels.save(im, "bd_paperback_spine")


def pages_mat():
    m = mats.M("pages", "#e9dfc6", 0.85)
    tc = m.coords()
    mp = m.node("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (1.0, 1.0, 4000.0)     # fine page lines across the edge (along Z)
    m.link(tc, mp.inputs["Vector"])
    n = m.noise(1.0, 2.0, coord=mp.outputs["Vector"])
    col = m.ramp(n.outputs["Fac"], [(0.35, "#d5c8a8"), (0.65, "#efe6d0")])
    m.link(col, m.bsdf.inputs["Base Color"])
    m.bump(n.outputs["Fac"], 0.3, 0.0003)
    return m.mat


def build():
    cp, bp, sp = cover(), back(), spine()
    m = mats.M("cover", "#4a1878", 0.38)          # glossy printed board
    c = mats.decal(m, cp, (0, 0, T), (W, L), "XY", facing="+Z")
    c = mats.decal(m, bp, (0, 0, 0), (W, L), "XY", base=c, flip_u=True, facing="-Z")
    c = mats.decal(m, sp, (-W / 2, 0, T / 2), (L, T), "YZ", base=c, flip_u=True, facing="-X")
    m.bump(m.noise(500.0, 2.0).outputs["Fac"], 0.03, 0.0003)
    # the page block, inset from the covers on three sides
    parts.box("pages", (W - OVER * 1.5, L - OVER * 2, T - 2 * CV), loc=(OVER * 0.75, 0, T / 2), mat=pages_mat(), bev=0.0006)
    # the covers and the spine (one wrap: two boards and the spine strip, slightly rounded)
    parts.box("front", (W, L, CV), loc=(0, 0, T - CV / 2), mat=m.mat, bev=0.0002, seg=1)
    parts.box("backc", (W, L, CV), loc=(0, 0, CV / 2), mat=m.mat, bev=0.0002, seg=1)
    sp_ob = parts.cylinder("spine", T / 2, L, verts=16, loc=(-W / 2 + T * 0.18, 0, T / 2), rot=(90, 0, 0), mat=m.mat, bev=0)
    sp_ob.scale = (0.4, 1.0, 1.0)
    core.apply_all(sp_ob)
