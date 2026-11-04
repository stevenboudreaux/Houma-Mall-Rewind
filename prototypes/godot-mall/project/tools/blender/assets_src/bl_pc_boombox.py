"""A mid-1990s portable stereo ("boom box"), a Pocket Change ticket prize (1995 map). Hand item, stock only:
redeemed at the counter for 5,000 tickets (Steven, Nov 3 2026, the wall tags' number; was 500 on Nov 2; design/godot-prize-counter.md), never placed.

Reference: none in the reference pack (refs/INDEX.md lists no boom box) and Wikimedia is not reachable from
the cloud sessions, so the shape is the period type from Steven's brief (Nov 2): twin cassette decks, a CD lid
on top, two big speakers with grilles, a carry handle, a telescoping antenna, a detachable-looking front panel,
slightly worn. The general type (one or two cassette decks, AM/FM, a carry handle; a CD player from the mid
90s) is Wikipedia's "Boombox". Everything else is guessed: proportions, colours, the key layout.
Brand and model invented (IP rule): "KREWE" "KR-95CD". No real logo; "CD" is a plain word, not a mark.
Size: 0.54 x 0.15 x 0.24 m body (a typical mid-90s CD boom box is about 50-60 cm wide), handle +7 cm.
Origin: bottom centre, standing; front (speakers) facing Godot +Z. Held by the handle: the item scene
models/bl_pc_boombox/bl_pc_boombox_item.tscn wraps the .glb with a Grip at the handle.
"""
import math
from lib import core, parts, mats, labels

W, D, H = 0.54, 0.15, 0.24          # body
R_CORNER = 0.045                    # rounded ends of the body (front view)
SPK_X, SPK_Z = 0.183, 0.112         # speaker centres
SPK_R = 0.074                       # grille radius
BEZ_R = 0.083                       # silver ring round each grille
PANEL = (0.19, 0.205, 0.128)        # detachable centre panel: width, height, centre z
DECK = (0.084, 0.058, 0.088)        # each cassette door: width, height, centre z
LCD = (0.13, 0.024, 0.186)          # tuner display: width, height, centre z
LID = (0.15, 0.13)                  # CD lid on top
HANDLE_X, HANDLE_H, HANDLE_R = 0.155, 0.068, 0.011
ANT = (0.0048, 0.0021, 0.34)        # telescoping antenna: base radius, tip radius, length
BODY = "#26272b"
TRIM = "#8d9097"
PANEL_COL = "#323439"

META = {
    "id": "bl_pc_boombox",
    "class": "hand",
    "tex": 2048,
    "ao": 0.4,
    "refs": [],
    "item": {"name": "Boom box", "year": 1995, "store": "POCKET CHANGE", "prize": "boombox", "tickets": 5000,
             "scene": "res://models/bl_pc_boombox/bl_pc_boombox_item.tscn"},
}


def art():
    """The printed bits: grille, brand, tuner, deck windows, the CD lid, the panel legend, the back label."""
    out = {}
    # speaker grille: a perforated disc with the cone's shading behind it
    n = 1024
    im, d = labels.canvas(n, n)
    c = n / 2
    for r in range(int(c), 0, -4):
        g = int(70 + 34 * (1 - r / c) ** 0.6)        # the perforated metal: dark grey, a little lighter inward
        d.ellipse((c - r, c - r, c + r, c + r), fill=(g, g, g + 3, 255))
    step = 30
    for y in range(0, n, step):
        for x in range(0, n, step):
            xx = x + (step / 2 if (y // step) % 2 else 0)
            rr = ((xx - c) ** 2 + (y - c) ** 2) ** 0.5
            if rr < c - 10:
                k = 14 if rr > 140 else 22                   # the cone behind: the dust cap shows lighter
                d.ellipse((xx - 9, y - 9, xx + 9, y + 9), fill=(k, k, k + 1, 255))
    d.ellipse((6, 6, n - 6, n - 6), outline=(40, 40, 44, 255), width=10)
    out["grille"] = labels.save(im, "pc_boombox_grille")
    # brand strip over the tuner
    im, d = labels.canvas(1400, 220)
    labels.text(d, (30, 110), "KREWE", "bold", 150, (232, 232, 236, 255), "lm")
    labels.text(d, (1370, 80), "KR-95CD", "sans", 70, (226, 70, 56, 255), "rm")
    labels.text(d, (1370, 165), "BASS BOOST", "italic", 54, (190, 190, 196, 255), "rm")
    out["brand"] = labels.save(im, "pc_boombox_brand")
    # tuner LCD (amber-green, the period look)
    im, d = labels.canvas(1300, 240, (88, 112, 92, 255))
    labels.text(d, (40, 120), "FM", "sans", 90, (24, 34, 26, 255), "lm")
    labels.text(d, (720, 120), "98.7", "sans", 190, (24, 34, 26, 255), "mm")
    labels.text(d, (1260, 70), "STEREO", "sans", 56, (24, 34, 26, 255), "rm")
    labels.text(d, (1260, 175), "CD  01", "sans", 56, (24, 34, 26, 255), "rm")
    out["lcd"] = labels.save(im, "pc_boombox_lcd")
    # the two cassette doors side by side: smoked window, reels, labels
    im, d = labels.canvas(1800, 620, (30, 31, 34, 255))
    for k, x0 in enumerate((0, 940)):
        d.rounded_rectangle((x0 + 70, 120, x0 + 790, 430), 28, fill=(14, 14, 16, 255), outline=(120, 122, 128, 255), width=6)
        for rx in (x0 + 250, x0 + 610):
            d.ellipse((rx - 70, 205, rx + 70, 345), fill=(58, 56, 52, 255))
            d.ellipse((rx - 28, 247, rx + 28, 303), fill=(200, 196, 186, 255))
        d.rectangle((x0 + 340, 250, x0 + 520, 300), fill=(150, 146, 136, 255))
        labels.text(d, (x0 + 430, 60), "DECK A" if k == 0 else "DECK B  REC/PLAY", "sans", 56, (200, 200, 206, 255))
        labels.text(d, (x0 + 430, 520), "PUSH EJECT", "sans", 46, (150, 150, 156, 255))
    out["decks"] = labels.save(im, "pc_boombox_decks")
    # panel legend under the decks
    im, d = labels.canvas(1500, 140)
    labels.text(d, (750, 70), "DUAL CASSETTE  ·  CD  ·  AM/FM STEREO", "sans", 66, (196, 196, 202, 255))
    out["legend"] = labels.save(im, "pc_boombox_legend")
    # CD lid: a smoked round window over a disc, OPEN
    im, d = labels.canvas(1200, 1040, (29, 30, 33, 255))
    d.ellipse((150, 70, 1050, 970), fill=(12, 12, 14, 255), outline=(110, 112, 118, 255), width=8)
    d.ellipse((260, 180, 940, 860), fill=(70, 74, 82, 255))
    for k in range(6):
        r = 300 - k * 40
        d.ellipse((600 - r, 520 - r, 600 + r, 520 + r), outline=(92 + k * 8, 96 + k * 8, 108 + k * 6, 255), width=10)
    d.ellipse((560, 480, 640, 560), fill=(12, 12, 14, 255))
    labels.text(d, (600, 1005), "CD   ◄ OPEN", "sans", 50, (190, 190, 196, 255))
    out["lid"] = labels.save(im, "pc_boombox_lid")
    # top key legends (two rows of five: the decks' transport and the CD's)
    im, d = labels.canvas(1500, 300)
    keys = ["REC", "PLAY", "REW", "F.F", "STOP", "PLAY", "STOP", "◄◄", "►►", "PROG"]
    for i, k in enumerate(keys):
        labels.text(d, (75 + i * 150, 150), k, "sans", 48, (40, 40, 44, 255))
    out["keys"] = labels.save(im, "pc_boombox_keys")
    # back: battery door label
    im, d = labels.canvas(1200, 300)
    labels.text(d, (600, 90), "BATTERY  10 x D (UM-1)", "sans", 72, (170, 170, 176, 255))
    labels.text(d, (600, 210), "AC 120V 60Hz  ·  MADE IN TAIWAN", "sans", 54, (140, 140, 146, 255))
    out["back"] = labels.save(im, "pc_boombox_back")
    return out


def worn(m, base, scuff, scale=40.0, amount=0.13):
    """Slightly worn moulded plastic: a fine grain bump and paler, rougher scuffs in a sparse noise."""
    n = m.noise(scale, 6.0, 0.65)
    f = m.math("GREATER_THAN", n.outputs["Fac"], 1.0 - amount)
    col = m.mix(m.math("MULTIPLY", f, 0.55), base, scuff)
    m.link(col, m.bsdf.inputs["Base Color"])
    m.link(m.math("MULTIPLY_ADD", f, 0.25, 0.5), m.bsdf.inputs["Roughness"])
    g = m.noise(900.0, 2.0)
    m.bump(g.outputs["Fac"], 0.05, 0.0003)
    return col


def build():
    a = art()
    fy = -D / 2           # the front face (Blender -Y = Godot +Z)
    # ---- body: a slab with rounded ends, worn dark plastic, the back label
    mb = mats.M("body", BODY, 0.5)
    col = worn(mb, BODY, "#4a4c52")
    mats.decal(mb, a["back"], (0, D / 2, 0.075), (0.2, 0.05), "XZ", base=col, flip_u=True, facing="+Y")
    parts.rounded_panel("body", W, H, D, R_CORNER, 6, loc=(0, 0, H / 2), mat=mb.mat, bev=0.004)
    # feet
    mf = mats.flat("feet", "#121214", 0.8)
    for x in (-0.2, 0.2):
        parts.box("foot%d" % (x > 0), (0.06, D - 0.03, 0.006), loc=(x, 0, -0.002), mat=mf, bev=0.002)
    # ---- speakers: a silver ring and a perforated grille each
    mring = mats.M("ring", TRIM, 0.35, 0.6)
    worn(mring, TRIM, "#c4c6cc", 60.0, 0.08)
    mg = mats.M("grille", "#121214", 0.6)
    for k, x in enumerate((-SPK_X, SPK_X)):
        parts.cylinder("ring%d" % k, BEZ_R, 0.008, 28, loc=(x, fy - 0.002, SPK_Z), rot=(90, 0, 0), mat=mring.mat, bev=0.0015)
    out = None
    for k, x in enumerate((-SPK_X, SPK_X)):
        out = mats.decal(mg, a["grille"], (x, fy, SPK_Z), (2 * SPK_R, 2 * SPK_R), "XZ", base=out, facing="-Y")
    for k, x in enumerate((-SPK_X, SPK_X)):
        parts.cylinder("grille%d" % k, SPK_R, 0.004, 28, loc=(x, fy - 0.0065, SPK_Z), rot=(90, 0, 0), mat=mg.mat, bev=0)
    # ---- the detachable front panel: a dark seam behind it, the panel proud of it, two release tabs
    pw, ph, pz = PANEL
    parts.rounded_panel("seam", pw + 0.008, ph + 0.008, 0.004, 0.014, 3, loc=(0, fy - 0.0015, pz), mat=mats.flat("seam", "#08080a", 0.9), bev=0)
    mp = mats.M("panel", PANEL_COL, 0.42, frozen=False)
    c = worn(mp, PANEL_COL, "#55575e", 50.0, 0.08)
    c = mats.decal(mp, a["brand"], (0, fy, pz + ph / 2 - 0.013), (0.17, 0.0267), "XZ", base=c, facing="-Y")
    c = mats.decal(mp, a["legend"], (0, fy, pz - ph / 2 + 0.011), (0.17, 0.0159), "XZ", base=c, facing="-Y")
    parts.rounded_panel("panel", pw, ph, 0.012, 0.012, 3, loc=(0, fy - 0.006, pz), mat=mp.mat, bev=0.002)
    mtab = mats.flat("tab", "#a7aab0", 0.35, 0.6)
    for k, x in enumerate((-0.07, 0.07)):
        parts.box("tab%d" % k, (0.022, 0.008, 0.006), loc=(x, fy - 0.009, pz + ph / 2 + 0.002), mat=mtab, bev=0.0012)
    # tuner display and the two cassette doors on the panel
    ml = mats.M("lcd", "#58705c", 0.2)
    mats.decal(ml, a["lcd"], (0, fy, LCD[2]), (LCD[0], LCD[1]), "XZ")
    parts.box("lcd", (LCD[0], 0.002, LCD[1]), loc=(0, fy - 0.0125, LCD[2]), mat=ml.mat, bev=0)
    md = mats.M("decks", "#1e1f22", 0.25)
    dw, dh, dz = DECK
    mats.decal(md, a["decks"], (0, fy, dz), (2 * dw + 0.008, (2 * dw + 0.008) * 620 / 1800), "XZ", facing="-Y")
    for k, x in enumerate((-(dw / 2 + 0.004), dw / 2 + 0.004)):
        parts.box("deck%d" % k, (dw, 0.004, dh), loc=(x, fy - 0.013, dz), mat=md.mat, bev=0.001)
    # ---- top: the CD lid, transport keys along the front edge, a volume knob, the handle
    mlid = mats.M("lid", "#1d1e21", 0.3)
    mats.decal(mlid, a["lid"], (0, 0.012, H), (LID[0], LID[0] * 1040 / 1200), "XY", facing="+Z")
    parts.rounded_panel("lid", LID[0], LID[1], 0.008, 0.02, 4, loc=(0, 0.012, H + 0.003), mat=mlid.mat, bev=0.0015, plane="XY")
    mk = mats.M("keys", "#b4b6bc", 0.4)
    mats.decal(mk, a["keys"], (0, fy + 0.012, H), (0.21, 0.042), "XY", facing="+Z")
    keys = parts.keypad("keys", rows=1, cols=10, key=(0.0185, 0.016, 0.007), pitch=(0.021, 0.02), loc=(0, fy + 0.0125, H - 0.002), mat=mk.mat, bev=0.0012)
    for md_ in [x for x in keys.modifiers if x.type == "BEVEL"]:     # one bevel segment: in budget
        md_.segments = 1
    mknob = mats.M("knob", "#3a3c41", 0.4)
    for k, x in enumerate((-0.212, 0.212)):
        parts.cylinder("knob%d" % k, 0.015, 0.012, 20, loc=(x, -0.02, H + 0.004), mat=mknob.mat, bev=0.0015)
    mh = mats.M("handle", TRIM, 0.35, 0.55)
    worn(mh, TRIM, "#c9cbd1", 70.0, 0.1)
    for k, x in enumerate((-HANDLE_X, HANDLE_X)):
        parts.cylinder("post%d" % k, 0.017, 0.022, 16, loc=(x, 0.03, H + 0.009), mat=mh.mat, bev=0.002)
    pts = [(-HANDLE_X, 0.03, H + 0.012), (-HANDLE_X + 0.012, 0.03, H + HANDLE_H - 0.01), (-0.08, 0.03, H + HANDLE_H),
           (0.08, 0.03, H + HANDLE_H), (HANDLE_X - 0.012, 0.03, H + HANDLE_H - 0.01), (HANDLE_X, 0.03, H + 0.012)]
    parts.tube_path("handle", pts, HANDLE_R, seg=8, mat=mh.mat)
    # rubber grip on the handle's top run
    parts.cylinder("grip", HANDLE_R + 0.002, 0.13, 14, loc=(0, 0.03, H + HANDLE_H), rot=(0, 90, 0), mat=mats.flat("rubber", "#151517", 0.85), bev=0.001)
    # ---- the telescoping antenna: a swivel at the back left corner, pulled out, leaning out and back
    mant = mats.brushed_metal("antenna", "#c2c4c8", 0.25, along="Z", metal=0.7)
    parts.sphere("swivel", 0.009, 16, 8, loc=(-W / 2 + 0.05, D / 2 - 0.016, H + 0.003), mat=mats.flat("swivel", "#2c2d31", 0.4))
    ant = parts.antenna("ant", ANT[0], ANT[1], ANT[2], 5, loc=(-W / 2 + 0.05, D / 2 - 0.016, H + 0.003), mat=mant)
    ant.rotation_euler = (math.radians(14), math.radians(-24), 0)
