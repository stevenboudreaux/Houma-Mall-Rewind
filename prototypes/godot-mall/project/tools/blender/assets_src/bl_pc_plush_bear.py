"""A claw-machine plush bear for Pocket Change's cranes (1995 map). Hand item. Generic, unbranded, from the
crane's own prize mix (tools/stores/pocket_change/crane.gd: bears, dogs, bunnies). Body plan, tint rule and
sources: _plush.py. The pile in the machine can tint it to any crane.gd FUR colour."""
import _plush

META = {
    "id": "bl_pc_plush_bear",
    "class": "hand",
    "tex": 512,
    "ao": 0.45,
    "refs": [],
    "item": {"name": "Plush bear", "year": 1995, "store": "POCKET CHANGE", "prize": "claw",
             "tint": ["#b5824a", "#5a3820", "#e8e0cc", "#c21f2a", "#ea88ae", "#72a6e0", "#9e82d4", "#7ccfa6", "#f2cc34"]},
}


def build():
    _plush.build("bear")
