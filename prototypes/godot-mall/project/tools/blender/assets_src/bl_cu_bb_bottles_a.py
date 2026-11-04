"""Cuco's back bar kit: a shelf row of liquor bottles, A (1995 map, store s42). Fixture (not an item).

Twelve bottles on 1.10 m of shelf: the bar's working stock, each with a steel pour spout in a rubber collar,
filled to different levels, labels turned a little this way and that. All brands and labels are INVENTED
(IP rule): CAMINO BLANCO, TÍO RAMÓN, BAYOU AÑEJO tequilas, GULFSTAR vodka, OLD PIROGUE whiskey, PELICAN
and ATCHAFALAYA rums, NARANJA triple sec, KREWE gin, SEÑORITA coffee liqueur, BLUE HERON curaçao, LAS PALMAS
mezcal (tools/blender/assets_src/_bar.py). No prepared drinks.
References: design/storefronts/cucos.md (the back bar of bottles behind the bar down the right wall); no
photo of the bottles. Guessed: everything; bottle sizes are 750 ml / 1 L types.
Placement: design/storefronts/cucos-back-bar-kit.md. Origin: the middle of the row's front edge on the
shelf top; the labels face -Y (Godot +Z). Static: give the .glb.import meshes/light_baking=2 if baked.
"""
import random
import _bar as BAR

ROW = 1.10
ORDER = [0, 3, 1, 4, 6, 2, 9, 5, 7, 10, 8, 11]
SEED = 31

META = {"id": "bl_cu_bb_bottles_a", "class": "small_fixture", "tex": 2048, "ao": 0.35, "refs": []}


def build():
    rng = random.Random(SEED)
    n = len(ORDER)
    for k, i in enumerate(ORDER):
        x = -ROW / 2 + ROW * (k + 0.5) / n
        BAR.bottle(i, (x, 0.050, 0.0), yaw=rng.uniform(-14, 14), fill=rng.uniform(0.25, 0.95), spout=True)
