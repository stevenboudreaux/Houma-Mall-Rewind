"""Repainting a converted Rocketbox person (numpy + PIL; called from rb_cast.py).

Order (Steven, Nov 8): the body as Rocketbox made it -> clothes repainted to the uniform (no logos) ->
build edits (rb_cast.py) -> only then tone tweaks on the skin. Every recolour keeps the texture's own light
and detail: target colour x (luminance / the region's reference luminance).
"""
import numpy as np
from PIL import Image


def hexrgb(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])


def lum(c):
    return c[..., 0] * 0.3 + c[..., 1] * 0.59 + c[..., 2] * 0.11


def sat(c):
    return c.max(-1) - c.min(-1)


def load(path, mode="RGB"):
    return np.asarray(Image.open(path).convert(mode), np.float32) / 255.0


def save(a, path, mode="RGB"):
    Image.fromarray((np.clip(a, 0, 1) * 255 + 0.5).astype(np.uint8), mode).save(path, optimize=True)


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


# ---- clothes ---------------------------------------------------------------------------------------
def classify(c, region):
    """Per-texel class of a Rocketbox body texture: 'skin', 'light' (shirts), 'dark' (trousers, shoes),
    from colour, refined by the body region each texel belongs to (region: 'top', 'legs', 'feet', 'hands', '')."""
    L = lum(c); S = sat(c)
    skin = (c[..., 0] > c[..., 2] + 0.07) & (c[..., 0] > c[..., 1]) & (L > 0.22) & (S > 0.08) & (S < 0.45)
    return skin


def recolour(c, mask, target, detail=1.0, ref=None):
    L = lum(c)
    if not mask.any():
        return c
    m = float(np.percentile(L[mask], 70)) if ref is None else ref
    Lf = m + (L - m) * detail
    out = c.copy()
    out[mask] = np.clip(target[None] * (Lf[mask] / max(m, 1e-3))[:, None], 0, 1)
    return out


def repaint_map(tex, region, spec):
    """Garments by colour: every non-skin texel of the trunk, legs and feet goes to the nearest of the
    data file's source colours ("map": [{"from": hex, "to": hex or absent = keep, "detail": k}]) and is
    recoloured from its own light. Skin = the hands region only ("skin_by": "region"), or by colour too."""
    skin = (region == 4)
    if spec.get("skin_by", "colour") != "region":
        skin = skin | classify(tex, region)
    out = tex.copy()
    cloth = ~skin & (region >= 1) & (region <= 3)
    if spec.get("by_uv"):                    # the entries' rectangles decide; regions only exclude hands
        cloth = ~skin & (region != 4)
    def feat(c):
        L = lum(c)[..., None]
        return np.concatenate([c / np.maximum(L, 0.05) * float(spec.get("chroma_w", 1.0)), L], -1)
    F = feat(tex)
    ents = spec["map"]
    seeds = np.stack([feat(hexrgb(e["from"])[None, None])[0, 0] for e in ents])
    d = np.linalg.norm(F[..., None, :] - seeds[None, None], axis=-1)
    # an entry only competes in its regions ("regions": ["top", "legs", "feet"], default all)
    code = {"top": 1, "legs": 2, "feet": 3}
    for i, e in enumerate(ents):
        if e.get("regions"):
            ok = np.isin(region, [code[r] for r in e["regions"]])
            d[..., i] = np.where(ok, d[..., i], 1e9)
        if e.get("uv"):                      # and only inside its texture rectangle(s) (image coords)
            H, W = region.shape
            rects = e["uv"] if isinstance(e["uv"][0], list) else [e["uv"]]
            ok = np.zeros(region.shape, bool)
            for x0, y0, x1, y1 in rects:
                ok[int(y0 * H):int(y1 * H), int(x0 * W):int(x1 * W)] = True
            d[..., i] = np.where(ok, d[..., i], 1e9)
    near = np.where(d.min(-1) < 1e8, d.argmin(-1), -1)      # -1: no entry may touch this texel
    for i, e in enumerate(ents):
        if not e.get("to"):
            continue
        m = cloth & (near == i)
        out = recolour(out, m, hexrgb(e["to"]), float(e.get("detail", 1.0)))
    return out, skin


def repaint_body(tex, region, spec):
    if "map" in spec:
        return repaint_map(tex, region, spec)
    """tex (H,W,3) float; region (H,W) str-coded int: 0 none, 1 top, 2 legs, 3 feet, 4 hands/skin areas.
    spec: the data file's "repaint" {top: hex, legs: hex, feet: hex, legs_detail, top_detail, prints: [...]}"""
    skin = classify(tex, region) | (region == 4)
    out = tex.copy()
    # garments by colour, seeded by region: a shirt tail weighted to the hips is still the shirt.
    # Each non-skin texel of the trunk / legs goes to the nearer of the two garments' median colours.
    cloth = ~skin & ((region == 1) | (region == 2))
    def feat(c):
        L = lum(c)[..., None]
        return np.concatenate([c / np.maximum(L, 0.05) * 0.25, L], -1)
    F = feat(tex)
    seeds = {}
    for code in (1, 2):
        m = cloth & (region == code)
        if m.any():
            seeds[code] = np.median(F[m], 0)
    cls = region.copy()
    if len(seeds) == 2:
        d1 = np.linalg.norm(F - seeds[1], axis=-1); d2 = np.linalg.norm(F - seeds[2], axis=-1)
        cls = np.where(cloth, np.where(d1 <= d2, 1, 2), region)
    for code, key in ((1, "top"), (2, "legs"), (3, "feet")):
        if key not in spec:
            continue
        m = (cls == code) & ~skin
        out = recolour(out, m, hexrgb(spec[key]), float(spec.get(key + "_detail", 1.0)))
    return out, skin


# ---- skin tone (last) --------------------------------------------------------------------------------
def tone(tex, skin_mask, spec, pos=None, eyes=None):
    """Warm the skin a touch and add subtle variation (cheeks, nose, ears) where pos (H,W,3, Y up metres)
    is known: spec {"warm": 0..1, "gain": [r,g,b], "cheeks": 0..1, "nose": 0..1}."""
    out = tex.copy()
    g = np.array(spec.get("gain", [1.0, 1.0, 1.0]), np.float32)
    w = float(spec.get("warm", 0.0))
    warm = np.array([1 + 0.06 * w, 1 + 0.015 * w, 1 - 0.05 * w], np.float32)
    k = g * warm
    out[skin_mask] = np.clip(out[skin_mask] * k, 0, 1)
    if pos is not None and eyes is not None:
        eL, eR = eyes
        red = np.array([1.06, 0.95, 0.93], np.float32)
        x, y, z = pos[..., 0], pos[..., 1], pos[..., 2]
        f = np.zeros(x.shape, np.float32)
        for e in (eL, eR):
            f += np.exp(-(((x - e[0] * 1.15) / 0.026) ** 2 + ((y - (e[1] - 0.035)) / 0.022) ** 2)) * float(spec.get("cheeks", 0.5))
        f += np.exp(-((x / 0.012) ** 2 + ((y - (eL[1] - 0.04)) / 0.022) ** 2)) * (z > eL[2]) * float(spec.get("nose", 0.4))
        f = np.clip(f, 0, 1)[..., None] * skin_mask[..., None]
        out = out * (1 - f) + np.clip(out * red, 0, 1) * f
    return out


# ---- eyes --------------------------------------------------------------------------------------------
def eyes(tex, eye_mask, spec):
    """Make the iris read at talk distance: find the pupil in the eye island, scale the iris up
    (iris_scale), brighten / re-tone it, and paint a catchlight (upper left of the pupil)."""
    out = tex.copy()
    L = lum(tex)
    ys, xs = np.nonzero(eye_mask & (L < 0.12))
    if len(xs) < 4:
        return out, None
    cy, cx = ys.mean(), xs.mean()
    # iris radius: where the eye turns bright (sclera) going out from the pupil
    H, W = L.shape
    rad = None
    for r in range(4, 200):
        ring = [(int(cy + r * np.sin(a)), int(cx + r * np.cos(a))) for a in np.linspace(0, 2 * np.pi, 24, endpoint=False)]
        v = np.mean([L[min(max(p[0], 0), H - 1), min(max(p[1], 0), W - 1)] for p in ring])
        if v > 0.55:
            rad = r; break
    rad = rad or 30
    s = float(spec.get("iris_scale", 1.3))
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    d = np.hypot(yy - cy, xx - cx)
    R2 = rad * s
    inside = (d < R2 * 1.04) & eye_mask
    # sample the original iris at d / s inside the new radius (a radial zoom)
    src_y = cy + (yy - cy) / s; src_x = cx + (xx - cx) / s
    sy = np.clip(src_y.round().astype(int), 0, H - 1); sx = np.clip(src_x.round().astype(int), 0, W - 1)
    zoom = tex[sy, sx]
    edge = smoothstep(R2 * 1.04, R2 * 0.9, d)[..., None]
    out = np.where(inside[..., None], zoom * edge + out * (1 - edge), out)
    ir = (d > rad * s * 0.38) & (d < R2) & eye_mask
    if spec.get("iris"):
        tgt = hexrgb(spec["iris"])
        Lo = lum(out)
        ref = float(np.percentile(Lo[ir], 60)) if ir.any() else 0.4
        out[ir] = np.clip(tgt[None] * (Lo[ir] / max(ref, 1e-3))[:, None], 0, 1)
    out[ir] = np.clip(out[ir] * float(spec.get("iris_gain", 1.25)), 0, 1)
    # catchlight: a soft white dot up and to the side of the pupil
    cl = float(spec.get("catchlight", 0.9))
    hx, hy = cx - rad * s * 0.35, cy - rad * s * 0.38
    spot = np.exp(-(((xx - hx) ** 2 + (yy - hy) ** 2) / (rad * s * 0.13) ** 2)) * eye_mask
    out = out * (1 - spot[..., None] * cl) + np.array([1.0, 1.0, 0.98]) * spot[..., None] * cl
    return out, (cx / W, cy / H, R2 / W)
