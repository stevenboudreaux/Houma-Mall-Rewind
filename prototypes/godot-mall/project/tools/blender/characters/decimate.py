"""The game-budget skin (and, with "6600 lo2_map", the coarser skin outer garments are cut from): hm08's 13380-vertex skin decimated once (Blender collapse, X symmetry, the
face, hands and feet kept denser) and stored as a barycentric map onto hm08:

  every low vertex = sum of 3 hm08 vertices x weights (its closest point on the hm08 surface)

so the low skin of ANY body shape is A @ coords: every blend shape, joint weight and region carries
over exactly, for both sexes, without re-decimating. Output: .scratch/chars/lo_map.npz
(tri: (T,3) low vertex ids, src: (V,3) hm08 vertex ids, bw: (V,3) weights, luv: (T,3,2) corner UVs).

  BPY python decimate.py [skin tris, default 13200]
"""
import os
import sys

import bpy
import bmesh
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mh  # noqa: E402


def main(target=13200, name="lo_map"):
    b = mh.Base()
    v = b.v.copy()
    fi = b.faces_of("body")
    q = b.f[fi]
    me = bpy.data.meshes.new("skin")
    used = np.unique(q)
    assert used.max() < mh.N_BODY
    me.from_pydata(v[:mh.N_BODY].tolist(), [], q.tolist())
    uvl = me.uv_layers.new(name="UV")
    corner_uv = b.uv[b.fuv[fi]].reshape(-1, 2)
    uvl.data.foreach_set("uv", corner_uv.ravel())
    ob = bpy.data.objects.new("skin", me)
    bpy.context.scene.collection.objects.link(ob)
    # keep detail where people look: face, hands, feet (weight 0 = decimated least)
    vg = ob.vertex_groups.new(name="spare")
    W = mh.weights()
    keep = np.zeros(mh.N_BODY)
    for k, lst in W.items():
        if any(s in k for s in ("Head", "Hand", "Foot", "Toe", "Neck")):
            a = np.array(lst)
            ids = a[:, 0].astype(int)
            ids = ids[ids < mh.N_BODY]
            keep[ids] = np.maximum(keep[ids], a[a[:, 0] < mh.N_BODY, 1])
    w = 1 - 1.0 * np.clip(keep, 0, 1)   # weight 1 = collapsed first (Blender), so face / hands / feet a bit less
    for i in range(mh.N_BODY):
        vg.add([i], float(w[i]), "REPLACE")
    hi_tris = len(q) * 2
    mod = ob.modifiers.new("dec", "DECIMATE")
    mod.decimate_type = "COLLAPSE"
    mod.use_symmetry = True
    mod.symmetry_axis = "X"
    # (a vertex group to spare the face was tried: Blender treats it as nearly on/off, 2.9k or 8k head tris)
    mod.vertex_group_factor = 0.002
    mod.use_collapse_triangulate = True
    # iterate the ratio until the triangle count is just under the target
    r = target / hi_tris
    for _ in range(8):
        mod.ratio = r
        dg = bpy.context.evaluated_depsgraph_get()
        n = len(ob.evaluated_get(dg).data.loop_triangles) if False else None
        ev = ob.evaluated_get(dg)
        m2 = ev.to_mesh(); m2.calc_loop_triangles(); n = len(m2.loop_triangles); ev.to_mesh_clear()
        if n <= target and n > target * 0.97:
            break
        r *= target / n * 0.995
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.modifier_apply(modifier="dec")
    bm = bmesh.new(); bm.from_mesh(ob.data)
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bm.verts.ensure_lookup_table()
    lo_v = np.array([x.co[:] for x in bm.verts])
    uvlay = bm.loops.layers.uv["UV"]
    tri = np.array([[l.vert.index for l in f.loops] for f in bm.faces])
    luv = np.array([[l[uvlay].uv[:] for l in f.loops] for f in bm.faces])
    bm.free()
    # closest point on hm08's triangles for every low vertex
    from body import quads_to_tris
    T = quads_to_tris(q)
    src, bw = closest(v, T, lo_v)
    out = os.path.join(mh.PROJ, ".scratch", "chars", name + ".npz")
    np.savez_compressed(out, tri=tri, src=src, bw=bw, luv=luv)
    err = np.linalg.norm((v[src] * bw[..., None]).sum(1) - lo_v, axis=1)
    print("LO", len(tri), "tris", len(lo_v), "verts; surface error mean %.2f mm, max %.2f mm" % (err.mean() * 1000, err.max() * 1000))


def closest(V, T, P):
    """For each point, the closest triangle (by brute force over nearby triangles) and barycentrics."""
    from mathutils.bvhtree import BVHTree
    from mathutils import Vector
    bvh = BVHTree.FromPolygons(V.tolist(), T.tolist(), all_triangles=True)
    src = np.zeros((len(P), 3), np.int64); bw = np.zeros((len(P), 3))
    for i, p in enumerate(P):
        loc, nrm, idx, d = bvh.find_nearest(Vector(p))
        a, b2, c = V[T[idx]]
        w = bary(np.array(loc), a, b2, c)
        src[i] = T[idx]; bw[i] = w
    return src, bw


def bary(p, a, b, c):
    v0, v1, v2 = b - a, c - a, p - a
    d00, d01, d11 = v0 @ v0, v0 @ v1, v1 @ v1
    d20, d21 = v2 @ v0, v2 @ v1
    den = d00 * d11 - d01 * d01
    y = (d11 * d20 - d01 * d21) / den
    z = (d00 * d21 - d01 * d20) / den
    w = np.clip([1 - y - z, y, z], 0, 1)
    return w / w.sum()


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    main(int(argv[0]) if argv else 13200, argv[1] if len(argv) > 1 else "lo_map")
