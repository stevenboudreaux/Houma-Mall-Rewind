"""A gilded bronze lion seated on a plinth, one each side of The Lion's Share's door (1995 map, store n36).
Large fixture. The right-hand lion is the same model mirrored (scale x = -1), as in the 2D game.

Reference: the picture Steven put on the 2D game's front (index.html mall-data media "lion", 193 x 300,
extracted to refs: see META refs; the 2D front draws it "a bronze lion sitting on its plinth either side
of the door ... both looking straight out across the hall"). From it: a European seated lion, front legs
straight and together, heavy paws with the toes showing, haunches wide at the sides with the hind paws
forward, a deep mane of long separate S-curved locks framing the face (a ruff), falling over the
shoulders and down the chest to the elbows, a broad muzzle, heavy brow, the face calm and looking
straight ahead. Gold-bronze, darker in the hollows, bright on the high points.
Guessed: the size (lion ~0.95 m, on a 0.32 m plinth), the plinth (cast stone, moulded edges), the tail
(curled round the right hind paw, the usual pose), the back (not in the picture).

How: the body is ellipsoids and capsules; the mane a solid mass (the "hood") covered in ~140 tapered locks
that hug its surface in S-waves, radiating from the face; everything is fused with a
voxel remesh and smoothed, so it reads as one casting (~400k triangles). The budget copy is decimated to
22k triangles and the sculpt is baked onto it (normal, colour with cavity shading, AO): the hipoly path
of build.py, the standard sculpt workflow.
Origin: bottom centre of the plinth, facing Godot +Z.
"""
import math
import random
import bpy
from mathutils import Vector
from lib import core, parts, mats

PZ = 0.32                 # plinth height = the lion's seat
PLINTH = (0.72, 0.76)     # plinth top, x by y
VOXEL = 0.0042            # remesh resolution (the finest mane detail)
SEED = 7
GOLD = ["#3e2a12", "#7d5c26", "#b08a3e", "#d9b663"]   # hollows -> high points

META = {
    "id": "bl_ls_lion",
    "class": "large_fixture",
    "tex": 2048,
    "ao": 0.55,
    "hipoly": 22000,
    "cage": 0.012,
    "refs": [["design/storefronts/refs/lions-share-lion.png", None, "Steven's lion (index.html media)"]],
}


def E(name, r, c, rot=(0, 0, 0), seg=24, rings=14):
    ob = parts.sphere(name, 1.0, seg, rings, scale=r)
    core.place(ob, (c[0], c[1], PZ + c[2]), rot)
    return ob


def capsule(name, a, b, r):
    a = Vector((a[0], a[1], PZ + a[2]))
    b = Vector((b[0], b[1], PZ + b[2]))
    d = b - a
    ob = parts.cylinder(name, r, d.length, 20, bev=0)
    ob.location = (a + b) / 2
    ob.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
    E(name + "a", (r, r, r), (a.x, a.y, a.z - PZ), seg=16, rings=8)
    E(name + "b", (r, r, r), (b.x, b.y, b.z - PZ), seg=16, rings=8)
    return ob


def lock(name, pts, r0, r1=0.0035):
    pts = [(p[0], p[1], PZ + p[2]) for p in pts]
    n = len(pts)
    taper = [1.0 - (1.0 - r1 / r0) * (i / (n - 1)) ** 1.3 for i in range(n)]
    return parts.tube_path(name, pts, r0, seg=8, taper=taper)


# measured on the reference (193 x 300 px for ~0.95 m: 3.3 mm/px): full width 0.63 m (haunches), mane
# 0.47 m wide from the top of the head (0.95) to mid-chest (0.36), face 0.23 m wide, chin at 0.64,
# front legs ~0.09 m thick at x = +-0.07, paws 0.13 m wide
HOOD_C = Vector((0.0, -0.03, 0.67))     # the mane's mass (centre above the seat)
HOOD_R = Vector((0.25, 0.17, 0.30))
FACE = Vector((0.0, -0.20, 0.77))       # where the face meets the mane


def body():
    for sx in (-1, 1):
        E("haunch", (0.115, 0.20, 0.155), (sx * 0.205, 0.08, 0.15), rot=(-10, 0, 0))
        E("thigh", (0.07, 0.12, 0.06), (sx * 0.24, -0.05, 0.06), rot=(8, 0, sx * -6))
        E("hindpaw", (0.055, 0.09, 0.04), (sx * 0.255, -0.14, 0.038))
        capsule("foreleg", (sx * 0.068, -0.15, 0.06), (sx * 0.075, -0.08, 0.48), 0.046)
        E("forearm", (0.05, 0.055, 0.12), (sx * 0.072, -0.11, 0.30))
        E("forepaw", (0.06, 0.085, 0.042), (sx * 0.068, -0.19, 0.04))
        for k in range(4):   # toes along the front of each paw
            x = sx * 0.068 + (k - 1.5) * 0.026
            E("toe", (0.017, 0.024, 0.022), (x, -0.26, 0.028), seg=12, rings=8)
        for k in range(3):
            x = sx * 0.255 + (k - 1) * 0.024
            E("htoe", (0.016, 0.02, 0.019), (x, -0.225, 0.024), seg=12, rings=8)
    E("belly", (0.17, 0.21, 0.19), (0, 0.08, 0.24))
    E("chest", (0.14, 0.12, 0.18), (0, -0.05, 0.44))
    E("back", (0.15, 0.17, 0.17), (0, 0.13, 0.42), rot=(25, 0, 0))
    E("hood", tuple(HOOD_R), tuple(HOOD_C))
    E("bib", (0.18, 0.10, 0.13), (0, -0.12, 0.50))
    for sx in (-1, 1):
        E("shoulder", (0.10, 0.12, 0.14), (sx * 0.16, -0.06, 0.50))   # the mane widens toward the bottom (bell)


def head():
    E("skull", (0.10, 0.10, 0.095), (0, -0.17, 0.80))
    E("brow", (0.098, 0.045, 0.036), (0, -0.245, 0.838), rot=(10, 0, 0))
    E("forehead", (0.08, 0.05, 0.05), (0, -0.215, 0.875), rot=(25, 0, 0))
    E("muzzle", (0.072, 0.085, 0.052), (0, -0.295, 0.745))
    for sx in (-1, 1):
        E("cheek", (0.042, 0.045, 0.034), (sx * 0.043, -0.318, 0.733), seg=16, rings=10)
        E("browL", (0.036, 0.02, 0.018), (sx * 0.05, -0.282, 0.826), rot=(0, sx * -15, 0), seg=14, rings=8)
        E("jaw", (0.05, 0.06, 0.05), (sx * 0.07, -0.24, 0.72), seg=14, rings=8)
        E("ear", (0.03, 0.016, 0.032), (sx * 0.095, -0.17, 0.905), rot=(0, sx * 30, 0), seg=12, rings=8)
    capsule("bridge", (0, -0.27, 0.855), (0, -0.345, 0.776), 0.028)
    E("nose", (0.038, 0.017, 0.02), (0, -0.362, 0.772), seg=14, rings=8)
    E("chin", (0.042, 0.038, 0.03), (0, -0.30, 0.683), seg=14, rings=8)
    E("lip", (0.058, 0.03, 0.02), (0, -0.33, 0.707), seg=14, rings=8)


def eyes():
    """The eyeballs under the brow (set after the remesh, sharper than the voxel size)."""
    out = []
    for sx in (-1, 1):
        out.append(E("eye", (0.017, 0.01, 0.011), (sx * 0.05, -0.305, 0.808), rot=(0, sx * 12, 0), seg=14, rings=8))
    return out


def on_hood(x, z, out=0.006, rim=0.96):
    """The point on the front/side surface of the mane's mass at (x, z), pushed `out` metres off it.
    Points past the rim are pulled back onto it, so locks curl along the mane's edge, not out of it."""
    u = ((x - HOOD_C.x) / HOOD_R.x) ** 2 + ((z - HOOD_C.z) / HOOD_R.z) ** 2
    if u > rim:
        k = math.sqrt(rim / u)
        x = HOOD_C.x + (x - HOOD_C.x) * k
        z = HOOD_C.z + (z - HOOD_C.z) * k
        u = rim
    y = HOOD_C.y - HOOD_R.y * math.sqrt(1.0 - u)
    n = Vector(((x - HOOD_C.x) / HOOD_R.x ** 2, (y - HOOD_C.y) / HOOD_R.y ** 2, (z - HOOD_C.z) / HOOD_R.z ** 2)).normalized()
    return Vector((x, y, z)) + n * out


def mane(rng):
    locks = []
    # locks radiate from the face over the front of the mane, curving down and outward in S-waves,
    # three overlapping rings; under the chin they become the long chest locks ending in points
    for ring, (rho0, n, ln, r0) in enumerate([(0.125, 40, 0.15, 0.021), (0.165, 46, 0.19, 0.023), (0.205, 50, 0.20, 0.025), (0.245, 44, 0.16, 0.025)]):
        for i in range(n):
            a = math.radians(-180 + 360 * (i + 0.5 * (ring % 2)) / n) + rng.uniform(-0.05, 0.05)
            dirv = Vector((math.cos(a), 0, math.sin(a)))
            below = max(0.0, -math.sin(a))
            L = ln * rng.uniform(0.85, 1.2) * (1.0 + 1.6 * below)
            wav = rng.uniform(0.018, 0.03) * rng.choice((-1, 1))
            pts = []
            for k in range(8):
                t = k / 7
                rho = rho0 + L * t
                side = Vector((-dirv.z, 0, dirv.x)) * wav * math.sin(t * math.pi * 1.5)
                drop = Vector((0, 0, -0.10 * t * t * (0.3 + below)))
                q = FACE + dirv * rho + side + drop
                pts.append(on_hood(q.x, q.z, 0.004 + 0.01 * (1 - t)))
            locks.append(lock("lock", [(p.x, p.y, p.z) for p in pts], r0 * rng.uniform(0.85, 1.1), 0.004))
    # the sides and top: locks flowing back and down over the mass
    for i in range(26):
        t0 = i / 25
        a = math.radians(-200 + 220 * t0)          # from the left side over the top to the right side
        start = HOOD_C + Vector((HOOD_R.x * 0.95 * math.cos(a), 0.02, HOOD_R.z * 0.9 * math.sin(a) * 0.8 + 0.06))
        pts = [start + Vector((0.01 * math.cos(a), 0.05 * k, -0.06 * k)) for k in range(4)]
        locks.append(lock("side", [tuple(p) for p in pts], rng.uniform(0.03, 0.036), 0.006))
    # a tuft over the forehead
    for i in range(9):
        a = math.radians(-70 + 140 * i / 8)
        top = FACE + Vector((0.075 * math.sin(a), 0.01, 0.12))
        locks.append(lock("crown", [tuple(top), tuple(top + Vector((0.03 * math.sin(a), 0.03, 0.04))), tuple(top + Vector((0.05 * math.sin(a), 0.08, 0.035)))], 0.022))
    return locks


def tail():
    pts = [(0.0, 0.31, 0.06), (0.14, 0.32, 0.025), (0.30, 0.17, 0.02), (0.33, 0.0, 0.02), (0.31, -0.13, 0.025), (0.28, -0.21, 0.04)]
    t = lock("tail", pts, 0.022, 0.016)
    E("tuft", (0.028, 0.038, 0.026), (0.275, -0.235, 0.045))
    return t


def gold_mat():
    m = mats.M("bronze", GOLD[2], 0.55, 0.7)
    geo = m.node("ShaderNodeNewGeometry")
    # pointiness: < 0.5 in hollows, > 0.5 on ridges; stretch it to use the whole ramp
    p = m.math("MULTIPLY_ADD", geo.outputs["Pointiness"], 4.0, -1.5)
    col = m.ramp(p, [(0.25, GOLD[0]), (0.42, GOLD[1]), (0.55, GOLD[2]), (0.75, GOLD[3])])
    var = m.noise(30.0, 3.0)
    fin = m.mix(m.math("MULTIPLY", var.outputs["Fac"], 0.25), col, GOLD[1])
    m.link(fin, m.bsdf.inputs["Base Color"])
    rough = m.ramp(p, [(0.3, "#b3b3b3"), (0.6, "#6e6e6e")])
    m.link(rough, m.bsdf.inputs["Roughness"])
    m.bump(m.noise(600.0, 2.0).outputs["Fac"], 0.08, 0.0005)    # the casting's fine grain
    return m.mat


def stone_mat():
    m = mats.M("stone", "#8d867b", 0.8)
    n = m.noise(25.0, 5.0)
    m.link(m.ramp(n.outputs["Fac"], [(0.35, "#7a7368"), (0.65, "#a19a8e")]), m.bsdf.inputs["Base Color"])
    m.bump(m.noise(300.0, 3.0).outputs["Fac"], 0.25, 0.0008)
    return m.mat


def fuse(objs, name, voxel, smooth):
    """Join, voxel-remesh (a union of all the forms) and smooth with volume kept."""
    for o in objs:
        core.apply_all(o)
    core.select_only(objs, objs[0])
    with bpy.context.temp_override(active_object=objs[0], selected_editable_objects=objs, selected_objects=objs):
        bpy.ops.object.join()
    ob = objs[0]
    ob.name = name
    rm = ob.modifiers.new("Remesh", "REMESH")
    rm.mode = "VOXEL"
    rm.voxel_size = voxel
    if smooth:
        sm = ob.modifiers.new("Smooth", "LAPLACIANSMOOTH")
        sm.lambda_factor = 1.0
        sm.iterations = smooth
        sm.use_volume_preserve = True
        sm.use_normalized = True
    core.apply_all(ob)
    return ob


def build():
    rng = random.Random(SEED)
    # 1. the big forms, blended into each other like a sculptor's clay block
    before = set(core.mesh_objects())
    body()
    forms = fuse([o for o in core.mesh_objects() if o not in before], "forms", 0.008, 25)
    # 2. the face, the mane's locks and the tail go on top; a light pass fuses them
    before = set(core.mesh_objects())
    head()
    mane(rng)
    tail()
    detail = [o for o in core.mesh_objects() if o not in before]
    L = fuse([forms] + detail, "lion", VOXEL, 3)
    L.data.materials.clear()
    L.data.materials.append(gold_mat())
    for e in eyes():
        e.data.materials.append(L.data.materials[0])
    # plinth: a moulded cast-stone block
    st = stone_mat()
    w, d = PLINTH
    parts.box("plinth", (w - 0.04, d - 0.04, PZ - 0.08), loc=(0, 0.02, 0.04 + (PZ - 0.08) / 2), mat=st, bev=0.004)
    parts.box("plinthbase", (w + 0.02, d + 0.02, 0.05), loc=(0, 0.02, 0.025), mat=st, bev=0.006, seg=3)
    parts.box("plinthtop", (w, d, 0.035), loc=(0, 0.02, PZ - 0.0175), mat=st, bev=0.008, seg=3)
    parts.trim("ogee", [(0.0, 0.0), (-0.006, 0.006), (-0.008, 0.014), (-0.014, 0.02)], w - 0.03, loc=(0, 0.02 - d / 2 + 0.03, PZ - 0.035 - 0.02), mat=st)
