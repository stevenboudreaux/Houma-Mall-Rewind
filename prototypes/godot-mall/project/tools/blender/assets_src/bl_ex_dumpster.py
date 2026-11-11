"""The outside's steel roll-off compactor container (workstream EXT-DOCKS, Nov 11 2026): the "green boxes" at
Dillard's dock and JCPenney's dock (tools/exterior/docks.gd), both years. Static prop, lightmapped with the outside.

Steven (Demo 53 walk): "the green rectangle on the ground (what even is that)"; then: keep them, texture them
properly: a real steel dumpster or compactor, ribbed sides, lids, wear, on a concrete pad (the pad is docks.gd's).
The type, from the footage: a closed roll-off container as it stands at both docks: a long steel box with vertical
channel ribs between a top and a bottom rail, a sloped lower nose at the hook end, a hinged full-width door with
cross ribs and a ratchet bar at the other end, two long skid rails on steel rollers, two hinged steel lids on top,
stains running down from the lid seams and rust along the bottom rail and the skids.
References: refs/derived/frames/IMG_4490/f026.jpg (Dillard's: ~2.2 m wide, ~2.1 m high, the nose and its legs),
IMG_4486/f108.jpg (JCPenney: ~7 m long, the ribs, the door end's rollers, the stains).
Guessed: the green (the footage's containers are tan today; the build's boxes were green and Steven keeps them),
the lids (the filmed ones are closed-top compactor receivers with a small hatch), the 1990s look being the same.
No lettering, no hauler's name (IP rule).
Budget: <= 1500 tris, one 1024 atlas. Origin: bottom centre; the long axis is Y; the nose (hook end) at -Y (Godot +Z), the door at +Y.
"""
import math
from lib import core, parts, mats

L, W, H = 6.4, 2.3, 1.85            # the box (length, width, height above the skids)
SK = 0.28                           # skid rail height: the box's floor above the pad
RIBS = 9                            # vertical ribs a side
RIB_W, RIB_D = 0.09, 0.07
NOSE = 0.9                          # the sloped nose's run at the hook end
GREEN = "#1f4a36"
RUST = "#6b3a22"

META = {
    "id": "bl_ex_dumpster",
    "class": "small_fixture",
    "tex": 1024,
    "ao": 0.5,
    "refs": [["refs/derived/frames/IMG_4490/f026.jpg", [0.44, 0.44, 0.62, 0.52], "Dillard's roll-off (4490 f026)"],
             ["refs/derived/frames/IMG_4486/f108.jpg", [0.0, 0.36, 1.0, 0.50], "JCPenney's compactor (4486 f108)"]],
}


def paint_mat(name, base, lid=False):
    """Painted steel: orange-peel, chips to rust on a noise, rust rising from the bottom rail, dark streaks
    running down from the top (lid seams), general grime."""
    m = mats.M(name, base, 0.55)
    tc = m.coords()
    sep = m.node("ShaderNodeSeparateXYZ")
    m.link(tc, sep.inputs[0])
    z = sep.outputs["Z"]
    # streaks: a noise stretched along Z (fine across, long down), stronger near the top
    mp = m.node("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (7.0, 7.0, 0.35)
    m.link(tc, mp.inputs["Vector"])
    st = m.noise(1.0, 3.0, 0.6, coord=mp.outputs["Vector"]).outputs["Fac"]
    streak = m.math("MULTIPLY", m.math("GREATER_THAN", st, 0.5), m.math("MULTIPLY", m.math("SUBTRACT", st, 0.5), 6.0))
    col = m.mix(m.math("MINIMUM", streak, 0.7), base, "#1c221c" if not lid else "#101210")
    # rust: low on the box, and in chips anywhere
    low = m.math("SUBTRACT", 1.0, m.math("MULTIPLY", m.math("SUBTRACT", z, SK), 2.2))          # 1 at the floor, 0 by 0.45 m up
    blot = m.noise(3.0, 4.0, 0.7, coord=tc).outputs["Fac"]
    chip = m.math("GREATER_THAN", m.noise(22.0, 3.0, 0.6, coord=tc).outputs["Fac"], 0.62)
    rust = m.math("MAXIMUM", m.math("GREATER_THAN", m.math("ADD", m.math("MULTIPLY", low, 0.5), blot), 0.8),
                  m.math("MULTIPLY", chip, m.math("GREATER_THAN", blot, 0.5)))
    col = m.mix(m.math("MULTIPLY", rust, 0.85), col, RUST)
    # sun-fade and dirt in big soft patches
    col = m.mix(m.math("MULTIPLY", m.noise(0.9, 2.0, coord=tc).outputs["Fac"], 0.22), col, "#7d8f7e" if not lid else "#3a3d3a")
    m.link(col, m.bsdf.inputs["Base Color"])
    rg = m.math("ADD", 0.5, m.math("MULTIPLY", rust, 0.4))
    m.link(rg, m.bsdf.inputs["Roughness"])
    m.bump(m.noise(260.0, 2.0, coord=tc).outputs["Fac"], 0.15, 0.002)
    return m.mat


def build():
    green = paint_mat("paint", GREEN)
    lidm = paint_mat("lid", "#26302a", True)
    steel = mats.M("skid", "#3a322c", 0.75)
    tc = steel.coords()
    steel.link(steel.mix(steel.math("MULTIPLY", steel.noise(6.0, 4.0, coord=tc).outputs["Fac"], 0.8), "#2b2826", RUST),
               steel.bsdf.inputs["Base Color"])
    steel = steel.mat
    B = lambda n, s, l, r=(0, 0, 0), mt=None: parts.box(n, s, loc=l, rot=r, mat=mt or green, bev=0)
    z0 = SK
    yb = NOSE / 2                                    # the full-height body sits behind the nose
    # the box, its nose (a sloped plate over a short lower box), the roof
    parts.box("body", (W, L - NOSE, H), loc=(0, yb, z0 + H / 2), mat=green, bev=0.025, seg=1)
    B("nose_top", (W, NOSE, H * 0.55), (0, -L / 2 + NOSE / 2, z0 + H - H * 0.275))
    sl = math.hypot(NOSE, H * 0.45)
    B("nose_slope", (W - 0.02, sl, 0.05), (0, -L / 2 + NOSE / 2, z0 + H * 0.225), (-math.degrees(math.atan2(H * 0.45, NOSE)), 0, 0))
    for s in (-1, 1):
        B("nose_cheek%d" % s, (0.06, NOSE * 0.5, H * 0.45), (s * (W / 2 - 0.03), -L / 2 + NOSE * 0.75, z0 + H * 0.225))
        B("nose_leg%d" % s, (0.14, 0.14, H * 0.45), (s * (W / 2 - 0.25), -L / 2 + 0.1, z0 + H * 0.225), mt=steel)
    # the side panels' vertical channel ribs between a top and a bottom rail
    for s in (-1, 1):
        x = s * (W / 2 + RIB_D / 2)
        for i in range(RIBS):
            y = -L / 2 + NOSE + 0.25 + i * (L - NOSE - 0.5) / (RIBS - 1)
            B("rib%d_%d" % (s, i), (RIB_D, RIB_W, H - 0.2), (x, y, z0 + H / 2))
        B("rail_top%d" % s, (RIB_D + 0.03, L - 0.04, 0.12), (x, 0, z0 + H - 0.06))
        B("rail_bot%d" % s, (RIB_D + 0.03, L - NOSE, 0.14), (x, yb, z0 + 0.07))
        # the skid rail and its rollers
        B("skid%d" % s, (0.16, L - 0.5, SK - 0.1), (s * 0.55, 0.1, 0.1 + (SK - 0.1) / 2), mt=steel)
        for y in (-L / 2 + 0.7, L / 2 - 0.45):
            parts.cylinder("roller%d_%d" % (s, int(y * 10)), 0.11, 0.24, verts=8, loc=(s * 0.55, y, 0.11),
                           rot=(0, 90, 0), mat=steel, bev=0)
    # the door end (+Y, opposite the nose): cross ribs, hinge posts, the ratchet bar
    yd = L / 2
    for k in range(3):
        B("door_rib%d" % k, (W - 0.3, 0.06, 0.1), (0, yd + 0.03, z0 + 0.35 + k * 0.58))
    for s in (-1, 1):
        B("door_post%d" % s, (0.12, 0.1, H), (s * (W / 2 - 0.06), yd + 0.05, z0 + H / 2))
    B("ratchet", (0.06, 0.07, H * 0.8), (0.55, yd + 0.09, z0 + H * 0.5), mt=steel)
    # the hook bar at the nose
    parts.cylinder("hook", 0.035, 0.7, verts=6, loc=(0, -L / 2 + 0.06, z0 + H * 0.3), rot=(0, 90, 0), mat=steel, bev=0)
    # two hinged steel lids on the roof (a little proud, a gap between), a hinge tube along the middle, handles
    lw = W / 2 - 0.07
    for s in (-1, 1):
        B("lid%d" % s, (lw, L - NOSE - 0.5, 0.05), (s * (lw / 2 + 0.03), yb, z0 + H + 0.03), (0, -2.5 * s, 0), lidm)
        for y in (yb - 1.4, yb + 1.4):
            B("lid_handle%d_%d" % (s, int(y * 10)), (0.05, 0.3, 0.05), (s * (W / 2 - 0.22), y, z0 + H + 0.075), mt=steel)
    parts.cylinder("lid_hinge", 0.03, L - NOSE - 0.5, verts=6, loc=(0, yb, z0 + H + 0.06), rot=(90, 0, 0), mat=steel, bev=0)
