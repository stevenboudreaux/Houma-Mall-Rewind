"""SEARS HARDWARE, the 1995 sign on the separate box by Armour Dr ("Old Sears Hardware" on Steven's annotated plan,
Unitech today; Workstream EXT-SIGNS, Nov 9 2026; design/exterior/signage-research.md "Sears Hardware / Unitech").
Placed by tools/exterior/signs.gd on the box's lot-facing wall, over its doors. 1995 only.

Sources: the southernretail blog on Southland (2012): "a Sears Hardware store behind the building, across the
parking lot"; Steven's plan (design/exterior/site-plan-annotated-2026-11-08.png). No picture of its sign: the
form follows the parent store's 1990s sign (bl_exs_sears: blue capitals, lit channel letters on a raceway),
"HARDWARE" in the same letter at 0.55 of the cap. A GUESS throughout; Archivo Black (OFL).
Sizes: SEARS cap 1.0 m, HARDWARE 0.55 m, one line, on a 7 m wall (H_UNITECH). Origin: on the wall, centred.

EXS_VARIANT=B: SEARS over HARDWARE on a lit white cabinet (the options sheet).
"""
import os
from lib import core
import _exsign as X

VAR = os.environ.get("EXS_VARIANT", "A")
CAP = 1.0
DEPTH = 0.1
BLUE = "#1f4fa8"

META = {
    "id": "bl_exs_sears_hw" + ("" if VAR == "A" else "_optb"),
    "class": "small_fixture",
    "tex": 1024,
    "ao": 0.3,
    "out": "exterior/signs" if VAR == "A" else "exterior/signs/options",
    "refs": [["refs/derived/frames/IMG_4486/f010.jpg", [0.0, 0.3, 1.0, 0.55], "IMG_4486 f010: the box, far back (unsigned today)"]],
}


def _shift(objs, dx, dz):
    from mathutils import Matrix
    for o in objs:
        o.data.transform(Matrix.Translation((dx, 0.0, dz)))


def build():
    f = X.font("ArchivoBlack-Regular.ttf")
    m_face = X.face_mat("face", BLUE if VAR == "A" else BLUE, 0.3)
    m_ret = X.paint("return", "#18306a", 0.4, 0.2)
    m_trim = X.paint("trim", BLUE, 0.35, 0.3, 0.0)
    m_race = X.paint("raceway", "#e9e7e1", 0.6)
    if VAR == "A":
        p1, f1 = X.channel_word("SEARS", f, CAP, DEPTH, 0.18, m_face, m_ret, m_trim, res=3, spacing=1.04)
        p2, f2 = X.channel_word("HARDWARE", f, CAP * 0.55, DEPTH, 0.18, m_face, m_ret, m_trim, res=2, spacing=1.04)
        w1 = X.word_bounds(f1); w2 = X.word_bounds(f2)
        gap = 0.45
        W = (w1[1] - w1[0]) + gap + (w2[1] - w2[0])
        _shift(p1, -W * 0.5 - w1[0], -w1[2] - CAP * 0.5)
        _shift(p2, -W * 0.5 + (w1[1] - w1[0]) + gap - w2[0], -w2[2] - CAP * 0.5)
        parts = p1 + p2
        parts.append(X.box("raceway", -W * 0.5 + 0.1, W * 0.5 - 0.1, -0.18, 0.0, -CAP * 0.5 + 0.05, -CAP * 0.5 + 0.25, m_race))
        parts.append(X.contact_shadow([f1, f2], "shadow", 0.12, 0.02))
    else:
        p1, f1 = X.channel_word("SEARS", f, CAP, 0.02, 0.25, m_face, m_ret, m_trim, trim_w=0.0, back=False)
        p2, f2 = X.channel_word("HARDWARE", f, CAP * 0.5, 0.02, 0.25, X.face_mat("face2", "#c8202e"), m_ret, m_trim,
                                trim_w=0.0, back=False, res=2)
        X.recentre(p1, f1); X.recentre(p2, f2)
        _shift(p1, 0.0, CAP * 0.45); _shift(p2, 0.0, -CAP * 0.55)
        w = max(X.word_bounds(f1)[1], X.word_bounds(f2)[1]) * 2 + 0.8
        ch = CAP * 2.4
        parts = p1 + p2
        parts.append(X.box("cab_face", -w * 0.5, w * 0.5, -0.251, -0.25, -ch * 0.5, ch * 0.5, X.face_mat("cabinet", "#f4f4f0")))
        parts.append(X.box("cab_body", -w * 0.5, w * 0.5, -0.25, 0.0, -ch * 0.5, ch * 0.5, m_ret))
    X.check(parts)
    for p in parts:
        if not p.name.startswith("shadow"):
            core.bevel(p, 0.0025, 1, 40.0)
