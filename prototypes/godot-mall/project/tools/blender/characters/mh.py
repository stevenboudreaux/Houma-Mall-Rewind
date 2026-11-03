"""MakeHuman CC0 data, read with numpy only (no MakeHuman / MPFB code is used).

Coordinates: MakeHuman's own space is Y-up, facing +Z, in decimetres; that is glTF / Godot space,
so everything here is MakeHuman * 0.1 (metres, Y-up, the body faces +Z, its left hand at +X).

What is read (all under .scratch/mh/mpfb2/src/mpfb/data, fetched by fetch_mh.sh):
  3dobjs/base.obj                    hm08 base mesh: 13380 body verts + helpers (eyes, teeth, tongue,
                                     lashes) + joint cubes; quads; one UV atlas
  targets/**.target.gz               sparse vertex offsets ("index dx dy dz", decimetres)
  rigs/standard/rig.mixamo.json      bone heads/tails as vertex means / joint cubes (MPFB's Mixamo rig)
  rigs/standard/weights.mixamo.json  per-bone vertex weights on hm08
  mesh_metadata/basemesh_vertex_groups.json, textures/mpfb_*.jpg (UV region masks)

Macro model (the MakeHuman 1.1 rules, re-implemented): a body is a dict of parameters
  gender 0 female .. 1 male, age 0 (1 y) .. 0.1875 (11 y) .. 0.5 (25 y) .. 1 (90 y),
  muscle, weight, height, proportions, cupsize, firmness (0..1, 0.5 average),
  african / asian / caucasian (sum 1)
and its shape is the sum of the macro targets weighted by products of those parameters' piecewise
linear weights, plus any number of plain (additive) targets.
"""
import gzip
import json
import os

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
DATA = os.path.join(PROJ, ".scratch", "mh", "mpfb2", "src", "mpfb", "data")
SCALE = 0.1
N_BODY = 13380          # vertices 0..13379 are the skin; the rest are helpers and joint cubes

DEFAULTS = {"gender": 0.5, "age": 0.5, "muscle": 0.5, "weight": 0.5, "height": 0.5, "proportions": 0.5,
            "cupsize": 0.5, "firmness": 0.5, "african": 1 / 3, "asian": 1 / 3, "caucasian": 1 / 3}


def path(*p):
    return os.path.join(DATA, *p)


class Base:
    """hm08: positions (N,3) metres, quads (F,4), per-corner UV indices (F,4), uvs (T,2), face groups."""

    def __init__(self):
        vs, uvs, faces, fuv, groups = [], [], [], [], []
        g = None
        with open(path("3dobjs", "base.obj")) as f:
            for l in f:
                if l.startswith("v "):
                    vs.append([float(x) for x in l.split()[1:4]])
                elif l.startswith("vt "):
                    uvs.append([float(x) for x in l.split()[1:3]])
                elif l.startswith("g "):
                    g = l.split(None, 1)[1].strip()
                elif l.startswith("f "):
                    c = [x.split("/") for x in l.split()[1:]]
                    faces.append([int(a[0]) - 1 for a in c])
                    fuv.append([int(a[1]) - 1 for a in c])
                    groups.append(g)
        self.v = np.array(vs, np.float64) * SCALE
        self.uv = np.array(uvs, np.float64)
        self.f = np.array(faces, np.int64)
        self.fuv = np.array(fuv, np.int64)
        self.group = np.array(groups)
        self._t = {}

    def faces_of(self, group):
        return np.nonzero(self.group == group)[0]

    def verts_of(self, group):
        return np.unique(self.f[self.faces_of(group)].ravel())

    def target(self, rel):
        """Sparse target -> dense (N,3) offset in metres (zeros where absent; missing file -> None)."""
        if rel in self._t:
            return self._t[rel]
        p = path("targets", rel + ".target.gz")
        if not os.path.exists(p):
            self._t[rel] = None
            return None
        d = np.zeros_like(self.v)
        with gzip.open(p, "rt") as f:
            rows = [l.split() for l in f if l.strip() and not l.startswith("#")]
        if rows:
            a = np.array(rows, np.float64)
            d[a[:, 0].astype(np.int64)] = a[:, 1:4] * SCALE
        self._t[rel] = d
        return d


# ---- the macro rules ------------------------------------------------------------------------
def _three(v, lo, mid, hi):
    """MakeHuman's min/average/max split of a 0..1 value."""
    mx = max(0.0, v * 2 - 1)
    mn = max(0.0, 1 - v * 2)
    return {lo: mn, mid: 1 - mx - mn, hi: mx}


def _age(a):
    if a < 0.5:
        young = max(0.0, (a - 0.1875) / 0.3125)
        baby = max(0.0, 1 - a / 0.1875)
        child = max(0.0, min(1.0, a / 0.1875) - young)
        return {"baby": baby, "child": child, "young": young, "old": 0.0}
    old = max(0.0, a * 2 - 1)
    return {"baby": 0.0, "child": 0.0, "young": 1 - old, "old": old}


def age_years(a):
    if a < 0.1875:
        return 1 + a / 0.1875 * 10
    if a < 0.5:
        return 11 + (a - 0.1875) / 0.3125 * 14
    return 25 + (a - 0.5) * 2 * 65


def age_value(years):
    if years < 11:
        return (years - 1) / 10 * 0.1875
    if years < 25:
        return 0.1875 + (years - 11) / 14 * 0.3125
    return 0.5 + (years - 25) / 130


def macro_terms(p):
    """[(target path, weight)] for one parameter set (only non-zero weights)."""
    P = dict(DEFAULTS)
    P.update(p)
    G = {"female": 1 - P["gender"], "male": P["gender"]}
    A = _age(P["age"])
    M = _three(P["muscle"], "minmuscle", "averagemuscle", "maxmuscle")
    W = _three(P["weight"], "minweight", "averageweight", "maxweight")
    H = _three(P["height"], "minheight", "averageheight", "maxheight")
    PR = _three(P["proportions"], "uncommonproportions", "regularproportions", "idealproportions")
    C = _three(P["cupsize"], "mincup", "averagecup", "maxcup")
    FI = _three(P["firmness"], "minfirmness", "averagefirmness", "maxfirmness")
    R = {"african": P["african"], "asian": P["asian"], "caucasian": P["caucasian"]}
    out = []
    for g, gw in G.items():
        for a, aw in A.items():
            if gw * aw == 0:
                continue
            for r, rw in R.items():
                out.append(("macrodetails/%s-%s-%s" % (r, g, a), gw * aw * rw))
            for m, mw in M.items():
                for w, ww in W.items():
                    k = gw * aw * mw * ww
                    if k == 0:
                        continue
                    out.append(("macrodetails/universal-%s-%s-%s-%s" % (g, a, m, w), k))
                    for h, hw in H.items():
                        if h != "averageheight" and hw:
                            out.append(("macrodetails/height/%s-%s-%s-%s-%s" % (g, a, m, w, h), k * hw))
                    for pr, pw in PR.items():
                        if pr != "regularproportions" and pw:
                            out.append(("macrodetails/proportions/%s-%s-%s-%s-%s" % (g, a, m, w, pr), k * pw))
                    if g == "female":
                        for c, cw in C.items():
                            for fi, fw in FI.items():
                                if cw * fw and not (c == "averagecup" and fi == "averagefirmness"):
                                    out.append(("breast/female-%s-%s-%s-%s-%s" % (a, m, w, c, fi), k * cw * fw))
    return [(t, w) for t, w in out if w > 1e-9]


def evaluate(base, params, extra=()):
    """Offsets (N,3) from the base mesh for a parameter set plus [(target, weight)] extras."""
    d = np.zeros_like(base.v)
    for t, w in list(macro_terms(params)) + list(extra):
        x = base.target(t)
        if x is not None:
            d += w * x
    return d


# ---- the rig ----------------------------------------------------------------------------------
def rig():
    return json.load(open(path("rigs", "standard", "rig.mixamo.json")))["bones"]


def weights():
    return json.load(open(path("rigs", "standard", "weights.mixamo.json")))["weights"]


def joint_pos(base, coords, spec):
    """A bone head / tail from MPFB's strategy: mean of a joint cube, of listed verts, or one vert."""
    s = spec.get("strategy")
    if s == "CUBE":
        return coords[base.verts_of(spec["cube_name"])].mean(0)
    if s == "MEAN":
        return coords[spec["vertex_indices"]].mean(0)
    if s == "VERTEX":
        return coords[spec["vertex_index"]]
    raise ValueError("strategy " + str(s))


def mask(name):
    """A UV-space region mask (2048 px, 0..1) from MPFB's textures (lips, fingernails, eyelids ...)."""
    from PIL import Image
    return np.asarray(Image.open(path("textures", "mpfb_%s.jpg" % name)).convert("L"), np.float32) / 255.0
