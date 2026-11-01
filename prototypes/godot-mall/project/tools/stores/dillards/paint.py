"""Paints the Dillard's level-1 textures into tex/dl/ (design/godot-dillards.md).

Run from the project folder:  python3 tools/stores/dillards/paint.py
Every texture tiles. Sources: refs/new/dillards_L1 (IMG_4490 110-166 s, IMG_4491), Oct 23 2026.
"""
import os
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "..", "tex", "dl")
rng = np.random.default_rng(1989)


def noise(n, scale, octaves=3, shape=None):
    """Tileable noise in 0..1 (low-passed white noise; periodic by construction)."""
    h, w = shape if shape else (n, n)
    fy = np.fft.fftfreq(h)[:, None]
    fx = np.fft.fftfreq(w)[None, :]
    r = np.sqrt(fx ** 2 + fy ** 2) * scale
    wgt = np.exp(-r * r)
    for o in range(1, octaves):
        wgt = wgt + 0.5 ** o * np.exp(-(r / 2 ** o) ** 2)
    a = np.real(np.fft.ifft2(np.fft.fft2(rng.standard_normal((h, w))) * wgt))
    return (a - a.min()) / (a.max() - a.min() + 1e-9)


def save(name, rgb):
    os.makedirs(OUT, exist_ok=True)
    Image.fromarray(np.uint8(np.clip(rgb, 0, 255))).save(os.path.join(OUT, name))
    print("wrote tex/dl/" + name)


def travertine():
    # polished beige travertine, 24" squares laid square (IMG_4490 t110_094-106, IMG_4491).
    # 1024 px = 4 x 4 tiles = 2.4 m. Each tile: banded veining along one direction, small pits.
    n = 1024
    t = n // 4
    rgb = np.zeros((n, n, 3))
    for i in range(4):
        for j in range(4):
            sub = noise(t, 10, 3)
            band = noise(t, 90, 1)
            yy = np.linspace(0, 1, t)[:, None] if (i + j) % 2 == 0 else np.linspace(0, 1, t)[None, :]
            vein = np.sin((yy * 5 + band * 1.4) * np.pi) * 0.5 + 0.5
            tone = rng.uniform(-8, 8)
            v = 214 + tone + (sub - 0.5) * 18 - vein ** 10 * 7
            c = np.stack([v * 1.0, v * 0.93, v * 0.80], -1)
            pits = rng.random((t, t)) > 0.9965
            c[pits] *= 0.78
            rgb[i * t:(i + 1) * t, j * t:(j + 1) * t] = c
    for i in range(4):
        rgb[i * t:i * t + 2, :] *= 0.82
        rgb[:, i * t:i * t + 2] *= 0.82
    save("trav.png", rgb)


def granite():
    # granite speckle (grey, tinted per strip by vertex colour: the black and the brown bands).
    n = 256
    a = noise(n, 2, 1)
    b = rng.random((n, n))
    v = 150 + (a - 0.5) * 60
    v[b > 0.92] = 230
    v[b < 0.06] = 60
    save("granite.png", np.stack([v, v, v], -1))


def cherry():
    # cherry-plank hardwood under men's (IMG_4490 t110_022-055): ~13 cm planks, random butt joints.
    # 1024 px = 2.4 m square.
    n = 1024
    pw = n // 18                 # 18 planks across 2.4 m: 13.3 cm
    rgb = np.zeros((n, n, 3))
    grain = noise(n, 2.0, 2)
    for r in range(18):
        y0, y1 = r * pw, (r + 1) * pw if r < 17 else n
        cuts = sorted(set([int(rng.integers(0, n))] + [int(c) for c in rng.integers(0, n, 2)]))
        for k, c0 in enumerate(cuts):
            c1 = cuts[(k + 1) % len(cuts)] + (n if k + 1 == len(cuts) else 0)
            xs = np.arange(c0, c1) % n
            tone = rng.uniform(0.82, 1.12)
            base = np.array([128, 58, 34]) * tone
            g = grain[y0:y1][:, xs]
            rgb[y0:y1, xs] = base[None, None, :] * (0.84 + 0.26 * g[..., None])
            rgb[y0:y1, c0 % n] *= 0.55
        rgb[y0, :] *= 0.6
    save("cherry.png", rgb)


def carpet(name, col, fleck, n=512):
    a = noise(n, 1.2, 1)
    b = noise(n, 50, 2)
    rgb = np.array(col, float)[None, None, :] * (0.88 + 0.16 * a[..., None] + 0.08 * (b[..., None] - 0.5))
    m = rng.random((n, n)) > 0.95
    rgb[m] = fleck
    save(name, rgb)


def tile_vest():
    # the vestibule: pale grey 12" tile with darker accent squares (notes_E, IMG_4490 f045-056).
    n = 512
    t = n // 4
    rgb = np.zeros((n, n, 3))
    for i in range(4):
        for j in range(4):
            v = 196 + rng.uniform(-5, 5)
            if (i, j) in ((1, 1), (3, 3)):
                v = 120
            c = v + (noise(t, 6, 2) - 0.5) * 14
            rgb[i * t:(i + 1) * t, j * t:(j + 1) * t] = np.stack([c, c, c * 1.02], -1)
    for i in range(4):
        rgb[i * t:i * t + 2, :] *= 0.7
        rgb[:, i * t:i * t + 2] *= 0.7
    save("vest.png", rgb)


def carpet95():
    # 1995 (guess): men's on a deep green-grey cut pile instead of today's hardwood
    carpet("carpet95.png", [86, 96, 88], [60, 66, 60])


if __name__ == "__main__":
    travertine()
    granite()
    cherry()
    carpet("carpet.png", [138, 138, 136], [100, 100, 100])
    tile_vest()
    carpet95()
