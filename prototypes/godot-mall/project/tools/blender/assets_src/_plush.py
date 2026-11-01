"""Shared body plan for the claw-machine plush (bl_pc_plush_bear / _dog / _bunny), following
tools/stores/pocket_change/crane.gd plush(): the same proportions (head 0.112 m wide at k = 1, body
0.12 x 0.14, muzzle, ears by type), sitting upright, ~0.24 m tall.

Fur is baked near-white with real-looking pile (fine stretched noise in the normal map, a centre seam), so
Godot can tint one model to every colour in crane.gd FUR with the material's albedo colour (a surface
override); eyes, nose and the bow are separate flat materials that a tint does not touch. The muzzle and
inner ears are a second baked-in shade of the same near-white, so they stay lighter after tinting
(crane.gd uses a contrasting fur colour there; a cream muzzle is the commonest real case).
Origin: bottom centre, facing Godot +Z.
"""
import math
from lib import core, parts, mats

FUR = "#f2efe8"           # tinted in Godot
MUZZLE = "#fbf6ea"


def fur_mat(name, base):
    m = mats.M(name, base, 0.92)
    tc = m.coords()
    # pile: fine noise, stretched a little along Z so the fibres lie down
    mp = m.node("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (1.0, 1.0, 0.45)
    m.link(tc, mp.inputs["Vector"])
    pile = m.noise(700.0, 6.0, 0.7, coord=mp.outputs["Vector"])
    clump = m.noise(90.0, 3.0, 0.5, coord=tc)
    h = m.math("MULTIPLY_ADD", clump.outputs["Fac"], 0.6, pile.outputs["Fac"])
    # the centre seam down the front and back (x = 0)
    sep = m.node("ShaderNodeSeparateXYZ")
    m.link(tc, sep.inputs[0])
    seam = m.math("LESS_THAN", m.math("ABSOLUTE", sep.outputs["X"]), 0.0012)
    h = m.math("SUBTRACT", h, m.math("MULTIPLY", seam, 0.8))
    m.bump(h, 0.6, 0.0012)
    shade = m.ramp(h, [(0.2, "#c9c4ba"), (0.9, base)])
    m.link(shade, m.bsdf.inputs["Base Color"])
    return m.mat


def ell(name, r, loc, mat, seg=14, rings=8, rot=(0, 0, 0)):
    ob = parts.sphere(name, 1.0, seg, rings, mat=mat, scale=r)
    core.place(ob, loc, rot)
    return ob


def build(kind):
    fur = fur_mat("fur", FUR)
    muz = fur_mat("muzzle", MUZZLE)
    eye = mats.flat("eyes", "#0b0b0c", 0.15, bake=False)
    nose = mats.flat("nose", "#2a1a14", 0.35, bake=False)
    # body sitting, legs forward, arms at the sides
    ell("body", (0.060, 0.052, 0.070), (0, 0, 0.068), fur)
    for sx in (-1, 1):
        ell("leg", (0.026, 0.040, 0.024), (sx * 0.034, -0.036, 0.022), fur, 10, 6)
        ell("foot", (0.024, 0.010, 0.024), (sx * 0.034, -0.074, 0.024), muz, 10, 5, rot=(90, 0, 0))
        ell("arm", (0.020, 0.022, 0.044), (sx * 0.058, -0.016, 0.082), fur, 10, 6, rot=(-25, sx * -20, 0))
    hz = 0.163
    ell("head", (0.056, 0.050, 0.052), (0, -0.004, hz), fur, 16, 9)
    mz = (0, -0.046, hz - 0.016)
    mr = (0.026, 0.019, 0.020)
    if kind == "dog":
        mz = (0, -0.054, hz - 0.016)
        mr = (0.027, 0.030, 0.022)
    ell("muzzle", mr, mz, muz, 12, 7)
    ell("nose", (0.009, 0.006, 0.007), (0, mz[1] - mr[1] + 0.002, mz[2] + 0.008), nose, 8, 5)
    for sx in (-1, 1):
        ell("eye", (0.0065, 0.0045, 0.0065), (sx * 0.020, -0.047, hz + 0.010), eye, 8, 5)
        if kind == "bear":
            ell("ear", (0.019, 0.010, 0.019), (sx * 0.040, -0.002, hz + 0.042), fur, 10, 6)
            ell("earin", (0.011, 0.004, 0.011), (sx * 0.040, -0.010, hz + 0.041), muz, 8, 4)
        elif kind == "dog":
            ell("ear", (0.012, 0.024, 0.040), (sx * 0.055, 0.0, hz - 0.004), fur, 10, 6, rot=(0, sx * 25, 0))
        elif kind == "bunny":
            ell("ear", (0.016, 0.008, 0.050), (sx * 0.020, 0.004, hz + 0.088), fur, 10, 6, rot=(0, sx * -10, 0))
            ell("earin", (0.009, 0.004, 0.038), (sx * 0.020, -0.004, hz + 0.088), muz, 8, 4, rot=(0, sx * -10, 0))
    if kind == "bunny":
        ell("tail", (0.020, 0.020, 0.020), (0, 0.052, 0.040), muz, 10, 6)
    if kind == "dog":
        ell("tail", (0.010, 0.026, 0.010), (0, 0.058, 0.060), fur, 8, 5, rot=(-40, 0, 0))
    if kind == "bear":
        # a ribbon bow at the neck (flat red, not tinted)
        bow = mats.flat("bow", "#c21f2a", 0.45, bake=False)
        parts.lathe("collar", [(0.040, 0.0), (0.044, 0.004), (0.044, 0.010), (0.040, 0.014)], 20, loc=(0, -0.004, 0.118), mat=bow, cap=False)
        for sx in (-1, 1):
            ell("bowloop", (0.016, 0.006, 0.010), (sx * 0.014, -0.047, 0.126), bow, 8, 5, rot=(0, sx * 20, 0))
        ell("knot", (0.006, 0.006, 0.007), (0, -0.050, 0.126), bow, 8, 5)
