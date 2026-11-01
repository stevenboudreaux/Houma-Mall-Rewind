"""Lo mein from Tee Tai's (1995 map, store s35). Hand item.

A white paper takeout pail (the folded "oyster pail" of the period) with a wire handle, open, heaped with
lo mein: soft brown-glazed noodles with carrot slivers, cabbage, snow peas and broccoli, and a pair of
split wooden chopsticks stuck in. The print is a small generic red pagoda and THANK YOU, no brand.

References: refs/era_1995/other/other_1.jpg (Steven's 1990s photo of Tee Tai's front: the lanterns and the
lit food pictures over the counter; the counter itself is not readable, so the pail is chosen over a
styrofoam plate as the more recognisable takeout look); design/storefronts/tee-tais.md (the menu: Lo Mein).
Size: a US pint pail, ~95 mm tall, 62 mm square base opening to ~92 mm. Guessed: the vegetables, the print.

How: the pail is a thin folded frustum (solidified) with the four corner gussets folded flat; the noodle
heap is a displaced dome whose strands are a baked wave pattern (albedo + normal), with ~14 loose noodles
on top as real tubes; vegetables are small low-poly pieces.
Origin: bottom centre.
"""
import math
import random
import bmesh
import bpy
from mathutils import Vector, Matrix
from lib import core, parts, mats, labels
from PIL import Image, ImageDraw

B, T, H = 0.062, 0.092, 0.095        # base side, top side, height
WALL = 0.0007
SEED = 11
NOODLE = ["#a9732c", "#d9a656"]      # soy-glazed wheat noodles: dark -> light

META = {
    "id": "bl_tt_lomein",
    "class": "hand",
    "tex": 1024,
    "ao": 0.45,
    "refs": [["refs/era_1995/other/other_1.jpg", [0.45, 0.05, 1.0, 0.75], "Tee Tai's, 1990s (Steven)"]],
    "item_file": "blender_props_2.json",
    "item": {"name": "Lo mein", "year": 1995, "store": "TEE TAI'S",
             # on the counter's top at its right end, clear of the steam table and its sneeze guard
             # (wave8.gd tee_tai(): co = P(W-0.2, 0, 2.5) = (21.8, 0, 8.5), top 0.95, customers on the -z side)
             "place": {"wing": 1, "year": 1995, "pos": [21.6, 0.95, 8.12], "yaw": 160}},
}


def print_art():
    w, h = 600, 600
    im, d = labels.canvas(w, h, (0, 0, 0, 0))
    red = (200, 26, 30, 255)
    cx = w // 2
    # a generic three-roof pagoda
    for k, (y, half, th) in enumerate(((120, 120, 26), (220, 150, 26), (320, 180, 28))):
        d.polygon([(cx - half, y + th), (cx - half + 30, y), (cx + half - 30, y), (cx + half, y + th)], fill=red)
        d.line([(cx - half, y + th), (cx - half - 18, y + th - 18)], fill=red, width=10)
        d.line([(cx + half, y + th), (cx + half + 18, y + th - 18)], fill=red, width=10)
        d.rectangle((cx - half + 50, y + th, cx + half - 50, y + th + 70), outline=red, width=8)
    d.polygon([(cx, 50), (cx - 70, 120), (cx + 70, 120)], fill=red)
    d.rectangle((cx - 200, 420, cx + 200, 430), fill=red)
    labels.text(d, (cx, 500), "THANK YOU", "bold", 74, red)
    return labels.save(im, "tt_lomein_print")


def pail():
    """The folded pail: a square frustum, open at the top, solidified; a printed side facing -Y."""
    m = mats.M("paper", "#f4f2ea", 0.7)
    art = print_art()
    c = mats.decal(m, art, (0, -(B + T) / 4 - 0.002, H * 0.5), (0.055, 0.055), "XZ", facing="-Y")
    mats.decal(m, art, (0, (B + T) / 4 + 0.002, H * 0.5), (0.055, 0.055), "XZ", base=c, flip_u=True, facing="+Y")
    m.bump(m.noise(400.0, 2.0).outputs["Fac"], 0.08, 0.0003)
    bm = bmesh.new()
    rings = []
    for z, s in ((0.0, B), (H * 0.5, (B + T) / 2), (H, T)):
        rings.append([bm.verts.new((x * s / 2, y * s / 2, z)) for x, y in ((-1, -1), (1, -1), (1, 1), (-1, 1))])
    bm.faces.new(list(reversed(rings[0])))
    for a, b in zip(rings, rings[1:]):
        for i in range(4):
            bm.faces.new((a[i], a[(i + 1) % 4], b[(i + 1) % 4], b[i]))
    ob = core.obj_from_bmesh("pail", bm, m.mat)
    core.bevel(ob, 0.006, 2, angle=30, harden=False)   # the rounded folds at the corners
    core.solidify(ob, WALL, -1.0)
    # the wire handle: a thin steel arc over the top, hooked through two sides
    steel = mats.brushed_metal("wire", "#b4b4b8", 0.35)
    pts = []
    for i in range(9):
        t = i / 8
        ang = math.pi * t
        pts.append((-(T / 2 + 0.0015) * math.cos(ang), 0.0, H - 0.012 + 0.075 * math.sin(ang)))
    parts.tube_path("handle", pts, 0.0009, seg=4, mat=steel)
    for sx in (-1, 1):
        parts.tube_path("hook", [(sx * (T / 2 + 0.0015), 0.0, H - 0.012), (sx * (T / 2 - 0.002), 0.0, H - 0.016)], 0.0009, seg=4, mat=steel)


def noodle_mat():
    m = mats.M("noodles", NOODLE[1], 0.25)
    tc = m.coords()
    # strands: a wave pattern, distorted, in two crossing directions so it reads as a tangle
    w1 = m.node("ShaderNodeTexWave", wave_type="BANDS", bands_direction="X")
    w1.inputs["Scale"].default_value = 150.0
    w1.inputs["Distortion"].default_value = 5.0
    w1.inputs["Detail"].default_value = 3.0
    m.link(tc, w1.inputs["Vector"])
    w2 = m.node("ShaderNodeTexWave", wave_type="BANDS", bands_direction="Y")
    w2.inputs["Scale"].default_value = 140.0
    w2.inputs["Distortion"].default_value = 6.0
    w2.inputs["Detail"].default_value = 3.0
    m.link(tc, w2.inputs["Vector"])
    sel = m.noise(60.0, 2.0, coord=tc)
    s = m.math("GREATER_THAN", sel.outputs["Fac"], 0.5)
    strands = m.mix(s, w1.outputs["Fac"], w2.outputs["Fac"])
    col = m.ramp(strands, [(0.15, "#8a5a22"), (0.5, NOODLE[0]), (0.8, NOODLE[1])])
    m.link(col, m.bsdf.inputs["Base Color"])
    m.bump(strands, 0.9, 0.0012)
    return m.mat


def build():
    rng = random.Random(SEED)
    pail()
    nm = noodle_mat()
    # the heap: a dome from just under the rim, bulging over it, lumpy
    heap = parts.sphere("heap", 1.0, 24, 10, loc=(0, 0, H - 0.004), mat=nm, scale=(T / 2 + 0.001, T / 2 + 0.001, 0.021))
    bm = bmesh.new()
    bm.from_mesh(heap.data)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < -0.006], context="VERTS")
    bm.to_mesh(heap.data)
    tex = bpy.data.textures.new("heaplumps", "CLOUDS")
    tex.noise_scale = 0.015
    d = heap.modifiers.new("Lumps", "DISPLACE")
    d.texture = tex
    d.texture_coords = "OBJECT"
    d.strength = 0.006
    # loose noodles on top and spilling over the rim
    glaze = nm
    for k in range(11):
        a0 = rng.uniform(0, math.tau)
        r0 = rng.uniform(0.0, 0.030)
        pts = []
        z_top = H + 0.020 + rng.uniform(0, 0.005)
        for j in range(5):
            t = j / 4
            a = a0 + t * rng.uniform(1.2, 2.4)
            r = r0 + t * rng.uniform(0.010, 0.030)
            z = z_top - 0.016 * (r / 0.045) ** 2 - (0.02 * (r - 0.045) / 0.01 if r > 0.045 else 0.0) + 0.002 * math.sin(t * 7 + k)
            pts.append((r * math.cos(a), r * math.sin(a), z))
        parts.tube_path("noodle", pts, 0.0019, seg=4, mat=glaze)
    # vegetables
    carrot = mats.M("carrot", "#e8781e", 0.45).mat
    cabbage = mats.M("cabbage", "#d9e2b0", 0.55).mat
    pea = mats.M("snowpea", "#5c9a2e", 0.45).mat
    broc = mats.M("broccoli", "#3f6e22", 0.8)
    broc.bump(broc.noise(900.0, 2.0).outputs["Fac"], 0.8, 0.0008)
    for k in range(9):
        a, r = rng.uniform(0, math.tau), rng.uniform(0.005, 0.034)
        z = H + 0.018 - (r / 0.045) ** 2 * 0.016
        ob = parts.box("carrot", (0.024, 0.0026, 0.0026), loc=(r * math.cos(a), r * math.sin(a), z), mat=carrot, bev=0.0004, seg=1)
        ob.rotation_euler = (rng.uniform(-0.4, 0.4), rng.uniform(-0.5, 0.5), rng.uniform(0, math.pi))
    for k in range(5):
        a, r = rng.uniform(0, math.tau), rng.uniform(0.004, 0.03)
        z = H + 0.017 - (r / 0.045) ** 2 * 0.016
        ob = parts.box("cabbage", (0.018, 0.010, 0.0012), loc=(r * math.cos(a), r * math.sin(a), z), mat=cabbage, bev=0.0005, seg=1)
        ob.rotation_euler = (rng.uniform(-0.6, 0.6), rng.uniform(-0.6, 0.6), rng.uniform(0, math.pi))
    for k in range(3):
        a, r = rng.uniform(0, math.tau), rng.uniform(0.008, 0.028)
        z = H + 0.018 - (r / 0.045) ** 2 * 0.016
        ob = parts.sphere("snowpea", 1.0, 10, 4, loc=(r * math.cos(a), r * math.sin(a), z), mat=pea, scale=(0.015, 0.0048, 0.0018))
        ob.rotation_euler = (rng.uniform(-0.4, 0.4), rng.uniform(-0.4, 0.4), rng.uniform(0, math.pi))
    for k in range(3):
        a, r = rng.uniform(0, math.tau), rng.uniform(0.010, 0.028)
        z = H + 0.016 - (r / 0.045) ** 2 * 0.016
        c = Vector((r * math.cos(a), r * math.sin(a), z))
        parts.cylinder("stem", 0.0028, 0.012, verts=6, loc=tuple(c + Vector((0, 0, -0.002))), mat=pea, bev=0)
        for j in range(4):
            off = Vector((rng.uniform(-0.004, 0.004), rng.uniform(-0.004, 0.004), 0.005 + rng.uniform(0, 0.002)))
            parts.sphere("floret", 0.0045, 6, 4, loc=tuple(c + off), mat=broc.mat)
    # disposable wooden chopsticks, split, stuck in at an angle toward the back
    wood = mats.M("chopsticks", "#e2cb98", 0.65)
    wood.bump(wood.noise(300.0, 3.0).outputs["Fac"], 0.2, 0.0004)
    for k, (dx, lean) in enumerate(((-0.006, 16), (0.006, 22))):
        L = 0.21
        base = Vector((dx, 0.004, H - 0.01))
        dirv = Vector((0.0, math.sin(math.radians(lean)), math.cos(math.radians(lean))))
        ob = parts.cylinder("chopstick", 0.0028, L, verts=6, mat=wood.mat, bev=0.0002, r2=0.0016)
        ob.location = base + dirv * (L / 2 - 0.04)
        ob.rotation_euler = (-math.radians(lean), math.radians(-4 if k == 0 else 3), 0)
