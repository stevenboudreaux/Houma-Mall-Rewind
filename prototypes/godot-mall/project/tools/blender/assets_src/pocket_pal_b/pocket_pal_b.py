"""Route B of the device bake-off (design/godot-device-bakeoff.md): what a free AI image-to-3D model makes
of the organizer, cleaned up to the same budget. NOT a usable device: evidence only.

Source mesh: Tencent Hunyuan3D-2mini (turbo, shape only), run on this cloud box's CPU from one cut-out video
still (production/qa/evidence/wsDEV-ref-064.jpg). The raw mesh is not in the repo (.scratch/blender/src/
pocket_pal_b_raw.glb; the steps to make it again are in the design note). It is a copy of the reference
organizer's shape, so it could never ship as the invented Pocket Pal; and the open model gives shape only
(its texture stage needs a 16 GB GPU), so the clean-up paints it one plain charcoal plastic.

Clean-up done here, all automatic (the pipeline's sculpt path, tools/blender/build.py META["hipoly"]):
keep the largest connected piece, turn it to lie like route A, scale it to route A's width, then the driver
voxel-remeshes, decimates to 8,000 triangles and bakes normal + AO. No hand modelling.
Run: mkdir -p .scratch/blender/pocket_pal_b && tools/blender/run.sh pocket_pal_b/pocket_pal_b
Origin: bottom centre.
"""
import os

import bmesh
import bpy
from mathutils import Matrix

from lib import core, mats, labels

RAW = os.path.join(labels.SRC, "pocket_pal_b_raw.glb")
WIDTH = 0.166                 # route A's width
BODY = "#2a2c2f"

META = {
    "id": "pocket_pal_b",
    "class": "small_fixture",       # the pipeline's 10k class; the device budget is the hipoly target below
    "out": "hud",
    "tex": 2048,
    "ao": 0.55,
    "hipoly": 8000,
    "cage": 0.004,
    "refs": [["production/qa/evidence/wsDEV-ref-064.jpg", [0.22, 0.0, 0.78, 1.0], "the still it was fed (0:63)"]],
}


def build():
    bpy.ops.import_scene.gltf(filepath=RAW)
    obs = core.mesh_objects()
    for o in obs:
        core.apply_all(o)
    core.select_only(obs, obs[0])
    if len(obs) > 1:
        with bpy.context.temp_override(active_object=obs[0], selected_editable_objects=obs, selected_objects=obs):
            bpy.ops.object.join()
    ob = obs[0]
    ob.parent = None
    for o in list(bpy.context.scene.objects):
        if o is not ob:
            bpy.data.objects.remove(o)
    # keep the largest connected piece (generators leave floating crumbs)
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bm.verts.ensure_lookup_table()
    seen, groups = set(), []
    for v in bm.verts:
        if v.index in seen:
            continue
        stack, grp = [v], []
        seen.add(v.index)
        while stack:
            a = stack.pop()
            grp.append(a)
            for e in a.link_edges:
                b = e.other_vert(a)
                if b.index not in seen:
                    seen.add(b.index)
                    stack.append(b)
        groups.append(grp)
    groups.sort(key=len, reverse=True)
    print("ROUTE B raw: %d verts, %d tris, %d pieces (largest %d verts)" % (len(bm.verts), len(bm.faces), len(groups), len(groups[0])))
    for g in groups[1:]:
        bmesh.ops.delete(bm, geom=g, context="VERTS")
    # lay it flat, face up: the slab's thin axis (smallest spread of the points) becomes +Z. The generator
    # leaves the face leaning toward the viewer (Blender -Y, up), which settles the sign
    import numpy as np
    P = np.array([v.co[:] for v in bm.verts])
    P -= P.mean(0)
    w, V = np.linalg.eigh(np.cov(P.T))
    n = V[:, 0]
    if n @ np.array([0.0, -1.0, 1.0]) < 0:
        n = -n
    x = np.array([1.0, 0.0, 0.0])
    x = x - n * (x @ n)
    x /= np.linalg.norm(x)
    y = np.cross(n, x)
    rot = Matrix(((x[0], x[1], x[2], 0), (y[0], y[1], y[2], 0), (n[0], n[1], n[2], 0), (0, 0, 0, 1)))
    bmesh.ops.transform(bm, matrix=rot, verts=bm.verts)
    xs = [v.co.x for v in bm.verts]
    s = WIDTH / (max(xs) - min(xs))
    bmesh.ops.scale(bm, vec=(s, s, s), verts=bm.verts)
    lo = [min(v.co[i] for v in bm.verts) for i in range(3)]
    hi = [max(v.co[i] for v in bm.verts) for i in range(3)]
    bmesh.ops.translate(bm, vec=(-(lo[0] + hi[0]) / 2, -(lo[1] + hi[1]) / 2, -lo[2]), verts=bm.verts)
    bm.to_mesh(ob.data)
    bm.free()
    ob.matrix_world = Matrix.Identity(4)
    core.set_mat(ob, mats.plastic("body", BODY, 0.6, 0.05, 900.0))
