"""A 1995 handheld programmable scanner radio (RadioShack, 1995 map). Hand item.

Reference: refs/new/radioshack_1999/ (the walls of black out-of-box electronics, 0:44-1:00; the 1999 video
is four years late, so only the kind of goods and colours are taken). The shape is the period type, guessed:
a tall black case, rubber-duck antenna and two knobs on top, speaker slots over a grey-green LCD, a 4 x 5
keypad, belt clip behind. Brand and model invented (BAYOU COM "SC-200").
Origin: bottom centre, standing upright, front facing Godot +Z.
"""
from lib import core, parts, mats, labels

W, D, H = 0.064, 0.036, 0.152
R = 0.010
LCD = (0.044, 0.018)
LCD_Z = 0.106
KEYS_Z = 0.058
ANT = (0.0058, 0.0042, 0.120)     # base radius, tip radius, length
BODY = "#18181a"

META = {
    "id": "bl_rs_scanner",
    "class": "hand",
    "tex": 1024,
    "ao": 0.35,
    "refs": [["refs/new/radioshack_1999/christmas-shopping-at-radioshack-in-1999_t000_056.jpg", [0.55, 0.0, 1.0, 0.75], "RS 1999 0:55 (wall of black electronics)"]],
    "item": {"name": "Scanner radio", "year": 1995, "store": "RADIO SHACK"},
}


def art():
    im, d = labels.canvas(880, 360, (122, 136, 108, 255))
    labels.text(d, (30, 90), "CH 047", "sans", 110, (30, 38, 28, 255), "lm")
    labels.text(d, (850, 90), "SCAN", "sans", 70, (30, 38, 28, 255), "rm")
    labels.text(d, (30, 260), "154.430", "sans", 150, (30, 38, 28, 255), "lm")
    lcd = labels.save(im, "rs_scanner_lcd")
    im, d = labels.canvas(1200, 340)
    labels.text(d, (20, 110), "BAYOU COM", "bold", 120, (215, 215, 215, 255), "lm")
    labels.text(d, (1180, 110), "SC-200", "sans", 90, (200, 60, 50, 255), "rm")
    labels.text(d, (20, 260), "200 CHANNEL PROGRAMMABLE SCANNER", "sans", 58, (175, 175, 175, 255), "lm")
    brand = labels.save(im, "rs_scanner_brand")
    # key legends: 4 columns x 5 rows
    keys = [["1", "2", "3", "SCAN"], ["4", "5", "6", "MAN"], ["7", "8", "9", "PGM"], ["CL", "0", ".", "E"], ["▲", "▼", "L/O", "PRI"]]
    im, d = labels.canvas(1000, 1000)
    for r, row in enumerate(keys):
        for c, k in enumerate(row):
            labels.text(d, (125 + c * 250, 100 + r * 200), k, "sans", 80 if len(k) < 3 else 58, (235, 235, 235, 255))
    legends = labels.save(im, "rs_scanner_keys")
    return lcd, brand, legends


def build():
    lcd, brand, legends = art()
    mb = mats.M("body", BODY, 0.5)
    mb.bump(mb.noise(800.0, 2.0).outputs["Fac"], 0.05, 0.0003)
    mats.decal(mb, brand, (0, -D / 2, 0.087), (0.050, 0.0142), "XZ", facing="-Y")
    parts.rounded_panel("body", W, H, D, R, 5, loc=(0, 0, H / 2), mat=mb.mat, bev=0.002)
    # speaker slots above the screen
    parts.grille("grille", 0.040, 0.012, slots=9, slot_w=0.0018, depth=0.0012, loc=(0, -D / 2 - 0.0004, 0.134),
                 mat=mats.flat("grille", "#0d0d0e", 0.55))
    parts.rounded_panel("bezel", LCD[0] + 0.006, LCD[1] + 0.006, 0.0014, 0.002, 2, loc=(0, -D / 2 - 0.0003, LCD_Z),
                        mat=mats.flat("bezel", "#0a0a0b", 0.25), bev=0.0004)
    ml = mats.M("lcd", "#7a886c", 0.15)
    mats.decal(ml, lcd, (0, 0, LCD_Z), LCD, "XZ")
    parts.box("lcd", (LCD[0], 0.0006, LCD[1]), loc=(0, -D / 2 - 0.0010, LCD_Z), mat=ml.mat, bev=0)
    # keypad: 4 x 5 grey rubber keys with printed legends
    mk = mats.M("keys", "#55565a", 0.6)
    mats.decal(mk, legends, (0, 0, KEYS_Z), (0.052, 0.050), "XZ")
    parts.keypad("keypad", rows=5, cols=4, key=(0.0105, 0.0072, 0.0024), pitch=(0.013, 0.010), loc=(0, -D / 2 + 0.0002, KEYS_Z),
                 rot=(90, 0, 0), mat=mk.mat, bev=0.0009)
    # top: antenna, volume and squelch knobs
    parts.antenna("antenna", ANT[0], ANT[1], ANT[2], 3, loc=(-0.018, 0.004, H - 0.002), mat=mats.flat("rubber", "#121213", 0.75))
    parts.cylinder("ant_base", 0.0075, 0.008, 16, loc=(-0.018, 0.004, H + 0.002), mat=mats.flat("ant_base", "#2a2a2c", 0.4))
    mknob = mats.M("knob", "#232325", 0.45)
    for i, x in enumerate((0.006, 0.021)):
        parts.cylinder("knob%d" % i, 0.0058, 0.010, 18, loc=(x, 0.002, H + 0.004), mat=mknob.mat, bev=0.0008)
    # belt clip
    parts.box("clip", (0.034, 0.003, 0.070), loc=(0, D / 2 + 0.0025, 0.095), mat=mats.flat("clip", "#141416", 0.45), bev=0.001)
