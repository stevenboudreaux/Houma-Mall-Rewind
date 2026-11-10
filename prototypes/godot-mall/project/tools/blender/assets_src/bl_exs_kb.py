"""K&B, the 1995 oval on the cream band of K&B's bay on the east facade (s25; Workstream EXT-SIGNS, Nov 9 2026;
design/exterior/signage-research.md "K&B"). Placed by tools/exterior/signs.gd where kb_bay() drew the flat purple
oval and the "K&B" label. 1995 only: K&B was sold to Rite Aid in 1997 and the purple signs came down (Gambit /
myneworleans); the 2026 face is Hypervelocity's and is left alone.

Sources: the logo as the mall sign already has it (tools/stores/signs/make_kb_oval.py: a purple oval 1.40 : 1,
gold rim, a thin red line inside it, white K&B traced from Steven's logo photo, which is of a LIT K&B sign, and the
1990s Houma newspaper ad); "K&B purple" on every sign (Wikipedia, St Tammany library, dirtycoast). The letters are
that trace (kb_letters_logo.json), not a web bitmap. The bay: refs IMG_4493 f011, IMG_4406 f004 (the canopy).
Sizes: 1.45 m tall (the 1.6 m band, exterior.gd kb_bay), 2.03 m wide; a 0.3 m deep cabinet.
Option A (default): a lit cabinet: translucent purple face with the red line, the white K&B letters as push-through
acrylic 15 mm proud, a gold retainer rim, purple painted returns, on a hidden rail 20 mm off the band.
EXS_VARIANT=B: an unlit purple panel with the gold rim and lit white K&B channel letters standing off it on studs.
Guessed: the cabinet depth, the rail, how it was lit (the photo shows it lit; not how). Origin: on the band,
centred on the oval.
"""
import os
import bpy
from lib import core
import _exsign as X

VAR = os.environ.get("EXS_VARIANT", "A")
H = 1.45
K = H / 1.25                       # make_kb_oval.py's frame is 1.25 m tall
RX, RY = 1.75 * 0.5 * K, H * 0.5
RIM = 0.07 * RY * 1.0              # the gold rim's width (make_kb_oval.py: 0.07 ry)
GAP = 0.02
D = 0.30
LOGO = os.path.join(X.PROJ, "tools", "stores", "signs", "kb_letters_logo.json")

META = {
    "id": "bl_exs_kb" + ("" if VAR == "A" else "_optb"),
    "class": "small_fixture",
    "tex": 512,
    "ao": 0.3,
    "out": "exterior/signs" if VAR == "A" else "exterior/signs/options",
    "refs": [["refs/derived/frames/IMG_4493/f011.jpg", [0.0, 0.25, 1.0, 0.75], "IMG_4493 f011: the bay (Hypervelocity today)"]],
}


def build():
    m_purple = X.face_mat("face", "#5b2a86", 0.35)               # lit in the game (ex_sign_kb_face)
    m_line = X.face_mat("line", "#c8202e", 0.4)                  # the red line, lit with the face
    m_letters = X.face_mat("letters", "#f6f3ff", 0.3)            # white K&B (ex_sign_kb_letters)
    m_ret = X.paint("return", "#3e1d5c", 0.45, 0.1)
    m_gold = X.paint("gold", "#c79a3c", 0.3, 0.8, 0.0)
    m_white = X.paint("acrylic", "#eeeaf4", 0.3, 0.0, 0.0)
    parts = []
    yb = -GAP
    if VAR == "A":
        yf = -(GAP + D)
        parts.append(X.ellipse_band("cab", RX, RY, yb, yf, m_ret))
        parts.append(X.ellipse_ring("cab_back", RX, RY, 0.0, 0.0, yb, m_ret))
        parts.append(X.ellipse_ring("face", RX - RIM * 0.5, RY - RIM * 0.5, 0.0, 0.0, yf, m_purple))
        parts.append(X.ellipse_ring("line", RX - RIM * 1.07, RY - RIM * 1.07, RX - RIM * 1.36, RY - RIM * 1.36, yf - 0.001, m_line))
        # the gold retainer: a ring on the face's edge and its own short return
        parts.append(X.ellipse_ring("rim", RX + 0.006, RY + 0.006, RX - RIM, RY - RIM, yf - 0.012, m_gold))
        parts.append(X.ellipse_band("rim_side", RX + 0.006, RY + 0.006, yf + 0.01, yf - 0.012, m_gold))
        ls, lf = X.logo_letters(LOGO, K, 0.015, GAP + D, m_letters, m_white, m_white, rim_w=0.004)
        parts += ls
        # the hidden rail
        parts.append(X.box("rail", -RX * 0.6, RX * 0.6, yb, 0.0, -0.08, 0.08, m_ret))
    else:
        yf = -(GAP + 0.08)
        parts.append(X.ellipse_band("panel", RX, RY, yb, yf, m_ret))
        parts.append(X.ellipse_ring("panel_face", RX, RY, 0.0, 0.0, yf, X.paint("panel", "#5b2a86", 0.5)))
        parts.append(X.ellipse_ring("line", RX - RIM * 1.07, RY - RIM * 1.07, RX - RIM * 1.36, RY - RIM * 1.36, yf - 0.002, m_line))
        parts.append(X.ellipse_ring("rim", RX + 0.006, RY + 0.006, RX - RIM, RY - RIM, yf - 0.012, m_gold))
        parts.append(X.ellipse_band("rim_side", RX + 0.006, RY + 0.006, yf, yf - 0.012, m_gold))
        ls, lf = X.logo_letters(LOGO, K, 0.08, GAP + 0.08 + 0.03, m_letters, m_ret, m_gold, rim_w=0.008)
        parts += ls
        parts.append(X.pins(lf, -(GAP + 0.08 + 0.03), 0.03, X.paint("pin", "#5a5a58", 0.5, 0.6, 0.0), r=0.008))
    disc = X.ellipse_ring("_sh", RX, RY, 0.0, 0.0, 0.0, m_ret)
    parts.append(X.contact_shadow(disc, "shadow", 0.16, 0.03))
    bpy.data.objects.remove(disc)
    X.check(parts)
