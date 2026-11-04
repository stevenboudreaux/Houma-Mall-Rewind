"""Shared shapes and finishes for Lynn's Interiors furniture (2026, wing 4_2026; design/lynns/inventory.md).

Used by the family generators _lynns_sofa.py and _lynns_bedroom.py and their variant scripts
(bl_ly_<family>_<variant>.py). Everything is in Blender axes (Z up, front = -Y = Godot +Z), metres,
origin at the bottom centre of the piece.

Shapes:
  soft_box     a rounded, crowned box made from its own quad lattice (cushions, arms, decks, mattresses,
               headboard panels): even quads, more rows near the edges, so it rounds without subdivision
  pillow       a throw pillow: a soft box with pinched corners and a deep crown
  outline_slab a flat 2D outline (front view) extruded to a depth, with bevelled edges (headboard rails,
               arched mirror frames, carved aprons)
  ring_slab    the band between an outline and its inset (a moulded frame round a panel or a mirror)
  welt         piping along a closed loop
  leg_*        tapered, turned, block, bun and splayed legs/feet
Finishes (procedural, baked to the atlas by the pipeline):
  fabric(kind, colour)  chenille / linen / tweed / boucle / velvet / leather
  wood(colour pair, along)  grain along X or Z
  paint(colour, wash)   painted / washed wood (grain showing through a colour)
"""
import math
import bmesh
from mathutils import Vector

from lib import core, parts, mats


# ---------------------------------------------------------------- shapes

def _spacing(n, bias=0.55):
    """n+1 positions in [-1, 1], closer together near the ends (rounded edges need the rows there)."""
    out = []
    for i in range(n + 1):
        t = i / n
        lin = 2 * t - 1
        cos = -math.cos(math.pi * t)
        out.append(bias * cos + (1 - bias) * lin)
    return out


def soft_box(name, size, r=0.03, crown=0.0, res=(10, 8, 4), mat=None, loc=(0, 0, 0), rot=(0, 0, 0),
             bulge=0.0, pinch=0.0, crown_bottom=0.0, sag=0.0, front_roll=0.0, smooth=True):
    """A rounded box w x d x h (x, y, z) centred on its own origin.
    r: edge radius; crown: top bulges up by this much in the middle; crown_bottom the same downward;
    bulge: the four sides bow out by this much at mid-height; pinch: corners drawn in (0-1, pillows);
    sag: the top dips in the middle of the front half (a sat-in seat); front_roll: the front top edge
    rolls forward/down (a waterfall seat edge). res: quads per side along x, y, z."""
    w, d, h = size
    nx, ny, nz = res
    hx, hy, hz = w / 2, d / 2, h / 2
    r = min(r, hx * 0.98, hy * 0.98, hz * 0.98)
    sx, sy, sz = _spacing(nx), _spacing(ny), _spacing(nz)
    bm = bmesh.new()
    vid = {}

    def vert(i, j, k):
        key = (i, j, k)
        if key in vid:
            return vid[key]
        p = Vector((sx[i] * hx, sy[j] * hy, sz[k] * hz))
        inner = Vector((hx - r, hy - r, hz - r))
        q = Vector((max(-inner.x, min(inner.x, p.x)), max(-inner.y, min(inner.y, p.y)), max(-inner.z, min(inner.z, p.z))))
        dv = p - q
        if dv.length > 1e-9:
            p = q + dv.normalized() * r
        u, v, t = p.x / hx, p.y / hy, p.z / hz
        if crown and t > 0:
            p.z += crown * (1 - u * u) * (1 - v * v) * t
        if crown_bottom and t < 0:
            p.z += crown_bottom * (1 - u * u) * (1 - v * v) * t
        if bulge:
            f = bulge * (1 - t * t)
            p.x += f * u * abs(u) ** 2
            p.y += f * v * abs(v) ** 2
        if pinch:
            c = (u * u) * (v * v)
            p.z *= 1 - pinch * c
            p.x *= 1 - pinch * 0.08 * c
            p.y *= 1 - pinch * 0.08 * c
        if sag and t > 0:
            p.z -= sag * (1 - u * u) * max(0.0, -v) * t
        if front_roll and v < -0.5 and t > 0:
            p.z -= front_roll * ((-v - 0.5) / 0.5) ** 2 * t
        v_ = bm.verts.new(p)
        vid[key] = v_
        return v_

    def face(a, b, c, dd):
        bm.faces.new((a, b, c, dd))

    for i in range(nx):
        for j in range(ny):
            face(vert(i, j, nz), vert(i + 1, j, nz), vert(i + 1, j + 1, nz), vert(i, j + 1, nz))
            face(vert(i, j + 1, 0), vert(i + 1, j + 1, 0), vert(i + 1, j, 0), vert(i, j, 0))
    for i in range(nx):
        for k in range(nz):
            face(vert(i, 0, k), vert(i + 1, 0, k), vert(i + 1, 0, k + 1), vert(i, 0, k + 1))
            face(vert(i, ny, k + 1), vert(i + 1, ny, k + 1), vert(i + 1, ny, k), vert(i, ny, k))
    for j in range(ny):
        for k in range(nz):
            face(vert(0, j, k + 1), vert(0, j + 1, k + 1), vert(0, j + 1, k), vert(0, j, k))
            face(vert(nx, j, k), vert(nx, j + 1, k), vert(nx, j + 1, k + 1), vert(nx, j, k + 1))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    ob = core.obj_from_bmesh(name, bm, mat, smooth=smooth)
    core.place(ob, loc, rot)
    return ob


def pillow(name, w, h, t, mat, loc, rot, res=(9, 9, 3)):
    """A throw pillow standing up (w wide, h tall, t thick) at loc, leaning back by rot[0] degrees and
    turned by rot[2]. Its pattern coordinates are frozen while it stands at the origin, facing -Y, so a
    pillow_mat() pattern is centred on its face (x across, z up)."""
    ob = soft_box(name, (w, h, t), r=t * 0.45, crown=t * 0.38, crown_bottom=t * 0.38, pinch=0.8, res=res, mat=mat)
    ob.rotation_euler = (math.radians(90), 0, 0)
    core.freeze([ob])
    ob.rotation_euler = (math.radians(-rot[0]), math.radians(rot[1]), math.radians(rot[2]))
    ob.location = Vector(loc)
    return ob


def _poly_from_fn(fn, n):
    return [fn(i / n) for i in range(n)]


def outline_slab(name, pts, depth, mat=None, loc=(0, 0, 0), rot=(0, 0, 0), bev=0.006, bev_seg=3, plane="XZ"):
    """A closed 2D outline [(x, z), ...] (counter-clockwise, front view) extruded `depth` along Y (centred).
    The caps are ear-clipped (concave outlines are fine) so no n-gon reaches the export."""
    bm = bmesh.new()
    front = [bm.verts.new((x, -depth / 2, z)) for x, z in pts]
    back = [bm.verts.new((x, depth / 2, z)) for x, z in pts]
    n = len(pts)
    for i in range(n):
        a, b = i, (i + 1) % n
        bm.faces.new((front[a], front[b], back[b], back[a]))
    fc = bm.faces.new(list(reversed(front)))
    bc = bm.faces.new(back)
    # ear-clip the caps (outlines can be concave: arched bands, serpentine headboards)
    bmesh.ops.triangulate(bm, faces=[fc, bc], quad_method="BEAUTY", ngon_method="EAR_CLIP")
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    ob = core.obj_from_bmesh(name, bm, mat)
    core.place(ob, loc, rot)
    if bev > 0:
        core.bevel(ob, bev, bev_seg, angle=30)
    return ob


def ring_slab(name, outer, inner, depth, mat=None, loc=(0, 0, 0), rot=(0, 0, 0), bev=0.004, profile_round=True):
    """The band between two outlines with the same point count (a frame), extruded `depth` along Y."""
    assert len(outer) == len(inner)
    bm = bmesh.new()
    n = len(outer)
    of = [bm.verts.new((x, -depth / 2, z)) for x, z in outer]
    ob_ = [bm.verts.new((x, depth / 2, z)) for x, z in outer]
    inf = [bm.verts.new((x, -depth / 2, z)) for x, z in inner]
    ib = [bm.verts.new((x, depth / 2, z)) for x, z in inner]
    for i in range(n):
        a, b = i, (i + 1) % n
        bm.faces.new((of[a], of[b], ob_[b], ob_[a]))          # outer side
        bm.faces.new((ib[a], ib[b], inf[b], inf[a]))          # inner side
        bm.faces.new((inf[a], inf[b], of[b], of[a]))          # front face
        bm.faces.new((ob_[a], ob_[b], ib[b], ib[a]))          # back face
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    o = core.obj_from_bmesh(name, bm, mat)
    core.place(o, loc, rot)
    if bev > 0:
        core.bevel(o, bev, 3 if profile_round else 1, angle=30)
    return o


def offset_outline(pts, dist, smooth=3):
    """Inset (dist > 0) a counter-clockwise outline: each point moves along its inward normal, the normals
    averaged over +-smooth neighbours so sharp or wavy corners do not throw spikes."""
    n = len(pts)
    P = [Vector(p) for p in pts]
    nrm = []
    for i in range(n):
        e = (P[(i + 1) % n] - P[i - 1])
        nrm.append(Vector((-e.y, e.x)).normalized() if e.length > 1e-9 else Vector((0, 0)))
    out = []
    for i in range(n):
        acc = Vector((0, 0))
        for k in range(-smooth, smooth + 1):
            acc += nrm[(i + k) % n]
        acc = acc.normalized() if acc.length > 1e-9 else nrm[i]
        q = P[i] + acc * dist
        out.append((q.x, q.y))
    return out


def resample(pts, n):
    """Resample a closed outline to n points evenly by length (so an inset ring can pair points)."""
    P = [Vector(p) for p in pts] + [Vector(pts[0])]
    L = [0.0]
    for a, b in zip(P, P[1:]):
        L.append(L[-1] + (b - a).length)
    tot = L[-1]
    out = []
    j = 0
    for i in range(n):
        s = tot * i / n
        while L[j + 1] < s:
            j += 1
        t = (s - L[j]) / max(1e-9, L[j + 1] - L[j])
        q = P[j].lerp(P[j + 1], t)
        out.append((q.x, q.y))
    return out


def welt(name, loop, radius=0.0045, mat=None):
    """Piping along a closed 3D loop."""
    return parts.tube_path(name, loop, radius, seg=6, mat=mat, closed=True)


def rrect_loop(cx, cy, z, w, d, r, n_corner=3):
    """A rounded-rectangle loop at height z (for welts round a cushion's top or bottom edge)."""
    pts = []
    for (ax, ay, a0) in ((w / 2 - r, d / 2 - r, 0), (-w / 2 + r, d / 2 - r, 90), (-w / 2 + r, -d / 2 + r, 180), (w / 2 - r, -d / 2 + r, 270)):
        for i in range(n_corner + 1):
            a = math.radians(a0 + 90 * i / n_corner)
            pts.append((cx + ax + r * math.cos(a), cy + ay + r * math.sin(a), z))
    return pts


def leg_tapered(name, h, r0, r1, mat, loc, splay=0.0, sq=False):
    if sq:
        ob = parts.cylinder(name, r0, h, verts=4, mat=mat, r2=r1, smooth=False, bev=0.002)
        ob.rotation_euler = (0, 0, math.radians(45))
    else:
        ob = parts.cylinder(name, r0, h, verts=12, mat=mat, r2=r1, bev=0.001)
    ob.location = Vector((loc[0], loc[1], loc[2] + h / 2))
    if splay:
        ob.rotation_euler = (math.radians(splay[1]), math.radians(splay[0]), ob.rotation_euler[2])
    return ob


def leg_turned(name, h, r, mat, loc):
    """A turned leg: foot, cove, bead, taper (lathe)."""
    prof = [(0, 0), (r * 0.70, 0), (r * 0.80, h * 0.06), (r * 0.62, h * 0.14), (r * 0.95, h * 0.24), (r * 0.70, h * 0.32),
            (r * 0.85, h * 0.55), (r * 1.0, h * 0.82), (r * 0.80, h * 0.90), (r * 1.0, h * 0.94), (r * 1.0, h), (0, h)]
    return parts.lathe(name, prof, seg=12, loc=loc, mat=mat, sharp_angle=50)


def bun_foot(name, r, h, mat, loc):
    prof = [(0, 0), (r * 0.62, 0), (r * 0.92, h * 0.25), (r * 1.0, h * 0.5), (r * 0.9, h * 0.75), (r * 0.62, h * 0.9), (r * 0.7, h), (0, h)]
    return parts.lathe(name, prof, seg=14, loc=loc, mat=mat, sharp_angle=60)


def knob(name, r, mat, loc, kind="round"):
    """A drawer knob on a -Y face at loc (the face point)."""
    if kind == "round":
        prof = [(0, 0), (r * 0.45, 0), (r * 0.35, r * 0.6), (r * 0.9, r * 1.1), (r * 1.0, r * 1.5), (r * 0.7, r * 1.9), (0, r * 2.0)]
    else:   # medallion: a flat rosette disc
        prof = [(0, 0), (r * 1.0, 0), (r * 1.05, r * 0.25), (r * 0.8, r * 0.45), (r * 0.5, r * 0.55), (0, r * 0.6)]
    ob = parts.lathe(name, prof, seg=12, mat=mat)
    ob.rotation_euler = (math.radians(90), 0, 0)
    ob.location = Vector(loc)
    return ob


def bar_pull(name, w, mat, loc):
    bar = parts.cylinder(name, 0.006, w, verts=8, mat=mat, bev=0)
    bar.rotation_euler = (0, math.radians(90), 0)
    bar.location = Vector((loc[0], loc[1] - 0.028, loc[2]))
    feet = []
    for s in (-1, 1):
        f = parts.cylinder(name + "_post", 0.005, 0.028, verts=8, mat=mat, bev=0)
        f.rotation_euler = (math.radians(90), 0, 0)
        f.location = Vector((loc[0] + s * (w / 2 - 0.01), loc[1] - 0.014, loc[2]))
        feet.append(f)
    return [bar] + feet


def ring_pull(name, r, mat, loc):
    """A round ring pull (glam): a torus-ish lathe ring plus a back plate."""
    pts = []
    n = 16
    for i in range(n):
        a = core.TAU * i / n
        pts.append((loc[0] + r * math.cos(a), loc[1] - 0.012, loc[2] - r + r * math.sin(a)))
    ring = parts.tube_path(name, pts, 0.0035, seg=6, mat=mat, closed=True)
    plate = knob(name + "_rose", 0.012, mat, loc, kind="medallion")
    return [ring, plate]


# ---------------------------------------------------------------- finishes

FABRIC = {
    # kind: (weave scale, weave strength, mottling, roughness, sheen-ish rough range)
    "chenille": (900.0, 0.35, 0.10, 0.93),
    "linen": (1400.0, 0.25, 0.06, 0.88),
    "tweed": (700.0, 0.55, 0.22, 0.95),
    "boucle": (260.0, 0.85, 0.12, 0.97),
    "velvet": (1800.0, 0.10, 0.16, 0.78),
    "leather": (0.0, 0.0, 0.18, 0.48),
}


def fabric(name, base, kind="chenille", dark=None):
    """An upholstery fabric: a fine two-way weave (bump), soft mottling in colour, nap shading.
    leather: a pebbled grain (voronoi) with darker creases and a lower roughness."""
    scale, wstr, mott, rough = FABRIC[kind]
    m = mats.M(name, base, rough)
    tc = m.coords()
    dark = dark or _shade(base, 0.82)
    if kind == "leather":
        grain = m.voronoi(420.0, "F1", coord=tc)
        big = m.noise(6.0, 3.0, 0.6, coord=tc)
        crease = m.noise(28.0, 6.0, 0.7, coord=tc)
        h = m.math("ADD", m.math("MULTIPLY", grain.outputs["Distance"], 0.6), m.math("MULTIPLY", crease.outputs["Fac"], 0.4))
        m.bump(h, 0.22, 0.0008)
        col = m.ramp(m.math("ADD", m.math("MULTIPLY", big.outputs["Fac"], 0.7), m.math("MULTIPLY", crease.outputs["Fac"], 0.3)),
                     [(0.30, dark), (0.62, base), (0.80, _shade(base, 1.10))])
        m.link(col, m.bsdf.inputs["Base Color"])
        r = m.math("MULTIPLY_ADD", big.outputs["Fac"], 0.18, rough - 0.08)
        m.link(r, m.bsdf.inputs["Roughness"])
        return m.mat
    # the weave: two perpendicular sets of fine stretched noise
    mx = m.node("ShaderNodeMapping")
    mx.inputs["Scale"].default_value = (1.0, 6.0, 6.0)
    m.link(tc, mx.inputs["Vector"])
    my = m.node("ShaderNodeMapping")
    my.inputs["Scale"].default_value = (6.0, 1.0, 1.0)
    m.link(tc, my.inputs["Vector"])
    a = m.noise(scale / 6.0, 2.0, 0.5, coord=mx.outputs["Vector"])
    b = m.noise(scale / 6.0, 2.0, 0.5, coord=my.outputs["Vector"])
    weave = m.math("MULTIPLY", m.math("ADD", a.outputs["Fac"], b.outputs["Fac"]), 0.5)
    if kind == "boucle":
        loops = m.voronoi(scale, "F1", coord=tc)
        weave = m.math("ADD", m.math("MULTIPLY", weave, 0.4), m.math("MULTIPLY", loops.outputs["Distance"], 0.9))
    if kind == "tweed":
        fleck = m.noise(scale * 0.35, 1.0, 0.5, coord=tc)
        weave = m.math("ADD", weave, m.math("MULTIPLY", m.math("GREATER_THAN", fleck.outputs["Fac"], 0.68), 0.6))
    m.bump(weave, wstr, 0.0006)
    mot = m.noise(9.0, 3.0, 0.55, coord=tc)
    shade = m.math("ADD", m.math("MULTIPLY", mot.outputs["Fac"], mott * 4.0), m.math("MULTIPLY", weave, 0.5))
    stops = [(0.25, dark), (0.75, base), (1.0, _shade(base, 1.06))]
    if kind == "tweed":
        stops = [(0.30, _shade(base, 0.7)), (0.62, base), (0.86, _shade(base, 1.35))]
    col = m.ramp(shade, stops)
    m.link(col, m.bsdf.inputs["Base Color"])
    return m.mat


def wood(name, light, dark, along="X", ring_scale=14.0, rough=0.55, figure=1.0):
    """Wood grain: wave bands along `along`, warped by noise, between a dark and a light tone."""
    m = mats.M(name, light, rough)
    tc = m.coords()
    mp = m.node("ShaderNodeMapping")
    # stretch the pattern along the grain direction
    mp.inputs["Scale"].default_value = (0.12, 1.0, 1.0) if along == "X" else ((1.0, 1.0, 0.12) if along == "Z" else (1.0, 0.12, 1.0))
    m.link(tc, mp.inputs["Vector"])
    warp = m.noise(3.0, 4.0, 0.6, coord=mp.outputs["Vector"])
    wv = m.node("ShaderNodeTexWave", Scale=ring_scale, Distortion=2.2 * figure, Detail=2.0)
    # rings round the grain axis: lines along the grain on every face (front, top and sides)
    wv.wave_type = "RINGS"
    wv.rings_direction = along
    vec = m.node("ShaderNodeVectorMath")
    vec.operation = "ADD"
    m.link(mp.outputs["Vector"], vec.inputs[0])
    m.link(warp.outputs["Color"], vec.inputs[1])
    m.link(vec.outputs[0], wv.inputs["Vector"])
    pores = m.noise(260.0, 2.0, 0.5, coord=mp.outputs["Vector"])
    f = m.math("ADD", m.math("MULTIPLY", wv.outputs["Fac"], 0.75), m.math("MULTIPLY", pores.outputs["Fac"], 0.25))
    col = m.ramp(f, [(0.2, _mix(dark, light, 0.25)), (0.6, _mix(dark, light, 0.7)), (0.95, light)])
    m.link(col, m.bsdf.inputs["Base Color"])
    m.bump(pores.outputs["Fac"], 0.08, 0.0005)
    return m.mat


def paint(name, base, wash=0.0, rough=0.6, along="X", wood_dark="#6b5a48"):
    """Painted or washed wood: the colour over a faint grain (wash 0 = solid lacquer, 0.3+ = grey wash)."""
    m = mats.M(name, base, rough)
    tc = m.coords()
    mp = m.node("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (0.12, 1.0, 1.0) if along == "X" else (1.0, 1.0, 0.12)
    m.link(tc, mp.inputs["Vector"])
    warp = m.noise(3.0, 4.0, 0.6, coord=mp.outputs["Vector"])
    wv = m.node("ShaderNodeTexWave", Scale=16.0, Distortion=6.0, Detail=3.0)
    wv.wave_type = "RINGS"
    wv.rings_direction = along
    vec = m.node("ShaderNodeVectorMath")
    vec.operation = "ADD"
    m.link(mp.outputs["Vector"], vec.inputs[0])
    m.link(warp.outputs["Color"], vec.inputs[1])
    m.link(vec.outputs[0], wv.inputs["Vector"])
    if wash > 0:
        f = m.math("MULTIPLY", wv.outputs["Fac"], wash)
        col = m.mix(f, base, _mix(base, wood_dark, 0.55))
        m.link(col, m.bsdf.inputs["Base Color"])
        m.bump(wv.outputs["Fac"], 0.06 * wash, 0.0006)
    else:
        n = m.noise(400.0, 2.0, 0.5, coord=tc)
        m.bump(n.outputs["Fac"], 0.02, 0.0003)
    return m.mat


def pillow_mat(name, kind, c1, c2="#f0ebe0", fabric_kind="linen"):
    """A throw-pillow cover in pillow-local coordinates (see pillow(); frozen): 'solid', 'stripe' (vertical
    bands), 'medallion' (a round burst on a plain ground, 4413 t052), 'ikat' (blurred diamonds),
    'velvet' (solid, soft sheen)."""
    m = mats.M(name, c1, FABRIC.get(fabric_kind, FABRIC["linen"])[3], frozen=True)
    tc = m.coords()
    sep = m.node("ShaderNodeSeparateXYZ")
    m.link(tc, sep.inputs[0])
    weave = m.noise(1300.0, 2.0, 0.5, coord=tc)
    m.bump(weave.outputs["Fac"], 0.25 if fabric_kind != "velvet" else 0.05, 0.0005)
    if kind == "stripe":
        f = m.math("SINE", m.math("MULTIPLY", sep.outputs["X"], 52.0))
        jit = m.noise(60.0, 2.0, 0.5, coord=tc)
        f = m.math("ADD", f, m.math("MULTIPLY", jit.outputs["Fac"], 0.5))
        col = m.ramp(f, [(0.42, c2), (0.58, c1)])
    elif kind == "medallion":
        r = m.math("SQRT", m.math("ADD", m.math("POWER", sep.outputs["X"], 2.0), m.math("POWER", sep.outputs["Z"], 2.0)))
        petals = m.noise(90.0, 3.0, 0.6, coord=tc)
        burst = m.math("ADD", r, m.math("MULTIPLY", petals.outputs["Fac"], 0.05))
        col = m.ramp(burst, [(0.10, c1), (0.135, c2)])
    elif kind == "ikat":
        u = m.math("ABSOLUTE", m.math("SINE", m.math("MULTIPLY", sep.outputs["X"], 22.0)))
        v = m.math("ABSOLUTE", m.math("SINE", m.math("MULTIPLY", sep.outputs["Z"], 22.0)))
        jit = m.noise(30.0, 4.0, 0.7, coord=tc)
        f = m.math("ADD", m.math("ADD", u, v), m.math("MULTIPLY", jit.outputs["Fac"], 0.5))
        col = m.ramp(f, [(0.9, c1), (1.25, c2)])
    else:
        mot = m.noise(12.0, 3.0, 0.5, coord=tc)
        col = m.ramp(mot.outputs["Fac"], [(0.2, _shade(c1, 0.86)), (0.8, c1)])
    m.link(col, m.bsdf.inputs["Base Color"])
    return m.mat


def metal(name, base, rough=0.35, metalness=0.75):
    return mats.brushed_metal(name, base, rough, along="Z", metal=metalness)


def _hex(c):
    c = c.lstrip("#")
    return [int(c[i:i + 2], 16) for i in (0, 2, 4)]


def _shade(c, f):
    r, g, b = _hex(c)
    return "#%02x%02x%02x" % tuple(max(0, min(255, int(v * f))) for v in (r, g, b))


def _mix(a, b, t):
    A, B = _hex(a), _hex(b)
    return "#%02x%02x%02x" % tuple(int(x + (y - x) * t) for x, y in zip(A, B))
