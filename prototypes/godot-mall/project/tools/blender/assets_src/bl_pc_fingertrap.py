"""A Chinese finger trap from Pocket Change's prize counter (Steven's test item). Pocket item, 1995.

The prize counter already lists it (scripts/prizes.json "finger_trap", 15 tickets; design/godot-prize-counter.md)
and paints far-off ones in bins with the colours natural bamboo, red, blue, green, yellow, pink, white
(scripts/prizes.gd _traps). This one is natural + red.
Shape: a woven bamboo tube ~15 x 1.5 cm, open at both ends, tapering toward the ends (the braid narrows
when pulled), a 2-over-2 diagonal (twill) weave of thin strips, one direction natural, the other dyed.

Weave: real weave geometry would be ~24 helical strips each way, 20-40k triangles for a 2k-triangle pocket
item, and the trap's silhouette is a smooth tube anyway. So the weave is procedural in the shader (strip
helices computed from the angle around the tube, so they narrow with the taper like a real braid) and baked
into albedo + a normal map at 1024 px (~0.1 mm per texel on the tube): up close in the hand the strips,
their over/under and the gaps between them read in the light; the outline stays a smooth low-poly tube.
Origin: bottom centre, lying along X (Godot X), resting on its side.
"""
import math
from lib import core, parts, mats

# ---- numbers (metres) ---------------------------------------------------------------------------
LENGTH = 0.150
R_BODY = 0.0075           # 1.5 cm across the middle
R_END = 0.0056            # the ends taper
TAPER = 0.028             # length of each taper
WALL = 0.0007             # strip thickness
SEG = 24                  # around the tube
N_STRANDS = 12            # strips per direction around the circumference
HELIX = 0.050             # axial advance of one strip per turn at the body (about 45 degrees)
COL_A = "#d8c08a"         # natural bamboo
COL_B = "#c8343c"         # dyed red
GAP_SHADE = 0.45          # how dark the gaps between strips get

META = {
    "id": "bl_pc_fingertrap",
    "class": "pocket",
    "tex": 1024,
    "ao": 0.3,
    "refs": [],
    "item": {"name": "Chinese finger trap", "year": 1995, "store": "POCKET CHANGE", "tickets": 15, "prize": "finger_trap"},
}


def profile():
    """Outer surface end to end, then the rim and the inner surface back (an open, walled tube along Z)."""
    zs = [0.0, 0.004, 0.010, 0.018, TAPER, 0.045, 0.060, 0.075]
    zs = zs + [LENGTH - z for z in reversed(zs[:-1])]

    def r(z):
        d = min(z, LENGTH - z)
        if d >= TAPER:
            return R_BODY
        t = d / TAPER
        return R_END + (R_BODY - R_END) * (1 - (1 - t) ** 2)
    outer = [(r(z), z) for z in zs]
    inner = [(r(z) - WALL, z) for z in reversed(zs) if z in (0.0, TAPER, LENGTH / 2, LENGTH - TAPER, LENGTH)]
    return outer + [(r(LENGTH) - WALL, LENGTH)] + inner[1:]


def weave_mat():
    m = mats.M("weave", COL_A, 0.5)
    tc = m.coords()
    # the tube lies along X with its axis at height R_BODY
    off = m.node("ShaderNodeVectorMath", operation="SUBTRACT")
    off.inputs[1].default_value = (0, 0, R_BODY)
    m.link(tc, off.inputs[0])
    sep = m.node("ShaderNodeSeparateXYZ")
    m.link(off.outputs["Vector"], sep.inputs[0])
    th = m.math("ARCTAN2", sep.outputs["Z"], sep.outputs["Y"])
    s = m.math("MULTIPLY", th, N_STRANDS / math.tau)
    ax = m.math("MULTIPLY", sep.outputs["X"], N_STRANDS / HELIX)
    u = m.math("ADD", s, ax)
    v = m.math("SUBTRACT", s, ax)
    iu, iv = m.math("FLOOR", u), m.math("FLOOR", v)
    fu, fv = m.math("FRACT", u), m.math("FRACT", v)
    # 2-over-2 twill: which direction is on top here
    over = m.math("LESS_THAN", m.math("FLOORED_MODULO", m.math("ADD", iu, iv), 4.0), 2.0)
    # a strip's cross-profile: round on top, falling into the gap at both edges
    hu = m.math("POWER", m.math("SINE", m.math("MULTIPLY", fu, math.pi)), 0.6)
    hv = m.math("POWER", m.math("SINE", m.math("MULTIPLY", fv, math.pi)), 0.6)
    # the top strip's profile where it is on top, the other's elsewhere; the under strip sits lower
    top = m.math("ADD", m.math("MULTIPLY", over, hu), m.math("MULTIPLY", m.math("SUBTRACT", 1.0, over), hv))
    fib = m.noise(900.0, 2.0, 0.5, coord=tc)
    h = m.math("MULTIPLY_ADD", fib.outputs["Fac"], 0.08, top)
    col = m.mix(over, COL_B, COL_A)
    shade = m.node("ShaderNodeMix")
    shade.data_type = "RGBA"
    shade.blend_type = "MULTIPLY"
    shade.inputs["Factor"].default_value = 1.0
    m.link(col, shade.inputs[6])
    g = m.math("MULTIPLY_ADD", top, GAP_SHADE, 1.0 - GAP_SHADE)
    cg = m.node("ShaderNodeCombineColor")
    for k in ("Red", "Green", "Blue"):
        m.link(g, cg.inputs[k])
    m.link(cg.outputs["Color"], shade.inputs[7])
    # a little colour variation along the strips
    var = m.noise(60.0, 2.0, coord=tc)
    fin = m.node("ShaderNodeMix")
    fin.data_type = "RGBA"
    fin.blend_type = "OVERLAY"
    fin.inputs["Factor"].default_value = 0.25
    m.link(shade.outputs[2], fin.inputs[6])
    m.link(var.outputs["Color"], fin.inputs[7])
    m.link(fin.outputs[2], m.bsdf.inputs["Base Color"])
    m.bump(h, 0.9, 0.0005)
    return m.mat


def build():
    ob = parts.lathe("tube", profile(), seg=SEG, mat=weave_mat(), cap=False, sharp_angle=70)
    # lie along +X, resting on z=0
    ob.rotation_euler = (0, math.radians(90), 0)
    ob.location = (-LENGTH / 2, 0, R_BODY)
