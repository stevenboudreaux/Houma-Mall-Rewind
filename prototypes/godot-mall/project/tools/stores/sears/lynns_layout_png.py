"""Draw Lynn's Interiors' floor plan (design/lynns/layout.png): the skeleton from store.gd (box, columns,
partitions, rooms, side exit, storefront), the zones (data/lynns/zones.json) and the Blender furniture
placed so far (data/lynns/placements.json), each piece as its rotated footprint.
Run from the project folder: python3 tools/stores/sears/lynns_layout_png.py ../../../design/lynns/layout.png"""
import json
import math
import sys
from PIL import Image, ImageDraw, ImageFont

X0, X1, ZF, ZB = -40.0, 30.0, -96.0, -146.0
COLS_X = [-35.5, -26.5, -17.5, -8.5, 0.5, 9.5, 18.5, 27.5]
COLS_Z = [-101.0, -110.0, -119.0, -128.0, -137.0]
PIPES = [[14.0, -133.0], [19.5, -133.0], [25.0, -133.0], [14.0, -140.0], [19.5, -140.0], [25.0, -140.0]]
PARTS = [[-40.0, -128.0, -17.5, -128.0, [[-31.0, -24.0]]], [-17.5, -146.0, -17.5, -128.0, [[-136.0, -131.0]]],
         [-26.5, -128.0, -26.5, -110.0, [[-122.0, -116.0]]], [-40.0, -110.0, -26.5, -110.0, []],
         [-17.5, -137.0, -8.5, -137.0, []], [-8.5, -146.0, -8.5, -137.0, [[-142.4, -140.6]]],
         [0.5, -146.0, 0.5, -137.0, []], [0.5, -137.0, 9.5, -137.0, []],
         [9.5, -146.0, 9.5, -128.0, [[-137.0, -131.0]]], [9.5, -128.0, 30.0, -128.0, [[13.0, 21.0]]]]
S = 16          # px per metre
M = 40          # margin
W = int((X1 - X0) * S) + 2 * M
H = int((ZF - ZB) * S) + 2 * M + 210


def P(x, z):
    # north (back, -z) at the top, south (the mall) at the bottom
    return (M + (x - X0) * S, M + (z - ZB) * S)


def main(out):
    Z = json.load(open("data/lynns/zones.json"))["zones"]
    D = json.load(open("data/lynns/placements.json"))
    im = Image.new("RGB", (W, H), (250, 249, 246))
    d = ImageDraw.Draw(im, "RGBA")
    try:
        f = ImageFont.truetype("fonts/sans.otf", 13)
        fb = ImageFont.truetype("fonts/sans.otf", 18)
    except Exception:
        f = fb = ImageFont.load_default()
    for z in Z:
        c = z["colour"].lstrip("#")
        rgb = tuple(int(c[i:i + 2], 16) for i in (0, 2, 4))
        for r in z["rects"]:
            d.rectangle([P(r[0], r[1]), P(r[2], r[3])], fill=rgb + (150,))
        r = z["rects"][0]
        d.text((P(r[0], r[1])[0] + 4, P(r[0], r[1])[1] + 3), z["id"], fill=(40, 40, 40), font=fb)
    # main aisle
    d.rectangle([P(-6, ZB), P(-2, ZF)], fill=(255, 255, 255, 200))
    d.text(P(-5.8, -122), "main\naisle", fill=(110, 110, 110), font=f)
    # walls
    d.rectangle([P(X0, ZB), P(X1, ZF)], outline=(30, 30, 30), width=3)
    for x0, z0, x1, z1, gaps in PARTS:
        segs = [(x0, z0, x1, z1)]
        for g in gaps:
            new = []
            for a, b, c, e in segs:
                if x0 == x1:
                    lo, hi = min(b, e), max(b, e)
                    new += [(a, lo, c, g[0]), (a, g[1], c, hi)]
                else:
                    lo, hi = min(a, c), max(a, c)
                    new += [(lo, b, g[0], e), (g[1], b, hi, e)]
            segs = new
        for a, b, c, e in segs:
            d.line([P(a, b), P(c, e)], fill=(30, 30, 30), width=3)
    d.text(P(1.0, -145.0), "R5 back of house\n(closed)", fill=(110, 110, 110), font=f)
    # mall mouth, side exit, storefront
    d.line([P(-16, ZF), P(8, ZF)], fill=(250, 249, 246), width=5)
    d.text(P(-10, -95.2), "mall mouth (C1 court)", fill=(60, 60, 60), font=f)
    d.line([P(-5.05, ZB), P(-2.95, ZB)], fill=(40, 120, 220), width=6)
    d.text(P(-7.5, -148.8), "side exit", fill=(40, 120, 220), font=f)
    d.line([P(X1, -121), P(X1, -115)], fill=(40, 120, 220), width=6)
    d.text((P(X1, -119)[0] + 3, P(X1, -119)[1]), "store-\nfront", fill=(40, 120, 220), font=f)
    for x in COLS_X:
        for z in COLS_Z:
            if 9.5 < x and z < -128:
                continue
            d.rectangle([P(x - 0.35, z - 0.35), P(x + 0.35, z + 0.35)], fill=(70, 70, 70))
    for x, z in PIPES:
        d.ellipse([P(x - 0.2, z - 0.2), P(x + 0.2, z + 0.2)], fill=(70, 70, 70))
    # placed pieces
    def poly(key, x, z, yaw):
        w, dd = D["models"][key]["size"]
        a = math.radians(yaw)
        fx, fz = math.sin(a), math.cos(a)   # front direction (+z at yaw 0) in plan
        rx, rz = math.cos(a), -math.sin(a)
        return [P(x + sx * rx * w / 2 + sz * fx * dd / 2, z + sx * rz * w / 2 + sz * fz * dd / 2) for sx, sz in ((-1, -1), (1, -1), (1, 1), (-1, 1))], fx, fz, dd

    def colour(key):
        if key.startswith(("bed", "night", "dresser", "chest")):
            return (90, 60, 40)          # generator bedroom suites
        if key.startswith("sofa"):
            return (70, 90, 110)         # generator sofas
        for pre, c in (("pk_mat", (40, 55, 110)), ("pk_bed", (120, 90, 60)), ("pk_recl", (110, 70, 50)), ("pk_t", (150, 120, 80)),
                       ("pk_chair", (170, 140, 100)), ("pk_stool", (170, 140, 100)), ("pk_side", (120, 120, 110)), ("pk_book", (120, 120, 110)),
                       ("pk_plant", (60, 120, 60)), ("pk_fridge", (150, 160, 170)), ("pk_range", (150, 160, 170)), ("pk_washer", (150, 160, 170)),
                       ("pk_dryer", (150, 160, 170))):
            if key.startswith(pre):
                return c
        return (120, 135, 150)           # other pack upholstery and tables

    for g in D["groups"]:          # rugs first, under everything
        if "rug" in g:
            r = g["rug"]
            c = r[4].lstrip("#")
            d.rectangle([P(r[0], r[1]), P(r[2], r[3])], fill=tuple(int(c[i:i + 2], 16) for i in (0, 2, 4)) + (200,))
        for it in g["items"]:
            if D["models"][it[0]].get("walk"):
                d.polygon(poly(it[0], it[1], it[2], it[3])[0], fill=(185, 175, 155, 170), outline=(150, 140, 120))
    for g in D["groups"]:
        for it in g["items"]:
            key, x, z, yaw = it[:4]
            if D["models"][key].get("walk") or len(it) > 4:
                continue
            pts, fx, fz, dd = poly(key, x, z, yaw)
            d.polygon(pts, fill=colour(key) + (230,), outline=(20, 20, 20))
            # a tick on the front edge
            d.line([P(x + fx * dd / 2 * 0.6, z + fz * dd / 2 * 0.6), P(x + fx * dd / 2, z + fz * dd / 2)], fill=(255, 255, 255), width=2)
    # scale, north, legend
    y0 = H - 200
    d.line([(M, y0), (M + 9 * S, y0)], fill=(0, 0, 0), width=3)
    d.text((M, y0 + 6), "9 m (one column bay)", fill=(0, 0, 0), font=f)
    d.text((W - 160, M - 30), "N (back) ↑   mall ↓ S", fill=(0, 0, 0), font=f)
    d.text((M, 8), "Lynn's Interiors 2026: zones and furniture, phase 1 + pass 2 (design/lynns/layout.md)", fill=(0, 0, 0), font=fb)
    yy = y0 + 30
    for i, z in enumerate(Z):
        c = z["colour"].lstrip("#")
        rgb = tuple(int(c[k:k + 2], 16) for k in (0, 2, 4))
        cx = M + (i % 2) * (W // 2)
        cy = yy + (i // 2) * 24
        d.rectangle([cx, cy, cx + 16, cy + 16], fill=rgb)
        d.text((cx + 22, cy), z["id"] + "  " + z["what"], fill=(20, 20, 20), font=f)
    d.text((M, H - 22), "brown = generator suites, steel blue = generator sofas, other colours = pack pieces, beige = rugs (white tick = the front); grey squares = columns",
           fill=(60, 60, 60), font=f)
    im.save(out)
    print("wrote", out, im.size)


if __name__ == "__main__":
    main(sys.argv[1])
