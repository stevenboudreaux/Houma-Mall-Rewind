"""Cuco's back bar kit: clean glassware upside down on a bar mat (1995 map, store s42). Fixture.

A black ribbed rubber bar mat on the back counter with six heavy beer mugs (the cu_beer mug) and four pint
glasses turned upside down to drain, and two stacks of three rocks glasses. Clean and empty: no drinks.
References: design/storefronts/cucos.md (the bar); no photo. Guessed: everything.
Size: mat 0.60 x 0.30 m.
Placement: design/storefronts/cucos-back-bar-kit.md. Origin: the middle of the mat's back edge on the
counter top; the long side runs along X.
"""
import math
import random
from lib import core, parts, mats
import _bar as BAR

SEED = 41

META = {"id": "bl_cu_bb_glasses", "class": "small_fixture", "tex": 1024, "ao": 0.4, "refs": []}


def build():
    rng = random.Random(SEED)
    rubber = mats.M("mat", "#121212", 0.85)
    sep = rubber.node("ShaderNodeSeparateXYZ")
    rubber.link(rubber.coords(), sep.inputs[0])
    rib = rubber.math("GREATER_THAN", rubber.math("SINE", rubber.math("MULTIPLY", sep.outputs["X"], 420.0)), 0.2)
    rubber.bump(rib, 0.8, 0.0012)
    parts.box("barmat", (0.60, 0.30, 0.010), loc=(0, -0.15, 0.005), mat=rubber.mat, bev=0.003, seg=2)
    glass = BAR.glass_mat("clear")
    z = 0.010
    k = 0
    for row, y in enumerate((-0.060, -0.150)):
        for j in range(3):
            x = -0.24 + j * 0.095 + (0.04 if row else 0.0)
            g = parts.lathe("mug%d" % k, BAR.mug_profile(), seg=20, mat=glass, cap=False)
            g.rotation_euler = (math.pi, 0, rng.uniform(0, math.tau))
            g.location = (x, y, z + 0.160)
            # the handle
            a = rng.uniform(-0.8, 0.8)
            h = parts.tube_path("mugh%d" % k, [(0.043, 0, 0.025), (0.073, 0, 0.028), (0.079, 0, 0.08), (0.073, 0, 0.125), (0.043, 0, 0.130)], 0.0075, seg=8, mat=glass)
            h.rotation_euler = (0, 0, a)
            h.location = (x, y, z)
            k += 1
    for j in range(4):
        x = 0.06 + j * 0.085
        g = parts.lathe("pint%d" % j, BAR.pint_profile(), seg=20, mat=glass, cap=False)
        g.rotation_euler = (math.pi, 0, 0)
        g.location = (x, -0.065 - (j % 2) * 0.09, z + 0.150)
    # two stacks of rocks glasses, right front
    rocks = [(0.0, 0.0), (0.036, 0.0), (0.038, 0.004), (0.040, 0.090), (0.0375, 0.0895), (0.0355, 0.018), (0.0, 0.016)]
    for s, x in enumerate((0.13, 0.215)):
        for t in range(3):
            g = parts.lathe("rocks%d%d" % (s, t), rocks, seg=20, mat=glass, cap=False)
            g.location = (x + 0.04, -0.230, z + t * 0.018)
