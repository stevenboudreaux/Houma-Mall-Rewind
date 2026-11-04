"""A cup of lunch-counter coffee from the Woolworth coffee shop (1995 map, store s13). Hand item; item id
`wl_coffee` (workstream FOOD, Nov 3 2026).

1995 lunch-counter style: a heavy thick-walled white diner mug of black coffee (a little foam at the edge, a
sheen on top) on its saucer, with a stainless teaspoon and a paper sugar packet. The back bar has two coffee
urns (tools/stores/woolworth/store.gd) and the menu strip sells COFFEE 59¢ (paint_lunch.py, invented 1995
prices). Plates and cups match the other Woolworth items (white, thin red line on the saucer: guessed).
References: refs/era_1995/stores/Woolworth.jpg (setting only). Guessed: the mug's shape, the packet (generic
"SUGAR", no brand).
Size: mug 92 mm tall, 82 mm across, 9 mm walls at the base; saucer 150 mm.
Origin: bottom centre of the saucer; the handle points right (+X).
"""
import math
from PIL import Image, ImageDraw
from lib import core, parts, mats, labels
import _food as F

SAUCER_R = 0.075
MUG_H, MUG_R = 0.092, 0.041
SZ = 0.017                   # the mug's foot sits in the saucer's well at this height
COFFEE_Z = MUG_H - 0.014

META = {
    "id": "bl_wl_coffee",
    "class": "hand",
    "tex": 1024,
    "ao": 0.4,
    "refs": [["refs/era_1995/stores/Woolworth.jpg", None, "a Woolworth lunch counter (setting)"]],
    "item_file": "food.json",
    "item": {"id": "wl_coffee", "name": "Cup of coffee", "year": 1995, "store": "WOOLWORTH", "price": 59},
}


def packet():
    im, d = labels.canvas(400, 260, (250, 250, 246, 255))
    d.rectangle((0, 0, 400, 26), fill=(196, 40, 44, 255))
    d.rectangle((0, 234, 400, 260), fill=(196, 40, 44, 255))
    labels.text(d, (200, 110), "SUGAR", "bold", 92, (196, 40, 44, 255))
    labels.text(d, (200, 186), "PURE CANE  ·  1 PORTION", "sans", 28, (90, 90, 90, 255))
    for x in range(0, 400, 10):
        d.line((x, 0, x + 5, 6), fill=(220, 220, 214, 255), width=2)
    return labels.save(im, "wl_coffee_packet")


def coffee_mat():
    m = mats.M("coffee", "#1e0e06", 0.04)
    r_, a_ = F.disc_mat_radial(m, 0.0, 0.0)
    n = m.noise(400.0, 3.0)
    foam = m.math("MULTIPLY", m.math("GREATER_THAN", r_, MUG_R - 0.0115), m.math("GREATER_THAN", n.outputs["Fac"], 0.45))
    col = m.ramp(r_, [(0.0, "#1a0b04"), (0.022, "#2a1408"), (0.030, "#4a2410")])
    col = m.mix(foam, col, "#8a5a32")
    m.link(col, m.bsdf.inputs["Base Color"])
    m.bump(n.outputs["Fac"], 0.08, 0.0003)
    return m.mat


def build():
    cer = F.ceramic_mat("china", band=("#b4232a", SAUCER_R * 0.90, SAUCER_R * 0.915))
    # saucer
    parts.lathe("saucer", [(0.0, 0.003), (0.034, 0.003), (0.036, 0.0), (0.042, 0.0), (0.044, 0.004), (0.046, 0.011),
                           (0.062, 0.015), (0.0735, 0.019), (SAUCER_R, 0.0195), (0.0745, 0.0175), (0.062, 0.0125),
                           (0.046, 0.009), (0.044, 0.0085), (0.0, 0.0085)], seg=40, mat=cer, cap=False)
    # the mug: thick wall, a heavy rounded base, a rolled lip
    plain = F.ceramic_mat("mug")
    prof = [(0.0, 0.0025), (0.028, 0.0025), (0.029, 0.0), (0.033, 0.0), (0.0375, 0.006), (0.0395, 0.020),
            (MUG_R, 0.050), (MUG_R + 0.0005, MUG_H - 0.004), (MUG_R - 0.001, MUG_H), (MUG_R - 0.006, MUG_H - 0.0005),
            (MUG_R - 0.0068, MUG_H - 0.006), (MUG_R - 0.0075, 0.040), (0.026, 0.016), (0.012, 0.012), (0.0, 0.0115)]
    parts.lathe("mug", [(r, z + SZ - 0.0085) for r, z in prof], seg=40, mat=plain, cap=False)
    # coffee: a disc a little below the lip, meniscus up the wall
    rr = MUG_R - 0.0072
    parts.lathe("coffee", [(0.0, COFFEE_Z + SZ - 0.0085), (rr - 0.002, COFFEE_Z + SZ - 0.0085), (rr, COFFEE_Z + SZ - 0.0075)],
                seg=40, mat=coffee_mat(), cap=False)
    # the handle: a thick C loop on the right
    zb = SZ - 0.0085
    pts = [(MUG_R - 0.002, 0, zb + 0.070), (MUG_R + 0.016, 0, zb + 0.072), (MUG_R + 0.026, 0, zb + 0.058),
           (MUG_R + 0.025, 0, zb + 0.036), (MUG_R + 0.014, 0, zb + 0.024), (MUG_R - 0.002, 0, zb + 0.022)]
    h = parts.tube_path("handle", pts, 0.0062, seg=10, mat=plain)
    h.scale = (1.0, 1.25, 0.85)          # an oval section, wider than deep
    # the teaspoon on the saucer, in front
    steel = mats.brushed_metal("spoon", "#c9c9cc", 0.28)
    sp_ob = parts.box("spoon_handle", (0.090, 0.006, 0.0016), loc=(-0.010, -0.052, 0.0175), rot=(0, -4, 8), mat=steel, bev=0.0006, seg=1)
    bowl = parts.sphere("spoon_bowl", 0.012, 16, 8, loc=(-0.062, -0.058, 0.0145), mat=steel, scale=(1.35, 0.85, 0.32))
    F.cut(bowl, (-0.062, -0.058, 0.0155), (0, 0, 1), steel)
    # a sugar packet lying on the saucer's rim, back left, tipped to follow the rim's slope
    pm = mats.M("packet", "#fafaf6", 0.6, frozen=True)
    mats.decal(pm, packet(), (0, 0, 0.0015), (0.050, 0.032), "XY", facing="+Z")
    pk = parts.box("packet", (0.050, 0.032, 0.003), loc=(0, 0, 0.0015), mat=pm.mat, bev=0.0010, seg=2)
    core.freeze([pk])
    pk.location = (-0.046, 0.044, 0.0165)
    pk.rotation_euler = (math.radians(-9), math.radians(9), math.radians(35))
