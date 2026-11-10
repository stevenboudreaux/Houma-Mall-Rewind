"""The Cycles beauty render of a Pocket Pal test model (design/godot-device-bakeoff.md): the exported
in-game .glb (what Godot gets: baked atlas, budget mesh), three-quarter view, 1920 x 1080.
  /home/claude/bvenv/bin/python tools/blender/assets_src/pocket_pal_shots/beauty.py <glb> <out.png> [samples]"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.abspath(os.path.join(HERE, "..", "..")))
import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402
from lib import core, render, mats  # noqa: E402

glb, out = sys.argv[1], sys.argv[2]
samples = int(sys.argv[3]) if len(sys.argv) > 3 else 256
vis = render.import_glb(glb)
lo, hi = core.bounds(vis)
c = (lo + hi) / 2
r = (hi - lo).length / 2
render.studio(0.05, 1.0)
sc = bpy.context.scene
sc.cycles.samples = samples
sc.render.resolution_x, sc.render.resolution_y = 1920, 1080
sc.render.image_settings.file_format = "PNG"
sc.view_settings.look = "AgX - Medium High Contrast"

# the LCD: a flat test card, no text (the game draws the real screens later)
from PIL import Image, ImageDraw  # noqa: E402
W, H = 1320, 400
bg, ink = (125, 138, 104), (34, 42, 30)
im = Image.new("RGB", (W, H), bg)
d = ImageDraw.Draw(im)
d.rectangle((0, 0, W - 1, H - 1), outline=ink, width=8)
for k in range(8):
    t = k / 7.0
    d.rectangle((44 + k * 154, 40, 44 + (k + 1) * 154 - 1, 120), fill=tuple(int(a + (b - a) * t) for a, b in zip(bg, ink)))
for y in range(12):
    for x in range(12):
        if (x + y) % 2 == 0:
            d.rectangle((44 + x * 17, 156 + y * 17, 44 + x * 17 + 16, 156 + y * 17 + 16), fill=ink)
for k in range(40):
    if k % 4 < 1 + k // 14:
        for row in range(0, 6, 2):
            d.rectangle((300 + k * 24, 156 + row * 34, 300 + k * 24 + 23, 156 + row * 34 + 33), fill=ink)
card = os.path.join(os.path.dirname(out), "_testcard.png")
im.save(card)
for ob in vis:
    for i, m in enumerate(ob.data.materials):
        if m and m.name.split(".")[0].endswith("_lcd"):
            nt = m.node_tree
            b = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
            t = nt.nodes.new("ShaderNodeTexImage")
            t.image = bpy.data.images.load(card)
            nt.links.new(t.outputs["Color"], b.inputs["Base Color"])
            b.inputs["Roughness"].default_value = 0.18
            b.inputs["Coat Weight"].default_value = 0.6
            b.inputs["Coat Roughness"].default_value = 0.08

# a desk: dark laminate with a soft sheen
import bmesh  # noqa: E402
bm = bmesh.new()
bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=3.0)
fl = core.obj_from_bmesh("desk", bm)
fl.location.z = lo.z - 0.0002
dm = mats.M("bl_beauty_desk", "#3a2a22", 0.38)
n = dm.noise(3.0, 8.0, 0.6)
mp = dm.node("ShaderNodeMapping")
mp.inputs["Scale"].default_value = (1.0, 14.0, 1.0)
dm.link(dm.coords("Object"), mp.inputs["Vector"])
dm.link(mp.outputs["Vector"], n.inputs["Vector"])
dm.link(dm.ramp(n.outputs["Fac"], [(0.3, "#241812"), (0.7, "#4a3528")]), dm.bsdf.inputs["Base Color"])
fl.data.materials.append(dm.mat)

# lights: a big soft key from the upper left (a mall skylight), a warm fill, a cool rim that rakes the keys
def light(name, energy, loc, size, color):
    ld = bpy.data.lights.new(name, "AREA")
    ld.energy, ld.size, ld.color = energy, size, color
    ob = bpy.data.objects.new(name, ld)
    core.link(ob)
    ob.location = c + Vector(loc)
    ob.rotation_euler = (c - ob.location).to_track_quat("-Z", "Y").to_euler()
light("key", 14.0, (-0.45, -0.25, 0.55), 0.45, (1.0, 0.97, 0.92))
light("fill", 2.2, (0.55, -0.45, 0.20), 0.5, (1.0, 0.86, 0.72))
light("rim", 9.0, (0.25, 0.60, 0.22), 0.25, (0.80, 0.90, 1.0))

cam = render.camera(28.0)
render.aim(cam, c + Vector((0, 0, -0.006)), r, 32, 30, 1.02, 28.0)
cam.data.dof.use_dof = True
cam.data.dof.focus_distance = (cam.location - (c + Vector((0, -0.01, 0)))).length
cam.data.dof.aperture_fstop = 11.0
sc.render.filepath = out
bpy.ops.render.render(write_still=True)
print("BEAUTY " + out)
