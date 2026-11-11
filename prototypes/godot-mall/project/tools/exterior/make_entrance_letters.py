"""The main entrance's "SOUTHLAND MALL" letters as outlines for channel.gd (EXT-ENTRANCES-BUILD, Nov 11 2026;
design/exterior/entrances-2026-11-09.md "The letters").

The letters stand on top of the porch canopy's fascia as real cans (tools/stores/signs/channel.gd extrudes them),
not a Label3D. Two sets, in channel.gd's logo format (metres, baseline y = 0, x from 0):
  ent_letters_2026.json   white condensed sans capitals (4406 f002-f003), from signs_src/ArchivoBlack-Regular.ttf (OFL)
  ent_letters_1990s.json  serif capitals, a GUESS after the mall's 1994 "Merchant List & Map" lettering, from
                          tools/exterior/signs_src/LibreCaslonText-SemiBold.ttf (OFL)
  python3 tools/exterior/make_entrance_letters.py      (from the project folder; needs fonttools, mapbox_earcut, shapely)
"""
import json, os
import mapbox_earcut as earcut
import numpy as np
from fontTools.ttLib import TTFont
from fontTools.pens.basePen import BasePen
from shapely.geometry import Polygon
from shapely.geometry.polygon import orient
from shapely.ops import unary_union

HERE = os.path.dirname(os.path.abspath(__file__))
TEXT = "SOUTHLAND MALL"
STEPS = 6
# name, font, cap height (m), the width the words are condensed to (m), tracking (m), the word space (x cap height)
# 2026: the canopy is only ~3.7 m wide and the letters on it ~0.5 m tall and ~3 m long (4406 f003, solved by its
# vanishing points): a heavy condensed sans. Archivo Black set narrow stands in for it.
SETS = [
    ("ent_letters_2026.json", os.path.join(HERE, "signs_src", "ArchivoBlack-Regular.ttf"), 0.5, 3.2, 0.03, 0.35),
    ("ent_letters_1990s.json", os.path.join(HERE, "signs_src", "LibreCaslonText-SemiBold.ttf"), 0.42, 3.3, 0.03, 0.4),
]

class FlatPen(BasePen):
    def __init__(self, gs):
        super().__init__(gs)
        self.contours = []
        self.cur = []

    def _moveTo(self, p):
        self.cur = [p]

    def _lineTo(self, p):
        self.cur.append(p)

    def _curveToOne(self, p1, p2, p3):
        p0 = self.cur[-1]
        for i in range(1, STEPS + 1):
            t = i / STEPS
            m = 1 - t
            self.cur.append((m ** 3 * p0[0] + 3 * m * m * t * p1[0] + 3 * m * t * t * p2[0] + t ** 3 * p3[0],
                             m ** 3 * p0[1] + 3 * m * m * t * p1[1] + 3 * m * t * t * p2[1] + t ** 3 * p3[1]))

    def _qCurveToOne(self, p1, p2):
        p0 = self.cur[-1]
        for i in range(1, STEPS + 1):
            t = i / STEPS
            m = 1 - t
            self.cur.append((m * m * p0[0] + 2 * m * t * p1[0] + t * t * p2[0],
                             m * m * p0[1] + 2 * m * t * p1[1] + t * t * p2[1]))

    def _closePath(self):
        if len(self.cur) > 2:
            if self.cur[0] == self.cur[-1]:
                self.cur.pop()
            self.contours.append(self.cur)
        self.cur = []

    _endPath = _closePath


def area(c):
    return 0.5 * sum(c[i][0] * c[(i + 1) % len(c)][1] - c[(i + 1) % len(c)][0] * c[i][1] for i in range(len(c)))


def build(font_path, CAP_H, fit, track, space):
    f = TTFont(font_path)
    gs = f.getGlyphSet()
    cmap = f.getBestCmap()
    cap = getattr(f["OS/2"], "sCapHeight", 0) or 700
    s = CAP_H / cap
    x = 0.0
    letters = []
    for ch in TEXT:
        if ch == " ":
            x += CAP_H * space
            continue
        g = gs[cmap[ord(ch)]]
        pen = FlatPen(gs)
        g.draw(pen)
        cs = [[(x + px * s, py * s) for px, py in c] for c in pen.contours]
        # overlapping contours (a serif H is two stems and a bar) are merged first; a contour wound against the
        # glyph's biggest one is a hole
        big = max(cs, key=lambda c: abs(area(c)))
        sgn = 1.0 if area(big) > 0 else -1.0
        solid = unary_union([Polygon(c).buffer(0) for c in cs if area(c) * sgn > 0])
        for c in cs:
            if area(c) * sgn < 0:
                solid = solid.difference(Polygon(c).buffer(0))
        tris = []
        loops = []
        for pg in (solid.geoms if hasattr(solid, "geoms") else [solid]):
            pg = orient(pg, 1.0)                 # outer loops counter-clockwise, holes clockwise
            rings = [list(pg.exterior.coords)[:-1]] + [list(r.coords)[:-1] for r in pg.interiors]
            verts = np.array([p for r in rings for p in r], dtype=np.float64)
            ends = np.cumsum([len(r) for r in rings]).astype(np.uint32)
            idx = earcut.triangulate_float64(verts, ends)
            tris += [[round(float(verts[i][0]), 5), round(float(verts[i][1]), 5)] for i in idx]
            loops += [[[round(p[0], 5), round(p[1], 5)] for p in r] for r in rings]
        letters.append({"ch": ch, "tris": tris, "loops": loops})
        x += g.width * s + track
    # condensed to the canopy: every x scaled so the words are `fit` wide
    k = fit / (x - track)
    for L in letters:
        L["tris"] = [[round(p[0] * k, 5), p[1]] for p in L["tris"]]
        L["loops"] = [[[round(p[0] * k, 5), p[1]] for p in lp] for lp in L["loops"]]
    x = fit + track
    return {"text": TEXT, "cap_h": CAP_H, "width": round(x - track, 5), "glow_pad": 0.0, "letters": letters,
            "note": "make_entrance_letters.py from " + os.path.basename(font_path)}


for name, font, cap_h, fit, track, space in SETS:
    J = build(font, cap_h, fit, track, space)
    json.dump(J, open(os.path.join(HERE, name), "w"), separators=(",", ":"))
    print(name, "width %.2f m" % J["width"], "cap %.2f m" % J["cap_h"], len(J["letters"]), "letters")
