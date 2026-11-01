"""Textures for Sound Shop's rebuilt front (Nov 1, 2026; design/storefronts/sound-shop.md),
written to tex/md/ss_*.png:

- ss_stucco.png: the black textured stucco of the curved fascia band that still survives at
  Southland (IMG_4484 f050-f055, now SOLA).
- ss_tile_black.png: the black 8-inch tile threshold in front of the glass (same frames).
  python3 tools/stores/media/paint_ss_front.py   (from the project folder)
"""
import os
import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "..", "tex", "md")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(1995)


def stucco():
    n = 512
    a = rng.normal(0, 1, (n, n))
    im = Image.fromarray(((a - a.min()) / (a.max() - a.min()) * 255).astype(np.uint8))
    fine = np.asarray(im.filter(ImageFilter.GaussianBlur(0.8)), float)
    blob = np.asarray(im.filter(ImageFilter.GaussianBlur(3.0)), float)
    v = 34 + (fine - 128) * 0.22 + (blob - 128) * 0.45
    # tile seamlessly: average with the rolled copy at the seams
    v = np.clip(v, 14, 70)
    rgb = np.stack([v * 1.0, v * 1.0, v * 1.04], -1)
    Image.fromarray(rgb.astype(np.uint8)).save(os.path.join(OUT, "ss_stucco.png"), optimize=True)


def tile_black():
    # 4 x 4 tiles of 8 in (0.2 m) per texture: 0.8 m repeat, 128 px a tile
    T, N = 128, 4
    a = np.zeros((T * N, T * N, 3), float)
    for i in range(N):
        for j in range(N):
            base = 20 + rng.uniform(-4, 5)
            noise = rng.normal(0, 2.0, (T, T))
            a[i * T:(i + 1) * T, j * T:(j + 1) * T] = (base + noise)[..., None] * np.array([1.0, 1.0, 1.05])
    g = 3   # grout lines, mid grey
    for k in range(N):
        a[k * T:k * T + g, :] = (78, 76, 72)
        a[:, k * T:k * T + g] = (78, 76, 72)
    Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)).save(os.path.join(OUT, "ss_tile_black.png"), optimize=True)


def halo():
    w, h = 1024, 160
    a = np.zeros((h, w), float)
    a[55:105, 70:w - 70] = 1.0
    im = Image.fromarray((a * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(26))
    al = np.asarray(im, float) / 255.0
    rgba = np.zeros((h, w, 4), np.uint8)
    rgba[..., 0] = 255
    rgba[..., 1] = 90
    rgba[..., 2] = 30
    rgba[..., 3] = np.clip(al * 70, 0, 255).astype(np.uint8)
    Image.fromarray(rgba, "RGBA").save(os.path.join(OUT, "ss_halo.png"), optimize=True)


if __name__ == "__main__":
    stucco()
    tile_black()
