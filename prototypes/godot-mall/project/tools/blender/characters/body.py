"""The two base bodies: MakeHuman hm08 (CC0) evaluated as a female / male base, with every slider of
keys.json as blend shapes, on the project's Mixamo skeleton.

Skeleton (design/godot-characters.md "Skeleton compatibility"):
  * 65 bones named as the NPC skins are in Godot (mixamorig_Hips ... mixamorig_RightToe_End).
  * REST pose (the glTF joint nodes, so Godot's Skeleton3D rest) = the Mixamo T-pose with exactly
    Ch01's global bone rotations (npc/anims.json "rest"): scripts/npc_rig.gd then finds nothing to
    fix, and every clip in npc/anims.res plays as authored.
  * BIND pose (the inverse bind matrices) = the A-pose the mesh is modelled and weighted in. Limb
    bones are turned from Ch01's direction onto the mesh's own limb direction (shortest arc), torso
    bones keep Ch01's rotation. At rest the skin is therefore shown in the T-pose.
  * Joint positions come from MPFB's Mixamo rig definition (means of hm08 vertices / joint cubes),
    so they move with every blend shape: the manifest lists, per blend shape, how far each bone's
    rest translation moves (`joints`), and the loader adds them (scripts/char_body.gd).

Run inside Blender's Python or plain python3 (numpy only):  python3 body.py [female|male] [--out DIR]
"""
import json
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mh  # noqa: E402
import glb  # noqa: E402
from glb import qmul, qinv, qrot, qarc, xform  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = mh.PROJ
OUT = os.path.join(PROJ, "models", "characters")
KEYS = json.load(open(os.path.join(HERE, "keys.json")))

# Ch01's 65 bones: parent of each (Mixamo standard), MPFB names use ':' and lack the *_End / *4 bones.
FINGERS = ["Thumb", "Index", "Middle", "Ring", "Pinky"]
LASHES = (1, 2)
TORSO = {"Hips", "Spine", "Spine1", "Spine2", "Neck", "Head", "HeadTop_End"}

# Body regions (UV2.x = region id): a garment lists the regions it covers completely, and the
# loader hides those regions of the body and of every lower layer (design note "Layering").
REGIONS = ["head", "neck", "chest_f", "chest_b", "belly_f", "belly_b", "pelvis_f", "pelvis_b",
           "shoulder_l", "shoulder_r", "upperarm_l", "upperarm_r", "forearm_l", "forearm_r", "hand_l", "hand_r",
           "thigh_l", "thigh_r", "shin_l", "shin_r", "foot_l", "foot_r", "crotch"]


def bone_list(rig):
    out = []          # (godot name, parent godot name, mpfb key or None)
    def g(n):
        return n.replace(":", "_")
    order = ["mixamorig:Hips"]
    i = 0
    while i < len(order):
        for n, b in rig.items():
            if b["parent"] == order[i] and n not in order:
                order.append(n)
        i += 1
    for n in order:
        out.append((g(n), g(rig[n]["parent"]) if rig[n]["parent"] else None, n))
    ends = [("mixamorig_HeadTop_End", "mixamorig_Head")]
    for s in ("Left", "Right"):
        ends.append(("mixamorig_%sToe_End" % s, "mixamorig_%sToeBase" % s))
        for f in FINGERS:
            ends.append(("mixamorig_%sHand%s4" % (s, f), "mixamorig_%sHand%s3" % (s, f)))
    for n, p in ends:
        out.append((n, p, None))
    return out


def short(n):
    return n.replace("mixamorig_", "").replace("Left", "").replace("Right", "")


class Body:
    def __init__(self, sex):
        self.sex = sex
        self.b = mh.Base()
        self.params = dict(KEYS["bodies"][sex]["macro"])
        self.rig = mh.rig()
        self.bones = bone_list(self.rig)
        self.names = [n for n, _, _ in self.bones]
        self.parent = {n: p for n, p, _ in self.bones}
        rest = json.load(open(os.path.join(PROJ, "npc", "anims.json")))["rest"]
        self.ch01 = {n: np.array(rest[n], float) / np.linalg.norm(rest[n]) for n in self.names}
        self.d0 = mh.evaluate(self.b, self.params)
        self.v0 = self.b.v + self.d0
        soles = np.argsort(self.v0[:mh.N_BODY, 1])[:60]
        self.soles = soles
        self.v0[:, 1] -= self.v0[soles, 1].min()
        self.v0[:, 2] -= self.joints(self.v0)["mixamorig_Hips"][2]   # hips over x = z = 0
        self.v0[:, 0] -= self.joints(self.v0)["mixamorig_Hips"][0]
        self.J0 = self.joints(self.v0)

    # ---- joints
    def joints(self, coords):
        J = {}
        tails = {}
        for n, p, k in self.bones:
            if k:
                J[n] = mh.joint_pos(self.b, coords, self.rig[k]["head"])
                tails[n] = mh.joint_pos(self.b, coords, self.rig[k]["tail"])
            else:
                J[n] = tails[p]
        self._tails = tails
        return J

    # ---- blend shapes
    def side_delta(self, side):
        """(N,3) offsets of one slider side from the body's base, feet kept on the ground."""
        if "macro" in side:
            p = dict(self.params); p.update(side["macro"])
            p0 = dict(self.params); p0.update(side.get("from_macro", {}))
            d = mh.evaluate(self.b, p) - mh.evaluate(self.b, p0)
        else:
            d = self.targets(side["targets"])
        return self.grounded(d * float(side.get("scale", 1.0)))

    def targets(self, tl):
        d = np.zeros_like(self.b.v)
        for t, w in tl:
            x = self.b.target(t)
            if x is None:
                raise SystemExit("missing target " + t)
            d += w * x
        return d

    def grounded(self, d):
        d = d.copy()
        d[:, 1] -= d[self.soles, 1].mean()
        return d

    def shapes(self):
        """[(blend shape name, delta)] for this body: slider sides, then correctives."""
        out = []
        sides = {}
        for s in KEYS["sliders"]:
            if s.get("sex") and s["sex"] != self.sex or "bones" in s:
                continue
            for sign in ("+", "-"):
                if sign in s:
                    sd = dict(s[sign])
                    if "from_macro" in s:
                        sd["from_macro"] = s["from_macro"]
                    d = self.side_delta(sd)
                    out.append((s["name"] + sign, d))
                    sides[s["name"] + sign] = sd
        # exact MakeHuman interaction terms (inclusion-exclusion over the macro sides)
        for combo in KEYS["correct"]:
            import itertools
            tot = np.zeros_like(self.b.v)
            for r in range(len(combo) + 1):
                for sub in itertools.combinations(combo, r):
                    p = dict(self.params)
                    for c in sub:
                        p.update(sides[c]["macro"])
                    sgn = (-1) ** (len(combo) - r)
                    tot += sgn * mh.evaluate(self.b, p)
            out.append(("c_" + "_".join(combo), self.grounded(tot)))
        return out

    # ---- skeleton
    def skeleton(self, J):
        """bind (A-pose) and rest (T-pose) global rotations, local translations, IBMs."""
        tails = self._tails
        gb = {}
        for n, p, k in self.bones:
            q = self.ch01[n]
            s = short(n)
            if s in TORSO:
                gb[n] = q
            elif k:
                y = qrot(q, [0, 1, 0])
                gb[n] = qmul(qarc(y, tails[n] - J[n]), q)
            else:   # *_End: same local turn as Ch01's
                gb[n] = qmul(gb[p], qmul(qinv(self.ch01[p]), q))
        loc_t = {}
        for n, p, _ in self.bones:
            loc_t[n] = J[n] if p is None else qrot(qinv(gb[p]), J[n] - J[p])
        return gb, loc_t

    def build(self, out_dir=OUT):
        os.makedirs(out_dir, exist_ok=True)
        b = self.b
        shapes = self.shapes()
        J0 = self.J0
        gb, lt = self.skeleton(J0)
        # joint deltas per blend shape, as local rest-translation offsets
        jd = {}
        for name, d in shapes:
            J = self.joints(self.v0 + d)
            self.joints(self.v0)   # restore tails
            ltk = {}
            for n, p, _ in self.bones:
                t = J[n] if p is None else qrot(qinv(gb[p]), J[n] - J[p])
                dt = t - lt[n]
                if np.abs(dt).max() > 2e-4:
                    ltk[n] = [round(float(x), 5) for x in dt]
            jd[name] = ltk
        info = {}
        for lod in ("lo", "hi"):
            mesh = Mesh(self, shapes, gb, lod)
            fn = "body_%s.glb" % self.sex if lod == "lo" else "body_%s_hi.glb" % self.sex
            info[lod] = mesh.write(os.path.join(out_dir, fn), self.bones, gb, lt)
        info["joints"] = jd
        info["bones"] = self.bone_info(gb, lt)
        info["hips_height"] = float(J0["mixamorig_Hips"][1])
        info["height_m"] = float(self.v0[:mh.N_BODY, 1].max())
        return info

    def bone_info(self, gb, lt):
        out = {}
        for n, p, _ in self.bones:
            rq = self.ch01[n] if p is None else qmul(qinv(self.ch01[p]), self.ch01[n])
            bq = gb[n] if p is None else qmul(qinv(gb[p]), gb[n])
            out[n] = {"parent": p, "pos": [round(float(x), 5) for x in lt[n]],
                      "rest_rot": [round(float(x), 6) for x in rq], "bind_rot": [round(float(x), 6) for x in bq]}
        return out


def topology(b, lod):
    """The skin's triangles as points on hm08: 'hi' = hm08 itself, 'lo' = decimate.py's map."""
    if lod == "hi":
        fi = b.faces_of("body")
        n = mh.N_BODY
        return {"src": np.stack([np.arange(n)] * 3, 1), "bw": np.tile([1.0, 0, 0], (n, 1)),
                "tri": quads_to_tris(b.f[fi]), "luv": b.uv[quads_to_tris(b.fuv[fi])]}
    z = np.load(os.path.join(PROJ, ".scratch", "chars", ("lo2_map" if lod == "lo2" else "lo_map") + ".npz"))
    return {k: z[k] for k in ("src", "bw", "tri", "luv")}


def face_normals(v, tris):
    n = np.cross(v[tris[:, 1]] - v[tris[:, 0]], v[tris[:, 2]] - v[tris[:, 0]])
    return n


def vertex_normals(v, tris):
    fn = face_normals(v, tris)
    vn = np.zeros_like(v)
    for k in range(3):
        np.add.at(vn, tris[:, k], fn)
    l = np.linalg.norm(vn, axis=1, keepdims=True)
    return vn / np.maximum(l, 1e-12)


def quads_to_tris(q):
    return np.concatenate([q[:, [0, 1, 2]], q[:, [0, 2, 3]]])


class Mesh:
    """Assembles body + head (+ eyes, teeth, tongue, lashes) from hm08 for one Body."""

    def __init__(self, body, shapes, gb, lod="lo"):
        self.body = body
        self.topo = topology(body.b, lod)
        self.shapes = shapes
        self.gb = gb

    def weights(self):
        """(N,4) joint indices and weights from MPFB's Mixamo weights, 4 largest per vertex."""
        B = self.body
        W = np.zeros((len(B.b.v), len(B.names)))
        for k, lst in mh.weights().items():
            j = B.names.index(k.replace(":", "_"))
            a = np.array(lst)
            W[a[:, 0].astype(int), j] = a[:, 1]
        return W

    def regions(self, W, v):
        B = self.body
        dom = W.argmax(1)
        J = B.J0
        reg = np.zeros(len(v), np.int64)
        for i in range(len(v)):
            n = short(B.names[dom[i]])
            side = "l" if v[i, 0] > 0 else "r"
            front = v[i, 2] > J["mixamorig_Spine1"][2]
            if n in ("Head", "HeadTop_End"):
                r = "head"
            elif n == "Neck":
                r = "neck"
            elif n == "Spine2":
                r = "chest_f" if front else "chest_b"
            elif n in ("Spine", "Spine1"):
                r = "belly_f" if front else "belly_b"
            elif n == "Hips":
                r = "pelvis_f" if front else "pelvis_b"
                if abs(v[i, 0]) < 0.06 and v[i, 1] < J["mixamorig_Hips"][1] - 0.06:
                    r = "crotch"
            elif n == "Shoulder":
                r = "shoulder_" + side
            elif n == "Arm":
                r = "upperarm_" + side
            elif n == "ForeArm":
                r = "forearm_" + side
            elif n.startswith("Hand"):
                r = "hand_" + side
            elif n == "UpLeg":
                r = "thigh_" + side
            elif n == "Leg":
                r = "shin_" + side
            else:
                r = "foot_" + side
            reg[i] = REGIONS.index(r)
        return reg

    def write(self, path, bones, gb, lt):
        B = self.body
        b = B.b
        v0 = B.v0
        W = self.weights()
        names = B.names
        # head / body split: faces on the head side of a plane through the mid neck
        J = B.J0
        nk, hd = J["mixamorig_Neck"], J["mixamorig_Head"]
        ax = (hd - nk) / np.linalg.norm(hd - nk)
        cut = nk + (hd - nk) * 0.42
        topo = self.topo
        tri = topo["tri"]
        def A(X):
            return (X[topo["src"]] * topo["bw"][..., None]).sum(1)
        pv = A(v0)
        cen = pv[tri].mean(1)
        is_head = ((cen - cut) @ ax) > 0
        parts = {"body": np.nonzero(~is_head)[0], "head": np.nonzero(is_head)[0]}
        # normals on the whole skin at once, so the seam is invisible; per blend shape too
        n0 = vertex_normals(pv, tri)
        sd = [A(d) for _, d in self.shapes]
        dn = [vertex_normals(pv + d, tri) - n0 for d in sd]
        regv = self.regions(W, v0)
        main = topo["src"][np.arange(len(topo["src"])), topo["bw"].argmax(1)]
        reg = regv[main]
        Wt = A(W)
        self._skin = (pv, n0, sd, dn, Wt, reg)
        g = glb.GLB()
        jnodes = {}
        root = None   # no wrapper node: Godot puts Skeleton3D right under the scene root, as in the NPC skins
        for n, p, _ in bones:
            q = B.ch01[n] if p is None else qmul(qinv(B.ch01[p]), B.ch01[n])
            jnodes[n] = g.node({"name": n, "translation": [float(x) for x in lt[n]],
                                "rotation": [float(x) for x in q / np.linalg.norm(q)]})
        for n, p, _ in bones:
            if p is None:
                g.j["scenes"][0]["nodes"].append(jnodes[n])
            else:
                g.j["nodes"][jnodes[p]].setdefault("children", []).append(jnodes[n])
        # inverse bind matrices from the bind (A-pose) globals
        gbind = {}
        for n, p, _ in bones:
            lq = gb[n] if p is None else qmul(qinv(gb[p]), gb[n])
            m = xform(lq, lt[n])
            gbind[n] = m if p is None else gbind[p] @ m
        ibm = [np.linalg.inv(gbind[n]) for n in names]
        skin = g.skin([jnodes[n] for n in names], ibm, skeleton=jnodes[names[0]])
        mats = {
            "skin": g.material("skin_body", albedo="skin_albedo.png", normal="skin_normal.png", orm="skin_orm.png",
                               extras={"slot": "skin", "tint": "skin"}),
            "face": g.material("skin_face", albedo="skin_albedo.png", normal="skin_normal.png", orm="skin_orm.png",
                               extras={"slot": "face", "tint": "skin"}),
            "teeth": g.material("teeth", color=(0.86, 0.83, 0.76, 1), rough=0.35),
            "mouth": g.material("tongue", color=(0.55, 0.22, 0.23, 1), rough=0.5),
            "sclera": g.material("eye_white", albedo="eye_albedo.png", rough=0.15, extras={"slot": "eye"}),
            "iris": g.material("eye_iris", albedo="eye_albedo.png", rough=0.12, extras={"slot": "eye", "tint": "iris"}),
            "lash": g.material("lashes", albedo="lash_albedo.png", rough=0.7, double=True, alpha="mask",
                               extras={"tint": "hair"}),
        }
        info = {"tris": {}, "verts": {}, "file": os.path.basename(path)}
        meshes = []
        # skin meshes
        for part, fi in parts.items():
            m = self.skin_part(part, fi, None, None, None, None, mats["face" if part == "head" else "skin"])
            meshes.append(m)
        # head extras: teeth, tongue, lashes (MakeHuman helpers, they follow the targets), eyes
        extras = self.helpers(W, mats)
        meshes.extend(extras)
        for m in meshes:
            name, pos, nrm, uv, prims, jw, morphs, col = m
            jj, ww = jw
            mi = g.mesh(name, pos, nrm, uv, prims, jj, ww, morphs, uv2=col)
            g.node({"name": name, "mesh": mi, "skin": skin}, root=True)
            info["tris"][name] = int(sum(len(t) for _, t in prims))
            info["verts"][name] = int(len(pos))
        info["bytes"] = g.write(path, extras={"sex": B.sex})
        info["shapes"] = [n for n, _ in self.shapes]
        info["regions"] = REGIONS
        return info

    def top4(self, Wv):
        idx = np.argsort(-Wv, axis=1)[:, :4]
        w = np.take_along_axis(Wv, idx, 1)
        s = w.sum(1, keepdims=True)
        w = np.where(s > 0, w / np.maximum(s, 1e-12), np.array([1, 0, 0, 0.0]))
        idx = np.where(s > 0, idx, 0)
        return idx.astype(np.uint16), w.astype(np.float32)

    def skin_part(self, name, fi, n0, dn, W, reg, mat):
        pv, n0, sd, dn, Wt, reg = self._skin
        topo = self.topo
        tri = topo["tri"][fi]
        cuv = topo["luv"][fi].reshape(-1, 2)
        key = np.concatenate([tri.reshape(-1, 1).astype(np.float64), np.round(cuv * 8192)], 1)
        uniq, first, inv = np.unique(key, axis=0, return_index=True, return_inverse=True)
        inv = inv.ravel()
        vi = uniq[:, 0].astype(np.int64)
        uv = cuv[first].copy()
        uv[:, 1] = 1 - uv[:, 1]
        tris = inv.reshape(-1, 3)
        morphs = [(sn, d[vi], dnn[vi]) for (sn, _), d, dnn in zip(self.shapes, sd, dn)]
        jj, ww = self.top4(Wt[vi])
        col = np.zeros((len(vi), 2), np.float32)     # UV2.x = region id (not COLOR_0: glTF multiplies albedo by it)
        col[:, 0] = reg[vi]
        return (name, pv[vi], n0[vi], uv, [(mat, tris)], (jj, ww), morphs, col)

    def helpers(self, W, mats):
        B = self.body
        b = B.b
        out = []
        head_j = B.names.index("mixamorig_Head")
        def rigid(n):
            jj = np.zeros((n, 4), np.uint16); jj[:, 0] = head_j
            ww = np.zeros((n, 4), np.float32); ww[:, 0] = 1
            return jj, ww
        # teeth + tongue: plain helper geometry, weighted to the head (no jaw bone in Mixamo)
        for name, groups, mat in (("teeth", ["helper-upper-teeth", "helper-lower-teeth"], mats["teeth"]),
                                  ("tongue", ["helper-tongue"], mats["mouth"])):
            fi = np.concatenate([b.faces_of(gname) for gname in groups])
            q = b.f[fi]
            vi, inv = np.unique(q.ravel(), return_inverse=True)
            tris = quads_to_tris(inv.reshape(-1, 4))
            pos = B.v0[vi]
            nrm = vertex_normals(pos, tris)
            morphs = []
            for sn, d in self.shapes:
                p2 = pos + d[vi]
                morphs.append((sn, d[vi], vertex_normals(p2, tris) - nrm))
            puv = np.zeros((len(vi), 2)); puv[:, 0] = 0.5; puv[:, 1] = 0.5   # untextured; UVs so tangents can be made
            out.append((name, pos, nrm, puv, [(mat, tris)], rigid(len(vi)), morphs, None))
        # lashes: the helper strips, UVs normalised into lash_albedo.png
        fi = np.concatenate([b.faces_of("helper-%s-eyelashes-%d" % (s, k)) for s in "lr" for k in LASHES])
        q = b.f[fi]; qu = b.fuv[fi]
        pairs = np.stack([q.ravel(), qu.ravel()], 1)
        uniq, inv = np.unique(pairs, axis=0, return_inverse=True)
        vi, ti = uniq[:, 0], uniq[:, 1]
        tris = quads_to_tris(inv.ravel().reshape(-1, 4))
        uv = b.uv[ti]
        lo, hi = uv.min(0), uv.max(0)
        # each strip is mapped by its own UV box; lash_albedo.png is one strip, root at v = 0
        strip_uv = np.zeros_like(uv)
        for gname in ["helper-%s-eyelashes-%d" % (s, k) for s in "lr" for k in LASHES]:
            gv = np.isin(vi, b.verts_of(gname))
            u = uv[gv]
            strip_uv[gv] = (u - u.min(0)) / np.maximum(u.max(0) - u.min(0), 1e-6)
        pos = B.v0[vi]
        nrm = vertex_normals(pos, tris)
        morphs = [(sn, d[vi], None) for sn, d in self.shapes]
        out.append(("lashes", pos, nrm, strip_uv, [(mats["lash"], tris)], rigid(len(vi)), morphs, None))
        # eyes: a proper eyeball (sclera + iris cap) fitted to each MakeHuman eye helper per blend shape
        ev, ef, euv, iris = eyeball()
        for s in "lr":
            hv = b.verts_of("helper-%s-eye" % s)
            def fit(coords):
                c = coords[hv].mean(0)
                r = np.linalg.norm(coords[hv] - c, axis=1).mean()
                return c, r
            c0, r0 = fit(B.v0)
            pos = c0 + ev * r0
            nrm = ev.copy()
            morphs = []
            for sn, d in self.shapes:
                c1, r1 = fit(B.v0 + d)
                morphs.append((sn, (c1 + ev * r1) - pos, None))
            prims = [(mats["sclera"], ef[~iris]), (mats["iris"], ef[iris])]
            out.append(("eye_" + s, pos, nrm, euv, prims, rigid(len(ev)), morphs, None))
        return out


def eyeball(seg=16, rings=11):
    """Unit sphere facing +Z; returns verts, tris, uvs (planar front projection into eye_albedo.png)
    and a mask of the iris-cap triangles."""
    v = [[0, 0, 1]]
    for i in range(1, rings):
        th = np.pi * i / rings
        for j in range(seg):
            ph = 2 * np.pi * j / seg
            v.append([np.sin(th) * np.cos(ph), np.sin(th) * np.sin(ph), np.cos(th)])
    v.append([0, 0, -1])
    v = np.array(v)
    t = []
    for j in range(seg):
        t.append([0, 1 + j, 1 + (j + 1) % seg])
    for i in range(rings - 2):
        a = 1 + i * seg
        for j in range(seg):
            p, q2 = a + j, a + (j + 1) % seg
            t.append([p, p + seg, q2]); t.append([q2, p + seg, q2 + seg])
    last = len(v) - 1
    a = 1 + (rings - 2) * seg
    for j in range(seg):
        t.append([a + j, last, a + (j + 1) % seg])
    t = np.array(t)
    # winding outward
    fn = np.cross(v[t[:, 1]] - v[t[:, 0]], v[t[:, 2]] - v[t[:, 0]])
    flip = (fn * v[t].mean(1)).sum(1) < 0
    t[flip] = t[flip][:, ::-1]
    uv = np.stack([0.5 + v[:, 0] * 0.5, 0.5 - v[:, 1] * 0.5], 1)
    iris = v[t].mean(1)[:, 2] > np.cos(0.62)
    return v, t, uv, iris


if __name__ == "__main__":
    sexes = [a for a in sys.argv[1:] if a in ("female", "male")] or ["female", "male"]
    allinfo = {}
    for s in sexes:
        B = Body(s)
        allinfo[s] = B.build()
        for lod in ("lo", "hi"):
            print("BODY", s, lod, sum(allinfo[s][lod]["tris"].values()), allinfo[s][lod]["tris"], allinfo[s][lod]["bytes"])
    os.makedirs(os.path.join(PROJ, ".scratch", "chars"), exist_ok=True)
    for s, i in allinfo.items():
        json.dump(i, open(os.path.join(PROJ, ".scratch", "chars", "body_%s.json" % s), "w"))
