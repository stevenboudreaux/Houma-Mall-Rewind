"""UNITECH, an OPTIONS-SHEET MOCK ONLY (Workstream EXT-SIGNS, Nov 9 2026; design/exterior/signage-research.md
"Sears Hardware / Unitech"). Unitech Training Academy (6007 West Park Ave; Houma campus since 2006, unitechta.edu)
is in the old Sears Hardware box today, but its 2026 sign is not legible in any frame (IMG_4486 f010, f072: the
box far back across the lot) and its logo could not be looked up from the cloud session. Steven (Nov 8) left the
box unsigned in both years. This is option B for 2026: plain white capitals, a GUESS, built only if Steven
picks it. Archivo Black (OFL), cap 0.9 m.
"""
from lib import core
import _exsign as X

META = {
    "id": "bl_exs_unitech_optb",
    "class": "small_fixture",
    "tex": 512,
    "ao": 0.3,
    "out": "exterior/signs/options",
    "refs": [["refs/derived/frames/IMG_4486/f072.jpg", [0.0, 0.3, 1.0, 0.55], "IMG_4486 f072: the box today"]],
}


def build():
    f = X.font("ArchivoBlack-Regular.ttf")
    parts, face = X.channel_word("UNITECH", f, 0.9, 0.08, 0.04, X.face_mat("face", "#f4f6fa"),
                                 X.paint("return", "#2a2f3a", 0.4, 0.3), X.paint("trim", "#c9cbd0", 0.3, 0.7, 0.0))
    X.recentre(parts, face)
    parts.append(X.pins(face, -0.04, 0.04, X.paint("pin", "#5a5a58", 0.5, 0.6, 0.0), r=0.01))
    parts.append(X.contact_shadow(face, "shadow", 0.08, 0.02))
    X.check(parts)
