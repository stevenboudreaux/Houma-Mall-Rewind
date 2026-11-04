"""Fresh lemonade from Corn Dog 7, in a printed paper cup with a clear lid. Hand item; item id
`cd7_lemonade` (workstream FOOD, Nov 3 2026). Year "both" (the stand is unchanged since the 1990s).

Packaging: Corn Dog 7's own style from the store's code and textures (no photo of its cups): the awning's
taxi yellow and navy, the pinstripe, and the store's traced sign lettering (tools/stores/cd7_letters.json:
"CORN DOG 7" and the "fresh lemonade" script, with paint_corn_dog_7.py's two hand strokes). The awning says
"fresh lemonade"; the menu box "Fresh Lemonade .99".
Guessed: the cup (printed waxed paper, 16 oz), a clear flat lid with a straw slot so the drink reads up close,
the cloudy lemonade with pulp, the ice, a lemon wheel floating in it, the navy-striped straw.

Size: 16 oz cup, 135 mm tall, 90 mm across the top, 60 mm at the base; straw 6.5 mm, 240 mm long.
Materials: the lid is its own transparent glTF material (not baked); everything else is in the atlas.
Origin: bottom centre of the cup.
"""
import math
import random
from PIL import Image, ImageDraw, ImageFilter
from lib import core, parts, mats, labels
import _food as F

H, RT, RB = 0.135, 0.045, 0.030
SEG = 36
YEL = (246, 220, 44, 255)
NAVY = (27, 36, 102, 255)
LIQ = H - 0.011            # the lemonade's surface
SEED = 5
STROKE = '<path d="%s" fill="none" stroke="#1b2466" stroke-width="2.1" stroke-linecap="round"/>'

META = {
    "id": "bl_cd7_lemonade",
    "class": "hand",
    "tex": 2048,
    "ao": 0.4,
    "refs": [["refs/derived/signs/corndog_IMG_4461_f005.jpg", [0.12, 0.18, 1.0, 0.62], "Corn Dog 7's awning (packaging style)"]],
    "item_file": "food.json",
    "item": {"id": "cd7_lemonade", "name": "Fresh lemonade", "year": "both", "store": "CORN DOG 7", "price": 99},
}


def wrap_art():
    L = F.cd7()
    w, h = 2600, 1300
    im = Image.new("RGBA", (w, h), YEL)
    d = ImageDraw.Draw(im)
    for x in range(w):
        k = 1.0 + 0.05 * math.cos((x / w) * math.tau * 2)
        d.line([(x, 0), (x, h)], fill=tuple(min(255, int(c * k)) for c in YEL[:3]) + (255,))
    d.rectangle((0, 0, w, 50), fill=NAVY)
    d.rectangle((0, h - 44, w, h), fill=NAVY)
    s0 = int(h * 0.52)
    s1 = s0 + 36
    d.rectangle((0, s0, w, s1), fill=NAVY)
    for cx in (w * 0.5, 0.0, w):
        cd = F.svg_letters(L["CD7"]["t"], 130)
        im.paste(cd, (int(cx - cd.width / 2), s0 - 60 - cd.height), cd)
        fl = F.svg_letters(L["CD7O"]["r"], 140, extra=STROKE % "M130.6 15.6 C137.5 14.8 137.2 9.6 133.2 10.2" +
                           STROKE % "M132.2 19.4 Q136.5 19.6 140 15.8")
        im.paste(fl, (int(cx - fl.width / 2), s1 + 50), fl)
    # a ring of lemons round the bottom band
    for k in range(14):
        x = (k + 0.5) * w / 14
        y = h - 120
        d.ellipse((x - 40, y - 30, x + 40, y + 30), fill=(255, 240, 120, 255), outline=NAVY, width=6)
        d.line((x + 34, y - 6, x + 52, y - 18), fill=(40, 120, 40, 255), width=8)
    im = im.filter(ImageFilter.GaussianBlur(0.6))
    return labels.save(im, "cd7_lemonade_wrap")


def lemon_mat():
    """A lemon wheel seen face-on: rind, pith, ten segments with pale membranes and pulp."""
    m = mats.M("lemon", "#f2dc5a", 0.35)
    sep = m.node("ShaderNodeSeparateXYZ")
    m.link(m.coords("Object"), sep.inputs[0])
    lx = m.math("SUBTRACT", sep.outputs["X"], LEMON_C[0])
    ly = m.math("SUBTRACT", sep.outputs["Y"], LEMON_C[1])
    r = m.math("SQRT", m.math("ADD", m.math("MULTIPLY", lx, lx), m.math("MULTIPLY", ly, ly)))
    ang = m.math("ARCTAN2", ly, lx)
    memb = m.math("GREATER_THAN", m.math("ABSOLUTE", m.math("SINE", m.math("MULTIPLY", ang, 5.0))), 0.93)
    pulp = m.noise(900.0, 3.0)
    col = m.ramp(pulp.outputs["Fac"], [(0.35, "#e9cf3c"), (0.65, "#fbe98a")])
    col = m.mix(memb, col, "#fbf6d8")
    pith = m.math("GREATER_THAN", r, LEMON_R * 0.80)
    col = m.mix(pith, col, "#fbf7e2")
    rind = m.math("GREATER_THAN", r, LEMON_R * 0.92)
    col = m.mix(rind, col, "#f2c40c")
    core_ = m.math("LESS_THAN", r, LEMON_R * 0.08)
    col = m.mix(core_, col, "#fbf6d8")
    m.link(col, m.bsdf.inputs["Base Color"])
    m.bump(pulp.outputs["Fac"], 0.4, 0.0005)
    return m.mat


LEMON_C = (-0.012, 0.010)
LEMON_R = 0.026


def build():
    rng = random.Random(SEED)
    wm = F.wrap_mat("cup", wrap_art(), 0.004, H - 0.002, rough=0.32)
    parts.lathe("cup_out", [(RB - 0.0015, 0.0), (RB, 0.002), (RT, H - 0.003), (RT + 0.0014, H - 0.0018),
                            (RT + 0.0016, H - 0.0004), (RT + 0.0006, H + 0.0006)], seg=SEG, mat=wm.mat, cap=False)
    inner = F.paper_mat("cup_in", "#f8f5ec", 0.6)
    parts.lathe("cup_in", [(RT - 0.0006, H + 0.0006), (RT - 0.0010, H - 0.002), (RT - 0.0042, LIQ - 0.004)], seg=SEG, mat=inner, cap=False)
    parts.lathe("cup_base", [(0.0, 0.0015), (RB - 0.0015, 0.0015), (RB - 0.0015, 0.0)], seg=SEG, mat=inner, cap=False)
    # the lemonade: cloudy pale yellow with fine pulp, a lens of liquid filling the cup to LIQ
    lm = mats.M("lemonade", "#f4ec9c", 0.08)
    n = lm.noise(700.0, 3.0)
    lm.link(lm.ramp(n.outputs["Fac"], [(0.4, "#efe48a"), (0.7, "#fbf5c4")]), lm.bsdf.inputs["Base Color"])
    lm.bump(n.outputs["Fac"], 0.08, 0.0003)
    rl = RT - 0.0042
    parts.lathe("lemonade", [(rl - 0.0004, LIQ - 0.004), (rl, LIQ), (0.0, LIQ)], seg=SEG, mat=lm.mat, cap=False)
    # ice: rounded cubes floating, a little above the surface
    ice = mats.M("ice", "#e8f2f4", 0.1)
    ice.bump(ice.noise(300.0, 3.0).outputs["Fac"], 0.5, 0.0006)
    for k, (x, y) in enumerate(((0.020, -0.014), (0.024, 0.014), (-0.004, -0.026), (0.006, 0.030), (-0.030, -0.010))):
        s = rng.uniform(0.015, 0.019)
        parts.box("ice%d" % k, (s, s, s * 0.9), loc=(x, y, LIQ - s * 0.15), rot=(rng.uniform(-20, 20), rng.uniform(-20, 20), rng.uniform(0, 90)),
                  mat=ice.mat, bev=0.0028, seg=2)
    # the lemon wheel floating, tipped a little
    lw = parts.cylinder("lemon", LEMON_R, 0.005, verts=28, loc=(LEMON_C[0], LEMON_C[1], LIQ + 0.0012), mat=lemon_mat(), bev=0.0012)
    # the straw, white with navy stripes, through the lid's cross-slot, leaning back-right
    sm = F.stripe_straw_mat("straw", "#f6f4ee", "#1b2466", turns=2.0, pitch=140.0)
    st = F.between("straw", (0.006, 0.004, 0.012), (0.024, 0.030, H + 0.105), 0.00325, sm, verts=12)
    # the clear flat lid: a recessed top inside a rim that snaps over the cup's, a cross-slot boss
    lid = mats.clear_plastic("lid", "#eef4f4", 0.16, 0.1)
    parts.lathe("lid", [(0.0, H + 0.0035), (RT - 0.006, H + 0.0035), (RT - 0.0045, H + 0.0070), (RT + 0.0006, H + 0.0080),
                        (RT + 0.0030, H + 0.0055), (RT + 0.0030, H - 0.0035), (RT + 0.0016, H - 0.0040)], seg=SEG, mat=lid, cap=False)
