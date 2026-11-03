"""A lunch-counter hamburger from the Woolworth coffee shop (1995 map, store s13). Hand item; item id
`wl_hamburger` (workstream FOOD, Nov 3 2026).

1995 lunch-counter style: a griddled beef patty with a slice of American cheese melting over its edge,
leaf lettuce, a tomato slice and two pickle chips on a soft sesame-seed bun, on the same heavy white plate as
the hot dog (thin red line, guessed) with a pickle spear. The shop's own food photos show a burger on a white
plate (tools/stores/woolworth/paint.py food()); the menu strip lists no hamburger price, so none is given.
References: refs/era_1995/stores/Woolworth.jpg (setting only). No photo of the food. Guessed: everything.
Size: bun 105 mm across, burger ~75 mm tall, plate 250 x 160 mm.
Origin: bottom centre of the plate; the burger sits left of centre, the spear to the right.
"""
import math
import random
import bmesh
from lib import core, parts, mats
import _food as F

PRX, PRY = 0.130, 0.085
BUN_R = 0.0525
PATTY_R, PATTY_H = 0.055, 0.014
BX = -0.022                 # the burger's centre on the plate
SEED = 9

META = {
    "id": "bl_wl_hamburger",
    "class": "hand",
    "tex": 2048,
    "ao": 0.45,
    "refs": [["refs/era_1995/stores/Woolworth.jpg", None, "a Woolworth lunch counter (setting)"]],
    "item_file": "food.json",
    "item": {"id": "wl_hamburger", "name": "Hamburger", "year": 1995, "store": "WOOLWORTH"},
}


def bun_crust(name, seeds):
    m = mats.M(name, "#c88a3c", 0.45)
    n = m.noise(40.0, 4.0)
    col = m.ramp(n.outputs["Fac"], [(0.25, "#a8662a"), (0.55, "#cf9446"), (0.9, "#e6b874")])
    if seeds:
        v = m.voronoi(260.0)
        seed = m.math("LESS_THAN", v.outputs["Distance"], 0.16)
        col = m.mix(seed, col, "#f4e8c8")
        m.bump(m.math("SUBTRACT", 1.0, m.math("MULTIPLY", v.outputs["Distance"], 4.0)), 0.25, 0.0006)
    else:
        m.bump(n.outputs["Fac"], 0.1, 0.0005)
    m.link(col, m.bsdf.inputs["Base Color"])
    return m.mat


def crumb_mat():
    c = mats.M("crumb", "#f1e2bf", 0.85)
    v = c.voronoi(700.0)
    c.link(c.ramp(v.outputs["Distance"], [(0.0, "#d9c494"), (0.35, "#f3e6c6")]), c.bsdf.inputs["Base Color"])
    c.bump(v.outputs["Distance"], 0.8, 0.0008)
    return c.mat


def disc_grid(name, r, mat, res=10, fn=None):
    """A flat round sheet (grid clipped to a circle, ring of edge verts) whose verts are moved by fn(x, y) ->
    z offset; used for the cheese drape, the lettuce ruffle."""
    bm = bmesh.new()
    rings = res
    seg = 28
    centre = bm.verts.new((0, 0, 0))
    prev = None
    allr = []
    for j in range(1, rings + 1):
        rr = r * j / rings
        ring = [bm.verts.new((rr * math.cos(math.tau * i / seg), rr * math.sin(math.tau * i / seg), 0)) for i in range(seg)]
        allr.append(ring)
    for i in range(seg):
        bm.faces.new((centre, allr[0][i], allr[0][(i + 1) % seg]))
    for a, b in zip(allr, allr[1:]):
        for i in range(seg):
            bm.faces.new((a[i], b[i], b[(i + 1) % seg], a[(i + 1) % seg]))
    for v in bm.verts:
        v.co.z = fn(v.co.x, v.co.y) if fn else 0.0
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    ob = core.obj_from_bmesh(name, bm, mat, smooth=True)
    return ob


def build():
    rng = random.Random(SEED)
    plate_m = F.ceramic_mat("plate", band=("#b4232a", PRX * 0.955, PRX * 0.965))
    _, z = F.oval_plate("plate", plate_m, PRX, PRY, well=0.72)
    crumb = crumb_mat()
    # bottom bun: a squat lower half of a bun, cut face (crumb) up
    bb = parts.sphere("bun_bottom", 1.0, 28, 10, mat=bun_crust("bun_low", False), scale=(BUN_R, BUN_R, 0.024))
    F.cut(bb, (0, 0, 0.002), (0, 0, 1), crumb)
    for v in bb.data.vertices:
        if v.co.z < -0.008:
            v.co.z = -0.008 + (v.co.z + 0.008) * 0.3   # flatten the underside onto the plate
    # the heel's bottom on the plate; the stack starts at its cut top
    lo = min(v.co.z for v in bb.data.vertices)
    hi = max(v.co.z for v in bb.data.vertices)
    bb.location = (BX, 0, z + 0.0012 - lo)
    zs = z + 0.0012 - lo + hi
    # the patty: a lumpy griddled disc, darker crust, charred edges
    pm = F.crust_mat("patty", [(0.2, "#1e0e06"), (0.45, "#3a1c0c"), (0.75, "#5a2e16"), (0.95, "#744024")], rough=0.5,
                     scale=220.0, bump=0.9, dist=0.0012, specks=("#1a0c04", 600.0, 0.72))
    pt = parts.cylinder("patty", PATTY_R, PATTY_H, verts=32, loc=(BX, 0, zs + PATTY_H / 2), mat=pm.mat, bev=0.004)
    F.lump(pt, 0.006, 0.0022)
    zs += PATTY_H
    # the cheese: a square slice laid on the patty, its corners sagging over the edge
    ch = mats.M("cheese", "#f2a21a", 0.28)
    ch.bump(ch.noise(300.0, 2.0).outputs["Fac"], 0.1, 0.0003)
    bm = bmesh.new()
    nn = 14
    s = 0.088
    vs = [[bm.verts.new((-s / 2 + s * i / nn, -s / 2 + s * j / nn, 0)) for i in range(nn + 1)] for j in range(nn + 1)]
    for j in range(nn):
        for i in range(nn):
            bm.faces.new((vs[j][i], vs[j][i + 1], vs[j + 1][i + 1], vs[j + 1][i]))
    for v in bm.verts:
        r = math.hypot(v.co.x, v.co.y)
        over = max(0.0, r - PATTY_R * 0.92)
        v.co.z = -over * 1.4 - over * over * 30.0
        if over > 0:     # pull in a little as it drapes
            k = 1.0 - over * 2.0
            v.co.x *= k
            v.co.y *= k
    ob = core.obj_from_bmesh("cheese", bm, ch.mat, smooth=True)
    core.solidify(ob, 0.0018, -1.0)
    ob.location = (BX, 0, zs + 0.0018)
    ob.rotation_euler = (0, 0, math.radians(17))
    zs += 0.0018
    # two pickle chips (ridged discs)
    pkm = mats.M("pickle_chip", "#7a8a30", 0.3)
    r_, a_ = F.disc_mat_radial(pkm, 0.0, 0.0)
    pkm.link(pkm.ramp(r_, [(0.0, "#c8c878"), (0.010, "#a8b058"), (0.0135, "#4a6a20")]), pkm.bsdf.inputs["Base Color"])
    for k, (dx, dy) in enumerate(((0.012, -0.010), (-0.014, 0.012))):
        c = parts.cylinder("pchip%d" % k, 0.0145, 0.0022, verts=16, mat=pkm.mat, bev=0.0006)
        core.apply_all(c)
        for v in c.data.vertices:
            r = math.hypot(v.co.x, v.co.y)
            if r > 0.012:
                a = math.atan2(v.co.y, v.co.x)
                v.co.x += 0.0008 * math.cos(a) * math.sin(8 * a)
                v.co.y += 0.0008 * math.sin(a) * math.sin(8 * a)
        c.location = (BX + dx, dy, zs + 0.0012)
    zs += 0.0022
    # the tomato slice
    tm = mats.M("tomato", "#d42a1e", 0.25)
    r_, a_ = F.disc_mat_radial(tm, 0.0, 0.0)
    loc_ = tm.math("GREATER_THAN", tm.math("ABSOLUTE", tm.math("SINE", tm.math("MULTIPLY", a_, 2.5))), 0.55)
    inner = tm.math("LESS_THAN", r_, 0.030)
    gel = tm.math("MULTIPLY", tm.math("MULTIPLY", loc_, inner), tm.math("GREATER_THAN", r_, 0.009))
    v = tm.voronoi(500.0)
    seed = tm.math("MULTIPLY", gel, tm.math("LESS_THAN", v.outputs["Distance"], 0.2))
    col = tm.mix(gel, "#d42a1e", "#e86a3a")
    col = tm.mix(seed, col, "#f4e0a0")
    col = tm.mix(tm.math("GREATER_THAN", r_, 0.037), col, "#b81c14")
    tm.link(col, tm.bsdf.inputs["Base Color"])
    tm.bump(v.outputs["Distance"], 0.2, 0.0004)
    to = parts.cylinder("tomato", 0.040, 0.0055, verts=28, mat=tm.mat, bev=0.0015)
    core.apply_all(to)
    to.location = (BX + 0.004, -0.004, zs + 0.0027)
    zs += 0.0055
    # leaf lettuce: a ruffled sheet hanging out past the bun on the front, under the crown
    lm = mats.M("lettuce", "#7cb83c", 0.35)
    ln = lm.noise(80.0, 4.0)
    r_, a_ = F.disc_mat_radial(lm, 0.0, 0.0)
    vein = lm.math("MULTIPLY", lm.math("GREATER_THAN", lm.math("ABSOLUTE", lm.math("SINE", lm.math("MULTIPLY", a_, 7.0))), 0.99), 0.6)
    col = lm.ramp(r_, [(0.0, "#d8ecb0"), (0.03, "#a8d468"), (0.055, "#5a9a2a")])
    col = lm.mix(vein, col, "#e0f0c0")
    lm.link(col, lm.bsdf.inputs["Base Color"])
    lm.bump(ln.outputs["Fac"], 0.5, 0.0008)
    le = disc_grid("lettuce", 0.058, lm.mat, res=6,
                   fn=lambda x, y: (-max(0.0, math.hypot(x, y) - 0.046) * 0.5
                                    + 0.004 * max(0.0, math.hypot(x, y) - 0.035) / 0.025 * math.sin(11 * math.atan2(y, x))))
    core.solidify(le, 0.0008, 0)
    le.location = (BX, 0, zs + 0.001)
    zs += 0.002
    # the crown: a domed top bun with sesame seeds, cut face (crumb) down
    tb = parts.sphere("bun_top", 1.0, 28, 12, mat=bun_crust("bun_crown", True), scale=(BUN_R, BUN_R, 0.034))
    F.lump(tb, 0.03, 0.0012)
    F.cut(tb, (0, 0, -0.004), (0, 0, -1), crumb)
    lo = min(v.co.z for v in tb.data.vertices)
    tb.location = (BX + 0.002, 0.001, zs - lo)
    tb.rotation_euler = (math.radians(3), math.radians(-4), 0)
    # sesame seeds as geometry on the crown's top (small flattened ovals), plus the painted ones in the crust
    sm = mats.M("sesame", "#f2e6c4", 0.5)
    top = zs - lo
    for k in range(18):
        a = rng.uniform(0, math.tau)
        rr = BUN_R * 0.75 * math.sqrt(rng.random())
        zz = 0.034 * math.sqrt(max(0.0, 1 - (rr / BUN_R) ** 2))
        sd = parts.sphere("seed%d" % k, 0.0022, 6, 3, mat=sm.mat, scale=(1.0, 0.55, 0.32))
        sd.location = (BX + 0.002 + rr * math.cos(a), 0.001 + rr * math.sin(a), top + zz - 0.0003)
        nrm = (rr * math.cos(a) / BUN_R ** 2, rr * math.sin(a) / BUN_R ** 2, zz / 0.034 ** 2)
        from mathutils import Vector
        q = Vector(nrm).normalized().to_track_quat("Z", "Y")
        sd.rotation_euler = q.to_euler()
        sd.rotation_euler.rotate_axis("Z", rng.uniform(0, math.pi))
    # a pickle spear on the right
    skin = F.crust_mat("pickle", [(0.3, "#3d5a1c"), (0.7, "#6a8a2c")], rough=0.4, scale=200.0, bump=0.6, dist=0.0010)
    seeds = mats.M("pickle_in", "#c8c878", 0.3)
    sv = seeds.voronoi(240.0)
    seeds.link(seeds.ramp(sv.outputs["Distance"], [(0.0, "#f0ecc0"), (0.12, "#b8b864"), (0.5, "#a8ac58")]), seeds.bsdf.inputs["Base Color"])
    pk = parts.sphere("pickle", 1.0, 20, 10, mat=skin.mat, scale=(0.042, 0.015, 0.015))
    F.lump(pk, 0.006, 0.0008)
    F.cut(pk, (0, 0, 0), (0, 1, 0), seeds.mat)
    F.cut(pk, (0, 0, 0), (0, 0, -1), seeds.mat)
    pk.rotation_euler = (0, 0, math.radians(100))
    pk.location = (0.066, 0.002, z + 0.0005)
