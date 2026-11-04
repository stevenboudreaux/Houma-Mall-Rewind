"""A lunch-counter hot dog from the Woolworth coffee shop (1995 map, store s13). Hand item; item id
`wl_hot_dog` (workstream FOOD, Nov 3 2026).

1995 lunch-counter style: a grilled frank with grill stripes in a steamed side-split bun, a zigzag of yellow
mustard and a line of green relish, on a heavy white oval plate with a dill pickle spear and a few potato
chips. The back bar's menu strip sells HOT DOG $1.29 (tools/stores/woolworth/paint_lunch.py, invented 1995
prices); the plates in the shop's food photos are plain white (paint.py food()).
References: refs/era_1995/stores/Woolworth.jpg (a period Woolworth lunch counter: the setting only). No
photo of the food: a period type. Guessed: everything on the plate, the plate's thin red line.
Size: frank 150 mm x 22 mm, bun 160 x 60 mm, plate 250 x 160 mm.
Origin: bottom centre of the plate; the dog lies across the plate (along X), facing the front.
"""
import math
import random
from lib import core, parts, mats
import _food as F

PRX, PRY = 0.130, 0.085
FRANK_L, FRANK_R = 0.150, 0.0108
BUN_L, BUN_W, BUN_H = 0.162, 0.058, 0.040
SEED = 3

META = {
    "id": "bl_wl_hot_dog",
    "class": "hand",
    "tex": 2048,
    "ao": 0.4,
    "refs": [["refs/era_1995/stores/Woolworth.jpg", None, "a Woolworth lunch counter (setting)"]],
    "item_file": "food.json",
    "item": {"id": "wl_hot_dog", "name": "Hot dog", "year": 1995, "store": "WOOLWORTH", "price": 129},
}


def bun_mats():
    crust = F.crust_mat("bun", [(0.2, "#a85e1e"), (0.5, "#cf8a38"), (0.85, "#e6b064")], rough=0.6, scale=60.0, bump=0.15, dist=0.0006)
    crumb = mats.M("crumb", "#f1e2bf", 0.85)
    v = crumb.voronoi(700.0)
    crumb.link(crumb.ramp(v.outputs["Distance"], [(0.0, "#d9c494"), (0.35, "#f3e6c6")]), crumb.bsdf.inputs["Base Color"])
    crumb.bump(v.outputs["Distance"], 0.8, 0.0008)
    return crust.mat, crumb.mat


def frank_mat():
    m = mats.M("frank", "#a8442a", 0.32)
    sep = m.node("ShaderNodeSeparateXYZ")
    m.link(m.coords(), sep.inputs[0])
    # grill stripes: diagonal dark bars across the top of the frank
    s = m.math("GREATER_THAN", m.math("SINE", m.math("MULTIPLY", m.math("ADD", sep.outputs["X"], m.math("MULTIPLY", sep.outputs["Y"], 0.8)), 260.0)), 0.82)
    top = m.math("GREATER_THAN", sep.outputs["Z"], BASE_Z + 0.030)
    n = m.noise(300.0, 3.0)
    col = m.ramp(n.outputs["Fac"], [(0.3, "#8a3220"), (0.7, "#b85434")])
    col = m.mix(m.math("MULTIPLY", s, top), col, "#3a160c")
    m.link(col, m.bsdf.inputs["Base Color"])
    m.bump(n.outputs["Fac"], 0.2, 0.0004)
    return m.mat


BASE_Z = 0.0


def build():
    global BASE_Z
    rng = random.Random(SEED)
    plate_m = F.ceramic_mat("plate", band=("#b4232a", PRX * 0.955, PRX * 0.965))
    _, z = F.oval_plate("plate", plate_m, PRX, PRY, well=0.72)
    BASE_Z = z
    crust, crumb = bun_mats()
    # the bun: two halves of an elongated loaf, hinged at the bottom, opened outward round the frank
    for side in (-1, 1):
        h = parts.sphere("bun%d" % side, 1.0, 32, 14, mat=crust, scale=(BUN_L / 2, BUN_W / 2, BUN_H / 2))
        F.lump(h, 0.02, 0.0015)
        F.cut(h, (0, 0, 0), (0, -side, 0), crumb)       # keep the half on this side; the cut face is crumb
        h.location = (0, side * 0.009, z + BUN_H / 2 - 0.004)
        h.rotation_euler = (math.radians(-side * 30), 0, 0)
    # the frank: a sausage lathe lying along X, resting in the split
    prof = [(0.0, 0.0), (FRANK_R * 0.55, 0.002), (FRANK_R * 0.92, 0.008), (FRANK_R, 0.016),
            (FRANK_R, FRANK_L - 0.016), (FRANK_R * 0.92, FRANK_L - 0.008), (FRANK_R * 0.55, FRANK_L - 0.002), (0.0, FRANK_L)]
    fk = parts.lathe("frank", prof, seg=20, mat=frank_mat(), cap=False)
    fk.rotation_euler = (0, math.radians(90), 0)
    fk.location = (-FRANK_L / 2, 0, z + BUN_H * 0.62 + 0.004)
    core.apply_all(fk)
    # a gentle curve: bend the frank's ends down a little
    for v in fk.data.vertices:
        v.co.z -= 0.010 * (v.co.x / (FRANK_L / 2)) ** 2
    zt = z + BUN_H * 0.62 + 0.004 + FRANK_R
    # mustard: a zigzag tube over the top
    mus = mats.M("mustard", "#f2c414", 0.3)
    pts = []
    for i in range(15):
        x = -0.064 + 0.128 * i / 14
        pts.append((x, (0.006 if i % 2 else -0.006), zt - 0.010 * (x / (FRANK_L / 2)) ** 2 + 0.0012))
    parts.tube_path("mustard", pts, 0.0024, seg=6, mat=mus.mat)
    # relish: a line of small green bits along one side of the split
    rel = F.crust_mat("relish", [(0.3, "#3e7a22"), (0.7, "#7ab43a")], rough=0.25, scale=500.0, bump=0.6, dist=0.0008)
    for k in range(14):
        x = -0.060 + 0.120 * k / 13 + rng.uniform(-0.003, 0.003)
        parts.box("relish%d" % k, (0.007, 0.005, 0.0035), loc=(x, 0.0115 + rng.uniform(-0.002, 0.002), zt - 0.004 - 0.010 * (x / 0.075) ** 2),
                  rot=(rng.uniform(-30, 30), rng.uniform(-30, 30), rng.uniform(0, 180)), mat=rel.mat, bev=0.0012, seg=1)
    # a dill pickle spear in front of the dog: a quarter of a ridged cucumber, seeds on the cut faces
    skin = F.crust_mat("pickle", [(0.3, "#3d5a1c"), (0.7, "#6a8a2c")], rough=0.4, scale=200.0, bump=0.6, dist=0.0010)
    seeds = mats.M("pickle_in", "#c8c878", 0.3)
    sv = seeds.voronoi(240.0)
    seeds.link(seeds.ramp(sv.outputs["Distance"], [(0.0, "#f0ecc0"), (0.12, "#b8b864"), (0.5, "#a8ac58")]), seeds.bsdf.inputs["Base Color"])
    seeds.bump(sv.outputs["Distance"], 0.4, 0.0006)
    pk = parts.sphere("pickle", 1.0, 24, 12, mat=skin.mat, scale=(0.044, 0.015, 0.015))
    F.lump(pk, 0.006, 0.0008)
    F.cut(pk, (0, 0, 0), (0, 1, 0), seeds.mat)
    F.cut(pk, (0, 0, 0), (0, 0, -1), seeds.mat)
    pk.rotation_euler = (0, 0, math.radians(176))   # resting on one cut face, the other (seeds) toward the viewer
    pk.location = (0.030, -0.033, z + 0.0005)
    # a few rippled potato chips by the pickle
    chip = F.crust_mat("chip", [(0.3, "#d8a040"), (0.6, "#f0cc70"), (0.9, "#f6e0a0")], rough=0.35, scale=120.0, bump=0.3, dist=0.0005,
                       specks=("#9a5a20", 900.0, 0.78))
    for k, (x, y, a) in enumerate(((-0.040, -0.040, 10), (-0.058, -0.036, 70), (-0.030, -0.034, 130), (-0.064, -0.046, 200), (-0.048, -0.050, 260))):
        c = parts.cylinder("chip%d" % k, 0.021 * rng.uniform(0.85, 1.1), 0.0012, verts=16, mat=chip.mat, bev=0)
        core.apply_all(c)
        for v in c.data.vertices:
            v.co.z += 0.0035 * math.sin(v.co.x * 260.0) + 0.004 * (v.co.x ** 2 + v.co.y ** 2) / 0.00044
        c.scale = (1.0, rng.uniform(0.75, 0.95), 1.0)
        c.location = (x, y, z + 0.004 + k * 0.0022)
        c.rotation_euler = (math.radians(rng.uniform(-12, 12)), math.radians(rng.uniform(-12, 12)), math.radians(a))
