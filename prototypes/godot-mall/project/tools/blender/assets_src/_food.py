"""Shared helpers for workstream FOOD's food, drink and bar models (not an asset: no META).

- `svg_letters(obj, h_px, fill)`: a traced lettering path from tools/stores/cd7_letters.json (Corn Dog 7's
  own sign lettering, traced from Steven's photo) rendered to an RGBA image.
- `wrap_mat(name, png, z0, z1, base)`: a printed wrap mapped round a part by angle and height (cylindrical
  projection in nodes, as bl_oj_cup.py).
- `stripe_straw_mat`, `ceramic_mat`, `paper_mat`: the common materials.
- `fry(name, ...)`: one fry (straight or crinkle-cut cross-section) bent a little, as one closed mesh.
- `lump(ob, size, depth)`: a Clouds Displace for organic surfaces.
"""
import io
import json
import math
import os
import random

import bmesh
import bpy
from mathutils import Matrix, Vector
from PIL import Image

from lib import core, mats, labels

LETTERS = os.path.join(labels.PROJ, "tools", "stores", "cd7_letters.json")


def svg_letters(obj, h_px, fill="#1b2466", extra=""):
    """Render one traced lettering object ({'w','h','p'}) h_px tall. extra: more SVG drawn in its frame."""
    import cairosvg
    w, h, p = obj["w"], obj["h"], obj["p"]
    wp = int(w / h * h_px)
    svg = ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %s %s">'
           '<path d="%s" fill="%s" fill-rule="evenodd"/>%s</svg>') % (wp, h_px, w, h, p, fill, extra)
    return Image.open(io.BytesIO(cairosvg.svg2png(bytestring=svg.encode()))).convert("RGBA")


def cd7():
    with open(LETTERS) as f:
        return json.load(f)


def cyl_uv(m, z0, z1, u_off=0.0):
    """(u, v) sockets: u = angle round Z (0..1, seam at -X), v = height between z0 and z1."""
    sep = m.node("ShaderNodeSeparateXYZ")
    m.link(m.coords(), sep.inputs[0])
    ang = m.math("ARCTAN2", sep.outputs["Y"], sep.outputs["X"])
    u = m.math("FRACT", m.math("MULTIPLY_ADD", ang, 1.0 / math.tau, 0.5 + u_off))
    v = m.math("MULTIPLY_ADD", sep.outputs["Z"], 1.0 / (z1 - z0), -z0 / (z1 - z0))
    return u, v


def wrap_mat(name, png, z0, z1, base="#faf8f2", rough=0.45, u_off=0.25, frozen=False):
    """A material whose colour is `png` wrapped once round Z between heights z0 and z1 (image u = angle:
    the image's centre faces -Y, the front)."""
    m = mats.M(name, base, rough, frozen=frozen)
    u, v = cyl_uv(m, z0, z1, u_off)
    cv = m.node("ShaderNodeCombineXYZ")
    m.link(u, cv.inputs[0])
    m.link(v, cv.inputs[1])
    tex = m.node("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(png, check_existing=True)
    tex.extension = "EXTEND"
    m.link(cv.outputs[0], tex.inputs["Vector"])
    m.link(tex.outputs["Color"], m.bsdf.inputs["Base Color"])
    m.bump(m.noise(600.0, 2.0).outputs["Fac"], 0.04, 0.0003)
    return m


def stripe_straw_mat(name, base="#f6f4ee", stripe="#d01c24", turns=3.0, pitch=120.0):
    sm = mats.M(name, base, 0.35)
    sep = sm.node("ShaderNodeSeparateXYZ")
    sm.link(sm.coords(), sep.inputs[0])
    ang = sm.math("ARCTAN2", sep.outputs["Y"], sep.outputs["X"])
    s = sm.math("GREATER_THAN", sm.math("SINE", sm.math("MULTIPLY_ADD", ang, turns, sm.math("MULTIPLY", sep.outputs["Z"], pitch))), 0.4)
    sm.link(sm.mix(s, base, stripe), sm.bsdf.inputs["Base Color"])
    return sm.mat


def ceramic_mat(name, base="#f4f1ea", rough=0.16, band=None, band_r=None):
    """Heavy restaurant china: glossy white, faint speckle. band=(hex, r0, r1): a coloured ring between
    radii r0 and r1 (on a plate's rim)."""
    m = mats.M(name, base, rough)
    n = m.noise(260.0, 2.0)
    col = m.ramp(n.outputs["Fac"], [(0.3, "#ece8de"), (0.7, base)])
    if band:
        hexc, r0, r1 = band
        sep = m.node("ShaderNodeSeparateXYZ")
        m.link(m.coords(), sep.inputs[0])
        r = m.math("SQRT", m.math("ADD", m.math("MULTIPLY", sep.outputs["X"], sep.outputs["X"]),
                                   m.math("MULTIPLY", sep.outputs["Y"], sep.outputs["Y"])))
        inb = m.math("MULTIPLY", m.math("GREATER_THAN", r, r0), m.math("LESS_THAN", r, r1))
        col = m.mix(inb, col, hexc)
    m.link(col, m.bsdf.inputs["Base Color"])
    m.bump(n.outputs["Fac"], 0.04, 0.0002)
    return m.mat


def paper_mat(name, base="#f6f2e6", rough=0.8, grease=None):
    """Plain paper (napkin, liner); grease=(hex, scale): translucent grease spots."""
    m = mats.M(name, base, rough)
    n = m.noise(400.0, 4.0)
    col = m.ramp(n.outputs["Fac"], [(0.35, "#e8e2d2"), (0.65, base)])
    if grease:
        g = m.noise(grease[1], 3.0)
        gm = m.math("GREATER_THAN", g.outputs["Fac"], 0.62)
        col = m.mix(gm, col, grease[0])
    m.link(col, m.bsdf.inputs["Base Color"])
    m.bump(n.outputs["Fac"], 0.15, 0.0003)
    return m.mat


def crust_mat(name, stops, rough=0.55, scale=260.0, bump=0.4, dist=0.0008, specks=None):
    """A fried/baked surface: a noise ramp through `stops`, bump from the same noise; specks=(hex, scale,
    threshold) adds seasoning or char specks."""
    m = mats.M(name, stops[-1][1], rough)
    n = m.noise(scale, 6.0, 0.6)
    col = m.ramp(n.outputs["Fac"], stops)
    if specks:
        f = m.noise(specks[1], 1.0)
        fl = m.math("GREATER_THAN", f.outputs["Fac"], specks[2])
        col = m.mix(fl, col, specks[0])
    m.link(col, m.bsdf.inputs["Base Color"])
    m.bump(n.outputs["Fac"], bump, dist)
    return m


def section(kind, w, d, n=24, waves=4, amp=0.0009):
    """A fry's cross-section in XY: a rectangle w x d with soft corners; kind 'crinkle' adds `waves`
    full waves along each side (the crinkle knife's ridges run along the fry)."""
    pts = []
    per = n // 4
    for side in range(4):
        for i in range(per):
            t = i / per
            if side == 0:
                x, y, L, nx, ny = -w / 2 + w * t, -d / 2, w, 0, -1
            elif side == 1:
                x, y, L, nx, ny = w / 2, -d / 2 + d * t, d, 1, 0
            elif side == 2:
                x, y, L, nx, ny = w / 2 - w * t, d / 2, w, 0, 1
            else:
                x, y, L, nx, ny = -w / 2, d / 2 - d * t, d, -1, 0
            o = amp * math.sin(t * waves * math.tau) if kind == "crinkle" else 0.0
            # pull the corners in a little (cut edges soften in the fryer)
            c = 0.0006 * (1 - min(1, 6 * min(t, 1 - t))) if kind != "crinkle" else 0.0
            pts.append((x + nx * (o - c), y + ny * (o - c)))
    return pts


def fry(name, mat, length, w=0.0095, d=0.0095, kind="crinkle", rings=4, bend=0.004, twist=0.0,
        loc=(0, 0, 0), dirv=(0, 0, 1), roll=0.0, n=24, waves=4, amp=0.0009, seed=0, cap_bottom=True):
    """One fry: the cross-section swept along a gently bent line from loc in direction dirv. Tips taper and
    close with a poked cap. Returns the object (frozen=False; place before baking)."""
    rng = random.Random(seed)
    sec = section(kind, w, d, n, waves, amp)
    bm = bmesh.new()
    rr = []
    for j in range(rings + 1):
        t = j / rings
        z = length * t
        off = bend * math.sin(math.pi * t)
        tip = 1.0 - 0.18 * (max(0.0, abs(t - 0.5) * 2 - 0.75) / 0.25)    # the last 12% each end narrows
        s = tip * (1.0 + rng.uniform(-0.04, 0.04))
        a = twist * t
        ca, sa = math.cos(a), math.sin(a)
        rr.append([bm.verts.new(((x * ca - y * sa) * s + off, (x * sa + y * ca) * s, z)) for x, y in sec])
    for a, b in zip(rr, rr[1:]):
        for i in range(len(sec)):
            bm.faces.new((a[i], a[(i + 1) % len(sec)], b[(i + 1) % len(sec)], b[i]))
    for ring, up in ((rr[0], False), (rr[-1], True)):
        if not up and not cap_bottom:
            continue
        f = bm.faces.new(ring if up else list(reversed(ring)))
        bmesh.ops.poke(bm, faces=[f])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    ob = core.obj_from_bmesh(name, bm, mat, smooth=True)
    ob.data.set_sharp_from_angle(angle=math.radians(50))
    q = Vector(dirv).normalized().to_track_quat("Z", "Y")
    ob.matrix_world = Matrix.Translation(Vector(loc)) @ q.to_matrix().to_4x4() @ Matrix.Rotation(roll, 4, "Z")
    return ob


def lump(ob, size=0.01, depth=0.002, kind="CLOUDS", depth_n=2):
    tex = bpy.data.textures.new(ob.name + "_lump", kind)
    tex.noise_scale = size
    if hasattr(tex, "noise_depth"):
        tex.noise_depth = depth_n
    d = ob.modifiers.new("Lumps", "DISPLACE")
    d.texture = tex
    d.texture_coords = "OBJECT"
    d.strength = depth
    return d


def between(name, p0, p1, r, mat, verts=10, bev=0.0):
    """A cylinder from p0 to p1."""
    from lib import parts
    p0, p1 = Vector(p0), Vector(p1)
    dv = p1 - p0
    ob = parts.cylinder(name, r, dv.length, verts=verts, mat=mat, bev=bev)
    ob.location = (p0 + p1) / 2
    ob.rotation_euler = dv.to_track_quat("Z", "Y").to_euler()
    return ob


def cut(ob, co, no, fill_mat=None):
    """Cut a closed mesh by the plane (co, no), keep the side behind the normal, and close the hole with a
    face of fill_mat (e.g. a bun's crumb, a pickle's seeds). Modifiers are applied first."""
    core.apply_all(ob)
    me = ob.data
    if fill_mat is not None and fill_mat.name not in [m.name for m in me.materials]:
        me.materials.append(fill_mat)
    fi = [m.name for m in me.materials].index(fill_mat.name) if fill_mat is not None else 0
    bm = bmesh.new()
    bm.from_mesh(me)
    geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
    res = bmesh.ops.bisect_plane(bm, geom=geom, plane_co=co, plane_no=no, clear_outer=True)
    cut_edges = [e for e in res["geom_cut"] if isinstance(e, bmesh.types.BMEdge)]
    f = bmesh.ops.edgeloop_fill(bm, edges=cut_edges)
    faces = f["faces"]
    for fc in faces:
        fc.material_index = fi
        fc.smooth = False
    if faces:
        bmesh.ops.triangulate(bm, faces=faces)
    bm.to_mesh(me)
    bm.free()
    return ob


def oval_plate(name, mat, rx, ry, h=0.022, well=0.6, seg=40):
    """A heavy restaurant plate: foot ring, sloped well, flat rim with a rolled edge. ry/rx sets the oval."""
    from lib import parts
    r = rx
    prof = [(0.0, 0.0035), (r * 0.42, 0.0035), (r * 0.44, 0.0), (r * 0.50, 0.0), (r * 0.52, 0.004), (r * well + r * 0.08, h * 0.45),
            (r * 0.93, h * 0.82), (r * 0.985, h * 0.98), (r, h * 0.92), (r * 0.995, h * 0.80), (r * 0.94, h * 0.70),
            (r * well + r * 0.06, h * 0.30), (r * well, h * 0.22), (0.0, h * 0.22)]
    ob = parts.lathe(name, prof, seg=seg, mat=mat, cap=False)
    ob.scale = (1.0, ry / rx, 1.0)
    core.apply_all(ob)
    return ob, h * 0.22     # the well's top surface height


def disc_mat_radial(m, cx, cy):
    """(r, angle) sockets about (cx, cy) in object XY."""
    sep = m.node("ShaderNodeSeparateXYZ")
    m.link(m.coords("Object"), sep.inputs[0])
    lx = m.math("SUBTRACT", sep.outputs["X"], cx)
    ly = m.math("SUBTRACT", sep.outputs["Y"], cy)
    r = m.math("SQRT", m.math("ADD", m.math("MULTIPLY", lx, lx), m.math("MULTIPLY", ly, ly)))
    return r, m.math("ARCTAN2", ly, lx)
