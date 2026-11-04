"""A draft beer at Cuco's Mexican Cafe's bar (1995 map, store s42). Hand item; item id `cu_beer`
(workstream FOOD, Nov 3 2026).

A heavy dimpled-free glass beer mug (the bar's taps pour draft; see the back-bar kit, bl_cu_backbar_*) of
pale golden lager with a two-finger head, a few bubbles rising, condensation beading on the cold glass, on
Cuco's own round bar coaster printed with the restaurant's neon-sign logo (the tenant's own mark, drawn from
tools/stores/signs/cu_sign.json). No beer brand anywhere (IP rule).
References: design/storefronts/cucos.md (the bar down the right wall at the back, red stools, a back bar of
bottles); no photo of the drinks. Guessed: the mug, the coaster.
Size: a 20 oz mug, 160 mm tall, 86 mm across; coaster 100 mm.
Materials: the glass and the droplets are their own transparent glTF materials (not baked); the beer, head
and coaster are in the atlas. Origin: bottom centre of the coaster; the handle points right (+X).
"""
import math
import random
from lib import core, parts, mats
import _food as F
import _cucos as C

H, R = 0.160, 0.043
WALL = 0.004
BASE = 0.016                # the mug's heavy glass base
BEER_TOP = H - 0.026
SEED = 13

META = {
    "id": "bl_cu_beer",
    "class": "hand",
    "tex": 1024,
    "ao": 0.35,
    "refs": [],
    "item_file": "food.json",
    "item": {"id": "cu_beer", "name": "Draft beer", "year": 1995, "store": "CUCOS"},
}


def build():
    rng = random.Random(SEED)
    z0 = C.coaster()
    glass = mats.clear_plastic("glass", "#f2f8f6", 0.16, 0.06)
    # the mug: outer wall with a slight barrel, thick base, inner wall
    out = [(R - 0.003, 0.0), (R, 0.004), (R + 0.0015, 0.05), (R + 0.0015, H - 0.03), (R, H - 0.002), (R - 0.0012, H),
           (R - WALL + 0.0006, H - 0.0006), (R - WALL, H - 0.004), (R - WALL, BASE + 0.004), (R - WALL - 0.003, BASE), (0.0, BASE)]
    parts.lathe("mug", [(0.0, 0.0)] + [(r, z) for r, z in out], seg=40, loc=(0, 0, z0), mat=glass)
    # the handle: a thick D of glass on the right
    pts = [(R, 0, z0 + H - 0.025), (R + 0.030, 0, z0 + H - 0.028), (R + 0.036, 0, z0 + H * 0.55), (R + 0.030, 0, z0 + 0.035), (R, 0, z0 + 0.030)]
    parts.tube_path("handle", pts, 0.0075, seg=10, mat=glass)
    # the beer: pale gold, a little darker deep down, fine bubbles in the normal map
    bm = mats.M("beer", "#e8a628", 0.05)
    sep = bm.node("ShaderNodeSeparateXYZ")
    bm.link(bm.coords(), sep.inputs[0])
    col = bm.ramp(sep.outputs["Z"], [(z0 + BASE, "#b8700c"), (z0 + BEER_TOP, "#f0b838")])
    bub = bm.voronoi(1400.0)
    col = bm.mix(bm.math("LESS_THAN", bub.outputs["Distance"], 0.05), col, "#fff0b0")
    bm.link(col, bm.bsdf.inputs["Base Color"])
    rb = R - WALL - 0.0006
    parts.lathe("beer", [(0.0, z0 + BASE + 0.0005), (rb - 0.003, z0 + BASE + 0.0005), (rb, z0 + BASE + 0.004), (rb, z0 + BEER_TOP), (0.0, z0 + BEER_TOP)],
                seg=40, mat=bm.mat)
    # the head: creamy white, domed a little over the rim
    fm = mats.M("head", "#fbf6e8", 0.7)
    v = fm.voronoi(1100.0)
    fm.link(fm.ramp(v.outputs["Distance"], [(0.0, "#e8dcc0"), (0.3, "#fdf9ee")]), fm.bsdf.inputs["Base Color"])
    fm.bump(v.outputs["Distance"], 0.6, 0.0006)
    head = parts.lathe("head", [(rb, z0 + BEER_TOP), (rb, z0 + H - 0.002), (R - 0.0005, z0 + H + 0.004), (R * 0.75, z0 + H + 0.009),
                                (R * 0.35, z0 + H + 0.011), (0.0, z0 + H + 0.0115)], seg=40, mat=fm.mat, cap=False)
    F.lump(head, 0.01, 0.0015)
    # condensation: beads on the outside of the glass, thicker low down
    drop = mats.clear_plastic("drops", "#ffffff", 0.35, 0.02)
    for k in range(34):
        a = rng.uniform(0.6, math.tau - 0.6)        # all round, not under the handle (+X)
        zz = rng.uniform(0.02, H - 0.03)
        rr = R + 0.0015
        s = rng.uniform(0.0012, 0.0024)
        parts.sphere("drop%d" % k, s, 6, 4, loc=(rr * math.cos(a), rr * math.sin(a), z0 + zz), mat=drop, scale=(0.6, 0.6, 0.9))
