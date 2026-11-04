"""Cuco's back bar kit: a shelf row of liquor bottles, B (1995 map, store s42). Fixture (not an item).

The upper-shelf stock: ten bottles, most still capped (backup and the better tequilas, kept out of the
speed rail), a few with pour spouts, in a different order from row A so two shelves never read as copies.
Same invented brands as row A (_bar.py; IP rule). No prepared drinks.
References: design/storefronts/cucos.md; no photo. Guessed: everything.
Placement: design/storefronts/cucos-back-bar-kit.md. Origin: the middle of the row's front edge on the
shelf top; labels face -Y (Godot +Z).
"""
import random
import _bar as BAR

ROW = 1.10
ORDER = [2, 1, 2, 0, 11, 8, 4, 4, 6, 9]
CAPPED = [True, True, True, False, True, True, True, False, True, False]
SEED = 37

META = {"id": "bl_cu_bb_bottles_b", "class": "small_fixture", "tex": 2048, "ao": 0.35, "refs": []}


def build():
    rng = random.Random(SEED)
    n = len(ORDER)
    for k, i in enumerate(ORDER):
        x = -ROW / 2 + ROW * (k + 0.5) / n + rng.uniform(-0.01, 0.01)
        BAR.bottle(i, (x, 0.050 + rng.uniform(-0.01, 0.01), 0.0), yaw=rng.uniform(-10, 10),
                   fill=1.0 if CAPPED[k] else rng.uniform(0.3, 0.8), spout=not CAPPED[k])
