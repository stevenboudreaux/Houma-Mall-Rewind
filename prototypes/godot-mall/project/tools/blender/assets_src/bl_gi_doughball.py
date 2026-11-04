"""A squishy dough stress ball (NeeDoh-type), a games, inc. prize (2026 map; workstream PRIZES, Steven Nov 3
2026). Pocket item, ~300 tickets (design/research/redemption-items.md section 4, T3: the sold-out craze of
late 2025-2026). Generic: a 6.5 cm matte, slightly translucent-looking pastel ball sagging a little under its
own weight, with the faint dimpled skin of the dough inside; no name, no face. Origin: bottom centre.
"""
from lib import core, parts, mats

R = 0.033
COL = "#ffc8dc"

META = {
    "id": "bl_gi_doughball",
    "class": "pocket",
    "tex": 512,
    "ao": 0.3,
    "refs": [],
    "item": {"name": "Squishy dough ball", "year": 2026, "store": "GAMES, INC.", "tickets": 300, "prize": "g_dough_ball"},
}


def build():
    m = mats.M("skin", COL, 0.35)
    v = m.voronoi(260.0)
    m.bump(v.outputs["Distance"], 0.25, 0.0005)
    sh = m.ramp(v.outputs["Distance"], [(0.0, "#f2b0c8"), (0.6, COL)])
    m.link(sh, m.bsdf.inputs["Base Color"])
    m.bsdf.inputs["Subsurface Weight"].default_value = 0.3
    # sagging: wider than tall, flatter underneath
    parts.lathe("ball", [(0.0, 0.0), (0.018, 0.0), (0.03, 0.006), (0.035, 0.02), (0.034, 0.036), (0.026, 0.052), (0.014, 0.06), (0.0, 0.062)], 28, mat=m.mat)
