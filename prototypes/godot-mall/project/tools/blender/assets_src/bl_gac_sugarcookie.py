"""A sugar cookie from Great American Cookie Co. (1995 map, store smuopv1vy0). Hand item. Steven's pick.

A big round soft sugar cookie, pale golden with browned edges and a crackled top glittering with coarse
sugar, slid into a small white paper cookie sleeve so its front half shows. Lying flat on the counter,
the open end toward the customer. Plain white sleeve (no print documented, so none invented), with a
faint grease spot.

References: design/storefronts/great-american-cookie.md (the glass case of cookies, the record); no photo
of the cookie or the bag. Size: a mall "giant" cookie ~100 mm across, 11 mm thick; the sleeve 115 x 90 mm.
Guessed: the sleeve shape (a flat glassine-style pouch with a thumb notch), the colours.
Origin: bottom centre of the sleeve, lying flat; the open end faces Godot +Z.
"""
import math
import bmesh
import bpy
from mathutils import Vector
from lib import core, parts, mats

CR, CT = 0.050, 0.011          # cookie radius, thickness
SW, SL, ST = 0.118, 0.088, 0.0148   # sleeve width (X), length (Y), max thickness (Z)
CY = -0.026                    # cookie centre (Y): it sticks out of the open end at -Y
DOUGH = ["#c99a52", "#e6c483", "#f2dca6"]   # browned edge -> pale golden top

META = {
    "id": "bl_gac_sugarcookie",
    "class": "hand",
    "tex": 1024,
    "ao": 0.35,
    "refs": [],
    "item_file": "blender_props_2.json",
    "item": {"name": "Sugar cookie", "year": 1995, "store": "GREAT AMERICAN COOKIE CO",
             # lying on the top of the cookie case at its east end, beside the register, behind the front glass
             # (wave7.gd cookie(): co = P(W-0.6, 0, 2.6) = (-26.6, 0, 45.4), case top 0.85-0.86, register x -27.2..-28.1).
             # Workstream G is rebuilding the case: if its top height changes, change pos[1] to match.
             "place": {"wing": 2, "year": 1995, "pos": [-26.92, 0.862, 45.02], "yaw": 12}},
}


def cookie_mat():
    m = mats.M("cookie", DOUGH[2], 0.7)
    tc = m.coords()
    # radial browning: darker at the rim (distance from the cookie's axis)
    sep = m.node("ShaderNodeSeparateXYZ")
    m.link(tc, sep.inputs[0])
    dx = m.math("SUBTRACT", sep.outputs["X"], 0.0)
    dy = m.math("SUBTRACT", sep.outputs["Y"], CY)
    rr = m.math("SQRT", m.math("ADD", m.math("MULTIPLY", dx, dx), m.math("MULTIPLY", dy, dy)))
    rim = m.math("MULTIPLY", rr, 1.0 / CR)
    n = m.noise(140.0, 4.0, coord=tc)
    rimn = m.math("ADD", rim, m.math("MULTIPLY", n.outputs["Fac"], 0.12))
    col = m.ramp(rimn, [(0.70, DOUGH[2]), (0.86, DOUGH[1]), (1.02, DOUGH[0])])
    # the crackle of a soft sugar cookie
    cr = m.node("ShaderNodeTexVoronoi", Scale=48.0)
    cr.feature = "DISTANCE_TO_EDGE"
    m.link(tc, cr.inputs["Vector"])
    crack = m.ramp(cr.outputs["Distance"], [(0.0, "#000000"), (0.025, "#ffffff")])
    patchy = m.math("GREATER_THAN", m.noise(30.0, 2.0, coord=tc).outputs["Fac"], 0.52)   # only some cells crack
    cmask = m.math("MULTIPLY", m.math("MULTIPLY", m.math("SUBTRACT", 1.0, crack), patchy), 0.45)
    col2 = m.mix(cmask, col, "#c08c46")
    # coarse sugar: bright crystals scattered over the top
    sug = m.node("ShaderNodeTexVoronoi", Scale=1100.0)
    m.link(tc, sug.inputs["Vector"])
    sp = m.math("LESS_THAN", sug.outputs["Distance"], 0.16)
    col3 = m.mix(sp, col2, "#fffdf4")
    m.link(col3, m.bsdf.inputs["Base Color"])
    m.link(m.ramp(sp, [(0.0, "#c4c4c4"), (1.0, "#1a1a1a")]), m.bsdf.inputs["Roughness"])   # crystals glint
    h = m.math("SUBTRACT", m.math("MULTIPLY", sp, 0.6), cmask)
    m.bump(h, 0.6, 0.0006)
    return m.mat


def sleeve_mat():
    m = mats.M("sleeve", "#f6f4ee", 0.6)
    tc = m.coords()
    # paper fibre and a soft grease spot near the cookie
    m.bump(m.noise(500.0, 3.0, coord=tc).outputs["Fac"], 0.12, 0.0003)
    sep = m.node("ShaderNodeSeparateXYZ")
    m.link(tc, sep.inputs[0])
    dx = m.math("SUBTRACT", sep.outputs["X"], 0.022)
    dy = m.math("SUBTRACT", sep.outputs["Y"], 0.004)
    rr = m.math("SQRT", m.math("ADD", m.math("MULTIPLY", dx, dx), m.math("MULTIPLY", dy, dy)))
    n = m.noise(90.0, 3.0, coord=tc)
    spot = m.ramp(m.math("ADD", rr, m.math("MULTIPLY", n.outputs["Fac"], 0.01)), [(0.012, "#ffffff"), (0.022, "#000000")])
    col = m.mix(m.math("MULTIPLY", spot, 0.5), "#f6f4ee", "#d9d2bd")
    m.link(col, m.bsdf.inputs["Base Color"])
    return m.mat


def sleeve():
    """A flat paper pouch: a lens-shaped section (two shallow arcs) along Y, closed and pinched at +Y,
    open at -Y with a thumb notch cut in the top layer."""
    bm = bmesh.new()
    nx, ny = 18, 10
    rows = []
    for j in range(ny + 1):
        y = SL / 2 - SL * j / ny
        pinch = min(1.0, (SL / 2 - y) / 0.012)            # the folded bottom at +Y is flat
        open_end = j == ny
        top, bot = [], []
        for i in range(nx + 1):
            x = -SW / 2 + SW * i / nx
            # flat over the cookie, rounding down to the side seams over the last 13 mm
            e = max(0.0, min(1.0, (SW / 2 - abs(x)) / 0.013))
            s = math.sin(e * math.pi / 2)
            th = ST * s * pinch
            ztop = 0.0005 + th
            if open_end:
                # the thumb notch: a dip in the top layer's edge
                ztop -= 0.0 if abs(x) > 0.02 else 0.0
            top.append(bm.verts.new((x, y, ztop)))
            bot.append(bm.verts.new((x, y, 0.0005 + 0.0008 * s * pinch)))
        rows.append((top, bot))
    for j in range(ny):
        (t0, b0), (t1, b1) = rows[j], rows[j + 1]
        for i in range(nx):
            bm.faces.new((t0[i], t1[i], t1[i + 1], t0[i + 1]))
            bm.faces.new((b0[i], b0[i + 1], b1[i + 1], b1[i]))
    # side seams: join top and bottom along both long edges
    for j in range(ny):
        (t0, b0), (t1, b1) = rows[j], rows[j + 1]
        bm.faces.new((t0[0], b0[0], b1[0], t1[0]))
        bm.faces.new((t0[-1], t1[-1], b1[-1], b0[-1]))
    t0, b0 = rows[0]
    for i in range(nx):
        bm.faces.new((t0[i], t0[i + 1], b0[i + 1], b0[i]))
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0002)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    ob = core.obj_from_bmesh("sleeve", bm, sleeve_mat(), smooth=True)
    core.solidify(ob, 0.0004, 1.0)
    # the thumb notch: a half-moon cut-out in the top layer, made by a boolean
    cut = parts.cylinder("notch", 0.014, 0.03, verts=20, loc=(0.0, -SL / 2, ST * 0.8), bev=0)
    bo = ob.modifiers.new("Notch", "BOOLEAN")
    bo.operation = "DIFFERENCE"
    bo.object = cut
    bo.solver = "EXACT"
    core.apply_all(ob)
    bpy.data.objects.remove(cut)
    return ob


def build():
    sleeve()
    # the cookie: a soft domed disc with a rounded, slightly spread edge, lying in the sleeve
    prof = [(0.0, 0.0012), (CR - 0.004, 0.0012), (CR - 0.0008, 0.0030), (CR, 0.0055), (CR - 0.0012, 0.0090),
            (CR - 0.006, 0.0112), (CR * 0.6, 0.0122), (0.0, 0.0128)]
    ck = parts.lathe("cookie", prof, seg=48, loc=(0, CY, 0.0004), mat=cookie_mat())
    tex = bpy.data.textures.new("ckl", "CLOUDS")
    tex.noise_scale = 0.012
    d = ck.modifiers.new("Lumps", "DISPLACE")
    d.texture = tex
    d.texture_coords = "OBJECT"
    d.strength = 0.0012
    core.subsurf(ck, 1)
