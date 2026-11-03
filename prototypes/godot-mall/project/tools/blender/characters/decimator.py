"""Blender collapse decimation of a garment part, keeping corner UVs and the colour-region index."""
import numpy as np
import bpy
import bmesh


def decimate(P, T, CUV, mat, target):
    me = bpy.data.meshes.new("dec")
    me.from_pydata(P.tolist(), [], T.tolist())
    uv = me.uv_layers.new(name="UV")
    uv.data.foreach_set("uv", CUV.reshape(-1).tolist())
    me.polygons.foreach_set("material_index", np.asarray(mat, np.int32).tolist())
    for _ in range(int(np.max(mat)) + 1):
        me.materials.append(None)
    ob = bpy.data.objects.new("dec", me)
    bpy.context.scene.collection.objects.link(ob)
    mod = ob.modifiers.new("d", "DECIMATE")
    mod.decimate_type = "COLLAPSE"
    mod.use_collapse_triangulate = True
    mod.use_symmetry = True
    mod.symmetry_axis = "X"
    mod.ratio = min(1.0, target / max(len(T), 1))
    dg = bpy.context.evaluated_depsgraph_get()
    ev = ob.evaluated_get(dg)
    m2 = bpy.data.meshes.new_from_object(ev)
    bm = bmesh.new(); bm.from_mesh(m2)
    bmesh.ops.triangulate(bm, faces=bm.faces[:])
    bm.verts.ensure_lookup_table()
    lay = bm.loops.layers.uv["UV"]
    V = np.array([v.co[:] for v in bm.verts])
    T2 = np.array([[l.vert.index for l in f.loops] for f in bm.faces], np.int64)
    C2 = np.array([[l[lay].uv[:] for l in f.loops] for f in bm.faces])
    M2 = np.array([f.material_index for f in bm.faces], np.int64)
    bm.free()
    bpy.data.objects.remove(ob); bpy.data.meshes.remove(me); bpy.data.meshes.remove(m2)
    return V, T2, C2, M2
