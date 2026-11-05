"""UBC garments (design/godot-ubc-characters.md "Outfits"): the pieces the five first looks wear, made
on each UBC body. Called by build_pieces.py (garments).

Surface garments (tee, polo, sweatshirt, flannel, vest, jeans, khakis, slacks, sneakers, watch) are CUT
FROM THE BODY: the body faces the garment covers are copied and moved out along the body's normal by
the layer's gap + the garment's ease; because every garment vertex IS a body vertex, its weights and
its shape keys (the body's shape at that vertex + the shaped normal x the gap) are exact: the garment
follows every slider. Trim (hems, cuffs, collar, waistband) and accent (name tag, placket, sole) are
material regions picked by distance to the cut edge or by position. Fabric UVs are cylindrical around
the body axis (torso) or the limb's bone (sleeves, legs), so a fabric tile repeats at a real size.
Loose / rigid pieces: the apron (a bib cut from the chest + a skirt panel on the hips), the backward
cap (a crown cut from the scalp + a brim, on the Head), the glasses (rings, bridge, temples on the Head).
No real brands, no words (the name tags are blank accent patches).
"""
import math
import os

import numpy as np
import bpy
import bmesh

import ubc_common as U
import build_body as BB

GAP = {1: 0.003, 2: 0.005, 3: 0.012, 4: 0.006, 5: 0.004}
TILE = 0.09        # m per fabric tile repeat
FAB_SRC = os.path.join(U.PROJ, "models", "characters")

# id: label, slot, layer, ease (m), fabric, default colours (main, trim, accent). Tops are worn out over
# the bottoms (more ease), an outer layer over both (layer 3's gap).
SPEC = {
    "top_tee": ("T-shirt", "top", 2, 0.004, "knit", ("#ffffff", "#ffffff", "#d8d4c8")),
    "top_polo": ("Polo shirt", "top", 2, 0.005, "pique", ("#1f4e79", "#1f4e79", "#d8d4c8")),
    "top_sweatshirt": ("Sweatshirt", "top", 2, 0.01, "fleece", ("#7f8a99", "#6f7a89", "#d8d4c8")),
    "top_flannel": ("Flannel (open, over a tee)", "top", 3, 0.006, "plaid", ("#8c2a22", "#8c2a22", "#d8d4c8")),
    "full_storevest": ("Store uniform (vest + name tag)", "outer", 3, 0.004, "twill", ("#b8202a", "#b8202a", "#f2efe6")),
    "full_storeapron": ("Store uniform (apron + name tag)", "outer", 3, 0.004, "canvas", ("#1f5a3a", "#1f5a3a", "#f2efe6")),
    "bot_jeans": ("Straight jeans", "bottom", 2, 0.0, "denim", ("#4a6a96", "#4a6a96", "#d8d4c8")),
    "bot_khakis": ("Khakis", "bottom", 2, 0.001, "twill", ("#c2ab84", "#c2ab84", "#d8d4c8")),
    "bot_slacks": ("Slacks", "bottom", 2, 0.001, "twill", ("#2e3238", "#2e3238", "#d8d4c8")),
    "shoe_sneakers": ("Sneakers", "shoes", 4, 0.004, "canvas", ("#f4f4f2", "#f0f0ee", "#c8c8c8")),
    "x_cap_back": ("Cap (backward)", "hat", 5, 0.006, "knit", ("#22325a", "#22325a", "#d8d4c8")),
    "x_glasses": ("Glasses", "glasses", 5, 0.0, "knit", ("#2a2522", "#2a2522", "#2a2522")),
    "x_watch": ("Watch", "watch", 5, 0.0, "knit", ("#2a2a2a", "#2a2a2a", "#d9d6cf")),
}


def _t_along(F, bone, V):
    a, b = F.head[bone], F.tail[bone]
    ax = b - a
    L = np.linalg.norm(ax)
    return ((V - a) @ ax) / max(L * L, 1e-9)


def masks(F, sex):
    """Per-vertex 0/1 keep masks for every surface garment, from regions, bones and heights."""
    V = F.V
    x, y, z = V[:, 0], V[:, 1], V[:, 2]
    reg = BB.regions(F)
    R = {n: (reg == BB.REGIONS.index(n)) for n in BB.REGIONS}
    hz = F.head["mixamorig_Hips"][2]
    nz = F.head["mixamorig_Neck"][2]
    s2z = F.head["mixamorig_Spine2"][2]
    torso = R["chest_f"] | R["chest_b"] | R["belly_f"] | R["belly_b"] | R["pelvis_f"] | R["pelvis_b"] | R["shoulder_l"] | R["shoulder_r"]
    tl = {s: _t_along(F, "mixamorig_%sArm" % s, V) for s in ("Left", "Right")}
    tf = {s: _t_along(F, "mixamorig_%sForeArm" % s, V) for s in ("Left", "Right")}
    tlg = {s: _t_along(F, "mixamorig_%sLeg" % s, V) for s in ("Left", "Right")}
    tul = {s: _t_along(F, "mixamorig_%sUpLeg" % s, V) for s in ("Left", "Right")}
    side = np.where(x >= 0, "Left", "Right")
    upper = np.array([tl[s][i] for i, s in enumerate(side)])
    fore = np.array([tf[s][i] for i, s in enumerate(side)])
    shin = np.array([tlg[s][i] for i, s in enumerate(side)])
    thigh = np.array([tul[s][i] for i, s in enumerate(side)])
    ua = R["upperarm_l"] | R["upperarm_r"]
    fa = R["forearm_l"] | R["forearm_r"]
    # the neckline: the neck itself, and a crew scoop at the front
    neckline = R["neck"] | (z > nz + 0.005) | ((y < F.head["mixamorig_Neck"][1] - 0.02) & (z > nz - 0.055) & (np.abs(x) < 0.065))
    hem = hz + 0.02                        # an untucked shirt ends at the hip joints, well above the crotch
    shirt_body = torso & ~neckline & (z > hem) & ~R["crotch"]
    M = {}
    M["top_tee"] = shirt_body | (ua & (upper < 0.42))
    M["top_polo"] = shirt_body | (ua & (upper < 0.48)) | (torso & (z > nz - 0.035) & (z < nz - 0.005) & (y > F.head["mixamorig_Neck"][1] - 0.03))
    M["top_sweatshirt"] = (torso & ~(R["neck"] | (z > nz + 0.01)) & (z > hem - 0.01) & ~R["crotch"]) | ua | (fa & (fore < 0.93))
    flannel = (torso & ~(R["neck"] | (z > nz + 0.01)) & (z > hem - 0.02) & ~R["crotch"]) | ua | (fa & (fore < 0.9))
    M["top_flannel"] = flannel & ~((np.abs(x) < 0.04) & (y < 0) & (z < nz - 0.02))
    M["full_storevest"] = torso & ~neckline & (z > hz + 0.01) & ~R["crotch"] & ~((R["shoulder_l"] | R["shoulder_r"]) & (np.abs(x) > 0.13)) \
        & ~((np.abs(x) > 0.15) & (z > s2z - 0.06))
    legs = R["thigh_l"] | R["thigh_r"] | R["shin_l"] | R["shin_r"] | R["crotch"] | R["pelvis_f"] | R["pelvis_b"] \
        | R["belly_f"] | R["belly_b"]
    waist_ok = z < hz + 0.07
    M["bot_jeans"] = legs & waist_ok & ~((R["shin_l"] | R["shin_r"]) & (shin > 0.9))
    M["bot_khakis"] = legs & waist_ok & ~((R["shin_l"] | R["shin_r"]) & (shin > 0.92))
    M["bot_slacks"] = legs & waist_ok & ~((R["shin_l"] | R["shin_r"]) & (shin > 0.94))
    feet = R["foot_l"] | R["foot_r"]
    M["shoe_sneakers"] = feet | ((R["shin_l"] | R["shin_r"]) & (shin > 0.93))
    M["x_watch"] = fa & (fore > 0.78) & (fore < 0.97) & (x > 0)          # the left wrist
    return M, reg


def _faces_of(o, keep):
    me = o.data
    n = len(me.polygons)
    loops = np.zeros(len(me.loops), dtype=np.int64)
    me.loops.foreach_get("vertex_index", loops)
    starts = np.zeros(n, dtype=np.int64); me.polygons.foreach_get("loop_start", starts)
    counts = np.zeros(n, dtype=np.int64); me.polygons.foreach_get("loop_total", counts)
    sel = np.zeros(n, dtype=bool)
    for i in range(n):
        vs = loops[starts[i]:starts[i] + counts[i]]
        sel[i] = keep[vs].all()
    return sel


def cut(body, keep, name):
    """A new object from the body faces whose vertices are all kept; returns (obj, body vertex index map)."""
    sel = _faces_of(body, keep)
    bm = bmesh.new()
    bm.from_mesh(body.data)
    bm.verts.ensure_lookup_table()
    bm.faces.ensure_lookup_table()
    for f in bm.faces:
        f.select = False
    kill = [f for f in bm.faces if not sel[f.index]]
    bmesh.ops.delete(bm, geom=kill, context="FACES")
    # remember where each kept vertex came from
    lay = bm.verts.layers.int.get("src") or bm.verts.layers.int.new("src")
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    # body shape keys come along with from_mesh? (bmesh drops them): map by position
    BV = U.verts(body)
    P = U.verts(o)
    from mathutils.kdtree import KDTree
    kd = KDTree(len(BV))
    for i, v in enumerate(BV):
        kd.insert(v, i)
    kd.balance()
    idx = np.array([kd.find(p)[1] for p in P], dtype=np.int64)
    if o.data.shape_keys:
        o.shape_key_clear()
    return o, idx


def boundary_distance(o, iters=40):
    """Approximate distance (m) of every vertex to the garment's cut edge (Dijkstra-like relaxation)."""
    bm = bmesh.new(); bm.from_mesh(o.data); bm.verts.ensure_lookup_table()
    n = len(bm.verts)
    d = np.full(n, 9.0)
    for e in bm.edges:
        if e.is_boundary:
            d[e.verts[0].index] = 0.0; d[e.verts[1].index] = 0.0
    E = np.array([[e.verts[0].index, e.verts[1].index] for e in bm.edges])
    L = np.array([e.calc_length() for e in bm.edges])
    bm.free()
    for _ in range(iters):
        a = np.minimum(d[E[:, 0]], d[E[:, 1]] + L)
        b = np.minimum(d[E[:, 1]], d[E[:, 0]] + L)
        np.minimum.at(d, E[:, 0], a)
        np.minimum.at(d, E[:, 1], b)
    return d


def cyl_uv(F, P, reg):
    """Fabric UVs (tile units): around the limb bone for sleeves / legs, else around the body axis."""
    uv = np.zeros((len(P), 2))
    limb = {"upperarm": "Arm", "forearm": "ForeArm", "thigh": "UpLeg", "shin": "Leg", "hand": "Hand", "foot": "Foot"}
    for i, p in enumerate(P):
        r = BB.REGIONS[reg[i]]
        base = r.rsplit("_", 1)[0]
        if base in limb:
            s = "Left" if r.endswith("_l") else "Right"
            bn = "mixamorig_%s%s" % (s, limb[base])
            a, b = F.head[bn], F.tail[bn]
            ax = (b - a) / max(np.linalg.norm(b - a), 1e-9)
            rel = p - a
            t = rel @ ax
            perp = rel - t * ax
            ref = np.array([0.0, -1.0, 0.0]) if abs(ax[1]) < 0.9 else np.array([1.0, 0, 0])
            ref = ref - (ref @ ax) * ax; ref /= np.linalg.norm(ref)
            ang = math.atan2(np.cross(ref, perp) @ ax, ref @ perp)
            rad = max(np.linalg.norm(perp), 0.03)
            uv[i] = (ang * rad / TILE, t / TILE)
        else:
            ang = math.atan2(p[0], -p[1])
            uv[i] = (ang * 0.16 / TILE, p[2] / TILE)
    return uv


def set_uv(o, uv, reg):
    me = o.data
    while len(me.uv_layers):
        me.uv_layers.remove(me.uv_layers[0])
    loops = np.zeros(len(me.loops), dtype=np.int64)
    me.loops.foreach_get("vertex_index", loops)
    a = me.uv_layers.new(name="UVMap")
    a.data.foreach_set("uv", uv[loops].reshape(-1))
    b = me.uv_layers.new(name="regions")
    co = np.zeros((len(loops), 2)); co[:, 0] = reg[loops]
    b.data.foreach_set("uv", co.reshape(-1))


def material(pid, part, fabric, color):
    name = "%s_%s" % (pid, part)      # pid = the piece id with its body: CharBody.paint
    if bpy.data.materials.get(name):
        return bpy.data.materials[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (1, 1, 1, 1)
    bsdf.inputs["Roughness"].default_value = 0.8
    img = os.path.join(FAB_SRC, "fab_%s_albedo.png" % fabric)
    if os.path.exists(img):
        t = nt.nodes.new("ShaderNodeTexImage")
        t.image = bpy.data.images.load(img, check_existing=True)
        nt.links.new(t.outputs["Color"], bsdf.inputs["Base Color"])
    nrm = os.path.join(FAB_SRC, "fab_%s_normal.png" % fabric)
    if os.path.exists(nrm):
        t2 = nt.nodes.new("ShaderNodeTexImage")
        t2.image = bpy.data.images.load(nrm, check_existing=True)
        t2.image.colorspace_settings.name = "Non-Color"
        nm = nt.nodes.new("ShaderNodeNormalMap")
        nt.links.new(t2.outputs["Color"], nm.inputs["Color"])
        nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
    return m


def assign_parts(o, part_of_vertex, pid, fabric):
    me = o.data
    pid = o.get("piece_id", pid)
    parts = ["main", "trim", "accent"]
    for p in parts:
        me.materials.append(material(pid, p, fabric if p != "accent" else "canvas", None))
    loops = np.zeros(len(me.loops), dtype=np.int64); me.loops.foreach_get("vertex_index", loops)
    starts = np.zeros(len(me.polygons), dtype=np.int64); me.polygons.foreach_get("loop_start", starts)
    counts = np.zeros(len(me.polygons), dtype=np.int64); me.polygons.foreach_get("loop_total", counts)
    mi = np.zeros(len(me.polygons), dtype=np.int64)
    for i in range(len(me.polygons)):
        vs = loops[starts[i]:starts[i] + counts[i]]
        mi[i] = int(np.round(np.median(part_of_vertex[vs])))
    me.polygons.foreach_set("material_index", mi)


RIM = 0.005       # m: the hem turned in toward the body (no paper-thin edges)


def surface(body, arm, F, sex, pid, keep, reg, keys):
    label, slot, layer, ease, fabric, cols = SPEC[pid]
    o, idx = cut(body, keep, "%s_%s" % (pid, sex))
    o["piece_id"] = "%s_%s" % (pid, sex)
    gap = GAP[layer] + ease
    # 1. straighten the cut: boundary vertices slide along their boundary loop (the body's faces made a
    #    sawtooth), then snap back onto the body surface
    bm = bmesh.new(); bm.from_mesh(o.data); bm.verts.ensure_lookup_table()
    from mathutils.bvhtree import BVHTree
    from mathutils import Vector
    bvh = BVHTree.FromPolygons(F.V.tolist(), F.T.tolist(), all_triangles=True)
    bverts = [v for v in bm.verts if v.is_boundary]
    for _ in range(24):
        newp = {}
        for v in bverts:
            nb = [e.other_vert(v) for e in v.link_edges if e.is_boundary]
            if len(nb) == 2:
                newp[v] = v.co * 0.5 + (nb[0].co + nb[1].co) * 0.25
        for v, p in newp.items():
            loc, n, fi, d = bvh.find_nearest(p, 0.1)
            v.co = loc if loc is not None else p
    # 2. the hem: the boundary turned in by RIM
    bnd = [e for e in bm.edges if e.is_boundary]
    ret = bmesh.ops.extrude_edge_only(bm, edges=bnd)
    rim = {v.index if False else v for v in ret["geom"] if isinstance(v, bmesh.types.BMVert)}
    bm.verts.index_update()
    rim_idx = np.array(sorted(v.index for v in rim), dtype=np.int64)
    bm.to_mesh(o.data); bm.free()
    P0 = U.verts(o)
    # 3. proxy-bind every vertex to the body; the garment sits `gap` out (the hem RIM less)
    b = U.Binding(F.V, F.T, P0, max_dist=0.2)
    b.res[:] = 0.0
    off = np.full(len(P0), gap)
    off[rim_idx] = max(gap - RIM, 0.001)
    b.off = off
    P = b.evaluate(F.V)
    U.set_verts(o, P)
    W = b.weights(F.W)
    set_weights_mat(o, F.names, W)
    regs = reg[F.T[b.tri, np.argmax(b.bary, 1)]]
    # material parts: trim near the cut edges, accent per garment
    d = boundary_distance(o)
    # trim = the turned-in hem (a band cut along the body's faces would zig-zag)
    part = np.zeros(len(P), dtype=int)
    part[rim_idx] = 1
    Pz = P[:, 2]
    if pid == "top_polo":       # placket: a strip down the front of the neck
        part = np.where((np.abs(P[:, 0]) < 0.018) & (P[:, 1] < 0) & (Pz > F.head["mixamorig_Spine2"][2]), 2, part)
    if pid in ("full_storevest", "full_storeapron"):   # the blank name tag on the left chest
        tag = (np.abs(P[:, 0] - 0.085) < 0.035) & (np.abs(Pz - (F.head["mixamorig_Spine2"][2] + 0.03)) < 0.016) & (P[:, 1] < 0)
        part = np.where(tag, 2, part)
    if pid == "shoe_sneakers":       # the sole
        part = np.where(Pz < 0.03, 1, np.where(d < 0.012, 2, 0))
    if pid == "x_watch":
        part = np.where((P[:, 2] > F.head["mixamorig_LeftHand"][2] + 0.01), 2, 0)
    assign_parts(o, part, pid, fabric)
    set_uv(o, cyl_uv(F, P, regs), regs)
    for name, KV in keys.items():
        U.add_key(o, name, b.evaluate(KV))
    o.data.shape_keys.use_relative = True
    hides = covered_regions(reg, idx)
    return o, hides


def set_weights_mat(o, names, W):
    for vg in list(o.vertex_groups):
        o.vertex_groups.remove(vg)
    for j, n in enumerate(names):
        col = W[:, j]
        nz = np.nonzero(col > 0.002)[0]
        if len(nz) == 0:
            continue
        vg = o.vertex_groups.new(name=n)
        for i in nz:
            vg.add([int(i)], float(col[i]), "REPLACE")


def covered_regions(reg, idx):
    out = []
    kept = np.zeros(len(reg), dtype=bool); kept[idx] = True
    for i, n in enumerate(BB.REGIONS):
        m = reg == i
        if m.sum() > 0 and kept[m].mean() > 0.97:
            out.append(n)
    return out


def set_weights_idx(o, F, idx):
    W = F.W[idx]
    for vg in list(o.vertex_groups):
        o.vertex_groups.remove(vg)
    for j, n in enumerate(F.names):
        col = W[:, j]
        nz = np.nonzero(col > 0.002)[0]
        if len(nz) == 0:
            continue
        vg = o.vertex_groups.new(name=n)
        for i in nz:
            vg.add([int(i)], float(col[i]), "REPLACE")


# ------------------------------------------------------------------ loose / rigid pieces
def mesh_from(name, V, faces):
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in V], [], [tuple(f) for f in faces])
    me.update()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    return o


def rigid(o, F, bone, body, keys, part, pid, fabric, reg_name="head", sex=""):
    """Weights all on one bone; shape keys through a proxy binding to the body; parts; UVs."""
    o["piece_id"] = "%s_%s" % (pid, sex) if sex else pid
    names = F.names
    for vg in list(o.vertex_groups):
        o.vertex_groups.remove(vg)
    vg = o.vertex_groups.new(name=bone)
    vg.add(list(range(len(o.data.vertices))), 1.0, "REPLACE")
    P = U.verts(o)
    b = U.Binding(F.V, F.T, P, max_dist=0.8)
    for name, KV in keys.items():
        U.add_key(o, name, b.evaluate(KV))
    o.data.shape_keys.use_relative = True
    assign_parts(o, part, pid, fabric)
    reg = np.full(len(P), BB.REGIONS.index(reg_name))
    uv = np.c_[P[:, 0] / TILE, P[:, 2] / TILE]
    set_uv(o, uv, reg)
    return o


def cap(F, sex):
    """A backward baseball cap: a crown over the scalp (a dome fitted to the head box) + a brim behind."""
    lo, hi = np.array(json_box(sex)[0]), np.array(json_box(sex)[1])
    c = (lo + hi) / 2
    rx, ry, rz = (hi - lo) / 2 * np.array([1.08, 1.06, 1.0])
    band = F.head["mixamorig_Head"][2] + (hi[2] - F.head["mixamorig_Head"][2]) * 0.52
    top = hi[2] + 0.012
    V, faces, part = [], [], []
    rings, seg = 9, 32
    for i in range(rings + 1):
        t = i / rings
        z = band + (top - band) * math.sin(t * math.pi / 2)
        s = math.cos(t * math.pi / 2) * 0.98 + 0.02
        for j in range(seg):
            a = 2 * math.pi * j / seg
            V.append((c[0] + rx * s * math.sin(a), c[1] - ry * s * math.cos(a), z))
            part.append(1 if i == 0 else 0)
    for i in range(rings):
        for j in range(seg):
            a0 = i * seg + j; a1 = i * seg + (j + 1) % seg
            faces.append((a0, a1, a1 + seg, a0 + seg))
    # the brim, behind (backward): a flattened half-disc
    b0 = len(V)
    for j in range(13):
        a = math.pi * (0.5 + j / 12)            # the back half: angles 90..270 degrees from the front
        for k, L in enumerate((1.0, 1.75)):
            V.append((c[0] + rx * L * math.sin(a) * 0.9, c[1] - ry * L * math.cos(a), band - 0.004 - 0.01 * (L - 1)))
            part.append(2)
    for j in range(12):
        a0 = b0 + j * 2
        faces.append((a0, a0 + 2, a0 + 3, a0 + 1))
    return np.array(V), faces, np.array(part)


def glasses(F, sex, eyes_center):
    """Round-ish 1990s frames: two rings, a bridge, two temples back to the ears."""
    V, faces, part = [], [], []
    ex, ey, ez = eyes_center
    lo, hi = np.array(json_box(sex)[0]), np.array(json_box(sex)[1])
    front_y = lo[1] - 0.006
    half = abs(ex)
    def tube(path, r=0.0025, sides=6):
        base = len(V)
        path = np.array(path)
        for i, p in enumerate(path):
            d = path[min(i + 1, len(path) - 1)] - path[max(i - 1, 0)]
            d /= max(np.linalg.norm(d), 1e-9)
            u = np.cross(d, [0, 0, 1.0]);
            if np.linalg.norm(u) < 1e-6: u = np.cross(d, [1.0, 0, 0])
            u /= np.linalg.norm(u); w = np.cross(d, u)
            for k in range(sides):
                a = 2 * math.pi * k / sides
                V.append(tuple(p + r * (math.cos(a) * u + math.sin(a) * w))); part.append(0)
        for i in range(len(path) - 1):
            for k in range(sides):
                a0 = base + i * sides + k; a1 = base + i * sides + (k + 1) % sides
                faces.append((a0, a1, a1 + sides, a0 + sides))
    for s in (-1, 1):
        cx = s * max(half, 0.032)
        ring = [(cx + 0.024 * math.cos(a), front_y, ez + 0.019 * math.sin(a)) for a in np.linspace(0, 2 * math.pi, 20)]
        tube(ring)
        tube([(cx + s * 0.024, front_y, ez + 0.006), (s * (hi[0] - 0.004), front_y + 0.02, ez + 0.01),
              (s * (hi[0] - 0.002), (lo[1] + hi[1]) / 2 + 0.01, ez + 0.0)], r=0.0018)
    tube([(-max(half, 0.032) + 0.024, front_y, ez + 0.008), (0, front_y - 0.002, ez + 0.012), (max(half, 0.032) - 0.024, front_y, ez + 0.008)], r=0.002)
    return np.array(V), faces, np.array(part)


def apron(F, sex, keep_bib):
    """Bib (cut from the chest front) is made by the surface path; this is the skirt panel on the hips."""
    hz = F.head["mixamorig_Hips"][2]
    V = F.V
    front = V[(np.abs(V[:, 0]) < 0.2) & (np.abs(V[:, 2] - (hz + 0.02)) < 0.02)]
    y0 = front[:, 1].min() - 0.02
    wx = 0.2
    Vs, faces, part = [], [], []
    rows, cols = 6, 8
    for i in range(rows + 1):
        z = hz + 0.04 - i * 0.075
        flare = 1 + i * 0.02
        for j in range(cols + 1):
            xx = (-wx + 2 * wx * j / cols) * flare
            Vs.append((xx, y0 - 0.025 * abs(xx) / wx * 0 - i * 0.012, z))
            part.append(1 if i == rows or j in (0, cols) else 0)
    for i in range(rows):
        for j in range(cols):
            a = i * (cols + 1) + j
            faces.append((a, a + 1, a + cols + 2, a + cols + 1))
    return np.array(Vs), faces, np.array(part)


_box = {}
def json_box(sex):
    import json
    if sex not in _box:
        _box[sex] = json.load(open(os.path.join(U.SCRATCH, "headbox_%s.json" % sex)))
    return _box[sex]


def build(sex, only=None):
    entries = []
    for pid in SPEC:
        if only and pid != only:
            continue
        arm, body = _open(sex)
        F = BB.Fields(arm, body)
        keys = U.body_keys(body)
        M, reg = masks(F, sex)
        label, slot, layer, ease, fabric, cols = SPEC[pid]
        hides = []
        objs = []
        if pid in M:
            o, hides = surface(body, arm, F, sex, pid, M[pid], reg, keys)
            objs.append(o)
        elif pid == "full_storeapron":
            # the bib: the chest front, offset like an outer layer
            V = F.V
            bib = (np.isin(reg, [BB.REGIONS.index(r) for r in ("chest_f", "belly_f", "pelvis_f")])) & (np.abs(V[:, 0]) < 0.13) \
                & (V[:, 2] < F.head["mixamorig_Neck"][2] - 0.07) & (V[:, 2] > F.head["mixamorig_Hips"][2] + 0.0)
            o, _ = surface(body, arm, F, sex, pid, bib, reg, keys)
            Vs, faces, part = apron(F, sex, bib)
            sk = mesh_from(pid + "_skirt", Vs, faces)
            sk = rigid(sk, F, "mixamorig_Hips", body, keys, part, pid, fabric, "pelvis_f", sex)
            objs += [o, sk]
        elif pid == "x_cap_back":
            Vs, faces, part = cap(F, sex)
            o = mesh_from("%s_%s" % (pid, sex), Vs, faces)
            objs.append(rigid(o, F, "mixamorig_Head", body, keys, part, pid, fabric, sex=sex))
        elif pid == "x_glasses":
            eyes = bpy.data.objects.get("eyes")
            ev = U.verts(eyes) if eyes else F.V[F.w("mixamorig_Head") > 0.9]
            ec = (ev[:, 0].min() * 0 + 0, 0, 0)
            exs = ev[ev[:, 0] > 0]
            center = (float(exs[:, 0].mean()), float(ev[:, 1].min()), float(ev[:, 2].mean()))
            Vs, faces, part = glasses(F, sex, center)
            o = mesh_from("%s_%s" % (pid, sex), Vs, faces)
            objs.append(rigid(o, F, "mixamorig_Head", body, keys, part, pid, fabric, sex=sex))
        for o in objs:
            o.parent = arm
            md = o.modifiers.new("Armature", "ARMATURE"); md.object = arm
        for o in list(bpy.data.objects):
            if o.type == "MESH" and o not in objs:
                bpy.data.objects.remove(o)
        out = os.path.join(U.OUT, "%s_%s.gltf" % (pid, sex))
        U.export([arm] + objs, out)
        tris = sum(len(U.tris(o)) for o in objs)
        print("UBC PIECE %s_%s %d tris, hides %s" % (pid, sex, tris, hides))
        mats = {"main": {"label": "main colour", "default": cols[0]}, "trim": {"label": "trim colour", "default": cols[1]},
                "accent": {"label": "accent colour", "default": cols[2]}}
        if pid == "x_glasses":
            mats = {"main": {"label": "frame colour", "default": cols[0]}}
        if pid == "x_watch":
            mats = {"main": {"label": "band colour", "default": cols[0]}, "accent": {"label": "face colour", "default": cols[2]}}
        e = {"id": "%s_%s" % (pid, sex), "base_id": pid, "body": sex, "tris": tris,
             "glb": "res://models/ubc/%s_%s.gltf" % (pid, sex), "materials": mats, "slot": slot, "layer": layer,
             "label": label, "default_color": cols[0], "texture": fabric, "hides": hides}
        if pid == "top_tee":
            e["shirt_words"] = True
            e["shirt_words_at"] = {"bone": "mixamorig_Spine2", "height": round(float(F.head["mixamorig_Spine2"][2]) + 0.03, 3)}
        entries.append(e)
    return entries


def _open(sex):
    U.reset()
    bpy.ops.wm.open_mainfile(filepath=os.path.join(U.SCRATCH, "body_%s.blend" % sex))
    return bpy.data.objects["Armature"], bpy.data.objects["body"]
