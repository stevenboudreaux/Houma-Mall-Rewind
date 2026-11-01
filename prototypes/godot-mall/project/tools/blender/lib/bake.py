"""Bake every authoring material of one joined object into one texture set and one Principled material.

UV0: Smart UV Project over the whole object (one atlas, even texel density), unless the asset passes
uv='keep' (its own UVs are already a non-overlapping 0-1 layout).
Maps (PNG, power of two):
  <asset>_albedo.png  base colour (sRGB), optionally darkened by baked ambient occlusion (META ao)
  <asset>_orm.png     R = AO, G = roughness, B = metallic (linear; glTF's occlusion/metallicRoughness layout)
  <asset>_normal.png  tangent-space normal (OpenGL +Y, which glTF and Godot use) from the materials' bump
Materials marked bake=False (glass, emissive screens) are left as flat Principled materials in their own slot.
"""
import os
import bpy
import numpy as np

from . import core


def _img(name, size, non_color, fill):
    im = bpy.data.images.new(name, size, size, alpha=False, float_buffer=False)
    im.generated_color = fill
    if non_color:
        im.colorspace_settings.name = "Non-Color"
    return im


def _baked_mats(ob):
    return [m for m in ob.data.materials if m is not None and m.get("bake", True)]


def uv_unwrap(ob, margin=0.004):
    core.select_only([ob], ob)
    while ob.data.uv_layers:
        ob.data.uv_layers.remove(ob.data.uv_layers[0])
    ob.data.uv_layers.new(name="UVMap")
    with bpy.context.temp_override(active_object=ob, object=ob, selected_objects=[ob], selected_editable_objects=[ob]):
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=margin, area_weight=0.0, correct_aspect=True, scale_to_bounds=False)
        bpy.ops.uv.pack_islands(rotate=True, margin=margin)
        bpy.ops.object.mode_set(mode="OBJECT")


def _target_node(mat, im):
    nt = mat.node_tree
    n = nt.nodes.get("__bake_target") or nt.nodes.new("ShaderNodeTexImage")
    n.name = "__bake_target"
    n.image = im
    nt.nodes.active = n
    return n


def _emit_swap(mat, socket_name):
    """Route a Principled input (linked or constant) to an Emission shader on the output; returns undo info."""
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    out = next(n for n in nt.nodes if n.type == "OUTPUT_MATERIAL" and n.is_active_output)
    old = out.inputs["Surface"].links[0].from_socket if out.inputs["Surface"].links else None
    em = nt.nodes.new("ShaderNodeEmission")
    em.name = "__bake_emit"
    sock = bsdf.inputs[socket_name]
    if sock.links:
        nt.links.new(sock.links[0].from_socket, em.inputs["Color"])
    else:
        v = sock.default_value
        em.inputs["Color"].default_value = tuple(v) if hasattr(v, "__len__") else (v, v, v, 1.0)
    nt.links.new(em.outputs["Emission"], out.inputs["Surface"])
    return (mat, em, old, out)


def _emit_restore(info):
    mat, em, old, out = info
    if old is not None:
        mat.node_tree.links.new(old, out.inputs["Surface"])
    mat.node_tree.nodes.remove(em)


def _bake(ob, kind, im, mats, samples, source=None, cage=0.02):
    sc = bpy.context.scene
    sc.cycles.samples = samples
    sc.render.bake.margin = 16
    sc.render.bake.margin_type = "EXTEND"
    sc.render.bake.use_clear = True
    for m in ob.data.materials:
        if m is None:
            continue
        _target_node(m, im if m in mats else _img("__dummy", 8, True, (0, 0, 0, 1)))
    sel = [ob] + ([source] if source else [])
    core.select_only(sel, ob)
    kw = {}
    if source:
        # high-poly -> low-poly: rays cast from a cage pushed out along the low mesh's normals
        kw = dict(use_selected_to_active=True, cage_extrusion=cage, max_ray_distance=cage * 2.5)
    with bpy.context.temp_override(active_object=ob, object=ob, selected_objects=sel, selected_editable_objects=sel):
        if kind == "NORMAL":
            bpy.ops.object.bake(type="NORMAL", normal_space="TANGENT", **kw)
        elif kind == "AO":
            bpy.ops.object.bake(type="AO", **kw)
        else:
            bpy.ops.object.bake(type="EMIT", **kw)


def _px(im):
    a = np.empty(len(im.pixels), dtype=np.float32)
    im.pixels.foreach_get(a)
    return a.reshape(im.size[1], im.size[0], 4)


def bake_object(ob, asset, out_dir, size=1024, ao=0.0, normal=True, uv="smart", samples=16, source=None, cage=0.02):
    """Bake and swap in the final material bl_<asset>_baked. Returns the list of written PNG paths.
    source: a high-poly object whose materials and surface detail are baked onto `ob` (selected-to-active;
    every source material is baked, none kept flat)."""
    os.makedirs(out_dir, exist_ok=True)
    if uv == "smart":
        uv_unwrap(ob)
    if source:
        tmp = bpy.data.materials.new("__bake_low")
        tmp.use_nodes = True
        ob.data.materials.clear()
        ob.data.materials.append(tmp)
        mats = [m for m in source.data.materials if m]
    else:
        mats = _baked_mats(ob)
    alb = _img(asset + "_albedo", size, False, (0.5, 0.5, 0.5, 1))
    rough = _img("__rough", size, True, (0.5, 0.5, 0.5, 1))
    metal = _img("__metal", size, True, (0, 0, 0, 1))
    nrm = _img(asset + "_normal", size, True, (0.5, 0.5, 1, 1))
    for im, sock in ((alb, "Base Color"), (rough, "Roughness"), (metal, "Metallic")):
        infos = [_emit_swap(m, sock) for m in mats]
        _bake(ob, "EMIT", im, [ob.data.materials[0]] if source else mats, 4, source, cage)
        for i in infos:
            _emit_restore(i)
    if normal:
        _bake(ob, "NORMAL", nrm, [ob.data.materials[0]] if source else mats, 4, source, cage)
    aoim = None
    if ao > 0:
        aoim = _img("__ao", size, True, (1, 1, 1, 1))
        bpy.context.scene.world = bpy.context.scene.world or bpy.data.worlds.new("w")
        _bake(ob, "AO", aoim, [ob.data.materials[0]] if source else mats, max(32, samples * 4), source, cage)
    # pack ORM, fold AO into albedo (stored sRGB: multiply in display space, close enough for AO)
    R = _px(rough)
    Mt = _px(metal)
    A = _px(aoim) if aoim else np.ones_like(R)
    orm = np.ones_like(R)
    orm[..., 0] = A[..., 0]
    orm[..., 1] = R[..., 0]
    orm[..., 2] = Mt[..., 0]
    ormim = _img(asset + "_orm", size, True, (1, 1, 1, 1))
    ormim.pixels.foreach_set(orm.ravel())
    if aoim:
        P = _px(alb)
        P[..., :3] *= (1.0 - ao + ao * A[..., :1])
        alb.pixels.foreach_set(P.ravel())
    written = []
    for im in [alb, ormim] + ([nrm] if normal else []):
        p = os.path.join(out_dir, im.name + ".png")
        im.filepath_raw = p
        im.file_format = "PNG"
        im.save()
        written.append(p)
    # the final material
    fm = bpy.data.materials.new("%s_baked" % asset if asset.startswith("bl_") else "bl_%s_baked" % asset)
    fm.use_nodes = True
    nt = fm.node_tree
    b = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    ta = nt.nodes.new("ShaderNodeTexImage"); ta.image = alb
    nt.links.new(ta.outputs["Color"], b.inputs["Base Color"])
    to = nt.nodes.new("ShaderNodeTexImage"); to.image = ormim
    sep = nt.nodes.new("ShaderNodeSeparateColor")
    nt.links.new(to.outputs["Color"], sep.inputs["Color"])
    nt.links.new(sep.outputs["Green"], b.inputs["Roughness"])
    nt.links.new(sep.outputs["Blue"], b.inputs["Metallic"])
    if normal:
        tn = nt.nodes.new("ShaderNodeTexImage"); tn.image = nrm
        nm = nt.nodes.new("ShaderNodeNormalMap")
        nt.links.new(tn.outputs["Color"], nm.inputs["Color"])
        nt.links.new(nm.outputs["Normal"], b.inputs["Normal"])
    # swap: every baked slot -> the final material
    for i, m in enumerate(ob.data.materials):
        if m in mats or source:
            ob.data.materials[i] = fm
    # merge duplicate slots
    _merge_slots(ob)
    for m in ob.data.materials:
        if m and "__bake_target" in m.node_tree.nodes:
            m.node_tree.nodes.remove(m.node_tree.nodes["__bake_target"])
    return written


def _merge_slots(ob):
    me = ob.data
    first = {}
    remap = []
    for i, m in enumerate(me.materials):
        key = m.name if m else None
        if key not in first:
            first[key] = len(first)
        remap.append(first[key])
    idx = np.empty(len(me.polygons), dtype=np.int32)
    me.polygons.foreach_get("material_index", idx)
    idx = np.array(remap, dtype=np.int32)[idx]
    uniq = [None] * len(first)
    for i, m in enumerate(me.materials):
        uniq[remap[i]] = m
    me.materials.clear()
    for m in uniq:
        me.materials.append(m)
    me.polygons.foreach_set("material_index", idx)
