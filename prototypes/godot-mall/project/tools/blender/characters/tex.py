"""Textures for the character bodies, painted with numpy on hm08's UV atlas (no photo sources).

skin_albedo.png  2048  near-white skin with RELATIVE colour only (lips, cheeks, knuckles, palms,
                       nails, areolae, brows): the material's tint is the skin tone, so one map
                       serves every tone from very light to very dark (manifest "skin_tones").
skin_normal.png  2048  tangent-space (OpenGL, +Y up) pores and fine creases.
skin_orm.png     1024  R occlusion (creases), G roughness (oily T-zone, lips, nails), B metal 0.
skin_wrinkle.png 2048  extra normal detail for age (forehead lines, crow's feet, nasolabial folds,
                       neck rings, hands), blended by the 'age' slider in scripts/char_skin.gdshader.
eye_albedo.png   512   sclera + a grey iris (tinted by the iris material) + pupil.
lash_albedo.png  256x64 one lash strip with alpha (root at v = 0).

Every texel of the skin maps to a point on the base body (rasterised from the UV triangles), so
the procedural detail is laid out in 3D (no stretching across UV islands) and islands are padded.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import mh  # noqa: E402

OUT = os.path.join(mh.PROJ, "models", "characters")


def raster(base, coords, size):
    """Per texel: 3D position, normal and a coverage mask, from the body's UV triangles."""
    from body import quads_to_tris, vertex_normals
    fi = base.faces_of("body")
    q = base.f[fi]; qu = base.fuv[fi]
    tris = quads_to_tris(q); tuv = quads_to_tris(qu)
    vn = vertex_normals(coords, tris)
    P = np.zeros((size, size, 3), np.float32)
    N = np.zeros((size, size, 3), np.float32)
    M = np.zeros((size, size), bool)
    uv = base.uv[tuv] * size            # (T,3,2) in pixels, v up
    uv[..., 1] = size - uv[..., 1]
    for t in range(len(tris)):
        a, b, c = uv[t]
        x0, y0 = np.floor(np.minimum(np.minimum(a, b), c)).astype(int)
        x1, y1 = np.ceil(np.maximum(np.maximum(a, b), c)).astype(int)
        x0, y0 = max(x0, 0), max(y0, 0); x1, y1 = min(x1, size - 1), min(y1, size - 1)
        if x1 < x0 or y1 < y0:
            continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        v0 = b - a; v1 = c - a
        den = v0[0] * v1[1] - v1[0] * v0[1]
        if abs(den) < 1e-12:
            continue
        px = xs - a[0]; py = ys - a[1]
        l1 = (px * v1[1] - v1[0] * py) / den
        l2 = (v0[0] * py - px * v0[1]) / den
        l0 = 1 - l1 - l2
        ins = (l0 >= -0.02) & (l1 >= -0.02) & (l2 >= -0.02)
        if not ins.any():
            continue
        iy, ix = ys[ins].astype(int), xs[ins].astype(int)
        w = np.stack([l0[ins], l1[ins], l2[ins]], 1)
        vt = coords[tris[t]]; nt = vn[tris[t]]
        P[iy, ix] = w @ vt
        N[iy, ix] = w @ nt
        M[iy, ix] = True
    return P, N, M


def noise3(P, freq, seed=0, octaves=3):
    """Cheap value noise in 3D (trilinear lattice), summed octaves, ~0..1."""
    rng = np.random.default_rng(seed)
    tab = rng.random(4096).astype(np.float32)
    out = np.zeros(P.shape[:-1], np.float32)
    amp, tot = 1.0, 0.0
    for o in range(octaves):
        p = P * freq * (2 ** o) + o * 17.3
        i = np.floor(p).astype(np.int64)
        f = p - i
        f = f * f * (3 - 2 * f)
        def h(dx, dy, dz):
            k = (i[..., 0] + dx) * 73856093 ^ (i[..., 1] + dy) * 19349663 ^ (i[..., 2] + dz) * 83492791
            return tab[k % 4096]
        x00 = h(0, 0, 0) * (1 - f[..., 0]) + h(1, 0, 0) * f[..., 0]
        x10 = h(0, 1, 0) * (1 - f[..., 0]) + h(1, 1, 0) * f[..., 0]
        x01 = h(0, 0, 1) * (1 - f[..., 0]) + h(1, 0, 1) * f[..., 0]
        x11 = h(0, 1, 1) * (1 - f[..., 0]) + h(1, 1, 1) * f[..., 0]
        y0 = x00 * (1 - f[..., 1]) + x10 * f[..., 1]
        y1 = x01 * (1 - f[..., 1]) + x11 * f[..., 1]
        out += amp * (y0 * (1 - f[..., 2]) + y1 * f[..., 2])
        tot += amp
        amp *= 0.5
    return out / tot


def pad(img, mask, n=8):
    """Grow island colours outward n px (no dark seams after mip-mapping)."""
    img = img.copy(); m = mask.copy()
    for _ in range(n):
        acc = np.zeros_like(img); cnt = np.zeros(m.shape, np.float32)
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            sm = np.roll(m, (dy, dx), (0, 1))
            si = np.roll(img, (dy, dx), (0, 1))
            acc += si * sm[..., None]; cnt += sm
        grow = (~m) & (cnt > 0)
        img[grow] = acc[grow] / cnt[grow][:, None]
        m = m | grow
    return img


def height_to_normal(h, strength, mask):
    gy, gx = np.gradient(h)
    n = np.stack([-gx * strength, gy * strength, np.ones_like(h)], -1)   # OpenGL: +Y up in the image
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    n[~mask] = [0, 0, 1]
    return n


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def ball(P, c, r):
    return np.clip(1 - np.linalg.norm(P - c, axis=-1) / r, 0, 1)


def skin(body, size=2048):
    b = body.b
    P, N, M = raster(b, body.v0, size)
    J = body.J0
    def resize(mk):
        return np.asarray(Image.fromarray((mk * 255).astype(np.uint8)).resize((size, size), Image.BILINEAR), np.float32) / 255
    lips = resize(mh.mask("lips")); nails = np.maximum(resize(mh.mask("fingernails")), resize(mh.mask("toenails")))
    areo = resize(mh.mask("aureolae")); ears = resize(mh.mask("ears")); lids = resize(mh.mask("eyelids"))
    mouth_in = resize(mh.mask("inside-mouth"))
    eye_l = body.v0[b.verts_of("helper-l-eye")].mean(0); eye_r = body.v0[b.verts_of("helper-r-eye")].mean(0)
    head = J["mixamorig_Head"]
    # landmarks
    nose_tip = body.v0[:mh.N_BODY][np.argmax(np.where(body.v0[:mh.N_BODY, 1] > head[1] - 0.02, body.v0[:mh.N_BODY, 2], -9))]
    mouth = (body.v0[b.verts_of("joint-mouth")]).mean(0)
    chin_y = mouth[1] - 0.045
    base = np.ones((size, size, 3), np.float32) * np.array([0.96, 0.90, 0.86], np.float32)
    n1 = noise3(P, 9.0, 1, 3)
    n2 = noise3(P, 60.0, 2, 2)
    blotch = (n1 - 0.5) * 0.10 + (n2 - 0.5) * 0.04
    base *= (1 + blotch[..., None])
    red = np.array([1.0, 0.78, 0.74], np.float32)
    def tint(mk, col, k):
        nonlocal base
        base = base * (1 - mk[..., None] * k) + base * np.array(col, np.float32) * mk[..., None] * k
    # flush: cheeks, nose, ears, knuckles, elbows, knees, lips
    cheek = ball(P, eye_l + [0.012, -0.035, 0.0], 0.045) + ball(P, eye_r + [-0.012, -0.035, 0.0], 0.045)
    tint(np.clip(cheek, 0, 1) * 0.8, red, 0.35)
    tint(ball(P, nose_tip, 0.03), red, 0.30)
    tint(ears, red, 0.25)
    for s in ("Left", "Right"):
        tint(ball(P, J["mixamorig_%sForeArm" % s], 0.05), red, 0.18)
        tint(ball(P, J["mixamorig_%sLeg" % s], 0.07), red, 0.15)
        for f in ("Index", "Middle", "Ring", "Pinky"):
            for k in (1, 2):
                tint(ball(P, J["mixamorig_%sHand%s%d" % (s, f, k)], 0.012), red, 0.25)
    tint(lips, [0.86, 0.52, 0.52], 0.85)
    tint(mouth_in, [0.75, 0.30, 0.30], 1.0)
    tint(areo, [0.70, 0.48, 0.42], 0.85)
    tint(lids, [0.92, 0.80, 0.78], 0.6)
    # palms and soles are lighter (strongly so on deep tones; the tint multiplies)
    palm = np.zeros((size, size), np.float32)
    for s in ("Left", "Right"):
        hand = J["mixamorig_%sHand" % s]
        palm += ball(P, hand, 0.11) * smoothstep(0.2, 0.7, -N[..., 1] * 0.5 + (np.sign(hand[0]) * -N[..., 0]) * 0.6)
        foot = J["mixamorig_%sFoot" % s]
        palm += smoothstep(0.03, 0.005, P[..., 1]) * ball(P, foot * [1, 0, 1], 0.2)
    palm = np.clip(palm, 0, 1)
    base = base * (1 - palm[..., None] * 0.35) + np.array([1.25, 1.12, 1.05], np.float32) * base * palm[..., None] * 0.35
    tint(nails, [1.15, 1.0, 0.98], 0.8)
    # brows (darken: the tint keeps them in the skin's own family; the face pass paints real brows)
    for e, sx in ((eye_l, 1), (eye_r, -1)):
        d = P - (e + [0.004 * sx, 0.022, 0.006])
        brow = np.exp(-(d[..., 0] / 0.024) ** 2 - (d[..., 1] / 0.0055) ** 2 - (d[..., 2] / 0.03) ** 2)
        brow *= 0.6 + 0.4 * noise3(P, 300.0, 5, 1)
        tint(np.clip(brow, 0, 1), [0.35, 0.28, 0.25], 0.75)
    base = np.clip(base, 0, 1)
    base = pad(base, M, 10)
    # pores / fine creases (normal) and roughness
    face = smoothstep(head[1] - 0.10, head[1] - 0.02, P[..., 1])
    pores = noise3(P, 1400.0, 7, 2) * (0.5 + 0.5 * face) + noise3(P, 420.0, 8, 2) * 0.15
    hN = height_to_normal(pores - pores.mean(), 0.9, M)
    rough = 0.72 + (noise3(P, 30.0, 9, 2) - 0.5) * 0.08
    tz = ball(P, nose_tip, 0.04) + ball(P, (eye_l + eye_r) / 2 + [0, 0.05, 0.0], 0.04)
    rough = rough - np.clip(tz, 0, 1) * 0.10 - lips * 0.15 - nails * 0.30 - mouth_in * 0.25
    ao = 1 - np.clip(mouth_in * 0.5, 0, 1)
    # wrinkles (age)
    wr = np.zeros((size, size), np.float32)
    brow_mid = (eye_l + eye_r) / 2
    fh = smoothstep(brow_mid[1] + 0.025, brow_mid[1] + 0.035, P[..., 1]) * smoothstep(brow_mid[1] + 0.085, brow_mid[1] + 0.06, P[..., 1])
    fh *= smoothstep(0.06, 0.03, np.abs(P[..., 0])) * (N[..., 2] > 0.3)
    wr += fh * np.sin((P[..., 1] - brow_mid[1]) * 2 * np.pi / 0.011 + noise3(P, 40, 11, 1) * 3) * 0.8
    for e, sx in ((eye_l, 1), (eye_r, -1)):
        c = e + [0.024 * sx, -0.002, -0.012]
        d = P - c
        ang = np.arctan2(d[..., 1], d[..., 0] * sx)
        rr = np.linalg.norm(d, axis=-1)
        crow = smoothstep(0.03, 0.008, rr) * smoothstep(0.004, 0.008, rr)
        wr += crow * np.sin(ang * 9 + noise3(P, 80, 12, 1) * 2) * 0.7
        bag = np.exp(-((P[..., 0] - e[0]) / 0.018) ** 2 - ((P[..., 1] - e[1] + 0.017) / 0.005) ** 2) * (N[..., 2] > 0.2)
        wr += bag * 0.8
    for sx in (1, -1):
        # nasolabial fold: from beside the nostril to past the mouth corner
        a = nose_tip + [0.018 * sx, -0.012, -0.012]; c = mouth + [0.03 * sx, -0.012, -0.004]
        ab = c - a; t = np.clip(((P - a) @ ab) / (ab @ ab), 0, 1)
        dist = np.linalg.norm(P - (a + t[..., None] * ab), axis=-1)
        wr += np.exp(-(dist / 0.0035) ** 2) * (N[..., 2] > 0.1) * 1.0
    neck = J["mixamorig_Neck"]
    nk = smoothstep(neck[1] - 0.03, neck[1], P[..., 1]) * smoothstep(chin_y - 0.0, chin_y - 0.04, P[..., 1]) * (N[..., 2] > 0)
    wr += nk * np.sin(P[..., 1] * 2 * np.pi / 0.018) * 0.6
    for s in ("Left", "Right"):
        wr += ball(P, J["mixamorig_%sHand" % s], 0.07) * np.sin(noise3(P, 150, 13, 2) * 30) * 0.5
    wN = height_to_normal(wr * 0.004 * size / 2048 * 100, 1.0, M)
    def save(a, name, sz=None):
        im = Image.fromarray(np.clip(a * 255 + 0.5, 0, 255).astype(np.uint8))
        if sz:
            im = im.resize((sz, sz), Image.LANCZOS)
        im.save(os.path.join(OUT, name), optimize=True)
    save(base ** (1 / 1.0), "skin_albedo.png")
    save(hN * 0.5 + 0.5, "skin_normal.png")
    save(wN * 0.5 + 0.5, "skin_wrinkle.png")
    orm = np.stack([pad(np.stack([ao] * 3, -1), M, 6)[..., 0], pad(np.stack([rough] * 3, -1), M, 6)[..., 0], np.zeros_like(ao)], -1)
    save(orm, "skin_orm.png", 1024)


def eye(size=512):
    y, x = np.mgrid[0:size, 0:size] / size * 2 - 1
    y = -y
    r = np.sqrt(x * x + y * y)                    # sphere front projection: r = sin(angle from +Z)
    ang = np.arcsin(np.clip(r, 0, 1))
    img = np.ones((size, size, 3), np.float32) * [0.93, 0.92, 0.90]
    th = np.arctan2(y, x)
    veins = (np.sin(th * 23 + np.sin(th * 7) * 2) > 0.97) * smoothstep(0.65, 1.0, r) * 0.25
    img -= veins[..., None] * np.array([0.0, 0.5, 0.5])
    iris_r = np.sin(0.62)
    ir = r / iris_r
    rng = np.random.default_rng(3)
    fib = sum(np.sin(th * k + rng.random() * 6) * rng.random() for k in (37, 53, 71, 97)) / 2
    iris = 0.55 + 0.25 * fib * smoothstep(0.3, 0.6, ir) - 0.25 * smoothstep(0.75, 1.0, ir) + 0.15 * smoothstep(0.55, 0.3, ir)
    iris = np.clip(iris, 0, 1)
    m = ir < 1.0
    img[m] = np.stack([iris] * 3, -1)[m]
    img[ir < 0.33] = [0.02, 0.02, 0.02]
    ring = smoothstep(0.92, 1.0, ir) * smoothstep(1.08, 1.0, ir)
    img *= (1 - ring * 0.5)[..., None]
    Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8)).save(os.path.join(OUT, "eye_albedo.png"), optimize=True)


def lash(w=256, h=64):
    img = np.zeros((h, w, 4), np.float32)
    img[..., :3] = 0.08
    rng = np.random.default_rng(4)
    yy, xx = np.mgrid[0:h, 0:w]
    a = np.zeros((h, w), np.float32)
    for i in range(70):
        x0 = rng.random() * w
        L = h * (0.55 + 0.45 * rng.random()) * (0.6 + 0.4 * np.sin(np.pi * x0 / w))
        curve = (rng.random() - 0.5) * 10
        t = yy / max(L, 1)
        xc = x0 + curve * t * t
        width = 1.6 * (1 - t)
        a = np.maximum(a, ((np.abs(xx - xc) < width) & (t < 1)).astype(np.float32))
    img[..., 3] = a
    Image.fromarray((img * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "lash_albedo.png"), optimize=True)


if __name__ == "__main__":
    import time
    from body import Body
    t = time.time()
    os.makedirs(OUT, exist_ok=True)
    B = Body("female")
    skin(B, int(sys.argv[1]) if len(sys.argv) > 1 else 2048)
    eye(); lash()
    print("TEX OK %.1fs" % (time.time() - t))
