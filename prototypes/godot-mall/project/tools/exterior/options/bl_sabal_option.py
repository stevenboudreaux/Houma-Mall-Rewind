"""Workstream LOT tree option C (Nov 8 2026; design/godot-exterior.md "Tree options"): a sabal palm
built in Blender with every leaflet as geometry (no alpha cards, so nothing thins out at distance), one
material with vertex colours. A sketch for Steven's choice, not wired into the build.

  /home/user/bvenv/bin/python tools/exterior/options/bl_sabal_option.py <out.glb>
"""
import sys
import math
import random
import bpy
import bmesh
from mathutils import Vector, Matrix

out = sys.argv[-1]
random.seed(1969)
bpy.ops.wm.read_factory_settings(use_empty=True)
bm = bmesh.new()
col = bm.loops.layers.color.new("Col")


def face(vs, c):
    f = bm.faces.new([bm.verts.new(v) for v in vs])
    for l in f.loops:
        l[col] = (c[0], c[1], c[2], 1.0)


# the trunk: tapered, 12 sides, grey-brown with darker boot bands
H = 6.5
segs = 14
for i in range(segs):
    y0 = H * i / segs; y1 = H * (i + 1) / segs
    r0 = 0.24 - 0.05 * i / segs; r1 = 0.24 - 0.05 * (i + 1) / segs
    sh = 0.42 if i % 2 else 0.36
    for k in range(12):
        a0 = 2 * math.pi * k / 12; a1 = 2 * math.pi * (k + 1) / 12
        face([(r0 * math.cos(a0), r0 * math.sin(a0), y0), (r0 * math.cos(a1), r0 * math.sin(a1), y0),
              (r1 * math.cos(a1), r1 * math.sin(a1), y1), (r1 * math.cos(a0), r1 * math.sin(a0), y1)],
             (sh, sh * 0.9, sh * 0.78))
top = Vector((0, 0, H))


def fan(yaw, elev):
    d = Vector((math.cos(yaw), math.sin(yaw), 0))
    up = Vector((0, 0, 1))
    dirv = (d * math.cos(elev) + up * math.sin(elev)).normalized()
    plen = random.uniform(0.9, 1.3)
    hast = top + dirv * plen
    # the petiole
    side = d.cross(up).normalized() * 0.03
    face([top - side, top + side, hast + side, hast - side], (0.30, 0.36, 0.20))
    # the leaflets fan out in the plane across the petiole, ~260 degrees, drooping at their tips
    across = d.cross(up).normalized()
    fup = (dirv + up * 0.3).normalized()
    g = random.uniform(0.85, 1.1)
    n = 34
    for i in range(n):
        t = -1.0 + 2.0 * i / (n - 1)
        ang = t * math.radians(125)
        ld = (fup * math.cos(ang) + across * math.sin(ang)).normalized()
        L = random.uniform(0.85, 1.05) * (1.0 - 0.25 * abs(t))
        w = 0.05
        pts = []
        p = hast
        for s in range(4):
            f = (s + 1) / 4
            droop = Vector((0, 0, -0.55 * f * f * L))
            q = hast + ld * (L * f) + droop
            pts.append((p, q, w * (1.0 - 0.7 * f)))
            p = q
        nrm = ld.cross(across).normalized()
        if nrm.length < 0.1:
            nrm = up
        wv = ld.cross(nrm).normalized()
        shade = (0.20 * g, 0.36 * g, 0.16 * g) if i % 2 else (0.25 * g, 0.42 * g, 0.20 * g)
        for a, b, ww in pts:
            # a folded leaflet: two strips meeting at a raised rib
            rib = nrm * ww * 0.6
            face([a - wv * ww, b - wv * ww * 0.6, b + rib * 0.6, a + rib], shade)
            face([a + rib, b + rib * 0.6, b + wv * ww * 0.6, a + wv * ww], shade)


for i in range(26):
    yaw = i * 2.39996 + random.uniform(-0.1, 0.1)
    elev = math.radians([60, 22, -15][i % 3] + random.uniform(-10, 10))
    fan(yaw, elev)

me = bpy.data.meshes.new("sabal")
bm.to_mesh(me)
ob = bpy.data.objects.new("sabal", me)
bpy.context.collection.objects.link(ob)
mat = bpy.data.materials.new("sabal_vc")
mat.use_nodes = True
nt = mat.node_tree
bsdf = nt.nodes["Principled BSDF"]
vc = nt.nodes.new("ShaderNodeVertexColor"); vc.layer_name = "Col"
nt.links.new(vc.outputs["Color"], bsdf.inputs["Base Color"])
bsdf.inputs["Roughness"].default_value = 0.85
bsdf.inputs["Metallic"].default_value = 0.0
me.materials.append(mat)
print("tris", sum(len(p.vertices) - 2 for p in me.polygons))
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=True, export_yup=True)
