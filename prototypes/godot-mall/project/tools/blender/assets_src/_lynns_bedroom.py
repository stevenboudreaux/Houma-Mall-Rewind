"""Family BED-A: Lynn's Interiors bedroom suites (2026). Four pieces per suite (bed dressed for display,
nightstand, dresser with its mirror, five-drawer chest), one generator per piece, one finish/style set
per suite (SUITES below). Variant scripts: bl_ly_<piece>_<suite>.py. Inventory, frames and what is
guessed per suite: design/lynns/inventory.md ("BED-A"). Shapes and finishes: _lynns_common.py.

Blender axes: x across, -y front (the foot of the bed, the drawer fronts), z up; origin bottom centre.
Sizes (queen, US retail): mattress 1.52 x 2.03 m; dresser ~1.6 x 0.48 x 0.92; chest ~0.98 x 0.48 x 1.32;
nightstand ~0.70 x 0.42 x 0.72; checked against the 1.2 m wall panels behind the vignettes (4413 t029,
t090, t120) and the 0.7 m columns.
"""
import math
from lib import core, parts, mats
import _lynns_common as C

# ---------------------------------------------------------------- the suites
SUITES = {
    # Louis Philippe panel suite in espresso: arched crown rails, raised panels, bun feet, dark knobs,
    # arched mirror (IMG_4413 t029, t120-125)
    "espresso": {"finish": ("wood", "#4a3426", "#21150f"), "bed": "lp", "feet": "bun", "pull": "knob",
                 "pull_col": "#2a2420", "mirror": "arch", "crown": True, "top_edge": 0.012,
                 "bedding": ("#f2f0ea", "#30486e", "ikat"), "drawer_panel": False},
    # farmhouse grey-wash: the same carcass language, a sage-grey wash, pewter knobs, bun feet
    # (IMG_4413 t045-049; its bed was not filmed: the lp panel bed in the same finish is a guess)
    "sage": {"finish": ("paint", "#7b796a", 0.38), "bed": "lp", "feet": "bun", "pull": "knob",
             "pull_col": "#6c6a64", "mirror": "rect", "crown": True, "top_edge": 0.012,
             "bedding": ("#ece8dc", "#9a9a8e", "stripe"), "drawer_panel": True},
    # French oak: pale limed oak frame round a cream linen scalloped headboard, low footboard on splayed
    # feet, grey striped bedding (IMG_4413 t089-091); the oak chest behind it (t090)
    "oak": {"finish": ("wood", "#cfc1a6", "#a3927a"), "bed": "french", "feet": "splay", "pull": "bar",
            "pull_col": "#8a7a62", "mirror": "rect_arch", "crown": False, "top_edge": 0.008,
            "bedding": ("#b9bcc0", "#d5d7da", "stripe"), "drawer_panel": False},
    # white glam: white lacquer, rosette knobs, slim brass legs and frame (IMG_4413 t065, t085-087);
    # paired here with the light-grey upholstered panel bed of the mattress gallery (4412 t045): a guess
    "glam": {"finish": ("paint", "#eeebe3", 0.0), "bed": "uph", "feet": "brass", "pull": "rosette",
             "pull_col": "#e9e3d4", "mirror": "scallop", "crown": False, "top_edge": 0.006,
             "bedding": ("#f4f2ee", "#d9b8b4", "solid"), "drawer_panel": False},
}


def finish(suite, part, along="X"):
    f = SUITES[suite]["finish"]
    if f[0] == "wood":
        return C.wood(part + ("_v" if along == "Z" else ""), f[1], f[2], along=along, ring_scale=22.0, rough=0.5)
    return C.paint(part + ("_v" if along == "Z" else ""), f[1], wash=f[2], rough=0.35 if f[2] == 0 else 0.6, along=along)


def gold():
    return C.metal("brass", "#b8924a", 0.32, 0.8)


# ---------------------------------------------------------------- case goods

def case(suite, w, d, h, rows, top_t=0.03, feet_h=0.09):
    """A drawer case. rows: top to bottom, (height fraction, drawers across)."""
    S = SUITES[suite]
    mh = finish(suite, "case")
    mv = finish(suite, "case", "Z")
    mf = finish(suite, "front")
    pull_m = gold() if S["pull"] == "rosette" else C.metal("pull", S["pull_col"], 0.4, 0.7)
    body_z0 = feet_h
    body_h = h - feet_h - top_t
    # carcass
    parts.box("carcass", (w, d, body_h), loc=(0, 0, body_z0 + body_h / 2), mat=mv, bev=0.003)
    # top: a slab with a softened edge, overhanging front and sides; a second, smaller slab under it
    # reads as an ogee/cove edge from the floor
    o = 0.025
    parts.box("top", (w + 2 * o, d + o, top_t), loc=(0, -o / 2, h - top_t / 2), mat=mh, bev=S["top_edge"], seg=3)
    parts.box("topcove", (w + o, d + o / 2, 0.018), loc=(0, -o / 4, h - top_t - 0.009), mat=mh, bev=0.006, seg=2)
    if S["crown"]:
        parts.box("crownbead", (w + 0.6 * o, d + 0.3 * o, 0.012), loc=(0, -0.15 * o, h - top_t - 0.024), mat=mh, bev=0.004)
    # base moulding
    if S["feet"] in ("bun", "splay"):
        parts.box("plinth", (w + 0.02, d + 0.01, 0.05), loc=(0, -0.005, body_z0 + 0.025), mat=mh, bev=0.006, seg=2)
    # side panels (a recessed field framed by stiles)
    for s in (-1, 1):
        parts.box("sidepanel", (0.006, d - 0.12, body_h - 0.16), loc=(s * (w / 2 + 0.001), 0, body_z0 + body_h / 2), mat=mv, bev=0.002)
    # drawer fronts
    gap = 0.008
    frame = 0.03
    z = h - top_t - frame
    usable = body_h - 2 * frame - (0.05 if S["feet"] in ("bun", "splay") else 0)
    tot = sum(r[0] for r in rows)
    for frac, n in rows:
        dh = usable * frac / tot
        dw = (w - 2 * frame - (n - 1) * gap) / n
        for i in range(n):
            x = -w / 2 + frame + dw * (i + 0.5) + gap * i
            zc = z - dh / 2
            parts.box("drawer", (dw - gap, 0.022, dh - gap), loc=(x, -d / 2 - 0.008, zc), mat=mf, bev=0.004, seg=2)
            if S["drawer_panel"]:
                parts.box("drawerfield", (dw - gap - 0.07, 0.006, dh - gap - 0.07), loc=(x, -d / 2 - 0.021, zc), mat=mf, bev=0.003)
            # pulls
            pulls = [x - dw * 0.25, x + dw * 0.25] if dw > 0.5 else [x]
            py = -d / 2 - 0.019 - (0.003 if S["drawer_panel"] else 0)
            for px in pulls:
                if S["pull"] == "knob":
                    C.knob("knob", 0.012, pull_m, (px, py, zc))
                elif S["pull"] == "bar":
                    C.bar_pull("bar", 0.12 if dw > 0.4 else 0.09, pull_m, (px, py, zc))
                elif S["pull"] == "rosette":
                    rm = C.paint("rosette", "#f4f1ea", 0.0, rough=0.4)
                    C.knob("rosette", 0.024, rm, (px, py, zc), kind="medallion")
                    C.knob("rosette_c", 0.008, pull_m, (px, py - 0.012, zc))
        z -= dh
    # feet
    fl = (-1, 1)
    if S["feet"] == "bun":
        for sx in fl:
            for sy in fl:
                C.bun_foot("bun", 0.045, feet_h, mh, (sx * (w / 2 - 0.035), sy * (d / 2 - 0.04), 0))
    elif S["feet"] == "splay":
        for sx in fl:
            for sy in fl:
                C.leg_tapered("foot", feet_h + 0.01, 0.024, 0.016, mv, (sx * (w / 2 - 0.03), sy * (d / 2 - 0.03), 0), splay=(sx * 8, -sy * 4), sq=True)
    elif S["feet"] == "brass":
        g = gold()
        for sx in fl:
            for sy in fl:
                C.leg_tapered("leg", feet_h, 0.013, 0.009, g, (sx * (w / 2 - 0.03), sy * (d / 2 - 0.03), 0))
        # a slim brass apron frame under the case
        parts.box("apronf", (w - 0.02, 0.012, 0.012), loc=(0, -d / 2 + 0.03, feet_h - 0.006), mat=g, bev=0.002)
        parts.box("apronb", (w - 0.02, 0.012, 0.012), loc=(0, d / 2 - 0.03, feet_h - 0.006), mat=g, bev=0.002)


def nightstand(suite):
    case(suite, 0.70, 0.42, 0.72, [(1.0, 1), (1.15, 1), (1.15, 1)])


def chest(suite):
    case(suite, 0.98, 0.48, 1.32, [(0.8, 2), (1.0, 1), (1.0, 1), (1.0, 1), (1.05, 1)], feet_h=0.1)


def dresser(suite):
    S = SUITES[suite]
    w, d, h = 1.60, 0.48, 0.92
    case(suite, w, d, h, [(0.85, 3), (1.0, 2), (1.0, 2)])
    mirror(suite, w, d, h)


def _arch_outline(w, h, rise, n=24, base=0.0):
    """Rectangle w x h (bottom at base) with a segmental arch rising `rise` over the top; CCW."""
    pts = [(-w / 2, base), (w / 2, base)]
    for i in range(n + 1):
        t = i / n
        x = w / 2 - w * t
        pts.append((x, base + h + rise * math.sin(math.pi * t)))
    return pts


def _rect_arch_outline(w, h, rise, shoulder=0.12, n=20, base=0.0):
    """Rectangle with square shoulders and an arch between them (the oak mirror/headboard crest)."""
    pts = [(-w / 2, base), (w / 2, base), (w / 2, base + h)]
    x0, x1 = w / 2 - shoulder, -w / 2 + shoulder
    for i in range(n + 1):
        t = i / n
        x = x0 + (x1 - x0) * t
        pts.append((x, base + h + rise * math.sin(math.pi * t)))
    pts.append((-w / 2, base + h))
    return pts


def _scallop_outline(w, h, n=96, amp=0.010, waves=14, base=0.0):
    """An ornate carved-look outline: a rounded rectangle whose edge waves (the glam mirror)."""
    pts = []
    for i in range(n):
        a = core.TAU * i / n
        # superellipse
        cx, cz = math.cos(a), math.sin(a)
        ex = 0.3
        x = w / 2 * math.copysign(abs(cx) ** ex, cx)
        z = h / 2 * math.copysign(abs(cz) ** ex, cz)
        k = 1 + amp * math.sin(waves * a) / max(w, h) * 4
        pts.append((x * k, base + h / 2 + z * k))
    pts = [(x, z) for (x, z) in pts]
    return pts[n * 3 // 4:] + pts[:n * 3 // 4]


def mirror(suite, w, d, h):
    S = SUITES[suite]
    mf = finish(suite, "mirror", "Z")
    glass = mats.flat("glass", "#cfd8dc", 0.04, 0.85, bake=False)
    mw, mh = 1.02, 0.95
    z0 = h + 0.02
    y = d / 2 - 0.05
    if S["mirror"] == "arch":
        out = _arch_outline(mw, mh - 0.14, 0.14, base=z0)
    elif S["mirror"] == "rect_arch":
        out = _rect_arch_outline(mw, mh - 0.10, 0.10, base=z0)
    elif S["mirror"] == "scallop":
        mw, mh = 0.86, 1.10
        out = _scallop_outline(mw, mh, base=z0)
    else:
        out = [(-mw / 2, z0), (mw / 2, z0), (mw / 2, z0 + mh), (-mw / 2, z0 + mh)]
    out = C.resample(out, 72)
    inner = C.offset_outline(out, 0.075 if S["mirror"] != "scallop" else 0.09)
    C.ring_slab("mirrorframe", out, inner, 0.045, mat=mf, loc=(0, y, 0), bev=0.008)
    # a raised bead inside the frame
    bead_o = C.offset_outline(out, 0.05)
    bead_i = C.offset_outline(out, 0.075)
    C.ring_slab("mirrorbead", bead_o, bead_i, 0.06, mat=mf, loc=(0, y, 0), bev=0.006)
    C.outline_slab("mirrorglass", C.offset_outline(out, 0.07), 0.006, mat=glass, loc=(0, y + 0.004, 0), bev=0)
    # the two support posts behind
    for s in (-1, 1):
        parts.box("mirrorpost", (0.04, 0.03, 0.3), loc=(s * (mw / 2 - 0.08), y + 0.035, z0 + 0.1), mat=mf, bev=0.003)


# ---------------------------------------------------------------- the bed

MW, ML = 1.52, 2.03          # queen mattress


def bed(suite):
    S = SUITES[suite]
    style = S["bed"]
    W = MW + 0.16
    L = ML + 0.16
    head_y = L / 2
    foot_y = -L / 2
    rail_z0, rail_z1 = 0.20, 0.44
    top_z = 0.66                      # mattress top
    if style == "uph":
        uph = C.fabric("uph", "#b3b2ad", "velvet")
        uph_w = C.fabric("uphwelt", "#a3a29c", "velvet")
        # tall upholstered headboard with a welted edge and slim wings
        hh = 1.42
        C.soft_box("headboard", (W + 0.04, 0.12, hh - 0.06), r=0.04, crown=0.0, res=(18, 3, 16), mat=uph,
                   loc=(0, head_y - 0.06, 0.06 + (hh - 0.06) / 2), bulge=0.0)
        hb = C.soft_box("hbpad", (W - 0.06, hh - 0.62, 0.05), r=0.03, crown=0.035, res=(18, 14, 3), mat=uph)
        hb.rotation_euler = (math.radians(90), 0, 0)
        hb.location = (0, head_y - 0.13, top_z + (hh - 0.62) / 2 + 0.02)
        C.welt("hbwelt", [(x, head_y - 0.12, z) for (x, z) in C.resample(
            [(-W / 2 - 0.02, 0.1), (W / 2 + 0.02, 0.1), (W / 2 + 0.02, hh), (-W / 2 - 0.02, hh)], 40)], 0.005, uph_w)
        for s in (-1, 1):
            C.soft_box("rail", (0.09, L - 0.2, rail_z1 - rail_z0 + 0.06), r=0.03, res=(3, 14, 3), mat=uph,
                       loc=(s * (W / 2 - 0.045), 0, (rail_z0 + rail_z1) / 2))
        C.soft_box("footboard", (W, 0.09, 0.46), r=0.035, crown=0.006, res=(16, 3, 5), mat=uph, loc=(0, foot_y + 0.045, 0.06 + 0.23))
        lg = C.wood("feet", "#3a2a20", "#1e140e", along="Z")
        for sx in (-1, 1):
            for sy in (-1, 1):
                parts.box("foot", (0.05, 0.05, 0.06), loc=(sx * (W / 2 - 0.05), sy * (L / 2 - 0.05), 0.03), mat=lg, bev=0.004)
    elif style == "french":
        mv = finish(suite, "frame", "Z")
        mh = finish(suite, "frame")
        lin = C.fabric("linen", "#e2dccd", "linen")
        # the headboard: an oak frame round a padded linen panel, scalloped shoulders up to a central arch
        hb_h, sh_h = 1.42, 1.18

        def hb_outline():
            # square posts' rounded shoulders, a serpentine dip, then a broad arch to the centre (t090)
            pts = [(-W / 2, 0.0), (W / 2, 0.0)]
            n = 60
            for i in range(n + 1):
                t = i / n
                x = W / 2 - W * t
                u = abs(x) / (W / 2)
                if u > 0.86:
                    z = sh_h + 0.05 * math.sin(math.pi * 0.5 * (1 - u) / 0.14) - 0.06 * ((u - 0.86) / 0.14) ** 3
                elif u > 0.70:
                    z = sh_h + 0.05 - 0.07 * math.sin(math.pi * (0.86 - u) / 0.16 * 0.5)
                else:
                    k = u / 0.70
                    z = sh_h - 0.02 + (hb_h - sh_h + 0.02) * (0.5 + 0.5 * math.cos(math.pi * k)) ** 0.8
                pts.append((x, z))
            return C.resample(pts, 120)
        out = hb_outline()
        inner = C.offset_outline(out, 0.06)
        C.ring_slab("hbframe", out, inner, 0.06, mat=mv, loc=(0, head_y - 0.03, 0), bev=0.01)
        panel = [p for p in C.offset_outline(out, 0.055)]
        # the padded panel: keep it above the mattress line (the lower frame band is solid wood)
        panel = [(x, max(z, top_z - 0.02)) for (x, z) in panel]
        C.outline_slab("hbpanel", panel, 0.07, mat=lin, loc=(0, head_y - 0.035, 0), bev=0.025, bev_seg=5)
        C.outline_slab("hblower", [(-W / 2 + 0.05, 0.12), (W / 2 - 0.05, 0.12), (W / 2 - 0.05, top_z - 0.02), (-W / 2 + 0.05, top_z - 0.02)],
                       0.04, mat=mh, loc=(0, head_y - 0.03, 0), bev=0.005)
        # low footboard: a bowed board on splayed feet
        fb_h = 0.42
        fb = [(-W / 2, 0.10), (W / 2, 0.10)]
        for i in range(21):
            t = i / 20
            x = W / 2 - W * t
            fb.append((x, fb_h + 0.03 * math.sin(math.pi * t)))
        C.outline_slab("footboard", C.resample(fb, 48), 0.05, mat=mh, loc=(0, foot_y + 0.025, 0), bev=0.008)
        for sx in (-1, 1):
            C.leg_tapered("footpost", 0.42, 0.035, 0.022, mv, (sx * (W / 2 - 0.02), foot_y + 0.03, 0), splay=(sx * 9, 6), sq=True)
            parts.box("rail", (0.05, L - 0.12, rail_z1 - rail_z0), loc=(sx * (W / 2 - 0.03), 0, (rail_z0 + rail_z1) / 2), mat=mh, bev=0.006)
    else:   # "lp": Louis Philippe panel bed (posts, arched crown rails, raised panels)
        mv = finish(suite, "frame", "Z")
        mh = finish(suite, "frame")
        post = 0.085
        for sx in (-1, 1):
            for (py, ph) in ((head_y - post / 2, 1.40), (foot_y + post / 2, 0.66)):
                parts.box("post", (post, post, ph), loc=(sx * (W / 2 - post / 2), py, ph / 2), mat=mv, bev=0.006, seg=2)
                parts.box("postcap", (post + 0.02, post + 0.02, 0.03), loc=(sx * (W / 2 - post / 2), py, ph + 0.015), mat=mh, bev=0.008, seg=2)
        iw = W - 2 * post
        for (y, z0, ph, rise, name) in ((head_y - post / 2, 0.42, 0.78, 0.16, "head"), (foot_y + post / 2, 0.18, 0.36, 0.06, "foot")):
            # the panel, then the arched crown rail over it and a bottom rail
            C.outline_slab(name + "panel", C.resample(_arch_outline(iw, ph, rise, base=z0), 64), 0.03, mat=mv, loc=(0, y, 0), bev=0.004)
            C.outline_slab(name + "field", C.resample(_arch_outline(iw - 0.14, ph - 0.12, rise, base=z0 + 0.07), 64), 0.05,
                           mat=mv, loc=(0, y, 0), bev=0.012, bev_seg=3)
            crown = _arch_outline(iw, 0.0, rise, base=z0 + ph)
            band_o = C.resample([(x, z + 0.07) for (x, z) in crown[2:]] + [(x, z - 0.035) for (x, z) in reversed(crown[2:])], 64)
            C.outline_slab(name + "crown", band_o, 0.06, mat=mh, loc=(0, y, 0), bev=0.008, bev_seg=3)
            parts.box(name + "botrail", (iw, 0.05, 0.09), loc=(0, y, z0 - 0.03), mat=mh, bev=0.006)
        for sx in (-1, 1):
            parts.box("rail", (0.04, L - 2 * post, rail_z1 - rail_z0), loc=(sx * (W / 2 - 0.03), 0, (rail_z0 + rail_z1) / 2), mat=mh, bev=0.006)
    dress(S, W, L, top_z, head_y)


def dress(S, W, L, top_z, head_y):
    """Display bedding: mattress on a foundation, a duvet hanging over three sides, sleeping pillows,
    two shams and a throw pillow, a folded throw across the foot."""
    c_duvet, c_accent, pat = S["bedding"]
    tick = C.fabric("tick", "#ecebe6", "linen")
    duv = C.fabric("duvet", c_duvet, "linen")
    MWd = MW
    mz0 = 0.36
    C.soft_box("foundation", (MWd, ML, mz0 - 0.16), r=0.01, res=(10, 12, 2), mat=tick, loc=(0, 0, 0.16 + (mz0 - 0.16) / 2))
    C.soft_box("mattress", (MWd, ML, top_z - mz0), r=0.05, crown=0.01, res=(12, 14, 4), mat=tick, loc=(0, 0, (mz0 + top_z) / 2))
    # duvet: a thin quilt over the top, hanging 0.22 m over the sides and the foot
    dl = ML - 0.30
    dy = -ML / 2 + dl / 2 - 0.02
    C.soft_box("duvettop", (MWd + 0.08, dl + 0.04, 0.07), r=0.03, crown=0.03, res=(14, 16, 2), mat=duv, loc=(0, dy, top_z + 0.03))
    for s in (-1, 1):
        C.soft_box("duvetside", (0.035, dl + 0.02, 0.30), r=0.015, bulge=0.015, res=(2, 16, 4), mat=duv,
                   loc=(s * (MWd / 2 + 0.035), dy, top_z - 0.12))
    C.soft_box("duvetfoot", (MWd + 0.08, 0.035, 0.30), r=0.015, bulge=0.015, res=(14, 2, 4), mat=duv,
               loc=(0, -ML / 2 - 0.035, top_z - 0.12))
    # a folded throw across the foot (the accent colour)
    thr = C.fabric("throw", c_accent, "chenille")
    C.soft_box("throwtop", (MWd + 0.14, 0.42, 0.05), r=0.02, crown=0.01, res=(14, 5, 2), mat=thr, loc=(0, -ML / 2 + 0.30, top_z + 0.085))
    for s in (-1, 1):
        C.soft_box("throwside", (0.03, 0.42, 0.34), r=0.012, bulge=0.01, res=(2, 5, 4), mat=thr,
                   loc=(s * (MWd / 2 + 0.07), -ML / 2 + 0.30, top_z - 0.06))
    # pillows: two sleeping pillows flat-ish, two shams leaning on the headboard, one accent pillow
    pw = C.fabric("pillowcase", "#f6f5f1" if c_duvet != "#f6f5f1" else "#ebe9e3", "linen")
    for s in (-1, 1):
        C.soft_box("sleeppillow", (0.66, 0.46, 0.14), r=0.06, crown=0.04, crown_bottom=0.02, pinch=0.5, res=(9, 7, 3), mat=pw,
                   loc=(s * 0.37, ML / 2 - 0.30, top_z + 0.09), rot=(-8, 0, 0))
    sham = C.pillow_mat("sham", "solid", c_duvet, c_duvet, "linen")
    for s in (-1, 1):
        C.pillow("sham", 0.66, 0.50, 0.16, sham, (s * 0.37, ML / 2 - 0.10, top_z + 0.33), (16, 0, 0))
    acc = C.pillow_mat("accent", pat, c_accent, "#f1eee6", "linen")
    C.pillow("accent", 0.50, 0.40, 0.14, acc, (0, ML / 2 - 0.38, top_z + 0.27), (20, 0, 0))
