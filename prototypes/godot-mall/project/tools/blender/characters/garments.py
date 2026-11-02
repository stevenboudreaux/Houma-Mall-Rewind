"""Outfit pieces (B1; no base layer since B-FIX), built per base body from the CATALOGUE below.

A 'surface' piece is cut from the body's own game-mesh skin:
  1. keep(F) is a signed field over the skin (> 0 keep, metres), built from fields.py's
     height / arm / leg / azimuth / front values and the body's landmarks; the skin's triangles
     are CLIPPED along keep = 0, so hems, necklines and leg openings are clean lines;
  2. offset outward along the normals by the piece's layer gap (+ ease where it hangs looser),
     then smoothed and pushed back out to that clearance;
  3. drape: fronts hang straight down from the bust / belly instead of following under them;
     trouser legs keep at least the knee's radius below the knee (straight), or flare (wide-leg);
  4. a hem lip folds every open edge back toward the skin (no see-through gap at grazing views);
  5. decimated to the piece's budget, colour regions assigned (main / trim / accent);
  6. bound to the body (pieces.write_piece): blend shapes for every slider, joint weights,
     regions. A 'fit_over' blend shape (+6 mm) is added to every piece above the base layer:
     the loader turns it on when another piece of the same or the layer below covers the same
     regions (the "push-out" of the brief).
Loose pieces (skirts, aprons, shoes, caps, glasses, watch) are generated around the body.
Pieces list the regions they cover completely ('hides', computed): the loader hides those
regions on the body and on every lower layer.

  BPY python garments.py [female|male] [piece id ...]
"""
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pieces  # noqa: E402
import body as bodymod  # noqa: E402
from pieces import Part, rig, write_piece, grid_tris  # noqa: E402
from fields import Fields  # noqa: E402
import fabric  # noqa: E402

GAP = {0: 0.0025, 1: 0.005, 2: 0.0075, 3: 0.014, 4: 0.004, 5: 0.003}


# ---------------------------------------------------------------- skin source (game mesh)
class Source:
    def __init__(self, sex, lod="lo"):
        self.R = R = rig(sex)
        topo = bodymod.topology(R.B.b, lod)
        self.src, self.bw = topo["src"], topo["bw"]
        self.T = topo["tri"]
        self.luv = topo["luv"]
        self.V = (R.B.v0[self.src] * self.bw[..., None]).sum(1)
        self.F = Fields(R)
        f = self.F
        def lo(a):
            return (a[self.src] * self.bw).sum(1)
        self.f = {k: lo(a) for k, a in f.all.items()}
        main = self.src[np.arange(len(self.src)), self.bw.argmax(1)]
        self.reg = f.reg[main]
        # arm / leg: no blending across the torso boundary (they jump there)
        self.f["arm"] = f.arm[main]; self.f["leg"] = f.leg[main]
        self.N = bodymod.vertex_normals(self.V, self.T)


def clip(V, T, CUV, fval):
    """Keep the part of the triangle mesh where fval > 0, cutting triangles along fval = 0.
    CUV: (T,3,2) corner uvs. Returns V2, T2, CUV2, origin (for each new vertex: (i, j, t))."""
    newv = {}
    outV = list(V)
    orig = [(i, i, 0.0) for i in range(len(V))]
    def edge(a, b):
        k = (min(a, b), max(a, b))
        if k not in newv:
            fa, fb = fval[a], fval[b]
            t = fa / (fa - fb)
            outV.append(V[a] + (V[b] - V[a]) * t)
            orig.append((a, b, t))
            newv[k] = len(outV) - 1
        return newv[k]
    T2 = []; U2 = []
    for ti, (tri, uv) in enumerate(zip(T, CUV)):
        s = fval[tri] > 0
        n = int(s.sum())
        if n == 3:
            T2.append(list(tri)); U2.append(list(uv)); continue
        if n == 0:
            continue
        # rotate so the odd one is first
        odd = int(np.nonzero(s if n == 1 else ~s)[0][0])
        idx = [(odd + k) % 3 for k in range(3)]
        a, b, c = tri[idx]; ua, ub, uc = uv[idx]
        fa, fb, fc = fval[[a, b, c]]
        tab = fa / (fa - fb); tac = fa / (fa - fc)
        pab, pac = edge(a, b), edge(a, c)
        uab = ua + (ub - ua) * tab; uac = ua + (uc - ua) * tac
        if n == 1:          # only a is kept
            T2.append([a, pab, pac]); U2.append([ua, uab, uac])
        else:               # a is dropped: keep the quad b c pac pab
            T2.append([pab, b, c]); U2.append([uab, ub, uc])
            T2.append([pab, c, pac]); U2.append([uab, uc, uac])
    T2 = np.array(T2, np.int64); U2 = np.array(U2)
    used = np.unique(T2)
    remap = -np.ones(len(outV), np.int64); remap[used] = np.arange(len(used))
    V2 = np.array(outV)[used]
    return V2, remap[T2], U2, [orig[i] for i in used]


def boundary_loops(T):
    from collections import defaultdict
    cnt = defaultdict(int); dirn = {}
    for a, b, c in T:
        for x, y in ((a, b), (b, c), (c, a)):
            k = (min(x, y), max(x, y)); cnt[k] += 1; dirn[k] = (x, y)
    edges = [dirn[k] for k, c in cnt.items() if c == 1]
    return edges


def smooth(V, T, keep_mask=None, it=4, lam=0.5):
    from collections import defaultdict
    nb = defaultdict(set)
    for a, b, c in T:
        nb[a] |= {b, c}; nb[b] |= {a, c}; nb[c] |= {a, b}
    V = V.copy()
    idx = np.array(sorted(nb)); lists = [np.array(sorted(nb[i])) for i in idx]
    for _ in range(it):
        avg = np.array([V[l].mean(0) for l in lists])
        m = np.ones(len(idx), bool) if keep_mask is None else ~keep_mask[idx]
        V[idx[m]] = V[idx[m]] * (1 - lam) + avg[m] * lam
    return V


class Builder:
    def __init__(self, sex):
        self.sex = sex
        self.Sfine = Source(sex, "lo")       # base layer: the game skin itself
        self.Scoarse = Source(sex, "lo2")    # everything else: a coarser cut of the same skin
        self.S = self.Scoarse
        self.R = self.S.R
        self.Fl = self.S.F

    # ---- the surface pipeline
    def surface(self, keep, layer, ease=None, drape=True, legs=None, lip=True, extra=None, smooth_it=3, fine=None):
        S = self.Sfine if (fine if fine is not None else layer <= 1) else self.Scoarse
        fv = keep(S.f, self.Fl)
        V, T, CUV, orig = clip(S.V, S.T, S.luv, fv)
        oi = np.array([o[0] for o in orig]); oj = np.array([o[1] for o in orig]); ot = np.array([o[2] for o in orig])
        N = S.N[oi] * (1 - ot[:, None]) + S.N[oj] * ot[:, None]
        N /= np.linalg.norm(N, axis=1, keepdims=True)
        F = {k: a[oi] * (1 - ot) + a[oj] * ot for k, a in S.f.items()}
        F["arm"] = np.where(ot < 0.5, S.f["arm"][oi], S.f["arm"][oj]); F["leg"] = np.where(ot < 0.5, S.f["leg"][oi], S.f["leg"][oj])
        reg = np.where(ot < 0.5, S.reg[oi], S.reg[oj])
        gap = GAP[layer] + (ease(F, self.Fl) if ease else 0.0)
        skin = V.copy()
        P = V + N * np.asarray(gap).reshape(-1, 1) if np.ndim(gap) else V + N * gap
        if drape:
            P = self.drape(P, F, reg)
        if legs:
            P = self.leg_profile(P, F, reg, legs)
        if extra:
            P = extra(P, F, N, self.Fl)
        bnd = np.zeros(len(P), bool)
        for a, b in boundary_loops(T):
            bnd[a] = bnd[b] = True
        P = smooth(P, T, keep_mask=bnd, it=smooth_it, lam=0.4)      # hems stay on their cut lines
        P = self.push_out(P, skin, N, GAP[layer] * 0.8)
        return P, T, CUV, F, reg, N

    def drape(self, P, F, reg):
        """fronts (and the back of skirts / long tops) hang straight below their highest bulge"""
        J = self.Fl.J
        out = P.copy()
        torso = np.isin(reg, ["chest_f", "belly_f", "pelvis_f", "chest_b", "belly_b", "pelvis_b", "crotch"])
        top = self.Fl.chest + 0.03
        for sgn in (1, -1):
            sel = np.nonzero(torso & (np.sign(F["front"]) == sgn) & (P[:, 1] < top))[0]
            if not len(sel):
                continue
            xb = np.round(P[sel, 0] / 0.025).astype(int)
            for b in np.unique(xb):
                ids = sel[xb == b]
                ids = ids[np.argsort(-P[ids, 1])]
                best = -1e9; ybest = None
                for i in ids:
                    z = P[i, 2] * sgn
                    if ybest is not None:
                        hang = best - 0.12 * (ybest - P[i, 1])     # hangs nearly straight (12 % inward)
                        if z < hang:
                            out[i, 2] = hang * sgn
                            continue
                    best, ybest = z, P[i, 1]
        return out

    def leg_profile(self, P, F, reg, mode):
        """trouser legs below the knee: at least the knee's radius (straight) or flaring (wide)."""
        J = self.Fl.J
        out = P.copy()
        for s, sx in (("Left", 1), ("Right", -1)):
            k = J["mixamorig_%sLeg" % s]; a = J["mixamorig_%sFoot" % s]
            axis = (a - k) / np.linalg.norm(a - k)
            sel = np.nonzero((P[:, 0] * sx > 0) & (F["leg"] > 0.0))[0]
            if not len(sel):
                continue
            d = P[sel] - k
            along = d @ axis
            rad_v = d - along[:, None] * axis
            r = np.linalg.norm(rad_v, axis=1)
            near_knee = np.abs(F["leg"][sel] - 0.5) < 0.04
            rk = np.percentile(r[near_knee], 80) if near_knee.any() else 0.06
            t = F["leg"][sel]
            if mode == "straight":
                target = np.where(t > 0.5, rk, 0)
            elif mode == "wide":
                target = np.where(t > 0.35, rk + 0.012 + np.clip(t - 0.35, 0, 1) * 0.16, 0)
            elif mode == "loose":
                target = np.where(t > 0.1, rk + 0.02, 0)
            else:
                target = np.zeros_like(r)
            grow = np.maximum(target - r, 0)
            out[sel] = P[sel] + rad_v / np.maximum(r[:, None], 1e-6) * grow[:, None]
        return out

    def push_out(self, P, skin, N, minc):
        """no vertex closer to its own skin point than minc (after smoothing)"""
        d = ((P - skin) * N).sum(1)
        low = d < minc
        P = P.copy()
        P[low] += N[low] * (minc - d[low])[:, None]
        return P

    def hem(self, P, T, CUV, N, depth):
        """fold open edges back toward the skin by `depth` (a thin lip, same material: trim)"""
        edges = boundary_loops(T)
        if not edges:
            return P, T, CUV, np.zeros(len(T), bool), N
        vs = sorted({v for e in edges for v in e})
        newi = {v: len(P) + i for i, v in enumerate(vs)}
        P2 = np.concatenate([P, P[vs] - N[vs] * depth])
        add = []
        uvs = []
        cu = {}
        for t, uv in zip(T, CUV):
            for k in range(3):
                cu[t[k]] = uv[k]
        for a, b in edges:
            add.append([b, a, newi[a]]); add.append([b, newi[a], newi[b]])
            ua, ub = cu[a], cu[b]
            uvs.append([ub, ua, ua + [0, 0.004]]); uvs.append([ub, ua + [0, 0.004], ub + [0, 0.004]])
        T2 = np.concatenate([T, np.array(add)])
        C2 = np.concatenate([CUV, np.array(uvs)])
        lipmask = np.zeros(len(T2), bool); lipmask[len(T):] = True
        N2 = np.concatenate([N, N[vs]])
        return P2, T2, C2, lipmask, N2

    def finish(self, pid, label, slot, layer, parts, mats, extra_meta=None, budget=None, follow=None):
        """decimate each part to the budget share, split uvs, bind, write"""
        import decimator
        out = []
        tot = sum(len(p[1]) for p in parts)
        for name, P, T, CUV, matmask in parts:
            # no decimation after cutting (it chews hem lines): outer pieces are cut from the
            # coarser skin instead; the catalogue's 'tris' is the budget they are checked against
            # split by material slot
            mm = np.asarray(matmask)
            for slot_name in mats:
                sel = mm == list(mats).index(slot_name)
                if not sel.any():
                    continue
                v, t, uv = split_uv(P, T[sel], CUV[sel])
                uv = uv * float((mats[slot_name].get("extras") or {}).get("uv_scale", 1.0))
                out.append(Part("%s_%s" % (name, slot_name), v, t, uv, slot_name, follow=follow))
        meta = {"slot": slot, "layer": layer, "label": label}
        if extra_meta:
            meta.update(extra_meta)
        meta["hides"] = self.covered(out)
        meta["budget"] = budget
        n = sum(len(p.t) for p in out)
        if budget and n > budget * 1.15:
            print("OVER BUDGET", pid, n, "tris; budget", budget)
        if layer >= 1:
            meta["fit_over"] = "fit_over"
        return write_piece(self.sex, pid, out, mats, meta, fit_over=(layer >= 1), resolve=GAP.get(layer, 0.004) * 0.6)

    def covered(self, parts):
        """regions fully under this piece (every skin vertex of the region within 3 cm of it)"""
        from mathutils.kdtree import KDTree
        P = np.concatenate([p.v for p in parts])
        kd = KDTree(len(P))
        for i, p in enumerate(P):
            kd.insert(p.tolist(), i)
        kd.balance()
        R = self.R
        names = bodymod.REGIONS
        out = []
        for ri, rn in enumerate(names):
            ids = np.nonzero(R.reg[:len(R.v)] == ri)[0]
            if not len(ids):
                continue
            far = 0
            for i in ids[::3]:
                if kd.find(R.v[i].tolist())[2] > 0.03:
                    far += 1
                    if far > max(2, len(ids) // 300):
                        break
            if far <= max(2, len(ids) // 300):
                out.append(rn)
        return out


def split_uv(P, T, CUV):
    key = np.concatenate([T.reshape(-1, 1).astype(float), np.round(CUV.reshape(-1, 2) * 4096)], 1)
    uniq, first, inv = np.unique(key, axis=0, return_index=True, return_inverse=True)
    vi = uniq[:, 0].astype(np.int64)
    uv = CUV.reshape(-1, 2)[first].copy()
    uv[:, 1] = 1 - uv[:, 1]
    return P[vi], inv.ravel().reshape(-1, 3), uv


# ---------------------------------------------------------------- field helpers (signed, metres)
def above(F, y):
    return F["y"] - y


def below(F, y):
    return y - F["y"]


def sleeve(F, L):
    return (L - F["arm"]) * 0.6


def legcut(F, L):
    return (L - F["leg"]) * 0.8


def legline(F, L, y_out, y_in=None, p=1.6):
    """leg openings of briefs and swimwear: keep above a line rising from the crotch (inner) to
    y_out at the side of the hip"""
    y_in = (L.crotch - 0.01) if y_in is None else y_in
    k = np.clip(np.abs(F["x"]) / (L.hip_w * 0.95), 0, 1) ** p
    line = y_in + (y_out - y_in) * k
    return F["y"] - line


def neck(F, L, front, back, vdepth=0.0, vwidth=40.0):
    az = np.radians(F["az"])
    w = ((1 + np.cos(az)) / 2) ** 2
    drop = back + (front - back) * w + vdepth * np.clip(1 - np.abs(F["az"]) / vwidth, 0, 1)
    return (L.neck_base - drop) - F["y"]


def straps(F, L, x=0.095, w=0.018, lo=None):
    lo = L.chest if lo is None else lo
    d = np.minimum(np.abs(F["x"] - x), np.abs(F["x"] + x))
    return np.where((F["y"] > lo) & (np.abs(F["arm"]) < 0.5), w / 2 - d, -1)


def U(*fs):
    return np.maximum.reduce(fs)


def I(*fs):
    return np.minimum.reduce(fs)


def opening_front(F, half):
    """open front (shirts worn open): drop a strip |x| < half in front"""
    return np.where(F["front"] > 0, np.abs(F["x"]) - half, 1)


# ---------------------------------------------------------------- the catalogue
def catalogue(L, sex):
    """(id, label, slot, layer, sexes, keep, options). L = Fields (landmarks)."""
    c, w, cr, nb = L.chest, L.waist, L.crotch, L.neck_base
    h = L.hips_joint          # tops' hems are measured from the hip joints
    r = L.rise
    F_ = "female"; M_ = "male"; B_ = ("female", "male")
    C = []
    def add(pid, label, slot, layer, sexes, keep, **o):
        C.append((pid, label, slot, layer, sexes if isinstance(sexes, tuple) else (sexes,), keep, o))
    # ---- no base layer (B-FIX, Steven, Nov 2, final): every character is always clothed, the body
    # itself carries a painted opaque base layer (tex.py) and a flattened chest / groin (flatten.py).
    # Underwear, lingerie and swimwear pieces are not made for the live game.
    # ---- tops (layer 2; flannel / cardigan are outerwear, 3)
    add("top_tee", "T-shirt", "top", 2, B_, lambda F, L: I(neck(F, L, 0.025, 0.004), sleeve(F, 0.23), above(F, h - 0.045)),
        tex="knit", tris=2000, default="#ffffff", ease="top", shirt_words=True)
    add("top_polo", "Polo shirt", "top", 2, B_, lambda F, L: I(neck(F, L, 0.015, 0.0), sleeve(F, 0.2), above(F, h - 0.05)),
        tex="pique", tris=2100, default="#1f4e79", ease="top", collar=0.03, placket=(0.012, c - 0.02))
    add("top_buttondown", "Button-down shirt", "top", 2, B_, lambda F, L: I(neck(F, L, 0.012, 0.0), sleeve(F, 0.98), above(F, h - 0.07)),
        tex="oxford", tris=2500, default="#e8eef5", ease="top", collar=0.032, placket=(0.012, h - 0.07))
    add("top_flannel", "Flannel (open, over a tee)", "top", 3, B_, lambda F, L: I(neck(F, L, 0.03, 0.0), sleeve(F, 0.97), above(F, h - 0.085), opening_front(F, 0.035)),
        tex="plaid", tris=2500, default="#8c2a22", ease="outer", collar=0.035, drape_open=True)
    add("top_babytee", "Baby tee", "top", 2, F_, lambda F, L: I(neck(F, L, 0.03, 0.006), sleeve(F, 0.12), above(F, w + 0.015)),
        tex="knit", tris=2100, default="#f4c6d0", ease="tight", shirt_words=True)
    add("top_tank", "Tank top", "top", 2, B_, lambda F, L: U(I(neck(F, L, 0.10, 0.06), sleeve(F, -0.03), above(F, h - 0.035)), I(straps(F, L, 0.085, 0.045), above(F, h))),
        tex="rib", tris=2200, default="#2b2b2b", ease="top")
    add("top_sweatshirt", "Sweatshirt", "top", 2, B_, lambda F, L: I(neck(F, L, 0.018, 0.004), sleeve(F, 0.985), above(F, h - 0.07)),
        tex="fleece", tris=2500, default="#7f8a99", ease="sweat", cuffs=0.05, waistband=0.05)
    add("top_cardigan", "Cardigan", "top", 3, B_, lambda F, L: I(neck(F, L, 0.03, 0.0, vdepth=0.16, vwidth=28), sleeve(F, 0.96), above(F, h - 0.07)),
        tex="cable", tris=2500, default="#6b4f3a", ease="outer", cuffs=0.04, waistband=0.04, placket=(0.014, h - 0.07), buttons=5)
    # ---- bottoms (layer 2)
    add("bot_jeans", "Straight jeans", "bottom", 2, B_, lambda F, L: I(below(F, r(0.5)), legcut(F, 0.99)),
        tex="denim", tris=2400, default="#4a6a96", legs="straight", waistband=0.035, ease="pants")
    add("bot_widejeans", "Wide-leg jeans", "bottom", 2, B_, lambda F, L: I(below(F, r(0.75)), legcut(F, 1.0)),
        tex="denim", tris=2400, default="#7d97bd", legs="wide", waistband=0.035, ease="pants")
    add("bot_slacks", "Slacks", "bottom", 2, B_, lambda F, L: I(below(F, r(0.8)), legcut(F, 0.99)),
        tex="twill", tris=2200, default="#2e3238", legs="straight", waistband=0.035, ease="pants")
    add("bot_khakis", "Khakis", "bottom", 2, B_, lambda F, L: I(below(F, r(0.6)), legcut(F, 0.99)),
        tex="twill", tris=2200, default="#c2ab84", legs="straight", waistband=0.035, ease="pants")
    add("bot_longshorts", "Long shorts (jams / cargo)", "bottom", 2, B_, lambda F, L: I(below(F, r(0.55)), legcut(F, 0.56)),
        tex="woven", tris=1600, default="#3d7a5a", legs="loose", waistband=0.035, ease="pants", patterns=True)
    add("bot_shortshorts", "Short shorts", "bottom", 2, B_, lambda F, L: I(below(F, r(0.95)), legcut(F, 0.1)),
        tex="denim", tris=1100, default="#9db3d3", waistband=0.03, ease="tight")
    add("bot_skirt", "Skirt (knee)", "bottom", 2, F_, None, kind="skirt", hem=0.48, flare=0.10, tex="twill", tris=1200, default="#3b3f5c")
    add("bot_overalls", "Overalls", "bottom", 2, B_,
        lambda F, L: U(I(below(F, r(0.6)), legcut(F, 0.99)),
                       I(np.where(F["front"] > 0, 0.12 - np.abs(F["x"]), -1), below(F, c + 0.06), above(F, w - 0.1)),
                       straps(F, L, 0.075, 0.035, lo=c + 0.02)),
        tex="denim", tris=2800, default="#4a6a96", legs="straight", ease="pants", buckles=True)
    # ---- full body
    add("full_football", "Football uniform", "full", 2, B_, None, kind="multi",
        parts=[("jersey", lambda F, L: I(neck(F, L, 0.04, 0.01, vdepth=0.03), sleeve(F, 0.24), above(F, h - 0.06)), "mesh", "#7a1f2b", "pads"),
               ("pants", lambda F, L: I(below(F, r(0.6)), legcut(F, 0.53)), "twill", "#e9e4d6", None),
               ("socks", lambda F, L: I(above(F, -1), legcut(F, 0.97), -legcut(F, 0.5)), "rib", "#7a1f2b", None)], tris=4200)
    add("full_cheer", "Cheerleader outfit", "full", 2, F_, None, kind="multi",
        parts=[("shell", lambda F, L: I(neck(F, L, 0.07, 0.02, vdepth=0.05), sleeve(F, -0.03), above(F, w + 0.005)), "knit", "#1d3c78", None),
               ("skirt", "skirt:0.24:0.10:pleats", "twill", "#1d3c78", None)], tris=2800)
    add("full_storevest", "Store uniform (vest + name tag)", "outer", 3, B_,
        lambda F, L: I(neck(F, L, 0.05, 0.0, vdepth=0.15, vwidth=30), sleeve(F, -0.025), above(F, h - 0.045), opening_front(F, 0.005)),
        tex="twill", tris=1700, default="#b8202a", ease="outer", nametag=True, buttons=4)
    add("full_storeapron", "Store uniform (apron + name tag)", "outer", 3, B_, None, kind="apron", bib=True, tex="canvas", tris=900, default="#1f5a3a", nametag=True)
    add("full_waitress", "Waitress uniform (dress + apron)", "full", 2, F_, None, kind="multi",
        parts=[("dress", lambda F, L: I(neck(F, L, 0.03, 0.005), sleeve(F, 0.15), above(F, w - 0.1)), "oxford", "#7fa7c9", "collar"),
               ("skirt", "skirt:0.42:0.07:", "oxford", "#7fa7c9", None),
               ("apron", "apron:half", "canvas", "#f4f2ee", None)], tris=3600, nametag=True)
    add("full_coveralls", "Work coveralls", "full", 2, B_,
        lambda F, L: I(neck(F, L, 0.03, 0.0), sleeve(F, 0.97), legcut(F, 0.99)),
        tex="twill", tris=3400, default="#3e4b5a", legs="straight", ease="sweat", collar=0.03, placket=(0.012, cr))
    # ---- shoes (layer 4), extras (layer 5)
    for sid, lab, d in (("sneakers", "Sneakers", "#f4f4f2"), ("boots", "Boots", "#5a3b24"), ("sandals", "Sandals", "#7a5a3a"), ("dressshoes", "Dress shoes", "#1c1a19")):
        add("shoe_" + sid, lab, "shoes", 4, B_, None, kind="shoe", style=sid, default=d, tris=1400)
    add("x_cap_fwd", "Cap (forward)", "hat", 5, B_, None, kind="cap", back=False, default="#22325a", tris=700)
    add("x_cap_back", "Cap (backward)", "hat", 5, B_, None, kind="cap", back=True, default="#22325a", tris=700)
    add("x_glasses", "Glasses", "glasses", 5, B_, None, kind="glasses", default="#2a2522", tris=700)
    add("x_watch", "Watch", "watch", 5, B_, None, kind="watch", default="#2a2a2a", tris=300)
    return C


EASE = {
    "top": lambda F, L: 0.002 + 0.007 * np.clip((L.chest - F["y"]) / 0.25, 0, 1),
    "tight": lambda F, L: 0.0,
    "sweat": lambda F, L: 0.010 + 0.012 * np.clip((L.chest - F["y"]) / 0.3, 0, 1),
    "outer": lambda F, L: 0.006 + 0.010 * np.clip((L.chest - F["y"]) / 0.3, 0, 1),
    "pants": lambda F, L: 0.002 + 0.006 * np.clip(F["leg"], 0, 1),
    "boxers": lambda F, L: 0.004 + 0.02 * np.clip(F["leg"] / 0.2, 0, 1),
}


def build_surface(B, pid, label, slot, layer, keep, o):
    L = B.Fl
    gap_layer = o.get("layer_gap", layer)
    if slot in ("bottom", "base_bottom"):
        k0 = keep
        keep = lambda F, L, k0=k0: I(k0(F, L), sleeve(F, -0.05))      # never the hands (they hang at hip height)
    P, T, CUV, F, reg, N = B.surface(keep, gap_layer, fine=(layer <= 1 and not o.get("coarse")), ease=EASE.get(o.get("ease")), drape=layer >= 1 and slot in ("top", "outer", "full", "base_top") and not o.get("tight"),
                                     legs=o.get("legs"))
    if o.get("pads"):
        pass
    # material regions: main 0, trim 1 (cuffs, waistband, collar, hems), accent 2 (placket, buttons, tag)
    tri_f = {k: a[T].mean(1) for k, a in F.items()}
    mat = np.zeros(len(T), np.int64)
    if o.get("waistband"):
        top = P[:, 1].max()
        mat[(P[T][:, :, 1].mean(1) > top - o["waistband"]) & (tri_f["leg"] < 0.05)] = 1
    if o.get("cuffs"):
        mat[tri_f["arm"] > 0.985 - o["cuffs"] * 2] = 1
    if o.get("placket"):
        wdt, ylo = o["placket"]
        mat[(np.abs(tri_f["x"]) < wdt) & (tri_f["front"] > 0) & (tri_f["y"] > ylo)] = 2
    P, T, CUV, lip, N2 = B.hem(P, T, CUV, N, GAP[gap_layer] * 0.75)
    mat = np.concatenate([mat, np.ones(lip.sum(), np.int64)])
    parts = [("cloth", P, T, CUV, mat)]
    extra_parts = []
    if o.get("collar"):
        extra_parts.append(collar(B, P, T, N2, o["collar"], layer))
    if o.get("nametag"):
        extra_parts.append(nametag(B, layer))
    if o.get("buttons"):
        extra_parts.append(buttons(B, o["buttons"], layer, o.get("placket", (0, L.hip))[1]))
    if o.get("buckles"):
        extra_parts.append(buckles(B, layer))
    mats = fabric.materials(pid, o.get("tex", "knit"), o.get("default", "#ffffff"))
    for ep in extra_parts:
        parts.append(ep)
    meta = {"default_color": o.get("default"), "texture": o.get("tex")}
    for k in ("counts_as", "shirt_words", "patterns"):
        if o.get(k):
            meta[k] = o[k]
    if o.get("shirt_words"):
        meta["shirt_words_at"] = {"bone": "mixamorig_Spine2", "height": round(float(L.chest + 0.05), 3)}
    return B.finish(pid, label, slot, layer, parts, mats, meta, budget=o.get("tris"), follow=None)


def collar(B, P, T, N, h, layer):
    """a turned-down collar: the neckline loop raised h along the neck, then folded out and down"""
    L = B.Fl
    edges = boundary_loops(T)
    vs = sorted({v for e in edges for v in e if P[v, 1] > L.chest + 0.05 and abs(P[v, 0]) < 0.12})
    if len(vs) < 6:
        return ("collar", np.zeros((3, 3)), np.zeros((1, 3), np.int64), np.zeros((1, 3, 2)), np.zeros(1, np.int64))
    ring = order_ring(P, vs, B.Fl.J["mixamorig_Neck"])
    rp = P[ring]
    ctr = np.array([B.Fl.J["mixamorig_Neck"][0], 0, B.Fl.J["mixamorig_Neck"][2]])
    out = (rp - ctr) * [1, 0, 1]
    out /= np.linalg.norm(out, axis=1, keepdims=True)
    rows = [rp, rp + [0, h * 0.55, 0] + out * 0.004, rp + [0, h * 0.5, 0] + out * 0.014, rp + out * (0.02 + h * 0.2) - [0, h * 0.25, 0]]
    V = np.concatenate(rows)
    n = len(ring)
    T2 = grid_tris(4, n)
    T2 = pieces.fix_winding(V, T2, lambda cc: np.stack([np.full(len(cc), ctr[0]), cc[:, 1], np.full(len(cc), ctr[2])], 1))
    CUV = np.zeros((len(T2), 3, 2)); CUV[..., 0] = (T2 % n) / n * 4; CUV[..., 1] = (T2 // n) / 4 * 0.2
    return ("collar", V, T2, CUV, np.ones(len(T2), np.int64))


def order_ring(P, vs, centre):
    a = np.arctan2(P[vs, 0] - centre[0], P[vs, 2] - centre[2])
    return [vs[i] for i in np.argsort(a)]


def box(c, size, rot_y=0.0):
    sx, sy, sz = np.asarray(size) / 2
    V = np.array([[x, y, z] for x in (-sx, sx) for y in (-sy, sy) for z in (-sz, sz)])
    T = np.array([[0, 1, 3], [0, 3, 2], [4, 6, 7], [4, 7, 5], [0, 4, 5], [0, 5, 1], [2, 3, 7], [2, 7, 6], [0, 2, 6], [0, 6, 4], [1, 5, 7], [1, 7, 3]])
    return V + c, T


def on_front(B, x, y, layer, out=0.0):
    """a point on the front of the torso at (x, y), offset like the given layer"""
    R = B.R
    o = np.array([x, y, 0.5])
    from mathutils import Vector
    hit = R_bvh(B).ray_cast(Vector(o), Vector((0, 0, -1)), 1.0)
    z = hit[0][2] if hit[0] else 0.12
    return np.array([x, y, z + GAP[layer] + 0.004 + out])


def R_bvh_regions(B, regions):
    """a BVH of the skin triangles in some regions only (skirts / aprons must not see the hands)"""
    key = tuple(regions)
    B.__dict__.setdefault("_bvhr", {})
    if key not in B._bvhr:
        from mathutils.bvhtree import BVHTree
        ids = [bodymod.REGIONS.index(r) for r in regions]
        ok = np.isin(B.R.reg[:len(B.R.v)], ids)
        T = B.R.tris[ok[B.R.tris].all(1)]
        B._bvhr[key] = BVHTree.FromPolygons(B.R.B.v0.tolist(), T.tolist(), all_triangles=True)
    return B._bvhr[key]


def R_bvh(B):
    if not hasattr(B, "_bvh"):
        from mathutils.bvhtree import BVHTree
        B._bvh = BVHTree.FromPolygons(B.R.B.v0.tolist(), B.R.tris.tolist(), all_triangles=True)
    return B._bvh


def nametag(B, layer):
    L = B.Fl
    p = on_front(B, 0.085, L.chest + 0.045, layer, 0.004)
    V, T = box(p, [0.07, 0.022, 0.004])
    CUV = np.zeros((len(T), 3, 2)) + 0.5
    return ("tag", V, T, CUV, np.full(len(T), 2))


def buttons(B, n, layer, ylo):
    L = B.Fl
    Vs, Ts = [], []
    top = L.chest + 0.02
    for k in range(n):
        y = top - (top - ylo - 0.04) * k / max(n - 1, 1)
        p = on_front(B, 0.0, y, layer, 0.003)
        v, t = box(p, [0.011, 0.011, 0.003])
        Ts.append(t + sum(len(x) for x in Vs)); Vs.append(v)
    V = np.concatenate(Vs); T = np.concatenate(Ts)
    return ("buttons", V, T, np.zeros((len(T), 3, 2)) + 0.5, np.full(len(T), 2))


def buckles(B, layer):
    L = B.Fl
    Vs, Ts = [], []
    for sx in (1, -1):
        p = on_front(B, sx * 0.075, L.chest + 0.04, layer, 0.004)
        v, t = box(p, [0.03, 0.025, 0.004])
        Ts.append(t + sum(len(x) for x in Vs)); Vs.append(v)
    V = np.concatenate(Vs); T = np.concatenate(Ts)
    return ("buckles", V, T, np.zeros((len(T), 3, 2)) + 0.5, np.full(len(T), 2))


if __name__ == "__main__":
    import loose
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    sexes = [a for a in argv if a in ("female", "male")] or ["female", "male"]
    want = [a for a in argv if a not in ("female", "male")]
    fabric.textures()
    for s in sexes:
        B = Builder(s)
        for pid, label, slot, layer, sx, keep, o in catalogue(B.Fl, s):
            if s not in sx or (want and pid not in want and not any(pid.startswith(w) for w in want)):
                continue
            kind = o.get("kind", "surface")
            try:
                if kind == "surface":
                    build_surface(B, pid + "_" + s, label, slot, layer, keep, o)
                else:
                    loose.build(B, kind, pid + "_" + s, label, slot, layer, o)
            except Exception as ex:
                import traceback; traceback.print_exc()
                print("FAILED", pid, s, ex)
