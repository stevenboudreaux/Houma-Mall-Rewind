"""Great American Cookie Co.'s case stock, both years (workstream FOOD3D, Nov 8 2026): a KIT of the cookies,
brownie and cookie cakes that fill ws/g's glass case (tools/stores/gac/case.gd), built side by side and baked
to one 1024 px atlas, then split into one node per kind by _kit.py so the case instances each kind (Steven,
Nov 7: the cookie case was the same in the 1990s, so one kit serves 1995 and 2026).

Pieces (each bottom centre at its kit position, lying flat, top up; the cakes too: the case leans them):
  cc (chocolate chip), dchoc (double chocolate), candy (candy-coated chocolate pieces in INVENTED colours:
  teal, coral, lilac, lime, sky, tangerine; plain lenses, no letters, no brand), sugar, wcm (white chocolate
  macadamia), snick (snickerdoodle), pb (peanut butter, fork criss-cross), brownie (fudge-iced square),
  cake_bday / cake_congrats / cake_team / cake_love (12 in cookie cakes, piped border and lettering:
  "Happy Birthday", "Congrats", "Go Team", "Love You", the words of the art they replace,
  tex/gac/cookie_cakes.png; its "Happy Day!" is "Happy Birthday" per Steven's brief).

References: refs/new/cookie_co/gacc_t000_065, 134-138 (2026 video, not Southland: bare aluminium sheet pans,
cookies heaped and shingled, ~9 cm cookies; cookie cakes golden brown with rosette borders and white
icing letters outlined in colour); design/storefronts/refs/great-american-cookie-case.jpg (1990s case:
same trays, lit cake windows). Sizes: a mall cookie ~3.6 in (92 mm) x 12 mm; a 12 in cookie cake (0.30 m)
x 14 mm; a brownie 65 mm square x 30 mm. Guessed: the kinds' looks (period-generic recipes), the candy
colours (invented, IP rule), cake colours per word (from the replaced art: purple / blue / purple / red).
The tray (bare aluminium half-size sheet pan, 0.30 x 0.15 m) is a flat material (not in the atlas).
Budget: <= 600 tris per cookie and cake (META["kit"]["max_tris"]); one 1024 atlas.
"""
import math
import random
import bmesh
import bpy
from mathutils import Vector
from lib import core, parts, mats, labels

R = 0.046          # cookie radius (92 mm)
H = 0.012          # cookie thickness
CH = 0.012
SEG = 20           # cookie lathe segments
CSEG = 40          # cake outline points
ROW0, ROW1 = 0.0, 0.52
KINDS = ["cc", "dchoc", "candy", "sugar", "wcm", "snick", "pb", "brownie"]
# name, plan, width, height (pan only), writing ink, border icing colours (two, alternating rosettes)
CAKES = [("cake_bday", "round", 0.406, 0, (122, 58, 154, 255), ("#fbf8f2", "#e85a8a")),
         ("cake_congrats", "round", 0.406, 0, (42, 90, 184, 255), ("#fbf8f2", "#2a1810")),
         ("cake_love", "heart", 0.38, 0, (200, 30, 58, 255), ("#e83a5a", "#fbf8f2")),
         ("cake_team", "pan", 0.38, 0.27, (106, 46, 154, 255), ("#fbf8f2", "#3a6ad8"))]
CANDY = ["#1fa39a", "#f0705a", "#b48fd8", "#9ccc3c", "#6cb8e8", "#f4a028"]   # invented, not a brand's set
GOLD = [(0.25, "#e8c588"), (0.55, "#d9a75e"), (0.85, "#b97a38")]            # pale centre -> browned rim

POS = {k: [-0.56 + 0.16 * i, ROW0] for i, k in enumerate(KINDS)}
POS.update({c[0]: [-0.69 + 0.46 * i, ROW1] for i, c in enumerate(CAKES)})
POS["tray"] = [0.0, -0.30]

META = {
    "id": "bl_gac_cookies",
    "class": "small_fixture",
    "tex": 1024,
    "ao": 0.3,
    "refs": [["refs/new/cookie_co/gacc_t000_136.jpg", [0.1, 0.0, 0.8, 0.6], "gacc 136 (video, trays)"],
             ["refs/new/cookie_co/gacc_t000_040.jpg", [0.0, 0.25, 1.0, 1.0], "gacc 040 (cookie cakes)"],
             ["design/storefronts/refs/great-american-cookie-case.jpg", [0.1, 0.55, 0.75, 0.85], "1990s case"]],
    "kit": {"pieces": POS, "max_tris": 600},
    "icon": False,
}


# ---------------------------------------------------------------- materials
def radial(m, cx, cy, r):
    """Distance from (cx, cy) over r (0 centre, 1 rim), in object space."""
    sep = m.node("ShaderNodeSeparateXYZ")
    m.link(m.coords(), sep.inputs[0])
    dx = m.math("SUBTRACT", sep.outputs["X"], cx)
    dy = m.math("SUBTRACT", sep.outputs["Y"], cy)
    return m.math("DIVIDE", m.math("SQRT", m.math("ADD", m.math("MULTIPLY", dx, dx), m.math("MULTIPLY", dy, dy))), r), sep


def dough(name, cx, cy, r, stops, crackle=0.0, sugar=0.0, dust=None, fork=False, rough=0.72):
    """A baked cookie top: colour by distance from the centre (browned rim) with noise, bump from the noise
    (crumb and lumps); crackle: voronoi edges darkened and sunk; sugar: bright crystals; dust: (hex, amount)
    a mottled spice dusting; fork: the peanut-butter cookie's criss-cross."""
    m = mats.M(name, stops[0][1], rough)
    rr, sep = radial(m, cx, cy, r)
    n = m.noise(180.0, 5.0, 0.6)
    t = m.math("ADD", rr, m.math("MULTIPLY", m.math("SUBTRACT", n.outputs["Fac"], 0.5), 0.5))
    col = m.ramp(t, stops)
    height = m.math("MULTIPLY", n.outputs["Fac"], 1.0)
    if crackle:
        v = m.node("ShaderNodeTexVoronoi", Scale=70.0)
        v.feature = "DISTANCE_TO_EDGE"
        m.link(m.coords(), v.inputs["Vector"])
        edge = m.math("LESS_THAN", v.outputs["Distance"], 0.035)
        col = m.mix(m.math("MULTIPLY", edge, crackle), col, stops[-1][1])
        height = m.math("SUBTRACT", height, m.math("MULTIPLY", edge, crackle * 1.4))
    if dust:
        d = m.noise(260.0, 3.0)
        dm = m.math("MULTIPLY", m.math("GREATER_THAN", d.outputs["Fac"], 0.48), dust[1])
        col = m.mix(dm, col, dust[0])
    if fork:
        # two sets of fork tines, crossed at right angles over the middle
        for ang in (0.0, math.pi / 2):
            a = m.math("ADD", m.math("MULTIPLY", sep.outputs["X"], math.cos(ang)), m.math("MULTIPLY", sep.outputs["Y"], math.sin(ang)))
            b = m.math("ADD", m.math("MULTIPLY", sep.outputs["X"], -math.sin(ang)), m.math("MULTIPLY", sep.outputs["Y"], math.cos(ang)))
            a = m.math("SUBTRACT", a, cx * math.cos(ang) + cy * math.sin(ang))
            b = m.math("SUBTRACT", b, -cx * math.sin(ang) + cy * math.cos(ang))
            groove = m.math("GREATER_THAN", m.math("SINE", m.math("MULTIPLY", b, 2 * math.pi / 0.0065)), 0.55)
            band = m.math("LESS_THAN", m.math("ABSOLUTE", b), 0.012)
            along = m.math("LESS_THAN", m.math("ABSOLUTE", a), r * 0.62)
            g = m.math("MULTIPLY", m.math("MULTIPLY", groove, band), along)
            col = m.mix(m.math("MULTIPLY", g, 0.6), col, stops[-1][1])
            height = m.math("SUBTRACT", height, m.math("MULTIPLY", g, 1.6))
    if sugar:
        s = m.node("ShaderNodeTexVoronoi", Scale=900.0)
        m.link(m.coords(), s.inputs["Vector"])
        sp = m.math("LESS_THAN", s.outputs["Distance"], 0.14 * sugar)
        col = m.mix(sp, col, "#fffcf2")
        m.link(m.ramp(sp, [(0.0, "#bdbdbd"), (1.0, "#262626")]), m.bsdf.inputs["Roughness"])
        height = m.math("ADD", height, m.math("MULTIPLY", sp, 0.6))
    m.link(col, m.bsdf.inputs["Base Color"])
    m.bump(height, 0.5, 0.0008)
    return m


def chip_mat(name, base, rough=0.45):
    m = mats.M(name, base, rough)
    n = m.noise(400.0, 3.0)
    m.link(m.ramp(n.outputs["Fac"], [(0.3, base), (0.7, "#1a0e08" if base != "#efe6cc" else "#d8ccaa")]), m.bsdf.inputs["Base Color"])
    m.bump(n.outputs["Fac"], 0.3, 0.0004)
    return m.mat


# ---------------------------------------------------------------- geometry
def top_z(r, rad=R, h=H):
    """Height of a cookie's top at radius r (the dome of the profile below)."""
    f = min(1.0, r / rad)
    return h * (1.0 - 0.35 * f ** 3) if f < 0.85 else h * 0.75 * (1.0 - (f - 0.85) / 0.15) + h * 0.2


def body(name, x, y, mat, rad=R, h=H, seg=SEG, lump=0.0016, seed=0):
    prof = [(0.0, 0.0), (rad - 0.004, 0.0), (rad - 0.0008, 0.0016), (rad, 0.0045), (rad - 0.0018, h * 0.72),
            (rad - 0.0075, h * 0.93), (rad * 0.5, h), (0.0, h * 1.02)]
    ob = parts.lathe(name, prof, seg=seg, loc=(x, y, 0.0), mat=mat, sharp_angle=70)
    # a cookie is never a perfect circle: wobble the rim, lump the top
    me = ob.data
    rnd = random.Random(seed)
    ph = [rnd.uniform(0, math.tau) for _ in range(3)]
    for v in me.vertices:
        a = math.atan2(v.co.y, v.co.x)
        r = math.hypot(v.co.x, v.co.y)
        k = 1.0 + 0.025 * math.sin(3 * a + ph[0]) + 0.015 * math.sin(5 * a + ph[1])
        v.co.x *= k
        v.co.y *= k
        if v.co.z > h * 0.5 and r < rad * 0.9:
            v.co.z += lump * math.sin(2 * a + ph[2]) * (1 - r / rad)
    return ob


def chip(name, x, y, z, s, mat, rnd, verts=4):
    """A chocolate chip: a squat cone set into the dough, tipped a little."""
    ob = parts.cylinder(name, s, s * 1.1, verts=verts, r2=s * 0.3, loc=(x, y, z + s * 0.55), mat=mat, bev=0)
    ob.rotation_euler = (rnd.uniform(-0.4, 0.4), rnd.uniform(-0.4, 0.4), rnd.uniform(0, 6.28))
    return ob


def scatter(cx, cy, n, rmax, rnd, mind=0.009):
    pts = []
    tries = 0
    while len(pts) < n and tries < 2000:
        tries += 1
        r = rmax * math.sqrt(rnd.random())
        a = rnd.uniform(0, math.tau)
        p = (cx + r * math.cos(a), cy + r * math.sin(a), r)
        if all(math.hypot(p[0] - q[0], p[1] - q[1]) > mind for q in pts):
            pts.append(p)
    return pts


def cookie_cc(name, x, y, base_stops, chip_hex, n_chips, seed):
    rnd = random.Random(seed)
    m = dough(name + "_dough", x, y, R, base_stops)
    body(name, x, y, m.mat, seed=seed)
    cm = chip_mat(name + "_chips", chip_hex)
    for i, (px, py, r) in enumerate(scatter(x, y, n_chips, R * 0.8, rnd)):
        chip("%s_chip%d" % (name, i), px, py, top_z(r) - 0.0012, rnd.uniform(0.0034, 0.0046), cm, rnd)


def build_candy(x, y):
    rnd = random.Random(7)
    m = dough("candy_dough", x, y, R, GOLD)
    body("candy", x, y, m.mat, seed=7)
    mats_c = [mats.M("candy_%d" % i, c, 0.28).mat for i, c in enumerate(CANDY)]
    for i, (px, py, r) in enumerate(scatter(x, y, 7, R * 0.78, rnd, 0.016)):
        lens = parts.lathe("candy_lens%d" % i, [(0.0, 0.0), (0.0058, 0.0019), (0.0, 0.0038)], seg=8,
                           loc=(px, py, top_z(r) - 0.0012), mat=mats_c[i % len(mats_c)], sharp_angle=80)
        lens.rotation_euler = (rnd.uniform(-0.35, 0.35), rnd.uniform(-0.35, 0.35), 0)
    cm = chip_mat("candy_chips", "#3a2010")
    for i, (px, py, r) in enumerate(scatter(x + 0.003, y - 0.004, 4, R * 0.7, rnd)):
        chip("candy_chip%d" % i, px, py, top_z(r) - 0.0012, 0.0036, cm, rnd)


def build_wcm(x, y):
    rnd = random.Random(11)
    m = dough("wcm_dough", x, y, R, [(0.25, "#ecca8e"), (0.55, "#dcae66"), (0.85, "#bd8240")])
    body("wcm", x, y, m.mat, seed=11)
    wm = chip_mat("wcm_white", "#efe6cc", 0.5)
    pts = scatter(x, y, 10, R * 0.8, rnd, 0.012)
    for i, (px, py, r) in enumerate(pts[:6]):
        chip("wcm_w%d" % i, px, py, top_z(r) - 0.0012, rnd.uniform(0.0042, 0.0052), wm, rnd)
    nm = mats.M("wcm_nut", "#e9d6a4", 0.55)
    nn = nm.noise(300.0, 3.0)
    nm.link(nm.ramp(nn.outputs["Fac"], [(0.3, "#f0e2b8"), (0.75, "#c9a868")]), nm.bsdf.inputs["Base Color"])
    for i, (px, py, r) in enumerate(pts[6:]):
        nut = parts.sphere("wcm_nut%d" % i, 0.0055, seg=6, rings=4, loc=(px, py, top_z(r) - 0.0015), mat=nm.mat, scale=(1, 1, 0.8))
        nut.rotation_euler = (rnd.uniform(-0.5, 0.5), rnd.uniform(-0.5, 0.5), 0)


def build_brownie(x, y):
    """A fudge brownie, 65 mm square, 26 mm cake under a 5 mm glossy fudge icing with a wavy spread."""
    s, hb, hi = 0.065, 0.026, 0.005
    m = mats.M("brownie_cake", "#4a2c1a", 0.8)
    n = m.noise(220.0, 5.0, 0.65)
    m.link(m.ramp(n.outputs["Fac"], [(0.3, "#5a3620"), (0.7, "#2e1a10")]), m.bsdf.inputs["Base Color"])
    m.bump(n.outputs["Fac"], 0.6, 0.001)
    parts.box("brownie", (s, s, hb), loc=(x, y, 0), mat=m.mat, bev=0.0025, seg=2, origin="bottom")
    im = mats.M("brownie_icing", "#2a160c", 0.22)
    ni = im.noise(60.0, 2.0)
    im.link(im.ramp(ni.outputs["Fac"], [(0.35, "#3a2010"), (0.7, "#1e0f08")]), im.bsdf.inputs["Base Color"])
    im.bump(ni.outputs["Fac"], 0.35, 0.0015)
    ic = parts.box("brownie_icing", (s - 0.004, s - 0.004, hi), loc=(x, y, hb - 0.0006), mat=im.mat, bev=0.0022, seg=2, origin="bottom")
    w = ic.modifiers.new("Wave", "DISPLACE")
    t = bpy.data.textures.new("ice_lumps", "CLOUDS")
    t.noise_scale = 0.012
    w.texture = t
    w.texture_coords = "OBJECT"
    w.strength = 0.0012


# ---------------------------------------------------------------- cookie cakes (Steven, Nov 8: the big ones in the
# lower window are COOKIE CAKES, their own models; shapes from the chain's own releases: 16 in rounds, hearts, pans)
def outline(kind, w, h):
    """The cake's plan as a closed polygon (counter-clockwise, centred): 'round' (w = diameter), 'heart'
    (w wide), 'pan' (w x h, rounded corners)."""
    if kind == "round":
        return [(w / 2 * math.cos(math.tau * i / CSEG), w / 2 * math.sin(math.tau * i / CSEG)) for i in range(CSEG)]
    if kind == "heart":
        pts = []
        for i in range(CSEG):
            t = math.tau * i / CSEG
            pts.append((16 * math.sin(t) ** 3, 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)))
        xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
        s = w / (max(xs) - min(xs))
        cy = (max(ys) + min(ys)) / 2
        pts = [(p[0] * s, (p[1] - cy) * s) for p in pts]
        # a baked dough heart: a shallower cusp (blend toward a circle), so the inset rings stay clean
        pts = [(0.82 * px + 0.18 * w / 2 * math.sin(math.tau * i / CSEG), 0.82 * py + 0.18 * w / 2 * math.cos(math.tau * i / CSEG))
               for i, (px, py) in enumerate(pts)]
        for _ in range(7):      # round the cusp and the tip a little: piped cookie dough is never sharp
            pts = [((pts[i - 1][0] + 2 * pts[i][0] + pts[(i + 1) % len(pts)][0]) / 4,
                    (pts[i - 1][1] + 2 * pts[i][1] + pts[(i + 1) % len(pts)][1]) / 4) for i in range(len(pts))]
        return list(reversed(pts)) if _area(pts) < 0 else pts
    pts = parts._rounded_rect(w, h, 0.03, 4)
    return list(reversed(pts)) if _area(pts) < 0 else pts


def _area(p):
    return sum(p[i][0] * p[(i + 1) % len(p)][1] - p[(i + 1) % len(p)][0] * p[i][1] for i in range(len(p))) / 2


def _offset(p, d):
    """Move every point of a CCW polygon `d` inward along its averaged edge normal."""
    out = []
    n = len(p)
    for i in range(n):
        a, b, c = Vector(p[i - 1]), Vector(p[i]), Vector(p[(i + 1) % n])
        e1 = (b - a).normalized(); e2 = (c - b).normalized()
        n1 = Vector((-e1.y, e1.x)); n2 = Vector((-e2.y, e2.x))      # inward for CCW
        nn = (n1 + n2)
        nn = nn.normalized() if nn.length > 1e-6 else n1
        k = max(0.9, nn.dot(n1))
        q = b + nn * (d / k)
        out.append((q.x, q.y))
    return out


def ring_mesh(name, x, y, rings, mat, cap_bottom=False, cap_top=False, smooth=True):
    """Skin a list of (polygon, z) rings (same point count) into a band; optional fan caps."""
    bm = bmesh.new()
    vr = [[bm.verts.new((x + px, y + py, z)) for px, py in poly] for poly, z in rings]
    n = len(vr[0])
    for a, b in zip(vr, vr[1:]):
        for i in range(n):
            bm.faces.new((a[i], a[(i + 1) % n], b[(i + 1) % n], b[i]))
    for ring, up, on in ((vr[0], False, cap_bottom), (vr[-1], True, cap_top)):
        if on:
            f = bm.faces.new(ring if up else list(reversed(ring)))
            # ear-clip, not a fan from the centre: the heart is concave at its cusp
            bmesh.ops.triangulate(bm, faces=[f], quad_method="BEAUTY", ngon_method="EAR_CLIP")
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    ob = core.obj_from_bmesh(name, bm, mat, smooth=smooth)
    ob.data.set_sharp_from_angle(angle=math.radians(60))
    return ob


def icing(d, xy, s, f, ink, white=(252, 250, 246, 255)):
    """Piped writing: a coloured line, a thinner white line over it."""
    d.text(xy, s, font=f, fill=ink, anchor="mm", stroke_width=11, stroke_fill=ink)
    d.text(xy, s, font=f, fill=white, anchor="mm", stroke_width=3, stroke_fill=white)


def top_png(name, kind, size_m, ink, px=1024):
    """The cake's piped top as RGBA (alpha = icing, which also raises the bump): words and simple drawings in
    the chain's style (white icing outlined in colour, coloured fills), all invented. The image spans
    size_m x size_m centred on the cake."""
    from PIL import ImageFilter
    im, d = labels.canvas(px, px)
    S = px / size_m                                   # px per metre
    C = px / 2
    def P(u, v):                                       # cake metres (x right, y up) -> image px
        return (C + u * S, C - v * S)
    def balloon(u, v, r, col):
        x0, y0 = P(u - r, v + r * 1.2); x1, y1 = P(u + r, v - r * 1.2)
        d.ellipse((x0, y0, x1, y1), fill=col, outline=(250, 250, 246, 255), width=5)
        d.line([P(u, v - r * 1.2), P(u + r * 0.3, v - r * 2.4), P(u - r * 0.2, v - r * 3.4)], fill=(250, 250, 246, 255), width=4)
        hx, hy = P(u - r * 0.4, v + r * 0.5)
        d.ellipse((hx - 6, hy - 9, hx + 6, hy + 9), fill=(255, 255, 255, 230))
    def star(u, v, r, col):
        pts = []
        for i in range(10):
            a = math.pi / 2 + math.pi * i / 5
            rr = r if i % 2 == 0 else r * 0.45
            pts.append(P(u + rr * math.cos(a), v + rr * math.sin(a)))
        d.polygon(pts, fill=col, outline=(250, 250, 246, 255), width=4)
    def heart(u, v, r, col):
        pts = [P(u + r * 16 * math.sin(t) ** 3 / 17, v + r * (13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)) / 17)
               for t in [math.tau * i / 40 for i in range(40)]]
        d.polygon(pts, fill=col, outline=(250, 250, 246, 255), width=4)
    if name == "cake_bday":
        icing(d, P(0, 0.035), "Happy", labels.font("script", 150), ink)
        icing(d, P(0, -0.04), "Birthday", labels.font("script", 150), ink)
        for (u, v, c) in ((-0.105, 0.105, (226, 40, 60, 255)), (-0.055, 0.125, (40, 120, 220, 255)), (0.075, 0.115, (250, 196, 30, 255)),
                          (0.11, 0.09, (60, 170, 80, 255))):
            balloon(u, v, 0.022, c)
    elif name == "cake_congrats":
        icing(d, P(0, 0.0), "Congrats", labels.font("script", 165), ink)
        for (u, v, r, c) in ((-0.1, 0.1, 0.03, (250, 200, 30, 255)), (0.1, 0.095, 0.022, (40, 110, 210, 255)), (0.0, 0.125, 0.018, (226, 50, 60, 255)),
                             (-0.08, -0.11, 0.02, (40, 110, 210, 255)), (0.09, -0.1, 0.028, (250, 200, 30, 255))):
            star(u, v, r, c)
    elif name == "cake_love":
        icing(d, P(0, -0.005), "Love You", labels.font("script", 150), ink)
        for (u, v, r) in ((-0.075, 0.07, 0.022), (0.075, 0.07, 0.022), (0.0, -0.085, 0.018)):
            heart(u, v, r, (236, 120, 160, 255))
    elif name == "cake_team":
        icing(d, P(0.03, -0.01), "Go Team", labels.font("script", 150), ink)
        # a pennant on a stick (no team, no letters on it)
        d.line([P(-0.14, -0.08), P(-0.14, 0.07)], fill=(250, 250, 246, 255), width=8)
        d.polygon([P(-0.14, 0.07), P(-0.035, 0.045), P(-0.14, 0.02)], fill=(230, 120, 20, 255), outline=(250, 250, 246, 255), width=4)
        star(0.12, 0.075, 0.018, (250, 200, 30, 255))
    im = im.filter(ImageFilter.GaussianBlur(1.4))
    return labels.save(im, "gac_" + name + "_top")


def build_cake(name, kind, w, h, ink, border, x, y, seed):
    """A cookie cake of plan `kind` w (x h) metres, 13 mm thick, piped border, piped top."""
    pl = outline(kind, w, h)
    ext = max(w, h)
    m = dough(name + "_dough", x, y, ext / 2, [(0.2, "#dcae68"), (0.7, "#c99050"), (0.98, "#a8682c")], rough=0.7)
    sp = m.node("ShaderNodeTexVoronoi", Scale=55.0)
    m.link(m.coords(), sp.inputs["Vector"])
    dots = m.math("LESS_THAN", sp.outputs["Distance"], 0.11)
    base = m.mix(dots, m.bsdf.inputs["Base Color"].links[0].from_socket, "#3a1e0e")
    png = top_png(name, kind, ext, ink)
    sep = m.node("ShaderNodeSeparateXYZ")
    m.link(m.coords(), sep.inputs[0])
    u = m.math("MULTIPLY_ADD", sep.outputs["X"], 1.0 / ext, 0.5 - x / ext)
    v = m.math("MULTIPLY_ADD", sep.outputs["Y"], 1.0 / ext, 0.5 - y / ext)
    cv = m.node("ShaderNodeCombineXYZ")
    m.link(u, cv.inputs[0])
    m.link(v, cv.inputs[1])
    tx = m.node("ShaderNodeTexImage")
    tx.image = bpy.data.images.load(png, check_existing=True)
    tx.extension = "CLIP"
    m.link(cv.outputs[0], tx.inputs["Vector"])
    nz = m.node("ShaderNodeSeparateXYZ")
    m.link(m.node("ShaderNodeTexCoord").outputs["Normal"], nz.inputs[0])
    a = m.math("MULTIPLY", tx.outputs["Alpha"], m.math("GREATER_THAN", nz.outputs["Z"], 0.6))
    m.link(m.mix(a, base, tx.outputs["Color"]), m.bsdf.inputs["Base Color"])
    m.link(m.ramp(a, [(0.0, "#b8b8b8"), (1.0, "#5a5a5a")]), m.bsdf.inputs["Roughness"])
    nb = m.noise(180.0, 5.0, 0.6)
    m.bump(m.math("ADD", m.math("MULTIPLY", a, 2.0), m.math("MULTIPLY", nb.outputs["Fac"], 0.5)), 0.6, 0.0015)
    # the cookie: bottom (inset), the spread side bulging out, the top edge rolling in; a fan top
    ring_mesh(name, x, y, [(_offset(pl, 0.004), 0.0), (pl, CH * 0.45), (_offset(pl, 0.003), CH * 0.85),
                           (_offset(pl, 0.010), CH)], m.mat, cap_bottom=False, cap_top=True)   # the back never shows (it leans on the window back)
    # the piped border: rosettes (voronoi blobs in the bump) in two icing colours picked per blob
    bm_ = mats.M(name + "_border", "#ffffff", 0.5)
    sx = bm_.node("ShaderNodeSeparateXYZ")
    bm_.link(bm_.coords(), sx.inputs[0])
    ang = bm_.math("ARCTAN2", bm_.math("SUBTRACT", sx.outputs["Y"], y), bm_.math("SUBTRACT", sx.outputs["X"], x))
    k = 60
    ros = bm_.math("ABSOLUTE", bm_.math("SINE", bm_.math("MULTIPLY", ang, k)))
    alt = bm_.math("GREATER_THAN", bm_.math("SINE", bm_.math("MULTIPLY", ang, k / 2.0)), 0.0)
    bm_.link(bm_.mix(alt, border[0], border[1]), bm_.bsdf.inputs["Base Color"])
    swirl = bm_.voronoi(700.0)
    bm_.bump(bm_.math("ADD", ros, bm_.math("MULTIPLY", swirl.outputs["Distance"], 0.3)), 0.9, 0.003)
    ring_mesh(name + "_ring", x, y, [(_offset(pl, 0.020), CH * 0.98), (_offset(pl, 0.018), CH + 0.007),
                                     (_offset(pl, 0.008), CH + 0.009), (_offset(pl, 0.004), CH * 0.98)], bm_.mat)


def build_tray(x, y):
    """A bare aluminium half-size sheet pan cut to the case's tier depth: 0.30 x 0.15 m, 15 mm rolled rim."""
    m = mats.M("tray", "#c9cbcf", 0.38, 0.6, bake=False).mat
    w, d, h, t = 0.30, 0.15, 0.015, 0.002
    parts.box("tray", (w, d, t), loc=(x, y, 0), mat=m, bev=0, origin="bottom")
    for (sx, sy, cx, cy) in ((w, t, 0, d / 2), (w, t, 0, -d / 2), (t, d, w / 2, 0), (t, d, -w / 2, 0)):
        parts.box("tray_rim", (sx + t, sy + t, h), loc=(x + cx, y + cy, 0), mat=m, bev=0, origin="bottom")
        parts.cylinder("tray_roll", 0.0022, sx if sx > sy else sy, verts=6,
                       loc=(x + cx, y + cy, h), rot=(0, 90, 0) if sx > sy else (90, 0, 0), mat=m, bev=0)


def build():
    p = POS
    cookie_cc("cc", p["cc"][0], p["cc"][1], GOLD, "#3a2010", 14, 1)
    cookie_cc("dchoc", p["dchoc"][0], p["dchoc"][1], [(0.25, "#5a3420"), (0.6, "#4a2a18"), (0.9, "#36200f")], "#1c0e06", 9, 2)
    build_candy(*p["candy"])
    m = dough("sugar_dough", p["sugar"][0], p["sugar"][1], R, [(0.3, "#f2dca6"), (0.7, "#e6c483"), (0.95, "#c99a52")], crackle=0.45, sugar=1.0)
    body("sugar", p["sugar"][0], p["sugar"][1], m.mat, seed=3)
    build_wcm(*p["wcm"])
    m = dough("snick_dough", p["snick"][0], p["snick"][1], R, [(0.3, "#f0d6a0"), (0.7, "#e2bb7c"), (0.95, "#c08c4c")],
              crackle=0.7, sugar=0.6, dust=("#a8642c", 0.55))
    body("snick", p["snick"][0], p["snick"][1], m.mat, h=H * 1.15, lump=0.0018, seed=5)
    m = dough("pb_dough", p["pb"][0], p["pb"][1], R, [(0.3, "#d8a868"), (0.7, "#c8924e"), (0.95, "#a87036")], fork=True, sugar=0.4)
    body("pb", p["pb"][0], p["pb"][1], m.mat, seed=6)
    build_brownie(*p["brownie"])
    for i, (name, kind, w, h, ink, border) in enumerate(CAKES):
        build_cake(name, kind, w, h, ink, border, p[name][0], p[name][1], 20 + i)
    build_tray(*p["tray"])
