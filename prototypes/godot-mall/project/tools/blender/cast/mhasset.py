"""MakeHuman's CC0 asset library (fetch_mhassets.sh), read with numpy only: compiled meshes (.npz),
MHCLO proxy fitting, delete_verts, material texture names. No MakeHuman code is used.

MHCLO: every asset vertex is either one hm08 vertex (rigid: eyes) or
    w1 c[v1] + w2 c[v2] + w3 c[v3] + offset * scale
where scale per axis = |c[a]_axis - c[b]_axis| / ref (the x_scale / y_scale / z_scale lines), so the
asset follows any body shape, and (with c + morph delta) every face morph.
"""
import os

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
LIB = os.path.join(PROJ, ".scratch", "mh", "mh11", "x", "usr", "share", "makehuman", "data")


def path(*p):
    return os.path.join(LIB, *p)


class Asset:
    """One proxy asset: kind/name (e.g. 'hair/short02'), mesh, UVs, fitting refs, deleted hm08 verts."""

    def __init__(self, rel, mhclo=None):
        self.rel = rel
        d = path(rel)
        name = os.path.basename(rel)
        clo = mhclo or os.path.join(d, name + ".mhclo")
        self.dir = os.path.dirname(clo)
        self.read_mhclo(clo)
        z = np.load(os.path.join(self.dir, os.path.splitext(self.obj)[0] + ".npz"))
        self.coord = z["coord"].astype(np.float64)
        fv = z["fvert"].astype(np.int64)
        fu = z["fuvs"].astype(np.int64)
        tex = z["texco"].astype(np.float64)
        tri, tuv = [], []
        for q, u in zip(fv, fu):
            if q[3] == q[2] or q[3] == q[0]:
                tri.append(q[:3]); tuv.append(u[:3])
            else:
                tri += [q[[0, 1, 2]], q[[0, 2, 3]]]; tuv += [u[[0, 1, 2]], u[[0, 2, 3]]]
        self.tri = np.array(tri)
        cuv = tex[np.array(tuv)]
        cuv[..., 1] = 1 - cuv[..., 1]            # image coordinates
        self.cuv = cuv
        if len(self.refs) != len(self.coord):
            raise SystemExit("mhasset: %s has %d refs for %d verts" % (rel, len(self.refs), len(self.coord)))

    def read_mhclo(self, p):
        self.scale = {}
        self.delete = []
        refs, ws, offs = [], [], []
        mode = None
        self.material = None
        self.obj = None
        for line in open(p, encoding="utf-8", errors="replace"):
            line = line.split("#")[0].strip()
            if not line:
                continue
            w = line.split()
            if w[0] == "verts":
                mode = "verts"; continue
            if w[0] == "delete_verts":
                mode = "del"; continue
            if mode == "verts" and w[0][0].isdigit() or (mode == "verts" and w[0][0] == "-"):
                if len(w) == 1:
                    refs.append([int(w[0])] * 3); ws.append([1, 0, 0]); offs.append([0, 0, 0])
                elif len(w) >= 9:
                    refs.append([int(x) for x in w[:3]]); ws.append([float(x) for x in w[3:6]])
                    offs.append([float(x) for x in w[6:9]])
                continue
            if mode == "del" and (w[0][0].isdigit()):
                i = 0
                while i < len(w):
                    if i + 2 < len(w) and w[i + 1] == "-":
                        self.delete += list(range(int(w[i]), int(w[i + 2]) + 1)); i += 3
                    else:
                        self.delete.append(int(w[i])); i += 1
                continue
            mode = None if w[0] not in ("verts", "delete_verts") else mode
            if w[0] in ("x_scale", "y_scale", "z_scale"):
                self.scale["xyz".index(w[0][0])] = (int(w[1]), int(w[2]), float(w[3]))
            elif w[0] == "obj_file":
                self.obj = w[1]
            elif w[0] == "material":
                self.material = w[1]
        self.refs = np.array(refs, np.int64)
        self.w = np.array(ws, np.float64)
        self.offs = np.array(offs, np.float64)
        self.delete = np.array(sorted(set(self.delete)), np.int64)

    def fit(self, c, delta=None):
        """Asset vertex positions on body coords c (hm08, metres); with delta: the asset's delta."""
        sc = np.ones(3)
        for ax, (a, b, ref) in self.scale.items():
            sc[ax] = abs(c[a, ax] - c[b, ax]) / ref
        if delta is not None:
            return (delta[self.refs] * self.w[..., None]).sum(1)
        return (c[self.refs] * self.w[..., None]).sum(1) + self.offs * sc

    def weights(self, W):
        """Bone weights from the hm08 refs (the same blend the position uses)."""
        return (W[self.refs] * self.w[..., None]).sum(1)

    def mat(self):
        """{key: value} of the asset's .mhmat (diffuseTexture, normalmapTexture, ...)."""
        out = {}
        p = os.path.join(self.dir, self.material) if self.material else None
        if p is None or not os.path.exists(p):
            return out
        for line in open(p, encoding="utf-8", errors="replace"):
            w = line.split("//")[0].split("#")[0].split()
            if len(w) >= 2:
                out[w[0]] = " ".join(w[1:])
        return out

    def texture(self, key="diffuseTexture"):
        m = self.mat()
        if key not in m:
            return None
        p = os.path.normpath(os.path.join(os.path.dirname(os.path.join(self.dir, self.material)), m[key]))
        return p if os.path.exists(p) else None


def skin_texture(name):
    return path("skins", "textures", name + ".png")


def eye_texture(name):
    return path("eyes", "materials", name + ".png")
