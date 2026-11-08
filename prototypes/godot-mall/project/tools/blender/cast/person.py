"""One cast member's body on hm08 (MakeHuman CC0 data, read by ../characters/mh.py): shape, joints,
skeleton (rest + bind), skin weights and the face's expression morphs.

Everything here is numpy; nothing from MPFB's GPL code. The skeleton rules are B1's (CHAR-STRIP
deletes ../characters/body.py, so they are restated here):
  * 65 Mixamo bones named as the NPC skins are in Godot (mixamorig_Hips ... mixamorig_RightToe_End),
    plus eye.L, eye.R and jaw under mixamorig_Head (placed from hm08's joint cubes).
  * REST (glTF node TRS = Godot's Skeleton3D rest) = the Mixamo T-pose with Ch01's global bone
    rotations (npc/anims.json "rest"), so scripts/npc_rig.gd finds nothing to retarget and every clip
    in npc/anims.res plays as authored.
  * BIND (inverse bind matrices) = the A-pose hm08 is modelled in: limb bones are turned from Ch01's
    direction onto the mesh's own limb direction, torso bones keep Ch01's rotation.
"""
import json
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "characters"))
import mh  # noqa: E402
from gltf import qmul, qinv, qrot, qarc  # noqa: E402

PROJ = mh.PROJ
N = mh.N_BODY
FINGERS = ["Thumb", "Index", "Middle", "Ring", "Pinky"]
TORSO = {"Hips", "Spine", "Spine1", "Spine2", "Neck", "Head", "HeadTop_End"}
EXTRA_BONES = [("eye.L", "joint-l-eye"), ("eye.R", "joint-r-eye"), ("jaw", "joint-jaw")]

# The face's morph targets: name -> [(expression unit, weight)]. The units are MakeHuman's CC0
# expression units (targets/expression/units/<ethnicity>/), mixed by the person's ethnicity.
# "left" in MakeHuman = the person's left = +X = glTF "_L".
MORPHS = [
    ("blink_L", [("eye-left-closure", 1.0)]),
    ("blink_R", [("eye-right-closure", 1.0)]),
    ("squint_L", [("eye-left-slit", 1.0)]),
    ("squint_R", [("eye-right-slit", 1.0)]),
    ("eyes_wide", [("eye-left-opened-up", 1.0), ("eye-right-opened-up", 1.0)]),
    ("smile", [("mouth-corner-puller", 1.0)]),
    ("jaw_open", [("mouth-open", 1.0)]),
    ("brow_up", [("eyebrows-left-up", 1.0), ("eyebrows-right-up", 1.0)]),
    ("brow_down", [("eyebrows-left-down", 1.0), ("eyebrows-right-down", 1.0)]),
    ("brow_inner_up", [("eyebrows-left-inner-up", 1.0), ("eyebrows-right-inner-up", 1.0)]),
    ("brow_up_L", [("eyebrows-left-up", 1.0)]),
    ("brow_up_R", [("eyebrows-right-up", 1.0)]),
    ("mouth_pucker", [("mouth-pursing", 1.0)]),
    ("mouth_press", [("mouth-compression", 1.0)]),
    ("mouth_wide", [("mouth-retraction", 1.0)]),
    ("mouth_funnel", [("mouth-protusion", 1.0)]),
    ("frown", [("mouth-depression", 1.0)]),
    ("lip_upper_up", [("mouth-elevation", 1.0)]),
    ("lips_part", [("mouth-parling", 1.0)]),
    ("sneer", [("nose-left-elevation", 1.0), ("nose-right-elevation", 1.0)]),
]


def short(n):
    return n.replace("mixamorig_", "").replace("Left", "").replace("Right", "")


def bone_list(rig):
    """[(godot name, parent godot name, mpfb rig key or None)] in parent-first order."""
    def g(n):
        return n.replace(":", "_")
    order = ["mixamorig:Hips"]
    i = 0
    while i < len(order):
        for n, b in rig.items():
            if b["parent"] == order[i] and n not in order:
                order.append(n)
        i += 1
    out = [(g(n), g(rig[n]["parent"]) if rig[n]["parent"] else None, n) for n in order]
    ends = [("mixamorig_HeadTop_End", "mixamorig_Head")]
    for s in ("Left", "Right"):
        ends.append(("mixamorig_%sToe_End" % s, "mixamorig_%sToeBase" % s))
        for f in FINGERS:
            ends.append(("mixamorig_%sHand%s4" % (s, f), "mixamorig_%sHand%s3" % (s, f)))
    out += [(n, p, None) for n, p in ends]
    out += [(n, "mixamorig_Head", None) for n, _ in EXTRA_BONES]
    return out


class Person:
    """Shape + rig of one cast member from its data file (tools/blender/cast/<id>.json)."""

    def __init__(self, data, base=None):
        self.data = data
        self.b = base or mh.Base()
        self.rig = mh.rig()
        self.bones = bone_list(self.rig)
        self.names = [n for n, _, _ in self.bones]
        self.parent = {n: p for n, p, _ in self.bones}
        anims = json.load(open(os.path.join(PROJ, "npc", "anims.json")))
        rest = anims["rest"]
        self.ch01 = {}
        for n, p, _ in self.bones:
            if n in rest:
                q = np.array(rest[n], float)
            else:                      # eye / jaw: the head's orientation (local identity)
                q = np.array(rest["mixamorig_Head"], float)
            self.ch01[n] = q / np.linalg.norm(q)
        self.params = self.macro_params()
        d = mh.evaluate(self.b, self.params, self.face_terms())
        v = self.b.v + d
        self.soles = np.argsort(v[:N, 1])[:60]
        lift = float(data.get("shoe_sole_m", 0.02))
        v[:, 1] -= v[self.soles, 1].min() - lift
        J = self.joints(v)
        v[:, 0] -= J["mixamorig_Hips"][0]
        v[:, 2] -= J["mixamorig_Hips"][2]
        self.v = v
        self.J = self.joints(v)
        self.ethnic = {k: float(self.params[k]) for k in ("african", "asian", "caucasian")}
        self.jaw_deg = self.fit_jaw()

    def fit_jaw(self):
        """hm08's joint-jaw cube sits at the chin, not the hinge: place the jaw bone at the pivot of the
        rigid rotation (about X) that best matches what the CC0 mouth-open unit does to the lower
        teeth, and return that angle (degrees, about +X) for jaw_open = 1."""
        vi = self.b.verts_of("helper-lower-teeth")
        d = dict(self.morphs())["jaw_open"][vi]
        p = self.v[vi][:, 1:3]; q = p + d[:, 1:3]
        best = None
        for deg in np.linspace(1, 40, 391):
            th = np.radians(deg)
            for sg in (1, -1):
                c, s_ = np.cos(sg * th), np.sin(sg * th)
                R = np.array([[c, -s_], [s_, c]])        # acts on (y, z): rotation about +X
                A = np.eye(2) - R
                rhs = (q - p @ R.T).mean(0)
                cen = np.linalg.solve(A, rhs)
                err = np.linalg.norm((p - cen) @ R.T + cen - q, axis=1).mean()
                if best is None or err < best[0]:
                    best = (err, sg * deg, cen)
        err, deg, cen = best
        self.J["jaw"] = np.array([0.0, cen[0], cen[1]])
        self.jaw_fit_mm = float(err * 1000)
        return float(deg)

    # ---- shape
    def macro_params(self):
        m = dict(self.data["macro"])
        p = {}
        p["gender"] = 1.0 if m.get("sex") == "male" else 0.0 if m.get("sex") == "female" else float(m.get("gender", 0.5))
        p["age"] = mh.age_value(float(m.get("age_years", 25)))
        for k in ("muscle", "weight", "height", "proportions", "cupsize", "firmness"):
            if k in m:
                p[k] = float(m[k])
        eth = m.get("ethnicity", {"caucasian": 1.0})
        tot = sum(float(x) for x in eth.values())
        for k in ("african", "asian", "caucasian"):
            p[k] = float(eth.get(k, 0.0)) / tot
        return p

    def face_terms(self):
        out = []
        for t, w in self.data.get("face", {}).items():
            if self.b.target(t) is None:
                raise SystemExit("cast: missing face target " + t)
            out.append((t, float(w)))
        return out

    # ---- joints
    def joints(self, coords):
        J, tails = {}, {}
        for n, p, k in self.bones:
            if k:
                J[n] = mh.joint_pos(self.b, coords, self.rig[k]["head"])
                tails[n] = mh.joint_pos(self.b, coords, self.rig[k]["tail"])
            elif n == "mixamorig_HeadTop_End":
                J[n] = tails[p]
            elif "End" in n or n[-1] == "4":
                J[n] = tails[p]
        for n, cube in EXTRA_BONES:
            J[n] = coords[self.b.verts_of(cube)].mean(0)
        self.tails = tails
        return J

    def skeleton(self):
        """bind global rotations gb, local rest translations lt (both from this body's joints)."""
        J, tails = self.J, self.tails
        gb = {}
        for n, p, k in self.bones:
            q = self.ch01[n]
            if short(n) in TORSO or n in dict(EXTRA_BONES):
                gb[n] = q
            elif k:
                y = qrot(q, [0, 1, 0])
                gb[n] = qmul(qarc(y, tails[n] - J[n]), q)
            else:
                gb[n] = qmul(gb[p], qmul(qinv(self.ch01[p]), q))
        lt = {}
        for n, p, _ in self.bones:
            lt[n] = J[n] if p is None else qrot(qinv(gb[p]), J[n] - J[p])
        return gb, lt

    def rest_local(self, n):
        p = self.parent[n]
        return self.ch01[n] if p is None else qmul(qinv(self.ch01[p]), self.ch01[n])

    # ---- weights (hm08 vertex -> bone), all vertices incl. helpers
    def weights(self):
        W = np.zeros((len(self.b.v), len(self.names)), np.float32)
        for k, lst in mh.weights().items():
            j = self.names.index(k.replace(":", "_"))
            a = np.array(lst)
            W[a[:, 0].astype(int), j] = a[:, 1]
        # MPFB's weights are not normalised per vertex (a foot vertex: Foot 0.2 + ToeBase 0.2)
        s = W.sum(1, keepdims=True)
        return np.where(s > 0, W / np.maximum(s, 1e-9), 0).astype(np.float32)

    # ---- morphs: dense (V,3) deltas on hm08 vertices
    def morphs(self):
        out = []
        for name, units in MORPHS:
            d = np.zeros_like(self.b.v)
            for u, w in units:
                for eth, ew in self.ethnic.items():
                    if ew <= 0:
                        continue
                    t = self.b.target("expression/units/%s/%s" % (eth, u))
                    if t is None:
                        raise SystemExit("cast: missing expression unit %s/%s" % (eth, u))
                    d += w * ew * t
            out.append((name, d))
        return out

    def height(self):
        return float(self.v[:N, 1].max())
