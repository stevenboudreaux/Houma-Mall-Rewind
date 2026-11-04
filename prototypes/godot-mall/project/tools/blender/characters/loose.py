"""Pieces generated around the body rather than cut from its skin: skirts, aprons, shoes, caps,
glasses, the watch, and the multi-part uniforms (garments.catalogue kind != 'surface').

Every one is still bound to the body by pieces.write_piece, so it follows the sliders: a skirt's
rings take the hips' and thighs' blend shapes and weights, shoes the feet's, a cap the head's.
"""
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pieces  # noqa: E402
import fabric  # noqa: E402
import garments as G  # noqa: E402
from pieces import grid_tris  # noqa: E402

TAU = 2 * math.pi


LOWER = ["pelvis_f", "pelvis_b", "crotch", "thigh_l", "thigh_r", "shin_l", "shin_r", "belly_f", "belly_b", "chest_f", "chest_b"]


def ray_in(B, o, d, far=0.6, regions=LOWER):
    """distance from o along d to the OUTERMOST skin surface (cast back from far away), seeing only
    the torso and legs (never the hands, which hang beside the hips in the A-pose)"""
    from mathutils import Vector
    bvh = G.R_bvh_regions(B, regions)
    start = Vector(o) + Vector(d) * far
    hit = bvh.ray_cast(start, -Vector(d), far)
    if hit[0] is None:
        return 0.0
    return float((Vector(hit[0]) - Vector(o)).length)


def ring_loft(B, y_top, y_bot, rows, cols, gap, flare, pleats=0.0, centre=None, follow_min=True):
    """a tube hanging from y_top to y_bot around the body axis, never inside the body, never
    narrowing going down (a skirt / dress / apron base)"""
    J = B.Fl.J
    cz = J["mixamorig_Hips"][2] if centre is None else centre
    C = cols + 1
    V = np.zeros((rows, C, 3))
    prev = None
    for i in range(rows):
        y = y_top + (y_bot - y_top) * i / (rows - 1)
        r = np.zeros(C)
        for j in range(C):
            th = TAU * j / cols
            d = np.array([math.sin(th), 0, math.cos(th)])
            rb = ray_in(B, np.array([0, y, cz]), d) + gap
            r[j] = rb
        if prev is not None:
            r = np.maximum(r, prev + flare * (y_top - y_bot) / (rows - 1))
        if pleats:
            r = r * (1 + pleats * (i / (rows - 1)) * np.abs(((np.arange(C) / cols * 28) % 1) - 0.5) * 2)
        prev = r
        for j in range(C):
            th = TAU * j / cols
            V[i, j] = [math.sin(th) * r[j], y, cz + math.cos(th) * r[j]]
    P = V.reshape(-1, 3)
    T = grid_tris(rows, C, wrap=False)
    T = pieces.fix_winding(P, T, lambda cc: np.stack([np.zeros(len(cc)), cc[:, 1], np.full(len(cc), cz)], 1))
    CUV = np.zeros((len(T), 3, 2))
    CUV[..., 0] = (T % C) / cols * 6
    CUV[..., 1] = (T // C) / rows * (y_top - y_bot) / 0.27
    return P, T, CUV


def leg_y(B, t):
    """height of the leg parameter t (0 hip joint, 0.5 knee, 1 ankle), left leg"""
    J = B.Fl.J
    h, k, a = J["mixamorig_LeftUpLeg"][1], J["mixamorig_LeftLeg"][1], J["mixamorig_LeftFoot"][1]
    return h + (k - h) * t * 2 if t < 0.5 else k + (a - k) * (t - 0.5) * 2


def skirt_part(B, hem_t, flare, pleats, layer):
    L = B.Fl
    P, T, CUV = ring_loft(B, L.rise(0.85), leg_y(B, hem_t), 12, 44, G.GAP[layer], flare, pleats=0.06 if pleats else 0.0)
    mat = np.zeros(len(T), np.int64)
    mat[T.min(1) < 45] = 1   # waistband row
    return P, T, CUV, mat


def apron_part(B, half, layer, bib=False):
    L = B.Fl
    J = L.J
    top = L.waist + 0.01 if half else L.chest + 0.09
    bot = leg_y(B, 0.42 if half else 0.5)
    rows, cols = 12, 12
    V = np.zeros((rows, cols, 3))
    hw = 0.2
    run = np.full(cols, -1.0)
    for i in range(rows):
        y = top + (bot - top) * i / (rows - 1)
        w = hw if (half or y < L.waist) else 0.12 + 0.08 * np.clip((L.waist - y + 0.05) / 0.05, 0, 1)
        # B2 fix (design/godot-character-editor.md): at the bib's top the outer rays pass beside the
        # chest (the shoulder regions are not in LOWER) and missed: z fell to ~0, the push-out then
        # shoved those corners sideways into the armpit and they took the arm's weights: the "stray
        # panel" at one side. A missed column now takes its nearest hit in the same row.
        xs = [-w + 2 * w * j / (cols - 1) for j in range(cols)]
        zs = np.array([ray_in(B, np.array([x, y, 0.0]), np.array([0, 0, 1.0])) for x in xs])
        hit = zs > 0.0
        if hit.any() and not hit.all():
            hi = np.nonzero(hit)[0]
            for j in np.nonzero(~hit)[0]:
                zs[j] = zs[hi[np.argmin(np.abs(hi - j))]]
        elif not hit.any() and i > 0:
            zs = V[i - 1, :, 2] - G.GAP[layer] - 0.006
        for j in range(cols):
            x = xs[j]
            z = zs[j] + G.GAP[layer] + 0.006
            z = max(z, run[j] - 0.1 * (bot - top) / (rows - 1)) if run[j] > 0 else z
            run[j] = z
            V[i, j] = [x, y, z]
    P = V.reshape(-1, 3)
    T = grid_tris(rows, cols, wrap=False)
    T = pieces.fix_winding(P, T, lambda cc: cc - [0, 0, 1])
    CUV = np.zeros((len(T), 3, 2)); CUV[..., 0] = (T % cols) / cols * 3; CUV[..., 1] = (T // cols) / rows * 3
    # ties / neck strap: a band round the waist (and the neck for a bib), cut from the skin
    parts = [("apron", P, T, CUV, np.zeros(len(T), np.int64))]
    band = lambda F, LL: np.minimum(0.011 - np.abs(F["y"] - (L.waist + 0.005)), G.sleeve(F, -0.05))
    S_ = B.surface(band, layer, drape=False, smooth_it=1)
    parts.append(("ties", S_[0], S_[1], S_[2], np.ones(len(S_[1]), np.int64)))
    if not half:
        strap = lambda F, LL: np.where(F["y"] > L.chest + 0.05, np.minimum(0.01 - np.abs(np.abs(F["x"]) - 0.06 - (F["y"] - L.chest) * 0.15), G.neck(F, LL, -0.02, -0.03) + 0.04), -1)
        S2 = B.surface(strap, layer, drape=False, smooth_it=1)
        if len(S2[1]):
            parts.append(("strap", S2[0], S2[1], S2[2], np.ones(len(S2[1]), np.int64)))
    return parts


def shoe_part(B, side, style, layer):
    """a lofted shoe around one foot: cross-sections from heel to toe, rounded, with a sole band"""
    R = B.R
    J = B.Fl.J
    s = "Left" if side > 0 else "Right"
    foot, toe = J["mixamorig_%sFoot" % s], J["mixamorig_%sToeBase" % s]
    ids = np.nonzero(np.isin(R.reg[:len(R.v)], [__import__("body").REGIONS.index("foot_" + ("l" if side > 0 else "r"))]))[0]
    pts = R.v[ids]
    pts = pts[pts[:, 1] < foot[1] + 0.03]
    fwd = (toe - foot) * [1, 0, 1]; fwd /= np.linalg.norm(fwd)
    lat = np.cross([0, 1, 0], fwd)
    a = (pts - foot) @ fwd
    l = (pts - foot) @ lat
    a0, a1 = a.min() - 0.006, a.max() + 0.012
    n_s, n_r = 16, 14
    gap = G.GAP[layer] + (0.004 if style != "sandals" else 0)
    shaft = 0.16 if style == "boots" else 0.0
    V = []
    for i in range(n_s):
        u = i / (n_s - 1)
        aa = a0 + (a1 - a0) * u
        sel = np.abs(a - aa) < 0.012
        if not sel.any():
            sel = np.abs(a - aa) < 0.03
        lo_l, hi_l = l[sel].min() - gap, l[sel].max() + gap
        top = pts[sel, 1].max() + gap
        if style == "dressshoes":
            top = min(top, foot[1] + 0.005)
            lo_l += 0.002; hi_l -= 0.002
        if u > 0.85:                          # rounded toe
            k = (u - 0.85) / 0.15
            sh = math.sqrt(max(1 - k * k, 0.05))
            mid = (lo_l + hi_l) / 2
            lo_l = mid + (lo_l - mid) * sh; hi_l = mid + (hi_l - mid) * sh
            top = 0.01 + (top - 0.01) * (0.55 + 0.45 * sh)
        if u < 0.1:
            k = (0.1 - u) / 0.1
            sh = math.sqrt(max(1 - k * k, 0.1))
            mid = (lo_l + hi_l) / 2
            lo_l = mid + (lo_l - mid) * sh; hi_l = mid + (hi_l - mid) * sh
        if shaft and u < 0.45:
            top = max(top, foot[1] + shaft * (1 - u / 0.45) ** 0.3)
            # the shaft must clear the lower shin: widen to the shin's width at this height
            sh_ids = np.nonzero(np.isin(R.reg[:len(R.v)], [__import__("body").REGIONS.index("shin_" + ("l" if side > 0 else "r"))]))[0]
            sp = R.v[sh_ids]; sp = sp[(sp[:, 1] > foot[1]) & (sp[:, 1] < foot[1] + shaft)]
            if len(sp):
                sl = (sp - foot) @ lat
                lo_l = min(lo_l, sl.min() - gap - 0.004); hi_l = max(hi_l, sl.max() + gap + 0.004)
        ring = []
        for r in range(n_r):
            ang = TAU * r / n_r
            cx, cy = math.cos(ang), math.sin(ang)
            xx = (lo_l + hi_l) / 2 + (hi_l - lo_l) / 2 * np.sign(cx) * abs(cx) ** 0.7
            yy = -0.002 + (top + 0.002) * (0.5 + 0.5 * np.sign(cy) * abs(cy) ** 0.6)
            p = foot * [1, 0, 1] + fwd * aa + lat * xx + [0, yy, 0]
            ring.append(p)
        V.append(ring)
    V = np.array(V).reshape(-1, 3)
    T = grid_tris(n_s, n_r)
    # caps
    c0 = len(V); V = np.concatenate([V, [V[:n_r].mean(0), V[-n_r:].mean(0)]])
    caps = [[c0, (r + 1) % n_r, r] for r in range(n_r)] + [[c0 + 1, (n_s - 1) * n_r + r, (n_s - 1) * n_r + (r + 1) % n_r] for r in range(n_r)]
    T = np.concatenate([T, np.array(caps)])
    ctr = foot * [1, 0, 1] + [0, 0.035, 0]
    T = pieces.fix_winding(V, T, lambda cc: np.stack([cc[:, 0] * 0 + ctr[0], np.full(len(cc), 0.035), cc[:, 2] * 0.0 + ctr[2]], 1) + (fwd * ((cc - ctr) @ fwd)[:, None]))
    CUV = np.zeros((len(T), 3, 2)); CUV[..., 0] = (T % n_r) / n_r * 2; CUV[..., 1] = (T // n_r) / n_s * 2
    ys = V[T].mean(1)[:, 1]
    mat = np.where(ys < 0.014 if style != "dressshoes" else ys < 0.008, 1, 0)
    if style == "sneakers":
        mat[(ys > 0.02) & (np.abs(V[T].mean(1) @ lat - foot @ lat) > 0.035) & (ys < 0.05)] = 2   # side stripe
    # boots: the shaft is a tube round the shin; push every vertex out of the skin
    V = push_clear(B, V, gap if style != "sandals" else 0.0015)
    if style == "sandals":
        # keep the sole and three straps only
        u = ((V[T].mean(1) - foot) @ fwd - a0) / (a1 - a0)
        keep = (ys < 0.012) | (np.abs(u - 0.62) < 0.04) | (np.abs(u - 0.35) < 0.04) | ((u < 0.12) & (ys < 0.05))
        T, CUV, mat = T[keep], CUV[keep], mat[keep]
    return V, T, CUV, mat


def push_clear(B, V, gap):
    """move points that are inside the skin (or closer than gap) out along the skin normal"""
    from mathutils import Vector
    bvh = G.R_bvh(B)
    V = V.copy()
    for i, p in enumerate(V):
        loc, nrm, _, d = bvh.find_nearest(Vector(p))
        s = (Vector(p) - loc).dot(nrm)
        if s < gap:
            V[i] = p + np.array(nrm) * (gap - s)
    return V


def cap_parts(B, back, layer):
    import hair as H
    head = H.Head(B.sex)
    e = head.eye[1]
    rows, cols = 9, 32
    C = cols + 1
    V = [head.c + np.array([0, 1, 0]) * (head.scalp(0, 0.0)[0] + 0.012)]
    line = H.lin(e + 0.058, e + 0.05, e + 0.045, e + 0.01)
    for i in range(rows):
        for j in range(C):
            th = TAU * j / cols
            yl = line(math.degrees(th))
            # polar angle where the scalp reaches the line (coarse search)
            best = 0.5
            for ph in np.linspace(0.2, 2.2, 60):
                r, d = head.scalp(th, ph)
                if head.c[1] + d[1] * r < yl:
                    best = ph; break
            ph = 0.08 + (best - 0.08) * (i + 1) / rows
            r, d = head.scalp(th, ph)
            V.append(head.c + d * (r + 0.016))
    V = np.array(V)
    T = [[0, 1 + j + 1, 1 + j] for j in range(cols)]
    T = np.concatenate([np.array(T), grid_tris(rows, C, wrap=False) + 1])
    # brim: a curved bill from the front edge (or the back)
    edge = V[1 + (rows - 1) * C:1 + rows * C]
    sel = [j for j in range(C) if abs(((math.degrees(TAU * j / cols) + (180 if back else 0) + 180) % 360) - 180) < 62]
    sel = sorted(sel, key=lambda j: ((TAU * j / cols + (math.pi if back else 0) + math.pi) % TAU))
    b0 = len(V)
    brim = []
    for j in sel:
        p = edge[j]
        out = (p - head.c) * [1, 0, 1]; out /= np.linalg.norm(out)
        fw = np.array([0, 0, -1.0 if back else 1.0])
        k = max(0, out @ fw)
        brim.append(p); brim.append(p + out * 0.02 + fw * 0.055 * k + [0, -0.012 * k, 0])
    V = np.concatenate([V, np.array(brim)])
    BT = []
    for q in range(len(sel) - 1):
        a = b0 + 2 * q
        BT += [[a, a + 1, a + 2], [a + 2, a + 1, a + 3]]
    BT = np.array(BT)
    T = pieces.fix_winding(V, T, head.c)
    CUV = np.zeros((len(T), 3, 2)) + 0.5
    BU = np.zeros((len(BT), 3, 2)) + 0.5
    return [("crown", V, T, CUV, np.zeros(len(T), np.int64)), ("brim", V, BT, BU, np.ones(len(BT), np.int64))]


def glasses_parts(B):
    import hair as H
    head = H.Head(B.sex)
    b = B.R.B.b
    Vs, Ts = [], []
    lens_V, lens_T = [], []
    for s, sx in (("l", 1), ("r", -1)):
        ec = B.R.B.v0[b.verts_of("helper-%s-eye" % s)].mean(0)
        c = ec + [0.004 * sx, 0.0, 0.03]
        loop = [c + [math.cos(a) * 0.026, math.sin(a) * 0.017, 0] for a in np.linspace(0, TAU, 17)[:-1]]
        loop.append(loop[0])
        from hair import tube
        v, t, _ = tube(np.array(loop), 0.0022, 4)
        Ts.append(t + sum(len(x) for x in Vs)); Vs.append(v)
        lv = np.array([c] + loop[:-1]); lt = np.array([[0, 1 + k, 1 + (k + 1) % 16] for k in range(16)])
        lens_T.append(lt + sum(len(x) for x in lens_V)); lens_V.append(lv)
        # temple arm to above the ear
        ear = np.array([sx * (head.ray(head.c, [sx, 0, 0]) + 0.004), ec[1] + 0.008, head.c[2] - 0.03])
        v, t, _ = tube(np.array([c + [sx * 0.026, 0.004, 0], c + [sx * 0.03, 0.006, -0.03], ear]), 0.0018, 4)
        Ts.append(t + sum(len(x) for x in Vs)); Vs.append(v)
    # bridge
    l = B.R.B.v0[b.verts_of("helper-l-eye")].mean(0) + [0.0, 0.004, 0.03]
    r = B.R.B.v0[b.verts_of("helper-r-eye")].mean(0) + [0.0, 0.004, 0.03]
    from hair import tube
    v, t, _ = tube(np.array([l - [0.022, 0, 0], (l + r) / 2 + [0, 0.004, 0.004], r + [0.022, 0, 0]]), 0.002, 4)
    Ts.append(t + sum(len(x) for x in Vs)); Vs.append(v)
    V = np.concatenate(Vs); T = np.concatenate(Ts)
    LV = np.concatenate(lens_V); LT = np.concatenate(lens_T)
    return [("frame", V, T, np.zeros((len(T), 3, 2)) + 0.5, np.zeros(len(T), np.int64)),
            ("lens", LV, LT, np.zeros((len(LT), 3, 2)) + 0.5, np.full(len(LT), 3))]


def watch_parts(B, layer):
    J = B.Fl.J
    w = J["mixamorig_LeftHand"]; e = J["mixamorig_LeftForeArm"]
    ax = (w - e) / np.linalg.norm(w - e)
    c = w - ax * 0.035
    R = B.R
    # band radius from the wrist skin
    ids = np.nonzero(np.abs((R.v - c) @ ax) < 0.008)[0]
    ids = ids[np.linalg.norm(R.v[ids] - c, axis=1) < 0.06]
    rad = np.linalg.norm((R.v[ids] - c) - np.outer((R.v[ids] - c) @ ax, ax), axis=1).max() + 0.003
    a = np.cross(ax, [0, 0, 1.0]); a /= np.linalg.norm(a); b2 = np.cross(ax, a)
    V = []
    n = 16
    for k in (-0.009, 0.009):
        for i in range(n):
            ang = TAU * i / n
            V.append(c + ax * k + (a * math.cos(ang) + b2 * math.sin(ang)) * rad)
    V = np.array(V)
    T = grid_tris(2, n)
    T = pieces.fix_winding(V, T, lambda cc: c + np.outer((cc - c) @ ax, ax))
    # face: a box on the back of the wrist (+a side faces away from the body in the A-pose)
    from garments import box
    out = -b2 if (c + -b2 * rad)[2] > (c + b2 * rad)[2] else b2
    fv, ft = box(np.zeros(3), [0.032, 0.032, 0.008])
    rot = np.stack([a, ax, out], 1)
    fv = fv @ rot.T + c + out * (rad + 0.003)
    return [("band", V, T, np.zeros((len(T), 3, 2)) + 0.5, np.zeros(len(T), np.int64)),
            ("face", fv, ft + 0, np.zeros((len(ft), 3, 2)) + 0.5, np.full(len(ft), 2))]


def build(B, kind, pid, label, slot, layer, o):
    tex = o.get("tex", "knit")
    meta = {"default_color": o.get("default"), "texture": tex}
    follow = None
    if kind == "skirt":
        P, T, CUV, mat = skirt_part(B, o["hem"], o["flare"], o.get("pleats"), layer)
        parts = [("skirt", P, T, CUV, mat)]
        follow = ["pelvis_f", "pelvis_b", "crotch", "thigh_l", "thigh_r", "belly_f", "belly_b"]
        mats = fabric.materials(pid, tex, o["default"])
    elif kind == "apron":
        parts = apron_part(B, half=not o.get("bib"), layer=layer, bib=o.get("bib"))
        if o.get("nametag"):
            parts.append(G.nametag(B, layer + 1))
        mats = fabric.materials(pid, tex, o["default"], accent="#f2efe6")
    elif kind == "shoe":
        parts = []
        for sd, nm in ((1, "l"), (-1, "r")):
            P, T, CUV, mat = shoe_part(B, sd, o["style"], layer)
            parts.append(("shoe_" + nm, P, T, CUV, mat))
        follow = ["foot_l", "foot_r", "shin_l", "shin_r"]
        tx = {"sneakers": "canvas", "boots": "leather", "sandals": "leather", "dressshoes": "leather"}[o["style"]]
        mats = fabric.materials(pid, tx, o["default"], trim_tex="rubber", accent="#c8c8c8")
        mats["trim"]["color"] = fabric.hexc("#2a2a2a" if o["style"] != "sneakers" else "#f0f0ee")
        mats["trim"]["extras"]["default"] = "#2a2a2a" if o["style"] != "sneakers" else "#f0f0ee"
        meta["texture"] = tx
    elif kind == "cap":
        parts = cap_parts(B, o["back"], layer)
        follow = ["head"]
        mats = fabric.materials(pid, "twill", o["default"])
    elif kind == "glasses":
        parts = glasses_parts(B)
        follow = ["head"]
        mats = {"main": {"color": fabric.hexc(o["default"]), "rough": 0.3, "extras": {"tint": "main", "label": "frame colour", "default": o["default"]}},
                "trim": {"color": [0.2, 0.2, 0.2, 1]}, "accent": {"color": [0.2, 0.2, 0.2, 1]},
                "lens": {"color": [0.85, 0.9, 0.95, 0.18], "rough": 0.05, "extras": {"tint": "lens", "label": "lens tint", "alpha": "blend"}}}
    elif kind == "watch":
        parts = watch_parts(B, layer)
        follow = ["forearm_l", "hand_l"]
        mats = {"main": {"color": fabric.hexc(o["default"]), "rough": 0.5, "extras": {"tint": "main", "label": "band colour", "default": o["default"]}},
                "trim": {"color": [0.3, 0.3, 0.3, 1]},
                "accent": {"color": fabric.hexc("#d9d6cf"), "rough": 0.25, "metal": 0.6, "extras": {"tint": "accent", "label": "face colour", "default": "#d9d6cf"}}}
    elif kind == "multi":
        parts = []
        mats = {}
        for k, (nm, keep, tx, col, extra) in enumerate(o["parts"]):
            ms = fabric.materials(pid, tx, col)
            mats[nm] = ms["main"]; mats[nm]["extras"] = dict(ms["main"]["extras"], tint=nm, label=nm + " colour")
            idx = list(mats).index(nm)
            if isinstance(keep, str):
                bits = keep.split(":")
                if bits[0] == "skirt":
                    P, T, CUV, mat = skirt_part(B, float(bits[1]), float(bits[2]), bits[3] == "pleats", layer)
                    parts.append((nm, P, T, CUV, np.full(len(T), idx)))
                elif bits[0] == "apron":
                    for q in apron_part(B, True, layer + 1):
                        parts.append((nm + q[0], q[1], q[2], q[3], np.full(len(q[2]), idx)))
                continue
            ease = None
            if extra == "pads":
                Jl, Jr = B.Fl.J["mixamorig_LeftArm"], B.Fl.J["mixamorig_RightArm"]
                def ease(F, L, Jl=Jl, Jr=Jr):
                    return 0.012 + 0.045 * np.exp(-np.minimum((F["x"] - Jl[0]) ** 2 + (F["y"] - Jl[1] - 0.04) ** 2, (F["x"] - Jr[0]) ** 2 + (F["y"] - Jr[1] - 0.04) ** 2) / 0.006)
            elif tx in ("twill", "oxford", "mesh"):
                ease = G.EASE["top"]
            if nm in ("pants", "socks"):
                k0 = keep
                keep = lambda F, L, k0=k0: G.I(k0(F, L), G.sleeve(F, -0.05))
            S_ = B.surface(keep, layer if nm != "socks" else 1, ease=ease, drape=nm in ("jersey", "dress", "shell"), fine=False)
            P, T, CUV, F, reg, N = S_
            P, T, CUV, lip, N2 = B.hem(P, T, CUV, N, G.GAP[layer] * 0.75)
            parts.append((nm, P, T, CUV, np.full(len(T), idx)))
            if extra == "collar":
                c = G.collar(B, P, T, N2, 0.03, layer)
                parts.append((nm + "_collar", c[1], c[2], c[3], np.full(len(c[2]), idx)))
        if o.get("nametag"):
            mats["accent"] = {"color": fabric.hexc("#f2efe6"), "rough": 0.5, "extras": {"tint": "accent", "label": "name tag", "default": "#f2efe6"}}
            t = G.nametag(B, layer + 1)
            parts.append((t[0], t[1], t[2], t[3], np.full(len(t[2]), list(mats).index("accent"))))
        meta["parts"] = [p[0] for p in o["parts"]]
    else:
        raise ValueError(kind)
    return B.finish(pid, label, slot, layer, parts, mats, meta, budget=o.get("tris"), follow=follow)
