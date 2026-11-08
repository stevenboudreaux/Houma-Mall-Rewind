"""Garments, built on the person's own body (no fitting in the game).

Shell garments (shirt, polo, tee, trousers, belt, shoes) are the skin `Surf` of the LOD, cut along a
field f (> 0 = covered, metres) so hems and necklines are clean lines, offset outward along the skin
normal by the garment's gap, smoothed, pushed back out to the gap, and closed with a hem lip toward
the skin (no see-through gap at grazing views). The skin under them is cut away (`cut_skin`), leaving
`MARGIN` of skin inside every hem.

Generated pieces (collar, tie, name tag, visor, cap) are small meshes placed from the body's landmarks
and skinned from the nearest garment / bone.

Every part comes back as a dict: name, pos (n,3), tri (m,3), cuv (m,3,2) in its atlas cell (image
coordinates of the 1024 clothes atlas), cell id, J (n,4) joints, Wt (n,4) weights, kind, colour.
"""
import math

import numpy as np

import topo
from topo import Surf, clip, vertex_normals, smooth, boundary_edges, loops

MARGIN = 0.025
# 1024 clothes atlas (image coordinates): shell garments map hm08's UV layout into a cell; the
# generated pieces get small cells of their own.
CELLS = {
    "top": (0.0, 0.0, 0.5, 0.75), "bottom": (0.5, 0.0, 0.5, 0.75), "suit": (0.0, 0.0, 1.0, 0.75),
    "shoes": (0.0, 0.75, 0.25, 0.25), "collar": (0.25, 0.75, 0.25, 0.125), "belt": (0.25, 0.875, 0.25, 0.0625),
    "tag": (0.25, 0.9375, 0.125, 0.0625), "tie": (0.5, 0.75, 0.25, 0.25), "headwear": (0.75, 0.75, 0.25, 0.25),
    "eye": (0.0, 0.0, 1.0, 1.0),
}


def cell_uv(cell, uv):
    x, y, w, h = CELLS[cell]
    return np.stack([x + uv[..., 0] * w, y + uv[..., 1] * h], -1)


class Ctx:
    """What every garment builder needs: the person, the LOD's skin surface and per-vertex semantics."""

    def __init__(self, P, S, coords, Wb, Nh):
        self.P, self.S, self.coords, self.Wb, self.Nh = P, S, coords, Wb, Nh
        self.J = P.J
        names = P.names
        def grp(*keys):
            m = np.zeros(len(names), bool)
            for i, n in enumerate(names):
                m[i] = any(k in n for k in keys)
            return m
        self.g_arm = grp("Arm", "Hand")      # Arm, ForeArm, Hand*
        self.g_leg = grp("UpLeg", "Leg", "Foot", "Toe")
        self.g_head = grp("Head", "eye.", "jaw")

    def sem(self, S):
        """Positions, normals and semantics on a surface."""
        p = S.ev(self.coords)
        n = S.ev(self.Nh); n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-9)
        W = S.ev(self.Wb)
        d = {"p": p, "n": n, "W": W,
             "arm": W[:, self.g_arm].sum(1), "leg": W[:, self.g_leg].sum(1), "head": W[:, self.g_head].sum(1)}
        d["t_arm"] = self.chain(p, "Arm", "ForeArm", "Hand")
        d["t_leg"] = self.chain(p, "UpLeg", "Leg", "Foot")
        return d

    def chain(self, p, a, b, c):
        """Distance along a limb (shoulder -> elbow -> wrist, hip -> knee -> ankle) of each point's
        projection, on the side of the body the point is on."""
        out = np.zeros(len(p))
        for side, sgn in (("Left", 1), ("Right", -1)):
            A = self.J["mixamorig_%s%s" % (side, a)]; B = self.J["mixamorig_%s%s" % (side, b)]
            C = self.J["mixamorig_%s%s" % (side, c)]
            m = (p[:, 0] * sgn) >= 0
            d1 = B - A; L1 = np.linalg.norm(d1); d1 /= L1
            d2 = C - B; d2 /= np.linalg.norm(d2)
            t1 = (p[m] - A) @ d1
            t2 = L1 + (p[m] - B) @ d2
            out[m] = np.where(t1 < L1, t1, t2)
        return out

    def limb_len(self, a, b, c):
        A = self.J["mixamorig_Left" + a]; B = self.J["mixamorig_Left" + b]; C = self.J["mixamorig_Left" + c]
        return np.linalg.norm(B - A), np.linalg.norm(B - A) + np.linalg.norm(C - B)


# ---- fields -----------------------------------------------------------------------------------
def neck_line(ctx, s, h0, drop, power=1.5, back_rise=0.0):
    """> 0 below a neckline: h0 above the neck joint at the back, `drop` lower at the front."""
    Jn = ctx.J["mixamorig_Neck"]; Jh = ctx.J["mixamorig_Head"]
    ax = (Jh - Jn) / np.linalg.norm(Jh - Jn)
    r = s["p"] - Jn
    h = r @ ax
    rh = r - np.outer(h, ax)
    c = rh[:, 2] / np.maximum(np.linalg.norm(rh, axis=1), 1e-9)
    line = h0 + back_rise * np.maximum(-c, 0) - drop * np.maximum(c, 0) ** power
    return line - h


def waist_line(ctx, s, above_hips, belly_drop=0.0):
    """> 0 below the waist: `above_hips` over the hip joint, lower at the front by belly_drop."""
    Jh = ctx.J["mixamorig_Hips"]
    r = s["p"] - Jh
    c = r[:, 2] / np.maximum(np.hypot(r[:, 0], r[:, 2]), 1e-9)
    return (Jh[1] + above_hips - belly_drop * np.maximum(c, 0) ** 2) - s["p"][:, 1]


def top_field(ctx, s, g):
    neck = g.get("neck", "collar")
    if neck == "collar":
        fn = neck_line(ctx, s, 0.012, 0.035)
    elif neck == "polo":
        fn = neck_line(ctx, s, 0.008, 0.035)
    else:                                       # crew
        fn = neck_line(ctx, s, -0.004, 0.045, power=1.2)
    upper, total = ctx.limb_len("Arm", "ForeArm", "Hand")
    if g.get("sleeve", "short") == "long":
        sl = total - 0.02
    else:
        sl = float(g.get("sleeve_len", 0.55)) * upper
    fs = np.where(s["arm"] > 0.4, sl - s["t_arm"], 1.0)
    if g.get("hem", "tucked") == "tucked":
        fh = -waist_line(ctx, s, -0.07)
    else:
        fh = -waist_line(ctx, s, float(g.get("hem_y", -0.13)))
    return np.minimum(np.minimum(fn, fs), fh)


def bottom_field(ctx, s, g):
    ft = waist_line(ctx, s, float(g.get("waist_y", 0.03)), float(g.get("belly_drop", 0.0)))
    ank = 0.5 * (ctx.J["mixamorig_LeftFoot"][1] + ctx.J["mixamorig_RightFoot"][1])
    fh = s["p"][:, 1] - (ank - 0.01)
    fa = np.where(s["arm"] > 0.3, -1.0, 1.0)
    return np.minimum(np.minimum(ft, fh), fa)


def belt_field(ctx, s, g, bottom):
    top = waist_line(ctx, s, float(bottom.get("waist_y", 0.03)) + 0.004, float(bottom.get("belly_drop", 0.0)))
    low = -waist_line(ctx, s, float(bottom.get("waist_y", 0.03)) - 0.036, float(bottom.get("belly_drop", 0.0)))
    fa = np.where(s["arm"] > 0.3, -1.0, 1.0)
    return np.minimum(np.minimum(top, low), fa)


def shoe_field(ctx, s, g):
    ank = 0.5 * (ctx.J["mixamorig_LeftFoot"][1] + ctx.J["mixamorig_RightFoot"][1])
    return np.where(s["leg"] > 0.3, (ank + float(g.get("top", 0.02))) - s["p"][:, 1], -1.0)


FIELDS = {"top": top_field, "bottom": bottom_field, "shoes": shoe_field}


# ---- shells -----------------------------------------------------------------------------------
def shell(ctx, f, gap, iters=4, cell="top", lip=True, extra=None, base_smooth=0, min_gap=None):
    """Cut ctx.S along f >= 0, offset by gap (array or float), smooth, push out, add the hem lip.
    base_smooth: smooth the skin first (shoes: toes merge into one shape); min_gap then guards the
    clearance over the real skin instead of the full gap."""
    G = clip(ctx.S, f)
    s = ctx.sem(G)
    gp = np.broadcast_to(np.asarray(gap, float), (len(G),)) if np.ndim(gap) == 0 else gap(s)
    if base_smooth:
        b = smooth(s["p"], G.tri, base_smooth, 0.6)
        nb = vertex_normals(b, G.tri)
        pos = b + nb * gp[:, None]
        gp = np.full(len(G), min_gap if min_gap is not None else 0.003)
    else:
        pos = s["p"] + s["n"] * gp[:, None]
    if extra is not None:
        pos = extra(s, pos)
    pos = smooth(pos, G.tri, iters, 0.5)
    d = ((pos - s["p"]) * s["n"]).sum(1)
    pos += s["n"] * np.maximum(gp - d, 0)[:, None]
    tri, cuv = G.tri, G.cuv
    if lip:
        pos, tri, cuv, G = hem_lip(G, s, pos, tri, cuv)
        s = ctx.sem(G)
    return {"surf": G, "pos": pos, "tri": tri, "cuv": cell_uv(cell, cuv), "W": s["W"], "cell": cell}


def hem_lip(G, s, pos, tri, cuv):
    """Fold every open edge back to the skin: a ring of new vertices just above the skin, joined
    to the hem by quads facing outward."""
    be = boundary_edges(tri)
    if len(be) == 0:
        return pos, tri, cuv, G
    vuv = np.zeros((len(G), 2))
    vuv[tri.ravel()] = cuv.reshape(-1, 2)
    bv = np.unique(be.ravel())
    m = len(G)
    newid = {int(v): m + i for i, v in enumerate(bv)}
    src = np.concatenate([G.src, G.src[bv]]); w = np.concatenate([G.w, G.w[bv]])
    inner = s["p"][bv] + s["n"][bv] * 0.0015
    pos = np.concatenate([pos, inner])
    T, C = [], []
    for a, b in be:
        a2, b2 = newid[int(a)], newid[int(b)]
        # boundary edge a->b as in its triangle; the lip goes b->a on the outside, toward the skin
        T += [[b, a, a2], [b, a2, b2]]
        ua, ub = vuv[a], vuv[b]
        C += [[ub, ua, ua], [ub, ua, ub]]
    G2 = Surf(src, w, np.concatenate([tri, np.array(T)]), np.concatenate([cuv, np.array(C)]))
    return pos, G2.tri, G2.cuv, G2


def straight_legs(ctx):
    """Trouser legs fall straight below the knee: each point at least the knee's radius from the
    knee-ankle axis."""
    def f(s, pos):
        for side, sgn in (("Left", 1), ("Right", -1)):
            K = ctx.J["mixamorig_%sLeg" % side]; A = ctx.J["mixamorig_%sFoot" % side]
            ax = (A - K) / np.linalg.norm(A - K)
            m = (s["p"][:, 0] * sgn > 0) & (s["leg"] > 0.3)
            r = pos[m] - K
            t = r @ ax
            radial = r - np.outer(t, ax)
            rl = np.linalg.norm(radial, axis=1)
            near = (np.abs(t) < 0.03)
            rk = np.percentile(rl[near], 70) if near.any() else rl.mean()
            below = t > 0
            want = np.where(below, np.maximum(rl, rk * (1 + 0.05 * t / 0.4)), rl)
            pos[m] = K + np.outer(t, ax) + radial / np.maximum(rl, 1e-9)[:, None] * want[:, None]
        return pos
    return f


def shoe_shape(ctx, lift):
    def f(s, pos):
        pos = pos.copy()
        sole = s["p"][:, 1] < lift + 0.012
        pos[sole, 1] = 0.0
        # toe box: a little longer and rounder
        fwd = s["p"][:, 2] > 0.03
        pos[fwd, 2] += 0.008
        return pos
    return f


def cut_skin(ctx, fields):
    """The skin with everything deeper than MARGIN under a garment removed."""
    s = ctx.sem(ctx.S)
    cover = np.full(len(ctx.S), -1.0)
    for f in fields:
        cover = np.maximum(cover, f(s) - MARGIN)
    return clip(ctx.S, -cover)


# ---- generated pieces ---------------------------------------------------------------------------
def nearest_weights(ctx, pts, ref_pos, ref_W):
    out = np.zeros((len(pts), ref_W.shape[1]))
    for i, p in enumerate(pts):
        d = np.linalg.norm(ref_pos - p, axis=1)
        k = np.argsort(d)[:4]
        wk = 1 / np.maximum(d[k], 1e-4)
        out[i] = (ref_W[k] * wk[:, None]).sum(0) / wk.sum()
    return out


def grid_tris(rows, cols, wrap=False):
    T = []
    cc = cols if wrap else cols - 1
    for r in range(rows - 1):
        for c in range(cc):
            a = r * cols + c; b = r * cols + (c + 1) % cols
            T += [[a, a + cols, b], [b, a + cols, b + cols]]
    return np.array(T, np.int64)


def grid_cuv(tri, uv):
    return uv[tri]


def collar(ctx, top, kind="dress"):
    """A collar from the shirt's neckline: a stand rising ~3 cm against the neck, then a fold going
    down and out over it to points at the front (dress shirt) or a flat knit fold (polo)."""
    pos = top["pos"]
    # the neckline = the boundary loop nearest the neck joint
    tri0 = top["tri"]
    Jn = ctx.J["mixamorig_Neck"]; Jh = ctx.J["mixamorig_Head"]
    ax = (Jh - Jn) / np.linalg.norm(Jh - Jn)
    be = boundary_edges(tri0)
    best = None
    for lp in loops(be):
        c = pos[lp].mean(0)
        d = np.linalg.norm(c - Jn)
        if len(lp) > 8 and (best is None or d < best[0]):
            best = (d, lp)
    lp = best[1]
    # the lip ring was appended after the hem: take hem vertices (outer) only
    ring = pos[lp]
    # order by azimuth, start at the front centre
    r = ring - Jn
    az = np.arctan2(r[:, 0], r[:, 2])
    o = np.argsort(az)
    ring = ring[o]
    az = az[o]
    # resample to an even count
    nseg = 32
    a_s = np.linspace(-math.pi, math.pi, nseg, endpoint=False) + math.pi / nseg
    def interp(a):
        aa = np.concatenate([az - 2 * math.pi, az, az + 2 * math.pi])
        rr = np.concatenate([ring, ring, ring])
        return np.stack([np.interp(a, aa, rr[:, k]) for k in range(3)], 1)
    base = interp(a_s)
    cen = Jn + ax * ((base - Jn) @ ax).mean()
    out_dir = base - cen - np.outer((base - cen) @ ax, ax)
    out_dir /= np.linalg.norm(out_dir, axis=1, keepdims=True)
    front = np.cos(a_s)            # 1 at the front centre (az = 0 is +Z)
    stand_h = 0.026 if kind == "dress" else 0.02
    fold_len = (0.034 + 0.022 * np.maximum(front, 0) ** 8) if kind == "dress" else (0.03 + 0.008 * np.maximum(front, 0) ** 4)
    # front gap: the collar opens at the very front (the tie's knot / the polo's placket)
    opening = 0.012 if kind == "dress" else 0.02
    rows = []
    rows.append(base - out_dir * 0.002)
    top_ring = base + ax * stand_h - out_dir * 0.004
    rows.append(top_ring)
    fold_top = top_ring + out_dir * 0.006 + ax * 0.003
    rows.append(fold_top)
    down = -ax * 0.8 + 0.6 * out_dir
    down /= np.linalg.norm(down, axis=1, keepdims=True)
    rows.append(fold_top + down * fold_len[:, None] * 0.55 + out_dir * 0.004)
    rows.append(fold_top + down * fold_len[:, None] + out_dir * 0.010)
    V = np.concatenate(rows)
    rcount = len(rows)
    # cut the front opening: drop the columns within `opening` of the front centre
    xs = base[:, 0]
    keep_col = ~((front > 0.8) & (np.abs(xs) < opening))
    T = []
    U = []
    for rr in range(rcount - 1):
        for c in range(nseg):
            c2 = (c + 1) % nseg
            if not (keep_col[c] and keep_col[c2]):
                continue
            a = rr * nseg + c; b = rr * nseg + c2
            T += [[a, b, a + nseg], [b, b + nseg, a + nseg]]
    T = np.array(T, np.int64)
    # make triangles face outward (away from the neck axis)
    fc = V[T].mean(1)
    fnrm = np.cross(V[T[:, 1]] - V[T[:, 0]], V[T[:, 2]] - V[T[:, 0]])
    rad = fc - Jn - np.outer((fc - Jn) @ ax, ax)
    # stand rows (0-1) face out; fold rows face out too
    flip = (fnrm * rad).sum(1) < 0
    T[flip] = T[flip][:, ::-1]
    # double-sided by duplicating with reversed winding, a hair inward (the fold's underside)
    uv = np.stack([np.tile((np.arange(nseg) + 0.5) / nseg, rcount), np.repeat(np.linspace(0.05, 0.95, rcount), nseg)], 1)
    Vb = V.copy()
    T2 = T[:, ::-1] + len(V)
    V = np.concatenate([V, Vb]); uv = np.concatenate([uv, uv])
    T = np.concatenate([T, T2])
    Wt = nearest_weights(ctx, V, pos, top["W"])
    return {"pos": V, "tri": T, "cuv": cell_uv("collar", uv[T]), "W": Wt, "cell": "collar"}


def raycast(V, T, o, d):
    """First hit (smallest t > 0) of the ray o + t d on triangles (V, T); None if missed."""
    a = V[T[:, 0]]; e1 = V[T[:, 1]] - a; e2 = V[T[:, 2]] - a
    pv = np.cross(d, e2)
    det = (e1 * pv).sum(1)
    ok = np.abs(det) > 1e-12
    inv = np.where(ok, 1 / np.where(ok, det, 1), 0)
    tv = o - a
    u = (tv * pv).sum(1) * inv
    qv = np.cross(tv, e1)
    v = (qv @ d) * inv
    t = (qv * e2).sum(1) * inv
    hit = ok & (u >= 0) & (v >= 0) & (u + v <= 1) & (t > 0)
    if not hit.any():
        return None
    k = np.nonzero(hit)[0][np.argmin(t[hit])]
    return o + d * t[k]


def front_point(top, y, x=0.0, band=None):
    """The front surface point of a garment shell at height y and lateral x (a ray from the front)."""
    p = raycast(top["pos"], top["tri"], np.array([x, y, 1.0]), np.array([0, 0, -1.0]))
    if p is None:
        raise SystemExit("cast: no garment surface at x=%.3f y=%.3f" % (x, y))
    return p


def tie(ctx, top, y_top, y_bot):
    """A necktie: a knot under the collar and a blade lying on the shirt, widening to a point."""
    n = 16
    ys = np.linspace(y_top - 0.03, y_bot, n)
    cols = 5
    V, U = [], []
    for i, y in enumerate(ys):
        t = i / (n - 1)
        wdt = 0.040 + 0.045 * t ** 0.8
        for j in range(cols):
            s = (j / (cols - 1)) * 2 - 1
            x = s * wdt / 2
            p = front_point(top, y, x).copy()
            p[2] += 0.004 + 0.003 * (1 - abs(s))   # slight crown
            V.append(p); U.append([0.05 + 0.9 * (s + 1) / 2, 0.15 + 0.8 * t])
    V = np.array(V); U = np.array(U)
    # the tip: a point below the last row
    tip = V[-cols:].mean(0); tip[1] -= 0.04; tip[2] -= 0.002
    V = np.concatenate([V, tip[None]]); U = np.concatenate([U, [[0.5, 0.98]]])
    T = grid_tris(n, cols)
    ti = len(V) - 1
    last = (n - 1) * cols
    for j in range(cols - 1):
        T = np.concatenate([T, [[last + j, ti, last + j + 1]]])
    # knot: a short tapered block at the collar
    kc = front_point(top, y_top - 0.01); kc[2] += 0.012
    kw0, kw1, kh, kd = 0.034, 0.024, 0.038, 0.014
    kv = []
    for yy, ww in ((0.012, kw0), (-kh + 0.012, kw1)):
        for xx in (-1, 1):
            for zz in (-kd / 2, kd / 2):
                kv.append(kc + np.array([xx * ww / 2, yy, zz]))
    kv = np.array(kv)
    kt = np.array([[0, 2, 1], [1, 2, 3], [4, 5, 6], [5, 7, 6], [1, 3, 5], [3, 7, 5], [0, 4, 2], [2, 4, 6],
                   [0, 1, 4], [1, 5, 4], [2, 6, 3], [3, 6, 7]]) + len(V)
    ku = np.array([[0.1, 0.02], [0.9, 0.02], [0.1, 0.12], [0.9, 0.12]] * 2)
    V = np.concatenate([V, kv]); U = np.concatenate([U, ku])
    T = orient_out(V, np.concatenate([T, kt]), None)
    Wt = nearest_weights(ctx, V, top["pos"], top["W"])
    return {"pos": V, "tri": T, "cuv": cell_uv("tie", U[T]), "W": Wt, "cell": "tie"}


def orient_out(V, T, centre):
    """Wind each triangle so its normal faces +Z-ish / outward from the body's axis."""
    fc = V[T].mean(1)
    fn = np.cross(V[T[:, 1]] - V[T[:, 0]], V[T[:, 2]] - V[T[:, 0]])
    out = fc.copy(); out[:, 1] = 0
    if centre is not None:
        out = fc - centre
    flip = (fn * out).sum(1) < 0
    T = T.copy(); T[flip] = T[flip][:, ::-1]
    return T


def box(c, size, xdir, ydir, zdir):
    sx, sy, sz = size
    V = []
    for xx in (-1, 1):
        for yy in (-1, 1):
            for zz in (-1, 1):
                V.append(c + xdir * xx * sx / 2 + ydir * yy * sy / 2 + zdir * zz * sz / 2)
    V = np.array(V)
    T = np.array([[0, 1, 3], [0, 3, 2], [4, 6, 7], [4, 7, 5], [0, 4, 5], [0, 5, 1], [2, 3, 7], [2, 7, 6],
                  [0, 2, 6], [0, 6, 4], [1, 5, 7], [1, 7, 3]])
    return V, T


def name_tag(ctx, top, side=1, w=0.075, h=0.022):
    """A blank name badge on the chest (no words, no logo)."""
    y = ctx.J["mixamorig_Spine2"][1] + 0.04
    x = side * 0.085
    p = front_point(top, y, x)
    # surface normal from nearby shirt points
    pos = top["pos"]
    m = np.linalg.norm(pos - p, axis=1) < 0.03
    q = pos[m] - pos[m].mean(0)
    _, _, vt = np.linalg.svd(q)
    nz = vt[2] * (1 if vt[2][2] > 0 else -1)
    xdir = np.cross([0, 1, 0], nz); xdir /= np.linalg.norm(xdir)
    ydir = np.cross(nz, xdir)
    V, T = box(p + nz * 0.003, (w, h, 0.003), xdir, ydir, nz)
    T = orient_out(V, T, p - nz * 0.05)
    uv = np.zeros((len(V), 2))
    uv[:, 0] = 0.1 + 0.8 * ((V - p) @ xdir / w + 0.5)
    uv[:, 1] = 0.1 + 0.8 * (0.5 - (V - p) @ ydir / h)
    Wt = nearest_weights(ctx, V, top["pos"], top["W"])
    return {"pos": V, "tri": T, "cuv": cell_uv("tag", uv[T]), "W": Wt, "cell": "tag"}


def head_frame(ctx):
    """Head centre (between the ears, a bit above eye level) and the skin points of the head."""
    s = ctx.sem(ctx.S)
    hm = s["head"] > 0.6
    hp = s["p"][hm]
    eyes = 0.5 * (ctx.J["eye.L"] + ctx.J["eye.R"])
    top = hp[:, 1].max()
    c = np.array([0.0, eyes[1] + 0.02, eyes[2] - 0.085])
    return c, hp, top


def radial_surface(hp, c, dirs, gap):
    """For each direction from c, the head's skin radius there (+ gap): nearest skin point by angle."""
    v = hp - c
    r = np.linalg.norm(v, axis=1)
    u = v / r[:, None]
    out = []
    for d in dirs:
        cs = u @ d
        k = np.argsort(-cs)[:6]
        out.append(c + d * (r[k].mean() + gap))
    return np.array(out)


def headwear(ctx, kind, colour):
    """A visor (band + brim) or a cap (crown + brim), rigid on the head bone."""
    c, hp, top = head_frame(ctx)
    hidx = ctx.P.names.index("mixamorig_Head")
    nseg = 40
    az = np.linspace(-math.pi, math.pi, nseg, endpoint=False)
    # band: a ring tilted down at the back, across the forehead ~3 cm above the brows
    eyes = 0.5 * (ctx.J["eye.L"] + ctx.J["eye.R"])
    V, U, T = [], [], []
    def ring(el_front, el_back, gap):
        dirs = []
        for a in az:
            cf = math.cos(a)
            el = el_back + (el_front - el_back) * (cf + 1) / 2
            d = np.array([math.sin(a) * math.cos(el), math.sin(el), math.cos(a) * math.cos(el)])
            dirs.append(d)
        return radial_surface(hp, c, np.array(dirs), gap)
    rows = []
    if kind == "visor":
        rows = [ring(0.28, 0.02, 0.010), ring(0.50, 0.22, 0.010)]
    else:
        els = [0.20, 0.45, 0.75, 1.05, 1.30]
        rows = [ring(e, e - 0.22, 0.012 + 0.004 * i) for i, e in enumerate(els)]
    for r in rows:
        V += list(r)
    nr = len(rows)
    T = list(grid_tris(nr, nseg, wrap=True))
    for i in range(nr):
        U += [[(j + 0.5) / nseg, 0.05 + 0.4 * i / max(nr - 1, 1)] for j in range(nseg)]
    if kind == "cap":
        apex = c + np.array([0, 1, 0.0]) * (np.linalg.norm(rows[-1] - c, axis=1).mean() * 0.98)
        apex[2] -= 0.01
        V.append(apex); U.append([0.5, 0.48])
        ai = len(V) - 1
        last = (nr - 1) * nseg
        for j in range(nseg):
            T.append([last + j, ai, last + (j + 1) % nseg])
    # brim: from the front of the lowest ring, out and slightly down
    base = rows[0]
    front = np.cos(az) > math.cos(math.radians(80))
    fi = np.nonzero(front)[0]
    fi = fi[np.argsort(az[fi])]
    brim_len = 0.075 if kind == "visor" else 0.07
    b0 = len(V)
    for j, k in enumerate(fi):
        p = base[k]
        d = p - c; d[1] = 0; d /= np.linalg.norm(d)
        fall = math.cos(az[k]) ** 2
        tip = p + d * brim_len * (0.35 + 0.65 * fall) + np.array([0, -0.012, 0])
        V += [p, tip]
        U += [[0.1 + 0.8 * j / (len(fi) - 1), 0.55], [0.1 + 0.8 * j / (len(fi) - 1), 0.95]]
    for j in range(len(fi) - 1):
        a = b0 + 2 * j
        T += [[a, a + 1, a + 2], [a + 2, a + 1, a + 3]]
    V = np.array(V); T = np.array(T, np.int64)
    T = orient_out(V, T, c)
    # double-sided (the inside of the band and the brim's underside)
    nV = len(V)
    V = np.concatenate([V, V]); U = np.array(U + U)
    T = np.concatenate([T, T[:, ::-1] + nV])
    Wt = np.zeros((len(V), len(ctx.P.names))); Wt[:, hidx] = 1
    return {"pos": V, "tri": T, "cuv": cell_uv("headwear", U[T]), "W": Wt, "cell": "headwear"}
