"""Paints the old Sears / Lynn's Interiors textures into tex/sr/ (design/godot-sears.md).

Run from the project folder:  python3 tools/stores/sears/paint.py
Every texture tiles. Sources: refs/new/sears (IMG_4409-4413, Oct 23 2026); the 1995 floors are guesses.
"""
import os
import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "..", "tex", "sr")
rng = np.random.default_rng(1995)


def noise(n, scale, octaves=4):
    """Tileable noise in 0..1: white noise low-passed in the frequency domain (periodic by
    construction), features about `scale` px across; `octaves` adds finer detail."""
    f = np.fft.fftfreq(n)
    r = np.sqrt(f[:, None] ** 2 + f[None, :] ** 2) * scale
    w = np.exp(-r * r) + 0.0
    for o in range(1, octaves):
        w = w + 0.5 ** o * np.exp(-(r / 2 ** o) ** 2)
    a = np.real(np.fft.ifft2(np.fft.fft2(rng.standard_normal((n, n))) * w))
    return (a - a.min()) / (a.max() - a.min() + 1e-9)


def wrap_smooth(a, k):
    """Gaussian-ish blur that wraps (keeps tiling)."""
    p = np.pad(a, k, mode="wrap")
    im = Image.fromarray(np.uint8(np.clip(p, 0, 1) * 255)).filter(ImageFilter.GaussianBlur(k / 2))
    return np.asarray(im, float)[k:-k, k:-k] / 255.0


def save(name, rgb):
    os.makedirs(OUT, exist_ok=True)
    Image.fromarray(np.uint8(np.clip(rgb, 0, 255))).save(os.path.join(OUT, name))
    print("wrote tex/sr/" + name)


def concrete():
    # 2026: polished light-grey concrete with mottling, trowel swirls and dark mastic ghosts
    # where the old floor came up (IMG_4409 f001, IMG_4411 f011). 1024 px = 4 m.
    n = 1024
    base = wrap_smooth(noise(n, 128), 8)
    fine = noise(n, 6, 2)
    ghost = wrap_smooth(noise(n, 256, 3), 20)
    ghost = np.clip((ghost - 0.62) * 6.0, 0, 1)
    v = 196 + (base - 0.5) * 26 + (fine - 0.5) * 10 - ghost * 26
    rgb = np.stack([v * 0.985, v * 1.0, v * 1.02], -1)
    # scuff scratches: thin random arcs
    im = Image.fromarray(np.uint8(np.clip(rgb, 0, 255)))
    from PIL import ImageDraw
    d = ImageDraw.Draw(im)
    for _ in range(60):
        x, y = rng.integers(0, n, 2)
        r = rng.integers(40, 260)
        a0 = rng.integers(0, 360)
        d.arc([x - r, y - r, x + r, y + r], a0, a0 + rng.integers(15, 70), fill=(150, 152, 156), width=1)
    save("concrete.png", np.asarray(im, float))


def vct95():
    # 1995 (guess): 12" almond vinyl composition tile, speckled, slight tile-to-tile tone shift.
    # 512 px = 4 x 4 tiles = 1.22 m
    n = 512
    t = n // 4
    rgb = np.zeros((n, n, 3))
    for i in range(4):
        for j in range(4):
            k = 1.0 + rng.uniform(-0.025, 0.025)
            rgb[i * t:(i + 1) * t, j * t:(j + 1) * t] = np.array([222, 212, 192]) * k
    sp = rng.random((n, n))
    rgb[sp > 0.985] *= 0.72
    rgb[(sp > 0.97) & (sp <= 0.985)] *= 1.06
    rgb[(sp < 0.012)] = [160, 142, 118]
    for i in range(4):
        rgb[i * t:i * t + 1, :] *= 0.86
        rgb[:, i * t:i * t + 1] *= 0.86
    save("vct95.png", rgb)


def carpet(name, col, fleck, n=512):
    a = noise(n, 3, 2)
    b = wrap_smooth(noise(n, 64), 4)
    rgb = np.array(col, float)[None, None, :] * (0.9 + 0.12 * a[..., None] + 0.06 * (b[..., None] - 0.5))
    m = rng.random((n, n)) > 0.93
    rgb[m] = np.array(fleck, float) * (0.9 + 0.2 * rng.random((m.sum(), 1)))
    save(name, rgb)


def panel():
    # the separator/perimeter walls: white gypsum panels 1.2 m wide (IMG_4410 f001, IMG_4411 f006).
    # 256 x 512 px = 1.2 m x 2.4 m: a joint at the left edge, faint roller texture.
    w, h = 256, 512
    a = noise(512, 4, 2)[:h, :w]
    v = 238 + (a - 0.5) * 6
    rgb = np.stack([v, v, v * 1.005], -1)
    rgb[:, 0:2] *= 0.80
    rgb[:, 2:3] *= 0.93
    save("panel.png", rgb)


def marble_vinyl():
    # one bedroom-vignette alcove: pale marbled vinyl tile (IMG_4413). 512 px = 1.2 m (4 x 4 tiles).
    n = 512
    m = noise(n, 40, 5)
    vein = np.abs(np.sin((m * 9.0 + np.linspace(0, 6, n)[None, :]) * np.pi))
    v = 232 - (1 - vein) ** 8 * 40
    rgb = np.stack([v * 1.0, v * 0.99, v * 0.97], -1)
    t = n // 4
    for i in range(4):
        rgb[i * t:i * t + 1, :] *= 0.9
        rgb[:, i * t:i * t + 1] *= 0.9
    save("marble_vinyl.png", rgb)


if __name__ == "__main__":
    concrete()
    vct95()
    # 1995 department carpet (guess): a dusty blue-grey with darker flecks
    carpet("carpet95.png", [118, 128, 146], [70, 76, 92])
    # 2026 mattress gallery: taupe carpet (IMG_4412 f025-f040)
    carpet("carpet_taupe.png", [150, 138, 122], [110, 100, 88])
    panel()
    marble_vinyl()
