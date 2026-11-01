"""Kitbash parts: small, parametric, real-size pieces that assets combine.

Every function returns a linked mesh object with modifiers still live (call core.apply_all or let the
build driver apply them). Sizes are metres; rotations degrees. All parts are built around their own
origin; `loc` moves them.

Parts: box, rounded_panel, cylinder, sphere, lathe, tube_path, screw, button, keypad, trim, fabric_fold,
label_plate, grille, antenna.
"""
import math
import bmesh
import bpy
from mathutils import Vector, Matrix

from . import core


def box(name, size, loc=(0, 0, 0), rot=(0, 0, 0), mat=None, bev=0.002, seg=2, origin="center"):
    """A box `size`=(x,y,z). origin 'center' or 'bottom' (sits on z=0). Bevelled unless bev=0."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    sx, sy, sz = size
    dz = sz / 2 if origin == "bottom" else 0.0
    bmesh.ops.transform(bm, matrix=Matrix.Translation((0, 0, dz)) @ Matrix.Diagonal((sx, sy, sz, 1)), verts=bm.verts)
    ob = core.obj_from_bmesh(name, bm, mat)
    core.place(ob, loc, rot)
    if bev > 0:
        core.bevel(ob, bev, seg)
    return ob


def _rounded_rect(w, h, r, seg):
    r = min(r, w / 2 - 1e-4, h / 2 - 1e-4)
    pts = []
    for cx, cy, a0 in ((w / 2 - r, h / 2 - r, 0), (-w / 2 + r, h / 2 - r, 90), (-w / 2 + r, -h / 2 + r, 180), (w / 2 - r, -h / 2 + r, 270)):
        for i in range(seg + 1):
            a = math.radians(a0 + 90 * i / seg)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def rounded_panel(name, w, h, depth, r=0.01, seg=4, loc=(0, 0, 0), rot=(0, 0, 0), mat=None, bev=0.0015, plane="XZ"):
    """A slab with rounded corners: w x h in `plane` ('XZ' = facing -Y, 'XY' = lying flat), depth thick."""
    bm = bmesh.new()
    vs = [bm.verts.new((x, y, -depth / 2)) for x, y in _rounded_rect(w, h, r, seg)]
    f = bm.faces.new(vs)
    ext = bmesh.ops.extrude_face_region(bm, geom=[f])
    bmesh.ops.translate(bm, vec=(0, 0, depth), verts=[e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    if plane == "XZ":
        bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(math.radians(90), 4, "X"))
    ob = core.obj_from_bmesh(name, bm, mat)
    core.place(ob, loc, rot)
    if bev > 0:
        core.bevel(ob, bev, 2, angle=60)
    return ob


def cylinder(name, r, depth, verts=24, loc=(0, 0, 0), rot=(0, 0, 0), mat=None, bev=0.001, r2=None, smooth=True):
    """A cylinder (or cone frustum with r2) along Z, centred."""
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=verts, radius1=r, radius2=r if r2 is None else r2, depth=depth)
    ob = core.obj_from_bmesh(name, bm, mat, smooth=smooth)
    ob.data.set_sharp_from_angle(angle=math.radians(40))
    core.place(ob, loc, rot)
    if bev > 0:
        core.bevel(ob, bev, 2, angle=40)
    return ob


def sphere(name, r, seg=24, rings=12, loc=(0, 0, 0), mat=None, scale=(1, 1, 1)):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=rings, radius=r)
    bmesh.ops.scale(bm, vec=scale, verts=bm.verts)
    ob = core.obj_from_bmesh(name, bm, mat, smooth=True)
    core.place(ob, loc)
    return ob


def lathe(name, profile, seg=24, loc=(0, 0, 0), rot=(0, 0, 0), mat=None, sharp_angle=40.0, cap=True):
    """Spin a profile [(radius, z), ...] (bottom to top) around Z. Radius 0 points close the ends."""
    bm = bmesh.new()
    rings = []
    for (r, z) in profile:
        if r <= 1e-6:
            rings.append([bm.verts.new((0, 0, z))])
        else:
            rings.append([bm.verts.new((r * math.cos(core.TAU * i / seg), r * math.sin(core.TAU * i / seg), z)) for i in range(seg)])
    for a, b in zip(rings, rings[1:]):
        if len(a) == 1 and len(b) == 1:
            continue
        for i in range(seg):
            if len(a) == 1:
                bm.faces.new((a[0], b[i], b[(i + 1) % seg]))
            elif len(b) == 1:
                bm.faces.new((a[i], b[0], a[(i + 1) % seg]))
            else:
                bm.faces.new((a[i], a[(i + 1) % seg], b[(i + 1) % seg], b[i]))
    if cap:
        for ring, up in ((rings[0], False), (rings[-1], True)):
            if len(ring) > 1:
                f = bm.faces.new(ring if up else list(reversed(ring)))
                # fan the cap so no n-gon survives to export
                bmesh.ops.poke(bm, faces=[f])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    ob = core.obj_from_bmesh(name, bm, mat, smooth=True)
    ob.data.set_sharp_from_angle(angle=math.radians(sharp_angle))
    core.place(ob, loc, rot)
    return ob


def tube_path(name, points, radius, seg=8, mat=None, closed=False, taper=None):
    """A round tube along a 3D polyline (smoothed as a NURBS-ish poly curve). taper: list of radius scales."""
    cu = bpy.data.curves.new(name, "CURVE")
    cu.dimensions = "3D"
    cu.bevel_depth = radius
    cu.bevel_resolution = max(1, seg // 4)
    cu.resolution_u = 4
    cu.use_fill_caps = True
    sp = cu.splines.new("BEZIER")
    sp.bezier_points.add(len(points) - 1)
    for i, p in enumerate(points):
        bp = sp.bezier_points[i]
        bp.co = Vector(p)
        bp.handle_left_type = bp.handle_right_type = "AUTO"
        if taper:
            bp.radius = taper[i]
    sp.use_cyclic_u = closed
    ob = bpy.data.objects.new(name, cu)
    core.link(ob)
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg), depsgraph=dg)
    bpy.data.objects.remove(ob)
    m = bpy.data.objects.new(name, me)
    core.link(m)
    for p in me.polygons:
        p.use_smooth = True
    if mat:
        me.materials.append(mat)
    return m


def screw(name, r=0.0015, loc=(0, 0, 0), rot=(0, 0, 0), mat=None, kind="phillips"):
    """A pan-head screw head (dome) with a cross or slot, facing +Z before rotation."""
    h = r * 0.55
    prof = [(0, 0)] + [(r * math.cos(a), h * math.sin(a)) for a in [math.radians(t) for t in (0, 30, 60, 80)]] + [(0, h)]
    ob = lathe(name, prof, seg=12, mat=mat, cap=False)
    core.place(ob, loc, rot)
    return ob


def button(name, r=0.004, h=0.002, loc=(0, 0, 0), rot=(0, 0, 0), mat=None, seg=16):
    """A round push button with a soft top edge, facing +Z."""
    prof = [(0, 0), (r, 0), (r, h * 0.6), (r * 0.85, h), (0, h)]
    ob = lathe(name, prof, seg=seg, mat=mat, cap=False, sharp_angle=60)
    core.place(ob, loc, rot)
    return ob


def keypad(name, rows=4, cols=3, key=(0.008, 0.006, 0.002), pitch=(0.011, 0.009), loc=(0, 0, 0), rot=(0, 0, 0), mat=None, bev=0.0008):
    """A grid of bevelled keys on the XY plane (tops facing +Z), centred on loc. Built with an Array.
    key = (width, height in the grid's row direction, how far it stands proud). rot=(90,0,0) stands the
    pad on a front face (tops toward -Y = Godot +Z), rows running down."""
    k = box(name, key, mat=mat, bev=0, origin="bottom")
    core.bevel(k, bev, 2, angle=30)
    a1 = core.array(k, cols, constant=(pitch[0], 0, 0))
    a2 = core.array(k, rows, constant=(0, -pitch[1], 0))
    k.rotation_euler = [math.radians(a) for a in rot]
    off = Vector((-(cols - 1) * pitch[0] / 2, (rows - 1) * pitch[1] / 2, 0))
    off.rotate(k.rotation_euler)
    k.location = Vector(loc) + off
    return k


def trim(name, profile, length, loc=(0, 0, 0), rot=(0, 0, 0), mat=None):
    """A molding: a 2D profile [(y, z), ...] (open, outer edge) extruded `length` along X."""
    bm = bmesh.new()
    a = [bm.verts.new((-length / 2, y, z)) for y, z in profile]
    b = [bm.verts.new((length / 2, y, z)) for y, z in profile]
    for i in range(len(profile) - 1):
        bm.faces.new((a[i], a[i + 1], b[i + 1], b[i]))
    ob = core.obj_from_bmesh(name, bm, mat, smooth=True)
    ob.data.set_sharp_from_angle(angle=math.radians(35))
    core.place(ob, loc, rot)
    return ob


def fabric_fold(name, w, h, folds=5, amp=0.01, thick=0.002, loc=(0, 0, 0), rot=(0, 0, 0), mat=None, res=(24, 16)):
    """A hanging cloth panel in XZ with vertical sine folds deepening toward the bottom."""
    bm = bmesh.new()
    nx, nz = res
    grid = []
    for j in range(nz + 1):
        z = -h * j / nz
        row = []
        for i in range(nx + 1):
            x = -w / 2 + w * i / nx
            y = amp * (0.35 + 0.65 * j / nz) * math.sin(folds * math.pi * i / nx)
            row.append(bm.verts.new((x, y, z)))
        grid.append(row)
    for j in range(nz):
        for i in range(nx):
            bm.faces.new((grid[j][i], grid[j][i + 1], grid[j + 1][i + 1], grid[j + 1][i]))
    ob = core.obj_from_bmesh(name, bm, mat, smooth=True)
    core.solidify(ob, thick, 0)
    core.place(ob, loc, rot)
    return ob


def label_plate(name, w, h, t=0.0005, loc=(0, 0, 0), rot=(0, 0, 0), mat=None):
    """A thin label/plate in XZ facing -Y (Godot +Z). UVs fill 0-1 so an image can go on it."""
    ob = box(name, (w, t, h), loc, rot, mat, bev=0)
    return ob


def grille(name, w, h, slots=8, slot_w=0.0015, depth=0.001, loc=(0, 0, 0), rot=(0, 0, 0), mat=None):
    """Speaker-grille slots: a row of thin bars standing proud of a panel (XZ, facing -Y)."""
    pitch = w / slots
    b = box(name, (slot_w, depth, h), mat=mat, bev=0)
    core.array(b, slots, constant=(pitch, 0, 0))
    b.location = Vector(loc) + Vector((-(slots - 1) * pitch / 2, 0, 0))
    b.rotation_euler = [math.radians(a) for a in rot]
    return b


def antenna(name, r0=0.006, r1=0.003, length=0.12, segments=3, loc=(0, 0, 0), mat=None):
    """A rubber-duck / telescoping antenna along +Z, stepping down in radius."""
    prof = []
    z = 0.0
    for i in range(segments):
        r = r0 + (r1 - r0) * i / max(1, segments - 1)
        prof += [(r, z), (r, z + length / segments * 0.98)]
        z += length / segments
    prof = [(0, 0)] + prof + [(r1 * 0.8, z), (0, z + r1 * 0.5)]
    return lathe(name, prof, seg=12, loc=loc, mat=mat)
