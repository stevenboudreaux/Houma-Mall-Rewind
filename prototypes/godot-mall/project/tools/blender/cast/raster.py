"""Rasterise per-corner attributes into texture space (numpy only), and pad islands.

Every texel of a painted texture maps to a point on the person (position, normal, hm08 UV ...), so
the painting is a function of the 3D surface: no stretching across islands, and the same paint works
on any UV layout.
"""
import numpy as np


def raster(cuv, attrs, W, H=None, pad_px=0.75):
    """cuv (m,3,2) image coords 0..1, attrs (m,3,k) -> (H,W,k) float32 image, (H,W) bool coverage.
    Triangles are grown by pad_px in barycentric tolerance so neighbouring triangles meet."""
    H = H or W
    k = attrs.shape[2]
    out = np.zeros((H, W, k), np.float32)
    cov = np.zeros((H, W), bool)
    P = cuv * np.array([W, H]) - 0.5
    for t in range(len(P)):
        a, b, c = P[t]
        x0 = int(max(np.floor(min(a[0], b[0], c[0]) - 1), 0)); x1 = int(min(np.ceil(max(a[0], b[0], c[0]) + 1), W - 1))
        y0 = int(max(np.floor(min(a[1], b[1], c[1]) - 1), 0)); y1 = int(min(np.ceil(max(a[1], b[1], c[1]) + 1), H - 1))
        if x1 < x0 or y1 < y0:
            continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1), np.arange(y0, y1 + 1))
        v0 = b - a; v1 = c - a
        den = v0[0] * v1[1] - v1[0] * v0[1]
        if abs(den) < 1e-12:
            continue
        px = xs - a[0]; py = ys - a[1]
        l1 = (px * v1[1] - v1[0] * py) / den
        l2 = (v0[0] * py - px * v0[1]) / den
        l0 = 1 - l1 - l2
        # tolerance in barycentric units ~ pad_px / triangle size
        size = max(np.sqrt(abs(den)), 1e-6)
        tol = pad_px / size
        m = (l0 >= -tol) & (l1 >= -tol) & (l2 >= -tol)
        # first writer wins at exact interiors; edge-tolerant texels only fill empties
        inside = (l0 >= 0) & (l1 >= 0) & (l2 >= 0)
        sel = m & (inside | ~cov[y0:y1 + 1, x0:x1 + 1])
        if not sel.any():
            continue
        L = np.stack([l0, l1, l2], -1).clip(0, None)
        L /= L.sum(-1, keepdims=True)
        val = np.einsum("hwj,jk->hwk", L, attrs[t])
        sub = out[y0:y1 + 1, x0:x1 + 1]
        sub[sel] = val[sel]
        cov[y0:y1 + 1, x0:x1 + 1] |= sel
    return out, cov


def dilate(img, cov, px=8):
    """Grow covered texels outward px times (mean of covered neighbours) so mipmaps don't bleed."""
    img = img.copy(); cov = cov.copy()
    for _ in range(px):
        acc = np.zeros_like(img); cnt = np.zeros(cov.shape, np.float32)
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (-1, -1), (1, -1), (-1, 1)):
            s = np.roll(np.roll(img * cov[..., None], dy, 0), dx, 1)
            c = np.roll(np.roll(cov, dy, 0), dx, 1)
            acc += s; cnt += c
        grow = (~cov) & (cnt > 0)
        img[grow] = acc[grow] / cnt[grow][:, None]
        cov = cov | grow
    return img, cov


def to8(a):
    return (np.clip(a, 0, 1) * 255 + 0.5).astype(np.uint8)


# ---- small procedural helpers ----------------------------------------------------------------
def hash3(p):
    p = np.asarray(p, np.float64)
    h = np.sin(p[..., 0] * 127.1 + p[..., 1] * 311.7 + p[..., 2] * 74.7) * 43758.5453
    return h - np.floor(h)


def vnoise3(p, scale):
    """Value noise in 3D, smooth, ~0..1."""
    q = np.asarray(p, np.float64) * scale
    i = np.floor(q); f = q - i
    u = f * f * (3 - 2 * f)
    out = 0
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                w = (u[..., 0] if dx else 1 - u[..., 0]) * (u[..., 1] if dy else 1 - u[..., 1]) * (u[..., 2] if dz else 1 - u[..., 2])
                out = out + w * hash3(i + np.array([dx, dy, dz]))
    return out


def fbm3(p, scale, octaves=3):
    s, a, t = scale, 1.0, 0.0
    tot = 0
    for _ in range(octaves):
        t = t + a * vnoise3(p, s)
        tot += a
        s *= 2.03; a *= 0.5
    return t / tot


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def hexrgb(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])


def srgb_to_lin(c):
    c = np.asarray(c, np.float64)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def lin_to_srgb(c):
    c = np.clip(np.asarray(c, np.float64), 0, 1)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)


def height_to_normal(h, strength):
    """Tangent-space normal map (OpenGL, +Y up in image = -row) from a height image (texels)."""
    gx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * 0.5 * strength
    gy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * 0.5 * strength
    n = np.stack([-gx, gy, np.ones_like(h)], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return n * 0.5 + 0.5
