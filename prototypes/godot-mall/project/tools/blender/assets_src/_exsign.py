"""Shared builder for the exterior department-store signs (Workstream EXT-SIGNS, Nov 9 2026;
design/exterior/signage-research.md, design/godot-exterior.md "EXT-SIGNS").

The construction copies the Cucos neon sign (tools/stores/signs/cucos_sign.gd): real geometry standing off the
wall, the parts a sign shop would make, proper materials, the light in its own channel. Here each letter is a
channel letter:

  return    the letter's sides, sheet metal `depth` deep, painted (baked into the atlas)
  trim cap  a thin rim round the face, a little wider than the face and just behind it (baked)
  face      the face: its own material, kept OUT of the atlas (mats bake=False) so the game can give it its
            emission (ex_sign_<sign>_face in tools/exterior/signs.gd, e_day / e_night)
  back      a closed back on each can (baked)
  mounting  either pins (studs) across a visible gap to the wall, or a raceway box the letters sit on

Axes (lib/core.py): the wall is the plane Blender y = 0; the sign stands out toward -Y (= Godot +Z, toward the
viewer). The origin is on the wall, centred on the sign horizontally and vertically: tools/exterior/signs.gd
places that point on the facade. Units are metres.
"""
import math
import os
import bmesh
import bpy
from mathutils import Matrix, Vector
from lib import core, mats

PROJ = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
FONTS = os.path.join(PROJ, "tools", "exterior", "signs_src")
MAX_TRIS = 6000       # the brief's budget per sign


def font(name):
    return bpy.data.fonts.load(os.path.join(FONTS, name), check_existing=True)


def _text_curve(txt, fnt, size, res=3, spacing=1.0):
    cu = bpy.data.curves.new("t_" + txt, "FONT")
    cu.body = txt
    cu.font = fnt
    cu.size = size
    cu.resolution_u = res
    cu.space_character = spacing
    cu.align_x = "CENTER"
    return cu


def cap_scale(fnt, ref="H"):
    """Height of the capital `ref` at font size 1 (so size = cap height / this)."""
    cu = _text_curve(ref, fnt, 1.0)
    ob = bpy.data.objects.new("_cap", cu)
    core.link(ob)
    bpy.context.view_layer.update()
    me = ob.evaluated_get(bpy.context.evaluated_depsgraph_get()).to_mesh()
    zs = [v.co.y for v in me.vertices]
    h = max(zs) - min(zs)
    ob.to_mesh_clear()
    bpy.data.objects.remove(ob)
    return h


def text_obj(name, txt, fnt, cap, extrude=0.0, offset=0.0, fill="BOTH", res=3, spacing=1.0, mat=None,
             y_front=0.0, cap_ref="H"):
    """The word as a mesh in the wall's plane (x along, z up), its front face at Blender y = y_front, extruded
    `extrude` back toward the wall. offset grows (+) or shrinks (-) the outline (the trim cap is the letter
    grown by its width). fill: BOTH / FRONT / BACK / NONE (which caps the extrusion keeps)."""
    size = cap / cap_scale(fnt, cap_ref)
    cu = _text_curve(txt, fnt, size, res, spacing)
    cu.extrude = extrude * 0.5
    cu.offset = offset
    cu.fill_mode = fill
    ob = bpy.data.objects.new(name, cu)
    core.link(ob)
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    bpy.data.objects.remove(ob)
    m = bpy.data.objects.new(name, me)
    core.link(m)
    # text lies in XY facing +Z; stand it up in XZ facing -Y, its front at y_front
    rot = Matrix.Rotation(math.radians(90.0), 4, "X")
    me.transform(rot)
    # after the rotation the extrusion runs y in [-extrude/2, +extrude/2] with the front at -extrude/2
    me.transform(Matrix.Translation((0.0, y_front + extrude * 0.5, 0.0)))
    if mat is not None:
        me.materials.append(mat)
    return m


def word_bounds(ob):
    xs = [v.co.x for v in ob.data.vertices]
    zs = [v.co.z for v in ob.data.vertices]
    return min(xs), max(xs), min(zs), max(zs)


def recentre(objs, ref):
    """Move every part so `ref`'s outline is centred on the origin (x and z)."""
    x0, x1, z0, z1 = word_bounds(ref)
    d = Vector((-(x0 + x1) * 0.5, 0.0, -(z0 + z1) * 0.5))
    for o in objs:
        o.data.transform(Matrix.Translation(d))
    return x1 - x0, z1 - z0


def islands(ob):
    """The letter's loose parts (a glyph, the dot of an i, the apostrophe): lists of (centroid, area, bbox)
    over the front-facing triangles of a flat face mesh."""
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bm.faces.ensure_lookup_table()
    seen = set()
    out = []
    for f in bm.faces:
        if f.index in seen:
            continue
        stack = [f]
        group = []
        seen.add(f.index)
        while stack:
            g = stack.pop()
            group.append(g)
            for e in g.edges:
                for h in e.link_faces:
                    if h.index not in seen:
                        seen.add(h.index)
                        stack.append(h)
        tris = []
        for g in group:
            c = g.calc_center_median()
            tris.append((c.copy(), g.calc_area()))
        xs = [t[0].x for t in tris]
        zs = [t[0].z for t in tris]
        area = sum(t[1] for t in tris)
        out.append({"tris": tris, "area": area, "bbox": (min(xs), max(xs), min(zs), max(zs))})
    bm.free()
    return out


def pins(face_ob, y_back, gap, mat, r=0.012, per_m=1.6):
    """Studs from the wall (y = 0) to each letter's back (y = y_back): one or two per glyph, more on wide
    ones, placed on the face's own triangles so they hide behind the letter. Returns the stud objects."""
    bm = bmesh.new()
    for isl in islands(face_ob):
        if isl["area"] < 0.002:
            continue
        x0, x1, z0, z1 = isl["bbox"]
        n = max(1, min(3, int(round((x1 - x0) * per_m))))
        if isl["area"] > 0.08 and n == 1:
            n = 2
        targets = [Vector((x0 + (x1 - x0) * (k + 0.5) / n, 0.0, (z0 + z1) * 0.5)) for k in range(n)]
        for tg in targets:
            best = min(isl["tris"], key=lambda t: (Vector((t[0].x, 0, t[0].z)) - tg).length - 2.0 * t[1])
            c = best[0]
            res = bmesh.ops.create_cone(bm, cap_ends=False, segments=6, radius1=r, radius2=r, depth=-y_back)
            for v in res["verts"]:
                v.co = Matrix.Rotation(math.radians(90.0), 3, "X") @ v.co
                v.co += Vector((c.x, y_back * 0.5, c.z))
    ob = core.obj_from_bmesh(face_ob.name + "_pins", bm, mat)
    return ob


def box(name, x0, x1, y0, y1, z0, z1, mat):
    bm = bmesh.new()
    res = bmesh.ops.create_cube(bm, size=1.0)
    for v in res["verts"]:
        v.co = Vector((x0 + (v.co.x + 0.5) * (x1 - x0), y0 + (v.co.y + 0.5) * (y1 - y0), z0 + (v.co.z + 0.5) * (z1 - z0)))
    return core.obj_from_bmesh(name, bm, mat)


def channel_word(txt, fnt, cap, depth, standoff, m_face, m_return, m_trim, m_back=None, trim_w=0.012,
                 res=3, spacing=1.0, cap_ref="H", face_proud=0.004, back=True):
    """One word of channel letters. The cans' backs at y = -standoff, the face plane at y = -(standoff+depth).
    Returns (parts, face_object)."""
    yf = -(standoff + depth)
    parts = []
    # the return: sides only, from the back to just behind the face
    ret = text_obj(txt + "_ret", txt, fnt, cap, extrude=depth - face_proud, fill="NONE", res=res, spacing=spacing,
                   mat=m_return, y_front=yf + face_proud, cap_ref=cap_ref)
    parts.append(ret)
    if back:
        bk = text_obj(txt + "_back", txt, fnt, cap, extrude=0.0, fill="BOTH", res=res, spacing=spacing,
                      mat=m_back or m_return, y_front=-standoff, cap_ref=cap_ref)
        # face the wall
        for p in bk.data.polygons:
            p.flip()
        parts.append(bk)
    # the trim cap: the outline grown by trim_w, a band face_proud deep round the face
    if trim_w > 0.0:
        trim = text_obj(txt + "_trim", txt, fnt, cap, extrude=face_proud, offset=trim_w, fill="FRONT", res=res,
                        spacing=spacing, mat=m_trim, y_front=yf + 0.0005, cap_ref=cap_ref)
        parts.append(trim)
    face = text_obj(txt + "_face", txt, fnt, cap, extrude=0.0, fill="BOTH", res=res, spacing=spacing,
                    mat=m_face, y_front=yf - 0.0005, cap_ref=cap_ref)
    parts.append(face)
    return parts, face


def ellipse_ring(name, rx, ry, rx2, ry2, y, mat, seg=48):
    """A flat elliptical ring (or a disc when rx2 = 0) in the wall's plane at depth y, facing -Y."""
    bm = bmesh.new()
    outer = [bm.verts.new((rx * math.cos(math.tau * i / seg), y, ry * math.sin(math.tau * i / seg))) for i in range(seg)]
    if rx2 <= 0.0:
        c = bm.verts.new((0.0, y, 0.0))
        for i in range(seg):
            bm.faces.new([c, outer[(i + 1) % seg], outer[i]])
    else:
        inner = [bm.verts.new((rx2 * math.cos(math.tau * i / seg), y, ry2 * math.sin(math.tau * i / seg))) for i in range(seg)]
        for i in range(seg):
            j = (i + 1) % seg
            bm.faces.new([outer[i], outer[j], inner[j], inner[i]])
    ob = core.obj_from_bmesh(name, bm, mat)
    _face_minus_y(ob)
    return ob


def ellipse_band(name, rx, ry, y0, y1, mat, seg=48):
    """The side (return) of an elliptical cabinet from y0 (wall side) to y1 (front), facing outward."""
    bm = bmesh.new()
    a = [bm.verts.new((rx * math.cos(math.tau * i / seg), y0, ry * math.sin(math.tau * i / seg))) for i in range(seg)]
    b = [bm.verts.new((rx * math.cos(math.tau * i / seg), y1, ry * math.sin(math.tau * i / seg))) for i in range(seg)]
    for i in range(seg):
        j = (i + 1) % seg
        bm.faces.new([a[i], a[j], b[j], b[i]])
    bm.normal_update()
    for f in bm.faces:
        c = f.calc_center_median()
        if f.normal.dot(Vector((c.x, 0.0, c.z))) < 0.0:
            f.normal_flip()
    ob = core.obj_from_bmesh(name, bm, mat, smooth=True)
    return ob


def _face_minus_y(ob):
    for p in ob.data.polygons:
        if p.normal.y > 0.0:
            p.flip()


def check(parts):
    n = 0
    for o in parts:
        o.data.calc_loop_triangles()
        n += len(o.data.loop_triangles)
    print("EXSIGN tris (before weld/triangulate): %d of %d" % (n, MAX_TRIS))
    if n > MAX_TRIS:
        raise SystemExit("OVER BUDGET: sign has %d triangles; the EXT-SIGNS budget is %d" % (n, MAX_TRIS))
    return n


def face_mat(name, colour, rough=0.35):
    """A letter face: flat, not baked (the game swaps in its own emissive ex_sign_* material by this name)."""
    return mats.M(name, colour, rough, 0.0, bake=False).mat


def paint(name, colour, rough=0.45, metal=0.0, grain=0.04):
    """Painted sheet metal for returns, backs and raceways: a faint orange-peel so it does not read as plastic."""
    m = mats.M(name, colour, rough, metal)
    n = m.noise(400.0, 2.0, coord=m.coords())
    m.bump(n.outputs["Fac"], grain, 0.0003)
    return m.mat


def logo_letters(path, k, depth, standoff, m_face, m_return, m_rim, rim_w=0.008, cx=None, cy=None):
    """Channel letters from a traced logo JSON (tools/stores/signs/*_logo.json: per letter `tris` (flat list
    of points) and `loops` (outer loops counter-clockwise, holes clockwise), in metres from the logo frame's
    bottom-left, `width` x `cap_h`), scaled by k and centred on (cx, cy) of that frame (default its middle).
    The face is flat (m_face, its own material), the return runs from the can's back (y = -standoff) to the
    face, and a rim of width rim_w edges the face just in front of it. Returns the parts and the face."""
    import json
    with open(path) as fh:
        J = json.load(fh)
    cx = float(J["width"]) * 0.5 if cx is None else cx
    cy = float(J["cap_h"]) * 0.5 if cy is None else cy
    yf = -(standoff + depth)
    P = lambda q, y: Vector(((float(q[0]) - cx) * k, y, (float(q[1]) - cy) * k))
    bf = bmesh.new()
    br = bmesh.new()
    bt = bmesh.new()
    for L in J["letters"]:
        tr = L["tris"]
        for i in range(0, len(tr), 3):
            vs = [bf.verts.new(P(tr[i + j], yf + 0.001)) for j in range(3)]
            f = bf.faces.new(vs)
            f.normal_update()
            if f.normal.y > 0.0:
                f.normal_flip()
        for lp in L["loops"]:
            n = len(lp)
            if n < 3:
                continue
            pts = [Vector((float(q[0]), float(q[1]))) for q in lp]
            # outward normal per vertex (outer loops ccw, holes cw: outward = right-hand side)
            vn = []
            for i in range(n):
                d0 = (pts[i] - pts[i - 1]).normalized()
                d1 = (pts[(i + 1) % n] - pts[i]).normalized()
                m = Vector((d0.y, -d0.x)) + Vector((d1.y, -d1.x))
                vn.append(m.normalized() if m.length > 1e-6 else Vector((d1.y, -d1.x)))
            for i in range(n):
                j = (i + 1) % n
                a0 = br.verts.new(P(pts[i], -standoff)); a1 = br.verts.new(P(pts[j], -standoff))
                b1 = br.verts.new(P(pts[j], yf)); b0 = br.verts.new(P(pts[i], yf))
                f = br.faces.new([a0, a1, b1, b0])
                f.normal_update()
                e = pts[j] - pts[i]
                out = Vector((e.y, 0.0, -e.x))
                if f.normal.dot(out) < 0.0:
                    f.normal_flip()
                ii = pts[i] - vn[i] * (rim_w / k)
                ij = pts[j] - vn[j] * (rim_w / k)
                r = [bt.verts.new(P(pts[i], yf)), bt.verts.new(P(pts[j], yf)), bt.verts.new(P(ij, yf)), bt.verts.new(P(ii, yf))]
                f = bt.faces.new(r)
                f.normal_update()
                if f.normal.y > 0.0:
                    f.normal_flip()
    face = core.obj_from_bmesh("logo_face", bf, m_face)
    ret = core.obj_from_bmesh("logo_return", br, m_return)
    rim = core.obj_from_bmesh("logo_rim", bt, m_rim)
    return [face, ret, rim], face


def contact_shadow(src, name, drop, side=0.0, y=-0.006, offset=0.0):
    """The sign's shadow on the wall: a copy of the face outline (src: a flat face object, or a list of them)
    moved down by `drop` (and across by `side`), flattened onto the wall at depth y. Its own material
    (`<asset>_shadow`, bake=False): the game draws it as a soft dark, see-through film (tools/exterior/signs.gd).
    The sun's real shadow does the same in an unbaked view; this keeps the gap legible once the wall is baked."""
    srcs = src if isinstance(src, (list, tuple)) else [src]
    bm = bmesh.new()
    for s in srcs:
        tmp = bmesh.new()
        tmp.from_mesh(s.data)
        for v in tmp.verts:
            v.co = Vector((v.co.x + side, y, v.co.z - drop))
        me = bpy.data.meshes.new("_tmp")
        tmp.to_mesh(me)
        tmp.free()
        bm.from_mesh(me)
        bpy.data.meshes.remove(me)
    for f in bm.faces:
        f.normal_update()
        if f.normal.y > 0.0:
            f.normal_flip()
    return core.obj_from_bmesh(name, bm, mats.M("shadow", "#000000", 1.0, 0.0, bake=False).mat)
