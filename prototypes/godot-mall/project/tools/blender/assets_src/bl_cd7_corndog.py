"""A corn dog from Corn Dog 7 (Steven's test item). Hand item, year "both": the same tenant in 1995 and 2026.

References: refs/derived/signs/corndog_IMG_4461_f005.jpg and refs/derived/frames/IMG_4461 f004-f006 show the
stand (yellow awning, navy tile), not the food; design/storefronts/corn-dog-7.md, tools/stores/corn_dog_7.gd.
The corn dog itself is a period type, guessed: a hand-dipped dog in golden-brown cornmeal batter, lumpy and
cracked from the fryer, darker where it browned, on a plain birch stick, with a squiggle of yellow mustard.
No packaging (the stand's real 1995 paper is not documented, so none is invented).

Lumps are real geometry (a Clouds Displace on a subdivided lathe); cracks, colour and the fine crust are
procedural and baked into albedo/ORM/normal.
Origin: the bottom of the stick, held upright (+Y up in Godot).
"""
import math
import bpy
from lib import core, parts, mats

# ---- numbers (metres) ---------------------------------------------------------------------------
STICK_R = 0.0028
STICK_LEN = 0.200           # the stick runs from 0 up into the batter
BODY = [                    # lathe profile (radius, height): the batter, bottom drip to rounded top
    (0.0031, 0.074), (0.0062, 0.079), (0.0110, 0.087), (0.0158, 0.097), (0.0190, 0.110), (0.0204, 0.130),
    (0.0210, 0.160), (0.0206, 0.190), (0.0192, 0.210), (0.0162, 0.222), (0.0112, 0.231), (0.0050, 0.236), (0.0, 0.238)]
BODY_SEG = 28
LUMP_SIZE = 0.016           # Clouds noise size
LUMP_DEPTH = 0.0034         # displacement strength
BEND = 3.0                  # degrees the dog leans off the stick axis (hand-dipped, not machine-straight)
MUSTARD_R = 0.0024
MUSTARD_ZIGS = 6
BATTER = ["#6a360c", "#a45c17", "#c88024", "#dc9f3e"]   # dark crust -> pale cornmeal (ramp)
CRACK = "#7a400f"

META = {
    "id": "bl_cd7_corndog",
    "class": "hand",
    "tex": 1024,
    "ao": 0.35,
    "refs": [
        ["refs/derived/signs/corndog_IMG_4461_f005.jpg", [0.12, 0.18, 1.0, 0.62], "IMG_4461 f005 (the stand)"],
        ["refs/derived/frames/IMG_4461/f005.jpg", None, "IMG_4461 f005"],
    ],
    "item": {"name": "Corn dog", "year": "both", "store": "CORN DOG 7",
             # SHOPS (design/godot-shops.md): shown on the counter, bought from the attendant (not picked up)
             "display": {"wing": 2, "year": "both", "pos": [-134.6, 1.03, 74.5], "yaw": 90, "runtime": True}},
}


def batter_mat():
    m = mats.M("batter", BATTER[2], 0.55)
    tc = m.coords()
    big = m.noise(55.0, 5.0, 0.55, coord=tc)
    col = m.ramp(big.outputs["Fac"], [(0.30, BATTER[0]), (0.45, BATTER[1]), (0.60, BATTER[2]), (0.75, BATTER[3])])
    vor = m.node("ShaderNodeTexVoronoi", Scale=38.0)
    vor.feature = "DISTANCE_TO_EDGE"
    m.link(tc, vor.inputs["Vector"])
    crack = m.ramp(vor.outputs["Distance"], [(0.0, "#404040"), (0.03, "#ffffff")])   # 0 in the cracks
    # only some cell edges crack: mask by a second noise
    mask = m.noise(25.0, 2.0, coord=tc)
    sel = m.math("GREATER_THAN", mask.outputs["Fac"], 0.6)
    inv = m.math("SUBTRACT", 1.0, crack)
    cr = m.math("MULTIPLY", inv, sel)
    final = m.mix(cr, col, CRACK)
    m.link(final, m.bsdf.inputs["Base Color"])
    fine = m.noise(320.0, 3.0, 0.6, coord=tc)
    h = m.math("SUBTRACT", fine.outputs["Fac"], cr)
    m.bump(h, 0.55, 0.0006)
    rough = m.math("MULTIPLY_ADD", big.outputs["Fac"], 0.3)       # a little oily sheen on the pale bits
    m.nt.nodes[rough.node.name].inputs[2].default_value = 0.35
    m.link(rough, m.bsdf.inputs["Roughness"])
    return m.mat


def wood_mat():
    m = mats.M("stick", "#d8c095", 0.7)
    tc = m.coords()
    mp = m.node("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (300.0, 300.0, 6.0)
    m.link(tc, mp.inputs["Vector"])
    n = m.noise(1.0, 4.0, coord=mp.outputs["Vector"])
    m.link(m.ramp(n.outputs["Fac"], [(0.35, "#c7a874"), (0.65, "#e2cfa6")]), m.bsdf.inputs["Base Color"])
    return m.mat


def build():
    body = parts.lathe("batter", BODY, seg=BODY_SEG, mat=batter_mat(), cap=False)
    core.subsurf(body, 1)
    tex = bpy.data.textures.new("lumps", "CLOUDS")
    tex.noise_scale = LUMP_SIZE
    tex.noise_depth = 2
    d = body.modifiers.new("Lumps", "DISPLACE")
    d.texture = tex
    d.texture_coords = "OBJECT"
    d.strength = LUMP_DEPTH
    d.mid_level = 0.5
    body.rotation_euler = (math.radians(BEND), 0, 0)
    parts.cylinder("stick", STICK_R, STICK_LEN, verts=10, loc=(0, 0, STICK_LEN / 2), mat=wood_mat(), bev=0.0006)
    # mustard: a zigzag laid on the front (-Y) face of the batter, following the lean
    pts = []
    n = MUSTARD_ZIGS * 4
    z0, z1 = 0.115, 0.218
    for i in range(n + 1):
        t = i / n
        z = z0 + (z1 - z0) * t
        r = max(rr for rr, zz in BODY if abs(zz - z) < 0.016) + LUMP_DEPTH * 0.5 + MUSTARD_R * 0.6
        a = math.radians(-90 + (34 + 8 * math.sin(t * 7.3)) * math.sin(t * MUSTARD_ZIGS * math.pi + 0.4 * math.sin(t * 5.1)))
        p = (r * math.cos(a), r * math.sin(a), z)
        # follow the lean (rotation about X)
        c, s = math.cos(math.radians(BEND)), math.sin(math.radians(BEND))
        pts.append((p[0], p[1] * c - p[2] * s, p[1] * s + p[2] * c))
    parts.tube_path("mustard", pts, MUSTARD_R, seg=8, mat=mats.M("mustard", "#e2b20e", 0.3).mat,
                         taper=[0.6] + [1.0] * (len(pts) - 2) + [0.6])
