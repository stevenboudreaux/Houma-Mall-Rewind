"""UBC (workstream CHARS-UBC, Nov 4 2026; design/godot-ubc-characters.md): shared helpers for the
Quaternius Universal Base Characters pipeline (CC0, models/ubc/LICENSE-UBC.txt).

Everything runs headless in Blender-as-a-module (bpy 5.2):
  * load(sex): the kit's glTF body, its UE-style bones renamed to our Mixamo names (so every clip in
    npc/anims.res plays through NpcRig; the kit's rest is already a T-pose like Ch01's), the extra UV
    maps and vertex colours dropped, an icosphere helper deleted;
  * fields: masks from bone weights and position (torso, arms, legs, head, regions);
  * bind(): MakeHuman-style PROXY binding of any mesh onto the body: each vertex is stored as a point
    on the nearest body triangle (barycentric) plus an offset along the interpolated normal, so it
    follows every body shape key exactly (hair, eyebrows, eyes, every garment).
Axes (Blender): x = the character's left, -y = front, z = up. Exported glTF is +Y up, front +Z.
"""
import math
import os
import sys

import numpy as np
import bpy
import bmesh
from mathutils import Vector
from mathutils.bvhtree import BVHTree

KIT = os.environ.get("UBC_KIT", "/home/claude/assets/New Character Templates 11.4/Universal Base Characters[Standard]")
BODY_GLTF = {"male": "Base Characters/Godot - UE/Superhero_Male_FullBody.gltf",
             "female": "Base Characters/Godot - UE/Superhero_Female_FullBody.gltf"}
HAIR_DIR = "Hairstyles/Rigged to Head Bone/glTF (Godot -Unreal)"
HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
OUT = os.path.join(PROJ, "models", "ubc")
SCRATCH = os.path.join(PROJ, ".scratch", "ubc")

# UE mannequin names (the kit) -> Mixamo names (our clips). "root" stays (identity, above the hips).
_FINGERS = {"thumb": "Thumb", "index": "Index", "middle": "Middle", "ring": "Ring", "pinky": "Pinky"}


def mixamo_name(n):
    if n == "root" or n.startswith("mixamorig_"):
        return "root"
    side = ""
    base = n
    if n.endswith("_l") or n.endswith("_r"):
        side = "Left" if n.endswith("_l") else "Right"
        base = n[:-2]
    simple = {"pelvis": "Hips", "spine_01": "Spine", "spine_02": "Spine1", "spine_03": "Spine2",
              "neck_01": "Neck", "Head": "Head", "clavicle": side + "Shoulder", "upperarm": side + "Arm",
              "lowerarm": side + "ForeArm", "hand": side + "Hand", "thigh": side + "UpLeg",
              "calf": side + "Leg", "foot": side + "Foot", "ball": side + "ToeBase",
              "ball_leaf": side + "Toe_End"}
    if base in simple:
        return "mixamorig_" + simple[base]
    parts = base.split("_")          # index_01, index_04_leaf
    if parts[0] in _FINGERS:
        return "mixamorig_%sHand%s%d" % (side, _FINGERS[parts[0]], int(parts[1]))
    return "mixamorig_" + n


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def import_gltf(path):
    before = set(bpy.data.objects)
    # merge_vertices: glTF splits vertices at UV seams; unmerged, every smoothing / shape key would open
    # cracks along the seams
    bpy.ops.import_scene.gltf(filepath=path, merge_vertices=True)
    return [o for o in bpy.data.objects if o not in before]


def rename_bones(arm, meshes):
    for b in arm.data.bones:
        b.name = mixamo_name(b.name)      # vertex groups follow bone renames on the armature's children
    for m in meshes:
        for vg in m.vertex_groups:
            nn = mixamo_name(vg.name)
            if nn != vg.name and nn not in m.vertex_groups:
                vg.name = nn


def clean_mesh(o, keep_uv=1):
    me = o.data
    while len(me.uv_layers) > keep_uv:
        me.uv_layers.remove(me.uv_layers[-1])
    while len(me.color_attributes) > 0:
        me.color_attributes.remove(me.color_attributes[0])


def load(sex):
    """The kit's body: (armature, body mesh, extra head meshes [eyes, brows])."""
    objs = import_gltf(os.path.join(KIT, BODY_GLTF[sex]))
    for o in list(objs):
        if o.type == "MESH" and o.parent is None:        # the kit's Icosphere helper
            bpy.data.objects.remove(o)
    arm = [o for o in bpy.data.objects if o.type == "ARMATURE"][0]
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    body = max(meshes, key=lambda o: len(o.data.vertices))
    rest = [o for o in meshes if o is not body]
    rename_bones(arm, meshes)
    drop_root(arm, meshes)
    for m in meshes:
        clean_mesh(m)
    return arm, body, rest


def drop_root(arm, meshes):
    """The kit has a "root" bone above the hips (UE style); our clips' skeleton starts at the hips.
    The hips become the root (any root weights move to them), so the skeleton is Mixamo's exactly."""
    for m in meshes:
        vg = m.vertex_groups.get("root")
        if vg is None:
            continue
        hips = m.vertex_groups.get("mixamorig_Hips") or m.vertex_groups.new(name="mixamorig_Hips")
        for v in m.data.vertices:
            for g in v.groups:
                if g.group == vg.index and g.weight > 0:
                    hips.add([v.index], g.weight, "ADD")
        m.vertex_groups.remove(vg)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm.data.edit_bones
    if "root" in eb:
        eb["mixamorig_Hips"].parent = None
        eb.remove(eb["root"])
    bpy.ops.object.mode_set(mode="OBJECT")


# ------------------------------------------------------------------ mesh data as numpy
def verts(o):
    n = len(o.data.vertices)
    a = np.zeros(n * 3)
    o.data.vertices.foreach_get("co", a)
    return a.reshape(n, 3)


def tris(o):
    me = o.data
    me.calc_loop_triangles()
    n = len(me.loop_triangles)
    a = np.zeros(n * 3, dtype=np.int64)
    me.loop_triangles.foreach_get("vertices", a)
    return a.reshape(n, 3)


def vnormals(V, T):
    fn = np.cross(V[T[:, 1]] - V[T[:, 0]], V[T[:, 2]] - V[T[:, 0]])
    N = np.zeros_like(V)
    for k in range(3):
        np.add.at(N, T[:, k], fn)
    ln = np.linalg.norm(N, axis=1, keepdims=True)
    return N / np.maximum(ln, 1e-12)


def weights(o, names):
    """(n, len(names)) weight matrix for the given vertex groups (missing = 0)."""
    idx = {vg.index: i for i, vg in enumerate(o.vertex_groups) if False}
    gi = {}
    for j, nm in enumerate(names):
        vg = o.vertex_groups.get(nm)
        if vg is not None:
            gi[vg.index] = j
    W = np.zeros((len(o.data.vertices), len(names)))
    for v in o.data.vertices:
        for g in v.groups:
            j = gi.get(g.group)
            if j is not None:
                W[v.index, j] = g.weight
    return W


def bone_names(arm):
    return [b.name for b in arm.data.bones]


def adjacency(o):
    me = o.data
    E = np.zeros(len(me.edges) * 2, dtype=np.int64)
    me.edges.foreach_get("vertices", E)
    return E.reshape(-1, 2)


def smooth(V, E, mask, iters=10, lam=0.5, mu=-0.53):
    """Taubin smoothing (keeps volume), only where mask > 0 (scaled by it)."""
    V = V.copy()
    n = len(V)
    deg = np.zeros(n)
    np.add.at(deg, E[:, 0], 1)
    np.add.at(deg, E[:, 1], 1)
    deg = np.maximum(deg, 1)[:, None]
    m = mask[:, None]
    for _ in range(iters):
        for f in ((lam, mu) if mu != 0.0 else (lam,)):
            S = np.zeros_like(V)
            np.add.at(S, E[:, 0], V[E[:, 1]])
            np.add.at(S, E[:, 1], V[E[:, 0]])
            V = V + f * m * (S / deg - V)
    return V


def smooth_field(x, E, iters=8):
    """Blur a per-vertex scalar along the edges (mask feathering)."""
    x = x.astype(float).copy()
    n = len(x)
    deg = np.zeros(n)
    np.add.at(deg, E[:, 0], 1)
    np.add.at(deg, E[:, 1], 1)
    deg = np.maximum(deg, 1)
    for _ in range(iters):
        S = np.zeros(n)
        np.add.at(S, E[:, 0], x[E[:, 1]])
        np.add.at(S, E[:, 1], x[E[:, 0]])
        x = 0.5 * x + 0.5 * S / deg
    return x


def set_verts(o, V):
    o.data.vertices.foreach_set("co", V.reshape(-1))
    o.data.update()


def add_key(o, name, V):
    if o.data.shape_keys is None:
        o.shape_key_add(name="Basis", from_mix=False)
    k = o.shape_key_add(name=name, from_mix=False)
    k.data.foreach_set("co", np.asarray(V, dtype=float).reshape(-1))
    return k


# ------------------------------------------------------------------ proxy binding
class Binding:
    """MakeHuman-style proxy binding of points onto a body mesh's triangles."""

    def __init__(self, body_V, body_T, P, max_dist=0.5):
        self.T = body_T
        bvh = BVHTree.FromPolygons(body_V.tolist(), body_T.tolist(), all_triangles=True)
        N0 = vnormals(body_V, body_T)
        self.tri = np.zeros(len(P), dtype=np.int64)
        self.bary = np.zeros((len(P), 3))
        self.off = np.zeros(len(P))
        for i, p in enumerate(P):
            loc, nrm, fi, d = bvh.find_nearest(Vector(p), max_dist)
            if fi is None:
                fi = 0; loc = Vector(body_V[body_T[0, 0]])
            a, b, c = (body_V[self.T[fi, k]] for k in range(3))
            w = _bary(np.array(loc), a, b, c)
            n = w[0] * N0[self.T[fi, 0]] + w[1] * N0[self.T[fi, 1]] + w[2] * N0[self.T[fi, 2]]
            n /= max(np.linalg.norm(n), 1e-12)
            self.tri[i] = fi
            self.bary[i] = w
            self.off[i] = float(np.dot(np.array(p) - np.array(loc), n))
            # keep the exact rest position: the residual tangent part is stored too
        self.rest_body = body_V.copy()
        self.P0 = np.array(P, dtype=float)
        self.res = self.P0 - self.evaluate(body_V, residual=False)

    def evaluate(self, body_V, residual=True):
        N = vnormals(body_V, self.T)
        tv = self.T[self.tri]
        base = (body_V[tv] * self.bary[:, :, None]).sum(1)
        n = (N[tv] * self.bary[:, :, None]).sum(1)
        n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)
        out = base + n * self.off[:, None]
        if residual:
            out = out + self.res
        return out

    def weights(self, body_W):
        tv = self.T[self.tri]
        return (body_W[tv] * self.bary[:, :, None]).sum(1)


def _bary(p, a, b, c):
    v0, v1, v2 = b - a, c - a, p - a
    d00, d01, d11 = v0 @ v0, v0 @ v1, v1 @ v1
    d20, d21 = v2 @ v0, v2 @ v1
    den = d00 * d11 - d01 * d01
    if abs(den) < 1e-18:
        return np.array([1.0, 0.0, 0.0])
    v = (d11 * d20 - d01 * d21) / den
    w = (d00 * d21 - d01 * d20) / den
    return np.array([1 - v - w, v, w])


def body_keys(body):
    """{name: (n,3) positions} of every shape key on the body (not the Basis)."""
    out = {}
    if body.data.shape_keys is None:
        return out
    n = len(body.data.vertices)
    for k in body.data.shape_keys.key_blocks[1:]:
        a = np.zeros(n * 3)
        k.data.foreach_get("co", a)
        out[k.name] = a.reshape(n, 3)
    return out


def follow(body, piece, binding=None, keys=None):
    """Give `piece` one shape key per body shape key, through a proxy binding (returns the binding)."""
    BV = verts(body)
    BT = tris(body)
    P = verts(piece)
    b = binding or Binding(BV, BT, P)
    keys = keys if keys is not None else body_keys(body)
    for name, KV in keys.items():
        add_key(piece, name, b.evaluate(KV))
    return b


def export(objs, path, fmt="GLTF_SEPARATE"):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=path, export_format=fmt, use_selection=True,
                              export_morph=True, export_morph_normal=True, export_skins=True,
                              export_animations=False, export_yup=True, export_apply=False,
                              export_texcoords=True, export_normals=True, export_tangents=False,
                              export_vertex_color="NONE", export_image_format="AUTO",
                              export_texture_dir="", export_extras=False)
