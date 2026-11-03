"""Hair library (B1): eleven styles per base body, each a static mesh on the Head bone (<= 2k tris),
with a colour slider (the material tint) and blend shapes from the head it sits on (head size, age,
weight ... move the scalp, the hair follows: pieces.py binding to head / neck skin only).

How a style is built: a grid over the scalp in (azimuth, polar angle) around the cranium centre:
  * each column runs from the crown down the scalp, offset by the style's thickness from the
    scalp (ray-cast onto the body's skin; over the ears the radius is dilated so hair passes
    over them) to the style's line (bangs / hairline / bowl edge, a height per azimuth);
  * long styles continue below the line as a curtain: straight down, pushed out to clear the
    neck, shoulders and back (horizontal rays onto the skin + a gap), flaring a little;
  * extras: curl displacement (perm, elderly set), puffs (two noisy spheres), braids (tubes
    hanging from the lower ring), a bald crown (horseshoe), a part line (groove).
Material: one strand texture (hair_albedo.png / hair_normal.png, grey, tinted per style colour).
Vertex colour (COLOR_0) darkens the roots and the curtain's underside (Godot multiplies it).

  BPY python hair.py [female|male] [style ...]
"""
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pieces  # noqa: E402
from pieces import Part, rig, write_piece, grid_tris  # noqa: E402
from tex import noise3  # noqa: E402

OUT = pieces.OUT


def lin(front, temple, ear, back):
    """A height per azimuth (degrees, 0 = front) by piecewise-linear interpolation, mirrored."""
    xs = [0, 60, 100, 180]; ys = [front, temple, ear, back]
    return lambda th: float(np.interp(abs(((th + 180) % 360) - 180), xs, ys))


STYLES = {
    # thick: (top, sides) metres; line: heights above eye level (front, temple, ear, back);
    # hang: curtain bottom (height above eye level) for sides/back, None = none
    "bowl":      {"label": "Bowl cut", "thick": (0.018, 0.013), "line": (0.032, 0.03, 0.02, -0.02), "dilate": True, "color": "brown"},
    "fade":      {"label": "Short fade", "thick": (0.011, 0.0035), "line": (0.072, 0.05, 0.035, -0.07), "fade": True, "color": "black"},
    "crew":      {"label": "Crew cut", "thick": (0.018, 0.005), "line": (0.072, 0.05, 0.035, -0.07), "color": "brown"},
    "sidepart":  {"label": "Side part", "thick": (0.026, 0.008), "line": (0.068, 0.048, 0.032, -0.07), "part": 38, "color": "dark brown"},
    "shoulder":  {"label": "Shoulder length", "thick": (0.016, 0.014), "line": (0.05, 0.03, 0.015, -0.05), "hang": -0.2, "dilate": True, "color": "light brown"},
    "long":      {"label": "Long straight", "thick": (0.014, 0.012), "line": (0.06, 0.03, 0.015, -0.05), "hang": -0.42, "dilate": True, "color": "dark blonde"},
    "perm":      {"label": "Perm / curly", "thick": (0.038, 0.05), "line": (0.055, 0.035, 0.015, -0.05), "hang": -0.16, "dilate": True, "curl": (0.016, 17.0), "color": "auburn"},
    "puffs":     {"label": "Puffs", "thick": (0.006, 0.004), "line": (0.07, 0.05, 0.035, -0.07), "puffs": 0.06, "color": "black"},
    "braids":    {"label": "Braids", "thick": (0.006, 0.005), "line": (0.07, 0.05, 0.035, -0.06), "braids": (8, -0.30), "color": "black"},
    "balding":   {"label": "Thinning / balding", "thick": (0.006, 0.005), "line": (0.04, 0.035, 0.03, -0.07), "bald": True, "color": "grey"},
    "elderly":   {"label": "White / grey set (elderly)", "thick": (0.03, 0.022), "line": (0.07, 0.045, 0.03, -0.06), "curl": (0.006, 55.0), "color": "white"},
}


class Head:
    def __init__(self, sex):
        self.R = R = rig(sex)
        B = R.B
        b = B.b
        self.eye = (B.v0[b.verts_of("helper-l-eye")].mean(0) + B.v0[b.verts_of("helper-r-eye")].mean(0)) / 2
        hv = R.v[R.reg[:len(R.v)] == 0]
        top = hv[:, 1].max()
        cr = hv[hv[:, 1] > self.eye[1]]
        self.c = np.array([0.0, (top + self.eye[1]) / 2 - 0.005, cr[:, 2].mean() - 0.005])
        self.top = top
        from mathutils.bvhtree import BVHTree
        self.bvh = BVHTree.FromPolygons(B.v0.tolist(), R.tris.tolist(), all_triangles=True)

    def ray(self, o, d):
        from mathutils import Vector
        # cast from outside inward so the outer surface is found
        start = Vector(o) + Vector(d) * 0.5
        hit = self.bvh.ray_cast(start, -Vector(d), 0.6)
        if hit[0] is None:
            return None
        return float((Vector(hit[0]) - Vector(o)).length)

    def scalp(self, th, ph):
        d = np.array([math.sin(ph) * math.sin(th), math.cos(ph), math.sin(ph) * math.cos(th)])
        r = self.ray(self.c, d)
        return r if r else 0.09, d

    def clearance(self, y, th):
        """distance from the head's vertical axis to the skin along azimuth th at height y"""
        o = np.array([self.c[0], y, self.c[2]])
        d = np.array([math.sin(th), 0, math.cos(th)])
        return self.ray(o, d) or 0.0


def build(sex, name, S, cols=36, rows=13, hang_rows=9):
    H = Head(sex)
    e = H.eye[1]
    arm_y = H.R.J["mixamorig_LeftArm"][1] + 0.06
    line = lin(*[e + x for x in S["line"]])
    C = cols + 1                      # vertex columns: the last repeats the first (texture seam)
    th_list = [2 * math.pi * i / cols for i in range(C)]
    # polar angle where the scalp reaches the line height, per column
    def phi_end(th):
        yl = line(math.degrees(th))
        lo, hi = 0.05, 2.4
        for _ in range(28):
            mid = (lo + hi) / 2
            r, d = H.scalp(th, mid)
            y = H.c[1] + d[1] * r
            if y > yl:
                lo = mid
            else:
                hi = mid
        return (lo + hi) / 2
    ends = [phi_end(t) for t in th_list]
    # scalp radius grid (dilated over the ears for styles that cover them)
    ph0 = 0.08
    R = np.zeros((rows, C)); D = np.zeros((rows, C, 3)); PH = np.zeros((rows, C))
    for j, th in enumerate(th_list):
        for i in range(rows):
            ph = ph0 + (ends[j] - ph0) * (i / (rows - 1)) ** 0.9
            r, d = H.scalp(th, ph)
            R[i, j], D[i, j], PH[i, j] = r, d, ph
    if S.get("dilate"):
        R2 = R.copy()
        for i in range(rows):
            for j in range(C):
                R2[i, j] = max(R[max(0, i - 2):i + 3, [(j + k) % cols for k in range(-2, 3)]].max(), R[i, j])
        R = 0.5 * R + 0.5 * R2
    top_t, side_t = S["thick"]
    P = np.zeros((rows, C, 3)); AO = np.ones((rows, C))
    for i in range(rows):
        for j in range(C):
            ph = PH[i, j]
            k = np.clip((ph - 0.5) / 0.8, 0, 1)
            t = top_t * (1 - k) + side_t * k
            if S.get("part"):
                pa = math.radians(S["part"])
                dth = abs(((th_list[j] - pa + math.pi) % (2 * math.pi)) - math.pi)
                if ph < 1.2:
                    t *= 1 - 0.55 * math.exp(-(dth / 0.12) ** 2)
                # sweep: more volume on the far side of the part at the front
                if math.cos(th_list[j]) > 0.3 and math.sin(th_list[j]) < 0:
                    t *= 1.25
            # taper to the edge
            t = max(t * (0.55 + 0.45 * (1 - (i / (rows - 1)) ** 4)), 0.003)   # >= 3 mm: no z-fighting with the scalp
            P[i, j] = H.c + D[i, j] * (R[i, j] + t)
            AO[i, j] = 0.85 + 0.15 * (1 - i / (rows - 1))
    verts = [H.c + np.array([0, 1, 0]) * (H.scalp(0, 0.0)[0] + top_t)]
    ao = [1.0]
    uvs = [[0.5, 0.0]]
    for i in range(rows):
        for j in range(C):
            verts.append(P[i, j]); ao.append(AO[i, j]); uvs.append([j / cols * 9, (i + 1) / rows * 0.5])
    tris = [[0, 1 + j + 1, 1 + j] for j in range(cols)]
    g = grid_tris(rows, C, wrap=False) + 1
    tris = np.concatenate([np.array(tris), g])
    verts = np.array(verts); ao = list(ao)
    nrow = rows
    # curtain
    if S.get("hang") is not None:
        yb = e + S["hang"]
        base = P[rows - 1]
        cur = [base]
        for k in range(1, hang_rows + 1):
            row = []
            for j, th in enumerate(th_list):
                deg = abs(((math.degrees(th) + 180) % 360) - 180)
                L = np.clip((deg - 40) / 45, 0, 1)        # no curtain over the face
                p0 = base[j]
                # the sides stop on the shoulders; the length falls down the back
                top = max(yb, arm_y)
                ybc = top + (yb - top) * float(np.clip((deg - 100) / 40, 0, 1))
                y = p0[1] + (min(ybc, p0[1]) - p0[1]) * (k / hang_rows) * L
                prev = cur[-1][j]
                rad = math.hypot(prev[0] - H.c[0], prev[2] - H.c[2]) + 0.002 * L
                need = H.clearance(y, th) + side_t + 0.012
                rad = max(rad, min(need, rad + 0.02)) if L > 0 else rad
                row.append(np.array([H.c[0] + math.sin(th) * rad, y, H.c[2] + math.cos(th) * rad]))
            cur.append(np.array(row))
        start = len(verts)
        add = np.concatenate(cur[1:])
        verts = np.concatenate([verts, add])
        for k in range(hang_rows):
            for j in range(C):
                ao.append(0.95 - 0.25 * (k / hang_rows)); uvs.append([j / cols * 9, 0.5 + (k + 1) / hang_rows * 0.8])
        g2 = grid_tris(hang_rows + 1, C, wrap=False) + (1 + (rows - 1) * C)
        # first row of g2 is the scalp's last row (already in verts), the rest follow `start`
        def remap(ix):
            r = (ix - (1 + (rows - 1) * C)) // C
            c = (ix - (1 + (rows - 1) * C)) % C
            return ix if r == 0 else start + (r - 1) * C + c
        g2 = np.vectorize(remap)(g2)
        tris = np.concatenate([tris, g2])
    if S.get("bald"):
        # keep only the lower band (horseshoe): drop triangles above a polar angle, and in front
        keep = []
        for t in tris:
            c = verts[t].mean(0) - H.c
            ph = math.acos(np.clip(c[1] / np.linalg.norm(c), -1, 1))
            th = math.degrees(math.atan2(c[0], c[2]))
            if ph > 1.05 and abs(th) > 55:
                keep.append(t)
        tris = np.array(keep)
    verts = np.array(verts, float)
    if S.get("curl"):
        amp, f = S["curl"]
        n = pieces.vertex_normals(verts, pieces.fix_winding(verts, tris, H.c))
        nz = noise3(verts[None] + 3.3, f, 21, 2)[0] - 0.5
        verts = verts + n * (nz * 2 * amp)[:, None]
    parts_v = [verts]; parts_t = [tris]; parts_uv = [np.array(uvs)]; parts_ao = [np.array(ao)]
    if S.get("puffs"):
        r = S["puffs"]
        for sx in (1, -1):
            pc = H.c + np.array([sx * 0.065, 0.055, -0.03])
            v, t = icosphere(2)
            nz = noise3(v[None] * 1.0 + sx, 6.0, 31, 2)[0]
            vv = pc + v * r * (0.9 + 0.25 * nz)[:, None]
            o = sum(len(x) for x in parts_v)
            parts_v.append(vv); parts_t.append(t + o)
            parts_uv.append(np.stack([np.arctan2(v[:, 0], v[:, 2]) / math.pi * 2, v[:, 1] * 1.5], 1)); parts_ao.append(0.85 + 0.15 * (v[:, 1] * 0.5 + 0.5))
    if S.get("braids"):
        nb, ybot = S["braids"]
        base = P[rows - 1]
        for q in range(nb):
            th = math.radians(122 + (360 - 244) * q / (nb - 1))
            j = int(round(th / (2 * math.pi) * cols)) % cols
            root = base[j] + (base[j] - H.c) * 0.03
            path = [root]
            y_end = e + ybot
            for k in range(1, 12):
                y = root[1] + (y_end - root[1]) * k / 11
                rad = max(math.hypot(path[-1][0] - H.c[0], path[-1][2] - H.c[2]), H.clearance(y, th) + 0.012)
                path.append(np.array([H.c[0] + math.sin(th) * rad, y, H.c[2] + math.cos(th) * rad]))
            v, t, uv = tube(np.array(path), 0.0065, 5, bumps=True)
            o = sum(len(x) for x in parts_v)
            parts_v.append(v); parts_t.append(t + o); parts_uv.append(uv); parts_ao.append(np.full(len(v), 0.8))
    V = np.concatenate(parts_v); T = np.concatenate(parts_t); UV = np.concatenate(parts_uv); AO = np.concatenate(parts_ao)
    # outward = away from the head's vertical axis (from the cranium centre above the eyes)
    T = pieces.fix_winding(V, T, lambda cc: np.stack([np.full(len(cc), H.c[0]), np.minimum(cc[:, 1], H.c[1]), np.full(len(cc), H.c[2])], 1))
    col = np.stack([AO, AO, AO, np.ones_like(AO)], 1)
    pid = "hair_%s_%s" % (name, sex)
    part = Part("hair", V, T, UV, "hair", follow=["head", "neck"], rigid_bone="mixamorig_Head", color=col)
    mats = {"hair": {"albedo": "hair_albedo.png", "normal": "hair_normal.png", "rough": 0.55, "double": True,
                     "extras": {"tint": "hair", "label": "hair colour"}}}
    return write_piece(sex, pid, [part], mats, {"slot": "hair", "layer": 5, "label": S["label"], "style": name,
                                                  "default_color": S["color"], "hides": []})


def icosphere(n):
    t = (1 + 5 ** 0.5) / 2
    v = [[-1, t, 0], [1, t, 0], [-1, -t, 0], [1, -t, 0], [0, -1, t], [0, 1, t], [0, -1, -t], [0, 1, -t], [t, 0, -1], [t, 0, 1], [-t, 0, -1], [-t, 0, 1]]
    f = [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
         [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]]
    v = [np.array(x, float) / np.linalg.norm(x) for x in v]
    for _ in range(n):
        mid = {}
        nf = []
        def m(a, b):
            k = (min(a, b), max(a, b))
            if k not in mid:
                p = v[a] + v[b]; v.append(p / np.linalg.norm(p)); mid[k] = len(v) - 1
            return mid[k]
        for a, b, c in f:
            ab, bc, ca = m(a, b), m(b, c), m(c, a)
            nf += [[a, ab, ca], [b, bc, ab], [c, ca, bc], [ab, bc, ca]]
        f = nf
    return np.array(v), np.array(f)


def tube(path, r, sides, bumps=False, r_end=None):
    """A tube along a polyline (closed sides, open ends), uvs along its length."""
    n = len(path)
    V = []; UV = []
    L = 0
    for i in range(n):
        tng = path[min(i + 1, n - 1)] - path[max(i - 1, 0)]
        tng /= np.linalg.norm(tng)
        a = np.cross(tng, [0, 0, 1.0]);
        if np.linalg.norm(a) < 1e-3:
            a = np.cross(tng, [1.0, 0, 0])
        a /= np.linalg.norm(a); b = np.cross(tng, a)
        if i:
            L += np.linalg.norm(path[i] - path[i - 1])
        rr = r if r_end is None else r + (r_end - r) * i / (n - 1)
        if bumps:
            rr *= 0.8 + 0.35 * abs(math.sin(L / 0.012 * math.pi))
        for s in range(sides):
            ang = 2 * math.pi * s / sides + (L / 0.012 * math.pi * 0.5 if bumps else 0)
            V.append(path[i] + (a * math.cos(ang) + b * math.sin(ang)) * rr)
            UV.append([s / sides, L / 0.1])
    T = grid_tris(n, sides)
    return np.array(V), T, np.array(UV)


def textures():
    from PIL import Image
    s = 512
    y, x = np.mgrid[0:s, 0:s] / s
    rng = np.random.default_rng(9)
    strands = np.zeros((s, s), np.float32)
    for k in range(260):
        x0 = rng.random(); w = 0.002 + rng.random() * 0.004; a = 0.3 + 0.7 * rng.random()
        wav = 0.004 * np.sin(y * 2 * np.pi * (1 + rng.random() * 2) + rng.random() * 6)
        d = np.abs(((x - x0 - wav + 0.5) % 1.0) - 0.5)
        strands = np.maximum(strands, a * np.clip(1 - d / w, 0, 1))
    base = 0.72 + 0.28 * strands
    alb = np.stack([base] * 3, -1)
    Image.fromarray((alb * 255).astype(np.uint8)).save(os.path.join(OUT, "hair_albedo.png"), optimize=True)
    gx = np.gradient(strands, axis=1)
    n = np.stack([-gx * 2.5, np.zeros_like(gx), np.ones_like(gx)], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    Image.fromarray(((n * 0.5 + 0.5) * 255).astype(np.uint8)).save(os.path.join(OUT, "hair_normal.png"), optimize=True)


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    sexes = [a for a in argv if a in ("female", "male")] or ["female", "male"]
    names = [a for a in argv if a in STYLES] or list(STYLES)
    textures()
    for s in sexes:
        for n in names:
            build(s, n, STYLES[n])
