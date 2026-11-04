"""Cuco's back bar kit: a hanging stemware rack with margarita glasses (1995 map, store s42). Fixture.

Three dark-stained wood rails with slotted brass runners, hung from the ceiling or the back-bar canopy on
four rods, twelve empty house margarita glasses hanging upside down by their feet (the same glass as the
cu_margarita item). Clean glasses: no drinks.
References: design/storefronts/cucos.md (the bar); no photo. Guessed: everything (a common period bar
fixture).
Size: rails 0.60 m long, 0.12 m apart; rods 0.30 m to the mounting plates.
Placement: design/storefronts/cucos-back-bar-kit.md. Origin: the middle of the mounting plates' top
(fix it to the ceiling or canopy underside); the rails run along X.
"""
from lib import core, parts, mats
import _bar as BAR

L = 0.60
GAP = 0.12
DROP = 0.30
PER_RAIL = 4

META = {"id": "bl_cu_bb_stemrack", "class": "small_fixture", "tex": 1024, "ao": 0.35, "refs": []}


def build():
    wood = mats.M("wood", "#4a2c18", 0.55)
    n = wood.noise(40.0, 6.0)
    wood.link(wood.ramp(n.outputs["Fac"], [(0.3, "#3a2010"), (0.7, "#5e3a20")]), wood.bsdf.inputs["Base Color"])
    wood.bump(n.outputs["Fac"], 0.2, 0.0006)
    brass = mats.brushed_metal("brass", "#b8964a", 0.3, along="X", metal=0.75)
    glass = BAR.glass_mat("clear")
    zr = -DROP
    for k in range(3):
        y = (k - 1) * GAP
        parts.box("rail%d" % k, (L, 0.030, 0.022), loc=(0, y, zr + 0.011), mat=wood.mat, bev=0.002, seg=2)
        # the brass runner under the rail: two lips with a slot between (the glasses' feet slide in)
        for s in (-1, 1):
            parts.box("lip%d%d" % (k, s), (L, 0.012, 0.003), loc=(0, y + s * 0.016, zr - 0.0015), mat=brass, bev=0.0006, seg=1)
            parts.box("web%d%d" % (k, s), (L, 0.002, 0.008), loc=(0, y + s * 0.011, zr + 0.002), mat=brass, bev=0)
        for j in range(PER_RAIL):
            x = -L / 2 + L * (j + 0.5) / PER_RAIL + (0.02 if k == 1 else 0.0)
            g = parts.lathe("glass%d%d" % (k, j), BAR.margarita_profile(), seg=14, mat=glass, cap=False)
            g.rotation_euler = (3.14159, 0, 0)
            g.location = (x, y, zr - 0.004)
    for x in (-L / 2 + 0.05, L / 2 - 0.05):
        for y in (-GAP, GAP):
            parts.cylinder("rod", 0.004, DROP - 0.002, verts=10, loc=(x, y, -DROP / 2), mat=brass, bev=0)
            parts.cylinder("plate", 0.022, 0.004, verts=16, loc=(x, y, -0.002), mat=brass, bev=0.0008)
