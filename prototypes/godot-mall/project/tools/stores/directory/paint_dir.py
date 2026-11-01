#!/usr/bin/env python3
"""Paint the mall directory kiosks' lit panels (design/godot-directory.md).

Reads tools/stores/directory/map.json (written by make_data.gd from the layout files, so the
panel map always matches the build) and writes:
  tex/dir/panel_2026.png  the real 2026 directory's look (IMG_4455, Oct 23 2026): cyan bands,
                          "Welcome!", STORES BY CATEGORY, the colour site map, MALL DIRECTORY.
                          The real panel's stock photo of a woman is NOT copied: a soft cyan
                          bokeh stands in its place.
  tex/dir/panel_1995.png  the same layout "less modern" (Steven, Nov 1): the mall's own March
                          1994 Merchant List & Map (The Courier, Mar 20 1994 p.99): the SOUTHLAND
                          MALL fan logo, numbered stores in category boxes, special locations A-G.
  tex/dir/back.png        the plain cream back (IMG_4484 f068) with a faint powder-coat grain.
Run from the project root: python3 tools/stores/directory/paint_dir.py
"""
import json, math, os, random
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
OUT = os.path.join(PROJ, "tex", "dir")
FONTS = os.path.join(PROJ, "tools", "stores", "signs", "y26", "src", "fonts")
# the lit art is 1.02 m x 1.14 m (kiosk.gd ART_W / ART_H)
W, H = 1024, 1145
SS = 2   # supersample


def font(name, size):
    paths = {
        "inter": ["/usr/share/fonts/opentype/inter/Inter-Regular.otf", os.path.join(PROJ, "fonts", "sans.otf")],
        "inter_b": ["/usr/share/fonts/opentype/inter/Inter-SemiBold.otf", os.path.join(PROJ, "fonts", "sans.otf")],
        "display": [os.path.join(PROJ, "fonts", "sans.otf")],
        "oswald": [os.path.join(FONTS, "Oswald-Bold.ttf")],
        "oswald_l": [os.path.join(FONTS, "Oswald-Light.ttf")],
        "serif": [os.path.join(PROJ, "fonts", "serif.ttf")],
        "cinzel": [os.path.join(FONTS, "Cinzel-Bold.ttf")],
        "script": [os.path.join(FONTS, "GreatVibes-Regular.ttf")],
    }[name]
    for p in paths:
        if os.path.exists(p):
            return ImageFont.truetype(p, int(size * SS))
    return ImageFont.load_default()


def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def map_fit(year, box, pad=0.0, crop=None):
    """World (x, z) -> panel pixels inside box (x0, y0, x1, y1); north (-z) up."""
    b = crop or year["bounds"]
    bw, bh = b[2] - b[0], b[3] - b[1]
    x0, y0, x1, y1 = box
    s = min((x1 - x0 - 2 * pad) / bw, (y1 - y0 - 2 * pad) / bh)
    ox = x0 + ((x1 - x0) - bw * s) / 2
    oy = y0 + ((y1 - y0) - bh * s) / 2
    return lambda x, z: (ox + (x - b[0]) * s, oy + (z - b[1]) * s), s


def draw_map(d, year, box, style):
    cats = {c[0]: c for c in year["cats"]}
    P, s = map_fit(year, box, 6 * SS)
    hall_col = hexc("#c9ccd1") if style == 2026 else hexc("#e2dccd")
    for r in year["halls"]:
        a, b = P(r[0], r[1]), P(r[2], r[3])
        d.rectangle([a[0], a[1], b[0], b[1]], fill=hall_col)
    edge = hexc("#ffffff") if style == 2026 else hexc("#3b3a36")
    fnum = font("inter_b", 9.5)
    fbig = font("display" if style == 2026 else "serif", 15)
    for st in year["stalls"]:
        anchor = st["cats"][0] == "dept"
        if st["vacant"]:
            col = hexc("#e9ebee") if style == 2026 else hexc("#f6f2e8")
        elif anchor:
            col = hexc("#232325") if style == 2026 else hexc("#6b6f7a")
        else:
            col = hexc(cats.get(st["cats"][0], ["", "", "#999999"])[2])
        for r in st["rects"]:
            a, b = P(r[0], r[1]), P(r[2], r[3])
            d.rectangle([a[0], a[1], b[0], b[1]], fill=col)
        for r in st["rects"]:
            a, b = P(r[0], r[1]), P(r[2], r[3])
            d.rectangle([a[0], a[1], b[0], b[1]], outline=edge, width=max(1, int(0.8 * SS)))
        lx, ly = P(*st["label"])
        if anchor:
            anchor_label(d, st, P, style)
        elif style == 1995 and st["num"]:
            d.text((lx, ly), str(st["num"]), font=fnum, fill=hexc("#ffffff"), anchor="mm",
                   stroke_width=max(1, SS // 2), stroke_fill=hexc("#2a2a2a"))
    if style == 1995:
        fl = font("inter_b", 10)
        for p in year["places"]:
            x, y = P(p[2], p[3])
            rr = 7 * SS
            d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=hexc("#1f5c66"), outline=hexc("#ffffff"), width=SS)
            d.text((x, y), p[0], font=fl, fill=hexc("#ffffff"), anchor="mm")
    else:
        # the 2026 map's mall entrances (black triangles) and restrooms (grey disc)
        for st in year["stalls"]:
            pass
    return P, s


def anchor_label(d, st, P, style):
    """An anchor's name fitted inside its biggest block; turned on its side when the block is tall
    and narrow (Dillard's)."""
    best = max(st["rects"], key=lambda r: (r[2] - r[0]) * (r[3] - r[1]))
    a, b = P(best[0], best[1]), P(best[2], best[3])
    bw, bh = b[0] - a[0], b[1] - a[1]
    fname = "display" if style == 2026 else "serif"
    side = bh > bw * 1.6
    room = (bh if side else bw) * 0.86
    size = 15.0
    while size > 6 and font(fname, size).getlength(st["name"]) > room:
        size -= 0.5
    f = font(fname, size)
    if not side:
        d.text(((a[0] + b[0]) / 2, (a[1] + b[1]) / 2), st["name"], font=f, fill=hexc("#ffffff"), anchor="mm")
        return
    tw = int(f.getlength(st["name"])) + 8
    th = int(size * SS * 1.6)
    im = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
    ImageDraw.Draw(im).text((tw / 2, th / 2), st["name"], font=f, fill=hexc("#ffffff"), anchor="mm")
    im = im.rotate(90, expand=True)
    d._image.paste(im, (int((a[0] + b[0]) / 2 - im.width / 2), int((a[1] + b[1]) / 2 - im.height / 2)), im)


def bokeh(img, box, base):
    """A soft cyan photo stand-in (circles of light), in place of the real panel's stock portrait."""
    x0, y0, x1, y1 = box
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    dl = ImageDraw.Draw(layer)
    rnd = random.Random(2026)
    for i in range(38):
        cx = rnd.uniform(x0, x1)
        cy = rnd.uniform(y0, y1)
        r = rnd.uniform(10, 46) * SS
        a = rnd.randint(30, 90)
        c = rnd.choice([(255, 255, 255), (200, 240, 255), (255, 230, 210)])
        dl.ellipse([cx - r, cy - r, cx + r, cy + r], fill=c + (a,))
    layer = layer.filter(ImageFilter.GaussianBlur(9 * SS))
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rectangle(box, fill=255)
    img.paste(layer, (0, 0), Image.composite(layer.split()[3], mask, mask))


def cat_list(d, year, x, y, col_w, y_max, style, cols):
    """The categories with their stores, flowing down columns (x, col_w, y_max)."""
    cats = year["cats"]
    by = {c[0]: [] for c in cats}
    for st in year["stalls"]:
        if st["vacant"]:
            continue
        for c in st["cats"]:
            if c in by:
                by[c].append(st)
    head = font("oswald", 10.5) if style == 2026 else font("inter_b", 9.5)
    item = font("inter", 9.2) if style == 2026 else font("inter", 9.0)
    lh = 12.4 * SS
    cx, cy = x, y
    ci = 0
    for c in cats:
        items = by.get(c[0], [])
        if not items:
            continue
        items.sort(key=lambda s: (s["num"] if style == 1995 else 0, s["name"].lower()))
        need = lh * (len(items) + 1.6)
        if cy + need > y_max and ci < cols - 1:
            ci += 1
            cx = x + ci * col_w
            cy = y
        if style == 2026:
            d.text((cx, cy), c[1].upper(), font=head, fill=hexc("#222222"), anchor="lt")
            cy += lh * 1.1
            for st in items:
                r = 3.0 * SS
                d.ellipse([cx + 2 * SS, cy + 4 * SS - r + 2, cx + 2 * SS + 2 * r, cy + 4 * SS + r + 2], fill=hexc(c[2]))
                d.text((cx + 12 * SS, cy), st["name"], font=item, fill=hexc("#333333"), anchor="lt")
                cy += lh
            cy += lh * 0.45
        else:
            # the 1994 page's boxes: a grey header bar with white letters, then "NN - Name"
            bw = col_w - 14 * SS
            d.rectangle([cx, cy, cx + bw, cy + lh * 1.15], fill=hexc(c[2]))
            d.text((cx + bw / 2, cy + lh * 0.58), c[1], font=head, fill=hexc("#ffffff"), anchor="mm")
            cy += lh * 1.35
            for st in items:
                d.text((cx + 22 * SS, cy), str(st["num"]), font=item, fill=hexc("#2b2b2b"), anchor="rt")
                d.text((cx + 27 * SS, cy), "- " + st["name"], font=item, fill=hexc("#2b2b2b"), anchor="lt")
                cy += lh
            cy += lh * 0.5


def fan_logo(d, cx, cy, s, col):
    """The SOUTHLAND MALL fan logo (1994 Merchant List & Map): a half-round arch outline with a
    stepped fan in it, SOUTHLAND across the base with the big S and D, M A L L spaced below."""
    r = 40 * s
    w = max(2, int(3 * s))
    d.arc([cx - r, cy - r, cx + r, cy + r], 180, 360, fill=col, width=w)
    d.line([cx - r, cy, cx - r, cy + 6 * s], fill=col, width=w)
    d.line([cx + r, cy, cx + r, cy + 6 * s], fill=col, width=w)
    # the fan: seven tapering blades from a point under the middle
    for i in range(7):
        a = math.radians(-90 + (i - 3) * 17)
        L = (30 if i in (2, 3, 4) else 24) * s
        bx, by = cx + math.cos(a) * L, cy - 4 * s + math.sin(a) * L
        n = (math.cos(a + math.pi / 2) * 3.2 * s, math.sin(a + math.pi / 2) * 3.2 * s)
        base = (cx, cy + 2 * s)
        d.polygon([base, (bx + n[0], by + n[1]), (bx - n[0], by - n[1])], fill=col)
    fs = font("display", 15 * s / SS)
    fb = font("display", 24 * s / SS)
    d.text((cx - r - 6 * s, cy + 18 * s), "S", font=fb, fill=col, anchor="mm")
    d.text((cx, cy + 12 * s), "OUTHLAN", font=fs, fill=col, anchor="mm")
    d.text((cx + r + 6 * s, cy + 18 * s), "D", font=fb, fill=col, anchor="mm")
    fm = font("inter", 9 * s / SS)
    d.text((cx, cy + 26 * s), "M    A    L    L", font=fm, fill=col, anchor="mm")


def panel_2026(data):
    y = data["years"]["2026"]
    img = Image.new("RGBA", (W * SS, H * SS), hexc("#f4f7f9"))
    d = ImageDraw.Draw(img)
    cyan, cyan2 = hexc("#2fb3dc"), hexc("#1d9cc8")
    top = int(H * 0.17) * SS
    # top band: a cyan gradient, the photo stand-in at left, "Welcome!" and the mall's handles
    for i in range(top):
        t = i / top
        d.line([(0, i), (W * SS, i)], fill=tuple(int(cyan[k] * (1 - t) + cyan2[k] * t) for k in range(3)) + (255,))
    bokeh(img, (0, 0, int(W * 0.30) * SS, top), cyan)
    d = ImageDraw.Draw(img)
    d.text((W * 0.30 * SS, top * 0.52), "Welcome!", font=font("display", 76), fill=hexc("#ffffff"), anchor="lm")
    fi = font("inter", 11)
    for k, t in enumerate(["southlandmallonline.com", "southlandmallinhouma", "slmhouma"]):
        yy = top * 0.30 + k * 22 * SS
        d.ellipse([W * 0.76 * SS, yy - 6 * SS, W * 0.76 * SS + 12 * SS, yy + 6 * SS], outline=hexc("#ffffff"), width=SS)
        d.text((W * 0.79 * SS, yy), t, font=fi, fill=hexc("#ffffff"), anchor="lm")
    # bottom band
    bot = int(H * 0.86) * SS
    for i in range(bot, H * SS):
        t = (i - bot) / (H * SS - bot)
        d.line([(0, i), (W * SS, i)], fill=tuple(int(cyan[k] * (1 - t) + cyan2[k] * t) for k in range(3)) + (255,))
    d.text((W * SS / 2, (bot + H * SS) / 2), "MALL DIRECTORY", font=font("inter", 52), fill=hexc("#ffffff"), anchor="mm")
    # the body
    d.text((44 * SS, top + 26 * SS), "STORES BY CATEGORY", font=font("oswald", 30), fill=hexc("#262626"), anchor="lt")
    d.text((W * 0.95 * SS, top + 34 * SS), "SECURITY 985.228.4563", font=font("oswald_l", 17), fill=hexc("#262626"), anchor="rt")
    cat_list(d, y, 44 * SS, top + 82 * SS, 150 * SS, bot - 16 * SS, 2026, 2)
    # the legend column, then the map
    fl = font("inter_b", 7.5)
    d.text((352 * SS, top + 84 * SS), "LEGEND", font=font("oswald", 9), fill=hexc("#333333"), anchor="lt")
    for k, t in enumerate(["MALL RESTROOMS", "TRANSIT STOP", "HANDICAP ENTRANCE", "ELEVATOR", "BANK ATM",
                           "PHOTO BOOTH", "ICE CREAM VENDING", "DRINK VENDING", "AMUSEMENT RIDES", "MALL ENTRANCE",
                           "SIT DOWN FOOD SERVICE", "COFFEE SERVICE", "BAR"]):
        yy = top + (104 + k * 17) * SS
        d.rectangle([352 * SS, yy, 362 * SS, yy + 10 * SS], fill=hexc("#555555"))
        d.text((370 * SS, yy + 5 * SS), t, font=fl, fill=hexc("#444444"), anchor="lm")
    P, s = draw_map(d, y, (430 * SS, top + 70 * SS, (W - 30) * SS, bot - 20 * SS), 2026)
    fr = font("inter_b", 8)
    d.text(((W - 40) * SS, top + 66 * SS), "ARMOUR DRIVE", font=fr, fill=hexc("#555555"), anchor="rt")
    d.text(((W - 40) * SS, bot - 24 * SS), "BAYOU GARDENS BOULEVARD", font=fr, fill=hexc("#555555"), anchor="rb")
    return img.resize((W, H), Image.LANCZOS)


def panel_1995(data):
    y = data["years"]["1995"]
    paper = hexc("#f5f1e6")
    img = Image.new("RGBA", (W * SS, H * SS), paper)
    d = ImageDraw.Draw(img)
    teal, mauve = hexc("#1f5c66"), hexc("#b0607e")
    top = int(H * 0.17) * SS
    d.rectangle([0, 0, W * SS, top], fill=teal)
    d.rectangle([0, top - 6 * SS, W * SS, top], fill=mauve)
    fan_logo(d, 150 * SS, top * 0.50, 1.55 * SS, hexc("#f5f1e6"))
    d.text((W * 0.62 * SS, top * 0.42), "Merchant List & Map", font=font("serif", 46), fill=hexc("#ffffff"), anchor="mm")
    d.text((W * 0.62 * SS, top * 0.74), "Welcome to Southland Mall  •  Houma, Louisiana", font=font("inter", 15),
           fill=hexc("#e6dccb"), anchor="mm")
    bot = int(H * 0.86) * SS
    d.rectangle([0, bot, W * SS, H * SS], fill=teal)
    d.rectangle([0, bot, W * SS, bot + 6 * SS], fill=mauve)
    d.text((W * SS / 2, (bot + H * SS) / 2 + 3 * SS), "MALL  DIRECTORY", font=font("cinzel", 46), fill=hexc("#ffffff"), anchor="mm")
    # the 1994 page's three columns of category boxes, then the floor plan
    cat_list(d, y, 26 * SS, top + 22 * SS, 168 * SS, bot - 14 * SS, 1995, 2)
    mx0 = 370 * SS
    P, s = draw_map(d, y, (mx0, top + 30 * SS, (W - 24) * SS, bot - 150 * SS), 1995)
    # the "Special Mall Locations" key under the map, as on the 1994 page
    kx, ky = mx0 + 10 * SS, bot - 140 * SS
    d.rectangle([kx, ky, kx + 168 * SS, ky + 22 * SS], fill=teal)
    d.text((kx + 84 * SS, ky + 11 * SS), "SPECIAL MALL LOCATIONS", font=font("inter_b", 9.5), fill=hexc("#ffffff"), anchor="mm")
    fl = font("inter_b", 9.5)
    for k, p in enumerate(y["places"]):
        col = k // 4
        row = k % 4
        xx = kx + col * 220 * SS
        yy = ky + (34 + row * 22) * SS
        d.ellipse([xx, yy - 8 * SS, xx + 16 * SS, yy + 8 * SS], fill=teal)
        d.text((xx + 8 * SS, yy), p[0], font=fl, fill=hexc("#ffffff"), anchor="mm")
        d.text((xx + 24 * SS, yy), p[1], font=font("inter", 10), fill=hexc("#2b2b2b"), anchor="lm")
    d.text(((W - 30) * SS, top + 24 * SS), "N ↑", font=font("serif", 14), fill=hexc("#3b3a36"), anchor="rt")
    return img.resize((W, H), Image.LANCZOS)


def back():
    rnd = random.Random(7)
    img = Image.new("RGB", (256, 256), (226, 219, 201))
    px = img.load()
    for yy in range(256):
        for xx in range(256):
            v = rnd.randint(-5, 5)
            c = px[xx, yy]
            px[xx, yy] = (c[0] + v, c[1] + v, c[2] + v)
    return img.filter(ImageFilter.GaussianBlur(0.6))


def main():
    data = json.load(open(os.path.join(HERE, "map.json")))
    os.makedirs(OUT, exist_ok=True)
    panel_2026(data).convert("RGB").save(os.path.join(OUT, "panel_2026.png"))
    panel_1995(data).convert("RGB").save(os.path.join(OUT, "panel_1995.png"))
    back().save(os.path.join(OUT, "back.png"))
    print("wrote", OUT)


if __name__ == "__main__":
    main()
