"""Cuco's artwork for workstream FOOD's items (not an asset: no META).

Everything is drawn from the store's own traced neon sign, tools/stores/signs/cu_sign.json (made by
make_cucos.py from Steven's photos, design/storefronts/cucos.md "The neon sign"): the script's can outlines
("cans", metres), the glass tube runs inside them ("tubes"), the MEXICAN CAFE letters ("plates") and the
periwinkle cabinet behind them (bar_w x bar_h). The sign is the tenant's own mark, so it may be used.

- `logo(px_w, ...)`: the sign as flat print (red script with a dark drop shadow over the periwinkle bar with
  white letters), RGBA, for the coaster and the coupon.
- `relief(px)`: a height map of the sign for stamping (doubloon): can walls raised, can floors a little
  sunk, the tubes as raised round lines inside, the bar a raised pill with the letters sunk into it.
"""
import json
import os

from PIL import Image, ImageDraw, ImageFilter

from lib import labels

SIGN = os.path.join(labels.PROJ, "tools", "stores", "signs", "cu_sign.json")
RED = (196, 40, 30)
PERI = (112, 128, 214)


def data():
    with open(SIGN) as f:
        return json.load(f)


def bounds(d):
    xs, ys = [], []
    for k in ("cans", "plates"):
        for c in d[k]:
            for l in c["loops"]:
                for x, y in l:
                    xs.append(x)
                    ys.append(y)
    return min(xs), max(xs), min(ys), max(ys)


def bar_box(d):
    """The cabinet behind MEXICAN CAFE: bar_w x bar_h, centred on the letters."""
    xs, ys = [], []
    for c in d["plates"]:
        for l in c["loops"]:
            for x, y in l:
                xs.append(x)
                ys.append(y)
    cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
    return cx - d["bar_w"] / 2, cy - d["bar_h"] / 2, cx + d["bar_w"] / 2, cy + d["bar_h"] / 2


def _frame(d, px_w, pad):
    x0, x1, y0, y1 = bounds(d)
    bx0, by0, bx1, by1 = bar_box(d)
    x0, x1, y0 = min(x0, bx0), max(x1, bx1), min(y0, by0)
    s = (px_w - 2 * pad) / (x1 - x0)
    H = int((y1 - y0) * s + 2 * pad)
    P = lambda p: ((p[0] - x0) * s + pad, (y1 - p[1]) * s + pad)
    return P, s, H


def logo(px_w=1600, pad=30, shadow=True, bar=True):
    d = data()
    P, s, H = _frame(d, px_w, pad)
    im = Image.new("RGBA", (px_w, H), (0, 0, 0, 0))
    dr = ImageDraw.Draw(im)
    if bar:
        bx0, by0, bx1, by1 = bar_box(d)
        a, b = P((bx0, by1)), P((bx1, by0))
        dr.rounded_rectangle((a[0], a[1], b[0], b[1]), radius=(b[1] - a[1]) / 2, fill=PERI + (255,))
        for k in (0, 1):   # the end stripes
            for x in ((a[0] + (b[1] - a[1]) * (0.55 + 0.22 * k)), (b[0] - (b[1] - a[1]) * (0.55 + 0.22 * k))):
                dr.line((x, a[1] + 4, x, b[1] - 4), fill=(255, 255, 255, 255), width=max(2, int(s * 0.012)))
        for c in d["plates"]:
            loops = c["loops"]
            dr.polygon([P(p) for p in loops[0]], fill=(255, 255, 255, 255))
            for l in loops[1:]:
                dr.polygon([P(p) for p in l], fill=PERI + (255,))
    if shadow:
        sh = Image.new("L", im.size, 0)
        sd = ImageDraw.Draw(sh)
        for c in d["cans"]:
            for l in c["loops"]:
                sd.polygon([P(p) for p in l], fill=255)
        off = int(s * 0.03)
        im.paste(Image.new("RGBA", im.size, (40, 10, 8, 255)), (off, off), sh.filter(ImageFilter.GaussianBlur(2)))
    for c in d["cans"]:
        for l in c["loops"]:
            dr.polygon([P(p) for p in l], fill=RED + (255,), outline=(120, 20, 14, 255))
    for t in d["tubes"]:   # the neon, drawn as pale highlights down each run (it reads as the sign)
        dr.line([P(p) for p in t["pts"]], fill=(255, 150, 120, 255), width=max(2, int(s * 0.012)), joint="curve")
    return im


def relief(px_w=1600, pad=30):
    """Grey height map (L): 128 = field. The can floors 112, walls 230, tubes 210 (rounded), bar 190 with
    letters at 140. Returns (image, frame height)."""
    d = data()
    P, s, H = _frame(d, px_w, pad)
    im = Image.new("L", (px_w, H), 128)
    dr = ImageDraw.Draw(im)
    bx0, by0, bx1, by1 = bar_box(d)
    a, b = P((bx0, by1)), P((bx1, by0))
    dr.rounded_rectangle((a[0], a[1], b[0], b[1]), radius=(b[1] - a[1]) / 2, fill=190)
    for c in d["plates"]:
        loops = c["loops"]
        dr.polygon([P(p) for p in loops[0]], fill=140)
        for l in loops[1:]:
            dr.polygon([P(p) for p in l], fill=190)
    wall = max(3, int(s * 0.022))
    for c in d["cans"]:
        for l in c["loops"]:
            dr.polygon([P(p) for p in l], fill=112)
    tub = Image.new("L", im.size, 0)
    td = ImageDraw.Draw(tub)
    for t in d["tubes"]:
        td.line([P(p) for p in t["pts"]], fill=255, width=max(3, int(s * 0.026)), joint="curve")
    tub = tub.filter(ImageFilter.GaussianBlur(max(1, s * 0.006)))     # a rounded profile
    im.paste(210, (0, 0), tub)
    for c in d["cans"]:
        for l in c["loops"]:
            dr.line([P(p) for p in l] + [P(l[0])], fill=230, width=wall, joint="curve")
    return im.filter(ImageFilter.GaussianBlur(0.8)), H


def coaster_art(px=1400, rng_seed=3):
    """A round pulp-board bar coaster: cream, a red ring, the sign in the middle."""
    import random
    rng = random.Random(rng_seed)
    im = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse((0, 0, px - 1, px - 1), fill=(244, 236, 214, 255))
    d.ellipse((px * 0.04, px * 0.04, px * 0.96, px * 0.96), outline=RED + (255,), width=int(px * 0.025))
    d.ellipse((px * 0.075, px * 0.075, px * 0.925, px * 0.925), outline=(40, 120, 110, 255), width=int(px * 0.008))
    lg = logo(int(px * 0.74), 0)
    im.paste(lg, (int((px - lg.width) / 2), int((px - lg.height) / 2)), lg)
    # a damp ring where a glass stood, a few speckles
    ring = Image.new("L", im.size, 0)
    ImageDraw.Draw(ring).ellipse((px * 0.2, px * 0.24, px * 0.82, px * 0.86), outline=60, width=int(px * 0.03))
    im.paste(Image.new("RGBA", im.size, (196, 176, 140, 255)), (0, 0), ring.filter(ImageFilter.GaussianBlur(px * 0.01)))
    for k in range(300):
        x, y = rng.randint(0, px), rng.randint(0, px)
        if (x - px / 2) ** 2 + (y - px / 2) ** 2 < (px * 0.47) ** 2:
            d.point((x, y), fill=(200, 190, 170, 255))
    return im


def coaster(build_parts=True, loc=(0, 0, 0), r=0.050, t=0.0025):
    """The round Cuco's bar coaster (pulp board, the sign printed on it), as a part. Returns its top height."""
    from lib import parts, mats
    im = coaster_art()
    p = labels.save(im, "cu_coaster")
    m = mats.M("coaster", "#f4ecd6", 0.85)
    mats.decal(m, p, (loc[0], loc[1], loc[2] + t), (2 * r, 2 * r), "XY", facing="+Z")
    m.bump(m.noise(900.0, 3.0).outputs["Fac"], 0.25, 0.0003)
    parts.cylinder("coaster", r, t, verts=32, loc=(loc[0], loc[1], loc[2] + t / 2), mat=m.mat, bev=0.0006)
    return loc[2] + t


def salt_rim(name, r, z, mat, seg=40, tube=0.0028, coarse=False):
    """A ring of salt crystals on a glass rim: a lumpy torus (the crystals are in its normal map)."""
    from lib import parts
    import math as _m
    pts = [(r * _m.cos(_m.tau * i / 14), r * _m.sin(_m.tau * i / 14), z) for i in range(14)]
    ob = parts.tube_path(name, pts, tube, seg=6, mat=mat, closed=True)
    return ob


def salt_mat(name="salt", coarse=False):
    from lib import mats
    m = mats.M(name, "#f6f4ee", 0.55)
    v = m.voronoi(900.0 if coarse else 2200.0)
    m.link(m.ramp(v.outputs["Distance"], [(0.0, "#ffffff"), (0.4, "#dcdad4")]), m.bsdf.inputs["Base Color"])
    m.bump(m.math("SUBTRACT", 1.0, v.outputs["Distance"]), 1.0, 0.0010 if coarse else 0.0006)
    return m.mat


def lime_wheel_mat(name, cx, cy, R, rind="#3e8a1e", flesh=("#b6d84a", "#dcef8c")):
    """A citrus wheel face-on (lime by default; orange with other colours)."""
    from lib import mats
    import _food as F
    m = mats.M(name, flesh[0], 0.35, frozen=True)   # built flat at the origin, frozen, then placed
    r, ang = F.disc_mat_radial(m, cx, cy)
    memb = m.math("GREATER_THAN", m.math("ABSOLUTE", m.math("SINE", m.math("MULTIPLY", ang, 5.0))), 0.93)
    pulp = m.noise(900.0, 3.0)
    col = m.ramp(pulp.outputs["Fac"], [(0.35, flesh[0]), (0.65, flesh[1])])
    col = m.mix(memb, col, "#f2f6dc")
    col = m.mix(m.math("GREATER_THAN", r, R * 0.82), col, "#eef4d6")
    col = m.mix(m.math("GREATER_THAN", r, R * 0.92), col, rind)
    m.link(col, m.bsdf.inputs["Base Color"])
    m.bump(pulp.outputs["Fac"], 0.4, 0.0005)
    return m.mat


def citrus_wheel(name, R, t, mat_fn_args, loc, rot):
    """A citrus wheel built flat (radial pattern about its own centre), frozen, then stood on a rim."""
    from lib import parts, core
    m = lime_wheel_mat(name, 0.0, 0.0, R, *mat_fn_args)
    ob = parts.cylinder(name, R, t, verts=28, mat=m, bev=0.0008)
    core.freeze([ob])
    ob.location = loc
    ob.rotation_euler = rot
    return ob
