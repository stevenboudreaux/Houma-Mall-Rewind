"""A frozen house margarita at Cuco's Mexican Cafe (1995 map, store s42). Hand item; item id
`cu_margarita` (workstream FOOD, Nov 3 2026).

The classic stepped margarita glass (a small lower bowl under a wide shallow upper bowl, on a stem), frozen
lime margarita mounded a little over the rim, a salted rim, a lime wheel on the rim, a short green straw,
on Cuco's own bar coaster (the sign's logo, tools/stores/signs/cu_sign.json). The plain house drink: compare
cu_top_shelf_margarita, which is made to look fancier.
References: design/storefronts/cucos.md (the bar); no photo of the drinks. Guessed: everything.
Size: a 12 oz margarita glass, 165 mm tall, 118 mm across the rim; coaster 100 mm.
Materials: glass transparent (not baked); slush, salt, lime, straw and coaster in the atlas.
Origin: bottom centre of the coaster.
"""
import math
from lib import core, parts, mats
import _food as F
import _cucos as C

RIM_R = 0.059
# the glass's outer profile (radius, height above the coaster's top)
GLASS = [(0.040, 0.0), (0.041, 0.003), (0.036, 0.006), (0.008, 0.012), (0.0055, 0.020), (0.0050, 0.060), (0.0065, 0.072),
         (0.016, 0.080), (0.024, 0.088), (0.028, 0.096), (0.030, 0.104), (0.034, 0.110), (0.046, 0.122), (0.055, 0.140),
         (0.0585, 0.160), (RIM_R, 0.165)]
SLUSH_TOP = 0.163

META = {
    "id": "bl_cu_margarita",
    "class": "hand",
    "tex": 1024,
    "ao": 0.35,
    "refs": [],
    "item_file": "food.json",
    "item": {"id": "cu_margarita", "name": "Margarita", "year": 1995, "store": "CUCOS"},
}


def r_at(z):
    for (r0, z0), (r1, z1) in zip(GLASS, GLASS[1:]):
        if z0 <= z <= z1:
            return r0 + (r1 - r0) * (z - z0) / max(1e-9, z1 - z0)
    return GLASS[-1][0]


def build():
    z0 = C.coaster()
    glass = mats.clear_plastic("glass", "#eef6f2", 0.14, 0.05)
    prof = [(r, z + z0) for r, z in GLASS]
    inner = [(max(0.0, r_at(z) - 0.0022), z + z0) for z in (0.165, 0.150, 0.130, 0.112, 0.104, 0.090, 0.080)] + [(0.0, 0.074 + z0)]
    parts.lathe("glass", [(0.0, z0)] + prof + inner, seg=40, mat=glass)
    # the frozen margarita: fills both bowls, a mound over the rim, icy grain
    sm = mats.M("slush", "#d8e89a", 0.45)
    n = sm.noise(500.0, 4.0)
    sm.link(sm.ramp(n.outputs["Fac"], [(0.3, "#c6dc80"), (0.7, "#eef6c4")]), sm.bsdf.inputs["Base Color"])
    sm.bump(sm.voronoi(1600.0).outputs["Distance"], 0.6, 0.0008)
    sl = [(0.0, 0.076 + z0)] + [(r_at(z) - 0.0026, z + z0) for z in (0.080, 0.090, 0.104, 0.112, 0.130, 0.150, 0.160)] + \
         [(RIM_R - 0.004, SLUSH_TOP + z0), (RIM_R * 0.7, SLUSH_TOP + 0.007 + z0), (RIM_R * 0.3, SLUSH_TOP + 0.011 + z0), (0.0, SLUSH_TOP + 0.012 + z0)]
    s = parts.lathe("slush", sl, seg=40, mat=sm.mat, cap=False)
    F.lump(s, 0.012, 0.0018)
    # salt on the rim
    C.salt_rim("salt", RIM_R - 0.0008, z0 + 0.1645, C.salt_mat())
    # a lime wheel on the rim, front right, cut to sit on it
    C.citrus_wheel("lime", 0.024, 0.005, (), (0.030, -0.050, z0 + 0.160), (math.radians(90), 0, math.radians(-30)))
    # a short green straw
    st = F.between("straw", (0.006, 0.010, z0 + 0.10), (0.018, 0.026, z0 + 0.215), 0.0032, mats.M("straw", "#2a9a3a", 0.35).mat, verts=10)
