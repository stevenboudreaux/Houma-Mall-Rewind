"""Decimation maps for MakeHuman assets (clothes, shoes, hair): Blender collapse on the asset's own mesh,
every low vertex stored as barycentrics on the asset's full mesh, so the decimated asset fits any body
(fit the full asset, then blend) and keeps its UVs.

  /home/claude/bvenv/bin/python tools/blender/cast/assetmap.py <asset rel> <lod0 ratio> <lod1 ratio> ...
  e.g. clothes/male_casualsuit06 0.42 0.14  -> .scratch/cast/amap_clothes_male_casualsuit06_lod0.npz, _lod1.npz
A ratio of 1 copies the asset as is.
"""
import os
import sys

import bpy
import bmesh
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import mhasset  # noqa: E402
from topo import MAPS  # noqa: E402
from skinmap import closest  # noqa: E402


def map_path(rel, lod):
    return os.path.join(MAPS, "amap_%s_%s.npz" % (rel.replace("/", "_"), lod))


def decimate(V, T, CUV, ratio, sym=True):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    me = bpy.data.meshes.new("a")
    me.from_pydata(V.tolist(), [], T.tolist())
    uv = me.uv_layers.new(name="UV")
    c = CUV.copy(); c[..., 1] = 1 - c[..., 1]
    uv.data.foreach_set("uv", c.reshape(-1))
    ob = bpy.data.objects.new("a", me)
    bpy.context.scene.collection.objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    mod = ob.modifiers.new("d", "DECIMATE")
    mod.decimate_type = "COLLAPSE"
    mod.use_collapse_triangulate = True
    mod.use_symmetry = sym
    mod.symmetry_axis = "X"
    mod.ratio = ratio
    bpy.ops.object.modifier_apply(modifier="d")
    bm = bmesh.new(); bm.from_mesh(ob.data)
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bm.verts.ensure_lookup_table()
    lay = bm.loops.layers.uv["UV"]
    lv = np.array([x.co[:] for x in bm.verts])
    tri = np.array([[l.vert.index for l in f.loops] for f in bm.faces])
    luv = np.array([[l[lay].uv[:] for l in f.loops] for f in bm.faces])
    bm.free()
    luv[..., 1] = 1 - luv[..., 1]
    return lv, tri, luv


def main(rel, ratios):
    a = mhasset.Asset(rel)
    V = a.coord * 0.1
    for lod, r in zip(("lod0", "lod1"), ratios):
        if r >= 0.999:
            n = len(V)
            np.savez_compressed(map_path(rel, lod), tri=a.tri, src=np.stack([np.arange(n)] * 3, 1),
                                bw=np.tile([1.0, 0, 0], (n, 1)), cuv=a.cuv)
            print("AMAP %s %s: %d tris (as is)" % (rel, lod, len(a.tri)))
            continue
        lv, tri, luv = decimate(V, a.tri, a.cuv, r, sym=not rel.startswith("hair/"))
        src, bw = closest(V, a.tri, lv)
        np.savez_compressed(map_path(rel, lod), tri=tri, src=src, bw=bw, cuv=luv)
        print("AMAP %s %s: %d -> %d tris" % (rel, lod, len(a.tri), len(tri)))


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    for i in range(0, len(argv), 3):
        main(argv[i], [float(argv[i + 1]), float(argv[i + 2])])
