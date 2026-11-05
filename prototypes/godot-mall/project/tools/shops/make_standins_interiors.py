#!/usr/bin/env python3
"""Labelled stand-in items for the four counter shops of ws/interiors (Nov 4 2026; design/godot-shops.md,
design/storefronts/great-american-cookie.md, auntie-annes.md, payless.md, spencers.md).

Steven (Nov 4, through the coordinator): add the proposed shop items, prices guessed and marked PLACEHOLDER.
No real models exist for them yet, so each is a STAND-IN the same way tools/shops/make_standins.py makes
RadioShack's (a few primitives of about the right size and colour, a "STAND-IN" tag over it, an icon with the
yellow STAND-IN band). Everything is invented and generic (IP rule): no brand, no logo, no licensed print; the
shoe boxes are plain, the tee and the mug carry invented words only.

Writes, run from the project folder (python3 tools/shops/make_standins_interiors.py):
  models/bl_standin_<key>/<id>.tscn, <id>_icon.png
  data/items/great_american_cookie.json, auntie_annes.json, payless.json, spencers.json (through items_io.py)
Then `godot --headless --path . --import` once for the PNGs.

When a real model lands: point the shop at its id in data/story/shops.json and delete the stand-in here.
"""
import math
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import make_standins as MS  # noqa: E402  (scene(), band(), font(), hexc(): the same stand-in look)

ROOT = MS.ROOT
GAC, AA, PAY, SP = "GREAT AMERICAN COOKIE CO", "AUNTIE ANNE'S", "PAYLESS SHOES", "SPENCER'S"

# parts as in make_standins.py: [shape, size, pos, colour(, "rotz")], metres, origin at the bottom centre, front +z
STANDINS = [
    # ---- Great American Cookie Co. (both years: the same case and stock in 1995 and 2026)
    {"id": "standin_gac_choc_chip_cookie", "name": "Chocolate-chip cookie", "class": "hand", "store": GAC, "year": "both",
     "category": "food", "subcategory": "sweet", "for": "a model (Great American Cookie Co.: a chocolate-chip cookie)",
     "icon": "cookie", "parts": [["cyl", [0.05, 0.012], [0, 0, 0], "#c8935a"]] +
     [["box", [0.012, 0.006, 0.012], [math.cos(a) * r, 0.011, math.sin(a) * r], "#3a2214"]
      for a, r in [(0.3, 0.02), (1.9, 0.03), (3.4, 0.015), (4.6, 0.033), (5.6, 0.025), (2.6, 0.0)]]},
    {"id": "standin_gac_cake_slice", "name": "Cookie-cake slice", "class": "hand", "store": GAC, "year": "both",
     "category": "food", "subcategory": "sweet", "for": "a model (Great American Cookie Co.: a slice of cookie cake)",
     "icon": "cake", "parts": [["box", [0.11, 0.004, 0.11], [0, 0, 0], "#f4f2ee"], ["box", [0.09, 0.016, 0.08], [0, 0.004, 0], "#c8935a"],
                               ["box", [0.09, 0.008, 0.012], [0, 0.02, 0.034], "#e86a9a"], ["box", [0.02, 0.006, 0.02], [0.01, 0.02, -0.01], "#f8f0e8"]]},
    {"id": "standin_gac_brownie", "name": "Brownie", "class": "hand", "store": GAC, "year": "both",
     "category": "food", "subcategory": "sweet", "for": "a model (Great American Cookie Co.: a brownie)",
     "icon": "brownie", "parts": [["box", [0.075, 0.035, 0.075], [0, 0, 0], "#4a2a18"], ["box", [0.076, 0.004, 0.076], [0, 0.035, 0], "#3a1e10"]]},
    {"id": "standin_gac_fountain_drink", "name": "Fountain drink", "class": "hand", "store": GAC, "year": "both",
     "category": "drink", "subcategory": "soft", "for": "a model (Great American Cookie Co.: a fountain drink)",
     "icon": "drink", "icon_col": "#c8202c",
     "parts": [["cyl", [0.042, 0.16], [0, 0, 0], "#f4f2ee"], ["cyl", [0.043, 0.04], [0, 0.07, 0], "#7a1830"],
               ["cyl", [0.046, 0.01], [0, 0.16, 0], "#f8f8f6"], ["cyl", [0.004, 0.08], [0.01, 0.17, 0], "#c8202c"]]},
    # ---- Auntie Anne's (2026)
    {"id": "standin_aa_original_pretzel", "name": "Original pretzel", "class": "hand", "store": AA, "year": 2026,
     "category": "food", "subcategory": "snack", "for": "a model (Auntie Anne's: a salted pretzel; the warmer's KNOT path in bl_aa_warmer.py could make it)",
     "icon": "pretzel", "icon_col": "#b8763a", "parts": [["box", [0.17, 0.004, 0.13], [0, 0, 0], "#f4f2ee"]] + [
         ["cyl", [0.014, 0.15], [0, 0.004, 0.035], "#b8763a", "rotz"], ["cyl", [0.014, 0.12], [-0.035, 0.004, -0.01], "#a8682e", "rotz"],
         ["cyl", [0.014, 0.12], [0.035, 0.004, -0.01], "#a8682e", "rotz"], ["cyl", [0.014, 0.15], [0, 0.004, -0.045], "#b8763a", "rotz"]]},
    {"id": "standin_aa_cinnamon_pretzel", "name": "Cinnamon sugar pretzel", "class": "hand", "store": AA, "year": 2026,
     "category": "food", "subcategory": "sweet", "for": "a model (Auntie Anne's: a cinnamon sugar pretzel)",
     "icon": "pretzel", "icon_col": "#9a5a2a", "parts": [["box", [0.17, 0.004, 0.13], [0, 0, 0], "#f4f2ee"]] + [
         ["cyl", [0.015, 0.15], [0, 0.004, 0.035], "#9a5a2a", "rotz"], ["cyl", [0.015, 0.12], [-0.035, 0.004, -0.01], "#8e5226", "rotz"],
         ["cyl", [0.015, 0.12], [0.035, 0.004, -0.01], "#8e5226", "rotz"], ["cyl", [0.015, 0.15], [0, 0.004, -0.045], "#9a5a2a", "rotz"]]},
    {"id": "standin_aa_pretzel_bites", "name": "Cup of pretzel bites", "class": "hand", "store": AA, "year": 2026,
     "category": "food", "subcategory": "snack", "for": "a model (Auntie Anne's: a cup of pretzel bites)",
     "icon": "bites", "parts": [["cyl", [0.048, 0.09], [0, 0, 0], "#1f2c6a"], ["cyl", [0.046, 0.03], [0, 0.08, 0], "#b8763a"],
                                ["box", [0.02, 0.018, 0.02], [0.015, 0.105, 0.01], "#a8682e"], ["box", [0.02, 0.018, 0.02], [-0.016, 0.104, -0.006], "#c08040"]]},
    {"id": "standin_aa_lemonade", "name": "Lemonade", "class": "hand", "store": AA, "year": 2026,
     "category": "drink", "subcategory": "soft", "for": "a model (Auntie Anne's: a lemonade)",
     "icon": "drink", "icon_col": "#f2d040",
     "parts": [["cyl", [0.042, 0.16], [0, 0, 0], "#f6e27a"], ["cyl", [0.043, 0.05], [0, 0.06, 0], "#1f2c6a"],
               ["cyl", [0.046, 0.01], [0, 0.16, 0], "#f8f8f6"], ["cyl", [0.004, 0.08], [0.01, 0.17, 0], "#1f3cbe"]]},
    # ---- Payless ShoeSource (1995): plain boxes, no maker's name
    {"id": "standin_pay_sneakers", "name": "Sneakers (boxed pair)", "class": "hand", "store": PAY, "year": 1995,
     "category": "clothing", "subcategory": "shoes", "for": "a model (Payless: a pair of sneakers in a box)",
     "icon": "shoebox", "icon_col": "#f4f4f2", "shoe": "sneaker",
     "parts": [["box", [0.32, 0.11, 0.2], [0, 0, 0], "#2a5aa8"], ["box", [0.325, 0.03, 0.205], [0, 0.1, 0], "#f2f2ee"]]},
    {"id": "standin_pay_pumps", "name": "Pumps (boxed pair)", "class": "hand", "store": PAY, "year": 1995,
     "category": "clothing", "subcategory": "shoes", "for": "a model (Payless: a pair of pumps in a box)",
     "icon": "shoebox", "icon_col": "#1c1c20", "shoe": "pump",
     "parts": [["box", [0.29, 0.1, 0.18], [0, 0, 0], "#c8202c"], ["box", [0.295, 0.03, 0.185], [0, 0.09, 0], "#f2f2ee"]]},
    {"id": "standin_pay_sandals", "name": "Sandals (boxed pair)", "class": "hand", "store": PAY, "year": 1995,
     "category": "clothing", "subcategory": "shoes", "for": "a model (Payless: a pair of sandals in a box)",
     "icon": "shoebox", "icon_col": "#c8a070", "shoe": "sandal",
     "parts": [["box", [0.28, 0.08, 0.17], [0, 0, 0], "#e88aa8"], ["box", [0.285, 0.03, 0.175], [0, 0.07, 0], "#f2f2ee"]]},
    {"id": "standin_pay_boots", "name": "Boots (boxed pair)", "class": "hand", "store": PAY, "year": 1995,
     "category": "clothing", "subcategory": "shoes", "for": "a model (Payless: a pair of boots in a box)",
     "icon": "shoebox", "icon_col": "#5a3218", "shoe": "boot",
     "parts": [["box", [0.36, 0.13, 0.25], [0, 0, 0], "#7a5a3a"], ["box", [0.365, 0.03, 0.255], [0, 0.12, 0], "#f2f2ee"]]},
    {"id": "standin_pay_socks", "name": "Socks, 3-pack", "class": "hand", "store": PAY, "year": 1995,
     "category": "clothing", "subcategory": "socks", "for": "a model (Payless: a 3-pack of socks on a card)",
     "icon": "socks", "parts": [["box", [0.1, 0.22, 0.03], [0, 0, 0], "#f6f6f2"], ["box", [0.104, 0.05, 0.034], [0, 0.17, 0], "#c8202c"]]},
    {"id": "standin_pay_shoe_polish", "name": "Shoe polish", "class": "pocket", "store": PAY, "year": 1995,
     "category": "clothing", "subcategory": "care", "for": "a model (Payless: a tin of shoe polish)",
     "icon": "polish", "parts": [["cyl", [0.032, 0.022], [0, 0, 0], "#1c1c20"], ["cyl", [0.033, 0.006], [0, 0.022, 0], "#c8a040"]]},
    # ---- Spencer's (2026): invented prints and words only
    {"id": "standin_sp_tee", "name": "Printed tee", "class": "hand", "store": SP, "year": 2026,
     "category": "clothing", "subcategory": "shirt", "for": "a model (Spencer's: a folded printed tee, an invented print)",
     "icon": "tee", "icon_col": "#1c1c20",
     "parts": [["box", [0.24, 0.03, 0.3], [0, 0, 0], "#1c1c20"], ["box", [0.12, 0.002, 0.12], [0, 0.03, 0.02], "#3cdc78"]]},
    {"id": "standin_sp_mug", "name": "Mug", "class": "hand", "store": SP, "year": 2026,
     "category": "home", "subcategory": "mug", "for": "a model (Spencer's: a coffee mug with invented words)",
     "icon": "mug", "parts": [["cyl", [0.042, 0.1], [0, 0, 0], "#f2f2ee"], ["box", [0.012, 0.06, 0.03], [0.05, 0.02, 0], "#f2f2ee"],
                              ["cyl", [0.043, 0.02], [0, 0.06, 0], "#e83a78"]]},
    {"id": "standin_sp_plush", "name": "Plush", "class": "hand", "store": SP, "year": 2026,
     "category": "toy", "subcategory": "plush", "for": "a model (Spencer's: an invented plush)",
     "icon": "plush", "parts": [["cyl", [0.07, 0.12], [0, 0, 0], "#8a5ad0"], ["cyl", [0.06, 0.09], [0, 0.12, 0], "#9a6ae0"],
                                ["box", [0.02, 0.02, 0.01], [-0.022, 0.17, 0.058], "#f8f8f6"], ["box", [0.02, 0.02, 0.01], [0.022, 0.17, 0.058], "#f8f8f6"]]},
    {"id": "standin_sp_stickers", "name": "Sticker pack", "class": "pocket", "store": SP, "year": 2026,
     "category": "stationery", "subcategory": "stickers", "for": "a model (Spencer's: a carded pack of invented stickers)",
     "icon": "stickers", "parts": [["box", [0.1, 0.15, 0.006], [0, 0, 0], "#f4f4f0"], ["box", [0.08, 0.1, 0.002], [0, 0.015, 0.004], "#3cb4f0"]]},
]


def icon(e):
    W = 256
    im = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    k = e["icon"]
    col = MS.hexc(e.get("icon_col", "#888888")) + (255,)
    if k == "cookie":
        d.ellipse([40, 50, 216, 206], fill=(200, 147, 90, 255), outline=(160, 110, 60, 255), width=4)
        for x, y in [(90, 90), (150, 80), (120, 130), (170, 150), (80, 160), (130, 175), (180, 110)]:
            d.ellipse([x - 9, y - 7, x + 9, y + 7], fill=(58, 34, 20, 255))
    elif k == "cake":
        d.polygon([(40, 170), (216, 170), (128, 50)], fill=(200, 147, 90, 255))
        d.line([(40, 170), (216, 170)], fill=(232, 106, 154, 255), width=16)
        for x in range(60, 200, 26):
            d.ellipse([x - 8, 154, x + 8, 170], fill=(248, 240, 232, 255))
    elif k == "brownie":
        d.rectangle([56, 70, 200, 186], fill=(74, 42, 24, 255))
        d.polygon([(56, 70), (200, 70), (216, 54), (72, 54)], fill=(58, 30, 16, 255))
        d.polygon([(200, 70), (216, 54), (216, 170), (200, 186)], fill=(52, 28, 14, 255))
    elif k == "drink":
        d.polygon([(84, 56), (172, 56), (162, 204), (94, 204)], fill=(244, 242, 238, 255))
        d.polygon([(88, 110), (168, 110), (165, 150), (91, 150)], fill=col)
        d.rectangle([80, 46, 176, 58], fill=(248, 248, 246, 255))
        d.line([140, 48, 156, 14], fill=col, width=7)
    elif k == "pretzel":
        d.ellipse([40, 80, 136, 190], outline=col, width=22)
        d.ellipse([120, 80, 216, 190], outline=col, width=22)
        d.arc([60, 30, 196, 150], 200, 340, fill=col, width=22)
        for x, y in [(70, 120), (100, 170), (160, 110), (190, 150), (128, 60), (150, 175)]:
            # salt on the original, cinnamon sugar on the other
            d.rectangle([x - 3, y - 3, x + 3, y + 3], fill=(250, 250, 248, 255) if "original" in e["id"] else (226, 196, 150, 255))
    elif k == "bites":
        d.polygon([(70, 100), (186, 100), (172, 210), (84, 210)], fill=(31, 44, 106, 255))
        for x, y in [(90, 90), (125, 80), (160, 92), (108, 70), (145, 66)]:
            d.ellipse([x - 22, y - 18, x + 22, y + 18], fill=(184, 118, 58, 255), outline=(150, 90, 40, 255), width=2)
    elif k == "shoebox":
        d.polygon([(30, 110), (180, 110), (226, 80), (76, 80)], fill=(242, 242, 238, 255))
        d.rectangle([30, 110, 180, 200], fill=(200, 200, 196, 255))
        d.polygon([(180, 110), (226, 80), (226, 170), (180, 200)], fill=(176, 176, 172, 255))
        s = e["shoe"]
        if s == "pump":
            d.polygon([(70, 90), (80, 60), (92, 60), (100, 84), (170, 84), (170, 96), (70, 96)], fill=col)
        elif s == "boot":
            d.polygon([(90, 96), (90, 24), (130, 24), (130, 76), (180, 80), (180, 96)], fill=col)
        elif s == "sandal":
            d.rectangle([70, 88, 180, 96], fill=col)
            for x in (95, 125, 155):
                d.arc([x - 16, 66, x + 16, 100], 180, 360, fill=col, width=6)
        else:
            d.rounded_rectangle([70, 62, 185, 96], radius=16, fill=col)
            d.rectangle([70, 90, 185, 98], fill=(250, 250, 250, 255))
            for x in range(100, 160, 14):
                d.line([x, 66, x + 8, 80], fill=(40, 90, 170, 255), width=4)
        d.rectangle([40, 166, 92, 190], fill=(250, 250, 250, 255))
    elif k == "socks":
        d.rectangle([76, 36, 180, 214], fill=(246, 246, 242, 255), outline=(200, 200, 196, 255), width=3)
        d.rectangle([76, 36, 180, 78], fill=(200, 32, 44, 255))
        for i, x in enumerate((98, 128, 158)):
            d.polygon([(x - 10, 90), (x + 10, 90), (x + 10, 170), (x + 22, 186), (x + 4, 196), (x - 10, 176)], fill=(236, 236, 230, 255), outline=(180, 180, 176, 255))
    elif k == "polish":
        d.ellipse([46, 120, 210, 190], fill=(28, 28, 32, 255))
        d.rectangle([46, 96, 210, 156], fill=(28, 28, 32, 255))
        d.ellipse([46, 64, 210, 128], fill=(200, 160, 64, 255))
        d.ellipse([90, 82, 166, 110], outline=(150, 112, 40, 255), width=4)
    elif k == "tee":
        d.polygon([(64, 50), (104, 36), (152, 36), (192, 50), (226, 96), (196, 112), (186, 100), (186, 216), (70, 216), (70, 100),
                   (60, 112), (30, 96)], fill=col)
        d.rectangle([94, 100, 162, 150], fill=(60, 220, 120, 255))
        d.text((128, 178), "BAYOU", font=MS.font(MS.SANS, 30), fill=(250, 220, 40, 255), anchor="mm")
    elif k == "mug":
        d.rounded_rectangle([64, 56, 176, 206], radius=12, fill=(242, 242, 238, 255))
        d.arc([150, 90, 214, 170], 270, 90, fill=(242, 242, 238, 255), width=16)
        d.text((120, 132), "NOPE", font=MS.font(MS.SANS, 34), fill=(232, 58, 120, 255), anchor="mm")
    elif k == "plush":
        d.ellipse([60, 110, 196, 220], fill=(138, 90, 208, 255))
        d.ellipse([74, 34, 182, 136], fill=(154, 106, 224, 255))
        d.ellipse([74, 30, 104, 64], fill=(154, 106, 224, 255))
        d.ellipse([152, 30, 182, 64], fill=(154, 106, 224, 255))
        for x in (108, 148):
            d.ellipse([x - 9, 74, x + 9, 92], fill=(250, 250, 248, 255))
            d.ellipse([x - 4, 80, x + 4, 88], fill=(20, 20, 20, 255))
    elif k == "stickers":
        d.rectangle([66, 30, 190, 220], fill=(244, 244, 240, 255), outline=(190, 190, 186, 255), width=3)
        d.ellipse([118, 38, 138, 52], fill=(120, 120, 120, 255))
        for (x, y, c, s) in [(96, 90, (60, 180, 240), "o"), (156, 90, (240, 60, 120), "t"), (96, 150, (250, 220, 40), "t"), (156, 150, (60, 220, 120), "o")]:
            if s == "o":
                d.ellipse([x - 22, y - 22, x + 22, y + 22], fill=c + (255,))
            else:
                d.polygon([(x, y - 24), (x + 24, y + 18), (x - 24, y + 18)], fill=c + (255,))
        d.text((128, 200), "STICKERS", font=MS.font(MS.SANS, 22), fill=(30, 30, 30, 255), anchor="mm")
    MS.band(im)
    return im


def main():
    os.chdir(ROOT)
    sys.path.insert(0, os.path.join(ROOT, "tools", "items"))
    import items_io
    items = []
    for e in STANDINS:
        d = MS.folder(e)
        os.makedirs(d, exist_ok=True)
        icon(e).save(os.path.join(d, e["id"] + "_icon.png"), optimize=True)
        with open(os.path.join(d, e["id"] + ".tscn"), "w") as f:
            f.write(MS.scene(e, d))
        items.append({"id": e["id"], "name": e["name"], "category": e["category"], "subcategory": e["subcategory"],
                      "class": e["class"], "scene": "res://%s/%s.tscn" % (d, e["id"]),
                      "icon": "res://%s/%s_icon.png" % (d, e["id"]), "year": e["year"], "store": e["store"],
                      "standin": True, "standin_for": e["for"]})
    items_io.upsert(items)
    print("wrote %d stand-ins" % len(items))


if __name__ == "__main__":
    main()
