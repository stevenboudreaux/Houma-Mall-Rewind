"""A pump-action water blaster (Super Soaker-type), a Pocket Change wall prize (1995 map; workstream PRIZES,
Steven Nov 3 2026). Hand item, 400-500 tickets (design/research/redemption-items.md T3: the type was on sale
by 1990). Generic: a neon green body, an orange reservoir on top, a yellow pump under the barrel; no name,
no logo. About 36 cm long (a small model; guess). Origin: bottom centre (the grip's foot), muzzle toward
Godot -Z, so it shows its side when hung or laid with +X to the customer.
"""
import math
from lib import core, parts, mats

L = 0.36
BODY = "#3cdc3c"
TANK = "#ff8a1e"
PUMP = "#ffd228"

META = {
    "id": "bl_pc_blaster",
    "class": "hand",
    "tex": 512,
    "ao": 0.4,
    "refs": [],
    "item": {"name": "Water blaster", "year": 1995, "store": "POCKET CHANGE", "tickets": 450, "prize": "blaster"},
}


def build():
    body = mats.plastic("body", BODY, 0.35, 0.03)
    tank = mats.plastic("tank", TANK, 0.3, 0.03)
    pump = mats.plastic("pump", PUMP, 0.4, 0.03)
    dark = mats.flat("trig", "#1c1c20", 0.5)
    # the main body along Y (Blender -Y = Godot +Z is the back; the muzzle at +Y = Godot -Z)
    parts.box("body", (0.05, 0.26, 0.06), loc=(0, 0.02, 0.11), mat=body, bev=0.012, seg=3)
    parts.cylinder("barrel", 0.016, 0.12, 16, loc=(0, 0.2, 0.12), rot=(90, 0, 0), mat=body)
    parts.cylinder("nozzle", 0.008, 0.02, 12, loc=(0, 0.27, 0.12), rot=(90, 0, 0), mat=dark)
    # the grip and trigger guard
    parts.box("grip", (0.034, 0.045, 0.1), loc=(0, -0.08, 0.05), rot=(-18, 0, 0), mat=body, bev=0.008, seg=2)
    parts.box("trigger", (0.012, 0.012, 0.03), loc=(0, -0.04, 0.072), mat=dark, bev=0.003)
    # reservoir on top, a fat round tank
    parts.cylinder("tank", 0.036, 0.16, 20, loc=(0, -0.01, 0.172), rot=(90, 0, 0), mat=tank)
    parts.cylinder("cap", 0.014, 0.014, 14, loc=(0, -0.05, 0.212), mat=dark)
    # the pump grip under the barrel
    parts.box("pump", (0.042, 0.09, 0.034), loc=(0, 0.16, 0.078), mat=pump, bev=0.01, seg=2)
    for i in range(4):
        parts.box("rib", (0.044, 0.004, 0.036), loc=(0, 0.13 + i * 0.02, 0.078), mat=pump, bev=0.001)
