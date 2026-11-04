#!/usr/bin/env python3
"""games, inc.'s WHIRLWIND (2026; workstream PRIZES, Steven Nov 3 2026: "literally the same machine",
slightly duller and faded): faded copies of Pocket Change's cabinet pictures (tex/pc/cyclone_*.png ->
tex/gi/ww_*.png, same size, same alpha), used by tools/stores/pocket_change/cyclone.gd when the build's
year is 2026. Thirty years of arcade light: colours lose about a third of their saturation, lift and warm
a little toward a dusty cream, contrast drops, and the big panels pick up faint scuffs. A guess at the
look (no photo of the 2026 cabinet in the refs pack). Run from the project folder.
"""
import glob
import os
import random
from PIL import Image, ImageEnhance, ImageDraw, ImageFilter

SAT = 0.66          # saturation kept
CONTRAST = 0.9
LIFT = (224, 214, 196)
LIFT_AMOUNT = 0.1
SCUFF_ON = ("side", "front", "console", "deck", "yellow", "decal", "decal_blank")

rnd = random.Random(2026)
for src in sorted(glob.glob("tex/pc/cyclone_*.png")):
    name = os.path.basename(src)[len("cyclone_"):-4]
    im = Image.open(src)
    alpha = im.getchannel("A") if im.mode == "RGBA" else None
    rgb = im.convert("RGB")
    rgb = ImageEnhance.Color(rgb).enhance(SAT)
    rgb = ImageEnhance.Contrast(rgb).enhance(CONTRAST)
    rgb = Image.blend(rgb, Image.new("RGB", rgb.size, LIFT), LIFT_AMOUNT)
    if name in SCUFF_ON and rgb.size[0] >= 256:
        sc = Image.new("L", rgb.size, 0)
        d = ImageDraw.Draw(sc)
        w, h = rgb.size
        for _ in range(int(w * h / 9000)):
            x, y = rnd.randrange(w), rnd.randrange(h)
            L = rnd.randrange(6, 40)
            d.line([(x, y), (x + rnd.randrange(-L, L), y + rnd.randrange(-4, 4))], fill=rnd.randrange(30, 90), width=1)
        sc = sc.filter(ImageFilter.GaussianBlur(0.6))
        rgb = Image.composite(Image.new("RGB", rgb.size, (236, 232, 222)), rgb, sc)
    if alpha is not None:
        rgb.putalpha(alpha)
    rgb.save("tex/gi/ww_%s.png" % name)
    print("tex/gi/ww_%s.png" % name)
