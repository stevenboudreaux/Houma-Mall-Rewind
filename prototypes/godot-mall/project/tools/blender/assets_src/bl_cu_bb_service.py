"""Cuco's back bar kit: the bartender's service things (1995 map, store s42). Fixture.

On a black rubber bar mat: a commercial bar blender for the frozen margaritas (heavy black base with a
chrome toggle panel, an empty clear polycarbonate jar with its lid: no prepared drink), a Boston shaker
(steel tin with the mixing glass nested in it), a long bar spoon and a hawthorne strainer, a black garnish
caddy with lime wedges, orange wheels and red cherries under its hinged lid, and a folded white bar towel.
Brands: none (the blender's badge is a plain chrome plate).
References: design/storefronts/cucos.md (the bar); no photo. Guessed: everything.
Size: mat 0.60 x 0.30 m; blender 0.45 m tall.
Placement: design/storefronts/cucos-back-bar-kit.md. Origin: the middle of the mat's back edge on the
counter top.
"""
import math
import random
from lib import core, parts, mats
import _food as F
import _bar as BAR
import _cucos as C

SEED = 43

META = {"id": "bl_cu_bb_service", "class": "small_fixture", "tex": 2048, "ao": 0.4, "refs": []}


def build():
    rng = random.Random(SEED)
    z = 0.010
    rubber = mats.M("mat", "#121212", 0.85)
    v = rubber.voronoi(160.0)
    rubber.bump(rubber.math("LESS_THAN", v.outputs["Distance"], 0.25), 0.8, 0.0012)
    parts.box("barmat", (0.60, 0.30, 0.010), loc=(0, -0.15, 0.005), mat=rubber.mat, bev=0.003, seg=2)
    steel = BAR.shared_mats()["steel"]
    black = mats.plastic("black", "#161616", 0.4)
    # the blender: base, jar, lid (left)
    bx, by = -0.20, -0.13
    parts.rounded_panel("bl_base", 0.20, 0.20, 0.17, r=0.03, plane="XY", loc=(bx, by, z + 0.085), mat=black, bev=0.004)
    panel = mats.brushed_metal("panel", "#c8cacc", 0.25, metal=0.75)
    parts.box("bl_panel", (0.13, 0.004, 0.06), loc=(bx, by - 0.101, z + 0.08), rot=(-8, 0, 0), mat=panel, bev=0.001, seg=1)
    for k in range(2):
        parts.box("bl_switch%d" % k, (0.012, 0.012, 0.022), loc=(bx - 0.02 + k * 0.04, by - 0.106, z + 0.085), rot=(-25, 0, 0), mat=steel, bev=0.002, seg=1)
    parts.cylinder("bl_pad", 0.055, 0.012, verts=24, loc=(bx, by, z + 0.176), mat=black, bev=0.002)
    jar = mats.clear_plastic("jar", "#e8f0f0", 0.22, 0.12)
    jp = [(0.0, 0.0), (0.050, 0.0), (0.052, 0.01), (0.070, 0.22), (0.072, 0.23), (0.069, 0.229), (0.067, 0.22), (0.049, 0.012), (0.0, 0.012)]
    parts.lathe("bl_jar", jp, seg=24, loc=(bx, by, z + 0.182), mat=jar, cap=False)
    parts.tube_path("bl_handle", [(bx + 0.07, by, z + 0.38), (bx + 0.11, by, z + 0.37), (bx + 0.115, by, z + 0.28), (bx + 0.10, by, z + 0.22), (bx + 0.06, by, z + 0.21)], 0.010, seg=8, mat=jar)
    parts.cylinder("bl_lid", 0.074, 0.016, verts=24, loc=(bx, by, z + 0.420), mat=black, bev=0.003)
    parts.cylinder("bl_lidcap", 0.025, 0.014, verts=16, loc=(bx, by, z + 0.434), mat=black, bev=0.002)
    # Boston shaker: the tin with the glass nested in it, upside down (centre)
    sx, sy = 0.00, -0.10
    parts.lathe("tin", [(0.0, 0.0), (0.042, 0.0), (0.044, 0.004), (0.046, 0.15), (0.047, 0.17), (0.0445, 0.17), (0.0435, 0.15), (0.0415, 0.004), (0.0, 0.003)],
                seg=24, loc=(sx, sy, z), mat=steel, cap=False)
    g = parts.lathe("mixglass", BAR.pint_profile(), seg=20, mat=BAR.glass_mat("clear"), cap=False)
    g.rotation_euler = (math.pi, 0, 0)
    g.location = (sx, sy, z + 0.245)
    # bar spoon and hawthorne strainer lying on the mat
    sp = parts.cylinder("barspoon", 0.0022, 0.28, verts=8, loc=(0.03, -0.24, z + 0.003), rot=(0, 90, 12), mat=steel, bev=0)
    parts.sphere("spoonbowl", 0.010, 12, 6, loc=(0.168, -0.211, z + 0.004), mat=steel, scale=(1.4, 0.9, 0.35))
    parts.cylinder("strainer", 0.040, 0.004, verts=24, loc=(0.06, -0.035, z + 0.002), mat=steel, bev=0.001)
    coil = [(0.06 + 0.036 * math.cos(a / 4), -0.035 + 0.036 * math.sin(a / 4), z + 0.003 + 0.002 * math.sin(a * 3)) for a in range(0, 26)]
    parts.tube_path("spring", coil, 0.0018, seg=6, mat=steel)
    parts.box("strainer_h", (0.09, 0.016, 0.003), loc=(0.125, -0.035, z + 0.003), mat=steel, bev=0.001, seg=1)
    # garnish caddy: black tray, six compartments, the lid hinged open at the back (right)
    cx, cy = 0.20, -0.14
    parts.box("caddy", (0.20, 0.12, 0.06), loc=(cx, cy, z + 0.03), mat=black, bev=0.004, seg=2)
    lid = parts.box("caddy_lid", (0.20, 0.12, 0.010), loc=(cx, cy + 0.06 + 0.004, z + 0.06 + 0.06), rot=(80, 0, 0), mat=jar, bev=0.003, seg=2)
    lime = C.lime_wheel_mat("lime", 0.0, 0.0, 0.025)
    for k in range(6):
        ix, iy = cx - 0.065 + (k % 3) * 0.065, cy - 0.028 + (k // 3) * 0.056
        parts.box("well%d" % k, (0.058, 0.050, 0.004), loc=(ix, iy, z + 0.061), mat=black, bev=0.001, seg=1)
        for j in range(4):
            jx, jy = ix + rng.uniform(-0.014, 0.014), iy + rng.uniform(-0.012, 0.012)
            if k in (0, 3):     # lime wedges
                w = parts.sphere("lw%d%d" % (k, j), 0.016, 10, 6, mat=lime, scale=(1.0, 0.45, 0.45))
                F.cut(w, (0, 0, 0), (0, 0, -1), lime)
                core.freeze([w])
                w.location = (jx, jy, z + 0.062)
                w.rotation_euler = (0, 0, rng.uniform(0, 3.14))
            elif k in (1, 4):   # orange half-wheels
                ow = C.citrus_wheel("ow%d%d" % (k, j), 0.020, 0.005, ("#e87810", ("#f2a020", "#fcc860")), (jx, jy, z + 0.066),
                                    (math.radians(rng.uniform(60, 80)), 0, rng.uniform(0, 3.14)))
            else:               # cherries
                ch = mats.M("cherry", "#b4081a", 0.15).mat
                parts.sphere("ch%d%d" % (k, j), 0.0085, 12, 8, loc=(jx, jy, z + 0.070), mat=ch)
    # a folded white bar towel at the front left
    towel = mats.M("towel", "#f4f2ec", 0.95)
    tn = towel.node("ShaderNodeSeparateXYZ")
    towel.link(towel.coords(), tn.inputs[0])
    stripe = towel.math("MULTIPLY", towel.math("GREATER_THAN", tn.outputs["X"], -0.13), towel.math("LESS_THAN", tn.outputs["X"], -0.12))
    towel.link(towel.mix(stripe, "#f4f2ec", "#2a5a9a"), towel.bsdf.inputs["Base Color"])
    towel.bump(towel.noise(1500.0, 4.0).outputs["Fac"], 0.6, 0.0006)
    t = parts.rounded_panel("towel", 0.16, 0.10, 0.018, r=0.012, plane="XY", loc=(-0.07, -0.25, z + 0.009), mat=towel.mat, bev=0.004)
    F.lump(t, 0.02, 0.002)
