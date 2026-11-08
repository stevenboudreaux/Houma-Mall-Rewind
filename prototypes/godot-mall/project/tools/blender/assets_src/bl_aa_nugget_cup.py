"""Auntie Anne's cup of pretzel nuggets, to hold (workstream FOOD3D, Nov 8 2026). 2026 only (the tenant).

Steven: today each cup in the warmer is a closed cup with a lump sitting on its lid; make an OPEN cup, the same
size and blue/white colours, filled with pretzel nuggets heaped above the rim and a few spilling; in the case
where the cups are now (bl_aa_nugget_cup_case: this cup plus nuggets spilled round it) and a second variant for
the hand item (this one: the heap, no spill). Item aa_pretzel_nuggets (data/items/food3d.json), the model the
stand-in standin_aa_pretzel_bites waits for.

The cup: a tapered paper cup (top 84 mm, base 64 mm, 80 mm tall: the warmer's old cups), navy with a white band
under a rolled white rim, white inside (plain: no print, IP rule). The nuggets: the warmer's pretzel crust
(bl_aa_warmer.pretzel_mat, golden brown with salt), pillow-shaped ~24 x 19 x 16 mm, a bed of them inside the cup
under a heap that rises ~30 mm over the rim.
References: refs/new/auntie_annes/aa_t000_001-031 (the clip, 144 x 256: navy cups heaped with bites; shapes and
colours only). Guessed: the band, the counts, the inside colour.
Origin: bottom centre of the cup.
"""
import math
import random
from lib import core, parts, mats
import bl_aa_warmer as AW

R0, R1, CH = 0.032, 0.042, 0.080        # base radius, top radius, height
SPILL = False
N_HEAP = 18

META = {
    "id": "bl_aa_nugget_cup",
    "class": "hand",
    "tex": 1024,
    "ao": 0.35,
    "refs": [["refs/new/auntie_annes/aa_t000_013.jpg", [0.0, 0.0, 1.0, 0.7], "the warmer (clip)"]],
    "icon": True,
}


def cup_mat():
    """Navy outside, a white band under the rim (z 0.061-0.075), white rim and inside (by normal: inside faces
    point at the axis)."""
    m = mats.M("cup", "#1d2a6e", 0.55)
    sep = m.node("ShaderNodeSeparateXYZ")
    m.link(m.coords(), sep.inputs[0])
    z = sep.outputs["Z"]
    band = m.math("MULTIPLY", m.math("GREATER_THAN", z, 0.061), m.math("LESS_THAN", z, 0.075))
    rim = m.math("GREATER_THAN", z, 0.0785)
    # inside: the normal points toward the axis (dot of normal and position in XY < 0)
    nn = m.node("ShaderNodeSeparateXYZ")
    m.link(m.node("ShaderNodeTexCoord").outputs["Normal"], nn.inputs[0])
    dot = m.math("ADD", m.math("MULTIPLY", nn.outputs["X"], sep.outputs["X"]), m.math("MULTIPLY", nn.outputs["Y"], sep.outputs["Y"]))
    inside = m.math("LESS_THAN", dot, 0.0)
    white = m.math("MAXIMUM", m.math("MAXIMUM", band, rim), inside)
    col = m.mix(white, "#1d2a6e", "#f4f2ec")
    m.link(col, m.bsdf.inputs["Base Color"])
    m.bump(m.noise(500.0, 2.0).outputs["Fac"], 0.1, 0.0003)
    return m.mat


def cup(mat):
    t = 0.0006
    prof = [(0.0, 0.0), (R0 - 0.002, 0.0), (R0, 0.002), (R1, CH - 0.002), (R1 + 0.0012, CH), (R1 - 0.0005, CH + 0.0016),
            (R1 - 0.0022, CH - 0.0005), (R1 - t - 0.001, CH - 0.004), (R0 - t, 0.006), (0.0, 0.006)]
    return parts.lathe("cup", prof, seg=28, mat=mat, cap=False, sharp_angle=60)


def nugget(name, loc, rnd, mat, s=1.0):
    ob = parts.sphere(name, 0.011 * s, seg=7, rings=5, loc=loc, mat=mat,
                      scale=(rnd.uniform(1.05, 1.25), rnd.uniform(0.85, 1.0), rnd.uniform(0.7, 0.85)))
    ob.rotation_euler = (rnd.uniform(-0.6, 0.6), rnd.uniform(-0.6, 0.6), rnd.uniform(0, 6.28))
    return ob


def heap(nm, rnd, n=N_HEAP):
    """A bed inside the cup and a dome of nuggets over the rim (the bed hides the cup's inside)."""
    bed = parts.lathe("bed", [(0.0, CH - 0.022), (R1 - 0.004, CH - 0.022), (R1 - 0.003, CH - 0.012), (0.0, CH - 0.008)],
                      seg=12, mat=nm, cap=False)
    pts = []
    # layer 1: a ring at the rim; layer 2: an inner ring higher; a crown
    for k in range(9):
        a = math.tau * k / 9 + rnd.uniform(-0.15, 0.15)
        pts.append((0.028 * math.cos(a), 0.028 * math.sin(a), CH - 0.002 + rnd.uniform(-0.002, 0.003)))
    for k in range(6):
        a = math.tau * k / 6 + 0.4 + rnd.uniform(-0.2, 0.2)
        pts.append((0.015 * math.cos(a), 0.015 * math.sin(a), CH + 0.012 + rnd.uniform(-0.002, 0.003)))
    for k in range(n - 15):
        a = math.tau * k / max(1, n - 15) + rnd.uniform(-0.3, 0.3)
        r = 0.007 if n - 15 > 1 else 0.0
        pts.append((r * math.cos(a), r * math.sin(a), CH + 0.023 + rnd.uniform(-0.002, 0.002)))
    for i, p in enumerate(pts):
        nugget("nug%d" % i, p, rnd, nm)


def build():
    rnd = random.Random(31)
    nm = AW.pretzel_mat("nugget", "#b8622a", "#7a3a14", "#f4f0e6")
    cup(cup_mat())
    heap(nm, rnd)
    if SPILL:
        # a few spilled: two on the tier in front, one against the cup's foot, one caught on the rim
        for i, p in enumerate([(-0.052, -0.03, 0.007), (0.046, -0.04, 0.007), (0.02, -0.046, 0.007), (0.044, 0.0, CH + 0.004)]):
            nugget("spill%d" % i, p, rnd, nm)
