#!/usr/bin/env python3
"""Paint the mall directory kiosks' lit panels and their click areas (design/godot-directory.md).

The panel IS the directory: in the game the action button shows this same picture full screen,
and you click a store's name or its place on the map (scripts/directory_ui.gd).

Writes (2048 x 2290 px; the lit art is 1.02 x 1.14 m, kiosk.gd ART_W / ART_H):
  tex/dir/panel_2026.png  the real 2026 directory, redrawn from IMG_4455 (Oct 23 2026, straightened):
                          every line of STORES BY CATEGORY with its dot colour, the LEGEND, the map
                          blocks, logos and roads at the photo's positions. The one thing not copied
                          is the stock portrait of a woman at top left (not ours to reproduce): the
                          plain cyan band runs through there instead (Steven, Nov 1: no stand-in).
  tex/dir/panel_1995.png  the same layout "less modern" (Steven, Nov 1), after the mall's own March
                          1994 Merchant List & Map: the fan logo, numbered stores in category boxes,
                          the floor plan from the game's 1995 map, special locations A-G.
  tex/dir/hotspots.json   per year, the click areas in panel pixels: each list line and each
                          store's place on the map, keyed by the store's unit id in the layout
                          (the jump spots come from the wing build, gen/<wing>/directory.json).
  tex/dir/back.png        the plain cream back (IMG_4484 f068).
Input: tools/stores/directory/map.json (make_data.gd, from the layout files).
Run from the project root: python3 tools/stores/directory/paint_dir.py
"""
import json, math, os, random
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
OUT = os.path.join(PROJ, "tex", "dir")
FONTS = os.path.join(PROJ, "tools", "stores", "signs", "y26", "src", "fonts")
K = 2                       # panel pixels per unit of the 1024 x 1145 tracing space
W, H = 1024 * K, 1145 * K


def font(name, size):
    p = {
        "reg": os.path.join(HERE, "fonts", "LiberationSans-Regular.ttf"),
        "bold": os.path.join(HERE, "fonts", "LiberationSans-Bold.ttf"),
        "serifb": os.path.join(HERE, "fonts", "LiberationSerif-Bold.ttf"),
        "display": os.path.join(PROJ, "fonts", "sans.otf"),
        "serif": os.path.join(PROJ, "fonts", "serif.ttf"),
        "cinzel": os.path.join(FONTS, "Cinzel-Bold.ttf"),
        "script": os.path.join(FONTS, "GreatVibes-Regular.ttf"),
        "inter": "/usr/share/fonts/opentype/inter/Inter-Regular.otf",
        "inter_b": "/usr/share/fonts/opentype/inter/Inter-SemiBold.otf",
    }[name]
    if not os.path.exists(p):
        p = os.path.join(HERE, "fonts", "LiberationSans-Bold.ttf" if name.endswith("b") else "LiberationSans-Regular.ttf")
    return ImageFont.truetype(p, max(1, int(round(size * K))))


def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def P(x, y):
    return (x * K, y * K)


def text(img, x, y, s, f, fill, sx=1.0, anchor="ls", rot=0):
    """Text at tracing-space (x, y), squeezed horizontally by sx (the sign's condensed type).
    anchor: l/m/r then s (y is the baseline). rot: degrees, centred on (x, y).
    Returns the ink box in panel pixels."""
    if not s:
        return (x * K, y * K, x * K, y * K)
    asc, desc = f.getmetrics()
    tw = int(f.getlength(s)) + 4
    tmp = Image.new("RGBA", (tw, asc + desc + 2), (0, 0, 0, 0))
    ImageDraw.Draw(tmp).text((1, asc), s, font=f, fill=fill, anchor="ls")
    nw = max(1, int(tw * sx))
    tmp = tmp.resize((nw, tmp.height), Image.LANCZOS)
    X, Y = x * K, y * K
    if rot:
        tmp = tmp.rotate(rot, expand=True, resample=Image.BICUBIC)
        px, py = X - tmp.width / 2, Y - tmp.height / 2
        img.alpha_composite(tmp, (int(px), int(py)))
        return (px, py, px + tmp.width, py + tmp.height)
    px = X - (nw / 2 if anchor[0] == "m" else nw if anchor[0] == "r" else 0)
    py = Y - asc
    img.alpha_composite(tmp, (int(px), int(py)))
    cap = -f.getbbox("H")[1] + asc if f.getbbox("H")[1] < 0 else asc - f.getbbox("H")[1]
    return (px, Y - (asc - f.getbbox("H")[1]) + (asc - f.getbbox("H")[1]) * 0, px + nw, Y + desc * 0.3)


def poly(d, pts, fill, outline=None, w=1.4):
    q = [P(*p) for p in pts]
    d.polygon(q, fill=fill)
    if outline:
        d.line(q + [q[0]], fill=outline, width=int(w * K), joint="curve")


def rect(d, x0, y0, x1, y1, fill, outline=None, w=1.4):
    poly(d, [(x0, y0), (x1, y0), (x1, y1), (x0, y1)], fill, outline, w)


# ------------------------------------------------------------------ 2026: the real directory
INK = hexc("#2d2e30")
GREY_TXT = hexc("#46474f")
COL = {"K": "#353638", "B": "#6cc7ec", "Y": "#eadf4f", "M": "#df5a9b", "O": "#f19c55", "G": "#55b8a4",
       "P": "#d293cc"}
# the colours read off the straightened photo, corrected for its white balance (the panel's white
# body reads #deeaf0 in the photo)
CYAN = hexc("#3fa8d6")
BODY = hexc("#f3f6f7")
HALL = hexc("#b3b8bc")

# (label, dot, y) in tracing space; dot None = a category header. Transcribed from IMG_4455.
# "|" marks the tiny "inside" word.
COL1 = [("DEPARTMENT STORES", None, 257), ("Dillard's", "K", 272.7), ("JCPenney", "K", 285), ("Lynn's Interiors", "K", 297.7),
        ("CHILDREN'S APPAREL", None, 313), ("Disney|inside|JCPenney", "K", 329), ("Rhea Lana's", "B", 340.7),
        ("COSMETICS, PERFUME, & BEAUTY", None, 356.7), ("Bath & Body Works", "B", 371), ("Dillard's", "K", 383.7),
        ("JCPenney Beauty", "K", 396), ("PINK|inside|Victoria's Secret", "G", 409), ("Victoria's Secret", "G", 421.7),
        ("ELECTRONICS", None, 436), ("EcoATM", "G", 451), ("ENTERTAINMENT", None, 466), ("Hypervelocity", "K", 481),
        ("Treasure Island Putt Putt Golf", "B", 493.7), ("Pocket Change", "B", 506), ("FASHION ACCESSORIES", None, 521),
        ("Claire's", "P", 535.7), ("FOOD", None, 550.3), ("Auntie Anne's", "Y", 565.3), ("Cakelicious", "B", 578),
        ("Cinnamonster", "Y", 590.3), ("Corn Dog 7", "B", 602.7), ("Great American Cookie Co.", "Y", 615.3),
        ("Red Seal Pizzeria & Bar", "K", 628), ("Wicked Wingz", "B", 640), ("HOME FURNISHINGS", None, 655.3),
        ("Lynn's Interiors", "K", 670.3), ("JEWELRY", None, 685), ("DJS Jewelers", "Y", 700), ("Zales", "G", 712.7),
        ("MEN'S APPAREL", None, 727.7), ("Aéropostale", "Y", 742.7), ("Ann Scrubs & Accessories", "Y", 755),
        ("Avant-Garde", "M", 767.7), ("Impressive Prints", "M", 780), ("Spencer's", "M", 793)]
COL2 = [("OTHER RETAIL", None, 259), ("Ann Scrubs & Accessories", "Y", 274.3), ("Bath & Body Works", "B", 287), ("GNC", "Y", 299.3),
        ("Hi-5", "M", 311.7), ("Rhea Lana's", "B", 324.7), ("SOLA Center for the Arts", "O", 337.3), ("Spencer's", "M", 350),
        ("White Barn|inside|Bath & Body Works", "B", 362.7), ("SCHOOL", None, 377.3), ("Unitech Training Academy", "K", 392.7),
        ("SERVICES", None, 407.3), ("House of Fadez Barbershop", "M", 422), ("Impressive Prints", "M", 434.7),
        ("Inspired 2 Dance", "O", 447), ("JCPenney Salon", "K", 459.3), ("Prime Time Fitness", "O", 471.7), ("Wax Utopia", "P", 484.3),
        ("SHOES", None, 499), ("Foot Locker", "M", 514), ("Journeys", "M", 526.3), ("Shoe Dept. Encore", "K", 538.7),
        ("SPORTS APPAREL", None, 553.7), ("Foot Locker", "M", 568.7), ("Lids", "Y", 581), ("ProImage Sports", "G", 593.3),
        ("WIRELESS SERVICES", None, 607.3), ("AT&T", "M", 622.7), ("Boost Mobile", "Y", 635.3), ("Cell Xpert", "B", 647.7),
        ("T-Mobile", "G", 660), ("WOMEN'S APPAREL", None, 674.3), ("Aéropostale", "Y", 689.3), ("Ann Scrubs & Accessories", "Y", 701.7),
        ("Impressive Prints", "M", 714), ("Lola LaBelle Bridal", "M", 726.3), ("maurices", "Y", 739), ("MG Boutique", "Y", 751.3),
        ("Neek & Co.", "O", 764), ("PINK|inside|Victoria's Secret", "G", 776), ("Rainbow", "Y", 788.7), ("Spencer's", "M", 801.3),
        ("Victoria's Secret", "G", 813.7), ("YOUTH SPORTS", None, 828.3), ("Bayou Soccer Club", "B", 843.3),
        ("Southland Soccer Fields", "K", 855.7)]
# a line on the sign -> the store's name in layout_2026.json (None: not a unit in the game's map)
ALIAS_2026 = {"Disney inside JCPenney": "JCPENNEY", "JCPenney Beauty": "JCPENNEY", "JCPenney Salon": "JCPENNEY",
              "PINK inside Victoria's Secret": "PINK", "White Barn inside Bath & Body Works": "BATH & BODY WORKS",
              "Hypervelocity": "HYPERVELOCITY RACE TRACK", "Pocket Change": "GAMES, INC. (POCKET CHANGE)",
              "Great American Cookie Co.": "GREAT AMERICAN COOKIES", "Red Seal Pizzeria & Bar": "THE RED SEAL PIZZERIA & BAR",
              "Aéropostale": "AÉROPOSTALE",
              "EcoATM": None, "Ann Scrubs & Accessories": None, "Unitech Training Academy": None, "T-Mobile": None,
              "MG Boutique": None, "Bayou Soccer Club": None, "Southland Soccer Fields": None}

# the map, in tracing space (straightened IMG_4455)
HALL_RECTS = [(720, 449, 886, 463), (797, 449, 821.5, 729), (522, 678, 821.5, 706), (522, 700, 560, 754), (880, 597, 898, 617)]
BLOCKS = [  # (colour, polygon)
    ("O", [(716.5, 462.5), (797.5, 462.5), (797.5, 590), (716.5, 590)]),
    ("Y", [(716.5, 590), (797.5, 590), (797.5, 687.5), (716.5, 687.5)]),
    ("M", [(522.5, 637.5), (716.5, 637.5), (716.5, 687.5), (562.5, 687.5), (555, 678.5), (522.5, 678.5)]),
    ("B", [(562.5, 702.5), (720, 702.5), (720, 740), (726, 740), (726, 775), (567.5, 775), (555, 762.5), (555, 710)]),
    ("B", [(522.5, 713.5), (537.5, 713.5), (537.5, 752.5), (522.5, 752.5)]),
    ("Y", [(726, 705), (785, 705), (797.5, 716), (797.5, 729), (726, 729)]),
    ("P", [(821.5, 462.5), (853.5, 462.5), (853.5, 520), (821.5, 520)]),
    ("P", [(821.5, 562.5), (898.5, 562.5), (898.5, 596), (837.5, 596), (837.5, 590), (821.5, 590)]),
    ("G", [(837.5, 616), (898.5, 616), (898.5, 637.5), (821.5, 637.5), (821.5, 622.5), (837.5, 622.5)]),
    ("G", [(821.5, 689), (898.5, 689), (898.5, 729), (821.5, 729)]),
]
ANCHORS = {  # the black blocks with logos
    "LYNN'S INTERIORS": [(690, 375), (901.5, 375), (901.5, 449), (690, 449)],
    "JCPENNEY": [(405, 570), (521.5, 570), (521.5, 753.5), (405, 753.5), (405, 640), (377.5, 640), (377.5, 590), (405, 590)],
    "DILLARD'S": [(747.5, 729), (905, 729), (905, 807.5), (747.5, 807.5)],
}
OTHER_BLACK = [  # the black blocks with tenants' logos, and UNITECH's own building
    [(853.5, 462.5), (900, 462.5), (900, 511.5), (853.5, 511.5)],
    [(821.5, 520), (900, 520), (900, 562.5), (821.5, 562.5)],
    [(821.5, 637.5), (898.5, 637.5), (898.5, 689), (821.5, 689)],
    [(628, 260), (695, 260), (695, 320), (628, 320)],
]


def zmap(z, pts):
    """Piecewise-linear 1-D map through [(world, panel), ...] (sorted by world)."""
    if z <= pts[0][0]:
        return pts[0][1]
    for (a, pa), (b, pb) in zip(pts, pts[1:]):
        if z <= b:
            return pa + (pb - pa) * (z - a) / (b - a)
    return pts[-1][1]


def map_spot_2026(st):
    """Where a store sits on the 2026 sign's map: the stretch of the coloured block along the hall
    its front faces, in tracing space (x0, y0, x1, y1). The sign's map is a diagram (blocks, not
    stalls), so each store gets the part of its block that matches its frontage in the game."""
    nm = st["layout_name"]
    if nm in ANCHORS:
        xs = [p[0] for p in ANCHORS[nm]]
        ys = [p[1] for p in ANCHORS[nm]]
        return (min(xs), min(ys), max(xs), max(ys))
    ax, az, bx, bz, nx, nz = st["front"]
    z0, z1 = sorted([az, bz])
    x0, x1 = sorted([ax, bx])
    zn = st["zone"]
    if nx > 0.5 and zn in ("H2", "C2", "H4", "C1"):            # the west side of the east hall
        Z = [(-86, 462.5), (48, 687.5)]
        return (716.5, zmap(z0, Z), 797.5, zmap(z1, Z))
    if nx < -0.5 and z1 <= 0:                                  # the east side, north of the main entrance
        Z = [(-86, 462.5), (-48, 520), (-28, 562.5), (-6, 596)]
        return (821.5, zmap(z0, Z), 898.5, zmap(z1, Z))
    if nx < -0.5 and zn in ("H4", "C3", "H8"):                 # the east side, south of the main entrance
        Z = [(6, 616), (26, 637.5), (50, 689), (80, 729)]
        return (821.5, zmap(z0, Z), 898.5, zmap(z1, Z))
    if zn == "H1b":                                            # the Sears hall east (The Red Seal)
        return (853.5, 462.5, 900, 511.5)
    if zn in ("C2", "H3"):                                     # by the main entrance (Claire's, Wax Utopia, Zales)
        if nz > 0.5 and az <= -10:
            return (837.5, 580, 898.5, 596)
        if az >= 6:
            return (837.5, 616, 898.5, 637.5)
        return (880, 597, 898, 617)
    if nz > 0.5 and az >= 40:                                  # the concourse's north row (and C4's north side)
        X = [(-154, 522.5), (-20, 716.5)]
        return (zmap(x0, X), 637.5, zmap(x1, X), 687.5)
    if nx > 0.5 and zn == "C3":                                # C3 west: the food strip
        return (726, 705, 797.5, 729)
    if zn == "H6":                                             # Corn Dog 7, by the JCPenney court
        return (522.5, 713.5, 537.5, 752.5)
    if nz < -0.5 or zn == "":                                  # the concourse's south row, the food court
        X = [(-136, 555), (-40, 700), (-20, 726)]
        if x0 >= -36:
            return (726, 705, 797.5, 729)
        return (zmap(x0, X), 702.5, zmap(x1, X), 775)
    return None


def draw_icon(d, kind, x, y, s=1.0, col=INK):
    """The sign's small black pictograms (simplified)."""
    X, Y = x * K, y * K
    r = 4.2 * K * s
    lw = max(1, int(K * 0.8 * s))
    if kind == "restroom":
        for dx in (-r * 0.6, r * 0.6):
            d.ellipse([X + dx - r * 0.25, Y - r, X + dx + r * 0.25, Y - r * 0.5], fill=col)
            d.rectangle([X + dx - r * 0.28, Y - r * 0.4, X + dx + r * 0.28, Y + r], fill=col)
    elif kind == "bus":
        d.rounded_rectangle([X - r, Y - r * 0.8, X + r, Y + r * 0.7], radius=r * 0.3, fill=col)
        d.rectangle([X - r * 0.7, Y - r * 0.5, X + r * 0.7, Y], fill=hexc("#ffffff"))
    elif kind == "wheel":
        d.ellipse([X - r * 0.15, Y - r, X + r * 0.25, Y - r * 0.6], fill=col)
        d.arc([X - r * 0.8, Y - r * 0.2, X + r * 0.6, Y + r], 0, 360, fill=col, width=lw)
        d.line([X, Y - r * 0.5, X, Y + r * 0.2, X + r * 0.8, Y + r * 0.2], fill=col, width=lw)
    elif kind == "elevator":
        d.rectangle([X - r, Y - r, X + r, Y + r], outline=col, width=lw)
        d.line([X, Y - r, X, Y + r], fill=col, width=lw)
    elif kind == "dollar":
        d.ellipse([X - r, Y - r, X + r, Y + r], fill=col)
        d.text((X, Y), "$", fill=hexc("#ffffff"), font=font("bold", 6 * s), anchor="mm")
    elif kind == "camera":
        d.rectangle([X - r, Y - r * 0.6, X + r, Y + r * 0.7], fill=col)
        d.ellipse([X - r * 0.4, Y - r * 0.3, X + r * 0.4, Y + r * 0.5], fill=hexc("#ffffff"))
    elif kind == "cone":
        d.ellipse([X - r * 0.6, Y - r, X + r * 0.6, Y - r * 0.1], fill=col)
        d.polygon([(X - r * 0.5, Y - r * 0.3), (X + r * 0.5, Y - r * 0.3), (X, Y + r)], fill=col)
    elif kind == "bottle":
        d.rectangle([X - r * 0.35, Y - r * 0.4, X + r * 0.35, Y + r], fill=col)
        d.rectangle([X - r * 0.15, Y - r, X + r * 0.15, Y - r * 0.4], fill=col)
    elif kind == "ride":
        d.ellipse([X - r * 0.5, Y - r, X + r * 0.5, Y - r * 0.2], fill=col)
        d.rectangle([X - r * 0.7, Y - r * 0.2, X + r * 0.7, Y + r * 0.6], fill=col)
        d.line([X - r * 0.6, Y + r, X + r * 0.6, Y + r], fill=col, width=lw)
    elif kind == "entrance":
        d.polygon([(X - r, Y + r * 0.8), (X + r, Y + r * 0.8), (X, Y - r)], fill=col)
    elif kind == "food":
        for dx in (-r * 0.35, r * 0.35):
            d.line([X + dx, Y - r, X + dx, Y + r], fill=col, width=lw)
    elif kind == "coffee":
        d.chord([X - r, Y - r * 0.6, X + r, Y + r], 0, 180, fill=col)
        d.line([X - r, Y - r * 0.1, X + r, Y - r * 0.1], fill=col, width=lw)
    elif kind == "bar":
        d.polygon([(X - r, Y - r), (X + r, Y - r), (X, Y)], fill=col)
        d.line([X, Y, X, Y + r], fill=col, width=lw)
        d.line([X - r * 0.5, Y + r, X + r * 0.5, Y + r], fill=col, width=lw)


def tri(d, x, y, pointing, col=INK, s=5.0):
    X, Y, r = x * K, y * K, s * K
    pts = {"r": [(X - r, Y - r * 0.8), (X - r, Y + r * 0.8), (X + r * 0.6, Y)],
           "l": [(X + r, Y - r * 0.8), (X + r, Y + r * 0.8), (X - r * 0.6, Y)],
           "u": [(X - r * 0.8, Y + r), (X + r * 0.8, Y + r), (X, Y - r * 0.6)]}[pointing]
    d.polygon(pts, fill=col)


def list_lines(img, d, col, xdot, xtxt, hot, stores_by_name):
    fh = font("bold", 10.2)
    fi = font("bold", 10.0)
    ftiny = font("bold", 4.4)
    for label, dot, y in col:
        if dot is None:
            text(img, xtxt - 1, y + 3.6, label, fh, hexc("#36373d"), sx=0.88)
            continue
        r = 3.2 * K
        d.ellipse([xdot * K - r, y * K - r, xdot * K + r, y * K + r], fill=hexc(COL[dot]))
        parts = label.split("|")
        x = xtxt
        x_end = x
        for i, ptx in enumerate(parts):
            f = ftiny if i == 1 else fi
            bx = text(img, x, y + (3.6 if i != 1 else 1.4), ptx, f, GREY_TXT, sx=0.88)
            x_end = bx[2] / K
            x = x_end + (2.0 if i != 1 else 1.6)
        full = " ".join(parts)
        nm = ALIAS_2026.get(full, full.upper())
        st = stores_by_name.get(nm) if nm else None
        if st:
            hot.append({"id": st["id"], "kind": "list", "label": full,
                        "rect": [round((xdot - 5) * K), round((y - 6.2) * K), round((x_end + 2) * K), round((y + 6.2) * K)]})


def panel_2026(data):
    y = data["years"]["2026"]
    by_name = {s["layout_name"]: s for s in y["stalls"] if not s["vacant"]}
    img = Image.new("RGBA", (W, H), BODY)
    d = ImageDraw.Draw(img)
    hot = []
    # the cyan bands, with the faint lighter facets of the print
    d.rectangle([0, 0, W, 178 * K], fill=CYAN)
    d.rectangle([0, 940 * K, W, H], fill=CYAN)
    face = Image.new("RGBA", img.size, (0, 0, 0, 0))
    fd = ImageDraw.Draw(face)
    for pts, a in [([(560, 0), (1024, 0), (1024, 120)], 18), ([(0, 1145), (300, 940), (520, 1145)], 14),
                   ([(700, 1145), (1024, 980), (1024, 1145)], 16), ([(380, 940), (640, 940), (520, 1040)], 10)]:
        fd.polygon([P(*p) for p in pts], fill=(255, 255, 255, a))
    img.alpha_composite(face)
    d = ImageDraw.Draw(img)
    d.line([P(355, 10), P(755, 10)], fill=(255, 255, 255, 150), width=int(1.3 * K))
    text(img, 292, 118, "Welcome!", font("reg", 98), hexc("#eef3f5"), sx=0.97)
    for k, (t, ic) in enumerate([("southlandmallonline.com", "web"), ("southlandmallinhouma", "fb"), ("slmhouma", "ig")]):
        yy = 58 + k * 26
        cx = 787
        if ic == "web":
            d.ellipse([P(cx - 9, yy - 9), P(cx + 9, yy + 9)], outline=hexc("#ffffff"), width=int(1.4 * K))
            d.line([P(cx - 9, yy), P(cx + 9, yy)], fill=hexc("#ffffff"), width=int(K))
            d.ellipse([P(cx - 4, yy - 9), P(cx + 4, yy + 9)], outline=hexc("#ffffff"), width=int(K))
        elif ic == "fb":
            d.ellipse([P(cx - 9, yy - 9), P(cx + 9, yy + 9)], fill=hexc("#ffffff"))
            text(img, cx + 1, yy + 6, "f", font("bold", 15), CYAN, anchor="ms")
        else:
            d.rounded_rectangle([P(cx - 8.5, yy - 8.5), P(cx + 8.5, yy + 8.5)], radius=5 * K, outline=hexc("#ffffff"), width=int(1.5 * K))
            d.ellipse([P(cx - 4, yy - 4), P(cx + 4, yy + 4)], outline=hexc("#ffffff"), width=int(1.4 * K))
        text(img, 806, yy + 4.6, t, font("reg", 13.5), hexc("#ffffff"), sx=0.98)
    text(img, 512, 1066, "MALL DIRECTORY", font("reg", 61), hexc("#e3eaee"), anchor="ms")
    # the body's headings
    text(img, 60, 230, "STORES BY CATEGORY", font("bold", 33), INK, sx=0.80)
    bx = text(img, 761, 219, "SECURITY", font("bold", 21), INK, sx=0.80)
    text(img, bx[2] / K + 4, 219, "985.228.4563", font("reg", 21), INK, sx=0.80)
    # the lists
    list_lines(img, d, COL1, 50, 61, hot, by_name)
    list_lines(img, d, COL2, 236, 246, hot, by_name)
    # the legend
    text(img, 472, 271, "LEGEND", font("bold", 8.5), INK, sx=0.86)
    for k, (t, ic) in enumerate([("MALL RESTROOMS", "restroom"), ("TRANSIT STOP", "bus"), ("HANDICAP ENTRANCE", "wheel"),
                                 ("ELEVATOR", "elevator"), ("BANK ATM", "dollar"), ("PHOTO BOOTH", "camera"),
                                 ("ICE CREAM VENDING", "cone"), ("DRINK VENDING", "bottle"), ("AMUSEMENT RIDES", "ride"),
                                 ("MALL ENTRANCE", "entrance"), ("SIT DOWN FOOD SERVICE", "food"), ("COFFEE SERVICE", "coffee"),
                                 ("BAR", "bar")]):
        yy = 289 + k * 19.3
        draw_icon(d, ic, 471, yy, 1.2)
        text(img, 489, yy + 2, t, font("bold", 5.4), INK, sx=0.9)
    # the map: the halls, the coloured blocks, the black blocks and their logos
    for r in HALL_RECTS:
        rect(d, *r, fill=HALL)
    for c, pts in BLOCKS:
        poly(d, pts, hexc(COL[c]), hexc("#2c2c2e"), 1.3)
    for pts in list(ANCHORS.values()) + OTHER_BLACK:
        poly(d, pts, hexc(COL["K"]))
    white = hexc("#ffffff")
    text(img, 794, 414, "Lynn's", font("script", 31), white, anchor="ms")
    text(img, 815, 433, "INTERIORS", font("cinzel", 10.5), white, sx=0.95, anchor="ms")
    d.line([P(762, 424.5), P(781, 424.5)], fill=white, width=int(0.8 * K))
    text(img, 463, 668, "JCPenney", font("reg", 19), white, sx=0.93, anchor="ms")
    text(img, 829, 777, "Dillard's", font("serifb", 23), white, sx=0.92, anchor="ms")
    text(img, 861, 543, "HYPERVELOCITY", font("bold", 6.6), white, sx=0.95, anchor="ms")
    text(img, 860, 665, "SHOE DEPT.", font("bold", 7.6), white, sx=0.9, anchor="ms")
    text(img, 860, 672.5, "ENCORE", font("reg", 6.6), white, sx=0.95, anchor="ms")
    text(img, 661, 292, "UNITECH", font("bold", 7), white, sx=0.9, anchor="ms")
    text(img, 873, 492, "THE RED", font("bold", 4.3), white, sx=0.9, anchor="rs")
    d.ellipse([P(874, 487), P(879.5, 492.5)], outline=white, width=int(0.7 * K))
    text(img, 880.5, 492, "SEAL", font("bold", 4.3), white, sx=0.9, anchor="ls")
    draw_icon(d, "food", 879, 474, 0.9, white)
    draw_icon(d, "bar", 889, 474, 0.9, white)
    # map pictograms, entrances (black triangles), transit stops
    for ic, x, yy in [("ride", 808, 525), ("camera", 595, 694), ("cone", 610, 694), ("dollar", 624, 694), ("dollar", 759, 696),
                      ("restroom", 565, 719), ("bottle", 578, 718), ("food", 614, 717), ("food", 565, 734), ("restroom", 728, 714),
                      ("coffee", 750, 715), ("coffee", 773, 715), ("bottle", 864, 606), ("restroom", 712, 760),
                      ("bus", 968, 287), ("bus", 966, 640), ("bus", 409, 841), ("bus", 760, 845)]:
        draw_icon(d, ic, x, yy, 0.8 if ic != "bus" else 1.0)
    for x, yy, pt in [(688, 456, "r"), (911, 454, "l"), (911, 605, "l"), (911, 646, "l")]:
        tri(d, x, yy, pt, s=4.6)
    tri(d, 544, 767, "u", s=5.0)
    for x, yy in [(926, 455), (926, 605), (556, 773)]:
        draw_icon(d, "wheel", x, yy, 0.8)
    fr = font("reg", 7.6)
    text(img, 977, 256, "ARMOUR DRIVE", fr, INK, sx=0.95, anchor="rs")
    text(img, 977, 853, "BAYOU GARDENS BOULEVARD", fr, INK, sx=0.95, anchor="rs")
    text(img, 990, 293, "WEST PARK AVENUE", fr, INK, sx=0.95, rot=-90)
    text(img, 990, 810, "WEST PARK AVENUE", fr, INK, sx=0.95, rot=-90)
    # the map's click areas: each store's stretch of its block
    for st in y["stalls"]:
        if st["vacant"]:
            continue
        r = map_spot_2026(st)
        if r is None:
            continue
        x0, y0, x1, y1 = r
        if y1 - y0 < 6:
            y0, y1 = (y0 + y1) / 2 - 3, (y0 + y1) / 2 + 3
        if x1 - x0 < 6:
            x0, x1 = (x0 + x1) / 2 - 3, (x0 + x1) / 2 + 3
        hot.append({"id": st["id"], "kind": "map", "label": st["name"], "rect": [round(v * K) for v in (x0, y0, x1, y1)]})
    return img, hot


# ------------------------------------------------------------------ 1995: the 1994 Merchant List & Map, less modern
def map_fit(year, box, pad=0.0):
    b = year["bounds"]
    bw, bh = b[2] - b[0], b[3] - b[1]
    x0, y0, x1, y1 = box
    s = min((x1 - x0 - 2 * pad) / bw, (y1 - y0 - 2 * pad) / bh)
    ox = x0 + ((x1 - x0) - bw * s) / 2
    oy = y0 + ((y1 - y0) - bh * s) / 2
    return lambda x, z: (ox + (x - b[0]) * s, oy + (z - b[1]) * s), s


def draw_map_1995(img, d, year, box, hot):
    cats = {c[0]: c for c in year["cats"]}
    Pm, s = map_fit(year, box, 6 * K)
    for r in year["halls"]:
        a, b = Pm(r[0], r[1]), Pm(r[2], r[3])
        d.rectangle([a[0], a[1], b[0], b[1]], fill=hexc("#e2dccd"))
    edge = hexc("#3b3a36")
    fnum = ImageFont.truetype(os.path.join(HERE, "fonts", "LiberationSans-Bold.ttf"), int(9.5 * K))
    for st in year["stalls"]:
        anchor = st["cats"][0] == "dept"
        col = hexc("#f6f2e8") if st["vacant"] else hexc("#6b6f7a") if anchor else hexc(cats.get(st["cats"][0], ["", "", "#999999"])[2])
        for r in st["rects"]:
            a, b = Pm(r[0], r[1]), Pm(r[2], r[3])
            d.rectangle([a[0], a[1], b[0], b[1]], fill=col, outline=edge, width=max(1, int(0.8 * K)))
    for st in year["stalls"]:
        if st["vacant"]:
            continue
        anchor = st["cats"][0] == "dept"
        lx, ly = Pm(*st["label"])
        if anchor:
            best = max(st["rects"], key=lambda r: (r[2] - r[0]) * (r[3] - r[1]))
            a, b = Pm(best[0], best[1]), Pm(best[2], best[3])
            side = (b[1] - a[1]) > (b[0] - a[0]) * 1.6
            room = ((b[1] - a[1]) if side else (b[0] - a[0])) * 0.86 / K
            size = 15.0
            while size > 6 and font("serif", size).getlength(st["name"]) / K > room:
                size -= 0.5
            if side:
                text(img, lx / K, ly / K, st["name"], font("serif", size), hexc("#ffffff"), rot=90)
            else:
                text(img, lx / K, ly / K + size * 0.35, st["name"], font("serif", size), hexc("#ffffff"), anchor="ms")
        elif st["num"]:
            d.text((lx, ly), str(st["num"]), font=fnum, fill=hexc("#ffffff"), anchor="mm", stroke_width=max(1, K // 2), stroke_fill=hexc("#2a2a2a"))
        for r in st["rects"]:
            a, b = Pm(r[0], r[1]), Pm(r[2], r[3])
            hot.append({"id": st["id"], "kind": "map", "label": st["name"], "rect": [round(a[0]), round(a[1]), round(b[0]), round(b[1])]})
    fl = font("inter_b", 10)
    for p in year["places"]:
        x, yy = Pm(p[2], p[3])
        rr = 7 * K
        d.ellipse([x - rr, yy - rr, x + rr, yy + rr], fill=hexc("#1f5c66"), outline=hexc("#ffffff"), width=K)
        d.text((x, yy), p[0], font=fl, fill=hexc("#ffffff"), anchor="mm")


def cat_list_1995(img, d, year, x, y, col_w, y_max, cols, hot):
    by = {c[0]: [] for c in year["cats"]}
    for st in year["stalls"]:
        if not st["vacant"]:
            for c in st["cats"]:
                if c in by:
                    by[c].append(st)
    head = font("inter_b", 9.5)
    item = font("inter", 9.0)
    lh = 12.4
    cx, cy, ci = x, y, 0
    for c in year["cats"]:
        items = sorted(by.get(c[0], []), key=lambda s: (s["num"], s["name"].lower()))
        if not items:
            continue
        if cy + lh * (len(items) + 1.6) > y_max and ci < cols - 1:
            ci += 1
            cx, cy = x + ci * col_w, y
        bw = col_w - 14
        d.rectangle([P(cx, cy), P(cx + bw, cy + lh * 1.15)], fill=hexc(c[2]))
        d.text(P(cx + bw / 2, cy + lh * 0.58), c[1], font=head, fill=hexc("#ffffff"), anchor="mm")
        cy += lh * 1.35
        for st in items:
            d.text(P(cx + 22, cy), str(st["num"]), font=item, fill=hexc("#2b2b2b"), anchor="rt")
            d.text(P(cx + 27, cy), "- " + st["name"], font=item, fill=hexc("#2b2b2b"), anchor="lt")
            tw = item.getlength("- " + st["name"]) / K
            hot.append({"id": st["id"], "kind": "list", "label": st["name"],
                        "rect": [round((cx + 2) * K), round((cy - 1.5) * K), round((cx + 29 + tw) * K), round((cy + 10.5) * K)]})
            cy += lh
        cy += lh * 0.5


def fan_logo(d, cx, cy, s, col):
    """The SOUTHLAND MALL fan logo (the 1994 page): an arch with a stepped fan in it, SOUTHLAND across
    its base with the big S and D, M A L L spaced below."""
    r = 40 * s
    w = max(2, int(3 * s))
    d.arc([cx - r, cy - r, cx + r, cy + r], 180, 360, fill=col, width=w)
    d.line([cx - r, cy, cx - r, cy + 6 * s], fill=col, width=w)
    d.line([cx + r, cy, cx + r, cy + 6 * s], fill=col, width=w)
    for i in range(7):
        a = math.radians(-90 + (i - 3) * 17)
        L = (30 if i in (2, 3, 4) else 24) * s
        bx, by = cx + math.cos(a) * L, cy - 4 * s + math.sin(a) * L
        n = (math.cos(a + math.pi / 2) * 3.2 * s, math.sin(a + math.pi / 2) * 3.2 * s)
        d.polygon([(cx, cy + 2 * s), (bx + n[0], by + n[1]), (bx - n[0], by - n[1])], fill=col)
    fs = ImageFont.truetype(os.path.join(PROJ, "fonts", "sans.otf"), int(15 * s))
    fb = ImageFont.truetype(os.path.join(PROJ, "fonts", "sans.otf"), int(24 * s))
    d.text((cx - r - 6 * s, cy + 18 * s), "S", font=fb, fill=col, anchor="mm")
    d.text((cx, cy + 12 * s), "OUTHLAN", font=fs, fill=col, anchor="mm")
    d.text((cx + r + 6 * s, cy + 18 * s), "D", font=fb, fill=col, anchor="mm")
    fm = ImageFont.truetype(os.path.join(HERE, "fonts", "LiberationSans-Regular.ttf"), int(9 * s))
    d.text((cx, cy + 26 * s), "M    A    L    L", font=fm, fill=col, anchor="mm")


def panel_1995(data):
    y = data["years"]["1995"]
    hot = []
    img = Image.new("RGBA", (W, H), hexc("#f5f1e6"))
    d = ImageDraw.Draw(img)
    teal, mauve = hexc("#1f5c66"), hexc("#b0607e")
    top = 178
    d.rectangle([P(0, 0), P(1024, top)], fill=teal)
    d.rectangle([P(0, top - 6), P(1024, top)], fill=mauve)
    fan_logo(d, 150 * K, top * 0.5 * K, 1.55 * K, hexc("#f5f1e6"))
    d.text(P(1024 * 0.62, top * 0.42), "Merchant List & Map", font=font("serif", 46), fill=hexc("#ffffff"), anchor="mm")
    d.text(P(1024 * 0.62, top * 0.74), "Welcome to Southland Mall  •  Houma, Louisiana", font=font("inter", 15),
           fill=hexc("#e6dccb"), anchor="mm")
    bot = 940
    d.rectangle([P(0, bot), P(1024, 1145)], fill=teal)
    d.rectangle([P(0, bot), P(1024, bot + 6)], fill=mauve)
    d.text(P(512, (bot + 1145) / 2 + 3), "MALL  DIRECTORY", font=font("cinzel", 46), fill=hexc("#ffffff"), anchor="mm")
    cat_list_1995(img, d, y, 26, top + 22, 168, bot - 14, 2, hot)
    mx0 = 370
    draw_map_1995(img, d, y, (mx0 * K, (top + 30) * K, (1024 - 24) * K, (bot - 150) * K), hot)
    kx, ky = mx0 + 10, bot - 140
    d.rectangle([P(kx, ky), P(kx + 168, ky + 22)], fill=teal)
    d.text(P(kx + 84, ky + 11), "SPECIAL MALL LOCATIONS", font=font("inter_b", 9.5), fill=hexc("#ffffff"), anchor="mm")
    for k, p in enumerate(y["places"]):
        xx = kx + (k // 4) * 220
        yy = ky + 34 + (k % 4) * 22
        d.ellipse([P(xx, yy - 8), P(xx + 16, yy + 8)], fill=teal)
        d.text(P(xx + 8, yy), p[0], font=font("inter_b", 9.5), fill=hexc("#ffffff"), anchor="mm")
        d.text(P(xx + 24, yy), p[1], font=font("inter", 10), fill=hexc("#2b2b2b"), anchor="lm")
    d.text(P(1024 - 30, top + 24), "N ↑", font=font("serif", 14), fill=hexc("#3b3a36"), anchor="rt")
    return img, hot


def back():
    rnd = random.Random(7)
    img = Image.new("RGB", (256, 256), (222, 214, 196))
    px = img.load()
    for yy in range(256):
        for xx in range(256):
            v = rnd.randint(-5, 5)
            c = px[xx, yy]
            px[xx, yy] = (c[0] + v, c[1] + v, c[2] + v)
    return img.filter(ImageFilter.GaussianBlur(0.6))


def main():
    data = json.load(open(os.path.join(HERE, "map.json")))
    os.makedirs(OUT, exist_ok=True)
    spots = {"size": [W, H]}
    for year, fn in [("2026", panel_2026), ("1995", panel_1995)]:
        img, hot = fn(data)
        img.convert("RGB").save(os.path.join(OUT, "panel_%s.png" % year), optimize=True)
        spots[year] = hot
        print(year, len(hot), "click areas;", len({h["id"] for h in hot}), "stores")
    json.dump(spots, open(os.path.join(OUT, "hotspots.json"), "w"), indent=0)
    back().save(os.path.join(OUT, "back.png"))
    print("wrote", OUT)


if __name__ == "__main__":
    main()
