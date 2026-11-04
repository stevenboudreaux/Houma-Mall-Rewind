"""A round squish-type plush (an 8 in stuffed ball-animal), a games, inc. prize (2026 map; workstream PRIZES,
Steven Nov 3 2026). Hand item, ~1,200 tickets (design/research/redemption-items.md section 4, T4: the type's
boom from 2020). Generic, no brand marks or tag: a soft, nearly spherical body flattened on the bottom, two
small rounded ears, tiny stubby arms, simple stitched eyes, rosy cheeks and a small smile on the front.
About 20 cm across. The fur bakes near-white with a soft velour pile, so the counter tints it to its
colour cycle (scripts/prize_units.gd TINT); the face stays dark. The 16 in and jumbo sizes on the wall are
the same model scaled (prize_units.gd BLENDER). Origin: bottom centre, facing Godot +Z.
"""
import math
from lib import core, parts, mats

R = 0.1
FUR = "#f4f2ee"

META = {
    "id": "bl_gi_squish",
    "class": "hand",
    "tex": 512,
    "ao": 0.4,
    "refs": [],
    "item": {"name": "Round plush", "year": 2026, "store": "GAMES, INC.", "tickets": 1200, "prize": "g_squish"},
}


def velour(name, base):
    m = mats.M(name, base, 0.95)
    n = m.noise(1400.0, 3.0, 0.6)
    m.bump(n.outputs["Fac"], 0.3, 0.0006)
    sh = m.ramp(n.outputs["Fac"], [(0.2, "#dcd8d0"), (0.85, base)])
    m.link(sh, m.bsdf.inputs["Base Color"])
    return m.mat


def build():
    fur = velour("fur", FUR)
    face = mats.flat("face", "#1a1416", 0.6, bake=False)
    cheek = mats.flat("cheek", "#f2a0b4", 0.8, bake=False)
    # the body: a sphere squashed a little, flat-ish at the bottom
    parts.lathe("body", [(0.0, 0.0), (0.06, 0.0), (0.085, 0.012), (0.098, 0.04), (0.1, 0.075), (0.093, 0.115), (0.072, 0.15), (0.04, 0.17), (0.0, 0.176)], 28, mat=fur)
    for sx in (-1, 1):
        ob = parts.sphere("ear", 1.0, 12, 6, loc=(sx * 0.055, 0.0, 0.163), mat=fur, scale=(0.026, 0.016, 0.022))
        parts.sphere("arm", 1.0, 10, 6, loc=(sx * 0.07, -0.06, 0.05), mat=fur, scale=(0.022, 0.018, 0.016))
        # eyes: short stitched arcs, closed-happy
        parts.tube_path("eye", [(sx * 0.044, -0.088, 0.103), (sx * 0.034, -0.0915, 0.110), (sx * 0.024, -0.093, 0.103)], 0.0022, 4, mat=face)
        parts.sphere("cheek", 1.0, 10, 5, loc=(sx * 0.052, -0.082, 0.086), mat=cheek, scale=(0.012, 0.004, 0.008))
    parts.tube_path("smile", [(-0.008, -0.0955, 0.091), (0.0, -0.0965, 0.086), (0.008, -0.0955, 0.091)], 0.0016, 4, mat=face)
