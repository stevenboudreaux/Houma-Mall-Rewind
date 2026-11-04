"""Shared parts for the Cuco's back-bar kit (workstream FOOD, Nov 3 2026). Not an asset (no META).

Bottles (glass shell as a transparent glTF material per colour, the liquid and labels baked), pour spouts,
invented labels (IP rule: every brand here is made up), glassware profiles. The kit's assets are
bl_cu_bb_*.py; the placement note is in design/storefronts/cucos-back-bar-kit.md.
Bottles are built at the origin (labels wrap by angle round their own axis), frozen, then moved.
"""
import math
import random

import bmesh
from PIL import Image, ImageDraw, ImageFilter

from lib import core, parts, mats, labels
import _food as F
import _book as B

# bottle profiles (radius, height), bottom to the lip; "label" = (z0, z1) of the label band
SHAPES = {
    "tall":    {"p": [(0.034, 0.0), (0.036, 0.004), (0.036, 0.200), (0.033, 0.222), (0.016, 0.246), (0.0125, 0.258), (0.0125, 0.296), (0.0138, 0.300)], "label": (0.060, 0.170)},
    "shoulder": {"p": [(0.040, 0.0), (0.042, 0.004), (0.042, 0.160), (0.038, 0.182), (0.018, 0.204), (0.0140, 0.214), (0.0140, 0.256), (0.0152, 0.260)], "label": (0.045, 0.140)},
    "taper":   {"p": [(0.040, 0.0), (0.043, 0.004), (0.039, 0.165), (0.030, 0.198), (0.0145, 0.222), (0.0125, 0.232), (0.0125, 0.268), (0.0138, 0.272)], "label": (0.050, 0.150)},
    "squat":   {"p": [(0.044, 0.0), (0.047, 0.004), (0.047, 0.110), (0.040, 0.136), (0.016, 0.152), (0.0140, 0.160), (0.0140, 0.188), (0.0150, 0.191)], "label": (0.030, 0.095)},
    "flask":   {"p": [(0.030, 0.0), (0.033, 0.004), (0.034, 0.150), (0.030, 0.170), (0.014, 0.190), (0.0120, 0.198), (0.0120, 0.236), (0.0132, 0.240)], "label": (0.040, 0.130)},
}

# invented bottles: (name lines, sub line, shape, glass colour, liquid colour, label colours (bg, ink, accent))
BOTTLES = [
    (("CAMINO", "BLANCO"), "TEQUILA 100% AGAVE", "taper", "clear", "#eef0ea", ((246, 242, 230), (30, 70, 60), (190, 40, 30))),
    (("TÍO", "RAMÓN"), "TEQUILA REPOSADO", "taper", "clear", "#d8a040", ((30, 40, 70), (240, 220, 160), (200, 160, 60))),
    (("BAYOU", "AÑEJO"), "TEQUILA AÑEJO", "squat", "clear", "#b06a20", ((20, 20, 20), (220, 190, 110), (150, 30, 30))),
    (("GULFSTAR",), "VODKA", "tall", "clear", "#f2f4f4", ((210, 230, 240), (20, 50, 110), (180, 30, 40))),
    (("OLD PIROGUE",), "KENTUCKY WHISKEY", "shoulder", "amber", "#a0581a", ((236, 222, 190), (60, 30, 16), (150, 30, 20))),
    (("PELICAN",), "GOLD RUM", "shoulder", "clear", "#c0781e", ((250, 230, 150), (20, 60, 90), (210, 80, 30))),
    (("NARANJA",), "TRIPLE SEC", "flask", "clear", "#f4f2e8", ((240, 140, 30), (255, 255, 255), (40, 90, 40))),
    (("KREWE",), "LONDON DRY GIN", "tall", "green", "#eaf2ea", ((240, 240, 236), (30, 80, 50), (120, 30, 90))),
    (("SEÑORITA",), "CAFÉ LICOR", "squat", "amber", "#2a1408", ((40, 24, 14), (230, 200, 140), (180, 40, 30))),
    (("BLUE HERON",), "BLUE CURAÇAO", "flask", "clear", "#2a64d8", ((250, 250, 250), (30, 60, 160), (220, 180, 40))),
    (("ATCHAFALAYA",), "SPICED RUM", "taper", "amber", "#7a3c12", ((20, 20, 24), (230, 180, 70), (190, 50, 30))),
    (("LAS PALMAS",), "MEZCAL", "shoulder", "green", "#e8e4d0", ((230, 216, 180), (80, 50, 20), (40, 110, 60))),
]

GLASS = {"clear": "#eef4f2", "amber": "#a85a12", "green": "#2f7a3e"}
GLASS_A = {"clear": 0.18, "amber": 0.62, "green": 0.55}


def label_art(name, sub, shape, cols, seed):
    """A label, flat: the width is the label's arc (about 120 degrees of the bottle), wrapped by angle."""
    rng = random.Random(seed)
    w, h = 900, int(900 * 0.9) if shape != "squat" else 700
    bg, ink, acc = cols
    im = Image.new("RGBA", (w, h), bg + (255,))
    d = ImageDraw.Draw(im)
    d.rectangle((14, 14, w - 14, h - 14), outline=acc + (255,), width=10)
    d.rectangle((34, 34, w - 34, h - 34), outline=ink + (255,), width=3)
    # an emblem: a sun, an agave, a star, a bird... picked by seed, drawn simply
    cx, cy, r = w / 2, h * 0.30, h * 0.14
    kind = seed % 4
    if kind == 0:     # sun
        for k in range(16):
            a = k / 16 * math.tau
            d.line((cx, cy, cx + r * 1.4 * math.cos(a), cy + r * 1.4 * math.sin(a)), fill=acc + (255,), width=8)
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=acc + (255,), outline=ink + (255,), width=4)
    elif kind == 1:   # agave
        for k in range(9):
            a = math.radians(-160 + k * 17.5)
            d.polygon([(cx - 10, cy + r), (cx + 10, cy + r), (cx + r * 1.5 * math.cos(a), cy + r + r * 1.5 * math.sin(a))], fill=acc + (255,))
    elif kind == 2:   # star in a ring
        d.ellipse((cx - r, cy - r, cx + r, cy + r), outline=acc + (255,), width=8)
        pts = [(cx + (r * 0.8 if k % 2 == 0 else r * 0.35) * math.cos(k / 10 * math.tau - math.pi / 2),
                cy + (r * 0.8 if k % 2 == 0 else r * 0.35) * math.sin(k / 10 * math.tau - math.pi / 2)) for k in range(10)]
        d.polygon(pts, fill=acc + (255,))
    else:             # a crest: a shield with a chevron
        d.polygon([(cx - r, cy - r), (cx + r, cy - r), (cx + r, cy + r * 0.2), (cx, cy + r * 1.2), (cx - r, cy + r * 0.2)], fill=acc + (255,), outline=ink + (255,))
        d.line((cx - r * 0.8, cy + r * 0.3, cx, cy - r * 0.3, cx + r * 0.8, cy + r * 0.3), fill=bg + (255,), width=14)
    f = B.ff("Cinzel-Bold.ttf", h * (0.15 if len(name) == 1 else 0.12))
    for i, s in enumerate(name):
        d.text((w / 2, h * (0.58 + i * 0.14) - (0.04 * h if len(name) == 1 else 0.07 * h)), s, font=f, fill=ink + (255,), anchor="mm")
    d.text((w / 2, h * 0.82), sub, font=B.ff("Oswald-Bold.ttf", h * 0.07), fill=acc + (255,), anchor="mm")
    d.text((w / 2, h * 0.90), "750 ML  ·  80 PROOF", font=B.ff("Oswald-Light.ttf", h * 0.045), fill=ink + (255,), anchor="mm")
    im = im.filter(ImageFilter.GaussianBlur(0.6))
    return labels.save(im, "cu_label_%d" % seed)


def arc_band(name, r, z0, z1, a0, a1, mat, seg=10):
    """A partial cylinder band (the label), angles in radians (-pi/2 = the front, -Y)."""
    bm = bmesh.new()
    lo, hi = [], []
    for i in range(seg + 1):
        a = a0 + (a1 - a0) * i / seg
        lo.append(bm.verts.new((r * math.cos(a), r * math.sin(a), z0)))
        hi.append(bm.verts.new((r * math.cos(a), r * math.sin(a), z1)))
    for i in range(seg):
        bm.faces.new((lo[i], lo[i + 1], hi[i + 1], hi[i]))
    ob = core.obj_from_bmesh(name, bm, mat, smooth=True)
    core.solidify(ob, 0.0003, 1.0)
    return ob


def label_mat(name, png, z0, z1, a0, a1):
    """The label image across the arc a0..a1 and z0..z1 (frozen coords: the bottle moves after)."""
    m = mats.M(name, "#f0ece0", 0.55, frozen=True)
    sep = m.node("ShaderNodeSeparateXYZ")
    m.link(m.coords(), sep.inputs[0])
    ang = m.math("ARCTAN2", sep.outputs["Y"], sep.outputs["X"])
    u = m.math("MULTIPLY_ADD", ang, 1.0 / (a1 - a0), -a0 / (a1 - a0))
    v = m.math("MULTIPLY_ADD", sep.outputs["Z"], 1.0 / (z1 - z0), -z0 / (z1 - z0))
    cv = m.node("ShaderNodeCombineXYZ")
    m.link(u, cv.inputs[0])
    m.link(v, cv.inputs[1])
    import bpy
    t = m.node("ShaderNodeTexImage")
    t.image = bpy.data.images.load(png, check_existing=True)
    t.extension = "EXTEND"
    m.link(cv.outputs[0], t.inputs["Vector"])
    m.link(t.outputs["Color"], m.bsdf.inputs["Base Color"])
    m.bump(m.noise(800.0, 2.0).outputs["Fac"], 0.05, 0.0002)
    return m.mat


_glass_cache = {}
_shared = {}


def glass_mat(kind):
    if kind not in _glass_cache:
        _glass_cache[kind] = mats.clear_plastic("glass_" + kind, GLASS[kind], GLASS_A[kind], 0.05)
    return _glass_cache[kind]


def shared_mats():
    if not _shared:
        _shared["steel"] = mats.brushed_metal("steel", "#c4c6ca", 0.26, along="Z", metal=0.75)
        _shared["cap"] = mats.M("cap", "#1a1a1a", 0.4, frozen=True).mat
    return _shared


def r_at(prof, z):
    for (r0, z0), (r1, z1) in zip(prof, prof[1:]):
        if z0 <= z <= z1:
            return r0 + (r1 - r0) * (z - z0) / max(1e-9, z1 - z0)
    return prof[-1][0]


def bottle(i, loc, yaw=0.0, fill=0.75, spout=True, seg=18, scale=1.0):
    """Bottle number i of BOTTLES at loc (its bottom centre), label facing -Y turned by yaw (degrees)."""
    name, sub, shape, gk, liq, cols = BOTTLES[i % len(BOTTLES)]
    S = SHAPES[shape]
    prof = [(r * scale, z * scale) for r, z in S["p"]]
    objs = []
    g = parts.lathe("bottle%d" % i, [(0.0, 0.002)] + prof, seg=seg, mat=glass_mat(gk), cap=False)
    objs.append(g)
    # the liquid: a slightly smaller solid up to the fill level (the bottom of the neck at most)
    top = prof[-1][1]
    lz = 0.006 + (top * 0.82 - 0.006) * fill
    lp = [(0.0, 0.006)] + [(max(0.0, r_at(prof, z) - 0.0025), z) for z in [0.008] + [z for _, z in prof if 0.008 < z < lz] + [lz]] + [(0.0, lz)]
    lm = mats.M("liq%d" % i, liq, 0.05, frozen=True)
    objs.append(parts.lathe("liq%d" % i, lp, seg=max(10, seg - 4), mat=lm.mat))
    # the label on the front
    z0, z1 = (S["label"][0] * scale, S["label"][1] * scale)
    rr = max(r_at(prof, z0), r_at(prof, z1)) + 0.0004
    a0, a1 = -math.pi / 2 - 1.05, -math.pi / 2 + 1.05
    png = label_art(name, sub, shape, cols, i)
    objs.append(arc_band("label%d" % i, rr, z0, z1, a0, a1, label_mat("label%d" % i, png, z0, z1, a0, a1)))
    sh = shared_mats()
    rn = prof[-1][0]
    if spout:   # a steel bar pour spout in a black rubber collar
        objs.append(parts.cylinder("collar%d" % i, rn + 0.0008, 0.016, verts=12, loc=(0, 0, top + 0.002), mat=sh["cap"], bev=0.0008))
        objs.append(parts.cylinder("spout%d" % i, 0.0032, 0.052, verts=8, loc=(0, -0.010, top + 0.030), rot=(-30, 0, 0), mat=sh["steel"], bev=0))
    else:
        objs.append(parts.cylinder("cap%d" % i, rn + 0.0012, 0.020, verts=14, loc=(0, 0, top + 0.008), mat=sh["cap"], bev=0.0012))
    core.freeze(objs)
    for o in objs:
        o.rotation_euler = (0, 0, math.radians(yaw))
        o.location = loc
    return objs


def margarita_profile(s=1.0):
    """The house margarita glass (bl_cu_margarita's profile), as one thin shell, scaled."""
    P = [(0.040, 0.0), (0.041, 0.003), (0.036, 0.006), (0.008, 0.012), (0.0055, 0.020), (0.0050, 0.060), (0.0065, 0.072),
         (0.016, 0.080), (0.024, 0.088), (0.028, 0.096), (0.030, 0.104), (0.034, 0.110), (0.046, 0.122), (0.055, 0.140),
         (0.0585, 0.160), (0.059, 0.165), (0.0565, 0.164), (0.053, 0.142), (0.044, 0.124), (0.032, 0.112), (0.026, 0.098),
         (0.018, 0.086), (0.0, 0.078)]
    return [(r * s, z * s) for r, z in P]


def mug_profile():
    R, H = 0.043, 0.160
    return [(0.0, 0.0), (R - 0.003, 0.0), (R, 0.004), (R + 0.0015, 0.05), (R + 0.0015, H - 0.03), (R, H - 0.002), (R - 0.0012, H),
            (R - 0.0034, H - 0.0006), (R - 0.004, H - 0.004), (R - 0.004, 0.020), (R - 0.007, 0.016), (0.0, 0.016)]


def pint_profile():
    return [(0.0, 0.0), (0.028, 0.0), (0.030, 0.004), (0.031, 0.020), (0.0415, 0.140), (0.0425, 0.150), (0.0395, 0.1495),
            (0.0385, 0.140), (0.0275, 0.024), (0.026, 0.010), (0.0, 0.010)]
