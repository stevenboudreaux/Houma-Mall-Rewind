"""A capybara plush, a games, inc. prize (2026 map; workstream PRIZES, Steven Nov 3 2026). Hand item,
~2,000 tickets (design/research/redemption-items.md section 4, T4: capybara plush demand through 2025).
Generic, no character or brand: the animal's real shape made soft: a long barrel body, a big blunt
box-shaped head with a deep square muzzle, small round ears high on the head, small dark eyes, four short
stubby legs; warm brown velour, a darker muzzle. About 28 cm long, 17 cm tall (a typical 11 in plush,
guess). Origin: bottom centre, facing Godot +Z (the head toward the customer).
"""
from lib import core, parts, mats

BODY = "#a8744a"
DARK = "#6e4a2e"

META = {
    "id": "bl_gi_capybara",
    "class": "hand",
    "tex": 512,
    "ao": 0.45,
    "refs": [],
    "item": {"name": "Capybara plush", "year": 2026, "store": "GAMES, INC.", "tickets": 2000, "prize": "g_capybara"},
}


def velour(name, base, dark):
    m = mats.M(name, base, 0.95)
    n = m.noise(1200.0, 3.0, 0.6)
    m.bump(n.outputs["Fac"], 0.35, 0.0006)
    sh = m.ramp(n.outputs["Fac"], [(0.2, dark), (0.85, base)])
    m.link(sh, m.bsdf.inputs["Base Color"])
    return m.mat


def build():
    fur = velour("fur", BODY, "#8c5c38")
    muz = velour("muzzle", DARK, "#4e3420")
    eye = mats.flat("eye", "#0e0b0a", 0.2, bake=False)
    # body along Blender Y (Godot -Z is its back end, +Z the head)
    parts.sphere("body", 1.0, 20, 10, loc=(0, 0.02, 0.085), mat=fur, scale=(0.085, 0.13, 0.075))
    for sx in (-1, 1):
        for sy in (-1, 1):
            parts.sphere("leg", 1.0, 10, 6, loc=(sx * 0.05, 0.02 + sy * 0.08, 0.02), mat=fur, scale=(0.026, 0.03, 0.022))
    parts.box("head", (0.1, 0.11, 0.085), loc=(0, -0.12, 0.125), mat=fur, bev=0.03, seg=4)
    parts.box("muzzle", (0.085, 0.05, 0.06), loc=(0, -0.17, 0.112), mat=muz, bev=0.022, seg=3)
    for sx in (-1, 1):
        parts.sphere("ear", 1.0, 10, 6, loc=(sx * 0.04, -0.09, 0.172), mat=muz, scale=(0.016, 0.01, 0.014))
        parts.sphere("eye", 1.0, 8, 5, loc=(sx * 0.035, -0.158, 0.146), mat=eye, scale=(0.008, 0.005, 0.008))
        parts.sphere("nostril", 1.0, 6, 4, loc=(sx * 0.016, -0.194, 0.124), mat=eye, scale=(0.005, 0.003, 0.003))
