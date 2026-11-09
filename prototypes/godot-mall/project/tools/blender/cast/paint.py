"""The person's three texture sets, painted from the 3D surface (flat, stylised: simplified tones,
no pores, no photo sources).

skin   2048  albedo (sRGB) / normal (OpenGL) / ORM (R occlusion, G roughness, B metal)
             head island (face-first, left 0.515 of the width), forearms / hands / neck, the eyes'
             iris disc, teeth and mouth swatches
clothes 1024 albedo / normal / ORM: one cell per garment (clothes.CELLS)
hair    512  albedo with alpha (shell strands on top, the lash strip in the bottom band) / normal
"""
import os

import numpy as np
from PIL import Image

import raster
from raster import smoothstep, hexrgb, fbm3, vnoise3, to8, height_to_normal

HERE = os.path.dirname(os.path.abspath(__file__))
import mh  # noqa: E402  (path set by person.py)

KIND_SKIN, KIND_EYE, KIND_TEETH, KIND_MOUTH = 0, 1, 2, 3
EYE_RECT = (0.53, 0.52, 0.2, 0.2)          # iris disc in the skin atlas (x, y, w, h)
TEETH_RECT = (0.76, 0.52, 0.05, 0.05)
MOUTH_RECT = (0.83, 0.52, 0.05, 0.05)

HAIR_CELLS = {"hair": (0.0, 0.0, 1.0, 0.75), "brows": (0.0, 0.75, 0.5, 0.25), "lashes": (0.5, 0.75, 0.5, 0.25)}
_MASKS = {}
_IMG = {}


def image(path, mode="RGB"):
    """A source texture (MakeHuman asset library) as float 0..1."""
    k = (path, mode)
    if k not in _IMG:
        _IMG[k] = np.asarray(Image.open(path).convert(mode), np.float32) / 255.0
    return _IMG[k]


def sample_img(img, uv):
    """Bilinear sample of an (H,W,C) image at image-coords uv (..,2), wrapping."""
    H, W = img.shape[:2]
    x = (uv[..., 0] % 1.0) * W - 0.5; y = (uv[..., 1] % 1.0) * H - 0.5
    x0 = np.floor(x).astype(int); y0 = np.floor(y).astype(int)
    fx = (x - x0)[..., None]; fy = (y - y0)[..., None]
    x0 %= W; y0 %= H; x1 = (x0 + 1) % W; y1 = (y0 + 1) % H
    return (img[y0, x0] * (1 - fx) * (1 - fy) + img[y0, x1] * fx * (1 - fy) +
            img[y1, x0] * (1 - fx) * fy + img[y1, x1] * fx * fy)


def lum(c):
    return c[..., 0] * 0.3 + c[..., 1] * 0.59 + c[..., 2] * 0.11


_CLEAN = {}


def uv_cover(cuv, H, W):
    """(H,W) bool: texels inside an asset's UV islands (cuv image coords)."""
    from PIL import ImageDraw
    im = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(im)
    for t in cuv:
        d.polygon([(float(u * W), float(v * H)) for u, v in t], fill=255)
    return np.asarray(im) > 0


def lowres_fill(a, w, n=64):
    """Masked average of a (H,W[,C]) over n x n blocks, upsampled bilinearly: fills holes of any size."""
    H, W = w.shape
    bh, bw = H // n, W // n
    a3 = a if a.ndim == 3 else a[..., None]
    num = (a3 * w[..., None]).reshape(n, bh, n, bw, -1).sum((1, 3))
    den = w.reshape(n, bh, n, bw).sum((1, 3))
    # spread into empty blocks from their neighbours
    small = num / np.maximum(den, 1e-6)[..., None]
    ok = den > 0
    for _ in range(n):
        if ok.all():
            break
        acc = np.zeros_like(small); cnt = np.zeros(ok.shape)
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            acc += np.roll(np.roll(small * ok[..., None], dy, 0), dx, 1); cnt += np.roll(np.roll(ok, dy, 0), dx, 1)
        grow = ~ok & (cnt > 0)
        small[grow] = acc[grow] / cnt[grow][:, None]; ok = ok | grow
    ys = (np.arange(H) + 0.5) / bh - 0.5; xs = (np.arange(W) + 0.5) / bw - 0.5
    y0 = np.clip(np.floor(ys).astype(int), 0, n - 1); y1 = np.clip(y0 + 1, 0, n - 1); fy = np.clip(ys - y0, 0, 1)[:, None, None]
    x0 = np.clip(np.floor(xs).astype(int), 0, n - 1); x1 = np.clip(x0 + 1, 0, n - 1); fx = np.clip(xs - x0, 0, 1)[None, :, None]
    out = (small[y0][:, x0] * (1 - fy) * (1 - fx) + small[y0][:, x1] * (1 - fy) * fx +
           small[y1][:, x0] * fy * (1 - fx) + small[y1][:, x1] * fy * fx)
    return out if a.ndim == 3 else out[..., 0]


def clean_top(path, rects=(), cuv=None):
    """A MakeHuman suit texture with the top's printed marks (logos, lettering) removed: texels much
    darker than a blurred copy of themselves (thin lines) take the blurred value; folds are broad and
    stay. The trousers are left alone."""
    key = (path, tuple(map(tuple, rects)))
    if key in _CLEAN:
        return _CLEAN[key]
    from PIL import ImageFilter
    im = Image.open(path).convert("RGB")
    a = np.asarray(im, np.float32) / 255
    b = np.asarray(im.filter(ImageFilter.GaussianBlur(14)), np.float32) / 255
    top = ~is_bottom(a)
    mark = top & ((lum(b) - lum(a) > 0.035) | ((a.max(-1) - a.min(-1)) > 0.12))
    from PIL import Image as I2
    mk = np.asarray(I2.fromarray((mark * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(5))) > 0
    mk &= top
    H, W = mk.shape
    for x0, y0, x1, y1 in rects:          # known prints (the data file's "paint_out", image coords)
        mk[int(y0 * H):int(y1 * H), int(x0 * W):int(x1 * W)] = True
    # fill the marks from the surrounding cloth: blur with the marks excluded
    isl = uv_cover(cuv, H, W) if cuv is not None else np.ones((H, W), bool)
    w = (~mk & top & isl).astype(np.float32)
    fill = lowres_fill(a, w)
    # feathered edge so the patch has no seam
    soft = np.asarray(I2.fromarray((mk * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(6)), np.float32) / 255
    soft = np.maximum(soft, mk * 1.0)[..., None]
    out = a * (1 - soft) + fill * soft
    # the mark mask rides along as a 4th channel (the AO and normal maps carry the print too)
    out = np.concatenate([out, mk[..., None].astype(np.float32)], -1)
    _CLEAN[key] = out
    return out


def clean_ao(path, rects, cuv=None):
    """The AO map with the paint-out rectangles filled from around them (prints are baked into it)."""
    key = ("ao", path, tuple(map(tuple, rects)))
    if key in _CLEAN:
        return _CLEAN[key]
    from PIL import ImageFilter
    im = Image.open(path).convert("L")
    a = np.asarray(im, np.float32) / 255
    H, W = a.shape
    mk = np.zeros((H, W), bool)
    for x0, y0, x1, y1 in rects:
        mk[int(y0 * H):int(y1 * H), int(x0 * W):int(x1 * W)] = True
    isl = uv_cover(cuv, H, W) if cuv is not None else np.ones((H, W), bool)
    fill = lowres_fill(a, ((~mk) & isl).astype(np.float32))
    soft = np.maximum(np.asarray(Image.fromarray((mk * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(6)), np.float32) / 255, mk * 1.0)
    out = (a * (1 - soft) + fill * soft)[..., None]
    _CLEAN[key] = out
    return out


def is_bottom(c):
    """Denim / trouser texels of a MakeHuman suit texture (blue over red), vs the top."""
    return (c[..., 2] - c[..., 0] > 0.05) & (lum(c) < 0.7)


def recolour(c, mask, target, ref=None):
    """Keep the texture's light and detail (its luminance relative to its own mean), take the target's
    colour: the tone adjustment used on every MakeHuman texture."""
    l = lum(c)
    m = float(np.mean(l[mask])) if ref is None else ref
    return target[None, None] * (l / max(m, 1e-3))[..., None]


def mask(name):
    if name not in _MASKS:
        _MASKS[name] = mh.mask(name)
    return _MASKS[name]


def sample(m, uv):
    """Bilinear sample of a (H,W) mask at image-coords uv (..,2)."""
    H, W = m.shape
    x = np.clip(uv[..., 0] * W - 0.5, 0, W - 1.001); y = np.clip(uv[..., 1] * H - 0.5, 0, H - 1.001)
    x0 = np.floor(x).astype(int); y0 = np.floor(y).astype(int)
    fx = x - x0; fy = y - y0
    return (m[y0, x0] * (1 - fx) * (1 - fy) + m[y0, x0 + 1] * fx * (1 - fy) +
            m[y0 + 1, x0] * (1 - fx) * fy + m[y0 + 1, x0 + 1] * fx * fy)


def mix(a, b, t):
    t = np.asarray(t)[..., None]
    return a * (1 - t) + b * t


def save(arr, path, mode="RGB"):
    Image.fromarray(to8(arr), mode).save(path, optimize=True)


# ---- skin -----------------------------------------------------------------------------------------
def paint_skin(P, hair, data, parts, size, out_prefix):
    """parts: list of dicts with cuv (m,3,2) atlas coords, pos/nrm (m,3,3), huv (m,3,2), kind (m,)."""
    cuv = np.concatenate([p["cuv"] for p in parts])
    A = np.concatenate([np.concatenate([p["pos"], p["nrm"], p["huv"], np.repeat(p["kind"][:, None, None], 3, 1).astype(float)], 2)
                        for p in parts])
    img, cov = raster.raster(cuv, A, size)
    pos, nrm, huv, kind = img[..., 0:3], img[..., 3:6], img[..., 6:8], np.rint(img[..., 8]).astype(int)
    sk = data.get("skin", {})
    tone = hexrgb(sk.get("tone", "#c89878"))
    col = np.broadcast_to(tone, pos.shape).copy()
    mhbase = sk.get("base")
    if mhbase:
        # MakeHuman's skin texture (hm08 UV) as the base, tone-matched: per-channel gain so the face's
        # mean colour becomes `tone`, keeping the texture's own variation
        import mhasset
        src = sample_img(image(mhasset.skin_texture(mhbase)), huv)
        facem = (kind == KIND_SKIN) & cov & (nrm[..., 2] > 0.5) & (pos[..., 1] > P.J["mixamorig_Neck"][1] + 0.05)
        gain = tone / np.maximum(src[facem].mean(0), 1e-3)
        col = np.clip(src * gain, 0, 1)
    J = P.J
    eL, eR = J["eye.L"], J["eye.R"]
    eyes = 0.5 * (eL + eR)
    mouth = P.v[P.b.verts_of("joint-mouth")].mean(0)
    dark = 1 - tone.mean()                       # 0 light .. ~0.75 very dark
    # broad tonal variation (warmer, redder centre of the face; cooler, darker jaw / neck under)
    if not mhbase:
        n = fbm3(pos, 9.0, 3)
        col *= (0.97 + 0.06 * n)[..., None]
    face = smoothstep(0.0, 0.5, nrm[..., 2]) * smoothstep(-0.13, -0.06, pos[..., 1] - eyes[1])
    red = hexrgb(sk.get("blush", "#d0605a"))
    cheekL = np.exp(-(((pos[..., 0] - (eL[0] + 0.004)) / 0.024) ** 2 + ((pos[..., 1] - (eL[1] - 0.038)) / 0.02) ** 2))
    cheekR = np.exp(-(((pos[..., 0] - (eR[0] - 0.004)) / 0.024) ** 2 + ((pos[..., 1] - (eR[1] - 0.038)) / 0.02) ** 2))
    nose = np.exp(-((pos[..., 0] / 0.012) ** 2 + ((pos[..., 1] - (eyes[1] - 0.04)) / 0.02) ** 2)) * smoothstep(0.03, 0.06, pos[..., 2] - eyes[2])
    ears = sample(mask("ears"), huv)
    flush = float(sk.get("flush", 0.25)) * (1 - dark)
    if mhbase:
        flush *= 0.4
    col = mix(col, col * red / red.max(), np.clip((cheekL + cheekR) * flush + nose * flush * 0.8 + ears * flush * 0.6, 0, 1) * face.clip(0.4, 1))
    # under-chin / under-jaw and neck a bit darker
    under = smoothstep(-0.1, -0.6, nrm[..., 1]) * 0.08
    col *= (1 - under)[..., None]
    # eye sockets: soft darkening around the lids
    lids = sample(mask("eyelids"), huv)
    sock = np.zeros(pos.shape[:2])
    for e in (eL, eR):
        d = ((pos[..., 0] - e[0]) / 0.024) ** 2 + ((pos[..., 1] - e[1] - 0.002) / 0.016) ** 2
        sock += np.exp(-d)
    if not mhbase:
        col *= (1 - float(sk.get("socket", 0.10)) * np.clip(sock, 0, 1) * face)[..., None]
        col = mix(col, col * np.array([0.92, 0.80, 0.80]), lids * 0.35)
    # lips
    lips = smoothstep(0.25, 0.6, sample(mask("lips"), huv))
    lipc = hexrgb(sk["lips"]) if "lips" in sk else tone * np.array([0.86, 0.62, 0.62]) * (1.0 - 0.25 * dark)
    # the lip line: darker where the lips meet (the mouth's horizontal centre line)
    lipline = np.exp(-((pos[..., 1] - mouth[1]) / 0.0018) ** 2) * np.exp(-(pos[..., 0] / 0.03) ** 6)
    col = mix(col, lipc, lips * (0.35 if mhbase else 0.9))
    col *= (1 - (0.0 if mhbase else 0.35) * lipline * smoothstep(0.0, 0.3, nrm[..., 2]))[..., None]
    inner = sample(mask("inside-mouth"), huv)
    col = mix(col, np.array([0.36, 0.13, 0.14]), smoothstep(0.3, 0.7, inner))
    # stubble / beard shadow (men)
    stub = float(sk.get("stubble", 0.0))
    if stub > 0:
        jaw = smoothstep(eyes[1] - 0.045, eyes[1] - 0.07, pos[..., 1]) * smoothstep(eyes[1] - 0.20, eyes[1] - 0.15, pos[..., 1])
        upper = np.exp(-((pos[..., 1] - (mouth[1] + 0.012)) / 0.007) ** 2) * np.exp(-(pos[..., 0] / 0.03) ** 4)

        b = np.clip(jaw + upper, 0, 1) * (1 - lips) * (1 - ears) * smoothstep(-0.03, 0.0, pos[..., 2] - eyes[2] + 0.11)
        b *= 0.75 + 0.25 * vnoise3(pos, 900)
        sc = hexrgb(sk.get("stubble_color", "#3a3028"))
        col = mix(col, col * sc / max(sc.max(), 0.2) * 0.85, b * stub)
    # freckles
    fr = float(sk.get("freckles", 0.0))
    if fr > 0:
        dots = smoothstep(0.78, 0.86, vnoise3(pos, 520.0)) * (0.5 + 0.5 * vnoise3(pos, 130.0))
        zone = np.exp(-((pos[..., 1] - (eyes[1] - 0.03)) / 0.035) ** 2) * smoothstep(0.0, 0.4, nrm[..., 2])
        zone = np.maximum(zone, smoothstep(0.2, 0.6, nrm[..., 1]) * 0.0 + (P.J["mixamorig_LeftArm"][1] - pos[..., 1] > 0.1) * 0.6 * (kind == KIND_SKIN) * (np.abs(pos[..., 0]) > 0.2))
        col = mix(col, col * np.array([0.78, 0.6, 0.48]), dots * zone * fr)
    # eyebrows
    br = dict(data.get("brows", {}))
    if br.get("asset"):
        # the brow card carries the hairs; paint only a soft tone under it (alpha-scissored cards thin out)
        br["density"] = float(br.get("under", 0.35)); br.setdefault("thick", 0.0042)
    bc = hexrgb(br.get("color", "#3a2a20"))
    brow = np.zeros(pos.shape[:2]); bstroke = np.zeros(pos.shape[:2])
    for e, sgn in ((eL, 1), (eR, -1)):
        dx = (pos[..., 0] - e[0]) * sgn + 0.004               # + outward
        t = np.clip((dx + 0.020) / 0.044, 0, 1)                # 0 inner .. 1 tail
        arch = float(br.get("arch", 0.004))
        yc = e[1] + float(br.get("height", 0.019)) + arch * np.sin(np.pi * t ** 0.8) - 0.004 * t ** 3
        th = float(br.get("thick", 0.0055)) * (1.15 - 0.6 * t ** 1.5)
        inside = smoothstep(0.0, 0.08, t) * smoothstep(1.0, 0.92, t) * (dx > -0.024)
        d = np.abs(pos[..., 1] - yc) / np.maximum(th, 1e-4)
        # soft edges, hair-stroke breakup (strokes lean outward and up), fading at both ends
        b = smoothstep(1.25, 0.35, d) * inside * smoothstep(0.1, 0.4, nrm[..., 2])
        strokes = 0.55 + 0.45 * smoothstep(0.35, 0.75, vnoise3(np.stack([pos[..., 0] * sgn * 2.0 - pos[..., 1] * 1.2, pos[..., 1] * 0.4, pos[..., 2]], -1), 2600))
        b *= 0.55 + 0.45 * smoothstep(0.0, 0.35, t) * smoothstep(1.0, 0.55, t) + 0.0
        brow = np.maximum(brow, b)
        bstroke = np.maximum(bstroke, b * strokes)
    col = mix(col, bc, np.clip(brow * float(br.get("density", 0.85)) * (0.8 + 0.2 * bstroke), 0, 1))
    # scalp hair (painted part of the cut)
    hd = np.zeros(pos.shape[:2])
    hcol = None
    if hair is not None:
        hcol = hexrgb(data["hair"].get("color", "#3a2a20"))
        hd = hair.paint_density(pos) * (1 - smoothstep(0.2, 0.5, ears)) * (kind == KIND_SKIN)
        hd *= float(data["hair"].get("scalp", 1.0))
        grain = 0.85 + 0.15 * vnoise3(pos * np.array([1, 0.25, 1]), 1400)
        col = mix(col, hcol * grain[..., None], np.clip(hd * float(data["hair"].get("paint", 0.92)), 0, 1))
    # palms and soles lighter on darker skin; fingernails
    palm = smoothstep(0.2, 0.7, -nrm[..., 0] * np.sign(pos[..., 0])) * (np.abs(pos[..., 0]) > 0.25) * (pos[..., 1] < J["mixamorig_LeftForeArm"][1] - 0.15)
    col = mix(col, np.clip(tone * 1.25 + 0.08, 0, 1), palm * 0.5 * dark)
    nails = smoothstep(0.3, 0.7, sample(mask("fingernails"), huv))
    col = mix(col, np.clip(tone * np.array([1.12, 1.0, 1.0]) + 0.12, 0, 1), nails * 0.7)
    # eyes / teeth / mouth swatches
    ex, ey, ew, eh = EYE_RECT
    lx = (np.arange(size)[None, :] + 0.5) / size; ly = (np.arange(size)[:, None] + 0.5) / size
    r = np.hypot((lx - (ex + ew / 2)) / (ew / 2), (ly - (ey + eh / 2)) / (eh / 2))
    ang = np.arctan2(ly - (ey + eh / 2), lx - (ex + ew / 2))
    iris_c = hexrgb(data.get("eyes", {}).get("iris", "#5a4030"))
    sclera = np.array([0.80, 0.77, 0.72])
    IR = 0.44
    ir_t = np.clip(r / IR, 0, 1)
    fib = 0.85 + 0.15 * np.sin(ang * 37 + 3 * np.sin(ang * 5)) * smoothstep(0.35, 0.6, ir_t)
    iris = iris_c * fib[..., None] * (0.75 + 0.35 * ir_t)[..., None]
    iris = mix(iris, iris_c * 1.35, smoothstep(0.55, 0.3, ir_t) * 0.35)
    eye = mix(sclera[None, None] * np.ones_like(col), iris, smoothstep(IR + 0.02, IR - 0.01, r))
    eye = mix(eye, np.array([0.12, 0.09, 0.08]), np.exp(-((r - IR) / 0.03) ** 2) * 0.8)   # limbal ring
    eye = mix(eye, np.array([0.02, 0.02, 0.02]), smoothstep(0.17, 0.14, r))
    eye = mix(eye, sclera * np.array([0.95, 0.85, 0.82]), smoothstep(0.75, 1.0, r) * 0.6)
    if data.get("eyes", {}).get("asset"):
        import mhasset
        eye = sample_img(image(mhasset.eye_texture(data["eyes"].get("texture", "brown_eye"))), huv)
        if data["eyes"].get("iris"):
            ic = hexrgb(data["eyes"]["iris"])
            sat = (eye.max(-1) - eye.min(-1)) > 0.12
            eye = np.where(sat[..., None], recolour(eye, sat & (kind == KIND_EYE), ic), eye)
        eye *= np.array([0.95, 0.93, 0.9])
    col = np.where((kind == KIND_EYE)[..., None], eye, col)
    col = np.where((kind == KIND_TEETH)[..., None], np.array([0.86, 0.83, 0.75]), col)
    col = np.where((kind == KIND_MOUTH)[..., None], np.array([0.40, 0.14, 0.15]), col)
    # ORM
    rough = np.full(pos.shape[:2], float(sk.get("rough", 0.72)))
    tz = np.exp(-((pos[..., 0] / 0.03) ** 2)) * face * 0.08
    rough -= tz
    rough = np.where(lips > 0.5, 0.42, rough)
    rough = np.where(hd > 0.5, 0.75, rough)
    rough = np.where(kind == KIND_EYE, 0.08, rough)
    rough = np.where(kind == KIND_TEETH, 0.3, rough)
    ao = 1 - 0.35 * smoothstep(0.3, 0.8, inner) - 0.15 * lids * 0
    orm = np.stack([ao, rough, np.zeros_like(rough)], -1)
    # normal: brow hairs, lip creases, hair grain (small)
    h = brow * bstroke * 0.15 + hd * 0.12 * vnoise3(pos * np.array([1, 0.2, 1]), 2500)
    nm = height_to_normal(h, 0.6)
    col, cov2 = raster.dilate(col, cov, 6)
    orm, _ = raster.dilate(orm, cov, 6)
    nm, _ = raster.dilate(nm, cov, 6)
    col[~cov2] = tone; orm[~cov2] = [1, 0.6, 0]; nm[~cov2] = [0.5, 0.5, 1]
    save(col, out_prefix + "_skin_albedo.png")
    save(orm, out_prefix + "_skin_orm.png")
    save(nm, out_prefix + "_skin_normal.png")
    return {"coverage": float(cov.mean())}


# ---- clothes --------------------------------------------------------------------------------------
def paint_clothes(P, data, parts, size, out_prefix):
    """parts: dicts with cuv (m,3,2) atlas coords, pos/nrm (m,3,3), and g (the garment spec), cell."""
    specs = []
    cuvs, attrs = [], []
    for i, p in enumerate(parts):
        specs.append(p["spec"])
        m = len(p["cuv"])
        local = p.get("luv")
        if local is None:
            local = np.zeros((m, 3, 2))
        a = np.concatenate([p["pos"], p["nrm"], local, np.full((m, 3, 1), float(i))], 2)
        cuvs.append(p["cuv"]); attrs.append(a)
    img, cov = raster.raster(np.concatenate(cuvs), np.concatenate(attrs), size)
    pos, nrm, luv, pid = img[..., 0:3], img[..., 3:6], img[..., 6:8], np.rint(img[..., 8]).astype(int)
    col = np.zeros(pos.shape); rough = np.full(pos.shape[:2], 0.8); metal = np.zeros(pos.shape[:2])
    height = np.zeros(pos.shape[:2])
    mhn = np.zeros(pos.shape); usen = np.zeros(pos.shape[:2], bool)
    J = P.J
    for i, g in enumerate(specs):
        m = (pid == i) & cov
        if not m.any():
            continue
        base = hexrgb(g.get("color", "#808080"))
        x, y, z = pos[..., 0], pos[..., 1], pos[..., 2]
        t = g["type"]
        c = np.broadcast_to(base, pos.shape).copy()
        weave = vnoise3(pos, 2200) - 0.5
        hgt = weave * 0.15
        r = np.full(pos.shape[:2], float(g.get("rough", 0.82)))
        if t in ("shirt", "polo", "tee"):
            # side and shoulder seams, folds at the waist and elbows (in the normal only)
            folds = fbm3(pos * np.array([3, 1, 3]), 25, 2) - 0.5
            hgt += folds * 1.2
            seam = np.exp(-((np.abs(x) - (np.abs(J["mixamorig_LeftArm"][0]) - 0.035)) / 0.002) ** 2) * (y > J["mixamorig_Spine2"][1])
            if t == "shirt":
                pl = (np.abs(x) < 0.017) & (z > 0) & (y > J["mixamorig_Hips"][1] - 0.1)
                edge = np.exp(-((np.abs(x) - 0.017) / 0.0012) ** 2) * (z > 0)
                c = mix(c, c * 1.02, pl * 1.0)
                hgt -= edge * 0.8
                by = (y - (J["mixamorig_Neck"][1] - 0.03)) / 0.09
                btn = np.exp(-((x / 0.0045) ** 2 + ((by - np.round(by)) * 0.09 / 0.0045) ** 2)) * (z > 0) * (by < 0.3)
                c = mix(c, base * 0.86, smoothstep(0.4, 0.7, btn))
                hgt += btn * 1.5
                if g.get("pocket"):
                    px0 = 0.085 if g.get("pocket") != "right" else -0.085
                    py = J["mixamorig_Spine2"][1] + 0.02
                    pk = (np.abs(x - px0) < 0.055) & (np.abs(y - py) < 0.06) & (z > 0)
                    pe = pk & ((np.abs(np.abs(x - px0) - 0.055) < 0.0015) | (np.abs(y - py - 0.06) < 0.0015) | (np.abs(y - py + 0.06) < 0.0015))
                    hgt += pe * 1.0
                    c = mix(c, c * 0.97, pe)
            if t == "polo":
                pl = (np.abs(x) < 0.016) & (z > 0) & (y > J["mixamorig_Neck"][1] - 0.15)
                edge = np.exp(-((np.abs(x) - 0.016) / 0.0012) ** 2) * (z > 0) * (y > J["mixamorig_Neck"][1] - 0.15)
                hgt -= edge
                for k in range(2):
                    by = J["mixamorig_Neck"][1] - 0.04 - 0.05 * k
                    btn = np.exp(-((x / 0.004) ** 2 + ((y - by) / 0.004) ** 2)) * (z > 0)
                    c = mix(c, base * 0.75 + 0.15, smoothstep(0.4, 0.7, btn))
                hgt += 0.25 * np.sin((x * 1400 + y * 200)) * 0.3        # knit
            hgt += seam * 0.8
            c = mix(c, c * 0.93, seam)
        elif t == "mh":
            import mhasset
            a = mhasset.Asset(g["asset"])
            if g.get("role") == "top":
                ct = sample_img(clean_top(a.texture(), g.get("paint_out", ()), a.cuv), luv)
                src, printed = ct[..., :3], ct[..., 3] > 0.1
            else:
                src, printed = sample_img(image(a.texture()), luv), np.zeros(pos.shape[:2], bool)
            nmp = a.texture("normalmapTexture")
            aop = a.texture("aomapTexture")
            if g.get("role") == "top":
                bt = is_bottom(src) & m
                tp = ~is_bottom(src) & m
                c = src.copy()
                if g.get("bottom_color"):
                    # plain trousers from the jeans: the target colour, the denim's detail flattened
                    l = lum(src); mb = float(np.mean(l[bt])) if bt.any() else 0.3
                    lf = mb + (l - mb) * float(g.get("bottom_detail", 0.4))
                    c = np.where(bt[..., None], hexrgb(g["bottom_color"])[None, None] * (lf / max(mb, 1e-3))[..., None], c)
                topc = hexrgb(g.get("color", "#f0f0ea"))
                # the top: its own light and folds, the person's colour; printed logos painted out
                logo = tp & ((src.max(-1) - src.min(-1)) > 0.12)
                tl = np.where(logo, np.median(lum(src)[tp & ~logo]) if (tp & ~logo).any() else 0.8, lum(src))
                tref = np.percentile(tl[tp], 70) if tp.any() else 1.0
                c = np.where(tp[..., None], topc[None, None] * np.clip(tl / max(tref, 1e-3), 0, 1.15)[..., None], c)
                if g.get("placket"):
                    pl = tp & (np.abs(x) < 0.016) & (z > 0) & (y > J["mixamorig_Hips"][1] + 0.05)
                    edge = tp & (np.abs(np.abs(x) - 0.016) < 0.0015) & (z > 0) & (y > J["mixamorig_Hips"][1] + 0.05)
                    c = np.where(edge[..., None], c * 0.86, c)
                    by = (y - (J["mixamorig_Neck"][1] - 0.03)) / 0.09
                    btn = np.exp(-((x / 0.0045) ** 2 + ((by - np.round(by)) * 0.09 / 0.0045) ** 2)) * pl
                    c = mix(c, topc * 0.8, smoothstep(0.4, 0.7, btn))
            else:
                c = recolour(src, m, hexrgb(g["color"])) if g.get("color") else src
            if nmp:
                srcn = np.where(printed[..., None], np.array([0.5, 0.5, 1.0]), sample_img(image(nmp), luv))
            if aop:
                ao = sample_img(clean_ao(aop, g.get("paint_out", ()), a.cuv) if g.get("role") == "top" else image(aop, "L")[..., None], luv)[..., 0]
                c = c * (0.55 + 0.45 * ao)[..., None]
            r = np.full(pos.shape[:2], float(g.get("rough", 0.85)))
            col[m] = c[m]; rough[m] = r[m]
            if nmp:
                mhn[m] = srcn[m]; usen[m] = True
            continue
        elif t == "trousers":
            for side in (1, -1):
                K = J["mixamorig_LeftLeg" if side > 0 else "mixamorig_RightLeg"]
                crease = np.exp(-((x - K[0]) / 0.002) ** 2) * (z > K[2]) * (np.sign(x) == side)
                hgt += crease * 1.5
                c = mix(c, c * 1.07, crease * 0.5)
                # slanted front pocket openings
                Hy = J["mixamorig_Hips"][1]
                pk = np.abs((np.abs(x) - 0.11) - (y - Hy - 0.02) * 0.45) < 0.0016
                pk &= (y > Hy - 0.07) & (y < Hy + 0.04) & (z > 0) & (np.sign(x) == side)
                hgt -= pk * 1.0
                c = mix(c, c * 0.8, pk * 0.8)
            fly = (np.abs(x - 0.012) < 0.0012) & (z > 0) & (y > J["mixamorig_Hips"][1] - 0.13) & (y < J["mixamorig_Hips"][1] + 0.05)
            hgt -= fly * 0.8
            folds = fbm3(pos * np.array([3, 1.5, 3]), 22, 2) - 0.5
            hgt += folds * 1.0
        elif t == "shoes":
            sole = y < 0.022
            c = mix(c, hexrgb(g.get("sole", "#1a1a1a")), sole * 1.0)
            lace = (np.abs(x - np.sign(x) * np.abs(J["mixamorig_LeftFoot"][0])) < 0.015) & (z > J["mixamorig_LeftFoot"][2] + 0.02) & (y > 0.05)
            hgt += lace * np.sin(z * 900) * 0.5
            r = np.where(sole, 0.9, float(g.get("rough", 0.45)))
        elif t == "belt":
            buckle = (np.abs(x) < 0.025) & (z > 0)
            c = mix(c, np.array([0.62, 0.6, 0.55]), buckle * 1.0)
            metal = np.where(m & buckle, 0.7, metal)
            r = np.where(buckle, 0.35, 0.55)
        elif t == "tie":
            if g.get("pattern") == "stripe":
                s = np.sin((luv[..., 0] * 0.6 + luv[..., 1]) * 60) > 0.75
                c = mix(c, hexrgb(g.get("stripe", "#8a2830")), s * 1.0)
            r = np.full(pos.shape[:2], 0.55)
        elif t == "nametag":
            border = (luv[..., 0] < 0.16) | (luv[..., 0] > 0.84) | (luv[..., 1] < 0.18) | (luv[..., 1] > 0.82)
            c = mix(c, hexrgb(g.get("border", "#b8b8b8")), border * 1.0)
            r = np.full(pos.shape[:2], 0.35)
        elif t in ("visor", "cap"):
            brim_under = luv[..., 1] > 0.55
            c = mix(c, c * 0.85, brim_under * 0.0)
            hgt += np.sin(luv[..., 0] * 300) * 0.2
        elif t == "collar":
            st = np.exp(-((luv[..., 1] - 0.9) / 0.01) ** 2)
            hgt -= st * 0.5
        col[m] = c[m]; rough[m] = r[m]; height[m] = hgt[m]
    nm = height_to_normal(height, 0.8)
    nm = np.where(usen[..., None], mhn, nm)
    orm = np.stack([np.ones_like(rough), rough, metal], -1)
    col, cov2 = raster.dilate(col, cov, 6)
    orm, _ = raster.dilate(orm, cov, 6)
    nm, _ = raster.dilate(nm, cov, 6)
    col[~cov2] = 0.5; orm[~cov2] = [1, 0.8, 0]; nm[~cov2] = [0.5, 0.5, 1]
    save(col, out_prefix + "_clothes_albedo.png")
    save(orm, out_prefix + "_clothes_orm.png")
    save(nm, out_prefix + "_clothes_normal.png")


# ---- hair -----------------------------------------------------------------------------------------
HAIR_SHELL = (0.0, 0.0, 1.0, 0.75)
HAIR_LASH = (0.0, 0.8, 1.0, 0.2)


def paint_hair_assets(data, parts, size, out_prefix):
    """MakeHuman hair / brows / lashes textures (RGBA), recoloured to the person's colours."""
    import mhasset
    cuvs = np.concatenate([p["cuv"] for p in parts])
    A = np.concatenate([np.concatenate([p["luv"], np.full(p["luv"].shape[:2] + (1,), float(i))], 2) for i, p in enumerate(parts)])
    img, cov = raster.raster(cuvs, A, size)
    luv, pid = img[..., 0:2], np.rint(img[..., 2]).astype(int)
    col = np.zeros((size, size, 3)); alpha = np.zeros((size, size)); nrm = np.zeros((size, size, 3)) + [0.5, 0.5, 1]
    for i, p in enumerate(parts):
        m = (pid == i) & cov
        if not m.any():
            continue
        a = mhasset.Asset(p["asset"])
        src = sample_img(image(a.texture(), "RGBA"), luv)
        key = p["key"]
        target = hexrgb(data.get(key, {}).get("color", data.get("hair", {}).get("color", "#3a2a20")))
        if key == "lashes":
            target = hexrgb(data.get("lashes", {}).get("color", "#1c1612"))
        opaque = m & (src[..., 3] > 0.5)
        c = recolour(src[..., :3], opaque if opaque.any() else m, target)
        col[m] = np.clip(c[m], 0, 1); alpha[m] = src[..., 3][m]
        nmp = a.texture("normalmapTexture")
        if nmp:
            nrm[m] = sample_img(image(nmp), luv)[m]
    col, cov2 = raster.dilate(col, cov, 4)
    rgba = np.concatenate([col, alpha[..., None]], -1)
    Image.fromarray(to8(rgba), "RGBA").save(out_prefix + "_hair_albedo.png", optimize=True)
    save(nrm, out_prefix + "_hair_normal.png")


def paint_hair(data, size, out_prefix):
    h = data.get("hair", {})
    base = hexrgb(h.get("color", "#3a2a20"))
    curl = float(h.get("curl", 0.0))
    W = size
    x = (np.arange(W)[None, :] + 0.5) / W
    y = (np.arange(W)[:, None] + 0.5) / W
    X = np.broadcast_to(x, (W, W)); Y = np.broadcast_to(y, (W, W))
    # strands: periodic in x (the shell's UV wraps around the head)
    p3 = np.stack([np.cos(2 * np.pi * X) * 6, np.sin(2 * np.pi * X) * 6, Y * (2 if curl < 0.5 else 30)], -1)
    s = vnoise3(p3, 9.0 if curl < 0.5 else 6.0)
    s2 = vnoise3(p3 * np.array([1, 1, 0.5]), 23.0)
    strand = 0.6 * s + 0.4 * s2
    if curl >= 0.5:
        coil = vnoise3(np.stack([np.cos(2 * np.pi * X) * 40, np.sin(2 * np.pi * X) * 40, Y * 40], -1), 1.0)
        strand = 0.5 * strand + 0.5 * coil
    col = base[None, None] * (0.72 + 0.3 * strand)[..., None]
    alpha = np.ones((W, W))
    if h.get("part_az") is not None:
        # the part as a thin line of scalp in the shell's lat-long UV (u = azimuth, v = elevation)
        up = float(h["part_az"]) / 360 + 0.5
        el = 70 - (Y / HAIR_SHELL[3]) * 140
        line = np.exp(-((X - up) / 0.0035) ** 2) * (el > 30) * (el < 66) * (Y < HAIR_SHELL[3])
        scalp = hexrgb(data.get("skin", {}).get("tone", "#c89878")) * 0.85
        col = mix(col, scalp, line * 0.8)
    if h.get("sweep"):
        # strands across the top (swept from the part): darker gaps across u near the crown
        pass
    nh = strand
    # lash band: one strip of lashes, root at the top of the band, alpha
    ly0 = int(HAIR_LASH[1] * W)
    band = (Y >= HAIR_LASH[1])
    v = (Y - HAIR_LASH[1]) / HAIR_LASH[3]
    # thin, sparse lashes, shorter toward the strip's ends (each lash strip maps u 0..1)
    ends = np.clip(np.minimum(X, 1 - X) / 0.2, 0, 1)
    lash = (np.abs(np.sin(X * np.pi * 34)) ** 14 > 0.35 + 0.65 * v) & (v < 0.25 + 0.4 * ends)
    lc = hexrgb(data.get("lashes", h.get("lash_color", "#1a1410")))
    col = np.where(band[..., None], lc, col)
    alpha = np.where(band, (lash & (v < 0.95)).astype(float), alpha)
    alpha[int(0.75 * W):ly0] = 0
    rgba = np.concatenate([col, alpha[..., None]], -1)
    Image.fromarray(to8(rgba), "RGBA").save(out_prefix + "_hair_albedo.png", optimize=True)
    save(height_to_normal(nh * 1.2, 1.0), out_prefix + "_hair_normal.png")
