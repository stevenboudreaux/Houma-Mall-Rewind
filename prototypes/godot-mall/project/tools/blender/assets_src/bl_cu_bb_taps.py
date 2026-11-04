"""Cuco's back bar kit: the draft beer taps (1995 map, store s42). Fixture (not an item).

A chrome T-tower with three faucets on the bar's back counter, frosted a little where the cold line runs,
three tapered tap handles (plain, no brewery marks: IP rule; each with an invented style word on a small
oval plate: LAGER, AMBER, DARK) and a stainless drip tray with a slotted grille on a black rubber bar mat.
The beer the mug item (cu_beer) is poured from.
References: design/storefronts/cucos.md (the bar); no photo. Guessed: everything (a period type).
Size: tower 0.36 m tall, 0.46 m across the faucets; tray 0.46 x 0.13 m.
Placement: design/storefronts/cucos-back-bar-kit.md. Origin: the middle of the drip tray's back edge on
the counter top; the faucets face -Y (Godot +Z): turn it so they face the bartender.
"""
import math
from PIL import Image, ImageDraw
from lib import core, parts, mats, labels
import _food as F
import _book as B

H = 0.36
SPAN = 0.46
NAMES = (("LAGER", (230, 190, 70)), ("AMBER", (190, 90, 30)), ("DARK", (60, 30, 18)))

META = {"id": "bl_cu_bb_taps", "class": "small_fixture", "tex": 1024, "ao": 0.4, "refs": []}


def plate_art(word, col):
    im, d = labels.canvas(400, 260, (0, 0, 0, 0))
    d.ellipse((4, 4, 396, 256), fill=(240, 232, 210, 255), outline=(150, 120, 60, 255), width=10)
    d.text((200, 132), word, font=B.ff("Oswald-Bold.ttf", 100), fill=col + (255,), anchor="mm")
    return labels.save(im, "cu_tap_" + word.lower())


def build():
    chrome = mats.brushed_metal("chrome", "#d4d6da", 0.16, along="Z", metal=0.8)
    steel = mats.brushed_metal("tray", "#b8babe", 0.32, along="X", metal=0.75)
    rubber = mats.M("mat", "#141414", 0.85)
    v = rubber.voronoi(160.0)
    rubber.bump(rubber.math("LESS_THAN", v.outputs["Distance"], 0.25), 0.8, 0.0012)
    # the bar mat and the drip tray on it
    parts.box("barmat", (SPAN + 0.06, 0.16, 0.008), loc=(0, -0.08, 0.004), mat=rubber.mat, bev=0.002, seg=2)
    parts.box("tray", (SPAN, 0.13, 0.022), loc=(0, -0.075, 0.008 + 0.011), mat=steel, bev=0.003, seg=2)
    grille = mats.M("grille", "#202022", 0.4, 0.6)
    parts.box("tray_in", (SPAN - 0.02, 0.11, 0.004), loc=(0, -0.075, 0.030), mat=grille.mat, bev=0)
    for k in range(17):
        x = -SPAN / 2 + 0.03 + k * (SPAN - 0.06) / 16
        parts.box("slat%d" % k, (0.006, 0.108, 0.004), loc=(x, -0.075, 0.033), mat=steel, bev=0.0008, seg=1)
    # the tower: a column from the counter behind the tray, a horizontal bar on top, three faucets
    parts.lathe("base", [(0.0, 0.0), (0.050, 0.0), (0.050, 0.012), (0.034, 0.024), (0.0, 0.024)], seg=24, loc=(0, 0.04, 0), mat=chrome)
    col = parts.cylinder("column", 0.030, H - 0.05, verts=24, loc=(0, 0.04, 0.024 + (H - 0.05) / 2), mat=chrome, bev=0.002)
    bar = parts.cylinder("crossbar", 0.030, SPAN, verts=24, loc=(0, 0.04, H - 0.028), rot=(0, 90, 0), mat=chrome, bev=0.002)
    for s in (-1, 1):
        parts.sphere("cap%d" % s, 0.030, 20, 10, loc=(s * SPAN / 2, 0.04, H - 0.028), mat=chrome, scale=(0.45, 1.0, 1.0))
    # frost where the cold line runs (a pale, rough band on the column)
    fr = mats.M("frost", "#d2dade", 0.55, 0.35)
    fn = fr.noise(700.0, 3.0)
    fr.link(fr.ramp(fn.outputs["Fac"], [(0.35, "#b8c2c8"), (0.7, "#eef4f6")]), fr.bsdf.inputs["Base Color"])
    fr.bump(fn.outputs["Fac"], 0.6, 0.0006)
    parts.cylinder("frost", 0.0312, 0.12, verts=24, loc=(0, 0.04, 0.17), mat=fr.mat, bev=0)
    for k, (word, colr) in enumerate(NAMES):
        x = (k - 1) * 0.15
        # faucet body: a shank out of the bar, the body down, the spout
        parts.cylinder("shank%d" % k, 0.010, 0.05, verts=14, loc=(x, 0.015, H - 0.030), rot=(90, 0, 0), mat=chrome, bev=0.001)
        parts.lathe("faucet%d" % k, [(0.0, 0.0), (0.009, 0.0), (0.012, 0.010), (0.014, 0.040), (0.012, 0.052), (0.0, 0.054)], seg=16,
                    loc=(x, -0.012, H - 0.080), mat=chrome)
        parts.cylinder("spout%d" % k, 0.005, 0.024, verts=10, loc=(x, -0.012, H - 0.090), mat=chrome, bev=0.0006)
        # the handle: a tapered black lever with a coloured top and an oval word plate
        hm = mats.M("handle%d" % k, "#1a1a1a", 0.35)
        hp = plate_art(word, colr)
        mats.decal(hm, hp, (x, -0.025, H + 0.065), (0.034, 0.022), "XZ", facing="-Y")
        parts.lathe("handle%d" % k, [(0.0, 0.0), (0.008, 0.0), (0.010, 0.030), (0.015, 0.100), (0.016, 0.118), (0.010, 0.124), (0.0, 0.125)],
                    seg=16, loc=(x, -0.012, H - 0.028), mat=hm.mat)
        tip = mats.M("tip%d" % k, "#%02x%02x%02x" % colr, 0.3)
        parts.sphere("tip%d" % k, 0.012, 14, 8, loc=(x, -0.012, H + 0.100), mat=tip.mat, scale=(1.0, 1.0, 0.7))
