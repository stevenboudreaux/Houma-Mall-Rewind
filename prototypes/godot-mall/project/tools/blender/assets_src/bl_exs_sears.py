"""SEARS, the 1995 department-store sign on the old Sears box (Workstream EXT-SIGNS, Nov 9 2026;
design/exterior/signage-research.md "Sears"). Placed by tools/exterior/signs.gd on the east face over the s1e
customer entrance, and on the west and north faces where the flat "Sears" labels were. 1995 only (Lynn's in 2026
is out of scope and unchanged).

Sources: the wordmark of 1984-2004 was the name in bold blue CAPITALS (blue from 1994; lower-case only came in
2004: Fox News on the 2004 logo, "no longer in all capital letters"; logos-world); department stores carried it
as internally lit channel letters. The letterform here is Archivo Black (OFL), a heavy grotesque close to it,
not a trace of the trademark. The wall: refs IMG_4406 f031-035 (white painted box, charcoal eyebrow band; the
Lynn's sign sits over the doors today).
Sizes: cap 1.6 m centred at 6.6 m on the 9 m wall (the 2.1 m doors and the 3.65 m canopy in the same frames);
cans 0.13 m deep on a 0.24 x 0.2 m raceway painted the wall's white (option A); option B a 0.3 m deep cabinet.
Guessed: the returns' colour (blue, matching the faces), the raceway, the exact cap height. Origin: on the wall,
centred on the word.

EXS_VARIANT=B builds option B (white letters on a blue lit cabinet) for the options sheet.
"""
import os
from lib import core
import _exsign as X

VAR = os.environ.get("EXS_VARIANT", "A")
CAP = 1.6
DEPTH = 0.13
BLUE = "#1f4fa8"       # the 1994-2004 Sears blue, read off period prints (a GUESS within the family)
RET_BLUE = "#18306a"
WALL_WHITE = "#e9e7e1"

META = {
    "id": "bl_exs_sears" + ("" if VAR == "A" else "_optb"),
    "class": "small_fixture",
    "tex": 1024,
    "ao": 0.3,
    "out": "exterior/signs" if VAR == "A" else "exterior/signs/options",
    "refs": [["refs/derived/frames/IMG_4406/f033.jpg", [0.0, 0.0, 1.0, 1.0], "the old Sears box's east face, 2026"]],
}


def build():
    f = X.font("ArchivoBlack-Regular.ttf")
    m_face = X.face_mat("face", BLUE if VAR == "A" else "#f4f6fa", 0.3)
    m_ret = X.paint("return", RET_BLUE, 0.4, 0.2)
    m_trim = X.paint("trim", BLUE, 0.35, 0.3, 0.0)
    m_race = X.paint("raceway", WALL_WHITE, 0.6)
    m_pin = X.paint("pin", "#6b6b68", 0.5, 0.6, 0.0)
    if VAR == "A":
        parts, face = X.channel_word("SEARS", f, CAP, DEPTH, 0.2, m_face, m_ret, m_trim, res=3, spacing=1.04)
        w, h = X.recentre(parts, face)
        # the raceway across the word's middle, 0.24 tall, 0.2 deep, the cans fixed to its face
        parts.append(X.box("raceway", -w * 0.5 + 0.15, w * 0.5 - 0.15, -0.2, 0.0, -0.12, 0.12, m_race))
        # brackets at the raceway's ends
        for sx in (-1.0, 1.0):
            parts.append(X.box("bracket", sx * (w * 0.5 - 0.15) - 0.03, sx * (w * 0.5 - 0.15) + 0.03, -0.18, 0.0, -0.2, 0.2, m_pin))
        parts.append(X.contact_shadow(face, "shadow", 0.16, 0.03))
    else:
        parts, face = X.channel_word("SEARS", f, CAP * 0.82, 0.03, 0.30, m_face, m_ret, m_trim, trim_w=0.0,
                                     res=3, spacing=1.04, back=False)
        w, h = X.recentre(parts, face)
        cw, ch = w + 1.2, CAP * 0.82 + 0.8
        m_cab = X.face_mat("cabinet", BLUE, 0.3)
        # the cabinet: a lit blue face (its own material), painted returns
        parts.append(X.box("cab_face", -cw * 0.5, cw * 0.5, -0.301, -0.30, -ch * 0.5, ch * 0.5, m_cab))
        parts.append(X.box("cab_body", -cw * 0.5, cw * 0.5, -0.30, 0.0, -ch * 0.5, ch * 0.5, m_ret))
    X.check(parts)
    for p in parts:
        core.bevel(p, 0.003, 1, 40.0)
