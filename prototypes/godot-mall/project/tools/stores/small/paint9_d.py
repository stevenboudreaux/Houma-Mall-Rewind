"""Textures for the Nov 1, 2026 pass on the Wave 9 shops (workstream D; tools/stores/small/wave9.gd),
written to tex/w9/*.png:

- concepts_siding.png: Concepts' cream lap siding (the game's flat front), 1 m square.
- concepts_sign_serif.png: the sign box, CONCEPTS in heavy serif capitals as in the store's own
  1990s Courier ad (refs/era_1995/ads/ad_6.jpg), cream on plum. Liberation Serif Bold stands in.
- concepts_bags.png: the back wall of school bags (the ad: "mesh bags as mandated by Lafourche
  Parish Schools; clear book bags also available"): mesh backpacks and clear bags on pegs,
  plain, no brand or logo. 4 m x 1 m.
- concepts_floor.png: a cream and grey vinyl tile with a plum feature row, 1.22 m repeat.
- concepts_spatter.png: spatter-paint flecks for the window solids (Steven: "the shapes are
  right; texture them more"; the finish is a guess, a period kids'-store look).

Everything is invented apart from the store's own name.
  python3 tools/stores/small/paint9_d.py   (from the project folder)
"""
import os, random, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "kay_bee"))
import paint_store as kb   # noqa: E402

OUT = os.path.join(HERE, "..", "..", "..", "tex", "w9")
os.makedirs(OUT, exist_ok=True)
SERIF_B = "/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf"
SS = 2


def save(im, name, colors=0):
    im = im.convert("RGB")
    if colors:
        im = im.quantize(colors, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    im.save(os.path.join(OUT, name + ".png"), optimize=True)


def siding():
    N = 512
    a = np.zeros((N, N, 3), np.float32)
    course = N // 7          # ~0.143 m courses
    for j in range(7):
        y0 = j * course
        for y in range(course):
            # each board is lit at the top, a shadow line under the lap above
            t = y / course
            v = 236 - 10 * t
            if y < 4:
                v = 168 + y * 14
            a[y0 + y, :] = (v, v * 0.955, v * 0.86)
    a += kb.noise(N, N, 3, 931, blur=1)[..., None]
    save(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)), "concepts_siding", 64)


def sign_serif():
    W, H = 1024 * SS, 192 * SS
    im = Image.new("RGB", (W, H), (58, 24, 40))
    d = ImageDraw.Draw(im)
    d.rectangle([10 * SS, 10 * SS, W - 10 * SS, H - 10 * SS], outline=(244, 232, 200), width=3 * SS)
    f = ImageFont.truetype(SERIF_B, 132 * SS)
    txt = "CONCEPTS"
    tr = 10 * SS
    ws = [d.textlength(ch, font=f) for ch in txt]
    x = W / 2 - (sum(ws) + tr * (len(txt) - 1)) / 2
    l, t, r, b = d.textbbox((0, 0), "C", font=f)
    for ch, w in zip(txt, ws):
        d.text((x, H / 2 - (t + b) / 2), ch, font=f, fill=(250, 238, 206))
        x += w + tr
    save(im.resize((1024, 192), Image.LANCZOS), "concepts_sign_serif", 32)


def bags():
    """1024 x 256 = 4 m x 1 m: two rows of bags on pegs over a white slat wall."""
    W, H = 1024 * SS, 256 * SS
    rng = random.Random(933)
    im = Image.new("RGB", (W, H), (236, 234, 228))
    d = ImageDraw.Draw(im)
    for y in range(0, H, 16 * SS):
        d.line([(0, y), (W, y)], fill=(214, 212, 206), width=SS)
    mesh_cols = [(26, 34, 70), (20, 20, 24), (150, 26, 36), (24, 70, 48), (40, 70, 140), (90, 30, 90)]
    for row in range(2):
        y0 = (6 + row * 125) * SS
        x = 8 * SS
        k = 0
        while x < W - 76 * SS:
            bw, bh = 64 * SS, 100 * SS
            top = y0 + 16 * SS
            d.ellipse([x + 22 * SS, y0 + 4 * SS, x + 42 * SS, y0 + 14 * SS], fill=(90, 90, 92))   # the peg
            clear = (k % 4 == 3)
            if clear:
                # a clear book bag: pale blue-grey vinyl, binders and a lunch box showing through
                d.rounded_rectangle([x, top, x + bw, top + bh], radius=14 * SS, fill=(196, 214, 222), outline=(120, 150, 170), width=3 * SS)
                for j, c in enumerate([(200, 40, 40), (40, 90, 170), (230, 190, 40)]):
                    d.rectangle([x + (8 + j * 16) * SS, top + 30 * SS, x + (20 + j * 16) * SS, top + 92 * SS], fill=tuple(int(v * 0.8 + 40) for v in c))
                d.rounded_rectangle([x + 10 * SS, top + 4 * SS, x + bw - 10 * SS, top + 22 * SS], radius=6 * SS, fill=(170, 190, 200))
            else:
                c = rng.choice(mesh_cols)
                d.rounded_rectangle([x, top, x + bw, top + bh], radius=16 * SS, fill=c)
                # the mesh: a diamond lattice, lighter where the bag's insides show
                inner = tuple(min(255, v + 70) for v in c)
                lat = Image.new("RGB", (bw, bh), c)
                ld = ImageDraw.Draw(lat)
                for s in range(-bh, bw + bh, 7 * SS):
                    ld.line([(s, 0), (s + bh, bh)], fill=inner, width=SS)
                    ld.line([(s + bh, 0), (s, bh)], fill=inner, width=SS)
                mask = Image.new("L", (bw, bh), 0)
                ImageDraw.Draw(mask).rounded_rectangle([0, 0, bw - 1, bh - 1], radius=16 * SS, fill=255)
                im.paste(lat, (x, top), mask)
                # trim round the edge, a solid bottom panel and a front pocket
                d.rounded_rectangle([x, top, x + bw, top + bh], radius=16 * SS, outline=tuple(max(0, v - 20) for v in c), width=5 * SS)
                d.rectangle([x + 4 * SS, top + bh - 18 * SS, x + bw - 4 * SS, top + bh - 4 * SS], fill=tuple(max(0, v - 15) for v in c))
                d.rounded_rectangle([x + 12 * SS, top + 52 * SS, x + bw - 12 * SS, top + 80 * SS], radius=6 * SS, outline=tuple(max(0, v - 20) for v in c), width=4 * SS)
                # the cover over the top of the bag and the edge of the white clip-off area
            # the haul loop over the peg
            d.arc([x + 20 * SS, y0, x + 44 * SS, y0 + 30 * SS], 180, 360, fill=(50, 50, 52), width=4 * SS)
            x += 76 * SS
            k += 1
        # a price strip on the shelf lip below each row
        d.rectangle([0, y0 + 118 * SS, W, y0 + 122 * SS], fill=(190, 188, 182))
    save(kb.grain(im.resize((1024, 256), Image.LANCZOS), 1.2, 935), "concepts_bags", 64)


def spatter():
    """The solids' finish: 1990s spatter paint, white ground (the material's colour multiplies
    it) with black and grey flecks. 512 x 512, 1 m."""
    N = 512
    rng = np.random.default_rng(939)
    im = Image.new("RGB", (N, N), (255, 255, 255))
    d = ImageDraw.Draw(im)
    for _ in range(2600):
        x, y = rng.uniform(0, N, 2)
        r = rng.choice([0.8, 1.2, 1.8, 2.6, 3.4], p=[0.4, 0.3, 0.17, 0.09, 0.04])
        c = (24, 24, 26) if rng.random() < 0.7 else (150, 150, 155)
        for ox in (-N, 0, N):
            for oy in (-N, 0, N):
                d.ellipse([x + ox - r, y + oy - r, x + ox + r, y + oy + r], fill=c)
    save(im, "concepts_spatter", 16)


def floor():
    N = 512   # 4 x 4 tiles of 0.305 m
    a = np.zeros((N, N, 3), np.float32)
    T = N // 4
    for j in range(4):
        for i in range(4):
            c = (226, 220, 206) if (i + j) % 2 == 0 else (196, 196, 192)
            if j == 3:
                c = (92, 44, 66) if i % 2 == 0 else (226, 220, 206)
            a[j * T:(j + 1) * T, i * T:(i + 1) * T] = c
            a[j * T:j * T + 2, i * T:(i + 1) * T] = (170, 166, 158)
            a[j * T:(j + 1) * T, i * T:i * T + 2] = (170, 166, 158)
    a += kb.noise(N, N, 4, 937, blur=1)[..., None]
    save(Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)), "concepts_floor", 64)


if __name__ == "__main__":
    siding(); sign_serif(); bags(); spatter(); floor()
    print("wrote tex/w9/concepts_*.png")
