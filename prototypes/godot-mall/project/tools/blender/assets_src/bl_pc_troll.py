"""A small wild-hair troll-type doll, a Pocket Change ticket prize (1995 map; workstream PRIZES, Steven Nov 3
2026: "use Blender for prizes you can win where you can"). Pocket item, 50-100 tickets
(design/research/redemption-items.md T2: the early-90s troll revival). Generic: no maker's marks, no name.
No reference photo of Pocket Change's own: proportions from the common 3 in vending troll (guess): a pear
body, a round face with a broad nose and big ears, and a tall upright tuft of bright hair, about 9 cm tall
with the hair. Origin: bottom centre, facing Godot +Z.
"""
from lib import core, parts, mats

H_BODY = 0.040
HAIR = "#ff3c96"          # hot pink (the counter cycles colours with its own stand-in)
SKIN = "#e9c49a"
GEM = "#3cdc8c"

META = {
    "id": "bl_pc_troll",
    "class": "pocket",
    "tex": 512,
    "ao": 0.4,
    "refs": [],
    "item": {"name": "Troll doll", "year": 1995, "store": "POCKET CHANGE", "tickets": 100, "prize": "troll"},
}


def skin_mat():
    m = mats.M("skin", SKIN, 0.55)
    n = m.noise(300.0, 2.0)
    m.bump(n.outputs["Fac"], 0.15, 0.0004)
    return m.mat


def hair_mat():
    m = mats.M("hair", HAIR, 0.8)
    tc = m.coords()
    mp = m.node("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (900.0, 900.0, 8.0)        # fibres run up
    m.link(tc, mp.inputs["Vector"])
    n = m.noise(1.0, 4.0, 0.6, coord=mp.outputs["Vector"])
    m.bump(n.outputs["Fac"], 0.8, 0.0008)
    col = m.ramp(n.outputs["Fac"], [(0.25, "#b0145a"), (0.75, HAIR)])
    m.link(col, m.bsdf.inputs["Base Color"])
    return m.mat


def build():
    sk = skin_mat()
    hr = hair_mat()
    eye = mats.flat("eye", "#2a5ad0", 0.2)
    dark = mats.flat("pupil", "#0c0c0e", 0.2)
    gem = mats.flat("gem", GEM, 0.15)
    # pear body and feet
    parts.lathe("body", [(0.0, 0.0), (0.016, 0.0), (0.019, 0.010), (0.018, 0.022), (0.013, 0.034), (0.0085, H_BODY)], 20, mat=sk)
    for sx in (-1, 1):
        parts.sphere("foot", 1.0, 12, 6, loc=(sx * 0.008, -0.006, 0.004), mat=sk, scale=(0.008, 0.012, 0.005))
        parts.sphere("arm", 1.0, 10, 6, loc=(sx * 0.018, -0.002, 0.024), mat=sk, scale=(0.005, 0.005, 0.012))
        parts.sphere("ear", 1.0, 10, 6, loc=(sx * 0.0185, 0.0, 0.052), mat=sk, scale=(0.006, 0.003, 0.009))
        parts.sphere("eye", 1.0, 10, 6, loc=(sx * 0.0062, -0.0135, 0.056), mat=eye, scale=(0.0042, 0.002, 0.0042))
        parts.sphere("pupil", 1.0, 8, 4, loc=(sx * 0.0062, -0.0152, 0.056), mat=dark, scale=(0.002, 0.0008, 0.002))
    parts.sphere("head", 1.0, 18, 10, loc=(0, 0, 0.052), mat=sk, scale=(0.016, 0.015, 0.015))
    parts.sphere("nose", 1.0, 10, 6, loc=(0, -0.015, 0.050), mat=sk, scale=(0.006, 0.005, 0.005))
    parts.sphere("gem", 1.0, 10, 6, loc=(0, -0.0175, 0.022), mat=gem, scale=(0.004, 0.002, 0.004))
    # the hair: a tall flame-shaped tuft
    parts.lathe("hair", [(0.0, 0.062), (0.014, 0.062), (0.016, 0.070), (0.013, 0.080), (0.008, 0.088), (0.0, 0.094)], 20, mat=hr)
