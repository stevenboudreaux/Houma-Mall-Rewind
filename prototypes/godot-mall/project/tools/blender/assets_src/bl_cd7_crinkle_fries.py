"""Crinkle-cut seasoned fries from Corn Dog 7, in a printed paper fry cup. Hand item; item id
`cd7_crinkle_fries` (workstream FOOD, Nov 3 2026). Year "both": the stand is unchanged since the 1990s
(design/storefronts/corn-dog-7.md).

Packaging: Corn Dog 7's own style, taken from the store's code and textures (no photo of its 1995 paper
goods exists): the awning's glossy taxi yellow (#f6dc2c) and navy (#1b2466), the navy pinstripe, and the
store's own traced sign lettering (tools/stores/cd7_letters.json: "CORN DOG 7" brush caps, the "seasoned
fries" script, with the two hand strokes paint_corn_dog_7.py adds). The menu box sells "Seasoned Fries .99".
Guessed: that the stand used a printed cup at all (a round waxed fry cup; plain paper would be as likely),
its size, the lettering layout on it, the seasoning (paprika-orange specks).

Size: a ~12 oz fry cup, 100 mm tall, 76 mm across the top, 54 mm at the base; fries ~9.5 mm square,
crinkle-cut (two full ridges a face, 0.8 mm deep), 60-95 mm long, a heap of 18 standing out of the top.
Detail: each visible fry is geometry with the crinkle in its cross-section; the hidden ends inside the cup
are left open (never seen) and a domed "fill" of fries below the rim carries the crinkle in the normal map.
Origin: bottom centre of the cup.
"""
import math
import random
from PIL import Image, ImageDraw, ImageFilter
from lib import core, parts, mats, labels
import _food as F

H, RT, RB = 0.100, 0.038, 0.027
SEG = 36
YEL = (246, 220, 44, 255)
NAVY = (27, 36, 102, 255)
N_FRIES = 18
FRY_W = 0.0095
SEED = 11
STROKE = '<path d="%s" fill="none" stroke="#1b2466" stroke-width="2.1" stroke-linecap="round"/>'

META = {
    "id": "bl_cd7_crinkle_fries",
    "class": "hand",
    "tex": 2048,
    "ao": 0.45,
    "refs": [["refs/derived/signs/corndog_IMG_4461_f005.jpg", [0.12, 0.18, 1.0, 0.62], "Corn Dog 7's awning (packaging style)"]],
    "item_file": "food.json",
    "item": {"id": "cd7_crinkle_fries", "name": "Seasoned fries", "year": "both", "store": "CORN DOG 7", "price": 99},
}


def wrap_art():
    """The cup's print, flat: one turn round the cup (u = angle, the image's centre faces the front)."""
    L = F.cd7()
    w, h = 2400, 1000
    im = Image.new("RGBA", (w, h), YEL)
    d = ImageDraw.Draw(im)
    # glossy waxed yellow: a faint vertical sheen band
    for x in range(w):
        k = 1.0 + 0.05 * math.cos((x / w) * math.tau * 2)
        d.line([(x, 0), (x, h)], fill=tuple(min(255, int(c * k)) for c in YEL[:3]) + (255,))
    # the navy rim band and base band, and the pinstripe a third up (as on the awning)
    d.rectangle((0, 0, w, 46), fill=NAVY)
    d.rectangle((0, h - 40, w, h), fill=NAVY)
    s0, s1 = int(h * 0.60), int(h * 0.60) + 34
    d.rectangle((0, s0, w, s1), fill=NAVY)
    for cx in (w * 0.5, 0.0, w):       # front, and the back (wrapping the seam)
        cd = F.svg_letters(L["CD7"]["t"], 118)
        im.paste(cd, (int(cx - cd.width / 2), s0 - 70 - cd.height), cd)
        # "seasoned fries" crossing the stripe, the stripe broken behind it (the awning's look)
        sf = F.svg_letters(L["CD7O"]["l"], 120, extra=STROKE % "M-4.2 19.2 Q-1.2 17.5 2.6 10.6")
        x0 = int(cx - sf.width / 2)
        d.rectangle((x0 - 30, s0 - 4, x0 + sf.width + 30, s1 + 4), fill=YEL)
        im.paste(sf, (x0, s0 - 22), sf)
    im = im.filter(ImageFilter.GaussianBlur(0.6))
    return labels.save(im, "cd7_fries_wrap")


def build():
    rng = random.Random(SEED)
    wm = F.wrap_mat("cup", wrap_art(), 0.004, H - 0.002, rough=0.32)
    # the cup: the printed outer wall with a rolled rim, a white inner wall, a recessed base
    parts.lathe("cup_out", [(RB - 0.0015, 0.0), (RB, 0.002), (RT, H - 0.003), (RT + 0.0014, H - 0.0018),
                            (RT + 0.0016, H - 0.0004), (RT + 0.0006, H + 0.0006)], seg=SEG, mat=wm.mat, cap=False)
    inner = F.paper_mat("cup_in", "#f8f5ec", 0.7, grease=("#d9c79a", 90.0))
    parts.lathe("cup_in", [(RT - 0.0006, H + 0.0006), (RT - 0.0010, H - 0.002), (RB - 0.0012, 0.006),
                           (0.0, 0.006)], seg=SEG, mat=inner, cap=False)
    parts.lathe("cup_base", [(0.0, 0.0015), (RB - 0.0015, 0.0015), (RB - 0.0015, 0.0)], seg=SEG, mat=inner, cap=False)
    # the fries: golden, browner at the cut ends, paprika seasoning
    fm = F.crust_mat("fry", [(0.2, "#b0601a"), (0.45, "#e6a22c"), (0.8, "#f6c845")], rough=0.42, scale=90.0,
                     bump=0.35, dist=0.0006, specks=("#b2401a", 1400.0, 0.70))
    fmat = fm.mat
    # a mound of fries filling the cup below the rim (seen between the standing ones)
    fill = parts.sphere("fill", RT - 0.002, 18, 6, loc=(0, 0, H - 0.012), mat=fmat, scale=(1.0, 1.0, 0.35))
    F.lump(fill, 0.006, 0.004)
    # the heap: fries standing out of the cup, leaning out from the middle, longer at the back
    placed = []
    golden = 2.39996
    for i in range(N_FRIES):
        r = 0.026 * math.sqrt((i + 0.5) / N_FRIES)
        a = i * golden + rng.uniform(-0.2, 0.2)
        x, y = r * math.cos(a), r * math.sin(a)
        back = max(0.0, y) / 0.026            # the back of the heap stands taller (reads from the front)
        ln = rng.uniform(0.060, 0.080) + 0.016 * back
        lean = 0.08 + 0.38 * r / 0.026
        dv = (x / max(r, 1e-4) * lean + rng.uniform(-0.08, 0.08), y / max(r, 1e-4) * lean + rng.uniform(-0.08, 0.08), 1.0)
        z0 = H - 0.040 + rng.uniform(-0.006, 0.004)
        F.fry("fry%02d" % i, fmat, ln, FRY_W * rng.uniform(0.92, 1.05), FRY_W * rng.uniform(0.92, 1.05),
              kind="crinkle", rings=3, bend=rng.uniform(-0.003, 0.004), twist=rng.uniform(-0.2, 0.2),
              loc=(x, y, z0), dirv=dv, roll=rng.uniform(0, math.pi), n=32, waves=2, amp=0.0008, seed=i, cap_bottom=False)
