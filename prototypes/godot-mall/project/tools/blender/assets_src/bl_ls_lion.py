"""A gilded lion seated on a plinth, one each side of The Lion's Share's door (1995 map, store n36).
Large fixture (not a pick-up). The right-hand lion is the same model mirrored (scale x = -1).

SECOND PASS (workstream T2, Nov 1 2026; Steven on the first pass: "they don't look good").
Reference: the picture Steven put on the 2D game's front (index.html media "lion", 193 x 300;
design/storefronts/refs/lions-share-lion.png), design/storefronts/lions-share.md. From it, measured at
~3.2 mm/px for a 0.95 m lion: a European heraldic lion sitting bolt upright; the head 0.93 m at the top of
the mane, the face 0.23 m wide at the eyes, eyes at 0.755, nose tip at 0.68, chin at 0.60; a mane of long
separate S-curved locks 0.50 m wide framing the face in tiers, the inner ruff lying over the outer locks,
falling over the shoulders and in long points down the chest to the legs; front legs straight, apart
(centres +-0.067 m, 0.08 m thick), heavy paws with four toes; haunches low and wide (0.59 m) at the sides
with the hind paws forward. Calm face: heavy brow with a frown crease, deep-set eyes, a broad flat nose
bridge, a wide nose with nostrils, round muzzle pads split by a groove, a closed mouth, a small chin.
Guessed: the depth (side and back are not in the picture), the plinth, the tail curled round the right
hind paw, the back of the mane.

How (the first pass read soft and blobby: 4 mm voxels, round tube locks hugging one mass, the face built
of balls): now
- big forms (ellipsoids, tapered capsules) fused and smoothed at 7 mm: clean anatomy;
- the face as planes (wedge brow ridges, a box nose bridge, a wedge nose, pads, cheeks), and ~110 mane
  locks as FLAT tapered ribbons in four tiers (ruff over middle over outer, tips curling off the surface),
  so the gaps between locks and the undercuts under each tier stay deep;
- everything unioned once with a 2.5 mm voxel remesh, lightly smoothed, then CARVED with boolean cutters:
  eye sockets, the frown crease, nostrils, the muzzle groove, the mouth line, the toe splits;
- eyeballs set into the sockets afterwards.
That sculpt (~2M triangles) is decimated to the budget and baked onto it (normal, colour with
pointiness cavity shading, AO): the hipoly path of build.py.
Origin: bottom centre of the plinth, facing Godot +Z (Blender -Y).
"""
import math
import random
import bmesh
import bpy
from mathutils import Vector, Matrix
from lib import core, parts, mats

PZ = 0.32                 # plinth height = the lion's seat
PLINTH = (0.72, 0.76)     # plinth top, x by y
VOXEL = 0.0025            # final remesh: the finest carved detail
FORM_VOXEL = 0.007        # the big anatomy
HEAD_FWD = 0.018           # the face pulled forward out of the mane
HEAD_VOXEL = 0.0016       # the face, carved after its remesh
SEED = 7
GOLD = ["#4a3210", "#8f6c2c", "#cba64e", "#f2d98e"]   # hollows -> high points

META = {
    "id": "bl_ls_lion",
    "class": "large_fixture",
    "tex": 2048,
    "ao": 0.7,
    "hipoly": 24000,
    "cage": 0.020,
    "lowpoly_voxel": 0.008,
    "hipoly_keep": ["stone"],
    "uv_shrink": {"stone": 0.3},
    "refs": [["design/storefronts/refs/lions-share-lion.png", None, "Steven's lion (index.html media)"]],
}


# ------------------------------------------------------------------ primitives (z is above the seat)
def E(name, r, c, rot=(0, 0, 0), seg=24, rings=14):
    ob = parts.sphere(name, 1.0, seg, rings, scale=r)
    core.place(ob, (c[0], c[1], PZ + c[2]), rot)
    return ob


def V(c):
    return Vector((c[0], c[1], PZ + c[2]))


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


def wedge(name, size, c, rot=(0, 0, 0), bev=0.006):
    """A bevelled box (planes for the face: brow, bridge, nose)."""
    ob = parts.box(name, size, mat=None, bev=bev, seg=3)
    core.place(ob, V(c), rot)
    return ob


def spline(ctrl, n):
    """Catmull-Rom through control points, n samples."""
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


def ribbon(name, pts, nrm, w0, h0, tip=0.15, sides=10):
    """A flat tapered lock: an elliptical section (w wide across the surface, h thick off it) swept along
    pts, with nrm[i] the surface normal at each point; it narrows to a rounded point."""
    bm = bmesh.new()
    rings = []
    n = len(pts)
    for i, p in enumerate(pts):
        s = i / (n - 1)
        t = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
        up = (nrm[i] - t * nrm[i].dot(t)).normalized()
        side = t.cross(up).normalized()
        # full width over the first third, then tapering to the point; a little swell near the root
        k = 1.0 if s < 0.3 else max(tip, 1.0 - ((s - 0.3) / 0.7) ** 1.4 * (1.0 - tip))
        k *= 1.0 + 0.12 * math.sin(min(1.0, s / 0.3) * math.pi * 0.5)
        w, h = w0 * k / 2, h0 * (0.55 + 0.45 * k) / 2
        if i == n - 1:
            rings.append([bm.verts.new(p)])
            continue
        ring = []
        for j in range(sides):
            a = math.tau * j / sides
            # a flat-backed, domed section: the back lies on the surface, the face bulges
            yv = math.sin(a)
            yv = yv if yv > 0 else yv * 0.35
            ring.append(bm.verts.new(p + side * (w * math.cos(a)) + up * (h * yv)))
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


# ------------------------------------------------------------------ measurements (metres, z above the seat)
HOOD_C = Vector((0.0, -0.045, 0.625))     # the mane's mass
HOOD_R = Vector((0.255, 0.19, 0.27))
FACE_C = Vector((0.0, 0.0, 0.735))       # the face's centre in the front plane (x, -, z)


def hood_point(x, z, out=0.0, rim=0.97):
    """The point on the front of the mane's mass at (x, z), `out` metres off it, and its normal. Points past
    the rim are pulled back onto it so locks follow the mane's edge round to the side."""
    u = ((x - HOOD_C.x) / HOOD_R.x) ** 2 + ((z - HOOD_C.z) / HOOD_R.z) ** 2
    if u > rim:
        k = math.sqrt(rim / u)
        x = HOOD_C.x + (x - HOOD_C.x) * k
        z = HOOD_C.z + (z - HOOD_C.z) * k
        u = rim
    y = HOOD_C.y - HOOD_R.y * math.sqrt(max(0.0, 1.0 - u))
    nrm = Vector(((x - HOOD_C.x) / HOOD_R.x ** 2, (y - HOOD_C.y) / HOOD_R.y ** 2, (z - HOOD_C.z) / HOOD_R.z ** 2)).normalized()
    return Vector((x, y, PZ + z)) + nrm * out, nrm


def hood_sph(theta, phi, out=0.0):
    """A point on the mane's mass by angles: theta from the top (0) down, phi round from the front (-Y)."""
    d = Vector((math.sin(theta) * math.sin(phi), -math.sin(theta) * math.cos(phi), math.cos(theta)))
    p = HOOD_C + Vector((d.x * HOOD_R.x, d.y * HOOD_R.y, d.z * HOOD_R.z))
    nrm = Vector(((p.x - HOOD_C.x) / HOOD_R.x ** 2, (p.y - HOOD_C.y) / HOOD_R.y ** 2, (p.z - HOOD_C.z) / HOOD_R.z ** 2)).normalized()
    return Vector((p.x, p.y, PZ + p.z)) + nrm * out, nrm


# ------------------------------------------------------------------ the parts
def body():
    """Seated-lion anatomy (Steven, Nov 1: "fill out the side and back", after his side-view statue refs):
    the back slopes from the withers down to a round rump on the plinth; a ribcage and flank between the
    shoulder and the haunch; a shoulder blade over each straight foreleg; the hind leg folded: a long
    thigh from the hip forward and down to the knee beside the chest, the shin back to the hock, the
    hind foot lying forward along the plinth to its paw."""
    for sx in (-1, 1):
        # hind leg
        taper("thigh", (sx * 0.15, 0.20, 0.21), (sx * 0.195, -0.05, 0.085), 0.115, 0.07)
        E("hipmuscle", (0.085, 0.15, 0.12), (sx * 0.17, 0.14, 0.17), rot=(-28, 0, sx * 4))
        taper("shin", (sx * 0.20, -0.05, 0.085), (sx * 0.215, 0.20, 0.045), 0.06, 0.042)
        taper("hindfoot", (sx * 0.215, 0.20, 0.035), (sx * 0.245, -0.12, 0.034), 0.04, 0.036)
        E("hindpaw", (0.052, 0.085, 0.036), (sx * 0.250, -0.155, 0.036))
        # the front leg: shoulder blade to elbow to wrist, straight, a little raked back at the top
        taper("scapula", (sx * 0.105, 0.03, 0.60), (sx * 0.095, -0.06, 0.34), 0.062, 0.055)
        taper("upperleg", (sx * 0.075, -0.075, 0.44), (sx * 0.070, -0.125, 0.25), 0.050, 0.043)
        taper("foreleg", (sx * 0.070, -0.125, 0.25), (sx * 0.068, -0.150, 0.07), 0.043, 0.034)
        E("elbow", (0.042, 0.05, 0.06), (sx * 0.08, -0.07, 0.30))
        E("forepaw", (0.056, 0.08, 0.036), (sx * 0.068, -0.195, 0.036))
        for k in range(4):   # toes along the front of each paw
            x = sx * 0.068 + (k - 1.5) * 0.026
            E("toe", (0.0165, 0.026, 0.022), (x, -0.255, 0.026 - 0.003 * abs(k - 1.5)), seg=14, rings=8)
        for k in range(3):
            x = sx * 0.250 + (k - 1) * 0.026
            E("htoe", (0.016, 0.022, 0.019), (x, -0.225, 0.022), seg=14, rings=8)
    E("chest", (0.13, 0.13, 0.16), (0, -0.065, 0.45))
    E("ribcage", (0.135, 0.19, 0.14), (0, 0.05, 0.36), rot=(-32, 0, 0))
    taper("spine", (0.0, 0.02, 0.60), (0.0, 0.22, 0.17), 0.12, 0.13)    # withers down to the rump
    E("rump", (0.17, 0.14, 0.13), (0, 0.21, 0.13))
    E("neck", (0.15, 0.13, 0.17), (0, 0.0, 0.64))
    for sx in (-1, 1):   # muscle: the triceps behind the elbow, the deltoid, the flank over the ribs
        E("triceps", (0.045, 0.07, 0.08), (sx * 0.10, 0.0, 0.40), rot=(-20, 0, 0))
        E("deltoid", (0.05, 0.07, 0.06), (sx * 0.11, -0.06, 0.47))
        E("flank", (0.05, 0.13, 0.08), (sx * 0.11, 0.08, 0.30), rot=(-30, 0, 0))
    # the mane's mass under the locks (they lie on it), widening to a bell over the shoulders and running
    # on down the back of the neck as a cape
    E("hood", tuple(HOOD_R * 0.88), tuple(HOOD_C), seg=32, rings=20)
    E("cape", (0.15, 0.12, 0.17), (0, 0.09, 0.52), rot=(-30, 0, 0))
    for sx in (-1, 1):
        E("shoulder", (0.10, 0.13, 0.15), (sx * 0.15, -0.04, 0.50))


def head():
    """The face from solids, fused by its own remesh and smoothed so the planes blend: skull and forehead,
    wedge brow ridges, a rounded muzzle block under a flat nose bridge, a wide wedge nose, cheeks, jaw,
    muzzle pads and chin. Returns the parts."""
    out = []
    out.append(E("skull", (0.100, 0.10, 0.095), (0, -0.160, 0.80)))
    out.append(E("forehead", (0.088, 0.06, 0.05), (0, -0.212, 0.852), rot=(30, 0, 0)))
    for sx in (-1, 1):
        out.append(wedge("brow", (0.072, 0.042, 0.032), (sx * 0.045, -0.268, 0.800), rot=(15, sx * 12, sx * -14), bev=0.013))
        out.append(E("cheek", (0.052, 0.062, 0.052), (sx * 0.068, -0.236, 0.705), seg=20, rings=12))
        out.append(E("jaw", (0.060, 0.07, 0.058), (sx * 0.058, -0.200, 0.664), seg=18, rings=10))
        out.append(E("pad", (0.036, 0.036, 0.030), (sx * 0.030, -0.322, 0.652), seg=18, rings=10))
        out.append(E("ear", (0.034, 0.018, 0.032), (sx * 0.088, -0.165, 0.880), rot=(0, sx * 30, 0), seg=14, rings=8))
    out.append(wedge("muzzle", (0.105, 0.095, 0.075), (0, -0.290, 0.672), bev=0.024))
    out.append(wedge("bridge", (0.062, 0.034, 0.12), (0, -0.288, 0.750), rot=(-34, 0, 0), bev=0.014))
    out.append(wedge("nose", (0.078, 0.036, 0.032), (0, -0.336, 0.690), rot=(-12, 0, 0), bev=0.013))
    out.append(E("chin", (0.040, 0.034, 0.026), (0, -0.290, 0.604), seg=16, rings=10))
    return out


def mane(rng):
    locks = []
    # four tiers radiating from the face over the front of the mass; each starts further out and lies
    # lower (less "out"), so the inner ruff overlaps the middle, the middle the outer
    tiers = [  # rho0, count, length, width, thickness, out
        (0.108, 30, 0.090, 0.050, 0.034, 0.020),
        (0.150, 34, 0.135, 0.060, 0.038, 0.013),
        (0.196, 34, 0.180, 0.068, 0.040, 0.007),
        (0.242, 30, 0.170, 0.072, 0.042, 0.002),
    ]
    for ti, (rho0, n, ln, w, h, out) in enumerate(tiers):
        for i in range(n):
            a = math.radians(-180 + 360 * (i + 0.5 * (ti % 2)) / n) + rng.uniform(-0.04, 0.04)
            dirv = Vector((math.cos(a), 0, math.sin(a)))
            below = max(0.0, -math.sin(a))          # under the chin: the long chest locks
            L = ln * rng.uniform(0.85, 1.15) * (1.0 + 1.5 * below * (ti / 3.0 + 0.4))
            wav = rng.uniform(0.016, 0.026) * rng.choice((-1, 1))
            ctrl = []
            for k in range(6):
                t = k / 5
                rho = rho0 + L * t
                side = Vector((-dirv.z, 0, dirv.x)) * wav * math.sin(t * math.pi * 1.6)
                drop = Vector((0, 0, -0.08 * t * t * (0.25 + below)))
                q = FACE_C + dirv * rho + side + drop
                ctrl.append((q.x, q.z, out + 0.008 * max(0.0, t - 0.6) / 0.4))   # the tip curls off
            pts, nrm = [], []
            for c in spline(ctrl, 14):
                p, nn = hood_point(c.x, c.y, c.z)
                pts.append(p)
                nrm.append(nn)
            locks.append(ribbon("lock", pts, nrm, w * rng.uniform(0.85, 1.1), h, tip=0.12))
    # over the top, down the sides and the back of the neck to the withers (Steven: no smooth back)
    for row, (th0, n, ln) in enumerate(((0.15, 18, 0.85), (0.45, 22, 1.0), (0.80, 24, 1.1), (1.15, 24, 1.05), (1.5, 22, 0.8))):
        for i in range(n):
            phi = math.radians(62 + 236 * (i + 0.5 * (row % 2)) / (n - 1)) + rng.uniform(-0.05, 0.05)
            sway = rng.uniform(0.12, 0.22) * rng.choice((-1, 1))
            ctrl = [(th0 + ln * t, phi + sway * math.sin(t * 3.2 + i), 0.012 + 0.016 * (1 - t) - 0.004 * row + 0.014 * max(0.0, t - 0.7) / 0.3)
                    for t in (0, 0.2, 0.4, 0.6, 0.8, 1.0)]
            pts, nrm = [], []
            for c in spline(ctrl, 14):
                p, nn = hood_sph(min(c.x, 2.35), c.y, c.z)
                # past the hood's equator the locks drape onto the cape and shoulders: let them fall lower
                if c.x > 1.9:
                    p = p + Vector((0, 0, -(c.x - 1.9) * 0.12))
                pts.append(p)
                nrm.append(nn)
            locks.append(ribbon("back", pts, nrm, rng.uniform(0.085, 0.105), 0.055, tip=0.12))
    return locks


def tail():
    pts = [V(p) for p in [(0.0, 0.31, 0.06), (0.14, 0.33, 0.026), (0.30, 0.19, 0.022), (0.335, 0.0, 0.022), (0.32, -0.13, 0.026), (0.29, -0.21, 0.04)]]
    pts = spline(pts, 16)
    nrm = [Vector((0, 0, 1))] * len(pts)
    t = ribbon("tail", pts, nrm, 0.044, 0.040, tip=0.75, sides=12)
    E("tuft", (0.03, 0.042, 0.028), (0.285, -0.235, 0.045))
    return t


def cutters():
    """Boolean cutters carved out of the fused sculpt: crisp features smaller than the smoothing."""
    cs = []
    for sx in (-1, 1):
        # deep eye sockets tucked under the brow
        cs.append(E("socket", (0.022, 0.024, 0.0135), (sx * 0.047, -0.292, 0.763), rot=(0, sx * 14, sx * -8), seg=18, rings=10))
        # nostrils, under the sides of the nose
        cs.append(E("nostril", (0.011, 0.012, 0.008), (sx * 0.019, -0.362, 0.670), rot=(0, 0, sx * 25), seg=12, rings=8))
        # the mouth line, from the muzzle groove down and out to the corners under the cheeks
        pts = [V(p) for p in [(sx * 0.002, -0.336, 0.638), (sx * 0.025, -0.33, 0.632), (sx * 0.048, -0.31, 0.630), (sx * 0.066, -0.285, 0.636)]]
        cs.append(parts.tube_path("mouth", [tuple(p) for p in pts], 0.0035, seg=8))
    # the frown crease between the brows, and the groove splitting the muzzle pads
    cs.append(taper("crease", (0.0, -0.29, 0.825), (0.0, -0.302, 0.792), 0.0035, 0.002, seg=8))
    cs.append(taper("groove", (0.0, -0.352, 0.668), (0.0, -0.338, 0.640), 0.0035, 0.003, seg=8))
    return cs


def eyes():
    """The eyeballs in the sockets, a little recessed, with the upper lid's ridge."""
    out = []
    for sx in (-1, 1):
        out.append(E("eye", (0.0165, 0.010, 0.0105), (sx * 0.047, -0.272, 0.763), rot=(0, sx * 14, sx * -8), seg=16, rings=10))
    return out


# ------------------------------------------------------------------ materials
def gold_mat():
    m = mats.M("bronze", GOLD[2], 0.4, 0.75)
    geo = m.node("ShaderNodeNewGeometry")
    # pointiness: < 0.5 in hollows, > 0.5 on ridges; stretched to use the whole ramp (cavity + curvature)
    p = m.math("MULTIPLY_ADD", geo.outputs["Pointiness"], 5.0, -2.0)
    col = m.ramp(p, [(0.22, GOLD[0]), (0.42, GOLD[1]), (0.56, GOLD[2]), (0.78, GOLD[3])])
    var = m.noise(30.0, 3.0)
    fin = m.mix(m.math("MULTIPLY", var.outputs["Fac"], 0.18), col, GOLD[1])
    m.link(fin, m.bsdf.inputs["Base Color"])
    rough = m.ramp(p, [(0.3, "#a8a8a8"), (0.65, "#4a4a4a")])    # polished on the high points, dull in the hollows
    m.link(rough, m.bsdf.inputs["Roughness"])
    m.bump(m.noise(600.0, 2.0).outputs["Fac"], 0.06, 0.0005)    # the casting's fine grain
    return m.mat


def stone_mat():
    m = mats.M("stone", "#8d867b", 0.8)
    n = m.noise(25.0, 5.0)
    m.link(m.ramp(n.outputs["Fac"], [(0.35, "#7a7368"), (0.65, "#a19a8e")]), m.bsdf.inputs["Base Color"])
    m.bump(m.noise(300.0, 3.0).outputs["Fac"], 0.25, 0.0008)
    return m.mat


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
    """Voxel remesh (a union of every form). close > 0: a morphological closing first (grow by `close`,
    remesh, shrink back), which fills the creases where forms meet with clay-like fillets of that radius.
    Smooth-shaded, so the bake reads curved surfaces, not facets."""
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
    forms = remesh(join([o for o in core.mesh_objects() if o not in before], "forms"), FORM_VOXEL, 4, 0.6, close=0.018)
    before = set(core.mesh_objects())
    mane(rng)
    tail()
    detail = [o for o in core.mesh_objects() if o not in before]
    L = remesh(join([forms] + detail, "lion"), VOXEL, 2, 0.5)
    print("SCULPT body + mane fused: %d faces" % len(L.data.polygons))
    # the face: its own finer remesh, carved alone (a boolean on the whole sculpt runs out of memory),
    # then kept as a shell sitting in the mane (the bake reads both; the ruff covers the join)
    Hd = remesh(join(head(), "head"), HEAD_VOXEL, 3, 0.5, close=0.014)
    carve(Hd, cutters())
    print("SCULPT head carved: %d faces" % len(Hd.data.polygons))
    gm = gold_mat()
    ey = eyes()
    for ob in [Hd] + ey:          # the face sits a little proud of the (wider) mane, as in the picture
        ob.location.y -= HEAD_FWD
    for ob in [L, Hd] + ey:
        ob.data.materials.clear()
        ob.data.materials.append(gm)
    # plinth: a moulded cast-stone block
    st = stone_mat()
    w, d = PLINTH
    parts.box("plinth", (w - 0.04, d - 0.04, PZ - 0.08), loc=(0, 0.02, 0.04 + (PZ - 0.08) / 2), mat=st, bev=0.004)
    parts.box("plinthbase", (w + 0.02, d + 0.02, 0.05), loc=(0, 0.02, 0.025), mat=st, bev=0.006, seg=3)
    parts.box("plinthtop", (w, d, 0.035), loc=(0, 0.02, PZ - 0.0175), mat=st, bev=0.008, seg=3)
    parts.trim("ogee", [(0.0, 0.0), (-0.006, 0.006), (-0.008, 0.014), (-0.014, 0.02)], w - 0.03, loc=(0, 0.02 - d / 2 + 0.03, PZ - 0.035 - 0.02), mat=st)
