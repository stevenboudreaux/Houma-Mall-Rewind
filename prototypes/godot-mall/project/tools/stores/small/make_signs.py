"""Outlines of the Wave 5 small shops' signs, for store.gd to extrude or trace in neon:
GNC's three red letters, MasterCuts' white condensed lettering, Coach House's white serif
capitals, Wicks 'N' Sticks' white rounded letters, Chick-fil-A's script name (traced in
neon). Stand-in faces: FreeSans Bold, DejaVu Sans Condensed Bold, DejaVu Serif, Nunito
Black (OFL, tools/stores/media) and Mr Dafoe (OFL, tools/stores/gumballs). Uses
tools/stores/apparel/make_signs.py's approach. Writes tools/stores/small/*_letters.json.
  python3 tools/stores/small/make_signs.py   (from the project folder)
"""
import os, shutil, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "pocket_change"))
import make_letters as ml
from fontTools.pens.boundsPen import BoundsPen

_TT = ml.TTFont


def _tt(path):
    f = _TT(path)
    os2 = f["OS/2"]
    if not getattr(os2, "sCapHeight", 0):
        bp = BoundsPen(f.getGlyphSet())
        f.getGlyphSet()["H"].draw(bp)
        os2.sCapHeight = int(bp.bounds[3])
    return f


ml.TTFont = _tt
DJ = "/usr/share/fonts/truetype/dejavu/"
SIGNS = [
    ("gnc_letters.json", "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf", "GNC", 0.5, 0.04, 0.5),
    ("mc_letters.json", DJ + "DejaVuSansCondensed-Bold.ttf", "MasterCuts", 0.28, 0.01, 0.5),
    ("ch_letters.json", DJ + "DejaVuSerif.ttf", "COACH HOUSE", 0.32, 0.08, 1.2),
    ("ws_letters.json", os.path.join(HERE, "..", "media", "Nunito-Black.ttf"), "Wicks 'N' Sticks", 0.26, 0.01, 0.8),
    ("cfa_letters.json", os.path.join(HERE, "..", "gumballs", "MrDafoe-Regular.ttf"), "Chick-fil-A", 0.42, 0.0, 0.5),
]
for out, font, text, cap, track, space in SIGNS:
    ml.HERE = HERE
    ml.FONT = font
    ml.TEXT = text
    ml.CAP_H = cap
    ml.TRACK = track
    ml.SPACE = space
    ml.main()
    shutil.move(os.path.join(HERE, "letters.json"), os.path.join(HERE, out))

# Wave 6 (store2.gd): Radio Shack's red wordmark, B. Dalton's white script, Karmelkorn's red
# slab-serif capitals with a big K, Zales' silver capitals
MORE = [
    ("rs_letters.json", DJ + "DejaVuSerif-BoldItalic.ttf", "Radio Shack", 0.30, 0.0, 0.6),
    ("bd_letters.json", os.path.join(HERE, "..", "gumballs", "MrDafoe-Regular.ttf"), "B. Dalton", 0.5, 0.0, 0.5),
    ("bd_sub_letters.json", DJ + "DejaVuSerif.ttf", "BOOKSELLER", 0.09, 0.2, 0.9),
    ("kk_letters.json", os.path.join(HERE, "..", "woolworth", "RobotoSlab-ExtraBold.ttf"), "KARMELKORN", 0.5, 0.03, 0.5),
    ("zl_letters.json", "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf", "ZALES", 0.34, 0.06, 0.5),
    ("zl_sub_letters.json", "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf", "JEWELERS", 0.11, 0.2, 0.5),
]
if __name__ == "__main__":
    for out, font, text, cap, track, space in MORE:
        ml.HERE = HERE
        ml.FONT = font
        ml.TEXT = text
        ml.CAP_H = cap
        ml.TRACK = track
        ml.SPACE = space
        ml.main()
        shutil.move(os.path.join(HERE, "letters.json"), os.path.join(HERE, out))

# Wave 7 (wave7.gd)
W7 = [
    ("mgr_merry.json", os.path.join(HERE, "..", "media", "Nunito-Black.ttf"), "MERRY", 0.42, 0.02, 0.5),
    ("mgr_go.json", os.path.join(HERE, "..", "media", "Nunito-Black.ttf"), "GO", 0.42, 0.02, 0.5),
    ("mgr_round.json", os.path.join(HERE, "..", "media", "Nunito-Black.ttf"), "ROUND", 0.42, 0.02, 0.5),
    ("jn_letters.json", os.path.join(HERE, "..", "gumballs", "MrDafoe-Regular.ttf"), "Jean Nicole", 0.55, 0.0, 0.5),
    ("champs_letters.json", DJ + "DejaVuSerif-Bold.ttf", "CHAMPS", 0.32, 0.04, 0.5),
    ("champs_sub.json", "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf", "SPORTS", 0.12, 0.25, 0.5),
    ("avenue_letters.json", DJ + "DejaVuSerif-Bold.ttf", "AVENUE", 0.24, 0.12, 0.5),
    ("regis_letters.json", "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf", "REGIS", 0.42, 0.06, 0.5),
    ("oj_letters.json", os.path.join(HERE, "..", "gumballs", "MrDafoe-Regular.ttf"), "Orange Julius", 0.40, 0.0, 0.5),
    ("at_letters.json", "/usr/share/fonts/opentype/inter/Inter-Light.otf", "afterthoughts", 0.30, 0.01, 0.5),
]
if __name__ == "__main__":
    for out, font, text, cap, track, space in W7:
        ml.HERE = HERE
        ml.FONT = font
        ml.TEXT = text
        ml.CAP_H = cap
        ml.TRACK = track
        ml.SPACE = space
        ml.main()
        shutil.move(os.path.join(HERE, "letters.json"), os.path.join(HERE, out))

# Wave 8 (wave8.gd): Optical Outlet's fat round letters, Tee Tai's gold brush script,
# Saadi's heavy serif
W8 = [
    ("oo_letters.json", os.path.join(HERE, "..", "media", "Nunito-Black.ttf"), "Optical Outlet", 0.36, 0.01, 0.5),
    ("tt_letters.json", os.path.join(HERE, "..", "gumballs", "MrDafoe-Regular.ttf"), "Tee Tai's", 0.42, 0.0, 1.3),
    ("saadi_letters.json", DJ + "DejaVuSerif-Bold.ttf", "Saadi's", 0.40, 0.02, 0.5),
]
if __name__ == "__main__":
    for out, font, text, cap, track, space in W8:
        ml.HERE = HERE
        ml.FONT = font
        ml.TEXT = text
        ml.CAP_H = cap
        ml.TRACK = track
        ml.SPACE = space
        ml.main()
        shutil.move(os.path.join(HERE, "letters.json"), os.path.join(HERE, out))

# Wave 9 (wave9.gd): Solarium's aqua neon, Rave's heavy italics, Country Fair's cream serif,
# American Bank's heavy rounded white letters
GF = "/usr/share/fonts/truetype/google-fonts/"
W9 = [
    ("sol_letters.json", GF + "Poppins-Medium.ttf", "solarium", 0.34, 0.01, 0.5),
    ("rave_letters.json", os.path.join(HERE, "..", "media", "Nunito-BlackItalic.ttf"), "RAVE", 0.5, 0.03, 0.5),
    # Nov 1, 2026 (Steven: "upright letters"): DejaVu Serif Bold, was Bold Italic
    ("cf_letters.json", DJ + "DejaVuSerif-Bold.ttf", "Country Fair", 0.3, 0.0, 0.8),
    ("ab_american.json", os.path.join(HERE, "..", "media", "Nunito-Black.ttf"), "American", 0.42, 0.0, 0.5),
    ("ab_bank.json", os.path.join(HERE, "..", "media", "Nunito-Black.ttf"), "Bank", 0.42, 0.0, 0.5),
]
if __name__ == "__main__":
    for out, font, text, cap, track, space in W9:
        ml.HERE = HERE
        ml.FONT = font
        ml.TEXT = text
        ml.CAP_H = cap
        ml.TRACK = track
        ml.SPACE = space
        ml.main()
        shutil.move(os.path.join(HERE, "letters.json"), os.path.join(HERE, out))
