"""UBC pieces (design/godot-ubc-characters.md): the kit's six hairstyles (+ beard) and the garments for
the five first looks, made for both UBC bodies and PROXY-BOUND to them (ubc_common.Binding: every
piece vertex is a point on a body triangle + an offset along its normal), so each follows every body
shape key exactly. Writes models/ubc/<piece>_<sex>.gltf and models/ubc/pieces.json (read by
tools/chars/ubc_manifest.gd).

Hair: each style was modelled on one of the kit's heads (Long, Buns, BuzzedFemale on the female;
Buzzed, SimpleParted, Beard on the male). On the other body it is moved and scaled from that head onto
this one (the head regions' bounding boxes), then bound. A vertex that would sit inside the scalp is
kept 2 mm out. Weights: the kit's (rigid on the Head); scripts/chars/char_fit.gd then skins a curtain
below the jaw onto the torso and keeps it clear of the shirt at load.

  BPY tools/blender/ubc/build_pieces.py [hair] [garments] [--only=<id>]
"""
import json
import os
import sys

import numpy as np
import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ubc_common as U  # noqa: E402

HAIRS = {
    # base_id: (kit file, modelled on, label, material texture)
    "hair_long": ("Hair_Long.gltf", "female", "Shoulder length", "hair_2"),
    "hair_buns": ("Hair_Buns.gltf", "female", "Buns", "hair_2"),
    "hair_buzzedfemale": ("Hair_BuzzedFemale.gltf", "female", "Short crop", "hair_1"),
    "hair_buzzed": ("Hair_Buzzed.gltf", "male", "Buzzed", "hair_1"),
    "hair_simpleparted": ("Hair_SimpleParted.gltf", "male", "Side part", "hair_1"),
    "x_beard": ("Hair_Beard.gltf", "male", "Beard", "hair_1"),
}
# old (B1) hair ids -> the closest UBC style (presets keep working; CharPreset.normalize)
ALIASES = {"hair_shoulder": "hair_long", "hair_puffs": "hair_buns", "hair_crew": "hair_buzzed",
           "hair_sidepart": "hair_simpleparted", "hair_bowl": "hair_simpleparted", "hair_fade": "hair_buzzed",
           "hair_balding": "hair_buzzed", "hair_elderly": "hair_simpleparted", "hair_perm": "hair_buns",
           "hair_braids": "hair_long",
           # garments not made for the UBC bodies yet: the closest one stands in (design note "Stand-ins")
           "shoe_dressshoes": "shoe_sneakers", "shoe_boots": "shoe_sneakers", "shoe_sandals": "shoe_sneakers",
           "top_buttondown": "top_polo", "top_cardigan": "top_flannel", "top_tank": "top_tee", "top_babytee": "top_tee",
           "bot_widejeans": "bot_jeans", "bot_skirt": "bot_slacks", "bot_longshorts": "bot_khakis",
           "bot_shortshorts": "bot_khakis", "bot_overalls": "bot_jeans", "x_cap_fwd": "x_cap_back"}
SCALP = 0.002


def base_body(sex):
    """The built UBC body (toned base + shape keys) from the body build's .blend."""
    U.reset()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(U.SCRATCH, "body_%s.blend" % sex))
    arm = bpy.data.objects["Armature"]
    body = bpy.data.objects["body"]
    return arm, body


def head_box(body, names):
    W = U.weights(body, ["mixamorig_Head"])
    V = U.verts(body)
    h = V[W[:, 0] > 0.9]
    return h.min(0), h.max(0)


def kit_head_box(sex):
    """The head box of the kit's own body of that sex (the hair was modelled on it)."""
    cur = bpy.context.window_manager  # noqa: F841
    store = os.path.join(U.SCRATCH, "headbox_%s.json" % sex)
    if os.path.exists(store):
        d = json.load(open(store))
        return np.array(d[0]), np.array(d[1])
    raise RuntimeError("run the body build first (it writes %s)" % store)


def import_piece(path):
    objs = U.import_gltf(path)
    arms = [o for o in objs if o.type == "ARMATURE"]
    meshes = [o for o in objs if o.type == "MESH"]
    for m in meshes:
        U.rename_bones(arms[0], [m]) if arms else None
        U.clean_mesh(m)
        mw = m.matrix_world.copy()
        m.parent = None
        m.matrix_world = mw
        bpy.ops.object.select_all(action="DESELECT")
        m.select_set(True)
        bpy.context.view_layer.objects.active = m
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        for md in list(m.modifiers):
            m.modifiers.remove(md)
    for a in arms:
        bpy.data.objects.remove(a)
    return meshes


def attach(piece, arm):
    """Parent a piece to the body's armature with an Armature modifier (its vertex groups = bone names)."""
    piece.parent = arm
    md = piece.modifiers.new("Armature", "ARMATURE")
    md.object = arm


def set_weights(piece, names, W):
    for vg in list(piece.vertex_groups):
        piece.vertex_groups.remove(vg)
    groups = {}
    for j, n in enumerate(names):
        col = W[:, j]
        idx = np.nonzero(col > 0.002)[0]
        if len(idx) == 0:
            continue
        vg = piece.vertex_groups.new(name=n)
        for i in idx:
            vg.add([int(i)], float(col[i]), "REPLACE")


def hair(sex, only=None):
    entries = []
    for bid, (fname, on, label, tex) in HAIRS.items():
        if only and bid != only:
            continue
        if bid == "x_beard" and sex == "female":
            continue
        arm, body = base_body(sex)
        lo_t, hi_t = head_box(body, None)
        lo_s, hi_s = kit_head_box(on)
        meshes = import_piece(os.path.join(U.KIT, U.HAIR_DIR, fname))
        piece = meshes[0]
        piece.name = bid
        P = U.verts(piece)
        if on != sex:
            cs, ct = (lo_s + hi_s) / 2, (lo_t + hi_t) / 2
            sc = (hi_t - lo_t) / np.maximum(hi_s - lo_s, 1e-6)
            P = (P - cs) * sc + ct
            U.set_verts(piece, P)
        BV, BT = U.verts(body), U.tris(body)
        b = U.Binding(BV, BT, P, max_dist=0.6)
        # nothing inside the scalp: keep every vertex at least SCALP out
        inside = b.off < SCALP
        b.off = np.where(inside, SCALP, b.off)
        U.set_verts(piece, b.evaluate(BV))
        if piece.data.shape_keys:
            piece.shape_key_clear()
        for name, KV in U.body_keys(body).items():
            U.add_key(piece, name, b.evaluate(KV))
        piece.data.shape_keys.use_relative = True
        # rigid on the head (as the kit has it)
        names = U.bone_names(arm)
        W = np.zeros((len(P), len(names)))
        W[:, names.index("mixamorig_Head")] = 1.0
        set_weights(piece, names, W)
        attach(piece, arm)
        mat = piece.data.materials[0]
        mat.name = "hair_" + bid
        for n in mat.node_tree.nodes:
            if n.type == "TEX_IMAGE" and n.image is not None:
                nm = n.image.name.lower()
                if "basecolor" in nm:
                    n.image = bpy.data.images.load(os.path.join(U.OUT, "ubc_%s_albedo.png" % tex), check_existing=True)
        try:
            mat.surface_render_method = "DITHERED"
            mat.blend_method = "CLIP"
        except Exception:
            pass
        bpy.data.objects.remove(body)
        for o in list(bpy.data.objects):
            if o.type == "MESH" and o is not piece:
                bpy.data.objects.remove(o)
        out = os.path.join(U.OUT, "%s_%s.gltf" % (bid, sex))
        U.export([arm, piece], out)
        tris = len(U.tris(piece))
        slot = "beard" if bid == "x_beard" else "hair"
        print("UBC PIECE %s_%s %d tris (inside the scalp before: %d)" % (bid, sex, tris, int(inside.sum())))
        entries.append({"id": "%s_%s" % (bid, sex), "base_id": bid, "body": sex, "tris": tris,
                        "glb": "res://models/ubc/%s_%s.gltf" % (bid, sex),
                        "materials": {"hair": {"label": "hair colour", "default": None}},
                        "slot": slot, "layer": 5, "label": label, "style": bid.replace("hair_", ""),
                        "hides": [], "kit": fname, "modelled_on": on})
    return entries


def merge(entries):
    path = os.path.join(U.OUT, "pieces.json")
    d = json.load(open(path)) if os.path.exists(path) else {"pieces": []}
    ids = {e["id"] for e in entries}
    d["pieces"] = [p for p in d["pieces"] if p["id"] not in ids] + entries
    d["pieces"].sort(key=lambda p: p["id"])
    d["aliases"] = ALIASES
    d["_"] = "CHARS-UBC pieces (tools/blender/ubc/build_pieces.py); merged into models/ubc/ubc.json by tools/chars/ubc_manifest.gd."
    json.dump(d, open(path, "w"), indent="\t")


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    only = next((a.split("=", 1)[1] for a in args if a.startswith("--only=")), None)
    what = [a for a in args if not a.startswith("--")] or ["hair"]
    ents = []
    for sex in ("female", "male"):
        if "hair" in what:
            ents += hair(sex, only)
        if "garments" in what:
            import garments_ubc
            ents += garments_ubc.build(sex, only)
    merge(ents)
