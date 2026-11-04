"""A Cuco's Mardi Gras doubloon (1995 map, store s42). Hand item; item id `cu_doubloon`
(workstream FOOD, Nov 3 2026).

Steven: a pog-sized metal disc stamped with Cuco's neon-sign logo. Physical facts from
design/research/mardi-gras-doubloons.md: a parade doubloon is struck aluminium, 39 mm across, ~1.5 mm at
the rim, plain edge, the field struck a little below a flat rim, relief never above the rim, often
anodized in the carnival colours (gold here: the oldest anodized colour, in Rex's first order). The note
found no restaurant that issued its own doubloon: a Cuco's doubloon is a plausible invention (a promo).
Obverse: the restaurant's own sign, from tools/stores/signs/cu_sign.json, as the research note proposes:
the script's channel cans as raised walls with their floors struck a little lower, the neon tube runs as
raised round lines inside them, the MEXICAN CAFE cabinet as a raised pill with the letters sunk into it, a
bead border. Reverse: a bead border, a chili pepper and "MARDI GRAS / 1995" (placeholder words for Steven
to change; no krewe emblem, no third-party mark, no mall name).
The relief is in the normal map (baked from a height image through a Bump node); the rim, the sunken field
and the bevelled edge are geometry. Lies flat, obverse up; origin bottom centre.
"""
import math
from PIL import Image, ImageDraw, ImageFilter
from lib import core, parts, mats, labels
import _cucos as C

R = 0.0195                  # 39 mm
T = 0.0015                  # rim thickness
RIM_W = 0.0012
FIELD_DROP = 0.0002         # the field below the rim, each side
RELIEF = 0.00022            # relief height used by the bump
PX = 2048                   # height image size across the coin
GOLD = "#d9b850"

META = {
    "id": "bl_cu_doubloon",
    "class": "hand",
    "tex": 1024,
    "ao": 0.2,
    "refs": [["prototypes/godot-mall/project/tools/stores/signs/src/cucos_front.jpg", None, "Cuco's neon sign (traced)"]],
    "icon_view": (10, 68),
    "item_file": "food.json",
    "item": {"id": "cu_doubloon", "name": "Cuco's doubloon", "year": 1995, "store": "CUCOS"},
}


def beads(d, cx, cy, r, n, rad, fill):
    for k in range(n):
        a = k / n * math.tau
        x, y = cx + r * math.cos(a), cy + r * math.sin(a)
        d.ellipse((x - rad, y - rad, x + rad, y + rad), fill=fill)


def obverse():
    im = Image.new("L", (PX, PX), 128)
    d = ImageDraw.Draw(im)
    c = PX / 2
    pxm = PX / (2 * R)                                   # px per metre
    beads(d, c, c, (R - RIM_W - 0.0009) * pxm, 72, 0.00028 * pxm, 205)
    d.ellipse((c - (R - RIM_W - 0.0016) * pxm, c - (R - RIM_W - 0.0016) * pxm, c + (R - RIM_W - 0.0016) * pxm, c + (R - RIM_W - 0.0016) * pxm), outline=170, width=int(0.0002 * pxm))
    rel, h = C.relief(int(0.028 * pxm), 0)               # the sign 28 mm wide
    im.paste(rel, (int(c - rel.width / 2), int(c - rel.height / 2 + 0.001 * pxm)))
    return im


def reverse():
    im = Image.new("L", (PX, PX), 128)
    d = ImageDraw.Draw(im)
    c = PX / 2
    pxm = PX / (2 * R)
    beads(d, c, c, (R - RIM_W - 0.0009) * pxm, 72, 0.00028 * pxm, 205)
    f1 = labels.font("bold", 0.0042 * pxm)
    f2 = labels.font("bold", 0.0062 * pxm)
    d.text((c, c - 0.0105 * pxm), "MARDI GRAS", font=f1, fill=210, anchor="mm")
    d.text((c, c + 0.0108 * pxm), "1995", font=f2, fill=210, anchor="mm")
    # a chili pepper across the middle: body, a curl at the tip, the cap and stem
    pts = []
    for i in range(41):
        t = i / 40
        x = c + (-0.009 + 0.018 * t) * pxm
        y = c + (0.002 * math.sin(t * math.pi * 1.2) - 0.001) * pxm
        pts.append((x, y))
    for i, (x, y) in enumerate(pts):
        r = (0.0005 + 0.0022 * math.sin(min(1.0, (i / 40) * 1.15) * math.pi * 0.95)) * pxm
        d.ellipse((x - r, y - r, x + r, y + r), fill=215)
    x0, y0 = pts[-1]
    d.ellipse((x0 - 0.0018 * pxm, y0 - 0.0022 * pxm, x0 + 0.0012 * pxm, y0 + 0.0022 * pxm), fill=200)
    d.line((x0, y0, x0 + 0.002 * pxm, y0 - 0.002 * pxm, x0 + 0.003 * pxm, y0 - 0.0015 * pxm), fill=200, width=int(0.0006 * pxm))
    # a highlight groove along the pepper
    d.line(pts[6:34], fill=150, width=int(0.00025 * pxm))
    return im.filter(ImageFilter.GaussianBlur(1.2))


def coin_mat(obv, rev):
    m = mats.M("metal", GOLD, 0.3, 0.75)
    sep = m.node("ShaderNodeSeparateXYZ")
    m.link(m.coords(), sep.inputs[0])
    u = m.math("MULTIPLY_ADD", sep.outputs["X"], 1.0 / (2 * R), 0.5)
    v = m.math("MULTIPLY_ADD", sep.outputs["Y"], 1.0 / (2 * R), 0.5)
    vr = m.math("MULTIPLY_ADD", sep.outputs["X"], -1.0 / (2 * R), 0.5)    # the reverse, seen from below
    cv = m.node("ShaderNodeCombineXYZ")
    m.link(u, cv.inputs[0])
    m.link(v, cv.inputs[1])
    cr = m.node("ShaderNodeCombineXYZ")
    m.link(vr, cr.inputs[0])
    m.link(v, cr.inputs[1])
    hs = []
    for path, vec in ((obv, cv), (rev, cr)):
        t = m.node("ShaderNodeTexImage")
        t.image = bpy.data.images.load(path, check_existing=True)
        t.image.colorspace_settings.name = "Non-Color"
        t.extension = "EXTEND"
        m.link(vec.outputs[0], t.inputs["Vector"])
        hs.append(t.outputs["Color"])
    nz = m.node("ShaderNodeSeparateXYZ")
    m.link(m.node("ShaderNodeTexCoord").outputs["Normal"], nz.inputs[0])
    up = m.math("GREATER_THAN", nz.outputs["Z"], 0.5)
    down = m.math("LESS_THAN", nz.outputs["Z"], -0.5)
    hsel = m.mix(down, m.mix(up, "#808080", hs[0]), hs[1])
    hb = m.node("ShaderNodeRGBToBW")
    m.link(hsel, hb.inputs[0])
    h = hb.outputs[0]
    # anodized gold: deeper and more saturated in the recesses, bright on the relief tops
    col = m.ramp(h, [(0.40, "#9a7a24"), (0.50, "#c8a440"), (0.80, "#f2dc84")])
    m.link(col, m.bsdf.inputs["Base Color"])
    m.link(m.ramp(h, [(0.40, (0.45, 0.45, 0.45, 1)), (0.50, (0.32, 0.32, 0.32, 1)), (0.80, (0.16, 0.16, 0.16, 1))]), m.bsdf.inputs["Roughness"])
    m.bump(h, 1.0, RELIEF * 4)
    return m.mat


import bpy  # noqa: E402  (after the module docstring imports, for the image loader above)


def build():
    po = labels.save(obverse(), "cu_doubloon_obv")
    pr = labels.save(reverse(), "cu_doubloon_rev")
    m = coin_mat(po, pr)
    rf = R - RIM_W
    prof = [(0.0, FIELD_DROP), (rf - 0.0003, FIELD_DROP), (rf, 0.0), (R - 0.0001, 0.0), (R, 0.0001), (R, T - 0.0001), (R - 0.0001, T),
            (rf, T), (rf - 0.0003, T - FIELD_DROP), (0.0, T - FIELD_DROP)]
    parts.lathe("coin", prof, seg=64, mat=m, cap=False, sharp_angle=30)
