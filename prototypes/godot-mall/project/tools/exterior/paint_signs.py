"""Paints the outside's sign faces and details into tex/ex/ (tools/exterior/monuments.gd,
tools/exterior/exterior.gd; design/godot-exterior.md, Workstream F, Nov 1 2026).

  mon_1995.png      the monument face, 1995: the mall's own fan logo as printed in its March 1994
                    "Merchant List & Map" (The Courier, Mar 20 1994): a half-round arch, a fan of
                    seven stepped wedges, SOUTHLAND with the big S and D, M A L L between rules.
                    Colours are a GUESS (the print is black and white): dark bronze on cream.
  mon_2026.png      the monument face, 2026: today's look (navy banner, white fan, as on the main
                    entrance tower, IMG_4406 f002). No monument face is legible in the footage:
                    a GUESS built from the mall's current banner.
  ua_head.png       the United Artists Southland Cinema roadside sign's header (era_1995/other/other_3.jpg,
                    summer 1997): UNITED ARTISTS + starburst + Theatres / SOUTHLAND CINEMA.
  ua_lines.png      its changeable-letter board: four tracks, invented house lines (no film titles:
                    the photo's 1997 films did not exist in 1995, and the IP rule).
  lace_frieze.png   Dillard's cast-iron lace frieze, 1 m x 0.5 m tile, alpha (refs/new/dillards_exterior
                    t056_021): a row of scrolled roundels between two bars.
  lace_bracket.png  the lace corner bracket at each column, 1 x 1 m, alpha (quarter-round scrollwork).
  firelane_pink.png the 2026 fire-lane ladder (4489 f001-f023, 4492 t104): two rails and rungs, alpha,
                    one tile = 2 m along x 1.2 m across.
  firelane_yellow.png the same ladder in yellow (the 1995 GUESS: today's pink is a recent repaint;
                    4487 still has yellow ladder hatching on the north side).
  ada_symbol.png    the wheelchair symbol, white on blue, alpha outside the square.
  tactile.png       the yellow truncated-dome mat (2026 only).
  acm_white.png     Shoe Dept.'s white aluminium-composite panels, 1.5 x 3 m joints (4492 f081-f099).
  eifs_panel.png    EIFS with scored panel reveals, 2.4 m board joints (the 2026 wing wall, 4489 f059).
  brick_painted.png painted brick relief, near white, tinted per band by the material (the rear
                    service lane's three bands, 4490 f006-f012).
Run: python3 tools/exterior/paint_signs.py
"""
import math
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "tex", "ex")
FONTS = os.path.join(HERE, "..", "..", "fonts")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(1994)


def font(name, size):
    return ImageFont.truetype(os.path.join(FONTS, name), size)


def save(name, im):
    im.save(os.path.join(OUT, name + ".png"))
    print("wrote", name, im.size)


def text_c(d, xy, s, f, fill, spacing=0):
    """Centred text at xy (centre), optional letter spacing in px."""
    if spacing == 0:
        w = d.textlength(s, font=f)
        d.text((xy[0] - w / 2, xy[1]), s, font=f, fill=fill, anchor="lm")
        return
    ws = [d.textlength(c, font=f) for c in s]
    tot = sum(ws) + spacing * (len(s) - 1)
    x = xy[0] - tot / 2
    for c, w in zip(s, ws):
        d.text((x, xy[1]), c, font=f, fill=fill, anchor="lm")
        x += w + spacing


def fan(d, cx, cy, r, fill, n=7, gap=0.22):
    """The fan: n stepped wedges converging to a point at (cx, cy + r * 0.05) below them, longest
    in the middle (the 1994 logo)."""
    tip = (cx, cy)
    for i in range(n):
        k = i - (n - 1) / 2
        a = math.radians(-90 + k * 15.0)
        half = math.radians(15.0 * (1 - gap) / 2)
        L = r * (1.0 - abs(k) * 0.11)
        p1 = (cx + math.cos(a - half) * L, cy + math.sin(a - half) * L)
        p2 = (cx + math.cos(a + half) * L, cy + math.sin(a + half) * L)
        # flat stepped tops: the wedge ends square, not on an arc
        d.polygon([tip, p1, p2], fill=fill)


def logo(d, W, H, ink, rule=True):
    """The 1994 fan logo, centred in a W x H face."""
    cx = W / 2
    # the half-round arch outline
    ar = H * 0.36
    ay = H * 0.50
    lw = max(4, int(H * 0.018))
    d.arc([cx - ar, ay - ar, cx + ar, ay + ar], 180, 360, fill=ink, width=lw)
    d.line([cx - ar, ay, cx + ar, ay], fill=ink, width=lw)
    d.line([cx - ar + lw / 2, ay - 2, cx - ar + lw / 2, ay - ar * 0.1], fill=ink, width=lw)
    # the fan, pointing down into the arch's base
    fan(d, cx, ay - ar * 0.12, ar * 0.72, ink)
    # SOUTHLAND with the big S and D, M A L L between rules
    big = font("sans.otf", int(H * 0.30))
    small = font("sans.otf", int(H * 0.15))
    mall = font("sans.otf", int(H * 0.085))
    sw = d.textlength("S", font=big)
    mid = "OUTHLAN"
    mw = d.textlength(mid, font=small)
    dw = d.textlength("D", font=big)
    tot = sw + mw + dw
    x0 = cx - tot / 2
    ty = ay + H * 0.17
    d.text((x0, ty + H * 0.06), "S", font=big, fill=ink, anchor="lm")
    d.text((x0 + sw, ty - H * 0.01), mid, font=small, fill=ink, anchor="lm")
    d.text((x0 + sw + mw, ty + H * 0.06), "D", font=big, fill=ink, anchor="lm")
    ry0 = ty + H * 0.065
    ry1 = ty + H * 0.185
    if rule:
        d.line([x0 + sw, ry0, x0 + sw + mw, ry0], fill=ink, width=max(2, lw // 2))
        d.line([x0 + sw, ry1, x0 + sw + mw, ry1], fill=ink, width=max(2, lw // 2))
    text_c(d, (x0 + sw + mw / 2, (ry0 + ry1) / 2), "MALL", mall, ink, spacing=int(mw * 0.16))


def stucco(W, H, base, amp=6):
    a = np.zeros((H, W, 3), np.float32) + np.array(base, np.float32)
    a += (rng.random((H, W, 1)) - 0.5) * amp
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


# ---------------------------------------------------------------- the monument faces (2:1)
W, H = 1024, 512
im = stucco(W, H, (238, 230, 212))
d = ImageDraw.Draw(im)
logo(d, W, H, (70, 54, 40))
save("mon_1995", im)

im = stucco(W, H, (29, 42, 74), amp=3)
d = ImageDraw.Draw(im)
logo(d, W, H, (244, 242, 236))
save("mon_2026", im)

# ---------------------------------------------------------------- United Artists Southland Cinema
W, H = 1024, 256
im = Image.new("RGB", (W, H), (246, 246, 242))
d = ImageDraw.Draw(im)
ua = font("sans_italic.otf", 78)
th = font("sans.otf", 54)
sc = font("sans.otf", 70)
x = 40
d.text((x, 70), "UNITED", font=ua, fill=(18, 18, 18), anchor="lm", stroke_width=2, stroke_fill=(18, 18, 18))
x += d.textlength("UNITED", font=ua) + 4
d.text((x, 70), "ARTISTS", font=ua, fill=(18, 18, 18), anchor="lm", stroke_width=2, stroke_fill=(18, 18, 18))
x += d.textlength("ARTISTS", font=ua) + 18
# the starburst
cx, cy = x + 34, 62
for i in range(16):
    a = math.radians(i * 22.5)
    L = 44 if i % 2 == 0 else 26
    d.polygon([(cx + math.cos(a) * L, cy + math.sin(a) * L), (cx + math.cos(a + 0.35) * 10, cy + math.sin(a + 0.35) * 10),
               (cx + math.cos(a - 0.35) * 10, cy + math.sin(a - 0.35) * 10)], fill=(18, 18, 18))
x = cx + 48
d.text((x, 74), "Theatres", font=th, fill=(18, 18, 18), anchor="lm")
text_c(d, (W / 2, 186), "SOUTHLAND CINEMA", sc, (18, 18, 18), spacing=6)
d.rectangle([0, 0, W - 1, H - 1], outline=(10, 10, 10), width=8)
save("ua_head", im)

W, H = 1024, 384
im = Image.new("RGB", (W, H), (240, 240, 236))
d = ImageDraw.Draw(im)
lf = font("sans.otf", 58)
lines = ["NOW SHOWING", "MATINEES DAILY", "", "WELCOME"]    # invented house lines, no titles
for i in range(4):
    y = 26 + i * 88
    for k in (0, 74):
        d.line([12, y + k, W - 12, y + k], fill=(150, 150, 146), width=3)
    if lines[i]:
        text_c(d, (W / 2, y + 38), lines[i], lf, (16, 16, 16), spacing=14)
d.rectangle([0, 0, W - 1, H - 1], outline=(10, 10, 10), width=8)
save("ua_lines", im)

# ---------------------------------------------------------------- Dillard's cast-iron lace
IRON = (40, 33, 28, 255)


def roundel(d, cx, cy, r, w):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=IRON, width=w)
    d.ellipse([cx - r * 0.42, cy - r * 0.42, cx + r * 0.42, cy + r * 0.42], outline=IRON, width=w)
    for k in range(4):
        a = math.radians(45 + k * 90)
        # C-scrolls inside the ring
        sx, sy = cx + math.cos(a) * r * 0.7, cy + math.sin(a) * r * 0.7
        d.arc([sx - r * 0.3, sy - r * 0.3, sx + r * 0.3, sy + r * 0.3], k * 90, k * 90 + 220, fill=IRON, width=w)


def scroll(d, cx, cy, r, start, w):
    """A spiral scroll from radius r inwards."""
    pts = []
    for i in range(60):
        t = i / 59.0
        a = math.radians(start + t * 540)
        rr = r * (1.0 - t * 0.8)
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    d.line(pts, fill=IRON, width=w)


# frieze: 1 m x 0.5 m -> 256 x 128
W, H = 256, 128
im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(im)
d.rectangle([0, 0, W, 9], fill=IRON)
d.rectangle([0, 56, W, 61], fill=IRON)
d.rectangle([0, H - 6, W, H], fill=IRON)
for i in range(4):
    roundel(d, 32 + i * 64, 33, 21, 3)
for i in range(4):
    cx = 32 + i * 64
    scroll(d, cx - 14, 92, 18, 180, 3)
    scroll(d, cx + 14, 92, 18, 0, 3)
    d.line([cx, 62, cx, H - 6], fill=IRON, width=3)
save("lace_frieze", im)

# bracket: 1 x 1 m -> 256 x 256, the column at the right edge, the beam at the top
W = H = 256
im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(im)
d.rectangle([0, 0, W, 8], fill=IRON)
d.rectangle([W - 9, 0, W, H], fill=IRON)
d.arc([-W + 18, 8 - H + 18 + 0, W - 9, H - 18], 0, 90, fill=IRON, width=7)
for r, st in ((70, 200), (52, 20), (40, 120)):
    pass
scroll(d, 150, 70, 48, 160, 5)
scroll(d, 196, 140, 38, 250, 5)
scroll(d, 92, 40, 30, 90, 4)
scroll(d, 220, 200, 26, 300, 4)
roundel(d, 205, 52, 26, 4)
save("lace_bracket", im)

# ---------------------------------------------------------------- lot paint
def ladder(name, col):
    W, H = 512, 307              # 2 m along x 1.2 m across
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    rw = 24
    d.rectangle([0, 0, W, rw], fill=col)
    d.rectangle([0, H - rw, W, H], fill=col)
    # the rungs lean (the "ladder" of 4489 / 4492): two per tile
    for x in (60, 316):
        d.polygon([(x, rw), (x + rw * 1.4, rw), (x + 110 + rw * 1.4, H - rw), (x + 110, H - rw)], fill=col)
    a = np.asarray(im).astype(np.float32)
    # worn paint
    wear = rng.random(a.shape[:2]) < 0.06
    a[..., 3][wear] *= 0.3
    save(name, Image.fromarray(a.astype(np.uint8), "RGBA"))


ladder("firelane_pink", (226, 72, 120, 255))
ladder("firelane_yellow", (226, 194, 50, 255))

W = H = 256
im = Image.new("RGBA", (W, H), (36, 92, 178, 255))
d = ImageDraw.Draw(im)
wh = (246, 246, 246, 255)
d.ellipse([112, 34, 140, 62], fill=wh)                       # head
d.line([(124, 70), (118, 140), (170, 140), (186, 196)], fill=wh, width=16)
d.line([(122, 100), (162, 100)], fill=wh, width=12)
d.arc([66, 112, 166, 212], 60, 300, fill=wh, width=14)       # the wheel
save("ada_symbol", im)

W = H = 128
a = np.zeros((H, W, 3), np.float32) + (222, 178, 40)
yy, xx = np.mgrid[:H, :W]
for cy in range(8, H, 16):
    for cx in range(8, W, 16):
        m = (yy - cy) ** 2 + (xx - cx) ** 2 < 20
        a[m] = (240, 202, 70)
        a[((yy - cy - 2) ** 2 + (xx - cx - 1) ** 2 < 20) & ~m] *= 0.8
save("tactile", Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)))

# ---------------------------------------------------------------- 2026 skins
# ACM panels, 1.5 m x 3 m per joint: one texture = 3 m x 3 m (2 x 1 panels)
W = H = 512
a = np.zeros((H, W, 3), np.float32) + (238, 238, 236)
a += (rng.random((H, W, 1)) - 0.5) * 2
for x in (0, W // 2):
    a[:, x:x + 3] = (170, 172, 172)
a[0:3, :] = (170, 172, 172)
save("acm_white", Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)))

# EIFS with board reveals every 2.4 m: one texture = 2.4 m x 2.4 m, neutral (tinted per use)
W = H = 512
a = np.zeros((H, W, 3), np.float32) + (236, 232, 226)
a += (rng.random((H, W, 1)) - 0.5) * 6
small = rng.random((16, 16))
a += ((np.asarray(Image.fromarray((small * 255).astype(np.uint8)).resize((W, H), Image.BILINEAR)) / 255.0 - 0.5) * 8)[..., None]
a[0:3, :] *= 0.82; a[:, 0:3] *= 0.82
save("eifs_panel", Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)))

# painted brick, near white, 2 m tile, standard units
px = 1024
pm = px / 2.0
a = np.zeros((px, px, 3), np.float32) + (214, 210, 204)
for r in range(int(2.0 / 0.0667)):
    y0 = int(r * 0.0667 * pm); y1 = int((r + 1) * 0.0667 * pm) - 4
    off = 0.1 * pm if r % 2 else 0
    for c in range(-1, 11):
        x0 = int(c * 0.2 * pm + off); x1 = int((c + 1) * 0.2 * pm + off) - 4
        xa, xb = max(0, x0), min(px, x1)
        if xb > xa:
            a[y0:y1, xa:xb] = 242 + rng.random() * 8
a += (rng.random((px, px, 1)) - 0.5) * 8
save("brick_painted", Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)))

# the navy vertical banner on today's main-entrance pier (IMG_4406 f002): the white fan
W, H = 256, 1024
im = stucco(W, H, (29, 42, 74), amp=3)
d = ImageDraw.Draw(im)
fan(d, W / 2, 330, 150, (244, 242, 236))
d.line([30, 380, W - 30, 380], fill=(244, 242, 236), width=6)
save("banner_2026", im)
