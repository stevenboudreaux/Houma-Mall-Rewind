"""A corn dog from Corn Dog 7 (Steven's test item; FOOD3D, Nov 8 2026: the cornmeal crust, batter_mat()). Hand item, year "both": the same tenant in 1995 and 2026.

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
BATTER = ["#6e360c", "#a85a14", "#cc8020", "#e0a03a"]   # dark crust -> pale cornmeal (ramp)
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
             # SHOPS (design/godot-shops.md): 1995 shown on the counter, bought from the attendant; 2026 (no attendant
             # there; Steven, Nov 4: "keep the corn dog pickup in 2026") a pick-up on the counter, as before
             "display": {"wing": 2, "year": 1995, "pos": [-134.6, 1.03, 74.5], "yaw": 90, "runtime": True},
             "place": {"wing": 2, "year": 2026, "pos": [-134.6, 1.03, 74.5], "yaw": 90}},
}


def batter_mat(name="batter"):
    """FOOD3D (Nov 8 2026): a cornmeal crust, not a glaze. Broad golden-to-brown fryer colour; cornmeal grain
    (fine dark and pale specks); fryer bubbles (small round blisters, browner rims); a few cracks; dry and
    matte with oily highlights on the high points. All baked (albedo, ORM, normal)."""
    m = mats.M(name, BATTER[2], 0.62)
    tc = m.coords()
    big = m.noise(40.0, 6.0, 0.6, coord=tc)
    mid = m.noise(140.0, 4.0, 0.55, coord=tc)
    t = m.math("ADD", big.outputs["Fac"], m.math("MULTIPLY", m.math("SUBTRACT", mid.outputs["Fac"], 0.5), 0.45))
    col = m.ramp(t, [(0.25, BATTER[0]), (0.39, BATTER[1]), (0.52, BATTER[2]), (0.68, BATTER[3])])
    # cornmeal grain: dense small cells, some darker (toasted), some paler (raw meal)
    gr = m.node("ShaderNodeTexVoronoi", Scale=1500.0)
    m.link(tc, gr.inputs["Vector"])
    gsep = m.node("ShaderNodeSeparateColor")
    m.link(gr.outputs["Color"], gsep.inputs[0])
    dark = m.math("LESS_THAN", gsep.outputs[0], 0.18)
    pale = m.math("GREATER_THAN", gsep.outputs[0], 0.86)
    col = m.mix(m.math("MULTIPLY", dark, 0.35), col, "#6a3410")
    col = m.mix(m.math("MULTIPLY", pale, 0.5), col, "#f0c770")
    # fryer bubbles: small round blisters with browner rims
    bub = m.node("ShaderNodeTexVoronoi", Scale=260.0)
    m.link(tc, bub.inputs["Vector"])
    bd = bub.outputs["Distance"]
    blister = m.math("LESS_THAN", bd, 0.32)
    rim = m.math("MULTIPLY", m.math("GREATER_THAN", bd, 0.26), blister)
    col = m.mix(m.math("MULTIPLY", rim, 0.45), col, BATTER[0])
    # cracks: only some cell edges
    vor = m.node("ShaderNodeTexVoronoi", Scale=38.0)
    vor.feature = "DISTANCE_TO_EDGE"
    m.link(tc, vor.inputs["Vector"])
    crack = m.ramp(vor.outputs["Distance"], [(0.0, "#404040"), (0.03, "#ffffff")])
    sel = m.math("GREATER_THAN", m.noise(25.0, 2.0, coord=tc).outputs["Fac"], 0.62)
    cr = m.math("MULTIPLY", m.math("SUBTRACT", 1.0, crack), sel)
    col = m.mix(cr, col, CRACK)
    m.link(col, m.bsdf.inputs["Base Color"])
    # height: blisters up, grain, cracks down
    h = m.math("ADD", m.math("MULTIPLY", m.math("SUBTRACT", 0.32, m.math("MINIMUM", bd, 0.32)), 2.2),
               m.math("MULTIPLY", m.noise(700.0, 2.0, coord=tc).outputs["Fac"], 0.35))
    h = m.math("SUBTRACT", h, m.math("MULTIPLY", cr, 0.8))
    m.bump(h, 0.7, 0.0007)
    # dry crust, oily on the high, pale points
    rough = m.math("SUBTRACT", 0.78, m.math("MULTIPLY", m.math("GREATER_THAN", big.outputs["Fac"], 0.62), 0.3))
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
