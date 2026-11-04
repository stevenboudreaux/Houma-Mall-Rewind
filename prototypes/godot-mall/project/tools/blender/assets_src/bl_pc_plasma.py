"""A plasma ball, a Pocket Change top-shelf prize (1995 map; workstream PRIZES, Steven Nov 3 2026). Hand
item, 1,500-2,500 tickets (design/research/redemption-items.md T4: an 80s novelty, still sold). Generic:
a 15 cm clear globe on a black base with a small grille and a switch, a dark glass electrode in the middle
and violet light filaments to the glass (flat, unbaked, so they keep their colour). Origin: bottom centre.
"""
import math
from lib import core, parts, mats

R = 0.075
BASE_H = 0.07

META = {
    "id": "bl_pc_plasma",
    "class": "hand",
    "tex": 512,
    "ao": 0.35,
    "refs": [],
    "item": {"name": "Plasma ball", "year": 1995, "store": "POCKET CHANGE", "tickets": 2000, "prize": "plasma"},
}


def build():
    base = mats.plastic("base", "#141418", 0.35, 0.03)
    trim = mats.brushed_metal("trim", "#b8b8c0")
    glass = mats.clear_plastic("glass", "#e8dcff", 0.25, 0.05)
    core_m = mats.flat("core", "#2a1a3a", 0.2)
    bolt = mats.flat("bolt", "#d07cff", 0.4, bake=False)
    parts.lathe("base", [(0.0, 0.0), (0.06, 0.0), (0.062, 0.006), (0.05, BASE_H - 0.01), (0.04, BASE_H), (0.0, BASE_H)], 28, mat=base)
    parts.lathe("ring", [(0.038, BASE_H - 0.002), (0.044, BASE_H), (0.044, BASE_H + 0.006), (0.036, BASE_H + 0.008)], 28, mat=trim, cap=False)
    parts.box("switch", (0.012, 0.006, 0.008), loc=(0, -0.056, 0.02), mat=trim, bev=0.001)
    c = (0, 0, BASE_H + R - 0.004)
    parts.sphere("glass", R, 28, 14, loc=c, mat=glass)
    parts.sphere("core", 0.016, 16, 8, loc=c, mat=core_m)
    rng = [0.3, 1.4, 2.6, 3.5, 4.4, 5.6, 0.9, 2.1]
    for i, th in enumerate(rng):
        ph = 0.5 + (i % 4) * 0.55
        end = (c[0] + math.cos(th) * math.sin(ph) * (R - 0.003), c[1] + math.sin(th) * math.sin(ph) * (R - 0.003), c[2] + math.cos(ph) * (R - 0.003))
        mid = tuple(c[q] + (end[q] - c[q]) * 0.5 + (0.006 if q == i % 3 else -0.004) for q in range(3))
        parts.tube_path("bolt", [(c[0], c[1], c[2]), mid, end], 0.0012, 4, mat=bolt, taper=[1.0, 0.7, 0.4])
