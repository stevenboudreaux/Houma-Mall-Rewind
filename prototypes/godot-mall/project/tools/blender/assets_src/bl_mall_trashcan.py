"""The mall's trash can (workstream FOOD3D, Nov 8 2026): every one placed by tools/build_mall.gd trash() (halls,
one lane out from the bench groups, and court corners), both years. Static fixture, in the switchable
"Benches & plants" set (dynamic, no rebake).

Steven: the grey cylinder with a domed lid should read as a trash can, a real 1990s mall receptacle. The type: a
round painted-steel receptacle with a dome top and two side push-door openings (the common 1980s-90s mall can):
a dark kick ring, a slightly tapered body in warm grey enamel (orange-peel finish, scuffs low down), a rolled
brushed-steel rim band, the dome in the same enamel with two openings opposite each other, each with a swing flap
hinged at its top edge and pushed in a little, the dark inside and the black liner bag's rolled edge showing
through. Kept at the old can's size (0.58 m across the rim, 0.99 m tall), so placement and the floor obstacle
are unchanged. No brand, no words.
References: none of Southland's cans in the pack (refs/INDEX.md); the type from period mall photos generally.
Guessed: everything above (colour kept close to the old grey).
Budget: <= 1500 tris, one 1024 atlas. Origin: bottom centre; one opening faces -Y (Godot +Z).
"""
import math
import bpy
from lib import core, parts, mats

RB, RT, HB = 0.245, 0.268, 0.82     # body radius at the foot / under the rim, body height
RR = 0.288                          # rim band
DOME_H = 0.15
SEG = 24
OPEN_W, OPEN_H = 0.30, 0.095        # each opening (chord width, height) on the dome's side
ENAMEL = "#a8a399"

META = {
    "id": "bl_mall_trashcan",
    "class": "small_fixture",
    "tex": 1024,
    "ao": 0.45,
    "refs": [],
}


def enamel_mat():
    m = mats.M("enamel", ENAMEL, 0.42)
    tc = m.coords()
    peel = m.noise(900.0, 2.0, coord=tc)
    m.bump(peel.outputs["Fac"], 0.12, 0.0004)
    # scuffs and grime low on the body (shoes, mop water), a few scratches
    sep = m.node("ShaderNodeSeparateXYZ")
    m.link(tc, sep.inputs[0])
    low = m.math("LESS_THAN", m.math("ADD", sep.outputs["Z"], m.math("MULTIPLY", m.noise(12.0, 3.0, coord=tc).outputs["Fac"], 0.12)), 0.2)
    sc = m.math("GREATER_THAN", m.noise(60.0, 4.0, coord=tc).outputs["Fac"], 0.6)
    col = m.mix(m.math("MULTIPLY", m.math("MULTIPLY", low, sc), 0.5), ENAMEL, "#5e5a54")
    col = m.mix(m.math("MULTIPLY", m.math("GREATER_THAN", m.noise(5.0, 2.0, coord=tc).outputs["Fac"], 0.64), 0.12), col, "#a6a198")
    m.link(col, m.bsdf.inputs["Base Color"])
    return m.mat


def build():
    en = enamel_mat()
    steel = mats.brushed_metal("rim", "#b9bbbe", 0.32, along="Z", metal=0.7)
    kick = mats.M("kick", "#2a2a2c", 0.6).mat
    dark = mats.M("inside", "#141414", 0.9).mat
    liner = mats.M("liner", "#18181a", 0.35)
    liner.bump(liner.noise(60.0, 3.0).outputs["Fac"], 0.5, 0.002)
    # body: kick ring, enamel shell, the rolled rim band
    parts.lathe("kick", [(RB - 0.004, 0.0), (RB + 0.006, 0.0), (RB + 0.006, 0.05), (RB, 0.055)], seg=SEG, mat=kick, cap=False)
    parts.lathe("body", [(RB, 0.05), (RB + 0.002, 0.06), (RT, HB - 0.03), (RT + 0.004, HB - 0.02)], seg=SEG, mat=en, cap=False)
    parts.lathe("rim", [(RT + 0.004, HB - 0.02), (RR, HB - 0.012), (RR + 0.004, HB + 0.012), (RR, HB + 0.034),
                        (RR - 0.012, HB + 0.04)], seg=SEG, mat=steel, cap=False)
    # the dome: a solid shell from the rim up, two openings cut by a boolean, then a dark throat inside each
    top = HB + 0.04
    prof = [(RR - 0.012, top), (RR - 0.014, top + 0.03), (RR - 0.03, top + 0.075), (RR - 0.07, top + 0.115),
            (RR - 0.13, top + 0.14), (0.05, top + DOME_H), (0.0, top + DOME_H + 0.004)]
    dome = parts.lathe("dome", prof, seg=SEG, mat=en, cap=False, sharp_angle=50)
    core.solidify(dome, 0.004, -1.0)
    core.apply_all(dome)
    zc = top + 0.022 + OPEN_H / 2
    for s in (-1, 1):
        cut = parts.box("cut%d" % s, (OPEN_W, 0.3, OPEN_H), loc=(0, s * RR, zc), mat=dark, bev=0)
        bo = dome.modifiers.new("Open%d" % s, "BOOLEAN")
        bo.operation = "DIFFERENCE"
        bo.object = cut
        bo.solver = "EXACT"
        core.apply_all(dome)
        bpy.data.objects.remove(cut)
        # the swing flap: hinged at the opening's top edge, pushed 28 degrees in
        fl = parts.box("flap%d" % s, (OPEN_W - 0.07, 0.004, OPEN_H - 0.01), mat=en, bev=0.0015, seg=1)
        r_in = RR - 0.085
        fl.location = (0, s * r_in, zc - 0.004)
        fl.rotation_euler = (math.radians(-28 * s), 0, 0)
    # the dark inside of the dome (seen through the openings) and the liner bag's rolled edge over the rim
    parts.lathe("throat", [(RT - 0.03, top - 0.02), (RT - 0.04, top + 0.1), (0.0, top + 0.11)], seg=12, mat=dark, cap=False)
    parts.lathe("liner", [(RT - 0.006, HB - 0.03), (RT + 0.004, HB + 0.022), (RT - 0.012, HB + 0.034), (RT - 0.022, HB + 0.01)],
                seg=SEG, mat=liner.mat, cap=False)
