"""A skateboard, a Pocket Change top-shelf prize (1995 map; workstream PRIZES, Steven Nov 3 2026). Hand item,
4,000-8,000 tickets (design/research/redemption-items.md T5: "skateboards, low-end electronics... several
thousand"). A cheap complete of the mid-90s (guess): a 7.5 x 30 in maple deck with kicktails, a bright
generic graphic (flames and stars, no words or logo), black grip tape on top, chrome trucks, white
wheels. Origin: bottom centre (the wheels on the floor), nose toward Godot -Z.
"""
import math
from lib import core, parts, mats, labels

W = 0.19
L = 0.76
TAIL = 0.13
DECK_Z = 0.075
KICK = 18.0          # degrees the tails turn up

META = {
    "id": "bl_pc_skateboard",
    "class": "hand",
    "tex": 1024,
    "ao": 0.4,
    "refs": [],
    "item": {"name": "Skateboard", "year": 1995, "store": "POCKET CHANGE", "tickets": 6000, "prize": "skateboard"},
}


def graphic():
    im, d = labels.canvas(256, 1024, (230, 40, 50, 255))
    for k in range(9):
        y = 980 - k * 60
        d.polygon([(30, y), (128, y - 160 - (k % 3) * 30), (226, y)], fill=(250, 160 + (k % 2) * 60, 30, 255))
    for (x, y) in [(70, 180), (180, 260), (110, 360), (60, 90), (200, 140)]:
        pts = []
        for i in range(10):
            a = i * math.pi / 5 - math.pi / 2
            r = 26 if i % 2 == 0 else 11
            pts.append((x + r * math.cos(a), y + r * math.sin(a)))
        d.polygon(pts, fill=(255, 245, 120, 255))
    return labels.save(im, "bl_pc_skateboard_graphic")


def build():
    grip = mats.M("grip", "#202024", 0.95)
    n = grip.noise(2500.0, 2.0)
    grip.bump(n.outputs["Fac"], 0.5, 0.0003)
    under = mats.M("under", "#e62832", 0.5)
    mats.decal(under, graphic(), (0, 0, DECK_Z - 0.006), (W, L), plane="XY", facing="-Z")
    ply = mats.flat("ply", "#d9b382", 0.7)
    metal = mats.brushed_metal("truck", "#c8c8cc")
    wheel = mats.flat("wheel", "#f4f0e0", 0.5)
    parts.rounded_panel("deck", W, L - 2 * TAIL, 0.012, r=0.02, loc=(0, 0, DECK_Z), plane="XY", mat=under.mat)
    parts.box("top", (W - 0.004, L - 2 * TAIL, 0.0015), loc=(0, 0, DECK_Z + 0.0065), mat=grip.mat, bev=0.0005)
    for sy in (-1, 1):
        y0 = sy * (L / 2 - TAIL)
        # the kicktail, hinged at the deck's end and turned up KICK degrees
        a = math.radians(KICK)
        cy = y0 + sy * math.cos(a) * TAIL / 2
        cz = DECK_Z + math.sin(a) * TAIL / 2
        parts.box("tail", (W, TAIL, 0.012), loc=(0, cy, cz), rot=(sy * KICK, 0, 0), mat=under.mat, bev=0.006, seg=3)
        parts.box("tailtop", (W - 0.004, TAIL - 0.01, 0.0015), loc=(0, cy - sy * math.sin(a) * 0.0065, cz + math.cos(a) * 0.0065), rot=(sy * KICK, 0, 0), mat=grip.mat, bev=0.0005)
        ty = sy * (L / 2 - 0.19)
        parts.box("base", (0.06, 0.07, 0.012), loc=(0, ty, DECK_Z - 0.012), mat=metal, bev=0.003)
        parts.box("hanger", (0.16, 0.02, 0.022), loc=(0, ty, 0.03), mat=metal, bev=0.006, seg=2)
        for sx in (-1, 1):
            parts.cylinder("wheel", 0.027, 0.032, 20, loc=(sx * 0.085, ty, 0.027), rot=(0, 90, 0), mat=wheel)
    parts.box("edge", (W - 0.01, L - 2 * TAIL - 0.01, 0.002), loc=(0, 0, DECK_Z - 0.0005), mat=ply, bev=0.0)
