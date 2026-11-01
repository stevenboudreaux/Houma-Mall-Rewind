"""Martin Folse's stick: the plain white pointer the HTV Houma weatherman laid on the radar map to call
landfall (design/godot-stockrooms.md, scripts/stockrooms.gd _stick()). Hand item folse_stick
(data/items/stockrooms.json); this model replaces the two cylinders in scripts/items/folse_stick.tscn.
Same size and origin as the stand-in: 1.22 m, the butt at the origin, the tip up (+Z here, +Y in Godot).

A wooden classroom-style pointer painted white: thicker at the grip, tapering to a slim shaft, a grey
rubber tip cap, and a turned collar where the grip ends. Worn the way a prop handled on
air for years would be: the paint greyed and scuffed where the hand holds it, a few chips showing wood,
faint marker smudges near the tip from the map board.
The paint keeps a faint glow of its own (the stand-in's emission 0.9 on white): META "emissive" makes
build.py set the glTF emissive texture to the baked albedo at that strength.

References: none of the real stick; stockrooms.gd (white, ~4 ft, worn tip). Guessed: the collar, the wear.
"""
import math
from lib import core, parts, mats

L = 1.22
R_BUTT, R_TIP = 0.0145, 0.0085
CAP = 0.045

META = {
    "id": "bl_sr_folse_stick",
    "class": "hand",
    "tex": 1024,
    "ao": 0.25,
    "uv": "smart",
    "emissive": 0.35,
    "icon": True,
    "refs": [],
}


def paint_mat():
    m = mats.M("paint", "#f2f0ea", 0.42)
    tc = m.coords()
    sep = m.node("ShaderNodeSeparateXYZ")
    m.link(tc, sep.inputs[0])
    z = sep.outputs["Z"]
    # hand grime: greyer over the grip (z 0.05-0.35), fading out
    grip = m.ramp(z, [(0.03, "#000000"), (0.10, "#ffffff"), (0.30, "#ffffff"), (0.45, "#000000")])
    n = m.noise(80.0, 4.0, coord=tc)
    grime = m.math("MULTIPLY", grip, m.math("MULTIPLY_ADD", n.outputs["Fac"], 0.6, 0.0))
    col = m.mix(grime, "#f2f0ea", "#c9c4b8")
    # chips in the paint showing the wood (sparse, mostly near the ends)
    chips = m.node("ShaderNodeTexVoronoi", Scale=180.0)
    m.link(tc, chips.inputs["Vector"])
    ends = m.ramp(z, [(0.0, "#ffffff"), (0.25, "#606060"), (0.9, "#606060"), (1.2, "#ffffff")])
    chip = m.math("MULTIPLY", m.math("LESS_THAN", chips.outputs["Distance"], 0.07), m.math("GREATER_THAN", ends, 0.5))
    col2 = m.mix(chip, col, "#b08a5a")
    # faint blue and red marker smudges near the tip (the map board)
    tipz = m.ramp(z, [(1.0, "#000000"), (1.08, "#ffffff"), (1.16, "#000000")])
    sm = m.noise(40.0, 3.0, coord=tc)
    smudge = m.math("MULTIPLY", tipz, m.math("GREATER_THAN", sm.outputs["Fac"], 0.58))
    col3 = m.mix(m.math("MULTIPLY", smudge, 0.35), col2, "#4a6aa8")
    m.link(col3, m.bsdf.inputs["Base Color"])
    m.bump(m.math("SUBTRACT", n.outputs["Fac"], chip), 0.15, 0.0004)
    return m.mat


def build():
    pm = paint_mat()
    # the shaft: a turned taper with a slight swell at the grip
    prof = [(0.0, 0.0), (R_BUTT - 0.002, 0.0), (R_BUTT, 0.002), (R_BUTT, 0.03), (R_BUTT + 0.0012, 0.12), (R_BUTT, 0.30),
            (R_BUTT * 0.88, 0.55), (R_TIP * 1.15, 0.95), (R_TIP, L - CAP + 0.004), (0.0, L - CAP + 0.004)]
    parts.lathe("shaft", prof, seg=16, mat=pm)
    # a turned collar where the grip ends
    parts.lathe("collar", [(R_BUTT + 0.0005, 0.315), (R_BUTT + 0.0024, 0.318), (R_BUTT + 0.0024, 0.326), (R_BUTT + 0.0005, 0.329)],
                seg=16, mat=pm, cap=False)
    # the rubber tip cap, grey, a little dome
    rub = mats.M("tip", "#8e8a82", 0.85)
    rub.bump(rub.noise(300.0, 2.0).outputs["Fac"], 0.2, 0.0004)
    parts.lathe("tip", [(0.0, L - CAP), (R_TIP + 0.0012, L - CAP), (R_TIP + 0.0016, L - CAP + 0.004), (R_TIP + 0.0014, L - 0.006),
                        (R_TIP * 0.8, L - 0.0015), (0.0, L)], seg=16, mat=rub.mat)
