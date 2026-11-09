"""A chocolate-chip cookie from Great American Cookie Co., to hold (workstream FOOD3D, Nov 8 2026). Both years.

The case's chocolate-chip cookie (bl_gac_cookies "cc", same dough and chips) at hand-item detail: a finer
outline (40 segments), more chips, lying on a square of white bakery tissue as handed over the counter.
Item gac_choc_chip_cookie (data/items/food3d.json): the model the stand-in standin_gac_choc_chip_cookie waits
for (the shop's list, data/story/shops.json, still names the stand-in: the integration session swaps it).

References: refs/new/cookie_co/gacc_t000_136 (the case's cookies, video), as bl_gac_cookies. Size: 92 mm x 12 mm;
the tissue 150 mm square. Guessed: the tissue (no bag documented; the sugar cookie's sleeve is T2's guess too).
Origin: bottom centre of the tissue.
"""
import math
import random
import bmesh
from lib import core, parts, mats
import bl_gac_cookies as CK

META = {
    "id": "bl_gac_choc_chip_cookie",
    "class": "hand",
    "tex": 1024,
    "ao": 0.3,
    "refs": [["refs/new/cookie_co/gacc_t000_136.jpg", [0.1, 0.0, 0.8, 0.6], "gacc 136 (video, trays)"]],
    "icon": True,
    "icon_view": (20, 50),
}


def tissue():
    """A 150 mm square of tissue, slightly crumpled, corners lifting."""
    bm = bmesh.new()
    n = 10
    s = 0.15
    rnd = random.Random(3)
    vs = [[bm.verts.new((-s / 2 + s * i / n, -s / 2 + s * j / n, 0.0004)) for i in range(n + 1)] for j in range(n + 1)]
    for j in range(n + 1):
        for i in range(n + 1):
            v = vs[j][i]
            e = max(abs(v.co.x), abs(v.co.y)) / (s / 2)
            v.co.z += max(0.0, e - 0.65) ** 2 * 0.02 + rnd.uniform(0, 0.0012) * e
    for j in range(n):
        for i in range(n):
            bm.faces.new((vs[j][i], vs[j][i + 1], vs[j + 1][i + 1], vs[j + 1][i]))
    m = mats.M("tissue", "#f7f5ef", 0.85)
    nn = m.noise(500.0, 3.0)
    m.bump(nn.outputs["Fac"], 0.2, 0.0003)
    ob = core.obj_from_bmesh("tissue", bm, m.mat, smooth=True)
    core.solidify(ob, 0.0003, 1.0)
    ob.rotation_euler.z = math.radians(12)
    return ob


def build():
    tissue()
    rnd = random.Random(1)
    m = CK.dough("dough", 0.0, 0.0, CK.R, CK.GOLD)
    ck = CK.body("cookie", 0.0, 0.0, m.mat, seg=40, seed=1)
    ck.location.z = 0.0012
    cm = CK.chip_mat("chips", "#3a2010")
    for i, (px, py, r) in enumerate(CK.scatter(0.0, 0.0, 18, CK.R * 0.84, rnd, 0.008)):
        CK.chip("chip%d" % i, px, py, CK.top_z(r) - 0.0012 + 0.0012, rnd.uniform(0.0034, 0.0048), cm, rnd, verts=6)
