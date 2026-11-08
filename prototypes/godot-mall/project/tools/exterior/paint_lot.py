"""Workstream LOT (Nov 8 2026): the lot's asphalt set, its wear decals, the worn stall paint and the
outside's foliage atlas, painted into tex/ex/ex_*.png (design/godot-exterior.md "Workstream LOT").

  ex_asphalt_alb.png   2048 px, 8 m: binder + exposed aggregate, mottling, tiles seamlessly (FFT noise)
  ex_asphalt_rgh.png   1024 px: roughness (binder ~0.93, worn stones ~0.80)
  ex_asphalt_nrm.png   1024 px: a subtle normal map from the aggregate's height
  ex_lot_decals.png    1024 px RGBA, 2 x 2 cells: sealed crack, alligator cracks, a patch, an oil stain
  ex_paint_worn.png    64 x 1024 RGBA: a stripe's worn paint mask (white; the material tints it)
  ex_foliage.png       1024 px RGBA, the trees' and shrubs' cards (cells listed at FOL below)
  ex_palm_bark.png     256 x 512: the sabal palm's trunk with its boot scars

Everything is deterministic (fixed seeds). Run: python3 tools/exterior/paint_lot.py
"""
import os
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "tex", "ex")
os.makedirs(OUT, exist_ok=True)


def save(name, arr, mode=None):
    a = np.clip(arr, 0, 255).astype(np.uint8)
    Image.fromarray(a, mode).save(os.path.join(OUT, name + ".png"), optimize=True)
    print("wrote", name, a.shape)


def pnoise(n, m, scale, rng):
    """Periodic (tileable) noise n x m, features about `scale` px, zero mean, unit std."""
    w = rng.standard_normal((n, m))
    fy = np.fft.fftfreq(n)[:, None]
    fx = np.fft.fftfreq(m)[None, :]
    f = np.sqrt(fx * fx + fy * fy)
    filt = np.exp(-(f * scale) ** 2 * 4.0)
    r = np.real(np.fft.ifft2(np.fft.fft2(w) * filt))
    r -= r.mean()
    return r / (r.std() + 1e-9)


# ------------------------------------------------------------------ asphalt
def asphalt():
    rng = np.random.default_rng(1995)
    N = 2048
    # aggregate: blobs from thresholded fine noise (2-4 px = 8-16 mm stones at 4 mm/px)
    fine = pnoise(N, N, 2.2, rng)
    fine2 = pnoise(N, N, 3.5, rng)
    stones = np.clip((fine - 0.9) * 2.5, 0, 1)
    stones2 = np.clip((fine2 - 1.3) * 2.0, 0, 1)
    stone_tone = pnoise(N, N, 6.0, rng)            # each stone a different grey / tan
    sand = rng.standard_normal((N, N)) * 0.5       # the binder's sand grain
    mott = pnoise(N, N, 40.0, rng)                 # ~16 cm blotches
    big = pnoise(N, N, 260.0, rng)                 # ~1 m wear
    lum = 100.0 + sand * 6.0 + mott * 5.0 + big * 6.0
    lum = lum + stones * (40.0 + stone_tone * 14.0) + stones2 * 26.0
    lum = lum - np.clip(-fine - 1.6, 0, 1) * 30.0  # dark pits where fines washed out
    img = np.stack([lum * 1.00, lum * 0.985, lum * 0.955], -1)
    # a few warm (limestone) and cool (gravel) stones
    warm = np.clip(stone_tone - 1.0, 0, 1) * stones
    img[..., 0] += warm * 14.0; img[..., 2] -= warm * 8.0
    save("ex_asphalt_alb", img)
    # roughness and height at 1024
    h = (stones * 1.0 + stones2 * 0.6 - np.clip(-fine - 1.6, 0, 1) * 0.8 + sand * 0.08)
    h = h.reshape(1024, 2, 1024, 2).mean((1, 3))
    rough = 0.93 - np.clip(h, 0, 1) * 0.13 + mott.reshape(1024, 2, 1024, 2).mean((1, 3)) * 0.015
    save("ex_asphalt_rgh", np.repeat((rough * 255.0)[..., None], 3, -1))
    gx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5
    gy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5
    k = 0.9                                         # subtle
    nx = -gx * k; ny = gy * k; nz = np.ones_like(nx)
    l = np.sqrt(nx * nx + ny * ny + nz * nz)
    nrm = np.stack([nx / l, ny / l, nz / l], -1) * 0.5 + 0.5
    save("ex_asphalt_nrm", nrm * 255.0)


# ------------------------------------------------------------------ decals
def crack_path(d, rng, x, y, ang, length, width, col, branch=2):
    pts = [(x, y)]
    for _ in range(int(length / 6)):
        ang += rng.normal(0, 0.13)
        x += math.cos(ang) * 6; y += math.sin(ang) * 6
        pts.append((x, y))
    d.line(pts, fill=col, width=int(width), joint="curve")
    if branch > 0:
        for _ in range(rng.integers(1, 3)):
            p = pts[rng.integers(len(pts) // 4, max(len(pts) // 4 + 1, len(pts) - 2))]
            crack_path(d, rng, p[0], p[1], ang + rng.choice([-1, 1]) * rng.uniform(0.6, 1.2),
                       length * 0.4, max(2, width * 0.6), col, branch - 1)


def decals():
    rng = np.random.default_rng(2026)
    C = 512
    atlas = np.zeros((1024, 1024, 4), np.float32)

    def cell(ix, iy, rgba):
        atlas[iy * C:(iy + 1) * C, ix * C:(ix + 1) * C] = rgba

    def edge_fade(a, m=40):
        y, x = np.mgrid[0:C, 0:C]
        e = np.minimum.reduce([x, y, C - 1 - x, C - 1 - y]).astype(np.float32)
        return a * np.clip(e / m, 0, 1)

    # 0: a sealed crack (tar crack-fill, a glossy black ribbon a few cm wide, 2 m across the cell)
    im = Image.new("L", (C, C), 0); d = ImageDraw.Draw(im)
    crack_path(d, rng, 20, 250, 0.05, 560, 9, 255)
    a = np.asarray(im.filter(ImageFilter.GaussianBlur(1.2)), np.float32) / 255.0
    cell(0, 0, np.dstack([np.full((C, C), 22.0), np.full((C, C), 22.0), np.full((C, C), 24.0), edge_fade(a, 30) * 235.0]))
    # 1: alligator cracking (a fatigue net, open cracks, darker binder between)
    im = Image.new("L", (C, C), 0); d = ImageDraw.Draw(im)
    for _ in range(14):
        crack_path(d, rng, rng.uniform(60, 450), rng.uniform(60, 450), rng.uniform(0, 6.28), rng.uniform(80, 200), 3, 255, 1)
    net = np.asarray(im.filter(ImageFilter.GaussianBlur(0.8)), np.float32) / 255.0
    y, x = np.mgrid[0:C, 0:C]
    blob = np.clip(1.2 - np.hypot(x - C / 2, y - C / 2) / (C * 0.42) + pnoise(C, C, 30, rng) * 0.15, 0, 1)
    a = np.clip(net * 0.95 + blob * 0.18, 0, 1) * blob
    cell(1, 0, np.dstack([np.full((C, C), 30.0), np.full((C, C), 30.0), np.full((C, C), 31.0), a * 255.0]))
    # 2: a patch: a rectangle of newer, darker asphalt with a sealed seam
    r = np.zeros((C, C), np.float32)
    x0, y0, x1, y1 = 50, 90, 462, 420
    jag = pnoise(C, C, 6, rng) * 4
    inside = (x > x0 + jag) & (x < x1 + jag) & (y > y0 + jag) & (y < y1 + jag)
    r[inside] = 1.0
    seam = np.asarray(Image.fromarray((r * 255).astype(np.uint8)).filter(ImageFilter.FIND_EDGES).filter(ImageFilter.MaxFilter(5)), np.float32) / 255.0
    # the patch's own asphalt: the lot's grain (ex_asphalt_alb), a little darker and less worn
    alb = np.asarray(Image.open(os.path.join(OUT, "ex_asphalt_alb.png")).convert("L"), np.float32)[700:700 + C, 300:300 + C]
    tone = alb * 0.78
    rgb = np.where(seam > 0.3, 25.0, tone)
    a = np.clip(r * 0.92 + seam, 0, 1)
    cell(0, 1, np.dstack([rgb, rgb, rgb * 1.02, a * 255.0]))
    # 3: an oil stain (where cars stand), soft and blotchy
    blob = np.clip(1.0 - np.hypot((x - C / 2) * 1.3, y - C / 2) / (C * 0.38) + pnoise(C, C, 25, rng) * 0.25, 0, 1)
    a = blob ** 1.5 * (0.55 + pnoise(C, C, 8, rng) * 0.12)
    cell(1, 1, np.dstack([np.full((C, C), 18.0), np.full((C, C), 17.0), np.full((C, C), 16.0), np.clip(a, 0, 1) * 255.0]))
    save("ex_lot_decals", atlas, "RGBA")


def paint():
    """A stripe's worn paint: v runs along the stripe (1024 px = 8 m), u across it (64 px)."""
    rng = np.random.default_rng(1969)
    W, H = 64, 1024
    wear = pnoise(H, W * 4, 10, rng)[:, ::4] * 0.6 + pnoise(H, W, 2.5, rng) * 0.4
    y, x = np.mgrid[0:H, 0:W]
    edge = np.minimum(x, W - 1 - x) / 6.0 + pnoise(H, W, 3, rng) * 0.3
    a = np.clip(0.95 - np.clip(wear - 0.6, 0, 1) * 1.4, 0.15, 1.0) * np.clip(edge, 0, 1)
    # the asphalt's stones show through the paint as dark specks
    speck = np.clip(pnoise(H, W, 1.2, rng) - 1.6, 0, 1)
    lum = 245.0 - speck * 120.0 - np.clip(wear, 0, 1) * 25.0
    save("ex_paint_worn", np.dstack([lum, lum, lum, a * 255.0]), "RGBA")


# ------------------------------------------------------------------ foliage
# Cells of ex_foliage.png (1024 px, u right, v down), as [u0, v0, u1, v1]:
FOL = {
    "fan": [0.0, 0.0, 0.5, 0.5],       # a sabal (cabbage palm) fan leaf, petiole at the bottom centre
    "oak": [0.5, 0.0, 1.0, 0.5],       # a live-oak leaf cluster (small dark leaves, dense)
    "shrub": [0.0, 0.5, 0.5, 1.0],     # a clipped shrub's leaf mass (holly / Indian hawthorn)
    "grass": [0.5, 0.5, 0.75, 1.0],    # an ornamental grass / liriope clump, bases at the bottom
    "dead": [0.75, 0.5, 1.0, 1.0],     # the palm's hanging dead fronds (brown)
}


def leaf_cluster(C, rng, n, size, base, var, dense_core=0.0):
    im = Image.new("RGBA", (C, C), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    if dense_core:
        # a solid core keeps the card's coverage when its mipmaps average the alpha (the far crowns)
        d.ellipse([C * (0.5 - dense_core), C * (0.5 - dense_core), C * (0.5 + dense_core), C * (0.5 + dense_core)],
                  fill=tuple(int(c * 0.55) for c in base) + (255,))
    for _ in range(n):
        r = math.sqrt(rng.random()) * C * 0.46
        t = rng.uniform(0, 6.283)
        cx = C / 2 + math.cos(t) * r; cy = C / 2 + math.sin(t) * r
        ang = rng.uniform(0, 6.283)
        L = size * rng.uniform(0.7, 1.3); Wd = L * 0.45
        sh = 0.65 + 0.5 * (1 - r / (C * 0.46)) * rng.uniform(0.6, 1.0)
        col = tuple(int(np.clip((base[k] + rng.normal(0, var)) * sh, 0, 255)) for k in range(3)) + (255,)
        pts = []
        for k in range(10):
            a = k / 10 * 6.283
            px = math.cos(a) * L * 0.5; py = math.sin(a) * Wd * 0.5
            pts.append((cx + px * math.cos(ang) - py * math.sin(ang), cy + px * math.sin(ang) + py * math.cos(ang)))
        d.polygon(pts, fill=col)
    return np.asarray(im, np.float32)


def foliage():
    rng = np.random.default_rng(1970)
    A = np.zeros((1024, 1024, 4), np.float32)
    C = 512
    # the sabal fan: costapalmate, ~40 stiff segments from the hastula, split tips, drooping threads
    im = Image.new("RGBA", (C, C), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    hx, hy = C / 2, C * 0.97
    nseg = 44
    for i in range(nseg):
        a = math.pi * (0.06 + 0.88 * i / (nseg - 1))
        L = C * (0.80 + 0.12 * math.sin(math.pi * i / (nseg - 1))) * rng.uniform(0.93, 1.03)
        w0 = 7.5
        ex, ey = hx - math.cos(a) * L, hy - math.sin(a) * L
        nxv, nyv = -math.sin(a), math.cos(a)
        g = int(rng.uniform(78, 104)); col = (int(g * 0.62), g, int(g * 0.52), 255)
        split = 0.78 + rng.uniform(-0.05, 0.05)
        mx, my = hx - math.cos(a) * L * split, hy - math.sin(a) * L * split
        d.polygon([(hx, hy), (hx + nxv * 2, hy + nyv * 2), (mx + nxv * w0, my + nyv * w0), (ex + nxv * 2, ey + nyv * 2),
                   (ex - nxv * 2, ey - nyv * 2), (mx - nxv * w0, my - nyv * w0)], fill=col)
        # the fold (midrib) is lighter
        d.line([(hx, hy), (mx, my)], fill=(int(g * 0.8), int(g * 1.15), int(g * 0.65), 255), width=2)
    # fill between the segments' bases so the far fan keeps its coverage
    d.pieslice([hx - C * 0.30, hy - C * 0.30, hx + C * 0.30, hy + C * 0.30], 186, 354, fill=(52, 82, 44, 255))
    fan = np.asarray(im, np.float32)
    A[0:C, 0:C] = fan
    # the live oak's cluster: many small dark glossy leaves
    A[0:C, C:2 * C] = leaf_cluster(C, rng, 2200, 22, (58, 84, 40), 9, dense_core=0.16)
    # the clipped shrub: smaller, lighter leaves, a dense core
    A[C:2 * C, 0:C] = leaf_cluster(C, rng, 3200, 16, (72, 104, 52), 10, dense_core=0.34)
    # grass / liriope: blades from the bottom centre
    im = Image.new("RGBA", (C // 2, C), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    for _ in range(220):
        bx = C / 4 + rng.normal(0, 16); L = rng.uniform(0.45, 0.95) * C; lean = rng.normal(0, 0.45)
        g = int(rng.uniform(70, 120)); col = (int(g * 0.55), g, int(g * 0.4), 255)
        pts = [(bx - 2, C), (bx + 2, C)]
        tx = bx + math.sin(lean) * L * 0.55; ty = C - L
        d.polygon([(bx - 2.5, C), (bx + 2.5, C), (tx, ty)], fill=col)
    A[C:2 * C, C:C + C // 2] = np.asarray(im, np.float32)
    # dead fronds: brown, hanging (the boot of old leaves under a sabal's crown)
    im = Image.new("RGBA", (C // 2, C), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    for _ in range(60):
        bx = C / 4 + rng.normal(0, 30); L = rng.uniform(0.5, 0.95) * C
        g = int(rng.uniform(80, 130)); col = (g, int(g * 0.78), int(g * 0.52), 255)
        d.polygon([(bx - 4, 0), (bx + 4, 0), (bx + rng.normal(0, 10), L)], fill=col)
    A[C:2 * C, C + C // 2:2 * C] = np.asarray(im, np.float32)
    # dilate colour into the transparent texels (no dark halos where the mipmaps blend)
    rgb = A[..., :3].copy(); al = A[..., 3] > 0
    for _ in range(6):
        im = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(3))
        grow = np.asarray(im, np.float32) * 0.85
        rgb = np.where(al[..., None], rgb, np.maximum(rgb, grow))
    A[..., :3] = rgb
    save("ex_foliage", A, "RGBA")
    # the palm's trunk: grey-brown with the crossed boot scars (sabal), v = 2 m of trunk
    W, H = 256, 512
    t = 108 + pnoise(H, W, 6, rng) * 10
    y, x = np.mgrid[0:H, 0:W]
    lat = (np.sin((x / W * 6.283 * 9) + (y / H * 6.283 * 9)) > 0.75) | (np.sin((x / W * 6.283 * 9) - (y / H * 6.283 * 9)) > 0.75)
    lat = np.asarray(Image.fromarray((lat * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.5)), np.float32) / 255.0
    t = t * (1.0 - lat * 0.12) + (np.sin(y / H * 6.283 * 22) * 4) + pnoise(H, W, 2, rng) * 5
    save("ex_palm_bark", np.dstack([t * 1.0, t * 0.92, t * 0.80]))


if __name__ == "__main__":
    asphalt()
    decals()
    paint()
    foliage()
