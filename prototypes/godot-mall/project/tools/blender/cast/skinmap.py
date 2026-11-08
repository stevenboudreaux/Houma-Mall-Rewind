"""The LOD maps: hm08's skin decimated once per LOD (Blender collapse, X symmetry) by zone, stored as
barycentrics onto hm08, so every person, morph, weight and garment shell carries over:

  every low vertex = sum of 3 hm08 vertices x weights (its closest point on hm08)

Zones (decimated separately, in one mesh: each pass protects the other zones with a vertex group):
  face  the front of the head (eyes, nose, mouth, cheeks, brows, chin)  -> LOD0 kept whole
  head  the rest of the head and the neck (mostly under hair)
  hands hands and fingers
  body  everything else (mostly under clothes: the clothes are cut from this surface)

  /home/claude/bvenv/bin/python tools/blender/cast/skinmap.py      -> .scratch/cast/map_lod0.npz, map_lod1.npz
"""
import os
import sys

import bpy
import bmesh
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import person  # noqa: E402,F401
import mh  # noqa: E402
from topo import quads_to_tris, MAPS  # noqa: E402

# per LOD: ratio kept per zone
LODS = {"lod0": {"face": 0.85, "head": 0.3, "hands": 0.13, "feet": 0.15, "body": 0.34},
        "lod1": {"face": 0.17, "head": 0.12, "hands": 0.05, "feet": 0.07, "body": 0.15}}


def zones(b):
    W = mh.weights()
    N = mh.N_BODY
    names = list(W.keys())
    M = np.zeros((N, len(names)))
    for j, k in enumerate(names):
        a = np.array(W[k]); a = a[a[:, 0] < N]
        M[a[:, 0].astype(int), j] = a[:, 1]
    M /= np.maximum(M.sum(1, keepdims=True), 1e-9)
    def s(*keys):
        return M[:, [j for j, n in enumerate(names) if any(k in n for k in keys)]].sum(1)
    head = s("Head") + s("Neck")
    hands = s("Hand")
    feet = s("Foot", "Toe")
    v = b.v[:N]
    eyes = b.v[b.verts_of("joint-l-eye")].mean(0); eyes[0] = 0
    rel = v - eyes
    # the face: the front of the head, from the hairline to under the chin, ear to ear (not the ears)
    face = (head > 0.5) & (rel[:, 2] > -0.045) & (rel[:, 1] < 0.115) & (rel[:, 1] > -0.135) & (np.abs(rel[:, 0]) < 0.068)
    z = np.full(N, "body", object)
    z[feet > 0.5] = "feet"
    z[hands > 0.5] = "hands"
    z[head > 0.5] = "head"
    z[face] = "face"
    return z


def main():
    b = mh.Base()
    v = b.v.copy()
    N = mh.N_BODY
    fi = b.faces_of("body")
    q = b.f[fi]
    T = quads_to_tris(q)
    Z = zones(b)
    os.makedirs(MAPS, exist_ok=True)
    for lod, ratios in LODS.items():
        bpy.ops.wm.read_factory_settings(use_empty=True)
        me = bpy.data.meshes.new("skin")
        me.from_pydata(v[:N].tolist(), [], q.tolist())
        uvl = me.uv_layers.new(name="UV")
        uvl.data.foreach_set("uv", b.uv[b.fuv[fi]].reshape(-1, 2).ravel())
        ob = bpy.data.objects.new("skin", me)
        bpy.context.scene.collection.objects.link(ob)
        bpy.context.view_layer.objects.active = ob
        ob.select_set(True)
        for zone in ("feet", "hands", "body", "head", "face"):
            r = ratios[zone]
            if r >= 0.999:
                continue
            # vertex group: 1 = may collapse (this zone), 0 = protected
            bm = bmesh.new(); bm.from_mesh(ob.data); bm.verts.ensure_lookup_table()
            co = np.array([x.co[:] for x in bm.verts]); bm.free()
            # zone of each current vertex = zone of the nearest hm08 vertex
            from mathutils.kdtree import KDTree
            kd = KDTree(N)
            for i, p in enumerate(v[:N]):
                kd.insert(p, i)
            kd.balance()
            zc = np.array([Z[kd.find(p)[1]] for p in co])
            vg = ob.vertex_groups.new(name="z_" + zone)
            ids = np.nonzero(zc == zone)[0].tolist()
            vg.add(ids, 1.0, "REPLACE")
            n_zone_tris = len(ids) * 2
            mod = ob.modifiers.new("dec", "DECIMATE")
            mod.decimate_type = "COLLAPSE"
            mod.use_symmetry = True
            mod.symmetry_axis = "X"
            mod.vertex_group = vg.name
            mod.vertex_group_factor = 1000.0
            mod.use_collapse_triangulate = True
            # aim the zone at r of its triangles: overall ratio = 1 - (removed / total)
            tot = sum(len(p.vertices) - 2 for p in ob.data.polygons)
            want = tot - n_zone_tris * (1 - r)
            mod.ratio = max(0.02, want / tot)
            bpy.ops.object.modifier_apply(modifier="dec")
            ob.vertex_groups.remove(ob.vertex_groups["z_" + zone])
            print(lod, zone, "->", sum(len(p.vertices) - 2 for p in ob.data.polygons), "tris")
        bm = bmesh.new(); bm.from_mesh(ob.data)
        bmesh.ops.triangulate(bm, faces=bm.faces[:])
        bm.verts.ensure_lookup_table()
        lo_v = np.array([x.co[:] for x in bm.verts])
        lay = bm.loops.layers.uv["UV"]
        tri = np.array([[l.vert.index for l in f.loops] for f in bm.faces])
        luv = np.array([[l[lay].uv[:] for l in f.loops] for f in bm.faces])
        bm.free()
        src, bw = closest(v[:N], T, lo_v)
        np.savez_compressed(os.path.join(MAPS, "map_%s.npz" % lod), tri=tri, src=src, bw=bw, luv=luv)
        err = np.linalg.norm((v[src] * bw[..., None]).sum(1) - lo_v, axis=1)
        zc = Z[src[np.arange(len(src)), bw.argmax(1)]]
        per = {z: int((zc[tri].tolist().count(z) if False else 0)) for z in ("face",)}
        tz = Z[src[tri[:, 0], bw[tri[:, 0]].argmax(1)]]
        print("MAP %s: %d tris, %d verts; error mean %.2f mm max %.2f mm; per zone %s" % (
            lod, len(tri), len(lo_v), err.mean() * 1000, err.max() * 1000,
            {z: int((tz == z).sum()) for z in ("face", "head", "hands", "feet", "body")}))


def closest(V, T, P):
    from mathutils.bvhtree import BVHTree
    from mathutils import Vector
    bvh = BVHTree.FromPolygons(V.tolist(), T.tolist(), all_triangles=True)
    src = np.zeros((len(P), 3), np.int64); bw = np.zeros((len(P), 3))
    for i, p in enumerate(P):
        loc, nrm, idx, d = bvh.find_nearest(Vector(p))
        a, b2, c = V[T[idx]]
        src[i] = T[idx]; bw[i] = bary(np.array(loc), a, b2, c)
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
    main()
