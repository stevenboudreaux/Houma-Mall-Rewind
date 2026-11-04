"""A plain yo-yo, a Pocket Change ticket prize (1995 map; workstream PRIZES, Steven Nov 3 2026). Pocket
item, 100-200 tickets (design/research/redemption-items.md T3: plain yo-yos fit 1995; the 1998-99 craze is
later). Generic: two moulded plastic halves with a ring step, a steel axle and a looped string; no brand.
5.6 cm across, 3.4 cm wide (a standard butterfly-free imperial shape, guess). Origin: bottom centre, the
axle along Godot X, the face to +Z.
"""
import math
from lib import core, parts, mats

R = 0.028
GAP = 0.003
COL = "#e8283c"

META = {
    "id": "bl_pc_yoyo",
    "class": "pocket",
    "tex": 512,
    "ao": 0.35,
    "refs": [],
    "item": {"name": "Yo-yo", "year": 1995, "store": "POCKET CHANGE", "tickets": 150, "prize": "yoyo"},
}


def build():
    body = mats.plastic("body", COL, 0.35, 0.02)
    hub = mats.flat("hub", "#f2f2f4", 0.4)
    axle = mats.brushed_metal("axle", "#c8c8cc")
    string = mats.flat("string", "#f4f0e2", 0.9)
    prof = [(0.0, GAP), (0.007, GAP), (0.010, GAP + 0.0015), (R - 0.005, GAP + 0.0035), (R - 0.001, GAP + 0.006), (R, 0.012), (R - 0.0015, 0.0160), (R - 0.004, 0.0170), (0.0, 0.0170)]
    for sx in (-1, 1):
        ob = parts.lathe("half", prof, 32, mat=body)
        ob.rotation_euler = (0, math.radians(90 * sx), 0)
        ob.location = (0, 0, R)
        parts.cylinder("cap", R * 0.55, 0.0012, 24, loc=(sx * 0.0172, 0, R), rot=(0, 90, 0), mat=hub)
    parts.cylinder("axle", 0.0018, GAP * 2, 10, loc=(0, 0, R), rot=(0, 90, 0), mat=axle)
    parts.tube_path("string", [(0, 0, R - 0.003), (0, -0.004, 0.012), (0.0, -0.012, 0.003), (0.006, -0.03, 0.0015), (0.012, -0.05, 0.0015)], 0.0008, 5, mat=string)
