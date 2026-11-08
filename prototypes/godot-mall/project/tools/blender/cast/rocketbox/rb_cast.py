"""A cast member from a Rocketbox person (Steven, Nov 8 2026: Rocketbox, MIT): tools/blender/cast/<id>.json
with a "rocketbox" source -> cast/<id>.glb + cast/<id>.json, the same contract as the MakeHuman path
(design/godot-cast.md): one skeleton (Mixamo names, Ch01 rests; eye.L / eye.R / jaw under the head), LOD0 +
LOD1, the cast's named morphs, 3 materials (body, head, hair/lashes alpha), Cast.body(id) loads it.

    /home/claude/bvenv/bin/python tools/blender/cast/rocketbox/rb_cast.py <id>

Steps: rb2glb.py converts (rename, T-pose, Ch01 rests, ARKit + visemes, HEAVY build push) -> clothes
repainted to the uniform (rb_paint.py) -> generated pieces (tie, badge) on the shirt -> resting-face edits
(more open lids, a fuller face for heavier builds) -> the cast's named morphs from the ARKit shapes ->
tone tweaks on the skin -> the head + hair surfaces split into a morph mesh (blend shapes cost memory per
vertex: the body carries none) -> LOD1 decimated -> export.
"""
import json
import math
import os
import subprocess
import sys

import bpy
import bmesh
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
CAST_TOOLS = os.path.dirname(HERE)
PROJ = os.path.abspath(os.path.join(CAST_TOOLS, "..", "..", ".."))
sys.path.insert(0, HERE); sys.path.insert(0, CAST_TOOLS)
import rb_paint  # noqa: E402
import raster  # noqa: E402

RB = os.path.join(PROJ, ".scratch", "rocketbox", "Assets", "Avatars")
SCR = os.path.join(PROJ, ".scratch", "cast", "rb")
OUT = os.path.join(PROJ, "cast")
PY = sys.executable

# the cast's morph names (same names as the MakeHuman path, person.MORPHS) from ARKit shapes
NAMED = [
    ("blink_L", {"EyeBlinkLeft": 1.0, "EyeSquintLeft": 0.55}),
    ("blink_R", {"EyeBlinkRight": 1.0, "EyeSquintRight": 0.55}),
    ("squint_L", {"EyeSquintLeft": 1.0}), ("squint_R", {"EyeSquintRight": 1.0}),
    ("eyes_wide", {"EyeWideLeft": 1.0, "EyeWideRight": 1.0}),
    ("smile", {"MouthSmileLeft": 1.0, "MouthSmileRight": 1.0}),
    ("jaw_open", {"JawOpen": 1.0}),
    ("brow_up", {"BrowInnerUp": 1.0, "BrowOuterUpLeft": 1.0, "BrowOuterUpRight": 1.0}),
    ("brow_down", {"BrowDownLeft": 1.0, "BrowDownRight": 1.0}),
    ("brow_inner_up", {"BrowInnerUp": 1.0}),
    ("brow_up_L", {"BrowOuterUpLeft": 1.0, "BrowInnerUp": 0.5}),
    ("brow_up_R", {"BrowOuterUpRight": 1.0, "BrowInnerUp": 0.5}),
    ("mouth_pucker", {"MouthPucker": 1.0}),
    ("mouth_press", {"MouthPressLeft": 1.0, "MouthPressRight": 1.0}),
    ("mouth_wide", {"MouthStretchLeft": 1.0, "MouthStretchRight": 1.0}),
    ("mouth_funnel", {"MouthFunnel": 1.0}),
    ("frown", {"MouthFrownLeft": 1.0, "MouthFrownRight": 1.0}),
    ("lip_upper_up", {"MouthUpperUpLeft": 1.0, "MouthUpperUpRight": 1.0}),
    ("lips_part", {"MouthLowerDownLeft": 0.6, "MouthLowerDownRight": 0.6, "MouthUpperUpLeft": 0.3, "MouthUpperUpRight": 0.3}),
    ("sneer", {"NoseSneerLeft": 1.0, "NoseSneerRight": 1.0}),
]
KEEP_PREFIX = ("viseme_",)          # kept as they are, for lip sync later (15)
BONE_RENAME = {"mixamorig:LeftEye": "eye.L", "mixamorig:RightEye": "eye.R", "mixamorig:Jaw": "jaw"}

TOP = ("Spine", "Shoulder", "Arm", "Neck")       # dominant bone -> region (body texture)
LEGS = ("Hips", "UpLeg", "Leg")
FEET = ("Foot", "Toe")
HANDS = ("Hand",)


def b2g(v):
    """Blender (Z up, front -Y) -> glTF / Godot (Y up, front +Z)."""
    v = np.asarray(v, float)
    return np.stack([v[..., 0], v[..., 2], -v[..., 1]], -1)


def g2b(v):
    v = np.asarray(v, float)
    return np.stack([v[..., 0], -v[..., 2], v[..., 1]], -1)


def mesh_arrays(me):
    m = me.data
    m.calc_loop_triangles()
    n = len(m.vertices)
    co = np.empty(n * 3); m.vertices.foreach_get("co", co); co = co.reshape(-1, 3)
    tri = np.array([t.vertices[:] for t in m.loop_triangles])
    loops = np.array([t.loops[:] for t in m.loop_triangles])
    uvd = np.empty(len(m.loops) * 2); m.uv_layers.active.data.foreach_get("uv", uvd); uvd = uvd.reshape(-1, 2)
    cuv = uvd[loops].copy(); cuv[..., 1] = 1 - cuv[..., 1]       # image coordinates
    mat = np.array([t.material_index for t in m.loop_triangles])
    names = [g.name for g in me.vertex_groups]
    W = np.zeros((n, len(names)))
    for v in m.vertices:
        for g in v.groups:
            W[v.index, g.group] = g.weight
    return co, tri, cuv, mat, names, W


def region_codes(names, W):
    dom = [names[i] for i in W.argmax(1)]
    code = np.zeros(len(dom))
    for i, d in enumerate(dom):
        d = d.replace("mixamorig:", "")
        if any(k in d for k in HANDS): code[i] = 4
        elif any(k in d for k in FEET): code[i] = 3
        elif any(d.startswith(k) or d.endswith(k) for k in LEGS) and "Spine" not in d: code[i] = 2
        elif any(k in d for k in TOP): code[i] = 1
    return code


def free_rect(cov, w, h):
    """Top-left (x, y) of an empty w x h block in a coverage image, or None."""
    H, W = cov.shape
    ii = np.cumsum(np.cumsum(cov.astype(np.int32), 0), 1)
    ii = np.pad(ii, ((1, 0), (1, 0)))
    for y in range(0, H - h, 8):
        for x in range(0, W - w, 8):
            s = ii[y + h, x + w] - ii[y, x + w] - ii[y + h, x] + ii[y, x]
            if s == 0:
                return x, y
    return None


def main(pid):
    data = json.load(open(os.path.join(CAST_TOOLS, pid + ".json")))
    rb = data["rocketbox"]
    src = os.path.join(RB, rb["person"])
    name = os.path.basename(rb["person"])
    work = os.path.join(SCR, pid)
    os.makedirs(work, exist_ok=True)
    conv = os.path.join(work, "conv.glb")
    env = dict(os.environ, HEAVY=str(rb.get("heavy", 0)))
    r = subprocess.run([PY, os.path.join(HERE, "rb2glb.py"), src, conv], env=env, capture_output=True, text=True)
    stats = [l for l in r.stdout.splitlines() if l.startswith("STATS")]
    if r.returncode or not stats:
        print(r.stdout[-3000:], r.stderr[-3000:]); raise SystemExit("rb_cast: conversion failed")
    hips = float(stats[0].split("hips_z=")[1].split()[0])
    print(stats[0])
    bpy.ops.wm.open_mainfile(filepath=conv.replace(".glb", ".blend"))
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    me = next(o for o in bpy.data.objects if o.type == "MESH")
    mats = {m.name.split("_")[-1]: i for i, m in enumerate(me.data.materials)}     # body / head / opacity
    texdir = os.path.join(work, name + "_tex")

    def tex_of(key):
        m = me.data.materials[mats[key]]
        for nd in m.node_tree.nodes:
            if nd.type == "TEX_IMAGE" and nd.image and "normal" not in nd.image.name:
                return nd
        return None

    # ---- bones: the cast's names for the eyes and jaw
    for old, new in BONE_RENAME.items():
        b = arm.data.bones.get(old)
        if b:
            vg = me.vertex_groups.get(old)
            b.name = new
            if vg and vg.name != new:
                vg.name = new
    bpy.context.view_layer.update()
    J = {b.name: b2g(np.array(arm.matrix_world @ b.head_local)) for b in arm.data.bones}

    # ---- resting-face edits (lids a little more open, a fuller face for heavier builds)
    kb = me.data.shape_keys.key_blocks
    n = len(me.data.vertices)
    def kco(k):
        a = np.empty(n * 3); k.data.foreach_get("co", a); return a.reshape(-1, 3)
    basis = kco(kb[0])
    deltas = {k.name: kco(k) - basis for k in list(kb)[1:]}
    rest_edit = np.zeros_like(basis)
    for k, w in data.get("resting_face", {}).items():
        if k in deltas:
            rest_edit += float(w) * deltas[k]
    # face fill (heavier people): jaw, cheeks and neck pushed out along normals, fading toward the eyes
    ff = float(data.get("face_fill_m", 0.0))
    if ff > 0:
        me.data.update()
        nr = np.empty(n * 3); me.data.vertices.foreach_get("normal", nr); nr = nr.reshape(-1, 3)
        hb = arm.data.bones["mixamorig:Head"].head_local; nkb = arm.data.bones["mixamorig:Neck"].head_local
        eyez = (arm.data.bones["mixamorig:LeftEye"].head_local.z if "mixamorig:LeftEye" in arm.data.bones else hb.z + 0.08)
        z = basis[:, 2]
        hm_ = np.zeros(n, bool)
        for p in me.data.polygons:
            if p.material_index == mats["head"]:
                hm_[list(p.vertices)] = True
        w = np.clip((eyez - 0.015 - z) / 0.06, 0, 1) * np.clip((z - (nkb.z - 0.06)) / 0.05, 0, 1)
        front = np.clip(-nr[:, 1] * 0.5 + 0.6, 0.3, 1.0)
        rest_edit = rest_edit + nr * (ff * w * front * hm_)[:, None]
    basis2 = basis + rest_edit

    # ---- clothes repaint + tone (body texture), eyes + tone (head texture)
    co, tri, cuv, mat, names, W = mesh_arrays(me)
    co = basis2.copy()
    code = region_codes(names, W)
    P = b2g(co)
    nb = tex_of("body"); nh = tex_of("head"); no = tex_of("opacity")
    body_png = bpy.path.abspath(nb.image.filepath); head_png = bpy.path.abspath(nh.image.filepath)
    op_png = bpy.path.abspath(no.image.filepath)
    body = rb_paint.load(body_png); BH = body.shape[0]
    bm_ = mat == mats["body"]
    A = np.concatenate([P[tri[bm_]], code[tri[bm_]][..., None]], 2)
    img, cov = raster.raster(cuv[bm_], A, BH)
    region = np.where(cov, np.rint(img[..., 3]).astype(int), 0)
    # texels the raster missed (slivers, UV padding) take their nearest covered neighbour's region
    for _ in range(24):
        z = region == 0
        if not z.any():
            break
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            nbr = np.roll(np.roll(region, dy, 0), dx, 1)
            region = np.where((region == 0) & (nbr > 0), nbr, region)
    body2, skin_b = rb_paint.repaint_body(body, region, data.get("repaint", {}))
    head = rb_paint.load(head_png); HH = head.shape[0]
    hm = mat == mats["head"]
    eyeg = np.zeros(n)
    for bn in ("eye.L", "eye.R"):
        if bn in names: eyeg += W[:, names.index(bn)]
    A = np.concatenate([P[tri[hm]], eyeg[tri[hm]][..., None]], 2)
    himg, hcov = raster.raster(cuv[hm], A, HH)
    eye_mask = hcov & (himg[..., 3] > 0.5)
    head2, iris = rb_paint.eyes(head, eye_mask, data.get("eyes", {}))
    skin_h = hcov & ~eye_mask & rb_paint.classify(head, None) & (himg[..., 1] < J["mixamorig:Head"][1] + 0.12)
    ts = data.get("tone", {})
    eyes_pos = (J["eye.L"], J["eye.R"])
    head2 = rb_paint.tone(head2, skin_h, ts, himg[..., :3], eyes_pos)
    body2 = rb_paint.tone(body2, skin_b & (region == 4) | (skin_b & (region == 1)), ts)

    # ---- generated pieces (tie, badge) on the shirt, textured in a free block of the hair/lash atlas
    extra = []
    op = rb_paint.load(op_png, "RGBA"); OH = op.shape[0]
    om = mat == mats["opacity"]
    _, ocov = raster.raster(cuv[om], np.zeros((om.sum(), 3, 1)), OH, pad_px=3)
    gens = [g for g in data.get("garments", []) if g["type"] in ("tie", "nametag")]
    if gens:
        import clothes
        top_t = tri[bm_][(code[tri[bm_]] <= 2).all(1)]     # shirt + trousers: the front surface the pieces lie on
        top = {"pos": P, "tri": top_t, "W": W}
        class Ctx:
            pass
        ctx = Ctx(); ctx.J = {k.replace(":", "_"): v for k, v in J.items()}
        for g in gens:
            if g["type"] == "tie":
                pr = clothes.tie(ctx, top, ctx.J["mixamorig_Neck"][1] + float(g.get("top_y", -0.005)),
                                 ctx.J["mixamorig_Hips"][1] + float(g.get("end_y", 0.06)))
                bw, bh = 96, 192
            else:
                pr = clothes.name_tag(ctx, top, side=int(g.get("side", 1)))
                bw, bh = 96, 32
            xy = free_rect(ocov, bw + 8, bh + 8)
            if xy is None:
                raise SystemExit("rb_cast: no free block in the hair atlas for " + g["type"])
            x0, y0 = xy[0] + 4, xy[1] + 4
            ocov[y0 - 4:y0 + bh + 4, x0 - 4:x0 + bw + 4] = True
            # the piece's own cell UV (clothes.cell_uv put it in the clothes atlas): back to 0..1 in its cell
            cx, cy, cw, ch = clothes.CELLS["tie" if g["type"] == "tie" else "tag"]
            luv = np.stack([(pr["cuv"][..., 0] - cx) / cw, (pr["cuv"][..., 1] - cy) / ch], -1)
            pr["cuv"] = np.stack([(x0 + luv[..., 0] * bw) / OH, (y0 + luv[..., 1] * bh) / OH], -1)
            c = rb_paint.hexrgb(g.get("color", "#202020"))
            block = np.ones((bh, bw, 3)) * c
            if g["type"] == "nametag":
                yy, xx = np.mgrid[0:bh, 0:bw]
                border = (xx < bw * 0.08) | (xx > bw * 0.92) | (yy < bh * 0.16) | (yy > bh * 0.84)
                block[border] = rb_paint.hexrgb(g.get("border", "#a0a0a0"))
            else:
                yy, xx = np.mgrid[0:bh, 0:bw]
                block *= (0.9 + 0.1 * np.sin(xx / bw * np.pi))[..., None]       # a soft crown
                if g.get("pattern") == "stripe":
                    s = np.sin((xx + yy) / 7.0) > 0.8
                    block[s] = rb_paint.hexrgb(g.get("stripe", "#7a2830"))
            op[y0:y0 + bh, x0:x0 + bw, :3] = block; op[y0:y0 + bh, x0:x0 + bw, 3] = 1.0
            extra.append(pr)

    # tone and repaint written; textures swapped into the materials
    outp = os.path.join(work, "paint"); os.makedirs(outp, exist_ok=True)
    for arr, key, mode, img_node in ((body2, "body", "RGB", nb), (head2, "head", "RGB", nh), (op, "opacity", "RGBA", no)):
        p = os.path.join(outp, "%s_%s.png" % (pid, key))
        rb_paint.save(arr, p, mode)
        img_node.image = bpy.data.images.load(p, check_existing=False)
        img_node.image.name = "%s_%s" % (pid, key)
    mo = me.data.materials[mats["opacity"]]
    mo.blend_method = "CLIP" if hasattr(mo, "blend_method") else None
    try:
        mo.alpha_threshold = float(data.get("alpha_cut", 0.35))
    except Exception:
        pass

    # ---- shape keys: the resting edit into every key, the named morphs, drop the raw ARKit keys
    for k in kb:
        k.data.foreach_set("co", (kco(k) + rest_edit).reshape(-1))
    rf = data.get("resting_face", {})
    for nm, mix in NAMED:
        k = me.shape_key_add(name=nm, from_mix=False)
        mix = dict(mix)
        if nm in ("blink_L", "blink_R"):
            # a blink closes all the way even with the resting lids opened a little (resting_face EyeWide*)
            side = "Left" if nm.endswith("L") else "Right"
            mix["EyeWide" + side] = mix.get("EyeWide" + side, 0.0) - float(rf.get("EyeWide" + side, 0.0))
        d = sum(float(w) * deltas[s] for s, w in mix.items() if s in deltas)
        k.data.foreach_set("co", (basis2 + d).reshape(-1))
    keep = {nm for nm, _ in NAMED}
    for k in list(me.data.shape_keys.key_blocks)[1:]:
        if k.name not in keep and not k.name.startswith(KEEP_PREFIX):
            me.shape_key_remove(k)
    me.data.vertices.foreach_set("co", basis2.reshape(-1))
    me.data.update()

    # ---- generated pieces into the body: one mesh, opacity material, skinned like the shirt under them
    if extra:
        ob = add_pieces(extra, me, arm, names, mats["opacity"])
    # ---- split: face (head + hair/lash surfaces, with morphs) and body (no morphs)
    bpy.ops.object.select_all(action="DESELECT")
    me.select_set(True); bpy.context.view_layer.objects.active = me
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="DESELECT")
    bpy.ops.object.mode_set(mode="OBJECT")
    for p in me.data.polygons:
        p.select = p.material_index in (mats["head"], mats["opacity"])
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.separate(type="SELECTED")
    bpy.ops.object.mode_set(mode="OBJECT")
    face = next(o for o in bpy.context.selected_objects if o != me)
    bodyo = me
    if bodyo.data.shape_keys:
        bodyo.shape_key_clear()
    if extra:
        # into the face mesh: the pieces use the hair/lash material, so they add no draw call there
        bpy.ops.object.select_all(action="DESELECT")
        ob.select_set(True); face.select_set(True); bpy.context.view_layer.objects.active = face
        bpy.ops.object.join()
    bodyo.name = pid + "_lod0"; bodyo.data.name = pid + "_lod0"
    face.name = pid + "_lod0_face"; face.data.name = pid + "_lod0_face"
    # ---- LOD1: both joined, no morphs, decimated
    lod1 = make_lod1(pid, bodyo, face, int(data.get("lod1_tris", 5600)))
    # ---- export
    os.makedirs(OUT, exist_ok=True)
    glb = os.path.join(OUT, pid + ".glb")
    # Godot extracts a .glb's embedded textures beside it once and never refreshes them: drop the old ones
    import glob as _g
    for f in _g.glob(os.path.join(OUT, pid + "_*.png")) + _g.glob(os.path.join(OUT, pid + "_*.png.import")):
        os.remove(f)
    bpy.ops.object.select_all(action="DESELECT")
    for o in (arm, bodyo, face, lod1):
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=glb, export_format="GLB", use_selection=True, export_animations=False,
                              export_morph=True, export_morph_normal=False, export_skins=True, export_apply=False,
                              export_yup=True, export_image_format="AUTO")
    patch_alpha(glb, "opacity", float(data.get("alpha_cut", 0.35)))
    tris = {}
    for o in (bodyo, face, lod1):
        o.data.calc_loop_triangles(); tris[o.name] = len(o.data.loop_triangles)
    surf = {o.name: len({t.material_index for t in o.data.loop_triangles}) for o in (bodyo, face, lod1)}
    zs = [(o.matrix_world @ v.co).z for o in (bodyo, face) for v in o.data.vertices]
    morphs = [k.name for k in face.data.shape_keys.key_blocks[1:]]
    meta = {"id": pid, "source": "rocketbox", "rocketbox": rb["person"], "hips": hips,
            "height_m": float(max(zs) - min(zs)), "morphs": morphs, "jaw_open_deg": 0.0,
            "eyes": {"L": [float(x) for x in J["eye.L"]], "R": [float(x) for x in J["eye.R"]]},
            "lod_switch_m": float(data.get("lod_switch_m", 9.0)),
            "lod0": {"tris": tris[bodyo.name] + tris[face.name], "surfaces": surf[bodyo.name] + surf[face.name],
                     "parts": {bodyo.name: tris[bodyo.name], face.name: tris[face.name]}},
            "lod1": {"tris": tris[lod1.name], "surfaces": surf[lod1.name]},
            "glb_bytes": os.path.getsize(glb), "iris": iris,
            "store": data.get("store"), "period": data.get("period"), "status": data.get("status", "proposal"),
            "built": __import__("time").strftime("%Y-%m-%d"), "source_file": "tools/blender/cast/%s.json" % pid}
    json.dump(meta, open(os.path.join(OUT, pid + ".json"), "w"), indent=1)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(work, pid + ".blend"))
    print("CAST %s lod0: %d tris (%s), %d surfaces; lod1: %d tris; %d morphs; %.1f MB glb" % (
        pid, meta["lod0"]["tris"], meta["lod0"]["parts"], meta["lod0"]["surfaces"], meta["lod1"]["tris"],
        len(morphs), meta["glb_bytes"] / 1e6))


def patch_alpha(glb, key, cut):
    """Blender 5's exporter writes the hair/lash material as alpha BLEND (Godot: blended with a depth
    pre-pass, cards sorted badly and the hair reads dark); make it alpha MASK at `cut` (Godot: scissor)."""
    import struct
    b = open(glb, "rb").read()
    jl = struct.unpack("<I", b[12:16])[0]
    j = json.loads(b[20:20 + jl])
    rest = b[20 + jl:]
    for m in j.get("materials", []):
        if m.get("name", "").endswith(key):
            m["alphaMode"] = "MASK"; m["alphaCutoff"] = cut; m["doubleSided"] = True
    js = json.dumps(j, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    out = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + len(rest)) + struct.pack("<II", len(js), 0x4E4F534A) + js + rest
    open(glb, "wb").write(out)


def add_pieces(extra, me, arm, names, mat_index):
    V, T, U, Wl = [], [], [], []
    off = 0
    for pr in extra:
        V.append(g2b(pr["pos"])); T.append(pr["tri"] + off)
        U.append(pr["cuv"]); Wl.append(pr["W"]); off += len(pr["pos"])
    V = np.concatenate(V); T = np.concatenate(T); U = np.concatenate(U); Wm = np.concatenate(Wl)
    m = bpy.data.meshes.new("pieces")
    m.from_pydata(V.tolist(), [], T.tolist())
    uv = m.uv_layers.new(name=me.data.uv_layers.active.name)
    u = U.reshape(-1, 2).copy(); u[:, 1] = 1 - u[:, 1]
    uv.data.foreach_set("uv", u.reshape(-1))
    for p in m.polygons:
        p.use_smooth = True
    ob = bpy.data.objects.new("pieces", m)
    bpy.context.scene.collection.objects.link(ob)
    for mt in me.data.materials:
        m.materials.append(mt)
    for p in m.polygons:
        p.material_index = mat_index
    ob.parent = arm
    mod = ob.modifiers.new("Armature", "ARMATURE"); mod.object = arm
    for j, nme in enumerate(names):
        col = Wm[:, j]
        idx = np.nonzero(col > 1e-3)[0]
        if len(idx) == 0:
            continue
        vg = ob.vertex_groups.new(name=nme)
        for i in idx:
            vg.add([int(i)], float(col[i]), "REPLACE")
    return ob


def make_lod1(pid, bodyo, face, target):
    bpy.ops.object.select_all(action="DESELECT")
    objs = []
    for o in (bodyo, face):
        c = o.copy(); c.data = o.data.copy()
        bpy.context.scene.collection.objects.link(c)
        if c.data.shape_keys:
            c.shape_key_clear()
        objs.append(c)
    for c in objs:
        c.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    l1 = bpy.context.view_layer.objects.active
    l1.data.calc_loop_triangles()
    n = len(l1.data.loop_triangles)
    mod = l1.modifiers.new("dec", "DECIMATE")
    mod.decimate_type = "COLLAPSE"; mod.use_collapse_triangulate = True
    mod.ratio = min(1.0, target / max(n, 1))
    # the armature modifier must stay last for export; move decimate first and apply it
    while l1.modifiers[0].name != "dec":
        bpy.ops.object.modifier_move_up(modifier="dec")
    bpy.ops.object.modifier_apply(modifier="dec")
    l1.name = pid + "_lod1"; l1.data.name = pid + "_lod1"
    return l1


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    for pid in argv:
        main(pid)
