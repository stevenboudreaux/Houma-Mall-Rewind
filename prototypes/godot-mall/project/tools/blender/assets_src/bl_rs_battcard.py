"""A blister card of four AA batteries (RadioShack's battery wall, 1995 map). Pocket item.

Reference: refs/new/radioshack_1999/ 0:56-1:20 and 2:36-3:00 (the back wall of battery cards under the
store's battery-department header: red and black cards on pegs). Brand invented ("ZAP-CELL"), red and
black like tools/stores/small/paint_rs.py's battery sheet; no real battery brand.
A printed card with a hang tab (a real hole, boolean), a clear blister (transparent, not baked) over four
cells. Origin: bottom centre, standing upright, front facing Godot +Z.
"""
import bpy
from lib import core, parts, mats, labels
from PIL import ImageDraw

CW, CT, CH = 0.090, 0.0012, 0.150      # card
BL = (0.070, 0.017, 0.076)             # blister w, d, h
BL_Z = 0.058                           # blister centre height
CELL = (0.00725, 0.0495)               # AA radius, length
PX = 1200 / CW

META = {
    "id": "bl_rs_battcard",
    "class": "pocket",
    "tex": 1024,
    "ao": 0.0,                         # the blister is see-through; AO would shade the cells as if it were solid
    "refs": [["refs/new/radioshack_1999/christmas-shopping-at-radioshack-in-1999_t000_061.jpg", [0.0, 0.0, 0.55, 0.6], "RS 1999 1:00 (battery wall)"]],
    "item": {"name": "AA batteries, 4-pack", "year": 1995, "store": "RADIO SHACK"},
}


def art():
    w, h = int(CW * PX), int(CH * PX)
    im, d = labels.canvas(w, h, (18, 18, 20, 255))
    d.rectangle((0, 0, w, h * 0.30), fill=(200, 28, 34, 255))
    d.polygon([(0, h * 0.30), (w, h * 0.22), (w, h * 0.30)], fill=(200, 28, 34, 255))
    d.ellipse((w / 2 - 70, 40, w / 2 + 70, 110), fill=(60, 60, 60, 255))     # around the hang hole
    labels.text(d, (w / 2, h * 0.14), "ZAP-CELL", "bold", 190, (255, 255, 255, 255))
    labels.text(d, (w / 2, h * 0.235), "ALKALINE", "bold", 82, (255, 220, 60, 255))
    labels.text(d, (w / 2, h * 0.93), "4  •  AA  •  1.5V", "bold", 96, (255, 255, 255, 255))
    front = labels.save(im, "rs_batt_card")
    im, d = labels.canvas(400, 1000, (20, 20, 22, 255))
    d.rectangle((0, 0, 400, 180), fill=(200, 28, 34, 255))
    labels.text(d, (200, 560), "ZAP", "bold", 120, (255, 255, 255, 255))
    labels.text(d, (200, 700), "AA", "bold", 90, (255, 220, 60, 255))
    cell = labels.save(im, "rs_batt_cell")
    return front, cell


def build():
    front, cell = art()
    mc = mats.M("card", "#141416", 0.55)
    mats.decal(mc, front, (0, -CT / 2, CH / 2), (CW, CH), "XZ", facing="-Y")
    card = parts.box("card", (CW, CT, CH), loc=(0, 0, CH / 2), mat=mc.mat, bev=0)
    hole = parts.cylinder("hole", 0.0045, 0.02, 16, loc=(0, 0, CH - 0.007), rot=(90, 0, 0), bev=0)
    hole.scale = (2.2, 1, 1)
    b = card.modifiers.new("Hole", "BOOLEAN")
    b.operation = "DIFFERENCE"
    b.object = hole
    b.solver = "EXACT"
    core.apply_all(card)
    bpy.data.objects.remove(hole)
    # the four cells, standing side by side behind the blister
    mcell = mats.M("cell", "#141416", 0.4)
    xs = [(i - 1.5) * (CELL[0] * 2 + 0.0012) for i in range(4)]
    c = None
    for x in xs:
        c = mats.decal(mcell, cell, (x, 0, BL_Z), (CELL[0] * 2, CELL[1]), "XZ", base=c, facing="-Y")
    for i, x in enumerate(xs):
        parts.cylinder("cell%d" % i, CELL[0], CELL[1], 16, loc=(x, -CT / 2 - CELL[0] - 0.0005, BL_Z), mat=mcell.mat, bev=0.0006)
        parts.cylinder("nub%d" % i, 0.0026, 0.0016, 10, loc=(x, -CT / 2 - CELL[0] - 0.0005, BL_Z + CELL[1] / 2 + 0.0008),
                       mat=mats.flat("nub", "#c9cbce", 0.25, 0.8), bev=0.0002)
    # the blister: a rounded clear shell over the cells
    bl = parts.rounded_panel("blister", BL[0], BL[2], BL[1], 0.008, 4, loc=(0, -CT / 2 - BL[1] / 2, BL_Z),
                             mat=mats.clear_plastic("blister"), bev=0.003)
    parts.box("flange", (BL[0] + 0.008, 0.0006, BL[2] + 0.008), loc=(0, -CT / 2 - 0.0003, BL_Z),
              mat=mats.clear_plastic("flange", alpha=0.15), bev=0)
