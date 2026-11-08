"""Surfaces on hm08: the skin of one LOD and every garment shell are `Surf`s whose vertices are
weighted sums of hm08 vertices, so any body shape, joint weight and morph carries over exactly.

  Surf.src (n,k) hm08 vertex ids, Surf.w (n,k) weights (rows sum to 1)
  Surf.tri (m,3) triangles, Surf.cuv (m,3,2) corner UVs in hm08's UV space, IMAGE coordinates
  (x right, y down, 0..1), the coordinates every texture here is painted in.

The LOD maps (`.scratch/cast/map_lod0.npz`, `map_lod1.npz`) come from skinmap.py (Blender collapse
decimation of hm08, face kept whole, every low vertex projected back onto hm08 as barycentrics).
"""
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "characters"))
import mh  # noqa: E402

MAPS = os.path.join(mh.PROJ, ".scratch", "cast")
K = 6


def quads_to_tris(q):
    return np.concatenate([q[:, [0, 1, 2]], q[:, [0, 2, 3]]])


class Surf:
    def __init__(self, src, w, tri, cuv):
        self.src = np.asarray(src, np.int64)
        self.w = np.asarray(w, np.float64)
        self.tri = np.asarray(tri, np.int64)
        self.cuv = np.asarray(cuv, np.float64)
        self.pos = None          # optional explicit positions (garments after offsetting)

    def __len__(self):
        return len(self.src)

    def ev(self, X):
        """Per-vertex value of an hm08 per-vertex array X (V,...) on this surface."""
        X = np.asarray(X)
        g = X[self.src]                        # (n,k,...)
        w = self.w.reshape(self.w.shape + (1,) * (X.ndim - 1))
        return (g * w).sum(1)

    def sub(self, tmask):
        """Keep only the triangles in tmask; drop unused vertices."""
        tri = self.tri[tmask]
        used, inv = np.unique(tri.ravel(), return_inverse=True)
        s = Surf(self.src[used], self.w[used], inv.reshape(-1, 3), self.cuv[tmask])
        if self.pos is not None:
            s.pos = self.pos[used]
        return s


def full_map(b):
    """hm08's own skin as a Surf (no decimation)."""
    fi = b.faces_of("body")
    tri = quads_to_tris(b.f[fi])
    tuv = quads_to_tris(b.fuv[fi])
    cuv = b.uv[tuv].copy()
    cuv[..., 1] = 1 - cuv[..., 1]
    n = mh.N_BODY
    src = np.zeros((n, K), np.int64); src[:, 0] = np.arange(n)
    w = np.zeros((n, K)); w[:, 0] = 1
    return Surf(src, w, tri, cuv)


def load_map(lod):
    p = os.path.join(MAPS, "map_%s.npz" % lod)
    if not os.path.exists(p):
        raise SystemExit("cast: no %s (run: BPY tools/blender/cast/skinmap.py)" % p)
    z = np.load(p)
    n = len(z["src"])
    src = np.zeros((n, K), np.int64); src[:, :3] = z["src"]
    w = np.zeros((n, K)); w[:, :3] = z["bw"]
    cuv = z["luv"].copy()
    cuv[..., 1] = 1 - cuv[..., 1]
    return Surf(src, w, z["tri"], cuv)


def _compact(src, w):
    """Merge duplicate sources per row and keep the K largest weights."""
    n, k = src.shape
    out_s = np.zeros((n, K), np.int64)
    out_w = np.zeros((n, K))
    order = np.argsort(src, axis=1)
    s2 = np.take_along_axis(src, order, 1)
    w2 = np.take_along_axis(w, order, 1)
    for i in range(n):
        d = {}
        for a, b in zip(s2[i], w2[i]):
            if b > 0:
                d[a] = d.get(a, 0.0) + b
        it = sorted(d.items(), key=lambda x: -x[1])[:K]
        tot = sum(x[1] for x in it) or 1.0
        for j, (a, b) in enumerate(it):
            out_s[i, j] = a
            out_w[i, j] = b / tot
    return out_s, out_w


def clip(S, f):
    """The part of S where f >= 0, cut exactly along f = 0 (shared edge points, so no cracks)."""
    f = np.where(np.abs(f) < 1e-5, 1e-5, f)
    keep = f >= 0
    tri = S.tri
    kin = keep[tri]
    cnt = kin.sum(1)
    out_tri = [tri[cnt == 3]]
    out_cuv = [S.cuv[cnt == 3]]
    new = {}                     # edge (a,b) -> new vertex id
    new_src, new_w, new_pos = [], [], []
    n0 = len(S)
    hasp = S.pos is not None

    def edge(a, b):
        key = (min(a, b), max(a, b))
        if key not in new:
            t = f[a] / (f[a] - f[b])
            new[key] = n0 + len(new_src)
            new_src.append(np.concatenate([S.src[a], S.src[b]]))
            new_w.append(np.concatenate([S.w[a] * (1 - t), S.w[b] * t]))
            if hasp:
                new_pos.append(S.pos[a] * (1 - t) + S.pos[b] * t)
        return new[key]

    def uvt(ua, ub, a, b):
        t = f[a] / (f[a] - f[b])
        return ua * (1 - t) + ub * t

    tri_l, cuv_l = [], []
    for ti in np.nonzero((cnt > 0) & (cnt < 3))[0]:
        v = tri[ti]
        u = S.cuv[ti]
        k = kin[ti]
        # rotate so the odd vertex is first
        if cnt[ti] == 1:
            r = int(np.argmax(k))
        else:
            r = int(np.argmin(k))
        idx = [(r + j) % 3 for j in range(3)]
        A, B, C = v[idx]
        uA, uB, uC = u[idx]
        AB = edge(A, B); AC = edge(A, C)
        uAB = uvt(uA, uB, A, B); uAC = uvt(uA, uC, A, C)
        if cnt[ti] == 1:          # A kept
            tri_l.append([A, AB, AC]); cuv_l.append([uA, uAB, uAC])
        else:                     # B, C kept, A out
            tri_l.append([AB, B, C]); cuv_l.append([uAB, uB, uC])
            tri_l.append([AB, C, AC]); cuv_l.append([uAB, uC, uAC])
    if tri_l:
        out_tri.append(np.array(tri_l, np.int64))
        out_cuv.append(np.array(cuv_l))
    src = S.src; w = S.w
    if new_src:
        ns, nw = _compact(np.array(new_src), np.array(new_w))
        src = np.concatenate([src, ns]); w = np.concatenate([w, nw])
    T = Surf(src, w, np.concatenate(out_tri), np.concatenate(out_cuv))
    if hasp:
        T.pos = np.concatenate([S.pos, np.array(new_pos).reshape(-1, 3)]) if new_pos else S.pos
    used = np.zeros(len(T), bool); used[T.tri.ravel()] = True
    return T.sub(np.ones(len(T.tri), bool)) if not used.all() else T


def vertex_normals(v, tri):
    fn = np.cross(v[tri[:, 1]] - v[tri[:, 0]], v[tri[:, 2]] - v[tri[:, 0]])
    vn = np.zeros_like(v)
    for k in range(3):
        np.add.at(vn, tri[:, k], fn)
    return vn / np.maximum(np.linalg.norm(vn, axis=1, keepdims=True), 1e-12)


def boundary_edges(tri):
    """Directed boundary edges (a, b) as they appear in their one triangle."""
    e = np.concatenate([tri[:, [0, 1]], tri[:, [1, 2]], tri[:, [2, 0]]])
    key = np.sort(e, 1)
    u, inv, cnt = np.unique(key, axis=0, return_inverse=True, return_counts=True)
    return e[cnt[inv.ravel()] == 1]


def loops(edges):
    """Boundary edges -> list of closed vertex loops (in edge direction)."""
    nxt = {int(a): int(b) for a, b in edges}
    seen = set()
    out = []
    for s in list(nxt):
        if s in seen:
            continue
        lp = [s]; seen.add(s)
        c = nxt.get(s)
        while c is not None and c != s and c not in seen:
            lp.append(c); seen.add(c); c = nxt.get(c)
        out.append(lp)
    return out


def neighbours(tri, n):
    rows, cols = [], []
    for a, b in ((0, 1), (1, 2), (2, 0)):
        rows += [tri[:, a], tri[:, b]]; cols += [tri[:, b], tri[:, a]]
    r = np.concatenate(rows); c = np.concatenate(cols)
    key = np.unique(np.stack([r, c], 1), axis=0)
    return key


def smooth(P, tri, iters, lam=0.5, fixed=None):
    """Umbrella smoothing; boundary vertices are smoothed along the boundary only."""
    n = len(P)
    E = neighbours(tri, n)
    bd = boundary_edges(tri)
    isb = np.zeros(n, bool); isb[bd.ravel()] = True
    BE = np.concatenate([bd, bd[:, ::-1]])
    for _ in range(iters):
        acc = np.zeros_like(P); cnt = np.zeros(n)
        m = ~isb[E[:, 0]]
        np.add.at(acc, E[m, 0], P[E[m, 1]]); np.add.at(cnt, E[m, 0], 1)
        np.add.at(acc, BE[:, 0], P[BE[:, 1]]); np.add.at(cnt, BE[:, 0], 1)
        avg = acc / np.maximum(cnt, 1)[:, None]
        Q = P + lam * (avg - P) * (cnt > 0)[:, None]
        if fixed is not None:
            Q[fixed] = P[fixed]
        P = Q
    return P


# ---- UV islands of hm08 (in image coordinates) -------------------------------------------------
_ISL = None


def island_image(b, res=1024):
    """(res,res) int image of hm08's UV islands (-1 = empty) and the id of the main head island."""
    global _ISL
    if _ISL is not None:
        return _ISL
    from PIL import Image, ImageDraw
    fi = b.faces_of("body")
    fuv = b.fuv[fi]
    # union-find over uv indices
    par = np.arange(len(b.uv))

    def find(x):
        while par[x] != x:
            par[x] = par[par[x]]
            x = par[x]
        return x
    for q in fuv:
        r0 = find(q[0])
        for x in q[1:]:
            r = find(x)
            if r != r0:
                par[r] = r0
    roots = np.array([find(q[0]) for q in fuv])
    ids = {r: i for i, r in enumerate(np.unique(roots))}
    im = Image.new("I", (res, res), -1)
    d = ImageDraw.Draw(im)
    for q, r in zip(fuv, roots):
        pts = [(b.uv[i][0] * res, (1 - b.uv[i][1]) * res) for i in q]
        d.polygon(pts, fill=ids[r])
    arr = np.array(im)
    # main head island = the island of the nose tip (the frontmost skin vertex on the head)
    head = b.v[:mh.N_BODY]
    tip = int(np.argmax(head[:, 2] - 10 * (head[:, 1] < head[:, 1].max() - 0.3)))
    qi = np.nonzero((b.f[fi] == tip).any(1))[0][0]
    hid = ids[roots[qi]]
    ys, xs = np.nonzero(arr == hid)
    box = (xs.min() / res, ys.min() / res, (xs.max() + 1) / res, (ys.max() + 1) / res)
    uvq = b.fuv[fi][qi]
    tipuv = b.uv[uvq].mean(0)
    _ISL = (arr, hid, box, (tipuv[0], 1 - tipuv[1]))
    return _ISL


def island_of(b, cuv):
    arr, hid, box, tip = island_image(b)
    res = arr.shape[0]
    c = cuv.mean(1)
    x = np.clip((c[:, 0] * res).astype(int), 0, res - 1)
    y = np.clip((c[:, 1] * res).astype(int), 0, res - 1)
    isl = arr[y, x]
    # centroids that fall in a gap (thin slivers): nearest corner's island
    for j in range(3):
        bad = isl < 0
        if not bad.any():
            break
        x = np.clip((cuv[bad, j, 0] * res).astype(int), 0, res - 1)
        y = np.clip((cuv[bad, j, 1] * res).astype(int), 0, res - 1)
        isl[bad] = arr[y, x]
    return isl
