"""A 1995 cordless phone: the handset standing in its charging base (RadioShack, 1995 map). Hand item.

Reference: the 1999 video's phone wall and the white phones on the counter (refs/new/radioshack_1999/
0:44-1:00, 2:40); 1995 cordless phones were mostly 46/49 MHz, some of the first 900 MHz: an off-white
handset with a stubby antenna, 12-key pad plus TALK / FLASH / CHAN, earpiece slots, in a slanted base with
a red charge light. Shape guessed from the period type; brand invented (BAYOU COM).
Origin: bottom centre of the base, front facing Godot +Z.
"""
import math
from lib import core, parts, mats, labels

HS = (0.052, 0.030, 0.190)         # handset w, d, h
BASE = (0.110, 0.150, 0.050)       # base w, d, h (slanted top)
TILT = 18.0                        # handset leans back (degrees)
SHELL = "#e8e2d2"                  # warm off-white plastic
KEYS = "#d3cdbd"

META = {
    "id": "bl_rs_cordless",
    "class": "hand",
    "tex": 1024,
    "ao": 0.4,
    "refs": [["refs/new/radioshack_1999/christmas-shopping-at-radioshack-in-1999_t000_156.jpg", [0.0, 0.0, 0.65, 1.0], "RS 1999 2:35 (phones)"]],
    "item": {"name": "Cordless phone", "year": 1995, "store": "RADIO SHACK"},
}


def art():
    keys = [["TALK", "FLASH", "CHAN"], ["1", "2 ABC", "3 DEF"], ["4 GHI", "5 JKL", "6 MNO"], ["7 PRS", "8 TUV", "9 WXY"], ["*", "0 OPER", "#"]]
    im, d = labels.canvas(780, 1000)
    for r, row in enumerate(keys):
        for c, k in enumerate(row):
            big = k.split(" ")[0]
            if len(big) <= 1:
                labels.text(d, (130 + c * 260, 85 + r * 200), big, "sans", 92, (40, 40, 44, 255))
                if " " in k:
                    labels.text(d, (130 + c * 260, 150 + r * 200), k.split(" ")[1], "sans", 40, (70, 70, 74, 255))
            else:
                labels.text(d, (130 + c * 260, 100 + r * 200), big, "sans", 56, (170, 30, 30, 255) if big == "TALK" else (40, 40, 44, 255))
    legends = labels.save(im, "rs_cordless_keys")
    im, d = labels.canvas(800, 200)
    labels.text(d, (400, 100), "BAYOU COM", "bold", 120, (120, 116, 106, 255))
    brand = labels.save(im, "rs_cordless_brand")
    return legends, brand


def build():
    legends, brand = art()
    w, d, h = HS
    shell = mats.M("shell", SHELL, 0.42, frozen=True)
    shell.bump(shell.noise(700.0, 2.0).outputs["Fac"], 0.04, 0.0003)
    # handset parts are built upright at the origin, then tilted and set into the base
    hs = []
    hs.append(parts.rounded_panel("handset", w, h, d, 0.012, 5, loc=(0, 0, h / 2), mat=shell.mat, bev=0.002))
    mk = mats.M("keys", KEYS, 0.5, frozen=True)
    mats.decal(mk, legends, (0, 0, 0.088), (0.042, 0.054), "XZ")
    hs.append(parts.keypad("keypad", rows=5, cols=3, key=(0.0115, 0.0075, 0.0022), pitch=(0.0138, 0.0108),
                           loc=(0, -d / 2 + 0.0002, 0.088), rot=(90, 0, 0), mat=mk.mat, bev=0.0009))
    mb = mats.M("brandplate", SHELL, 0.42, frozen=True)
    mats.decal(mb, brand, (0, 0, 0.135), (0.032, 0.008), "XZ")
    hs.append(parts.box("brandplate", (0.034, 0.0004, 0.009), loc=(0, -d / 2 - 0.0001, 0.135), mat=mb.mat, bev=0))
    hs.append(parts.grille("earpiece", 0.024, 0.010, slots=6, slot_w=0.0016, depth=0.0010, loc=(0, -d / 2 - 0.0003, 0.170),
                           mat=mats.flat("ear", "#b9b3a3", 0.5)))
    hs.append(parts.cylinder("mic", 0.0016, 0.002, 8, loc=(0, -d / 2, 0.022), rot=(90, 0, 0), mat=mats.flat("mic", "#3a3836", 0.6), bev=0))
    hs.append(parts.antenna("antenna", 0.0045, 0.0035, 0.045, 2, loc=(0.016, 0.004, h - 0.003), mat=mats.flat("ant", "#2b2a28", 0.6)))
    # tilt the handset back and seat it in the base's well
    core.freeze(hs)
    for o in hs:
        o.rotation_euler = (math.radians(-TILT), 0, 0)
        o.location = (0, 0.020, 0.018)
    # base: a wedge, high at the back
    bw, bd, bh = BASE
    bshell = mats.M("baseshell", SHELL, 0.42)
    bshell.bump(bshell.noise(700.0, 2.0).outputs["Fac"], 0.04, 0.0003)
    base = parts.box("base", (bw, bd, bh), loc=(0, 0.020, bh / 2), mat=bshell.mat, bev=0.004, seg=3)
    # slant the top by moving the front-top edge down (the box is still unmodified geometry)
    for v in base.data.vertices:
        if v.co.z > 0 and v.co.y < 0:
            v.co.z -= 0.022
    parts.box("well", (w + 0.010, d + 0.010, 0.010), loc=(0, 0.020, bh - 0.001), mat=mats.flat("well", "#cfc9b9", 0.5), bev=0.002)
    parts.cylinder("led", 0.0022, 0.002, 10, loc=(0.036, 0.020 - bd / 2 + 0.018, bh - 0.016), rot=(-30, 0, 0),
                   mat=mats.flat("led", "#c81e1e", 0.2), bev=0)
    for x in (-0.045, 0.045):
        for y in (-0.040, 0.080):
            parts.cylinder("foot", 0.006, 0.002, 10, loc=(x, y, 0.001), mat=mats.flat("feet", "#2a2a2a", 0.8), bev=0)
