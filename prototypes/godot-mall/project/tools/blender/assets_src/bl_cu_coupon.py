"""A Cuco's coupon for one free top-shelf margarita (1995 map, store s42). Hand item; item id `cu_coupon`
(workstream FOOD, Nov 3 2026). Redeemed for cu_top_shelf_margarita.

Wording: the brief allows only "Free top shelf margarita" and the Cuco's name; workstream CUCOS writes any
other words, so there is none (no expiry, no fine print). The name is the restaurant's own neon sign
(tools/stores/signs/cu_sign.json, drawn by _cucos.logo()), the tenant's own mark.
Look (guessed, a period print-shop coupon): heavy cream card stock, a teal dashed cut-here border, papel
picado flags strung along the top in the restaurant's colours (red, teal, periwinkle, yellow; the room has
papel picado, design/storefronts/cucos.md), the sign, FREE / TOP SHELF MARGARITA in a slab serif, a drawn
cactus-stem margarita glass (the drink's own look), the left edge torn along a perforation.
Size: 152 x 70 mm (a coupon-book leaf), 0.35 mm card, a slight curl.
Origin: bottom centre, lying flat, printed side up, its top away from the viewer.
"""
import math
import random
import bmesh
from PIL import Image, ImageDraw, ImageFilter
from lib import core, parts, mats, labels
import _cucos as C
import _book as B

W, L, T = 0.152, 0.070, 0.00035
PPM = 2400 / W
SEED = 23
TEAL = (30, 120, 112)
RED = (196, 40, 30)

META = {
    "id": "bl_cu_coupon",
    "class": "hand",
    "tex": 2048,
    "ao": 0.15,
    "refs": [["prototypes/godot-mall/project/tools/stores/signs/src/cucos_front.jpg", None, "Cuco's neon sign (traced)"]],
    "icon_view": (0, 70),
    "item_file": "food.json",
    "item": {"id": "cu_coupon", "name": "Coupon: free top shelf margarita", "year": 1995, "store": "CUCOS"},
}


def glass(d, x, y, s):
    """The top-shelf glass, drawn: a cobalt rim, the bowl of amber, a cactus stem."""
    d.polygon([(x - s, y - s * 0.9), (x + s, y - s * 0.9), (x + s * 0.55, y - s * 0.1), (x, y + s * 0.05), (x - s * 0.55, y - s * 0.1)], fill=(236, 178, 60, 255), outline=(60, 40, 20, 255))
    d.rectangle((x - s, y - s * 1.0, x + s, y - s * 0.86), fill=(30, 60, 200, 255))
    d.rectangle((x - s * 0.1, y, x + s * 0.1, y + s * 0.9), fill=(40, 150, 70, 255))
    d.line((x - s * 0.1, y + s * 0.4, x - s * 0.35, y + s * 0.4, x - s * 0.35, y + s * 0.15), fill=(40, 150, 70, 255), width=int(s * 0.14))
    d.line((x + s * 0.1, y + s * 0.55, x + s * 0.35, y + s * 0.55, x + s * 0.35, y + s * 0.3), fill=(40, 150, 70, 255), width=int(s * 0.14))
    d.ellipse((x - s * 0.6, y + s * 0.82, x + s * 0.6, y + s * 1.0), fill=(40, 150, 70, 255))
    d.ellipse((x + s * 0.4, y - s * 1.22, x + s * 0.9, y - s * 0.72), fill=(120, 190, 50, 255), outline=(40, 110, 30, 255), width=4)


def art():
    rng = random.Random(SEED)
    im, d = B.canvas_for(W, L, PPM, (246, 238, 214, 255))
    w, h = im.size
    for k in range(5000):                                  # card stock fibres
        x, y = rng.randint(0, w - 1), rng.randint(0, h - 1)
        c = rng.randint(-14, 8)
        d.point((x, y), fill=(246 + c if c < 0 else 246, 238 + c, 214 + c, 255))
    # papel picado flags along the top
    d.line((0, h * 0.06, w, h * 0.06), fill=(80, 80, 80, 255), width=3)
    cols = [RED, TEAL, (112, 128, 214), (240, 196, 40)]
    n = 16
    for k in range(n):
        x0 = k * w / n + 6
        x1 = (k + 1) * w / n - 6
        c = cols[k % 4]
        d.polygon([(x0, h * 0.06), (x1, h * 0.06), (x1, h * 0.16), ((x0 + x1) / 2, h * 0.19), (x0, h * 0.16)], fill=c + (255,))
        for j in range(3):                                 # cut-out holes
            cx = x0 + (x1 - x0) * (0.25 + 0.25 * j)
            d.ellipse((cx - 6, h * 0.10 - 6, cx + 6, h * 0.10 + 6), fill=(246, 238, 214, 255))
    # dashed cut border
    m = 26
    for x in range(m, w - m, 40):
        d.line((x, h * 0.22, x + 22, h * 0.22), fill=TEAL + (255,), width=5)
        d.line((x, h - m, x + 22, h - m), fill=TEAL + (255,), width=5)
    for y in range(int(h * 0.22), h - m, 40):
        d.line((m + 30, y, m + 30, y + 22), fill=TEAL + (255,), width=5)
        d.line((w - m, y, w - m, y + 22), fill=TEAL + (255,), width=5)
    # the sign, left; the offer, right
    lg = C.logo(int(w * 0.36), 0)
    im.paste(lg, (int(w * 0.07), int(h * 0.30)), lg)
    glass(d, w * 0.18, h * 0.80, h * 0.08)
    slab = B.ff("Coustard-Black.ttf", h * 0.20)
    d.text((w * 0.70, h * 0.38), "FREE", font=slab, fill=RED + (255,), anchor="mm")
    d.text((w * 0.70, h * 0.60), "TOP SHELF", font=B.ff("Coustard-Black.ttf", h * 0.115), fill=(30, 30, 40, 255), anchor="mm")
    d.text((w * 0.70, h * 0.76), "MARGARITA", font=B.ff("Coustard-Black.ttf", h * 0.115), fill=(30, 30, 40, 255), anchor="mm")
    d.line((w * 0.47, h * 0.86, w * 0.93, h * 0.86), fill=TEAL + (255,), width=6)
    im = im.filter(ImageFilter.GaussianBlur(0.7))
    B.wear(im, rng, 60, (226, 214, 186))
    return labels.save(im, "cu_coupon_front")


def back_art():
    rng = random.Random(SEED + 1)
    im, d = B.canvas_for(W, L, PPM, (240, 232, 208, 255))
    for k in range(4000):
        x, y = rng.randint(0, im.width - 1), rng.randint(0, im.height - 1)
        d.point((x, y), fill=(226, 218, 194, 255))
    return labels.save(im, "cu_coupon_back")


def build():
    m = mats.M("card", "#f6eed6", 0.75)
    c = mats.decal(m, art(), (0, 0, 0), (W, L), "XY", facing="+Z")
    c = mats.decal(m, back_art(), (0, 0, 0), (W, L), "XY", base=c, flip_u=True, facing="-Z")
    m.bump(m.noise(1200.0, 3.0).outputs["Fac"], 0.12, 0.0002)
    # the leaf: a grid with a torn perforated left edge and a slight curl up at the ends
    rng = random.Random(SEED + 2)
    bm = bmesh.new()
    nx, ny = 24, 10
    vs = []
    for j in range(ny + 1):
        row = []
        for i in range(nx + 1):
            x = -W / 2 + W * i / nx
            y = -L / 2 + L * j / ny
            if i == 0:
                x += rng.uniform(-0.0006, 0.0006) + (0.0005 if j % 2 else -0.0003)   # the torn perforation
            z = 0.0018 * ((x / (W / 2)) ** 2) + 0.0006 * ((y / (L / 2)) ** 2)
            row.append(bm.verts.new((x, y, z)))
        vs.append(row)
    for j in range(ny):
        for i in range(nx):
            bm.faces.new((vs[j][i], vs[j][i + 1], vs[j + 1][i + 1], vs[j + 1][i]))
    ob = core.obj_from_bmesh("coupon", bm, m.mat, smooth=True)
    core.solidify(ob, T, 1.0)
