"""A striped bag of caramel corn from Karmelkorn (1995 map, store s57). Hand item.

A flat-bottomed paper bag in red and white vertical stripes, open at the top and heaped with glossy
caramel corn. The label is generic (CARAMEL CORN in a cream oval): the tenant's own bag print is not
documented, so no wordmark is put on the product (IP rule: invented or generic on products).

References: design/storefronts/karmelkorn.md (the red-and-cream shop, caramel corn heaped under glass);
no photo of the bag. Size: a medium bag ~95 x 60 mm at the base, 190 mm tall. Guessed: the stripes, the
label, the bag's shape.
Origin: bottom centre.
"""
import math
import random
import bmesh
import bpy
from PIL import Image, ImageDraw
from lib import core, parts, mats, labels

BW, BD, BH = 0.095, 0.060, 0.190    # bag width (X), depth (Y), height
SEED = 5
CORN = ["#7a3a0c", "#b8661a", "#dc9a3c", "#f2c878"]

META = {
    "id": "bl_kk_caramelcorn",
    "class": "hand",
    "tex": 1024,
    "ao": 0.4,
    "refs": [],
    "item_file": "blender_props_2.json",
    "item": {"name": "Caramel corn", "year": 1995, "store": "KARMELKORN",
             # on the L counter's steel top (store2.gd karmelkorn(): o = P(W-1.6, 0, 1.6) = (-21.6, 0, 61.6),
             # glass to 1.25, steel top 1.25-1.28; register at x -22.6..-23.5; customers on the -z side)
             "place": {"wing": 2, "year": 1995, "pos": [-24.9, 1.28, 61.95], "yaw": 195}},
}


def stripes_art():
    """Round the bag: red and white stripes, a cream oval label front and back."""
    w, h = 2048, 1024
    im = Image.new("RGBA", (w, h), (250, 248, 240, 255))
    d = ImageDraw.Draw(im)
    n = 28
    for k in range(n):
        if k % 2 == 0:
            d.rectangle((k * w / n, 0, (k + 1) * w / n, h), fill=(206, 24, 34, 255))
    for cx in (w * 0.25, w * 0.75):
        d.ellipse((cx - 250, h * 0.42 - 140, cx + 250, h * 0.42 + 140), fill=(248, 236, 204, 255), outline=(150, 20, 24, 255), width=12)
        labels.text(d, (cx, h * 0.38), "CARAMEL", "bold", 68, (150, 20, 24, 255))
        labels.text(d, (cx, h * 0.48), "CORN", "bold", 80, (150, 20, 24, 255))
    return labels.save(im, "kk_bag_stripes")


def bag_mat():
    m = mats.M("bag", "#faf8f0", 0.6)
    tc = m.coords()
    sep = m.node("ShaderNodeSeparateXYZ")
    m.link(tc, sep.inputs[0])
    # unwrap by angle round the bag (front = -Y at u 0.25)
    ang = m.math("ARCTAN2", sep.outputs["Y"], sep.outputs["X"])
    u = m.math("MULTIPLY_ADD", ang, 1.0 / math.tau, 0.5)
    v = m.math("MULTIPLY", sep.outputs["Z"], 1.0 / BH)
    cv = m.node("ShaderNodeCombineXYZ")
    m.link(u, cv.inputs[0])
    m.link(v, cv.inputs[1])
    tex = m.node("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(stripes_art(), check_existing=True)
    m.link(cv.outputs[0], tex.inputs["Vector"])
    m.link(tex.outputs["Color"], m.bsdf.inputs["Base Color"])
    m.bump(m.noise(400.0, 3.0).outputs["Fac"], 0.12, 0.0004)
    return m.mat


def bag():
    """A gusseted bag: a rounded-rectangle section, bulging a little, the sides' gussets folding in near the
    open top; solidified paper."""
    bm = bmesh.new()
    nr, seg = 10, 32
    rings = []
    for j in range(nr + 1):
        z = BH * j / nr
        bulge = 1.0 + 0.06 * math.sin(math.pi * min(1.0, z / (BH * 0.85)))
        top = max(0.0, (z - BH * 0.8) / (BH * 0.2))
        ring = []
        for i in range(seg):
            a = math.tau * i / seg
            c, s = math.cos(a), math.sin(a)
            # superellipse: a rounded rectangle
            x = math.copysign(abs(c) ** 0.45, c) * BW / 2 * bulge
            y = math.copysign(abs(s) ** 0.45, s) * BD / 2 * bulge
            # the gussets: the side faces (|x| large) fold inward toward the top
            x *= 1.0 - 0.10 * top * abs(c) ** 3
            y *= 1.0 - 0.18 * top * (1.0 - abs(s))
            zz = z + (0.004 * math.sin(a * 3 + 1.0) if j == nr else 0.0)   # the uneven torn-open top
            ring.append(bm.verts.new((x, y, zz)))
        rings.append(ring)
    bottom = bm.faces.new(list(reversed(rings[0])))
    bmesh.ops.poke(bm, faces=[bottom])
    for a, b in zip(rings, rings[1:]):
        for i in range(seg):
            bm.faces.new((a[i], a[(i + 1) % seg], b[(i + 1) % seg], b[i]))
    ob = core.obj_from_bmesh("bag", bm, bag_mat(), smooth=True)
    core.solidify(ob, 0.0006, -1.0)
    return ob


def corn_mat():
    m = mats.M("corn", CORN[2], 0.25)
    tc = m.coords()
    n = m.noise(260.0, 4.0, coord=tc)
    col = m.ramp(n.outputs["Fac"], [(0.3, CORN[0]), (0.45, CORN[1]), (0.6, CORN[2]), (0.75, CORN[3])])
    m.link(col, m.bsdf.inputs["Base Color"])
    m.bump(m.noise(900.0, 3.0, coord=tc).outputs["Fac"], 0.5, 0.0005)
    m.link(m.ramp(n.outputs["Fac"], [(0.3, "#2e2e2e"), (0.7, "#6a6a6a")]), m.bsdf.inputs["Roughness"])   # glossy glaze
    return m.mat


def build():
    rng = random.Random(SEED)
    bag()
    cm = corn_mat()
    # the heap: a lumpy mound filling the top, and loose popped kernels piled on it
    mound = parts.sphere("mound", 1.0, 20, 8, loc=(0, 0, BH - 0.012), mat=cm, scale=(BW / 2 * 0.98, BD / 2 * 0.98, 0.022))
    tex = bpy.data.textures.new("pop", "CLOUDS")
    tex.noise_scale = 0.008
    d = mound.modifiers.new("Lumps", "DISPLACE")
    d.texture = tex
    d.texture_coords = "OBJECT"
    d.strength = 0.007
    for k in range(34):
        x = rng.uniform(-BW / 2 * 0.85, BW / 2 * 0.85)
        y = rng.uniform(-BD / 2 * 0.85, BD / 2 * 0.85)
        rr = (x / (BW / 2)) ** 2 + (y / (BD / 2)) ** 2
        z = BH + 0.004 + 0.014 * (1.0 - rr) + rng.uniform(0, 0.006)
        r = rng.uniform(0.0075, 0.010)
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=r, location=(x, y, z))
        ob = bpy.context.active_object
        ob.name = "kernel"
        ob.scale = (rng.uniform(0.8, 1.25), rng.uniform(0.8, 1.25), rng.uniform(0.7, 1.0))
        ob.rotation_euler = (rng.uniform(0, 3), rng.uniform(0, 3), rng.uniform(0, 3))
        ob.data.materials.append(cm)
        dd = ob.modifiers.new("Puff", "DISPLACE")
        dd.texture = tex
        dd.texture_coords = "OBJECT"
        dd.strength = 0.004
        for p in ob.data.polygons:
            p.use_smooth = True
