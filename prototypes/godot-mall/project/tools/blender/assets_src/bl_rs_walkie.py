"""A 1995 walkie-talkie (RadioShack, 1995 map). Hand item; the shop sold them in pairs, this is one unit.

Period check: FRS radios only arrived in 1996, so this is the 49 MHz / CB hand-held type of the early 90s:
a tall grey-black case, long telescoping chrome antenna, a speaker grille over most of the front, a big
push-to-talk bar on the left side, channel and volume knobs on top, a CALL button. Shape guessed from the
period type; colours from the 1999 video's walls (refs/new/radioshack_1999/). Brand invented (BAYOU COM).
Origin: bottom centre, upright, front facing Godot +Z.
"""
from lib import core, parts, mats, labels

W, D, H = 0.060, 0.034, 0.165
R = 0.012
ANT_LEN = 0.200
BODY = "#2b2c2f"

META = {
    "id": "bl_rs_walkie",
    "class": "hand",
    "tex": 1024,
    "ao": 0.35,
    "refs": [["refs/new/radioshack_1999/christmas-shopping-at-radioshack-in-1999_t000_021.jpg", [0.1, 0.0, 0.55, 0.45], "RS 1999 0:20 (radio wall)"]],
    "item": {"name": "Walkie-talkie", "year": 1995, "store": "RADIO SHACK"},
}


def art():
    im, d = labels.canvas(1000, 420)
    labels.text(d, (500, 90), "BAYOU COM", "bold", 130, (220, 220, 220, 255))
    labels.text(d, (500, 230), "49 MHz  2-WAY", "sans", 80, (230, 190, 40, 255))
    labels.text(d, (500, 340), "TALK ◀  CALL ●", "sans", 64, (190, 190, 190, 255))
    return labels.save(im, "rs_walkie_brand")


def build():
    brand = art()
    mb = mats.M("body", BODY, 0.5)
    mb.bump(mb.noise(800.0, 2.0).outputs["Fac"], 0.05, 0.0003)
    mats.decal(mb, brand, (0, -D / 2, 0.040), (0.044, 0.0185), "XZ", facing="-Y")
    parts.rounded_panel("body", W, H, D, R, 5, loc=(0, 0, H / 2), mat=mb.mat, bev=0.002)
    # speaker grille panel
    parts.rounded_panel("grillepanel", 0.046, 0.070, 0.0016, 0.004, 3, loc=(0, -D / 2 - 0.0004, 0.106),
                        mat=mats.flat("grillepanel", "#1a1a1c", 0.5), bev=0.0004)
    parts.grille("grille", 0.040, 0.062, slots=11, slot_w=0.0017, depth=0.0012, loc=(0, -D / 2 - 0.0012, 0.106),
                 mat=mats.flat("grille", "#3a3b3f", 0.45))
    # push-to-talk bar on the left side, call button on the front
    parts.rounded_panel("ptt", 0.040, 0.012, 0.004, 0.004, 3, loc=(-W / 2 - 0.0012, 0, 0.098), rot=(0, 90, 90),
                        mat=mats.flat("ptt", "#151516", 0.6), bev=0.0008)
    parts.button("call", 0.0055, 0.0022, loc=(0, -D / 2, 0.020), rot=(90, 0, 0), mat=mats.flat("call", "#b8241c", 0.4))
    # top: knobs and the telescoping antenna
    mk = mats.flat("knob", "#1c1c1e", 0.45)
    parts.cylinder("vol", 0.0062, 0.011, 18, loc=(0.010, 0.002, H + 0.004), mat=mk, bev=0.0008)
    parts.cylinder("chan", 0.0050, 0.008, 6, loc=(0.024, 0.002, H + 0.003), mat=mk, bev=0.0006)
    chrome = mats.brushed_metal("chrome", "#d4d6da", 0.15, along="Z", metal=0.8)
    parts.antenna("antenna", 0.0042, 0.0018, ANT_LEN, 5, loc=(-0.017, 0.004, H - 0.004), mat=chrome)
    parts.sphere("tip", 0.0030, 12, 6, loc=(-0.017, 0.004, H - 0.004 + ANT_LEN + 0.0015), mat=chrome)
    parts.cylinder("ant_base", 0.0072, 0.010, 16, loc=(-0.017, 0.004, H + 0.003), mat=mk)
    # belt clip and battery door seam
    parts.box("clip", (0.030, 0.003, 0.060), loc=(0, D / 2 + 0.0025, 0.110), mat=mats.flat("clip", "#18181a", 0.45), bev=0.001)
    parts.box("door", (0.048, 0.0008, 0.068), loc=(0, D / 2 + 0.0003, 0.042), mat=mats.flat("door", "#26272a", 0.55), bev=0.0003)
