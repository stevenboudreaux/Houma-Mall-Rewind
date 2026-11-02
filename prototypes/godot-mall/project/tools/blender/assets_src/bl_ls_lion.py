"""A gilded heraldic lion seated on a plinth, one each side of The Lion's Share's door (1995 map, store n36).
Large fixture (not a pick-up). The right-hand lion is the same model mirrored (scale x = -1).

THIRD PASS (workstream L, Nov 2 2026). Steven on pass two: "still soft and blobby: a smooth blob with a
vague mane and face"; he wants a carved, polished gold statue that reads at arm's length. This is a
restart, not an extension: pass two hung its locks on one big ellipsoid (the "helmet" silhouette) and built
the face from balls.

Reference: the picture Steven put on the 2D game's front (index.html media "lion", 193 x 300 px, the only
lion picture in the repo or on the refs branch; design/storefronts/refs/lions-share-lion.png). Measured
from it at S = 0.95 m / 300 px (pass two's height, kept so the placement does not change), centre at
x = 72 px, z = 0 at the seat (the picture's bottom edge):
  mane top 0.95; brow 0.855; eyes 0.785, 0.11 m apart; nose leather 0.735-0.697, 0.09 m wide; mouth 0.67;
  chin 0.64, the beard to 0.58; the face 0.19 m wide at the eyes; the mane 0.25 m wide at the top, 0.40 m
  at the cheeks, falling in locks down the sides to 0.41 and in points down the chest to 0.30;
  shoulders 0.33 m wide; front legs straight, centres +-0.083 m, 0.095 m thick, a 0.07 m gap; haunches
  low and wide (0.44 m) from 0.11 to 0.29; big paws with four toes.
Guessed: the depth (the side and back are not in the picture; seated-lion anatomy as in pass two, after
Steven's side-view statue references), the back of the mane, the tail curled round the right side to the
front, the ears (hidden in the picture's mane), the plinth (pass two's).

How it is made (the hipoly path of build.py):
1. Big forms (ellipsoids, tapered capsules) fused by a voxel remesh with a morphological closing: anatomy
   with clay-like fillets, plus the mane's core mass (crown, neck, bib) under the locks.
2. ~140 mane locks, each a hand-placed flat ribbon with a CORRUGATED top (two or three strand ridges per
   lock), laid on the core by ray casting (so they drape over the crown, neck, shoulders and chest
   instead of hugging an ellipsoid), in tiers: the face ruff (rooted on the face's edge, raised above the
   middle ring once it leaves the face) over the middle ring over the long outer locks; tips lift off the
   surface (deep undercuts); paths and normals smoothed along each lock.
3. Paws and toes as separate solids with real gaps between the toes (no closing on them).
4. Everything unioned by a 2.4 mm voxel remesh, lightly smoothed.
5. The face as a CARVED RELIEF (relief()): one surface whose depth is a sum of smooth terms (dome, snout
   profile, nose leather, nostrils, pads, philtrum, mouth line, chin, V brow ridges, almond sockets, lids,
   cheeks, carved fur strokes), closed into a solid, fused with the skull and ears at 1.4 mm; whisker dots
   and ear cups carved with booleans; eyeballs with drilled pupils in the sockets. (Iteration 1 built the
   face from solids, as pass two did: it read as a pug / teddy bear however it was tuned.)
6. Decimated to the budget; normal, AO and curvature baked down (build.py); finish_maps() below drives the
   gold from the baked AO and curvature: polished and bright on the high points, darker and rougher in the
   recesses; subtle scratches come from the hipoly material.
7. Steven's picture as texture: projected straight on from the front (orthographic camera projection, its
   fine detail only: a high-pass of the picture) onto the front of the mane and face, masked to
   front-facing surfaces; strength REF_DETAIL. At 193 x 300 px it adds faint grain only; the read comes
   from the geometry.
Review: tools/blender/compare.py (the reference, this build and pass two at the same angles);
production/qa/evidence/wsL-lion-sheet-{1..5}.jpg.
Origin: bottom centre of the plinth, facing Godot +Z (Blender -Y).
"""
import math
import os
import random
import bmesh
import bpy
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from lib import core, parts, mats

PZ = 0.32                 # plinth height = the lion's seat
PLINTH = (0.72, 0.76)     # plinth top, x by y
VOXEL = 0.0024            # final remesh of body + mane: the finest lock groove
FORM_VOXEL = 0.007        # the big anatomy
CLOSE = 0.016             # fillet radius where the big forms meet
HEAD_VOXEL = 0.0014       # the face, carved after its remesh
SEED = 11
# mane param space: (u, h): u = arc metres round from the front (+ = the lion's left, Blender +X),
# h = height above the seat; below HC rays run level towards the axis, above it they tilt over the crown
AX_Y = -0.05              # the mane's axis (y)
HC = 0.80                 # where rays start to tilt over the crown
RTOP = 0.17               # arc metres from HC to the crown's pole
RC = 0.19                 # arc metres per radian round the axis
FACE_H = 0.755            # the face's centre height
REF_DETAIL = 0.35         # Steven's picture as albedo detail on the front (0 = off)
REF_PX = 0.95 / 300       # metres per reference pixel
REF_CX = 72               # the lion's centre line in the picture (px)
# gold: hollows -> high points (sRGB), and roughness at each
GOLD_LO, GOLD_MID, GOLD_HI = (0.30, 0.22, 0.08), (0.78, 0.63, 0.31), (0.97, 0.88, 0.56)
ROUGH_LO, ROUGH_MID, ROUGH_HI = 0.62, 0.34, 0.18
METAL = 0.9

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", "..", "..", "..", ".."))
REF = os.path.join(REPO, "design", "storefronts", "refs", "lions-share-lion.png")

META = {
    "id": "bl_ls_lion",
    "class": "large_fixture",
    "tex": 2048,
    "ao": 0.7,
    "curvature": True,
    "hipoly": 24000,
    "cage": 0.016,
    "lowpoly_voxel": 0.007,
    "hipoly_keep": ["stone"],
    "uv_shrink": {"stone": 0.3},
    "refs": [["design/storefronts/refs/lions-share-lion.png", None, "Steven's lion (index.html media)"]],
}


# ------------------------------------------------------------------ primitives (z above the seat)
def V(c):
    return Vector((c[0], c[1], PZ + c[2]))


def E(name, r, c, rot=(0, 0, 0), seg=24, rings=14):
    ob = parts.sphere(name, 1.0, seg, rings, scale=r)
    core.place(ob, tuple(V(c)), rot)
    return ob


def taper(name, a, b, ra, rb, seg=20):
    """A tapered capsule from a (radius ra) to b (radius rb)."""
    a, b = V(a), V(b)
    d = b - a
    ob = parts.cylinder(name, ra, d.length, seg, bev=0, r2=rb)
    ob.location = (a + b) / 2
    ob.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
    for p, r in ((a, ra), (b, rb)):
        s = parts.sphere(name + "_end", r, 16, 8)
        s.location = p
    return ob


def trap(name, w_top, w_bot, h, d, c, rot=(0, 0, 0), bev=0.008):
    """A bevelled trapezoid prism (w_top at +z, w_bot at -z, h tall, d deep): the nose, the bridge."""
    bm = bmesh.new()
    vs = []
    for z, w in ((-h / 2, w_bot), (h / 2, w_top)):
        for x, y in ((-w / 2, -d / 2), (w / 2, -d / 2), (w / 2, d / 2), (-w / 2, d / 2)):
            vs.append(bm.verts.new((x, y, z)))
    for f in ((0, 1, 2, 3), (7, 6, 5, 4), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)):
        bm.faces.new([vs[i] for i in f])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    ob = core.obj_from_bmesh(name, bm, None, smooth=True)
    core.place(ob, tuple(V(c)), rot)
    if bev:
        core.bevel(ob, bev, 3, angle=30, harden=False)
    return ob


def spline(ctrl, n):
    """Catmull-Rom through control points (tuples or Vectors), n samples."""
    P = [Vector(p) for p in ctrl]
    P = [P[0] * 2 - P[1]] + P + [P[-1] * 2 - P[-2]]
    out = []
    segs = len(P) - 3
    for i in range(n):
        t = i / (n - 1) * segs
        k = min(int(t), segs - 1)
        u = t - k
        p0, p1, p2, p3 = P[k], P[k + 1], P[k + 2], P[k + 3]
        out.append(0.5 * ((2 * p1) + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u * u + (-p0 + 3 * p1 - 3 * p2 + p3) * u ** 3))
    return out


def ribbon(name, pts, nrm, w0, h0, tip=0.12, sides=16, ridges=2, full=0.35):
    """A carved lock: a flat-backed section w wide across the surface, h thick off it, its top corrugated
    by `ridges` strand ridges (grooves ~25% of the thickness), swept along pts (nrm = the surface normal at
    each point), full width over the first `full` of its length, then narrowing to a rounded point."""
    bm = bmesh.new()
    rings = []
    n = len(pts)
    for i, p in enumerate(pts):
        s = i / (n - 1)
        t = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
        up = (nrm[i] - t * nrm[i].dot(t)).normalized()
        side = t.cross(up).normalized()
        k = 1.0 if s < full else max(tip, 1.0 - ((s - full) / (1 - full)) ** 1.3 * (1.0 - tip))
        k *= 1.0 + 0.10 * math.sin(min(1.0, s / full) * math.pi * 0.5)
        if s < 0.12:                       # the root tucks in under the tier above
            k *= 0.75 + 0.25 * s / 0.12
        w, h = w0 * k / 2, h0 * (0.5 + 0.5 * k) / 2
        if i == n - 1:
            rings.append([bm.verts.new(p + up * h * 0.3)])
            continue
        ring = []
        for j in range(sides):
            a = math.tau * j / sides
            x = math.cos(a)
            yv = math.sin(a)
            if yv > 0:     # the carved top: a dome with strand grooves running along the lock
                yv *= 1.0 - 0.28 * (0.5 - 0.5 * math.cos((x + 1) * math.pi * ridges)) * min(1.0, k * 1.5)
            else:          # the flat back lying on the surface
                yv *= 0.3
            ring.append(bm.verts.new(p + side * (w * x) + up * (h * yv)))
        rings.append(ring)
    for a, b in zip(rings, rings[1:]):
        if len(b) == 1:
            for j in range(sides):
                bm.faces.new((a[j], a[(j + 1) % sides], b[0]))
        else:
            for j in range(sides):
                bm.faces.new((a[j], a[(j + 1) % sides], b[(j + 1) % sides], b[j]))
    f = bm.faces.new(list(reversed(rings[0])))
    bmesh.ops.poke(bm, faces=[f])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return core.obj_from_bmesh(name, bm, None, smooth=True)


# ------------------------------------------------------------------ the big forms
def body():
    """Seated-lion anatomy: chest up, the back sloping from the withers to a round rump, a shoulder blade
    over each straight foreleg, the hind leg folded (thigh forward to the knee beside the chest, the shin
    back to the hock, the hind foot lying forward on the plinth)."""
    for sx in (-1, 1):
        # hind leg: the haunch is the round thigh seen beside the front legs (0.11-0.29 high, 0.44 m wide)
        taper("thigh", (sx * 0.14, 0.20, 0.20), (sx * 0.175, -0.04, 0.10), 0.115, 0.08)
        E("haunch", (0.085, 0.16, 0.105), (sx * 0.150, 0.06, 0.175), rot=(-12, 0, sx * 4))
        taper("shin", (sx * 0.19, -0.04, 0.085), (sx * 0.205, 0.19, 0.045), 0.06, 0.042)
        taper("hindfoot", (sx * 0.205, 0.19, 0.035), (sx * 0.225, -0.10, 0.034), 0.042, 0.038)
        # front leg: shoulder blade, upper arm to the elbow, forearm straight down to the wrist
        taper("scapula", (sx * 0.105, 0.03, 0.60), (sx * 0.095, -0.05, 0.36), 0.065, 0.058)
        taper("upperarm", (sx * 0.090, -0.07, 0.46), (sx * 0.086, -0.115, 0.28), 0.062, 0.054)
        taper("forearm", (sx * 0.085, -0.120, 0.28), (sx * 0.083, -0.135, 0.075), 0.052, 0.040)
        E("elbow", (0.045, 0.05, 0.06), (sx * 0.095, -0.065, 0.29))
        E("forearm_m", (0.048, 0.05, 0.085), (sx * 0.085, -0.125, 0.22))        # the forearm's muscle
    E("chest", (0.135, 0.125, 0.17), (0, -0.075, 0.44))
    E("ribcage", (0.135, 0.19, 0.14), (0, 0.05, 0.34), rot=(-32, 0, 0))
    taper("spine", (0.0, 0.03, 0.58), (0.0, 0.21, 0.18), 0.105, 0.12)
    E("back", (0.15, 0.17, 0.11), (0, 0.13, 0.40), rot=(-50, 0, 0))
    E("rump", (0.17, 0.14, 0.13), (0, 0.21, 0.13))
    for sx in (-1, 1):
        E("triceps", (0.045, 0.07, 0.08), (sx * 0.10, 0.0, 0.40), rot=(-20, 0, 0))
        E("flank", (0.05, 0.13, 0.08), (sx * 0.11, 0.08, 0.30), rot=(-30, 0, 0))
        E("shoulder", (0.10, 0.12, 0.14), (sx * 0.12, -0.04, 0.50))
    # the mane's core mass (the locks lie on it): crown round the skull, the neck, a bib over the chest
    E("crown", (0.145, 0.15, 0.13), (0, -0.07, 0.80))
    E("neckmass", (0.165, 0.17, 0.18), (0, -0.02, 0.63))
    for sx in (-1, 1):     # the mane's breadth at the cheeks (0.40 m across in the picture)
        E("jowl", (0.075, 0.10, 0.13), (sx * 0.135, -0.09, 0.70))
    E("bib", (0.115, 0.075, 0.15), (0, -0.135, 0.50))
    E("cape", (0.13, 0.12, 0.15), (0, 0.08, 0.55), rot=(-30, 0, 0))


def paws():
    """Front paws (big, four toes with real gaps) and the hind paws beside them."""
    out = []
    for sx in (-1, 1):
        cx = sx * 0.083
        out.append(E("forepaw", (0.056, 0.075, 0.040), (cx, -0.175, 0.040)))
        out.append(E("wrist", (0.044, 0.05, 0.05), (cx, -0.140, 0.075)))
        for k in range(4):
            x = cx + (k - 1.5) * 0.0285
            out.append(E("toe", (0.0122, 0.030, 0.024), (x, -0.232 + 0.006 * abs(k - 1.5), 0.024), rot=(0, 0, (k - 1.5) * -6), seg=16, rings=10))
        hx = sx * 0.232
        out.append(E("hindpaw", (0.046, 0.065, 0.034), (hx, -0.125, 0.034)))
        for k in range(3):
            x = hx + (k - 1) * 0.027
            out.append(E("htoe", (0.0118, 0.026, 0.020), (x, -0.178 + 0.005 * abs(k - 1), 0.020), seg=14, rings=8))
    return out


def tail():
    pts = [V(p) for p in [(0.0, 0.31, 0.06), (0.14, 0.34, 0.026), (0.29, 0.21, 0.022), (0.325, 0.02, 0.022), (0.31, -0.13, 0.026), (0.285, -0.20, 0.04)]]
    pts = spline(pts, 18)
    nrm = [Vector((0, 0, 1))] * len(pts)
    t = ribbon("tail", pts, nrm, 0.044, 0.040, tip=0.75, sides=12, ridges=1)
    tf = []
    for k, (dx, dy, a) in enumerate(((0.0, 0.0, 0), (-0.018, -0.006, -25), (0.018, -0.006, 25))):   # the tuft: three locks
        c = Vector((0.285 + dx, -0.20 + dy, 0.045))
        p = [V(tuple(c)), V(tuple(c + Vector((math.sin(math.radians(a)) * 0.03, -0.05, 0.004)))), V(tuple(c + Vector((math.sin(math.radians(a)) * 0.05, -0.085, -0.008))))]
        p = spline(p, 8)
        tf.append(ribbon("tuft", p, [Vector((0, 0, 1))] * len(p), 0.034, 0.03, tip=0.1, sides=10, ridges=2, full=0.2))
    return [t] + tf


# ------------------------------------------------------------------ the mane
class Drape:
    """Lays (u, h) mane coordinates on the core by ray casting from outside towards the mane's axis."""

    def __init__(self, obs):
        dg = bpy.context.evaluated_depsgraph_get()
        self.bvhs = [BVHTree.FromObject(ob, dg) for ob in obs]

    def ray(self, u, h):
        phi = u / RC
        if h <= HC:
            el, z = 0.0, h
        else:
            el, z = min((h - HC) / RTOP, 1.57), HC
        d = Vector((math.sin(phi) * math.cos(el), -math.cos(phi) * math.cos(el), math.sin(el)))
        a = Vector((0, AX_Y, PZ + z))
        return a, d

    def at(self, u, h, off):
        a, d = self.ray(u, h)
        hits = [h for h in (b.ray_cast(a + d * 1.5, -d, 3.0) for b in self.bvhs) if h[0] is not None]
        hit = min(hits, key=lambda h: h[3]) if hits else (None,)    # the outermost surface: core or face
        if hit[0] is None:
            return a + d * 0.15, d
        n = hit[1]
        if n.dot(d) < 0.2:          # a grazing hit (an overhang): use the ray's own direction
            n = (n + d).normalized()
        return hit[0] + n * off, n


def lay(dr, name, ctrl, w, h, n=18, ridges=2, tip=0.12, full=0.35):
    """ctrl: [(u, h, off), ...] control points in mane coordinates; returns the lock."""
    pts, nrm = [], []
    for c in spline(ctrl, n):
        p, nn = dr.at(c.x, c.y, c.z)
        pts.append(p)
        nrm.append(nn)
    # smooth the path and the normals along the lock (the drape switching between the face and the core,
    # and the core's facets, would kink and twist it)
    for _ in range(3):
        pts = [pts[0]] + [(pts[i - 1] + pts[i] * 2 + pts[i + 1]) / 4 for i in range(1, n - 1)] + [pts[-1]]
    sm = nrm
    for _ in range(3):
        sm = [(sm[max(i - 1, 0)] + sm[i] * 2 + sm[min(i + 1, n - 1)]).normalized() for i in range(n)]
    return ribbon(name, pts, sm, w, h, tip=tip, ridges=ridges, full=full)


def mane(dr, drf, rng):
    """dr lays locks on the core; drf on the core or the face, whichever is outermost (the ruff only)."""
    locks = []
    J = lambda s: rng.uniform(-s, s)   # noqa: E731

    def radial(a, r0, L, g, off0, lift, sway, w, th, ridges, name, d=None, edge=False, rise=0.0):
        """A lock from the ring round the face at angle a (0 = up, + = the lion's left), going out and
        bending down with gravity g; lift raises the tip off the surface. edge: the root sits on the face
        oval's margin (true x, z: x = 0.115 sin a, z = 0.752 + 0.138 cos a), converted to mane coordinates."""
        su, sh = math.sin(a), math.cos(a)
        if edge:
            u0 = RC * math.asin(max(-1.0, min(1.0, 0.112 * su / 0.205)))
            h0 = 0.752 + 0.133 * sh
        else:
            u0, h0 = su * r0 * 1.05, FACE_H + sh * r0 * 0.95
        ctrl = []
        for k in range(6):
            t = k / 5
            rr = L * t
            sw = sway * math.sin(t * math.pi * 1.3)
            u = u0 + su * rr * 1.05 + sh * sw
            hh = h0 + sh * rr * 0.95 - su * sw - g * (L * t) ** 2 * (1.0 + abs(su))
            ctrl.append((u, hh, off0 + rise * min(1.0, t / 0.3) + lift * max(0.0, t - 0.45) / 0.55))
        locks.append(lay(d or dr, name, ctrl, w, th, ridges=ridges))

    # 1. the inner ruff framing the face (over everything); the lowest ones become the beard
    n = 22
    for i in range(n):
        a = math.pi * (-1 + 2 * (i + 0.5) / n) + J(0.03)
        down = max(0.0, -math.cos(a))
        if down > 0.93:
            continue                          # under the chin: the beard below
        L = (0.075 + 0.05 * abs(math.sin(a)) + 0.06 * down) * rng.uniform(0.9, 1.1)
        radial(a, 0.0, L * 1.45, 1.4, 0.014, 0.022, rng.uniform(0.012, 0.02) * rng.choice((-1, 1)), 0.064 * rng.uniform(0.9, 1.1), 0.040, 2, "ruff", d=drf, edge=True, rise=0.034)
    # 2. the middle ring: longer, heavier, bending down at the sides
    n = 24
    for i in range(n):
        a = math.pi * (-1 + 2 * (i + 0.5 * (1 + J(0.3))) / n)
        down = max(0.0, -math.cos(a))
        if down > 0.9:
            continue
        L = (0.12 + 0.07 * abs(math.sin(a)) + 0.06 * down) * rng.uniform(0.88, 1.12)
        radial(a, 0.165, L, 2.0, 0.024, 0.032, rng.uniform(0.015, 0.03) * rng.choice((-1, 1)), 0.072 * rng.uniform(0.9, 1.1), 0.042, 3, "mid")
    # 3. the beard and chest: locks from under the chin falling in long points down the chest, three tiers
    for tier, (h0, cnt, L, off, w) in enumerate(((0.645, 4, 0.17, 0.034, 0.062), (0.60, 5, 0.22, 0.024, 0.068), (0.55, 6, 0.24, 0.014, 0.074))):
        for i in range(cnt):
            u0 = (i - (cnt - 1) / 2) * w * 0.82 + J(0.006)
            sway = rng.uniform(0.012, 0.025) * rng.choice((-1, 1))
            ctrl = [(u0 * (1 + 0.25 * t) + sway * math.sin(t * 3.0), h0 - L * t * rng.uniform(0.9, 1.1), off + 0.018 * max(0.0, t - 0.6) / 0.4) for t in (0, 0.2, 0.4, 0.6, 0.8, 1.0)]
            locks.append(lay(dr, "beard", ctrl, w * rng.uniform(0.9, 1.08), 0.040, ridges=3))
    # 4. the outer mane: rows from over the crown falling down the sides of the neck past the shoulders
    #    (the front view's long side locks), and down the back of the neck to the withers
    rows = [  # (h0 root, number per side, u from, u to, length, off)
        (1.06, 7, 0.06, 0.60, 0.32, 0.012),
        (0.97, 8, 0.14, 0.62, 0.36, 0.018),
        (0.88, 8, 0.22, 0.62, 0.38, 0.010),
        (0.77, 7, 0.28, 0.62, 0.34, 0.004),
    ]
    for ri, (h0, cnt, ua, ub, L, off) in enumerate(rows):
        for sx in (-1, 1):
            for i in range(cnt):
                u0 = ua + (ub - ua) * (i + 0.5 * (ri % 2)) / (cnt - 0.5) + J(0.01)
                if u0 > ub:
                    continue
                back = min(1.0, max(0.0, (u0 - 0.30) / 0.3))     # 0 at the sides, 1 at the back
                LL = L * rng.uniform(0.85, 1.12) * (1.0 - 0.25 * back)
                flick = (0.012 + 0.014 * rng.random()) * (1 - back)  # the side locks' tips stand out
                sway = rng.uniform(0.012, 0.026) * (1 if (i + ri) % 2 else -1)
                ctrl = []
                for k in range(6):
                    t = k / 5
                    # side locks drift outward-forward as they fall (round the shoulder); back ones straight down
                    u = u0 - 0.06 * t * (1 - back) + sway * math.sin(t * math.pi * 1.4)
                    ctrl.append((sx * u, h0 + 0.03 - LL * t * (1.2 if h0 > HC else 1.0), off + 0.006 + flick * max(0.0, t - 0.55) / 0.45))
                locks.append(lay(dr, "outer", ctrl, rng.uniform(0.085, 0.10), 0.05, ridges=3))
    # 5. over the top of the head: short locks combed back from the brow
    for i in range(7):
        u0 = (i - 3) * 0.04 + J(0.006)
        ctrl = [(u0 * (0.8 + 0.5 * t), 0.875 + 0.20 * t, 0.026 + 0.012 * t) for t in (0, 0.25, 0.5, 0.75, 1.0)]
        locks.append(lay(dr, "top", ctrl, 0.062, 0.038, ridges=2))
    return locks


# ------------------------------------------------------------------ the face
FY = -0.012     # the whole face, forward (-) or back (+)


def F(c):
    return (c[0], c[1] + FY, c[2])


YB = -0.200      # the face relief's base plane (y); the relief comes forward of it
FACE_X = (-0.135, 0.135)
FACE_Z = (0.585, 0.905)
FACE_RES = 0.0012


def _sbox(t, half, soft):
    """1 inside |t| < half, 0 outside, a smooth edge `soft` wide."""
    return np.clip((half + soft - np.abs(t)) / (2 * soft), 0, 1) ** 2 * (3 - 2 * np.clip((half + soft - np.abs(t)) / (2 * soft), 0, 1))


def _g(d, r):
    return np.exp(-(d / r) ** 2)


def _segd(x, z, a, b):
    ax, az = a
    bx, bz = b
    vx, vz = bx - ax, bz - az
    t = np.clip(((x - ax) * vx + (z - az) * vz) / (vx * vx + vz * vz), 0, 1)
    return np.hypot(x - ax - t * vx, z - az - t * vz)


def relief(x, z, sockets=True):
    """How far the carved face stands forward of YB at (x, z) (metres; z above the seat). Every feature is
    a smooth term, so the planes blend like carving instead of meeting like balls. Front-view positions are
    measured from Steven's picture; the depths are guessed."""
    ax = np.abs(x)
    # the snout: the bridge slopes forward from between the eyes to the nose, then the muzzle falls back
    prof = np.interp(z, [0.600, 0.625, 0.645, 0.662, 0.690, 0.708, 0.740, 0.790, 0.825], [0.0, 0.026, 0.040, 0.050, 0.058, 0.060, 0.046, 0.012, 0.0])
    halfw = np.interp(z, [0.600, 0.640, 0.680, 0.702, 0.740, 0.790, 0.825], [0.030, 0.056, 0.064, 0.050, 0.029, 0.025, 0.030])
    snout = prof * _sbox(x, halfw, 0.016)
    nose = 0.007 * _sbox(x, np.interp(z, [0.695, 0.737], [0.018, 0.046]), 0.0035) * _sbox(z - 0.716, 0.021, 0.0035)
    nostril = -0.011 * _g(np.hypot(ax - 0.025, (z - 0.700) * 1.4), 0.0065)
    pads = 0.016 * _g(np.hypot(ax - 0.034, (z - 0.670) * 1.15), 0.028)
    philtrum = -0.006 * _g(x, 0.0032) * _sbox(z - 0.672, 0.024, 0.004)
    zm = 0.649 + 2.2 * x * x
    mouth = -0.008 * _g(z - zm, 0.0034) * _sbox(x, 0.074, 0.008)
    chin = 0.010 * _g(np.hypot(x, (z - 0.627) * 1.3), 0.022)
    brow = 0.017 * _g(_segd(ax, z, (0.013, 0.794), (0.094, 0.823)), 0.011)
    cheek = 0.013 * _g(np.hypot(ax - 0.080, z - 0.712), 0.036)
    frown = -0.0045 * _g(x, 0.0026) * _sbox(z - 0.814, 0.019, 0.004) - 0.003 * _g(ax - 0.015, 0.0022) * _sbox(z - 0.812, 0.012, 0.004)
    lid = 0.004 * _g(_segd(ax, z, (0.032, 0.762), (0.072, 0.768)), 0.004)
    feats = snout + nose + nostril + pads + philtrum + mouth + chin + brow + cheek + frown + lid
    # the features fade out towards the face's oval; the dome runs to its edge (meeting the ruff, which
    # covers the join); beyond the oval the relief sinks back into the skull and mane (no slab edges)
    r = np.hypot(x / 0.118, (z - 0.752) / 0.140)
    m = np.clip((1.0 - r) / 0.2, 0, 1)
    sink = np.clip((r - 0.98) / 0.08, 0, 1)
    dome = 0.064 * np.sqrt(np.clip(1 - r * r, 0, 1)) + 0.018
    # carved fur strokes radiating from the nose over the cheeks, the brow and the forehead (not on the muzzle)
    ang = np.arctan2(z - 0.700, x)
    rn = np.hypot(x, (z - 0.700) * 1.1)
    strokes = 0.0026 * (0.5 + 0.5 * np.cos(ang * 34 + 6 * rn)) * np.clip((rn - 0.075) / 0.03, 0, 1) * np.clip((1.0 - r) / 0.12, 0, 1)
    strokes = strokes * (1 - _g(_segd(ax, z, (0.012, 0.786), (0.088, 0.790)), 0.022))   # not across the eyes
    feats = feats - strokes
    d = (dome + feats * m) * (1 - sink) - 0.085 * sink
    if sockets:
        # almond sockets under the brow, outer corner up
        c, s_ = math.cos(math.radians(14)), math.sin(math.radians(14))
        u = (ax - 0.052) * c - (z - 0.777) * s_
        v = (ax - 0.052) * s_ + (z - 0.777) * c
        e = np.hypot(u / 0.026, v / 0.0135)
        d = d - 0.024 * np.clip((1.15 - e) / 0.5, 0, 1) ** 1.5
    return d


def face_relief():
    """The face relief as a closed solid: the carved front surface, a flat back at y = YB + 0.09."""
    nx = int((FACE_X[1] - FACE_X[0]) / FACE_RES) + 1
    nz = int((FACE_Z[1] - FACE_Z[0]) / FACE_RES) + 1
    xs = np.linspace(FACE_X[0], FACE_X[1], nx)
    zs = np.linspace(FACE_Z[0], FACE_Z[1], nz)
    X, Z = np.meshgrid(xs, zs)
    Y = YB + FY - relief(X, Z)
    me = bpy.data.meshes.new("face")
    front = np.stack([X.ravel(), Y.ravel(), Z.ravel() + PZ], 1)
    back = front.copy()
    back[:, 1] = YB + FY + 0.09
    verts = np.concatenate([front, back])
    idx = np.arange(nx * nz).reshape(nz, nx)
    o = nx * nz
    faces = []
    for j in range(nz - 1):
        for i in range(nx - 1):
            a, b, c, d = idx[j, i], idx[j, i + 1], idx[j + 1, i + 1], idx[j + 1, i]
            faces.append((a, d, c, b))
            faces.append((a + o, b + o, c + o, d + o))
    ring = list(idx[0, :]) + list(idx[1:, -1]) + list(idx[-1, -2::-1]) + list(idx[-2:0:-1, 0])
    for k in range(len(ring)):
        a, b = ring[k], ring[(k + 1) % len(ring)]
        faces.append((a, b, b + o, a + o))
    me.from_pydata(verts.tolist(), [], faces)
    me.validate()
    ob = bpy.data.objects.new("face", me)
    core.link(ob)
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    return ob


def head():
    """The carved face relief, the skull behind it, the ears half in the mane."""
    out = [face_relief()]
    out.append(E("skull", (0.10, 0.11, 0.095), F((0, -0.13, 0.80))))
    for sx in (-1, 1):
        out.append(E("ear", (0.028, 0.014, 0.030), F((sx * 0.098, -0.15, 0.885)), rot=(-10, sx * 25, sx * -15), seg=16, rings=10))
    return out


def cutters():
    """Boolean cutters carved out of the face after its remesh: the whisker dots and the ear cups."""
    cs = []
    for sx in (-1, 1):
        for r, (dz, cnt) in enumerate(((0.684, 3), (0.673, 3), (0.662, 3))):   # whisker dots in rows on the pads
            for k in range(cnt):
                x = sx * (0.020 + 0.012 * k + 0.003 * r)
                y = YB + FY - float(relief(np.array(x), np.array(dz)))
                cs.append(E("dot", (0.0024, 0.006, 0.0024), F((x, y - FY, dz)), seg=8, rings=6))
        cs.append(E("earcup", (0.019, 0.012, 0.022), F((sx * 0.098, -0.158, 0.885)), rot=(-10, sx * 25, sx * -15), seg=14, rings=8))
    return cs


def eyes():
    """The eyeballs in the sockets, their fronts a little behind the socket rims, looking straight out."""
    out = []
    for sx in (-1, 1):
        x, z = sx * 0.052, 0.777
        rim = float(relief(np.array(x), np.array(z), sockets=False))
        y = YB - rim + 0.009 + 0.011       # front 9 mm behind the un-cut surface; centre one radius behind
        eye = E("eye", (0.022, 0.011, 0.0118), F((x, y, z)), rot=(0, 0, sx * -14), seg=24, rings=16)
        pupil = E("pupil", (0.0065, 0.004, 0.0065), F((x - sx * 0.002, y - 0.011, z)), seg=12, rings=8)
        carve(eye, [pupil])        # a drilled pupil, as on carved statues
        out.append(eye)
    return out


# ------------------------------------------------------------------ materials
def ref_highpass():
    """Steven's picture, its fine detail only (luminance minus a blur, around 0.5), for the projection."""
    from PIL import Image, ImageFilter
    out = os.path.join(REPO, "prototypes", "godot-mall", "project", ".scratch", "blender", "bl_ls_lion_refdetail.png")
    im = Image.open(REF).convert("RGBA")
    a = np.asarray(im.split()[3], dtype=np.float32) / 255.0
    lum = np.asarray(im.convert("L"), dtype=np.float32) / 255.0
    blur = np.asarray(Image.fromarray((lum * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(5)), dtype=np.float32) / 255.0
    hp = np.clip(0.5 + (lum - blur) * 1.6, 0, 1) * a + 0.5 * (1 - a)
    Image.fromarray((hp * 255).astype(np.uint8)).save(out)
    return out


def gold_mat():
    """The hipoly's gold: the colour and roughness DETAIL (casting grain, scratches, Steven's picture
    projected on the front); finish_maps() then builds the final gold from the baked AO and curvature."""
    m = mats.M("bronze", "#9c7430", 0.3, 1.0)
    co = m.coords()
    # scratches: thin streaks (noise stretched along one axis) in two directions, a little brighter, rougher
    sc = []
    for rot in ((0.3, 0.9, 0.2), (1.1, -0.4, 0.7)):
        mp = m.node("ShaderNodeMapping")
        mp.inputs["Rotation"].default_value = rot
        mp.inputs["Scale"].default_value = (2.0, 2.0, 160.0)
        m.link(co, mp.inputs["Vector"])
        n = m.node("ShaderNodeTexNoise", Scale=9.0, Detail=1.0, Roughness=0.3)
        m.link(mp.outputs["Vector"], n.inputs["Vector"])
        sc.append(m.ramp(n.outputs["Fac"], [(0.0, "#000000"), (0.475, "#000000"), (0.5, "#ffffff"), (0.525, "#000000")]))
    spot = m.ramp(m.noise(6.0, 2.0).outputs["Fac"], [(0.45, "#000000"), (0.62, "#ffffff")])   # scratches come in patches
    scr = m.math("MULTIPLY", m.math("MAXIMUM", sc[0], sc[1]), spot)
    grain = m.noise(80.0, 4.0)
    base = m.mix(m.math("MULTIPLY", grain.outputs["Fac"], 0.25), "#9c7430", "#b08540")
    base = m.mix(m.math("MULTIPLY", scr, 0.35), base, "#e8c878")
    if REF_DETAIL > 0 and os.path.exists(REF):
        img = m.node("ShaderNodeTexImage")
        img.image = bpy.data.images.load(ref_highpass(), check_existing=True)
        img.image.colorspace_settings.name = "Non-Color"
        img.extension = "CLIP"
        # orthographic projection from the front: u = REF_CX/W + x/(W*px), v = (z - PZ)/(H*px)
        W, H = 193, 300
        mp = m.node("ShaderNodeMapping")
        m.link(co, mp.inputs["Vector"])
        mp.inputs["Rotation"].default_value = (math.radians(90), 0, 0)   # object XZ -> image UV
        mp.inputs["Scale"].default_value = (1 / (W * REF_PX), 1 / (H * REF_PX), 1)
        mp.inputs["Location"].default_value = (REF_CX / W, -PZ / (H * REF_PX), 0)
        m.link(mp.outputs["Vector"], img.inputs["Vector"])
        geo = m.node("ShaderNodeNewGeometry")
        sep = m.node("ShaderNodeSeparateXYZ")
        m.link(geo.outputs["Normal"], sep.inputs["Vector"])
        facing = m.math("MULTIPLY", m.math("MAXIMUM", m.math("MULTIPLY_ADD", sep.outputs["Y"], -1.6, -0.5), 0.0), REF_DETAIL)   # only where the surface faces the front
        facing = m.math("MINIMUM", facing, REF_DETAIL)
        # albedo *= 1 + (hp - 0.5) * 2 * facing
        k = m.math("MULTIPLY_ADD", m.math("SUBTRACT", img.outputs["Color"], 0.5), m.math("MULTIPLY", facing, 2.0), 1.0)
        mul = m.node("ShaderNodeMix")
        mul.data_type = "RGBA"
        mul.blend_type = "MULTIPLY"
        mul.inputs["Factor"].default_value = 1.0
        m.link(base, mul.inputs[6])
        m.link(m.node("ShaderNodeCombineColor").outputs[0], mul.inputs[7])
        cc = mul.inputs[7].links[0].from_node
        for s in ("Red", "Green", "Blue"):
            m.link(k, cc.inputs[s])
        base = mul.outputs[2]
    m.link(base, m.bsdf.inputs["Base Color"])
    m.link(m.math("MULTIPLY_ADD", scr, 0.25, 0.3), m.bsdf.inputs["Roughness"])   # baked as the scratch layer
    m.bump(m.noise(500.0, 2.0).outputs["Fac"], 0.05, 0.0004)
    return m.mat


def stone_mat():
    m = mats.M("stone", "#8d867b", 0.8)
    n = m.noise(25.0, 5.0)
    m.link(m.ramp(n.outputs["Fac"], [(0.35, "#7a7368"), (0.65, "#a19a8e")]), m.bsdf.inputs["Base Color"])
    m.bump(m.noise(300.0, 3.0).outputs["Fac"], 0.25, 0.0008)
    return m.mat


def _blur(a, r):
    """A cheap box blur (r px) for the curvature map."""
    k = 2 * r + 1
    c = np.cumsum(np.pad(a, ((r + 1, r), (0, 0)), mode="edge"), axis=0)
    a = (c[k:] - c[:-k]) / k
    c = np.cumsum(np.pad(a, ((0, 0), (r + 1, r)), mode="edge"), axis=1)
    return (c[:, k:] - c[:, :-k]) / k


def finish_maps(mp):
    """The gold from the baked AO and curvature (build.py hook): hollows dark and rough, high points
    bright and polished; the hipoly's scratch/picture detail is kept on top. The stone plinth (metal 0
    in the bake) keeps its own maps, with the plain AO fold."""
    alb, rough, metal, ao = mp["albedo"], mp["rough"], mp["metal"], mp["ao"]
    gold = metal > 0.5
    curv = mp["curv"] if mp["curv"] is not None else np.full_like(ao, 0.5)
    c = _blur(curv, 1)
    hollow = np.clip((0.5 - c) * 7.0, 0, 1)           # concave: lock grooves, under the tiers, sockets
    ridge = np.clip((c - 0.5) * 7.0, 0, 1)            # convex: lock crests, brow, toes
    occ = np.clip((1.0 - ao) * 1.6, 0, 1) ** 0.8      # deep: between locks, under the mane, between legs
    dark = np.clip(0.65 * occ + 0.6 * hollow, 0, 0.85)
    lo, mid, hi = (np.array(x, dtype=np.float32) for x in (GOLD_LO, GOLD_MID, GOLD_HI))
    t_hi = np.clip(ridge * 0.9 + (1 - occ) * 0.35 - 0.15, 0, 1)
    col = mid[None, None, :] * (1 - t_hi[..., None]) + hi[None, None, :] * t_hi[..., None]
    col = col * (1 - dark[..., None]) + lo[None, None, :] * dark[..., None]
    # the hipoly's own detail: its colour relative to its mean gold, as a multiplier
    base_lin = np.array((0.612, 0.455, 0.188), dtype=np.float32)    # "#9c7430" in sRGB 0..1, as baked
    det = np.clip(alb[..., :3] / base_lin[None, None, :], 0.6, 1.6)
    col = np.clip(col * det, 0, 1)
    out = alb.copy()
    out[..., :3] = np.where(gold[..., None], col, alb[..., :3] * (0.3 + 0.7 * ao[..., None]))
    r_scr = np.clip((rough - 0.3) / 0.25, 0, 1)      # the scratch layer (hipoly roughness 0.3 + 0.25 * scratch)
    rg = ROUGH_MID + (ROUGH_HI - ROUGH_MID) * t_hi
    rg = rg + (ROUGH_LO - rg) * dark + 0.12 * r_scr
    mp["rough"] = np.where(gold, np.clip(rg, 0.05, 1), rough)
    mp["metal"] = np.where(gold, METAL - 0.15 * dark, metal)
    mp["albedo"] = out
    return mp


# ------------------------------------------------------------------ assembly
def join(objs, name):
    for o in objs:
        core.apply_all(o)
    core.select_only(objs, objs[0])
    with bpy.context.temp_override(active_object=objs[0], selected_editable_objects=objs, selected_objects=objs):
        bpy.ops.object.join()
    ob = objs[0]
    ob.name = name
    return ob


def _vox(ob, voxel):
    rm = ob.modifiers.new("Remesh", "REMESH")
    rm.mode = "VOXEL"
    rm.voxel_size = voxel
    core.apply_all(ob)


def _grow(ob, d):
    dp = ob.modifiers.new("Grow", "DISPLACE")
    dp.strength = d
    dp.mid_level = 0.0
    core.apply_all(ob)


def remesh(ob, voxel, smooth=0, factor=0.5, close=0.0):
    """Voxel remesh (a union of every form). close > 0: a morphological closing first (grow, remesh,
    shrink back): clay-like fillets of that radius where forms meet. Smooth-shaded."""
    if close > 0:
        _vox(ob, max(voxel, close / 3))
        _grow(ob, close)
        _vox(ob, max(voxel, close / 3))
        _grow(ob, -close)
    _vox(ob, voxel)
    if smooth:
        sm = ob.modifiers.new("Smooth", "LAPLACIANSMOOTH")
        sm.lambda_factor = factor
        sm.iterations = smooth
        sm.use_volume_preserve = True
        sm.use_normalized = True
        core.apply_all(ob)
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def carve(ob, cuts):
    cut = join(cuts, "cutters")
    bo = ob.modifiers.new("Carve", "BOOLEAN")
    bo.operation = "DIFFERENCE"
    bo.object = cut
    bo.solver = "EXACT"
    bo.use_self = True
    bo.use_hole_tolerant = True
    n0 = len(ob.data.polygons)
    core.apply_all(ob)
    if len(ob.data.polygons) == n0:
        raise SystemExit("CARVE FAILED: the boolean changed nothing")
    bpy.data.objects.remove(cut)


def build():
    rng = random.Random(SEED)
    before = set(core.mesh_objects())
    body()
    forms = remesh(join([o for o in core.mesh_objects() if o not in before], "forms"), FORM_VOXEL, 4, 0.6, close=CLOSE)
    fr = face_relief()          # the ruff lies over the face's edge, not behind it
    dr = Drape([forms])
    drf = Drape([forms, fr])
    before = set(core.mesh_objects())
    bpy.data.objects.remove(fr)
    mane(dr, drf, rng)
    tail()
    paws()
    detail = [o for o in core.mesh_objects() if o not in before]
    print("SCULPT %d locks/paws/tail parts" % len(detail))
    L = remesh(join([forms] + detail, "lion"), VOXEL, 2, 0.5)
    print("SCULPT body + mane fused: %d faces" % len(L.data.polygons))
    # the face: its own finer remesh, carved alone (a boolean on the whole sculpt runs out of memory), kept
    # as a shell sitting in the ruff (the bake reads both)
    Hd = remesh(join(head(), "head"), HEAD_VOXEL, 3, 0.5, close=0.010)
    carve(Hd, cutters())
    print("SCULPT head carved: %d faces" % len(Hd.data.polygons))
    gm = gold_mat()
    for ob in [L, Hd] + eyes():
        ob.data.materials.clear()
        ob.data.materials.append(gm)
    # plinth: a moulded cast-stone block (pass two's)
    st = stone_mat()
    w, d = PLINTH
    parts.box("plinth", (w - 0.04, d - 0.04, PZ - 0.08), loc=(0, 0.02, 0.04 + (PZ - 0.08) / 2), mat=st, bev=0.004)
    parts.box("plinthbase", (w + 0.02, d + 0.02, 0.05), loc=(0, 0.02, 0.025), mat=st, bev=0.006, seg=3)
    parts.box("plinthtop", (w, d, 0.035), loc=(0, 0.02, PZ - 0.0175), mat=st, bev=0.008, seg=3)
    parts.trim("ogee", [(0.0, 0.0), (-0.006, 0.006), (-0.008, 0.014), (-0.014, 0.02)], w - 0.03, loc=(0, 0.02 - d / 2 + 0.03, PZ - 0.035 - 0.02), mat=st)
