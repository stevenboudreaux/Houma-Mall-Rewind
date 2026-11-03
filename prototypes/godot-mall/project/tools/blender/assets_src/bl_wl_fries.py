"""Lunch-counter French fries from the Woolworth coffee shop (1995 map, store s13). Hand item; item id
`wl_fries` (workstream FOOD, Nov 3 2026).

1995 lunch-counter style: a heap of straight-cut fries, golden with browned ends, salted, on a small heavy
white oval plate (the hot dog's plate, smaller) with a paper soufflé cup of ketchup. The shop's food photos
show fries on a white plate (tools/stores/woolworth/paint.py food() "fries"); no menu price for them.
References: refs/era_1995/stores/Woolworth.jpg (setting only). No photo of the food. Guessed: everything.
Size: fries 8 mm square, 55-95 mm long; plate 230 x 150 mm; ketchup cup 2 oz, 50 mm across.
Detail: the fries on top and round the edge of the heap are full geometry; the heap's core is a lumpy mound
in the same material.
Origin: bottom centre of the plate.
"""
import math
import random
from lib import core, parts, mats
import _food as F

PRX, PRY = 0.115, 0.075
N_FRIES = 24
SEED = 21

META = {
    "id": "bl_wl_fries",
    "class": "hand",
    "tex": 2048,
    "ao": 0.5,
    "refs": [["refs/era_1995/stores/Woolworth.jpg", None, "a Woolworth lunch counter (setting)"]],
    "item_file": "food.json",
    "item": {"id": "wl_fries", "name": "French fries", "year": 1995, "store": "WOOLWORTH"},
}


def build():
    rng = random.Random(SEED)
    plate_m = F.ceramic_mat("plate", band=("#b4232a", PRX * 0.952, PRX * 0.964))
    _, z = F.oval_plate("plate", plate_m, PRX, PRY, well=0.72)
    fm = F.crust_mat("fry", [(0.2, "#b06a1e"), (0.45, "#e0a448"), (0.8, "#f2cf78")], rough=0.45, scale=70.0,
                     bump=0.3, dist=0.0005, specks=("#fbf6ea", 2600.0, 0.80))     # salt grains
    # the heap's core, so gaps between fries never show the plate through the middle
    core_ = parts.sphere("heap", 1.0, 20, 8, loc=(-0.012, 0.004, z), mat=fm.mat, scale=(0.045, 0.030, 0.018))
    F.lump(core_, 0.008, 0.004)
    F.cut(core_, (0, 0, z + 0.0005), (0, 0, -1))      # nothing below the plate's surface
    # fries in three layers, criss-crossed, the top ones on the heap's slope
    for i in range(N_FRIES):
        layer = 0 if i < 10 else (1 if i < 18 else 2)
        a = rng.uniform(0, math.pi)
        ln = rng.uniform(0.055, 0.095)
        cx = -0.012 + rng.uniform(-0.030, 0.030) * (1.0 - 0.3 * layer)
        cy = 0.004 + rng.uniform(-0.020, 0.020) * (1.0 - 0.3 * layer)
        zz = z + 0.004 + 0.007 * layer + (0.014 if layer == 2 else 0.0) * (1.0 - math.hypot(cx + 0.012, cy) / 0.04)
        tilt = rng.uniform(-0.18, 0.18)
        dv = (math.cos(a), math.sin(a), tilt)
        start = (cx - math.cos(a) * ln / 2, cy - math.sin(a) * ln / 2, zz - tilt * ln / 2)
        F.fry("fry%02d" % i, fm.mat, ln, 0.0082 * rng.uniform(0.9, 1.08), 0.0080 * rng.uniform(0.9, 1.08), kind="straight",
              rings=3, bend=rng.uniform(-0.004, 0.004), twist=rng.uniform(-0.3, 0.3), loc=start, dirv=dv,
              roll=rng.uniform(0, math.pi), n=16, seed=i)
    # the ketchup: a pleated paper soufflé cup, front right
    cup = mats.M("souffle", "#f6f3ea", 0.7)
    cx, cy = 0.066, -0.020
    r_, a_ = F.disc_mat_radial(cup, cx, cy)
    cup.bump(cup.math("SINE", cup.math("MULTIPLY", a_, 24.0)), 0.25, 0.0004)       # the pleats
    parts.lathe("souffle", [(0.0, 0.0), (0.019, 0.0), (0.0205, 0.002), (0.025, 0.026), (0.0256, 0.0268), (0.0244, 0.0268),
                            (0.0238, 0.025), (0.0188, 0.003), (0.0, 0.003)], seg=32, loc=(cx, cy, z), mat=cup.mat, cap=False)
    k = mats.M("ketchup", "#9a1008", 0.08)
    k.bump(k.noise(80.0, 2.0).outputs["Fac"], 0.2, 0.0008)
    kp = parts.lathe("ketchup", [(0.0, 0.020), (0.0225, 0.020), (0.0232, 0.0215), (0.015, 0.0232), (0.0, 0.0240)], seg=32,
                     loc=(cx, cy, z), mat=k.mat, cap=False)
