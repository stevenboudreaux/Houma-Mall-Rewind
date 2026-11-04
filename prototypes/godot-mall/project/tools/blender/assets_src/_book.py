"""Shared book model for B. Dalton's books (workstream FOOD, Nov 3 2026). Not an asset (no META).

One model, two bindings, so every book is built the same way and only its covers (and size) differ:
- "hard": a case binding. Two boards 2.6 mm thick with 3 mm squares past the page block on three sides,
  a rounded, backed spine, a hinge groove pressed into each board beside the spine, endpapers on the
  boards' insides, red-and-gold headbands at both ends of the spine, a concave fore-edge (the round of the
  spine pushes the page block's front edge in), optional ribbon marker. The case is one swept section, so
  the boards, groove and spine are one surface with bevelled corners.
- "paper": a perfect-bound paperback: a 0.5 mm cover wrapped flush round the page block, a squared spine
  with a scored hinge line on each side, a slight spring at the fore-edge.
Page edges carry fine page lines (normal map). Covers are painted with PIL by the asset (front, back, spine
images) and mapped by position; `gilt` masks (front/spine) make stamped gold foil metallic.

Axes: lying flat, front cover up (+Z), spine on the left (-X), the top of the book away from the viewer
(+Y), as bl_bd_paperback.py. Origin bottom centre.
"""
import math

import bmesh
import bpy
from mathutils import Vector

from lib import core, parts, mats, labels


def section_case(W, T, b, a, gd):
    """The case's cross-section (XZ) as one closed loop: front board top surface -> groove -> spine (outer)
    -> back board bottom -> fore-edge -> back board inside -> spine (inner) -> front board inside."""
    x0 = -W / 2
    pts = []
    # front board, top surface, from the fore-edge to the spine
    pts.append((W / 2, T))
    g0, g1 = x0 + 0.0095, x0 + 0.0055
    if gd:
        pts += [(g0, T), (g0 - 0.001, T - gd), (g1 + 0.001, T - gd), (g1, T)]
    n = 14
    for i in range(n + 1):                     # outer spine, top to bottom
        t = math.pi * i / n
        pts.append((x0 - a * math.sin(t), T / 2 + (T / 2) * math.cos(t)))
    if gd:
        pts += [(g1, 0.0), (g1 + 0.001, gd), (g0 - 0.001, gd), (g0, 0.0)]
    pts.append((W / 2, 0.0))
    pts.append((W / 2, b))                     # back board's fore-edge
    ai = max(0.0005, a - 0.0015)
    for i in range(n, -1, -1):                 # inner spine, bottom to top
        t = math.pi * i / n
        pts.append((x0 + 0.0012 - ai * math.sin(t), T / 2 + (T / 2 - b) * math.cos(t)))
    pts.append((W / 2, T - b))
    return pts


def section_block(W, T, b, a, sq, round_d):
    """The page block: spine side following the case's inner spine, a concave fore-edge."""
    x0 = -W / 2
    ai = max(0.0004, a - 0.0018)
    n = 14
    pts = []
    for i in range(n + 1):
        t = math.pi * i / n
        pts.append((x0 + 0.0016 - ai * math.sin(t), T / 2 + (T / 2 - b - 0.0002) * math.cos(t)))
    for i in range(n, -1, -1):
        t = math.pi * i / n
        pts.append((W / 2 - sq - round_d * math.sin(t), T / 2 + (T / 2 - b - 0.0002) * math.cos(t)))
    return pts


def sweep(name, sec, L, mat, rings=1):
    """Extrude a closed XZ section along Y from -L/2 to L/2, caps triangulated."""
    bm = bmesh.new()
    rr = []
    for j in range(rings + 1):
        y = -L / 2 + L * j / rings
        rr.append([bm.verts.new((x, y, z)) for x, z in sec])
    n = len(sec)
    for a, b in zip(rr, rr[1:]):
        for i in range(n):
            bm.faces.new((a[i], b[i], b[(i + 1) % n], a[(i + 1) % n]))
    caps = [bm.faces.new(list(reversed(rr[0]))), bm.faces.new(rr[-1])]
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bmesh.ops.triangulate(bm, faces=caps, quad_method="BEAUTY", ngon_method="EAR_CLIP")
    return core.obj_from_bmesh(name, bm, mat)


def img_alpha(m, path, center, size, plane, flip_u=False, facing=None):
    """An image's alpha, mapped by position like mats.decal (for gilt masks)."""
    a, b = {"XZ": ("X", "Z"), "XY": ("X", "Y"), "YZ": ("Y", "Z")}[plane]
    ia, ib = "XYZ".index(a), "XYZ".index(b)
    sep = m.node("ShaderNodeSeparateXYZ")
    m.link(m.coords("Object"), sep.inputs[0])
    su = -1.0 if flip_u else 1.0
    u = m.math("MULTIPLY_ADD", sep.outputs[a], su / size[0], 0.5 - su * center[ia] / size[0])
    v = m.math("MULTIPLY_ADD", sep.outputs[b], 1.0 / size[1], 0.5 - center[ib] / size[1])
    cv = m.node("ShaderNodeCombineXYZ")
    m.link(u, cv.inputs[0])
    m.link(v, cv.inputs[1])
    tex = m.node("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(path, check_existing=True)
    tex.extension = "CLIP"
    m.link(cv.outputs[0], tex.inputs["Vector"])
    al = tex.outputs["Alpha"]
    if facing:
        nrm = m.node("ShaderNodeSeparateXYZ")
        m.link(m.node("ShaderNodeTexCoord").outputs["Normal"], nrm.inputs[0])
        side = m.math("MULTIPLY", nrm.outputs[facing[1]], -1.0 if facing[0] == "-" else 1.0)
        al = m.math("MULTIPLY", al, m.math("GREATER_THAN", side, 0.5))
    return al


def pages_mat(name="pages", base="#ece3cc", lines=4200.0, edge=None):
    """Page edges: fine lines across the thickness, a little uneven; edge='#hex' tints them (stained edges)."""
    m = mats.M(name, base, 0.85)
    mp = m.node("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (1.0, 1.0, lines)
    m.link(m.coords(), mp.inputs["Vector"])
    n = m.noise(1.0, 2.0, coord=mp.outputs["Vector"])
    stops = [(0.35, "#d4c6a4"), (0.65, base)] if not edge else [(0.35, edge), (0.65, base)]
    col = m.ramp(n.outputs["Fac"], stops)
    dirt = m.noise(60.0, 3.0)
    col = m.mix(m.math("MULTIPLY", m.math("GREATER_THAN", dirt.outputs["Fac"], 0.68), 0.12), col, "#c8b898")
    m.link(col, m.bsdf.inputs["Base Color"])
    m.bump(n.outputs["Fac"], 0.35, 0.0003)
    return m.mat


def headband_mat():
    m = mats.M("headband", "#b8242a", 0.5)
    sep = m.node("ShaderNodeSeparateXYZ")
    m.link(m.coords(), sep.inputs[0])
    s = m.math("GREATER_THAN", m.math("SINE", m.math("MULTIPLY", sep.outputs["Z"], 2600.0)), 0.0)
    m.link(m.mix(s, "#b8242a", "#e8c860"), m.bsdf.inputs["Base Color"])
    m.bump(s, 0.3, 0.0003)
    return m.mat


def build_book(kind, W, L, T, front, back, spine, base="#334455", rough=0.4, cloth=False, gilt=None,
               endpaper="#efe6cf", page_edge=None, ribbon=None, spine_flip=True):
    """Make the book's parts. front/back/spine: PNG paths (RGBA; transparent = base colour). gilt: dict with
    any of 'front', 'spine' -> mask PNGs (alpha = foil). cloth: book cloth weave instead of a printed
    jacket's gloss. ribbon: '#hex' for a ribbon marker out of the tail (hard only)."""
    hard = kind == "hard"
    b = 0.0026 if hard else 0.00055
    a = 0.0055 if hard else 0.0009
    sq = 0.003 if hard else 0.0004
    m = mats.M("cover", base, rough)
    c = mats.decal(m, front, (0, 0, T), (W, L), "XY", facing="+Z")
    c = mats.decal(m, back, (0, 0, 0), (W, L), "XY", base=c, flip_u=True, facing="-Z")
    c = mats.decal(m, spine, (-W / 2 - a / 2, 0, T / 2), (L, T), "YZ", base=c, flip_u=spine_flip, facing="-X")
    if cloth:
        mp = m.node("ShaderNodeMapping")
        mp.inputs["Scale"].default_value = (2600.0, 2600.0, 2600.0)
        m.link(m.coords(), mp.inputs["Vector"])
        wv = m.node("ShaderNodeTexWave", Scale=1.0)
        m.link(mp.outputs["Vector"], wv.inputs["Vector"])
        wv2 = m.node("ShaderNodeTexWave", Scale=1.0)
        wv2.bands_direction = "Y"
        m.link(mp.outputs["Vector"], wv2.inputs["Vector"])
        weave = m.math("MULTIPLY", wv.outputs["Fac"], wv2.outputs["Fac"])
        bump = m.node("ShaderNodeBump", Strength=0.35, Distance=0.0003)
        m.link(weave, bump.inputs["Height"])
        nrm_out = bump.outputs["Normal"]
    else:
        n = m.noise(500.0, 2.0)
        bump = m.node("ShaderNodeBump", Strength=0.03, Distance=0.0003)
        m.link(n.outputs["Fac"], bump.inputs["Height"])
        nrm_out = bump.outputs["Normal"]
    if gilt:
        foil = None
        if gilt.get("front"):
            foil = img_alpha(m, gilt["front"], (0, 0, T), (W, L), "XY", facing="+Z")
        if gilt.get("spine"):
            fs = img_alpha(m, gilt["spine"], (-W / 2 - a / 2, 0, T / 2), (L, T), "YZ", flip_u=spine_flip, facing="-X")
            foil = fs if foil is None else m.math("MAXIMUM", foil, fs)
        m.link(m.mix(foil, c, "#d8b860"), m.bsdf.inputs["Base Color"])
        met = m.math("MULTIPLY", foil, 0.8)
        m.link(met, m.bsdf.inputs["Metallic"])
        m.link(m.math("SUBTRACT", rough, m.math("MULTIPLY", foil, rough - 0.25)), m.bsdf.inputs["Roughness"])
        # stamped foil sits a little below the cloth
        bump2 = m.node("ShaderNodeBump", Strength=0.6, Distance=0.0004)
        bump2.invert = True
        m.link(foil, bump2.inputs["Height"])
        m.link(nrm_out, bump2.inputs["Normal"])
        nrm_out = bump2.outputs["Normal"]
    m.link(nrm_out, m.bsdf.inputs["Normal"])
    endm = mats.M("endpaper", endpaper, 0.8).mat
    case = sweep("case", section_case(W, T, b, a, 0.0009 if hard else 0.00025), L, m.mat)
    # the boards' insides (seen at the squares) are endpaper
    me = case.data
    me.materials.append(endm)
    for p in me.polygons:
        cz = p.center.z
        if abs(p.normal.z) > 0.7 and b * 0.5 < cz < T - b * 0.5:
            p.material_index = 1
    core.bevel(case, 0.0006 if hard else 0.0003, 2, angle=50)
    blk = sweep("block", section_block(W, T, b, a, sq, 0.0035 if hard else 0.0006), L - 2 * sq, pages_mat(edge=page_edge))
    blk.location.x = 0.0 if hard else 0.0
    core.bevel(blk, 0.0004, 1, angle=50)
    if hard:
        # headbands: a beaded cord along the inner spine at each end of the block
        hm = headband_mat()
        for sgn in (-1, 1):
            pts = []
            ai = max(0.0004, a - 0.0018)
            for i in range(9):
                t = math.pi * i / 8
                pts.append((-W / 2 + 0.0026 - ai * math.sin(t), sgn * (L / 2 - sq + 0.0003), T / 2 + (T / 2 - b - 0.0012) * math.cos(t)))
            parts.tube_path("headband%d" % sgn, pts, 0.0011, seg=6, mat=hm)
        if ribbon:
            rm = mats.M("ribbon", ribbon, 0.45)
            rm.bump(rm.noise(2000.0, 1.0).outputs["Fac"], 0.2, 0.0002)
            bm = bmesh.new()
            path = [(-0.012, -L / 2 + sq + 0.004, T * 0.55), (-0.010, -L / 2 + sq - 0.001, T * 0.5),
                    (-0.008, -L / 2 - 0.002, T * 0.30), (-0.004, -L / 2 - 0.006, 0.004), (0.002, -L / 2 - 0.016, 0.0006),
                    (0.010, -L / 2 - 0.040, 0.0004)]
            w = 0.0032
            prev = None
            for p in path:
                v1 = bm.verts.new((p[0] - w, p[1], p[2]))
                v2 = bm.verts.new((p[0] + w, p[1], p[2]))
                if prev:
                    bm.faces.new((prev[0], prev[1], v2, v1))
                prev = (v1, v2)
            ob = core.obj_from_bmesh("ribbon", bm, rm.mat, smooth=True)
            core.solidify(ob, 0.0003, 0)
    return case, blk


def price_sticker(price, w=300, h=150):
    """B. Dalton's own price sticker (the store's name is its own; allowed): white, red name, price."""
    from PIL import Image, ImageDraw
    st = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(st)
    d.rounded_rectangle((3, 3, w - 3, h - 3), 16, fill=(250, 248, 240, 255), outline=(200, 196, 186, 255), width=3)
    d.text((w / 2, h * 0.26), "B. DALTON", font=labels.font("bold", h * 0.2), fill=(180, 24, 30, 255), anchor="mm")
    d.text((w / 2, h * 0.43), "BOOKSELLER", font=labels.font("sans", h * 0.11), fill=(120, 20, 24, 255), anchor="mm")
    d.text((w / 2, h * 0.72), price, font=labels.font("bold", h * 0.34), fill=(30, 30, 30, 255), anchor="mm")
    return st


FONT_DIRS = ["tools/stores/signs/src/", "tools/stores/signs/y26/src/fonts/", "tools/stores/media/", "tools/stores/gumballs/",
             "tools/stores/woolworth/", "tools/stores/directory/fonts/", "fonts/"]


def ff(name, px):
    """A font by file name from the project's (OFL/Apache) font folders."""
    import os
    from PIL import ImageFont
    for d in FONT_DIRS:
        p = os.path.join(labels.PROJ, d, name)
        if os.path.exists(p):
            return ImageFont.truetype(p, int(px))
    raise SystemExit("font not found: " + name)


def canvas_for(W, L, ppm, bg=(0, 0, 0, 0)):
    from PIL import Image, ImageDraw
    im = Image.new("RGBA", (int(W * ppm), int(L * ppm)), bg)
    return im, ImageDraw.Draw(im)


def spine_canvas(L, T, ppm, bg=(0, 0, 0, 0)):
    """The spine image: its width runs the book's length (top of the book at the left), its height the
    thickness (front cover at the top)."""
    from PIL import Image, ImageDraw
    im = Image.new("RGBA", (int(L * ppm), max(64, int(T * ppm))), bg)
    return im, ImageDraw.Draw(im)


def gradient(w, h, top, bottom):
    from PIL import Image, ImageDraw
    im = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(im)
    for y in range(h):
        t = y / max(1, h - 1)
        d.line([(0, y), (w, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(top, bottom)) + (255,))
    return im


def wear(im, rng, amount=90, colour=(236, 230, 220)):
    """Scuffed edges and corners (whitened where the print rubbed)."""
    from PIL import Image, ImageDraw, ImageFilter
    w, h = im.size
    m = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(m)
    for k in range(amount):
        e = rng.choice("lrtb")
        x = rng.randint(0, w) if e in "tb" else (rng.randint(0, 8) if e == "l" else w - rng.randint(0, 8))
        y = rng.randint(0, h) if e in "lr" else (rng.randint(0, 8) if e == "t" else h - rng.randint(0, 8))
        r = rng.randint(2, 6)
        d.ellipse((x - r, y - r, x + r, y + r), fill=rng.randint(60, 170))
    im.paste(Image.new("RGBA", (w, h), colour + (255,)), (0, 0), m.filter(ImageFilter.GaussianBlur(1.2)))
    return im


def barcode(d, box, rng):
    x0, y0, x1, y1 = box
    d.rectangle(box, fill=(255, 255, 255, 255))
    x = x0 + (x1 - x0) * 0.06
    while x < x1 - (x1 - x0) * 0.08:
        wb = rng.choice((2, 3, 3, 5, 7))
        d.rectangle((x, y0 + (y1 - y0) * 0.1, x + wb, y1 - (y1 - y0) * 0.25), fill=(0, 0, 0, 255))
        x += wb + rng.choice((2, 3, 4, 6))
    d.text(((x0 + x1) / 2, y1 - (y1 - y0) * 0.12), "0 12345 67890 5", font=labels.font("sans", (y1 - y0) * 0.16), fill=(0, 0, 0, 255), anchor="mm")
