"""A top-shelf margarita at Cuco's Mexican Cafe (1995 map, store s42). Hand item; item id
`cu_top_shelf_margarita` (workstream FOOD, Nov 3 2026). The free drink on cu_coupon.

Made visibly fancier than the house cu_margarita: a big hand-blown Mexican glass with a cobalt-blue rim and a
green saguaro-cactus stem (two arms), served on the rocks (golden amber: premium tequila and orange liqueur,
not the frozen green), coarse salt on the rim, a lime wheel AND an orange wheel, a bigger glass, ice, on
Cuco's own bar coaster.
References: design/storefronts/cucos.md; no photo of the drinks. Guessed: everything (the cactus-stem
glass is a common Mexican restaurant glass of the period).
Size: 190 mm tall, 132 mm across the rim; coaster 100 mm.
Materials: the three glasses (clear bowl, blue rim, green stem) are transparent glTF materials (not baked);
drink, ice, salt, fruit and coaster in the atlas. Origin: bottom centre of the coaster.
"""
import math
import random
from lib import core, parts, mats
import _food as F
import _cucos as C

RIM_R = 0.066
STEM_TOP = 0.092
# the bowl's outer profile, above the stem (radius, height above the coaster's top)
BOWL = [(0.010, STEM_TOP), (0.026, STEM_TOP + 0.006), (0.044, STEM_TOP + 0.020), (0.058, STEM_TOP + 0.042), (0.064, STEM_TOP + 0.068),
        (0.066, STEM_TOP + 0.088), (RIM_R, STEM_TOP + 0.096)]
TOP = STEM_TOP + 0.096
DRINK = TOP - 0.024
SEED = 17

META = {
    "id": "bl_cu_top_shelf_margarita",
    "class": "hand",
    "tex": 1024,
    "ao": 0.35,
    "refs": [],
    "item_file": "food.json",
    "item": {"id": "cu_topshelf", "name": "Top-shelf margarita", "year": 1995, "store": "CUCOS"},
}


def r_at(z):
    for (r0, z0), (r1, z1) in zip(BOWL, BOWL[1:]):
        if z0 <= z <= z1:
            return r0 + (r1 - r0) * (z - z0) / max(1e-9, z1 - z0)
    return BOWL[-1][0]


def build():
    rng = random.Random(SEED)
    z0 = C.coaster()
    clear = mats.clear_plastic("glass", "#eef6f2", 0.14, 0.05)
    blue = mats.clear_plastic("blue_rim", "#1838c8", 0.62, 0.06)
    green = mats.clear_plastic("cactus", "#2a9a4a", 0.55, 0.08)
    # the foot: a green disc
    parts.lathe("foot", [(0.0, z0), (0.044, z0), (0.045, z0 + 0.003), (0.040, z0 + 0.007), (0.012, z0 + 0.012), (0.0, z0 + 0.013)], seg=36, mat=green)
    # the cactus stem: a ribbed column with two arms, rounded top under the bowl
    ribs = 8
    prof = [(0.010, z0 + 0.010), (0.0105, z0 + 0.03), (0.0105, z0 + 0.07), (0.011, z0 + STEM_TOP - 0.004), (0.010, z0 + STEM_TOP + 0.004)]
    col = parts.lathe("stem", prof, seg=16, mat=green, cap=False)
    for v in col.data.vertices:
        a = math.atan2(v.co.y, v.co.x)
        k = 1.0 - 0.12 * (0.5 + 0.5 * math.cos(ribs * a))
        v.co.x *= k
        v.co.y *= k
    for side in (-1, 1):
        h0 = 0.040 if side < 0 else 0.052
        pts = [(side * 0.009, 0, z0 + h0), (side * 0.020, 0, z0 + h0 - 0.002), (side * 0.026, 0, z0 + h0 + 0.006), (side * 0.027, 0, z0 + h0 + 0.022)]
        parts.tube_path("arm%d" % side, pts, 0.0055, seg=10, mat=green)
        parts.sphere("armtip%d" % side, 0.0055, 10, 6, loc=(side * 0.027, 0, z0 + h0 + 0.022), mat=green)
    # the bowl: clear glass, then the cobalt rim band (its own material) over the top 14 mm
    split = TOP - 0.014
    out_lo = [(r, z) for r, z in BOWL if z < split] + [(r_at(split), split)]
    inn_lo = [(r_at(split) - 0.0028, split)] + [(max(0.0, r - 0.0028), z) for r, z in reversed(BOWL) if STEM_TOP + 0.006 < z < split] + [(0.0, STEM_TOP + 0.006)]
    parts.lathe("bowl", [(r, z + z0) for r, z in out_lo + inn_lo], seg=40, mat=clear, cap=False)
    rim = [(r_at(split), split), (RIM_R, TOP - 0.002), (RIM_R - 0.001, TOP), (RIM_R - 0.0032, TOP - 0.001), (r_at(split) - 0.0028, split)]
    parts.lathe("rim", [(r, z + z0) for r, z in rim], seg=40, mat=blue, cap=False)
    # the drink: golden amber on the rocks
    dm = mats.M("drink", "#e8b440", 0.04)
    n = dm.noise(300.0, 2.0)
    dm.link(dm.ramp(n.outputs["Fac"], [(0.3, "#d89a28"), (0.7, "#f2c858")]), dm.bsdf.inputs["Base Color"])
    parts.lathe("drink", [(0.0, z0 + STEM_TOP + 0.007)] + [(r_at(z) - 0.003, z + z0) for z in (STEM_TOP + 0.010, STEM_TOP + 0.03, STEM_TOP + 0.05, DRINK)] + [(0.0, z0 + DRINK)],
                seg=40, mat=dm.mat)
    ice = mats.M("ice", "#eef6f6", 0.08)
    ice.bump(ice.noise(300.0, 3.0).outputs["Fac"], 0.5, 0.0006)
    for k, (x, y) in enumerate(((0.026, -0.020), (-0.024, -0.024), (0.010, 0.034), (-0.030, 0.016), (0.034, 0.018), (-0.002, -0.004), (0.002, -0.040))):
        sz = rng.uniform(0.020, 0.024)
        parts.box("ice%d" % k, (sz, sz, sz * 0.9), loc=(x, y, z0 + DRINK - sz * 0.1), rot=(rng.uniform(-25, 25), rng.uniform(-25, 25), rng.uniform(0, 90)),
                  mat=ice.mat, bev=0.0032, seg=2)
    # coarse salt on the blue rim
    C.salt_rim("salt", RIM_R - 0.0012, z0 + TOP + 0.0002, C.salt_mat("salt", coarse=True), tube=0.0034)
    # a lime wheel and an orange wheel on the rim, front
    C.citrus_wheel("lime", 0.025, 0.005, (), (0.034, -0.056, z0 + TOP - 0.004), (math.radians(90), 0, math.radians(-32)))
    C.citrus_wheel("orange", 0.031, 0.006, ("#e87810", ("#f2a020", "#fcc860")), (-0.026, -0.060, z0 + TOP - 0.006), (math.radians(90), 0, math.radians(22)))
    # two short black cocktail straws
    sm = mats.M("straws", "#141414", 0.35).mat
    F.between("straw_a", (0.010, 0.012, z0 + STEM_TOP + 0.02), (0.028, 0.040, z0 + TOP + 0.06), 0.0024, sm, verts=8)
    F.between("straw_b", (0.016, 0.008, z0 + STEM_TOP + 0.02), (0.036, 0.034, z0 + TOP + 0.058), 0.0024, sm, verts=8)
