"""The "Pocket Pal" PP-95: an invented 1990s clamshell pocket organizer, the future menu device
(workstream DEVICE-BAKEOFF, design/godot-device-bakeoff.md). TEST ASSET: nothing in the game uses it.

Reference: production/qa/evidence/wsDEV-ref-*.jpg (stills from Steven's video of a Sharp clamshell organizer).
Taken from it: charcoal grained plastic, rubber keys in recessed wells, a light bezel around an olive LCD, a
hinge barrel, a teal backlight key. NOT taken: the wordmark, model number, proportions and key layout. The
name, the model number and every legend are invented; the layout is the brief's (four tab keys, a direction
pad, LIGHT / BACK / ENTER, no other keys). Guessed: every dimension (a palm-sized organizer, about 166 x 72 mm
closed), the underside (feet, battery door, a blank rating plate), the lid's outside print.

Origin: bottom centre of the base, which lies flat; the lid stands open 150 degrees behind it (Blender +Y).
make(hi) builds the device twice from the same numbers: hi=False is the in-game mesh, hi=True the dense
source whose shapes and materials are baked onto it (tools/blender/lib/bake.py, selected-to-active).
"""
import math
import os

import bpy
from mathutils import Matrix

from lib import core, parts, mats, labels

HERE = os.path.dirname(os.path.abspath(__file__))
CC0 = os.path.join(HERE, "cc0")

# ---- the numbers (metres) ----
W = 0.166                    # width of both halves
BD, TB = 0.072, 0.0125       # base depth, thickness
LD, TL = 0.072, 0.0085       # lid depth, thickness
RC = 0.009                   # corner radius
OPEN = 150.0                 # degrees between the two inner faces
HR = 0.0062                  # hinge barrel radius
HY, HZ = BD / 2 + 0.0045, TB - 0.0040      # hinge axis
LID0 = HY + 0.0045           # where the flat lid starts (y)
BEZ = (0.150, 0.052)         # the light bezel around the LCD
BEZ_Y = LID0 + 0.006 + BEZ[1] / 2
LCD = (0.132, 0.040)         # the LCD window: full width
PRINT_Y = BEZ_Y + BEZ[1] / 2 + 0.0085      # the name line above the bezel
WELL, PROUD = 0.0013, 0.0011               # well depth, how far a key stands above the deck
TAB = (0.0155, 0.0200)       # tab key
TAB_X = (-0.0670, -0.0490, -0.0310, -0.0130)
TAB_Y = -0.0050
TAB_NAMES = ("MAIN", "BAG", "JUMP TO", "CONTROLS")
PAD_X, PAD_Y, PAD_R = 0.0165, -0.0050, 0.0172
NOTCH = (0.030, 0.0045)       # the thumb notch in the front edge, for opening the lid
PAD_ARM = (0.0300, 0.0108)   # the direction pad: a plus of two rounded bars
LIGHT = (0.0470, 0.0060, 0.0120, 0.0080)   # x, y, w, h
BACK = (0.0670, 0.0060, 0.0160, 0.0080)
ENTER = (0.0580, -0.0130, 0.0340, 0.0115)

BODY, BODY_DARK = "#2a2c2f", "#1b1c1e"
BEZEL = "#b4b2a6"
KEY, KEY_DARK = "#4a4c50", "#2c2d30"
TEAL, RED = "#1e8d88", "#a8362f"
LCD_OLIVE = "#7d8a68"
INK = (226, 226, 220, 255)
PXMM = 24                    # label art resolution, pixels per millimetre


def _px(m):
    return int(round(m * 1000 * PXMM))


def _pict(d, kind, cx, cy, s, fill=INK):
    """Small white pictograms, drawn (not from any icon set). s = half-height in px."""
    lw = max(2, int(s * 0.18))
    if kind == "person":
        d.ellipse((cx - s * 0.36, cy - s, cx + s * 0.36, cy - s * 0.28), fill=fill)
        d.pieslice((cx - s * 0.78, cy - s * 0.12, cx + s * 0.78, cy + s * 1.9), 180, 360, fill=fill)
    elif kind == "bag":
        d.arc((cx - s * 0.42, cy - s, cx + s * 0.42, cy - s * 0.05), 180, 360, fill=fill, width=lw)
        d.rounded_rectangle((cx - s * 0.8, cy - s * 0.5, cx + s * 0.8, cy + s), radius=s * 0.16, fill=fill)
    elif kind == "arrow":
        d.arc((cx - s * 0.85, cy - s * 0.75, cx + s * 0.45, cy + s * 1.6), 180, 318, fill=fill, width=lw)
        d.polygon([(cx + s * 0.95, cy + s * 0.25), (cx + s * 0.02, cy + s * 0.05), (cx + s * 0.72, cy - s * 0.75)], fill=fill)
        d.ellipse((cx - s * 0.98, cy + s * 0.55, cx - s * 0.62, cy + s * 0.91), fill=fill)
    elif kind == "pad":
        d.rounded_rectangle((cx - s, cy - s * 0.58, cx + s, cy + s * 0.58), radius=s * 0.5, fill=fill)
        k = (30, 31, 34, 255)
        d.rectangle((cx - s * 0.66, cy - s * 0.1, cx - s * 0.22, cy + s * 0.1), fill=k)
        d.rectangle((cx - s * 0.54, cy - s * 0.22, cx - s * 0.34, cy + s * 0.22), fill=k)
        d.ellipse((cx + s * 0.22, cy - s * 0.02, cx + s * 0.44, cy + s * 0.2), fill=k)
        d.ellipse((cx + s * 0.5, cy - s * 0.22, cx + s * 0.72, cy), fill=k)


def art():
    """Paints the printed legends. Returns {name: (png, centre (x, y), size (w, h))} in the flat layout."""
    out = {}
    # base deck: labels printed on the case above the keys
    im, d = labels.canvas(_px(W), _px(BD))

    def P(x, y):                       # metres (flat layout) -> pixels on the base sheet
        return (_px(x + W / 2), _px(BD / 2 - y))
    for x, n in zip(TAB_X, TAB_NAMES):
        labels.text(d, P(x, TAB_Y + TAB[1] / 2 + 0.0042), n, "sans", _px(0.0021 if len(n) > 6 else 0.0024), INK)
    labels.text(d, P(LIGHT[0], LIGHT[1] + LIGHT[3] / 2 + 0.0038), "LIGHT", "sans", _px(0.0023), (120, 214, 206, 255))
    labels.text(d, P(BACK[0], BACK[1] + BACK[3] / 2 + 0.0038), "BACK", "sans", _px(0.0023), INK)
    out["base"] = (labels.save(im, "pocket_pal_base"), (0, 0), (W, BD))
    # key tops: pictograms, pad arrows, ENTER
    im, d = labels.canvas(_px(W), _px(BD))
    for x, k in zip(TAB_X, ("person", "bag", "arrow", "pad")):
        cx, cy = P(x, TAB_Y)
        _pict(d, k, cx, cy, _px(0.0036))
    a = _px(0.0019)
    for dx, dy in ((0, 1), (0, -1), (1, 0), (-1, 0)):
        cx, cy = P(PAD_X + dx * 0.0108, PAD_Y + dy * 0.0108)
        tip = (cx + dx * a, cy - dy * a)
        b1 = (cx - dx * a * 0.7 + dy * a, cy + dy * a * 0.7 + dx * a)
        b2 = (cx - dx * a * 0.7 - dy * a, cy + dy * a * 0.7 - dx * a)
        d.polygon([tip, b1, b2], fill=INK)
    labels.text(d, P(ENTER[0], ENTER[1]), "ENTER", "sans", _px(0.0034), INK)
    out["keys"] = (labels.save(im, "pocket_pal_keys"), (0, 0), (W, BD))
    # lid: the name line
    im, d = labels.canvas(_px(W), _px(0.009))
    labels.text(d, (_px(W / 2 - BEZ[0] / 2 + 0.001), _px(0.0045)), "POCKET PAL", "bold", _px(0.0046), INK, "lm")
    labels.text(d, (_px(W / 2 + BEZ[0] / 2 - 0.001), _px(0.0045)), "PP-95", "sans", _px(0.0034), (190, 190, 184, 255), "rm")
    out["lid"] = (labels.save(im, "pocket_pal_lid"), (0, PRINT_Y), (W, 0.009))
    # lid, outside: the name again, small
    im, d = labels.canvas(_px(0.040), _px(0.006))
    labels.text(d, (_px(0.020), _px(0.003)), "POCKET PAL", "bold", _px(0.0040), (150, 152, 152, 255))
    out["back"] = (labels.save(im, "pocket_pal_back"), (0, LID0 + LD * 0.5), (0.040, 0.006))
    return out


# ---- materials (the dense source only) ----
def _scan(m, name, tile, bump, rough0, rough_var, prints=0.0):
    """A CC0 scanned surface (ambientCG) laid over the part by position (box projection): the scan's height
    map drives the bump, its roughness map the gloss. prints > 0 adds finger smudges (lower roughness)."""
    co = m.coords()
    mp = m.node("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (1.0 / tile,) * 3
    m.link(co, mp.inputs["Vector"])

    def tex(fn, vec):
        t = m.node("ShaderNodeTexImage")
        t.image = bpy.data.images.load(os.path.join(CC0, fn), check_existing=True)
        t.image.colorspace_settings.name = "Non-Color"
        t.projection = "BOX"
        t.projection_blend = 0.25
        m.link(vec, t.inputs["Vector"])
        return t.outputs["Color"]
    m.bump(tex(name + "_1K-JPG_Displacement.jpg", mp.outputs["Vector"]), bump, 0.0006)
    r = m.math("MULTIPLY_ADD", tex(name + "_1K-JPG_Roughness.jpg", mp.outputs["Vector"]), rough_var, rough0 - rough_var * 0.5)
    if prints > 0:
        m2 = m.node("ShaderNodeMapping")
        m2.inputs["Scale"].default_value = (1.0 / 0.11,) * 3
        m2.inputs["Rotation"].default_value = (0.0, 0.0, 0.6)
        m.link(co, m2.inputs["Vector"])
        r = m.math("SUBTRACT", r, m.math("MULTIPLY", tex("Fingerprints009_1K-JPG_Opacity.jpg", m2.outputs["Vector"]), prints))
    m.link(r, m.bsdf.inputs["Roughness"])


def materials(a):
    M = {}
    b = mats.M("body", BODY, 0.6, frozen=True)
    _scan(b, "Plastic004", 0.030, 0.55, 0.60, 0.22, prints=0.10)
    c = mats.decal(b, a["base"][0], (a["base"][1][0], a["base"][1][1], 0), a["base"][2], "XY", facing="+Z")
    c = mats.decal(b, a["lid"][0], (a["lid"][1][0], a["lid"][1][1], 0), a["lid"][2], "XY", base=c, facing="+Z")
    mats.decal(b, a["back"][0], (a["back"][1][0], a["back"][1][1], 0), a["back"][2], "XY", base=c, flip_u=True, facing="-Z")
    M["body"] = b.mat
    z = mats.M("bezel", BEZEL, 0.42, frozen=True)
    _scan(z, "Plastic012A", 0.020, 0.25, 0.40, 0.14, prints=0.12)
    M["bezel"] = z.mat
    M["gasket"] = mats.M("gasket", "#0c0d0d", 0.35, frozen=True).mat
    for n, col in (("key", KEY), ("keydark", KEY_DARK), ("teal", TEAL), ("red", RED)):
        k = mats.M(n, col, 0.8, frozen=True)
        _scan(k, "Rubber004", 0.016, 0.35, 0.78, 0.16)
        mats.decal(k, a["keys"][0], (0, 0, 0), a["keys"][2], "XY", facing="+Z")
        M[n] = k.mat
    f = mats.M("foot", "#151515", 0.9, frozen=True)
    _scan(f, "Rubber004", 0.010, 0.3, 0.85, 0.1)
    M["foot"] = f.mat
    M["plate"] = mats.M("plate", "#9a9c9e", 0.35, 0.6, frozen=True).mat
    return M


# ---- geometry ----
def _finish(ob, bw, hi, seg_hi=3, angle=35.0):
    """Bevel (always on hard edges), then smooth shading with area-weighted normals, so the big faces stay
    flat and the bevels carry the highlight."""
    if bw > 0:
        core.bevel(ob, bw, seg_hi if hi else 1, angle=angle, harden=False)
    core.apply_all(ob)
    for p in ob.data.polygons:
        p.use_smooth = True
    ob.data.set_sharp_from_angle(angle=math.radians(62))
    core.weighted_normals(ob)
    core.apply_all(ob)
    return ob


def _cut(target, cutter, mat=None):
    """Boolean difference, applied at once; the cut faces take `mat` when given."""
    if mat is not None:
        core.set_mat(cutter, mat)
        if mat.name not in [m.name for m in target.data.materials if m]:
            target.data.materials.append(mat)
    b = target.modifiers.new("Cut", "BOOLEAN")
    b.operation = "DIFFERENCE"
    b.solver = "EXACT"
    b.object = cutter
    core.apply_all(target)
    bpy.data.objects.remove(cutter)
    return target


def _slab(name, w, h, d, r, z_top, x, y, mat, hi, seg=None):
    """A rounded slab lying flat with its top face at z_top."""
    return parts.rounded_panel(name, w, h, d, r, seg or (8 if hi else 3), loc=(x, y, z_top - d / 2), mat=mat, bev=0, plane="XY")


def make(hi, M=None):
    """Builds the device flat-open (lid lying behind the base), then stands the lid up. Returns
    (parts, lcd): lcd is the screen quad, kept apart (its own material slot; the game draws on it)."""
    M = M or {}
    g = lambda n: M.get(n)                                   # noqa: E731
    base_parts, lid_parts = [], []
    cs = 10 if hi else 6
    # base shell with the key wells cut into the deck
    base = _slab("base", W, BD, TB, RC, TB, 0, 0, g("body"), hi, cs)
    wells = [(x, TAB_Y, TAB[0], TAB[1], 0.0022) for x in TAB_X]
    wells += [(k[0], k[1], k[2], k[3], 0.0020) for k in (LIGHT, BACK, ENTER)]
    for i, (x, y, w, h, r) in enumerate(wells):
        _cut(base, _slab("cw%d" % i, w + 0.0018, h + 0.0018, WELL * 2, r + 0.0009, TB + WELL, x, y, None, hi,  6 if hi else 3))
    _cut(base, parts.cylinder("cnotch", NOTCH[0] / 2, 0.006, 40 if hi else 14, loc=(0, -BD / 2 - NOTCH[0] / 2 + NOTCH[1], TB + 0.0012), bev=0, smooth=False))
    _cut(base, parts.cylinder("cpad", PAD_R, WELL * 2, 40 if hi else 24, loc=(PAD_X, PAD_Y, TB), bev=0, smooth=False))
    if hi:
        # a parting line round the shell, and the underside: battery door, rating plate
        _cut(base, _ring("cseam", W + 0.002, BD + 0.002, RC, 0.0005, 0.0005, TB * 0.52))
    _finish(base, 0.0011 if hi else 0.0009, hi)
    base_parts.append(base)
    if hi:
        base_parts.append(_finish(_slab("door", 0.060, 0.030, 0.0005, 0.002, 0.0002, -0.040, -0.018, g("body"), hi), 0.0002, hi))
        base_parts.append(_finish(_slab("plate", 0.050, 0.022, 0.0003, 0.001, 0.0001, 0.040, -0.010, g("plate"), hi), 0.0001, hi))
        for sx in (-1, 1):
            for sy in (-1, 1):
                base_parts.append(_finish(parts.cylinder("foot", 0.0042, 0.0012, 20, loc=(sx * (W / 2 - 0.014), sy * (BD / 2 - 0.012), -0.0003),
                                                         mat=g("foot"), bev=0), 0.0004, hi))
    # keys
    zk = TB + PROUD
    hk = WELL + PROUD
    for i, x in enumerate(TAB_X):
        base_parts.append(_finish(_slab("tab%d" % i, TAB[0], TAB[1], hk, 0.0022, zk, x, TAB_Y, g("key"), hi,  6 if hi else 3), 0.0008 if hi else 0.0006, hi))
    for n, k, m in (("light", LIGHT, "teal"), ("back", BACK, "red"), ("enter", ENTER, "key")):
        base_parts.append(_finish(_slab(n, k[2], k[3], hk, 0.0020, zk, k[0], k[1], g(m), hi,  6 if hi else 3), 0.0008 if hi else 0.0006, hi))
    pad = _slab("pad", PAD_ARM[0], PAD_ARM[1], hk + 0.0003, 0.0030, zk + 0.0003, PAD_X, PAD_Y, g("keydark"), hi, 6 if hi else 3)
    core.apply_all(pad)
    arm = _slab("padv", PAD_ARM[1], PAD_ARM[0], hk + 0.0003, 0.0030, zk + 0.0003, PAD_X, PAD_Y, g("keydark"), hi, 6 if hi else 3)
    b = pad.modifiers.new("Join", "BOOLEAN")           # one plus-shaped key, not two crossed bars
    b.operation, b.solver, b.object = "UNION", "EXACT", arm
    core.apply_all(pad)
    bpy.data.objects.remove(arm)
    if hi:
        _cut(pad, parts.sphere("cdimple", 0.0060, 24, 12, loc=(PAD_X, PAD_Y, zk + 0.0003 + 0.0054)))   # a shallow dish in the middle
    base_parts.append(_finish(pad, 0.0009 if hi else 0.0006, hi))
    # hinge: two knuckles on the base, the long barrel on the lid
    hv = 32 if hi else 16
    for sx in (-1, 1):
        base_parts.append(_finish(parts.cylinder("knuckle", HR, 0.017, hv, loc=(sx * (W / 2 - 0.0125), HY, HZ), rot=(0, 90, 0), mat=g("body"), bev=0),
                                  0.0007 if hi else 0.0005, hi, angle=50))
    lid_parts.append(_finish(parts.cylinder("barrel", HR, W - 0.0425, hv, loc=(0, HY, HZ), rot=(0, 90, 0), mat=g("body"), bev=0),
                             0.0007 if hi else 0.0005, hi, angle=50))
    # lid shell (inner face up while flat), the bezel standing 0.6 mm proud, the LCD window sunk into it
    lid = _slab("lid", W, LD, TL, RC, TB, 0, LID0 + LD / 2, g("body"), hi, cs)
    if hi:
        _cut(lid, _ring("lseam", W + 0.002, LD + 0.002, RC, 0.0005, 0.0005, TB - TL * 0.5, y=LID0 + LD / 2))
    lid_parts.append(_finish(lid, 0.0011 if hi else 0.0009, hi))
    bez = _slab("bezel", BEZ[0], BEZ[1], 0.0016, 0.0035, TB + 0.0007, 0, BEZ_Y, g("bezel"), hi, 6 if hi else 3)
    _cut(bez, _slab("clcd", LCD[0], LCD[1], 0.0016, 0.0016, TB + 0.0007 + 0.0008, 0, BEZ_Y, None, hi, 4 if hi else 2), g("gasket"))
    lid_parts.append(_finish(bez, 0.0006 if hi else 0.0005, hi))
    lcd = parts.box("lcd", (LCD[0] - 0.0004, LCD[1] - 0.0004, 0.0002), loc=(0, BEZ_Y, TB + 0.0001), bev=0)
    core.apply_all(lcd)
    # the legends are placed in the flat layout: freeze, then stand the lid up
    core.freeze(base_parts + lid_parts)
    if not M:
        # the in-game mesh: faces nobody looks at (the underside, the lid's outside) get a smaller share of
        # the atlas (bake.uv_unwrap's shrink, by material name), so the keys and legends get more texels
        top, under = mats.flat("lowtop"), mats.flat("lowunder")
        for ob in base_parts + lid_parts:
            ob.data.materials.clear()
            ob.data.materials.append(top)
            ob.data.materials.append(under)
            for p in ob.data.polygons:
                p.material_index = 1 if p.normal.z < -0.3 else 0
    rot = Matrix.Translation((0, HY, HZ)) @ Matrix.Rotation(math.radians(180.0 - OPEN), 4, "X") @ Matrix.Translation((0, -HY, -HZ))
    for ob in lid_parts + [lcd]:
        ob.data.transform(rot)
        ob.data.update()
    return base_parts + lid_parts, lcd


def _ring(name, w, h, r, band, depth, z, y=0.0):
    """A thin frame (outer rounded rectangle minus a slightly smaller one): the cutter for a parting line."""
    o = parts.rounded_panel(name, w, h, band, r, 8, loc=(0, y, z), bev=0, plane="XY")
    i = parts.rounded_panel(name + "i", w - 0.002 - depth * 2, h - 0.002 - depth * 2, band * 3, r - depth, 8, loc=(0, y, z), bev=0, plane="XY")
    core.apply_all(o)
    return _cut(o, i)
