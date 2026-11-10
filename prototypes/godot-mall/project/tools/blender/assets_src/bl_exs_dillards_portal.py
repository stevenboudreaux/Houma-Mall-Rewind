"""Dillard's, the entrance-portal letters on the Bayou Gardens face (s2s; Workstream EXT-SIGNS, Nov 9 2026;
design/exterior/signage-research.md "Dillard's"). Placed by tools/exterior/signs.gd on the portal's entablature
(exterior.gd portal()), both years.

Sources: refs new/dillards_exterior and IMG_4490 f045-f048: "white stucco with a recessed sign band carrying
black serif cut-out 'Dillard's' letters, pin-mounted and slightly faded" (notes_E); the shadow of each letter on
the band shows the gap. Same letterform as bl_exs_dillards (Libre Caslon Text 600, OFL).
Sizes: cap 0.8 m (the D against the 2.4 m door frames in f046); cut-out letters 0.03 m thick (they read as flat
plates, not cans, in f047) on 0.04 m studs. Guessed: the thickness, the edge colour. Unlit (no can to light).
Origin: on the band, centred on the word.
"""
from lib import core
import _exsign as X

CAP = 0.8
THICK = 0.03
GAP = 0.04
WORD = "Dillard’s"

META = {
    "id": "bl_exs_dillards_portal",
    "class": "small_fixture",
    "tex": 512,
    "ao": 0.3,
    "out": "exterior/signs",
    "refs": [["refs/derived/frames/IMG_4490/f047.jpg", [0.0, 0.1, 1.0, 0.6], "IMG_4490 f047: the portal letters"]],
}


def build():
    f = X.font("LibreCaslonText-SemiBold.ttf")
    m_face = X.face_mat("face", "#1a1918", 0.6)
    m_edge = X.paint("edge", "#2b2622", 0.5, 0.3, 0.0)
    m_pin = X.paint("pin", "#5a5a58", 0.5, 0.6, 0.0)
    parts, face = X.channel_word(WORD, f, CAP, THICK, GAP, m_face, m_edge, m_edge, trim_w=0.0, res=3,
                                 spacing=1.06, cap_ref="D", face_proud=0.0)
    X.recentre(parts, face)
    parts.append(X.pins(face, -GAP, GAP, m_pin, r=0.008))
    sh = X.contact_shadow(face, "shadow", 0.045, 0.01)
    X.check(parts + [sh])
    for p in parts:
        core.bevel(p, 0.0015, 1, 40.0)
