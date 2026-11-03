"""Shared machinery for everything worn on a B1 body: hair, the base layer, outfit pieces.

A piece is modelled on one base body at neutral (its bind / A-pose), then BOUND to that body:
every piece vertex takes the K nearest skin vertices (inside the regions the piece may follow)
with inverse-distance weights, and from them
  * a blend shape for every body blend shape that moves it (same names: the loader gives the
    piece the body's weights, so the piece follows every slider, correctives included),
  * its joint weights (hair: the Head bone only, as the brief asks: static, parented to the head),
  * its region id (UV2.x), so an outer layer can hide this piece where it covers it.
The piece .glb carries the same 65-bone skeleton and inverse bind matrices as the body, so its
Skin's bind indices are the body's (scripts/char_body.gd moves its meshes under the body's
Skeleton3D). Layering clearance comes from each layer's offset from the skin (LAYER_GAP) plus, where
a lower layer is loose, the region hiding of the loader (design note, "Layering").
"""
import json
import os
import sys

import numpy as np
try:
    import bpy  # noqa: F401  (makes mathutils importable)
except ImportError:
    pass

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mh  # noqa: E402
import glb  # noqa: E402
import body as bodymod  # noqa: E402
from glb import qmul, qinv, xform  # noqa: E402

PROJ = mh.PROJ
OUT = os.path.join(PROJ, "models", "characters")
SC = os.path.join(PROJ, ".scratch", "chars")
_CACHE = {}


class Rig:
    """One body at neutral with everything a piece needs: skin verts, shapes, weights, regions."""

    def __init__(self, sex):
        B = bodymod.Body(sex)
        self.B = B
        self.sex = sex
        self.shapes = B.shapes()
        self.gb, self.lt = B.skeleton(B.J0)
        m = bodymod.Mesh(B, self.shapes, self.gb, "hi")
        self.W = m.weights()
        self.reg = m.regions(self.W, B.v0)
        b = B.b
        fi = b.faces_of("body")
        self.tris = bodymod.quads_to_tris(b.f[fi])
        self.v = B.v0[:mh.N_BODY]
        self.n = bodymod.vertex_normals(B.v0, self.tris)[:mh.N_BODY]
        self.J = B.J0
        self.names = B.names
        self._kd = {}

    def kd(self, regions):
        key = tuple(sorted(regions)) if regions else None
        if key not in self._kd:
            from mathutils.kdtree import KDTree
            ids = np.arange(mh.N_BODY)
            if regions:
                ok = np.isin(self.reg, [bodymod.REGIONS.index(r) for r in regions])
                ids = ids[ok[:mh.N_BODY]]
            t = KDTree(len(ids))
            for j, i in enumerate(ids):
                t.insert(self.v[i].tolist(), j)
            t.balance()
            self._kd[key] = (t, ids)
        return self._kd[key]

    def bind(self, P, regions=None, k=8):
        """(idx (N,k), w (N,k)) inverse-distance weights onto skin vertices."""
        t, ids = self.kd(regions)
        I = np.zeros((len(P), k), np.int64); D = np.zeros((len(P), k))
        for n, p in enumerate(P):
            r = t.find_n(p.tolist(), k)
            for j, (co, ix, d) in enumerate(r):
                I[n, j] = ids[ix]; D[n, j] = d
        w = 1.0 / (D * D + 1e-6)
        w /= w.sum(1, keepdims=True)
        return I, w

    def nearest_dist(self, P, regions=None):
        t, ids = self.kd(regions)
        return np.array([t.find(p.tolist())[2] for p in P])

    def surface(self, P, regions=None):
        """closest skin vertex and its normal for each point (for offsetting)."""
        t, ids = self.kd(regions)
        out = np.array([ids[t.find(p.tolist())[1]] for p in P])
        return self.v[out], self.n[out], out


def _lo_skin(R):
    if not hasattr(R, "_lo"):
        topo = bodymod.topology(R.B.b, "lo")
        R._lo = topo
    return R._lo


def _resolve(self, P, dd, d, gap):
    """the push-out: with the body fully at this blend shape, any piece vertex closer than gap to
    the game skin (or inside it) is moved out along the skin normal, and that move becomes part of
    the piece's blend shape. Sliders then combine linearly (extremes checked by fitcheck.py)."""
    from mathutils.bvhtree import BVHTree
    from mathutils import Vector
    topo = _lo_skin(self)
    sv = ((self.B.v0 + d)[topo["src"]] * topo["bw"][..., None]).sum(1)
    bvh = BVHTree.FromPolygons(sv.tolist(), topo["tri"].tolist(), all_triangles=True)
    Q = P + dd
    out = dd.copy()
    for i, q in enumerate(Q):
        loc, nrm, _, dist = bvh.find_nearest(Vector(q))
        if loc is None:
            continue
        s = (Vector(q) - loc).dot(nrm)
        if s < gap:
            out[i] = dd[i] + np.array(nrm) * (gap - s)
    return out


Rig.resolve = _resolve


def rig(sex):
    if sex not in _CACHE:
        _CACHE[sex] = Rig(sex)
    return _CACHE[sex]


def vertex_normals(v, t):
    return bodymod.vertex_normals(v, t)


class Part:
    """One mesh of a piece: positions (bind space), triangles, uvs, a material slot."""

    def __init__(self, name, v, t, uv, mat, follow=None, rigid_bone=None, color=None):
        self.name, self.v, self.t, self.uv, self.mat = name, np.asarray(v, float), np.asarray(t, np.int64), uv, mat
        self.follow, self.rigid_bone, self.color = follow, rigid_bone, color


def write_piece(sex, pid, parts, mats, meta, eps=5e-4, fit_over=False, resolve=None):
    """parts: [Part]; mats: {slot: dict(material kwargs)}. Writes models/characters/<pid>.glb and
    .scratch/chars/piece_<pid>.json (the manifest entry). Returns the entry."""
    R = rig(sex)
    B = R.B
    g = glb.GLB()
    
    jn = {}
    for n, p, _ in B.bones:
        q = B.ch01[n] if p is None else qmul(qinv(B.ch01[p]), B.ch01[n])
        jn[n] = g.node({"name": n, "translation": [float(x) for x in R.lt[n]], "rotation": [float(x) for x in q / np.linalg.norm(q)]})
    for n, p, _ in B.bones:
        (g.j["scenes"][0]["nodes"] if p is None else g.j["nodes"][jn[p]].setdefault("children", [])).append(jn[n])
    gbind = {}
    for n, p, _ in B.bones:
        lq = R.gb[n] if p is None else qmul(qinv(R.gb[p]), R.gb[n])
        m = xform(lq, R.lt[n])
        gbind[n] = m if p is None else gbind[p] @ m
    skin = g.skin([jn[n] for n in B.names], [np.linalg.inv(gbind[n]) for n in B.names], skeleton=jn[B.names[0]])
    mi = {}
    for slot, kw in mats.items():
        kw = dict(kw)
        kw.setdefault("extras", {})["slot"] = slot
        if (kw.get("extras") or {}).get("alpha") == "blend":
            kw["alpha"] = "blend"
        mi[slot] = g.material(pid + "_" + slot, **kw)
    tris = 0
    used_shapes = set()
    for P in parts:
        if resolve:
            P.v = P.v + R.resolve(P.v, np.zeros_like(P.v), np.zeros_like(R.B.v0), resolve)
        I, w = R.bind(P.v, P.follow)
        morphs = []
        nrm = vertex_normals(P.v, P.t)
        for sn, d in R.shapes:
            dd = (d[:mh.N_BODY][I] * w[..., None]).sum(1)
            if resolve and not sn.startswith("c_") and np.abs(dd).max() >= eps:
                dd = R.resolve(P.v, dd, d, resolve)
            if np.abs(dd).max() < eps:
                continue
            morphs.append((sn, dd, None))     # no normal deltas on pieces (size; cloth shading barely changes)
            used_shapes.add(sn)
        if fit_over:
            morphs.append(("fit_over", nrm * 0.006, None))
        if P.rigid_bone:
            jj = np.zeros((len(P.v), 4), np.uint16); jj[:, 0] = B.names.index(P.rigid_bone)
            ww = np.zeros((len(P.v), 4), np.float32); ww[:, 0] = 1
        else:
            Wv = (R.W[:mh.N_BODY][I] * w[..., None]).sum(1)
            jj, ww = bodymod.Mesh.top4(None, Wv)
        reg = R.reg[I[:, 0]]
        uv2 = np.zeros((len(P.v), 2), np.float32); uv2[:, 0] = reg
        uv = P.uv if P.uv is not None else np.full((len(P.v), 2), 0.5)
        m = g.mesh(P.name, P.v, nrm, uv, [(mi[P.mat], P.t)], jj, ww, morphs, uv2=uv2, color=P.color, eps=3e-4)
        g.node({"name": P.name, "mesh": m, "skin": skin}, root=True)
        tris += len(P.t)
    path = os.path.join(OUT, pid + ".glb")
    size = g.write(path, extras={"piece": pid})
    entry = {"id": pid, "base_id": pid.rsplit("_", 1)[0], "glb": "res://models/characters/%s.glb" % pid, "body": sex, "tris": int(tris),
             "bytes": size, "materials": {s: {"label": (k.get("extras") or {}).get("label", s), "default": (k.get("extras") or {}).get("default")}
                                          for s, k in mats.items() if (k.get("extras") or {}).get("tint")},
             "shapes": len(used_shapes)}
    entry.update(meta)
    os.makedirs(SC, exist_ok=True)
    json.dump(entry, open(os.path.join(SC, "piece_%s.json" % pid), "w"), indent=1)
    print("PIECE", pid, tris, "tris", "%.0f KB" % (size / 1024), len(used_shapes), "shapes")
    return entry


def grid_tris(rows, cols, wrap=True):
    """Triangles of a rows x cols vertex grid (row-major), wrapping in columns if wrap."""
    t = []
    cc = cols if wrap else cols - 1
    for r in range(rows - 1):
        for c in range(cc):
            a = r * cols + c; b = r * cols + (c + 1) % cols
            t.append([a, a + cols, b]); t.append([b, a + cols, b + cols])
    return np.array(t, np.int64)


def fix_winding(v, t, center):
    """Make triangles face away from `center` (a point or a function of the triangle centroid)."""
    fn = np.cross(v[t[:, 1]] - v[t[:, 0]], v[t[:, 2]] - v[t[:, 0]])
    c = v[t].mean(1)
    out = c - (center(c) if callable(center) else center)
    flip = (fn * out).sum(1) < 0
    t = t.copy(); t[flip] = t[flip][:, ::-1]
    return t
