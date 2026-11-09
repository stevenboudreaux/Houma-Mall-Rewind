"""Auntie Anne's pretzel warming case, with its pretzels and nugget cups (2026 map, store n56). Fixture.

Steven (voice note, Nov 3 2026): "that's exactly what the pretzels look like in the little things".
A stainless counter-top warmer: a base pan, a stainless back, three stepped stainless wire tiers
rising toward the staff side, a sloped glass front up to a flat glass top, glass ends, a warm lit
strip under the top. Front tier: a row of navy paper cups heaped with pretzel bites; the two upper
tiers: rows of twisted pretzels leaning back against the tier behind, golden brown with salt, a few
cinnamon-sugar ones. Cups plain (no packaging print: IP rule).

References: refs/new/auntie_annes/aa_t000_001-031 (the "Love a good pretzel" clip: the steel tiers,
the leaning rows, the cups in front, the blue counter front under it), refs/derived/frames/IMG_4439
f025 (Southland, Oct 23 2026: the warmer on the left of the counter, about a third of the 4 m stall).
Size: measured against the counter in f025, ~1.25 m wide, 0.55 m deep, 0.6 m tall (guessed to +-10 cm).
Guessed: the tier heights, the counts, the cinnamon-sugar ones.
Origin: bottom centre, on the counter top; the glass front faces -Y (Godot +Z, the customer).
"""
import math
import random
import bmesh
import bpy
from mathutils import Vector
from lib import core, parts, mats

W, D, H = 1.25, 0.55, 0.60       # outside width (X), depth (Y), height
SEED = 25
TIERS = [  # (z of the tier, y from, y to): front (cups), middle, back (pretzels)
    (0.07, -0.25, -0.09),
    (0.17, -0.08, 0.08),
    (0.30, 0.08, 0.24),
]
N_PRETZEL = 6      # per tier
N_CUP = 8
CUPS = False       # FOOD3D (Nov 8 2026): the closed cups are gone; the open cups of nuggets (bl_aa_nugget_cup_case)
                   # are instanced at the same places by tools/stores/auntie_annes/store.gd
SCALE = 1.3        # the pretzels: ~19 cm across, as in the clip against the cups

META = {"id": "bl_aa_warmer", "class": "small_fixture", "tex": 1024, "ao": 0.4,
        "refs": [["refs/new/auntie_annes/aa_t000_013.jpg", [0.0, 0.0, 1.0, 0.7], "the warmer (clip)"],
                 ["refs/derived/frames/IMG_4439/f025.jpg", [0.0, 0.5, 0.45, 0.68], "Southland, Oct 23 2026"]]}

# a pretzel's centre line in its own plane (x across, z up), metres: the belly at the bottom, the two
# lobes on top, the ends twisted across the middle and pressed onto the belly
KNOT = [(0.045, 0.004, 0.0), (0.022, 0.030, 0.006), (-0.012, 0.055, 0.010), (-0.045, 0.078, 0.006), (-0.072, 0.058, 0.0),
        (-0.074, 0.020, 0.0), (-0.050, -0.010, 0.0), (0.0, -0.022, 0.0), (0.050, -0.010, 0.0), (0.074, 0.020, 0.0),
        (0.072, 0.058, 0.0), (0.045, 0.078, 0.006), (0.012, 0.055, 0.0), (-0.022, 0.030, -0.006), (-0.045, 0.004, 0.0)]


def catmull(pts, n_per):
    out = []
    P = [Vector(p) for p in pts]
    P = [P[0]] + P + [P[-1]]
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        for k in range(n_per):
            t = k / n_per
            t2, t3 = t * t, t * t * t
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
    out.append(P[-2])
    return out


def rope(bm, path, rad, sides=6):
    """A tube along `path` (a list of Vectors), thinner at the ends, capped."""
    rings = []
    n = len(path)
    for i, p in enumerate(path):
        tang = (path[min(i + 1, n - 1)] - path[max(i - 1, 0)]).normalized()
        up = Vector((0, 1, 0)) if abs(tang.y) < 0.9 else Vector((1, 0, 0))
        a = tang.cross(up).normalized()
        b = tang.cross(a).normalized()
        s = min(1.0, 0.55 + 0.45 * min(i, n - 1 - i) / 3.0)
        ring = []
        for k in range(sides):
            ang = math.tau * k / sides
            ring.append(bm.verts.new(p + (a * math.cos(ang) + b * math.sin(ang)) * rad * s))
        rings.append(ring)
    for r0, r1 in zip(rings, rings[1:]):
        for k in range(sides):
            bm.faces.new((r0[k], r0[(k + 1) % sides], r1[(k + 1) % sides], r1[k]))
    for ring, rev in ((rings[0], True), (rings[-1], False)):
        f = bm.faces.new(list(reversed(ring)) if rev else ring)
        bmesh.ops.poke(bm, faces=[f])


def pretzel_mat(name, base, dark, salt):
    m = mats.M(name, base, 0.35)
    tc = m.coords()
    n = m.noise(90.0, 3.0, coord=tc)
    col = m.ramp(n.outputs["Fac"], [(0.35, dark), (0.65, base)])
    if salt:
        v = m.voronoi(420.0, coord=tc)
        flecks = m.math("LESS_THAN", v.outputs["Distance"], 0.12)
        col = m.mix(flecks, col, salt)
    m.link(col, m.bsdf.inputs["Base Color"])
    m.bump(m.noise(600.0, 2.0, coord=tc).outputs["Fac"], 0.25, 0.0006)
    return m.mat


def pretzel(bm_map, mat_key, x, y, z, lean, turn, rng):
    """One pretzel standing on the tier, its top leaning back (+Y) by `lean` radians."""
    sx = rng.uniform(0.95, 1.05) * SCALE
    pts = catmull([(p[0] * sx, p[2] * SCALE, p[1] * SCALE + 0.024 * SCALE) for p in KNOT], 2)    # (x, depth, up)
    c, s = math.cos(lean), math.sin(lean)
    ct, st = math.cos(turn), math.sin(turn)
    out = []
    for q in pts:
        qy, qz = q.y * c + q.z * s, -q.y * s + q.z * c
        out.append(Vector((q.x * ct - qy * st + x, q.x * st + qy * ct + y, qz + z)))
    rope(bm_map[mat_key], out, 0.0105 * SCALE)


def build():
    rng = random.Random(SEED)
    steel = mats.brushed_metal("steel", "#c4c6ca", 0.3, along="X", metal=0.7)
    wire = mats.brushed_metal("wire", "#a8aaae", 0.35, along="X", metal=0.7)
    glass = mats.clear_plastic("glass", "#f4f8fa", 0.07, 0.04)
    lm = mats.M("lamp", "#fff2d8", 0.3, bake=False)
    lm.bsdf.inputs["Emission Color"].default_value = mats.hexc("#ffe8c0")
    lm.bsdf.inputs["Emission Strength"].default_value = 3.0
    lamp = lm.mat
    # body: base pan, back, the top frame
    parts.box("pan", (W, D, 0.06), loc=(0, 0, 0.03), mat=steel, bev=0.004)
    parts.box("back", (W, 0.025, H - 0.06), loc=(0, D / 2 - 0.0125, 0.06 + (H - 0.06) / 2), mat=steel, bev=0.003)
    parts.box("top_frame_b", (W, 0.08, 0.025), loc=(0, D / 2 - 0.04, H - 0.0125), mat=steel, bev=0.003)
    parts.box("top_frame_f", (W, 0.03, 0.025), loc=(0, -0.06, H - 0.0125), mat=steel, bev=0.003)
    for s in (-1, 1):
        parts.box("post%d" % s, (0.025, 0.025, H - 0.06), loc=(s * (W / 2 - 0.0125), -0.06, 0.06 + (H - 0.06) / 2), mat=steel, bev=0.002)
    # the lit strip under the top
    parts.box("lamp", (W - 0.1, 0.04, 0.01), loc=(0, D / 2 - 0.08, H - 0.03), mat=lamp, bev=0)
    # glass: the sloped front from the pan's front edge up to the top frame, the top, the ends
    y0, z0, y1, z1 = -D / 2 + 0.01, 0.06, -0.075, H - 0.02
    ln = math.hypot(y1 - y0, z1 - z0)
    ang = math.degrees(math.atan2(y1 - y0, z1 - z0))
    parts.box("glass_front", (W - 0.06, 0.006, ln), loc=(0, (y0 + y1) / 2, (z0 + z1) / 2), rot=(-ang, 0, 0), mat=glass, bev=0)
    parts.box("glass_top", (W - 0.06, D - 0.2, 0.006), loc=(0, 0.04, H - 0.004), mat=glass, bev=0)
    for s in (-1, 1):
        bm = bmesh.new()
        xs = s * (W / 2 - 0.004)
        vs = [bm.verts.new((xs, y, z)) for (y, z) in [(-D / 2 + 0.01, 0.06), (D / 2 - 0.03, 0.06), (D / 2 - 0.03, H - 0.02), (-0.075, H - 0.02)]]
        bm.faces.new(vs if s > 0 else list(reversed(vs)))
        bmesh.ops.triangulate(bm, faces=bm.faces[:])
        core.obj_from_bmesh("glass_end%d" % s, bm, glass)
    # the tiers: a steel shelf and a wire lip each, stepping up to the back
    for (z, ya, yb) in TIERS:
        parts.box("tier", (W - 0.06, yb - ya, 0.008), loc=(0, (ya + yb) / 2, z), mat=wire, bev=0.001, seg=1)
        parts.box("lip", (W - 0.06, 0.006, 0.03), loc=(0, ya + 0.003, z + 0.015), mat=wire, bev=0.001, seg=1)
        if z > 0.1:
            for s in (-1, 1):
                parts.box("riser", (0.01, 0.01, z - 0.06), loc=(s * (W / 2 - 0.05), ya + 0.01, 0.06 + (z - 0.06) / 2), mat=wire, bev=0)
    # the cups of pretzel bites on the front tier
    cup = mats.M("cup", "#1d2a6e", 0.6)
    band = mats.flat("cup_band", "#f4f2ec", 0.6)
    bites = pretzel_mat("bites", "#b8622a", "#7a3a14", "#f4f0e6")
    z, ya, yb = TIERS[0]
    for k in range(N_CUP if CUPS else 0):
        x = -W / 2 + 0.09 + k * (W - 0.18) / (N_CUP - 1)
        y = (ya + yb) / 2
        parts.cylinder("cup", 0.042, 0.08, verts=12, loc=(x, y, z + 0.044), mat=cup.mat, bev=0, r2=0.032)
        parts.cylinder("band", 0.0425, 0.014, verts=12, loc=(x, y, z + 0.068), mat=band, bev=0, r2=0.040)
        for j in range(4):
            parts.sphere("bite", 0.016, 6, 4, loc=(x + rng.uniform(-0.02, 0.02), y + rng.uniform(-0.02, 0.02), z + 0.09 + rng.uniform(0, 0.012)),
                         mat=bites, scale=(1.2, 1.0, 0.8))
    # the pretzels: salted golden ones, every fourth one cinnamon sugar
    gold = pretzel_mat("pretzel", "#a8541c", "#6a2e0c", "#f6f2e8")
    cinn = pretzel_mat("cinnamon", "#c88a4a", "#9a5a28", "#e8d2a8")
    bms = {"gold": bmesh.new(), "cinn": bmesh.new()}
    for ti, (z, ya, yb) in enumerate(TIERS[1:]):
        for k in range(N_PRETZEL):
            x = -W / 2 + 0.1 + k * (W - 0.2) / (N_PRETZEL - 1) + rng.uniform(-0.012, 0.012)
            key = "cinn" if (k + ti * 2) % 4 == 3 else "gold"
            pretzel(bms, key, x, ya + 0.05, z + 0.008, math.radians(rng.uniform(18, 28)), math.radians(rng.uniform(-8, 8)), rng)
    core.obj_from_bmesh("pretzels", bms["gold"], gold, smooth=True)
    core.obj_from_bmesh("pretzels_cinn", bms["cinn"], cinn, smooth=True)
