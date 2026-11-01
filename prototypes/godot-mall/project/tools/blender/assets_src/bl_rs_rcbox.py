"""A boxed radio-controlled monster truck (RadioShack, 1995 map). Hand item (carried in both arms).

Reference: refs/new/radioshack_1999/ 0:15-0:35, 1:05-1:20, 2:20-2:45 (the shop's R/C truck boxes: big
cartons with a yellow truck, flames and a bold italic name on a purple-blue field). Everything printed is
invented, following design/storefronts/radio-shack.md ("purple-blue with yellow flames, invented") and
tools/stores/small/paint_rs.py: the name "TURBO DUNE", the truck drawing, the badges. No real product,
logo or the store's own mark on the box.
Origin: bottom centre, front (the big picture) facing Godot +Z.
"""
import math
from lib import core, parts, mats, labels
from PIL import Image, ImageDraw, ImageFilter

W, D, H = 0.460, 0.240, 0.220
PX = 2000 / W                      # artwork pixels per metre

META = {
    "id": "bl_rs_rcbox",
    "class": "hand",
    "tex": 2048,
    "ao": 0.25,
    "refs": [
        ["refs/new/radioshack_1999/christmas-shopping-at-radioshack-in-1999_t000_021.jpg", [0.0, 0.3, 0.5, 1.0], "RS 1999 0:20 (an R/C box)"],
        ["refs/new/radioshack_1999/christmas-shopping-at-radioshack-in-1999_t000_061.jpg", [0.3, 0.25, 0.85, 1.0], "RS 1999 1:00"],
    ],
    "item": {"name": "R/C monster truck (boxed)", "year": 1995, "store": "RADIO SHACK"},
}

YEL = (255, 214, 30, 255)
RED = (214, 40, 30, 255)


def gradient(w, h, top=(70, 28, 130), bottom=(30, 70, 190)):
    im = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(im)
    for y in range(h):
        t = y / max(1, h - 1)
        d.line([(0, y), (w, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(top, bottom)) + (255,))
    return im


def flames(im, y0, scale=1.0):
    d = ImageDraw.Draw(im)
    w, h = im.size
    for layer, col in ((0, (255, 214, 30, 255)), (1, (255, 130, 20, 255)), (2, (200, 30, 20, 255))):
        pts = [(0, h)]
        x = 0
        k = 0
        while x < w:
            tall = (180 - layer * 55) * scale * (0.7 + 0.3 * math.sin(k * 1.7))
            pts += [(x + 40 * scale, y0 - tall), (x + 60 * scale, y0 - tall * 0.35)]
            x += 70 * scale
            k += 1
        pts += [(w, h)]
        d.polygon(pts, fill=col)


def truck(d, cx, cy, s):
    """An invented monster truck, side-on: a yellow pickup lifted high on huge black tyres."""
    for wx in (-1.0, 1.0):
        x = cx + wx * 200 * s
        d.ellipse((x - 135 * s, cy - 20 * s, x + 135 * s, cy + 250 * s), fill=(18, 18, 20, 255))
        for k in range(14):   # tread blocks
            import math as _m
            a = k / 14 * _m.tau
            px, py = x + 128 * s * _m.cos(a), cy + 115 * s + 128 * s * _m.sin(a)
            d.ellipse((px - 14 * s, py - 14 * s, px + 14 * s, py + 14 * s), fill=(40, 40, 44, 255))
        d.ellipse((x - 60 * s, cy + 55 * s, x + 60 * s, cy + 175 * s), fill=(200, 200, 205, 255))
        d.ellipse((x - 22 * s, cy + 93 * s, x + 22 * s, cy + 137 * s), fill=(90, 90, 95, 255))
    # lift: shocks and frame under the body
    d.rectangle((cx - 260 * s, cy - 40 * s, cx + 260 * s, cy - 20 * s), fill=(30, 30, 30, 255))
    for x in (cx - 200 * s, cx + 200 * s):
        d.rectangle((x - 10 * s, cy - 40 * s, x + 10 * s, cy + 100 * s), fill=(220, 40, 30, 255))
    by = cy - 35 * s    # body bottom, sitting on the lifted frame
    d.polygon([(cx - 330 * s, by + 20 * s), (cx + 330 * s, by + 20 * s), (cx + 345 * s, by - 50 * s), (cx + 140 * s, by - 65 * s),
               (cx + 90 * s, by - 165 * s), (cx - 60 * s, by - 165 * s), (cx - 70 * s, by - 65 * s), (cx - 340 * s, by - 60 * s)], fill=YEL)
    d.polygon([(cx + 75 * s, by - 150 * s), (cx - 45 * s, by - 150 * s), (cx - 52 * s, by - 75 * s), (cx + 120 * s, by - 75 * s)], fill=(70, 140, 220, 255))
    d.rectangle((cx - 330 * s, by - 20 * s, cx + 340 * s, by), fill=RED)
    d.polygon([(cx - 300 * s, by - 55 * s), (cx - 120 * s, by - 58 * s), (cx - 160 * s, by - 25 * s), (cx - 300 * s, by - 25 * s)], fill=(255, 140, 20, 255))
    d.rectangle((cx + 320 * s, by - 45 * s, cx + 350 * s, by - 28 * s), fill=(255, 255, 230, 255))
    d.rectangle((cx - 10 * s, by - 205 * s, cx + 80 * s, by - 170 * s), fill=(30, 30, 30, 255))   # roof light bar
    for k in range(4):
        d.ellipse((cx + k * 22 * s - 6 * s, by - 200 * s, cx + k * 22 * s + 12 * s, by - 176 * s), fill=(255, 250, 200, 255))


def name(d, xy, px, anchor="mm"):
    for dx, dy in ((-6, -6), (6, -6), (-6, 6), (6, 6), (0, 9)):
        labels.text(d, (xy[0] + dx, xy[1] + dy), "TURBO DUNE", "bold", px, RED, anchor)
    labels.text(d, xy, "TURBO DUNE", "bold", px, YEL, anchor)


def badge(d, xy, txt, px=44, fill=(255, 255, 255, 255), bg=RED):
    f = labels.font("bold", px)
    x0, y0, x1, y1 = d.textbbox(xy, txt, font=f, anchor="mm")
    d.rounded_rectangle((x0 - 18, y0 - 12, x1 + 18, y1 + 12), 14, fill=bg)
    d.text(xy, txt, font=f, fill=fill, anchor="mm")


def art():
    fw, fh = int(W * PX), int(H * PX)
    front = gradient(fw, fh)
    flames(front, int(fh * 0.80), 1.4)
    d = ImageDraw.Draw(front)
    truck(d, fw * 0.60, fh * 0.50, 0.95)
    name(d, (fw * 0.36, fh * 0.14), 170)
    badge(d, (fw * 0.16, fh * 0.92), "RADIO CONTROLLED", 50)
    badge(d, (fw * 0.84, fh * 0.12), "27 MHz", 64, (20, 20, 20, 255), YEL)
    badge(d, (fw * 0.86, fh * 0.92), "FULL FUNCTION", 46)
    labels.text(d, (fw * 0.45, fh * 0.92), "1:10 SCALE  •  AGES 8 & UP", "bold", 44, (255, 255, 255, 255))
    fp = labels.save(front, "rs_rcbox_front")
    back = gradient(fw, fh, (30, 70, 190), (70, 28, 130))
    d = ImageDraw.Draw(back)
    name(d, (fw * 0.5, fh * 0.13), 150)
    for i, line in enumerate(["• FORWARD / REVERSE / LEFT / RIGHT", "• GIANT 5\" TIRES", "• TURBO SPEED SWITCH",
                              "• REQUIRES 6 \"AA\" + 1 9V BATTERY", "   (BATTERIES NOT INCLUDED)"]):
        labels.text(d, (fw * 0.08, fh * (0.32 + i * 0.11)), line, "bold", 64, (255, 255, 255, 255), "lm")
    truck(d, fw * 0.80, fh * 0.55, 0.55)
    d.rectangle((fw * 0.70, fh * 0.80, fw * 0.92, fh * 0.94), fill=(255, 255, 255, 255))
    for i in range(30):   # bar code
        x = fw * 0.71 + i * fw * 0.0068
        d.rectangle((x, fh * 0.81, x + (fw * 0.003 if i % 3 else fw * 0.005), fh * 0.91), fill=(0, 0, 0, 255))
    bp = labels.save(back, "rs_rcbox_back")
    sw, sh = int(D * PX), int(H * PX)
    side = gradient(sw, sh)
    flames(side, int(sh * 0.85), 0.9)
    d = ImageDraw.Draw(side)
    labels.text(d, (sw * 0.5, sh * 0.25), "TURBO", "bold", 160, YEL)
    labels.text(d, (sw * 0.5, sh * 0.47), "DUNE", "bold", 160, YEL)
    badge(d, (sw * 0.5, sh * 0.68), "R/C 4x4", 60, (20, 20, 20, 255), YEL)
    sp = labels.save(side, "rs_rcbox_side")
    tw, th = int(W * PX), int(D * PX)
    top = gradient(tw, th, (60, 30, 140), (60, 30, 140))
    d = ImageDraw.Draw(top)
    name(d, (tw * 0.5, th * 0.5), 200)
    tp = labels.save(top, "rs_rcbox_top")
    return fp, bp, sp, tp


def build():
    fp, bp, sp, tp = art()
    m = mats.M("carton", "#3a2c8a", 0.6)
    c = mats.decal(m, fp, (0, -D / 2, H / 2), (W, H), "XZ", facing="-Y")
    c = mats.decal(m, bp, (0, D / 2, H / 2), (W, H), "XZ", base=c, flip_u=True, facing="+Y")
    c = mats.decal(m, sp, (W / 2, 0, H / 2), (D, H), "YZ", base=c, facing="+X")
    c = mats.decal(m, sp, (-W / 2, 0, H / 2), (D, H), "YZ", base=c, flip_u=True, facing="-X")
    c = mats.decal(m, tp, (0, 0, H), (W, D), "XY", base=c, facing="+Z")
    # cardboard: faint flute texture in the bump, gloss print
    n = m.noise(400.0, 2.0)
    m.bump(n.outputs["Fac"], 0.04, 0.0005)
    parts.box("carton", (W, D, H), loc=(0, 0, H / 2), mat=m.mat, bev=0.0025, seg=2)
    # the lid's tuck flap seam on the top, and a tape strip
    parts.box("tape", (0.05, D + 0.002, 0.0006), loc=(0, 0, H + 0.0003), mat=mats.flat("tape", "#d8d2c0", 0.3), bev=0)
