"""Dillard's, the long-face letters (Workstream EXT-SIGNS, Nov 9 2026; design/exterior/signage-research.md
"Dillard's"). Placed by tools/exterior/signs.gd on the east (West Park) and south (Bayou Gardens) faces between
the two cream cornices, where the flat labels were; both years (Dillard's has held the D.H. Holmes building since
1989 and kept its Canal Street skin: the southernretail blog on Southland, 2012).

Sources: refs IMG_4490 f002-f016 (the west/south letters, sharp in f013): black serif "Dillard's", deep cans with
a thin bronze edge, standing off the scored peach EIFS on studs; notes_E IMG_4490. The letterform is Libre Caslon
Text at 600 (OFL), a close old-style serif, not a trace of the trademark; the apostrophe is the curly one, as on
the wall.
Sizes (f013 against the cornices, 9.8 / 13.4 m in tools/exterior/exterior.gd): the D's cap about 55 % of the band =
2.0 m; cans 0.14 m deep; 0.05 m studs (the gap and its shadow show in f013).
Guessed: the returns' bronze, the stud count. Unlit (option A, the default); EXS_VARIANT=B adds a halo
(reverse-channel) silhouette on the wall for the options sheet. Origin: on the wall, centred on the word.
"""
import os
from lib import core
import _exsign as X

VAR = os.environ.get("EXS_VARIANT", "A")
CAP = 2.0
DEPTH = 0.14
GAP = 0.05
WORD = "Dillard’s"

META = {
    "id": "bl_exs_dillards" + ("" if VAR == "A" else "_optb"),
    "class": "small_fixture",
    "tex": 1024,
    "ao": 0.3,
    "out": "exterior/signs" if VAR == "A" else "exterior/signs/options",
    "refs": [["refs/derived/frames/IMG_4490/f013.jpg", [0.0, 0.05, 1.0, 0.45], "IMG_4490 f013: the letters on the wall"]],
}


def build():
    f = X.font("LibreCaslonText-SemiBold.ttf")
    m_face = X.face_mat("face", "#141312", 0.55)
    m_ret = X.paint("return", "#2a221c", 0.45, 0.5)
    m_trim = X.paint("trim", "#5b4532", 0.35, 0.7, 0.0)
    m_pin = X.paint("pin", "#4a4a48", 0.5, 0.6, 0.0)
    parts, face = X.channel_word(WORD, f, CAP, DEPTH, GAP, m_face, m_ret, m_trim, trim_w=0.01, res=3,
                                 spacing=1.06, cap_ref="D")
    X.recentre(parts, face)
    parts.append(X.pins(face, -GAP, GAP, m_pin, r=0.014))
    parts.append(X.contact_shadow(face, "shadow", 0.11, 0.025))
    if VAR == "B":
        halo = X.text_obj("halo", WORD, f, CAP, extrude=0.0, offset=0.07, fill="BOTH", res=2, spacing=1.06,
                          mat=X.face_mat("halo", "#ffe6c0", 0.9), y_front=-0.004, cap_ref="D")
        X.recentre([halo], face)
        parts.append(halo)
    X.check(parts)
    for p in parts:
        if not p.name.startswith(("halo", "shadow")):
            core.bevel(p, 0.002, 1, 40.0)
