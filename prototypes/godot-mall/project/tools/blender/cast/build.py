"""Build one cast member: tools/blender/cast/<id>.json -> cast/<id>.glb (+ textures, + cast/<id>.json).

    python3 tools/blender/cast/build.py <id> [--full]     (numpy + PIL; the LOD maps need Blender once:
    /home/claude/bvenv/bin/python tools/blender/cast/skinmap.py)

The .glb (design/godot-cast.md):
  * one skeleton: Mixamo-named (mixamorig_*), rest = Ch01's T-pose (npc/anims.res plays unchanged),
    plus eye.L, eye.R, jaw under mixamorig_Head
  * <id>_lod0: one mesh, three surfaces: skin (2048 atlas, face first), clothes (1024 atlas),
    hair (512, alpha mask: the short-hair shell and the lashes); named morph targets (person.MORPHS)
  * <id>_lod1: the same three surfaces at crowd density, no morphs, eyes, teeth or lashes
  * textures beside it: cast/<id>_{skin,clothes,hair}_{albedo,normal,orm}.png
  * cast/<id>.json: what the loader needs (hips height, height, morph names, jaw angle per jaw_open,
    counts) and what was built from what.
`--full` uses hm08 undecimated (a check of the LOD maps; over budget by design).
"""
import json
import math
import os
import sys
import time

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import person  # noqa: E402  (sets the path to ../characters for mh)
import mh  # noqa: E402
import topo  # noqa: E402
import clothes  # noqa: E402
import paint  # noqa: E402
import gltf  # noqa: E402
import mhasset  # noqa: E402
from hairline import Hair  # noqa: E402
from topo import Surf, clip, vertex_normals, quads_to_tris  # noqa: E402
from gltf import qinv, qmul, qrot, xform  # noqa: E402

PROJ = mh.PROJ
OUT = os.path.join(PROJ, "cast")
BUDGET = {"lod0": 15000, "lod1": 6000}
SKIN_TEX, CLOTHES_TEX, HAIR_TEX = 2048, 1024, 1024
HEAD_W = 0.505            # the head island's share of the skin atlas width


# ---- UV atlas ---------------------------------------------------------------------------------------
def _warp(s, s0, A=1.6, sig=0.2):
    g = np.linspace(0, 1, 1025)
    rho = 1 + A * np.exp(-((g - s0) / sig) ** 2)
    cdf = np.concatenate([[0], np.cumsum((rho[1:] + rho[:-1]) / 2)])
    cdf /= cdf[-1]
    return np.interp(s, g, cdf)


def skin_atlas(b, cuv):
    """hm08 image-coords corner UVs -> the skin atlas: the main head island (face, scalp, ears' roots,
    neck top) warped so the face is magnified, into the left HEAD_W; everything else is hm08's own
    layout scaled into the top right."""
    arr, hid, box, tip = topo.island_image(b)
    isl = topo.island_of(b, cuv)
    out = np.empty_like(cuv)
    h = isl == hid
    x0, y0, x1, y1 = box
    s = (cuv[h, :, 0] - x0) / (x1 - x0)
    t = (cuv[h, :, 1] - y0) / (y1 - y0)
    s0 = (tip[0] - x0) / (x1 - x0); t0 = (tip[1] - y0) / (y1 - y0)
    out[h, :, 0] = 0.004 + _warp(s, s0, 1.4, 0.25) * (HEAD_W - 0.008)
    out[h, :, 1] = 0.004 + _warp(t, t0, 1.6, 0.18) * 0.992
    out[~h] = np.array([HEAD_W + 0.01, 0.0]) + cuv[~h] * (1 - HEAD_W - 0.012)
    return out


def rect_uv(rect, uv01):
    x, y, w, h = rect
    return np.stack([x + uv01[..., 0] * w, y + uv01[..., 1] * h], -1)


# ---- parts ------------------------------------------------------------------------------------------
class Part:
    """Vertices (welded) + per-corner UVs; split into glTF vertices at the end."""

    def __init__(self, name, mat, pos, tri, cuv, W, morphs=None, kind=None, huv=None, smooth_n=True):
        self.name, self.mat = name, mat
        self.pos = np.asarray(pos, float)
        self.tri = np.asarray(tri, np.int64)
        self.cuv = np.asarray(cuv, float)
        self.W = np.asarray(W, float)
        self.morphs = morphs            # [(name, (n,3) delta)] or None
        self.kind = kind if kind is not None else np.zeros(len(self.tri), int)
        self.huv = huv
        self.nrm = vertex_normals(self.pos, self.tri)

    def tris(self):
        return len(self.tri)


def surf_part(name, mat, S, pos, cuv, Wb, morphs=None, **kw):
    W = S.ev(Wb)
    md = [(n, S.ev(d)) for n, d in morphs] if morphs is not None else None
    return Part(name, mat, pos, S.tri, cuv, W, md, **kw)


def eyeball(seg=16, rings=11):
    v = [[0, 0, 1]]
    for i in range(1, rings):
        th = np.pi * i / rings
        for j in range(seg):
            ph = 2 * np.pi * j / seg
            v.append([np.sin(th) * np.cos(ph), np.sin(th) * np.sin(ph), np.cos(th)])
    v.append([0, 0, -1])
    v = np.array(v)
    t = []
    for j in range(seg):
        t.append([0, 1 + j, 1 + (j + 1) % seg])
    for i in range(rings - 2):
        a = 1 + i * seg
        for j in range(seg):
            p, q2 = a + j, a + (j + 1) % seg
            t.append([p, p + seg, q2]); t.append([q2, p + seg, q2 + seg])
    last = len(v) - 1
    a = 1 + (rings - 2) * seg
    for j in range(seg):
        t.append([a + j, last, a + (j + 1) % seg])
    t = np.array(t)
    fn = np.cross(v[t[:, 1]] - v[t[:, 0]], v[t[:, 2]] - v[t[:, 0]])
    flip = (fn * v[t].mean(1)).sum(1) < 0
    t[flip] = t[flip][:, ::-1]
    uv = np.stack([0.5 + v[:, 0] * 0.5, 0.5 - v[:, 1] * 0.5], 1)
    return v, t, uv


class Builder:
    def __init__(self, pid, full=False):
        self.id = pid
        p = os.path.join(HERE, pid + ".json")
        if not os.path.exists(p):
            p = os.path.join(HERE, "mh_fallback", pid + ".json")     # MakeHuman people kept as the fallback
        self.data = json.load(open(p))
        self.P = person.Person(self.data)
        self.b = self.P.b
        self.coords = self.P.v
        self.Wb = self.P.weights()
        self.morphs = self.P.morphs()
        self.full = full
        b = self.b
        # hm08 vertex normals of the whole skin (shells offset along them, at every LOD)
        fi = b.faces_of("body")
        T = quads_to_tris(b.f[fi])
        self.Nh = np.zeros_like(self.coords)
        self.Nh[:mh.N_BODY] = vertex_normals(self.coords[:mh.N_BODY], T)
        hs = self.data.get("hair", {})
        self.hair = Hair(self.P, hs) if hs.get("style", "none") not in ("none", "bald") else None
        self.names = self.P.names
        self.jidx = {n: i for i, n in enumerate(self.names)}

    def onehot(self, n, bone):
        W = np.zeros((n, len(self.names))); W[:, self.jidx[bone]] = 1
        return W

    # ---- one LOD
    def lod(self, lod):
        S = topo.full_map(self.b) if self.full else topo.load_map(lod)
        ctx = clothes.Ctx(self.P, S, self.coords, self.Wb, self.Nh)
        g = self.data.get("garments", [])
        parts, cl_parts = [], []
        fields = []
        bottom_spec = next((x for x in g if x["type"] == "trousers"), {})
        top = None
        deleted = np.zeros(len(self.coords), bool)
        for spec in g:
            t = spec["type"]
            if t == "mh":
                pr, a = self.mh_part(spec["asset"], lod, spec.get("cell", "suit"))
                deleted[a.delete[a.delete < len(deleted)]] = True
                pr["spec"] = spec; cl_parts.append(pr)
                if spec.get("role") == "top":
                    top = pr
                    top["spec"] = dict(spec, neck=spec.get("neck", "collar"))
            elif t in ("shirt", "polo", "tee"):
                spec = dict(spec); spec.setdefault("neck", {"shirt": "collar", "polo": "polo", "tee": "crew"}[t])
                f = lambda s, spec=spec: clothes.top_field(ctx, s, spec)
                gap0 = float(spec.get("gap", 0.005 if spec.get("hem", "tucked") == "tucked" else 0.006))
                if spec.get("hem", "tucked") != "tucked":
                    wy = ctx.J["mixamorig_Hips"][1] + float(bottom_spec.get("waist_y", 0.03)) + 0.03
                    gapf = lambda s, wy=wy, g0=gap0: g0 + 0.009 * np.clip((wy - s["p"][:, 1]) / 0.06, 0, 1)
                else:
                    gapf = gap0
                top = clothes.shell(ctx, f(ctx.sem(S)), gapf, iters=3, cell="top")
                top["spec"] = spec
                cl_parts.append(top); fields.append(f)
            elif t == "trousers":
                f = lambda s, spec=spec: clothes.bottom_field(ctx, s, spec)
                pr = clothes.shell(ctx, f(ctx.sem(S)), float(spec.get("gap", 0.010)), iters=4, cell="bottom",
                                   extra=clothes.straight_legs(ctx) if spec.get("cut", "straight") == "straight" else None)
                pr["spec"] = spec; cl_parts.append(pr); fields.append(f)
            elif t == "shoes":
                f = lambda s, spec=spec: clothes.shoe_field(ctx, s, spec)
                pr = clothes.shell(ctx, f(ctx.sem(S)), float(spec.get("gap", 0.011)), iters=4, cell="shoes",
                                   base_smooth=30, min_gap=0.004,
                                   extra=clothes.shoe_shape(ctx, float(self.data.get("shoe_sole_m", 0.02))))
                pr["spec"] = spec; cl_parts.append(pr); fields.append(f)
        for spec in g:
            t = spec["type"]
            if t == "belt" and top is not None and top["spec"]["type"] == "mh":
                pr = self.mh_belt(top, spec)
                pr["spec"] = spec; cl_parts.append(pr)
            elif t == "belt":
                f = clothes.belt_field(ctx, ctx.sem(S), spec, bottom_spec)
                pr = clothes.shell(ctx, f, float(bottom_spec.get("gap", 0.010)) + 0.004, iters=2, cell="belt")
                pr["spec"] = spec; cl_parts.append(pr)
            elif t == "tie" and top is not None:
                y_top = ctx.J["mixamorig_Neck"][1] + 0.0
                pr = clothes.tie(ctx, top, y_top, ctx.J["mixamorig_Hips"][1] + float(spec.get("end_y", 0.07)))
                pr["spec"] = spec; cl_parts.append(pr)
            elif t == "nametag" and top is not None:
                pr = clothes.name_tag(ctx, top, side=int(spec.get("side", 1)))
                pr["spec"] = spec; cl_parts.append(pr)
            elif t in ("visor", "cap"):
                pr = clothes.headwear(ctx, t, spec.get("color"))
                pr["spec"] = spec; cl_parts.append(pr)
        if top is not None and top["spec"].get("neck") in ("collar", "polo") and lod == "lod0":
            cspec = {"type": "collar", "color": top["spec"].get("collar_color", top["spec"].get("color"))}
            pr = clothes.collar(ctx, top, "dress" if top["spec"]["neck"] == "collar" else "polo")
            if lod == "lod1":
                pr = decimate_ring(pr)
            pr["spec"] = cspec; cl_parts.append(pr)
        # the skin, cut under the clothes
        if deleted.any():
            # MakeHuman clothes list the body vertices they hide (delete_verts): drop the LOD's skin
            # triangles whose corners all sit on hidden vertices
            dom = S.src[np.arange(len(S)), S.w.argmax(1)]
            gone = deleted[dom][S.tri].all(1)
            S = S.sub(~gone)
            ctx = clothes.Ctx(self.P, S, self.coords, self.Wb, self.Nh)
        skin = clothes.cut_skin(ctx, fields)
        kp = skin.ev(self.coords)
        skin_cuv = skin_atlas(self.b, skin.cuv)
        morphs = self.morphs if lod == "lod0" else None
        sp = surf_part("skin", 0, skin, kp, skin_cuv, self.Wb, morphs, huv=skin.cuv)
        parts.append(sp)
        # clothes parts
        for c in cl_parts:
            nm = c["spec"]["asset"].split("/")[-1] if c["spec"]["type"] == "mh" else c["spec"]["type"]
            parts.append(Part(nm, 1, c["pos"], c["tri"], c["cuv"], c["W"]))
            parts[-1].spec = c["spec"]
            parts[-1].luv = c.get("luv")
        # hair: a MakeHuman hair mesh, or the shell
        hs = self.data.get("hair", {})
        if hs.get("asset"):
            pr, _ = self.mh_part(hs["asset"], lod, "hair", atlas="hair", morphs=lod == "lod0")
            parts.append(Part("hair", 2, pr["pos"], pr["tri"], pr["cuv"], pr["W"], pr.get("morphs")))
            parts[-1].spec = {"type": "mh_hair", "asset": hs["asset"]}; parts[-1].luv = pr["luv"]
        elif self.hair is not None and hs.get("shell", True):
            parts.append(self.hair_shell(ctx, S, lod))
        for key, cell in (("brows", "brows"), ("lashes", "lashes")):
            spec = self.data.get(key, {})
            if spec.get("asset") and (key == "brows" or lod == "lod0"):
                pr, _ = self.mh_part(spec["asset"], lod, cell, atlas="hair", morphs=lod == "lod0")
                parts.append(Part(key, 2, pr["pos"], pr["tri"], pr["cuv"], pr["W"], pr.get("morphs")))
                parts[-1].spec = {"type": "mh_" + key, "asset": spec["asset"]}; parts[-1].luv = pr["luv"]
        if lod == "lod0":
            parts += self.face_extras()
        else:
            parts += self.eyes_lo()
        return parts

    def mh_part(self, rel, lod, cell, atlas="clothes", morphs=False):
        """A MakeHuman asset fitted to this body, decimated by its map (assetmap.py), UVs into its cell."""
        a = mhasset.Asset(rel)
        p = os.path.join(topo.MAPS, "amap_%s_%s.npz" % (rel.replace("/", "_"), lod))
        if not os.path.exists(p):
            raise SystemExit("cast: no %s (run assetmap.py %s)" % (p, rel))
        z = np.load(p)
        def low(X):
            return (X[z["src"]] * z["bw"].reshape(z["bw"].shape + (1,) * (X.ndim - 1))).sum(1)
        pos = low(a.fit(self.coords))
        W = low(a.weights(self.Wb))
        suv = z["cuv"]
        cuv = clothes.cell_uv(cell, suv) if atlas == "clothes" else rect_uv(paint.HAIR_CELLS[cell], suv)
        out = {"pos": pos, "tri": z["tri"], "cuv": cuv, "luv": suv, "W": W, "cell": cell}
        if morphs:
            out["morphs"] = [(n, low(a.fit(self.coords, delta=d))) for n, d in self.morphs]
        return out, a

    def mh_belt(self, top, spec):
        """A belt on a MakeHuman suit: the suit's own triangles in a band at the trousers' top, lifted
        3 mm. The band's height comes from the suit texture (where the trousers start)."""
        from PIL import Image
        a = mhasset.Asset(top["spec"]["asset"])
        im = np.asarray(Image.open(a.texture()).convert("RGB"), np.float32) / 255
        uv = np.zeros((len(top["pos"]), 2)); uv[top["tri"].ravel()] = top["luv"].reshape(-1, 2)
        H, Wd = im.shape[:2]
        c = im[np.clip((uv[:, 1] * H).astype(int), 0, H - 1), np.clip((uv[:, 0] * Wd).astype(int), 0, Wd - 1)]
        bottom = paint.is_bottom(c)
        y = top["pos"][:, 1]
        front = (np.abs(top["pos"][:, 0]) < 0.12) & (top["pos"][:, 2] > 0) & (y > self.P.J["mixamorig_Hips"][1] - 0.15)
        wy = np.percentile(y[bottom & front], 97) if (bottom & front).any() else self.P.J["mixamorig_Hips"][1] + 0.03
        wy = float(spec.get("y", wy))
        tc = top["pos"][top["tri"]].mean(1)
        T = top["tri"][(tc[:, 1] < wy + 0.006) & (tc[:, 1] > wy - 0.04) & bottom[top["tri"]].any(1)]
        used, inv = np.unique(T.ravel(), return_inverse=True)
        tri = inv.reshape(-1, 3)
        pos = top["pos"][used]
        n = vertex_normals(top["pos"], top["tri"])[used]
        pos = pos + n * 0.003
        lu = np.stack([np.clip((np.arctan2(pos[:, 0], pos[:, 2]) / (2 * np.pi)) + 0.5, 0, 1), (wy + 0.004 - pos[:, 1]) / 0.04], 1)
        return {"pos": pos, "tri": tri, "cuv": clothes.cell_uv("belt", lu[tri]), "luv": lu[tri], "W": top["W"][used], "cell": "belt"}

    def hair_shell(self, ctx, S, lod):
        s = ctx.sem(S)
        ears = paint.sample(paint.mask("ears"), S.cuv.mean(1))
        vears = np.zeros(len(S)); np.maximum.at(vears, S.tri.ravel(), np.repeat(ears, 3))
        inset = float(self.data["hair"].get("shell_inset_deg", 2.0))
        f = self.hair.signed(s["p"]) - inset
        f = np.where(vears > 0.3, -1, f)
        f = np.where(s["head"] > 0.3, f, -1)
        G = clip(S, f)
        gs = ctx.sem(G)
        th = self.hair.thickness(gs["p"])
        # taper to the skin at the edge of the shell
        above = self.hair.signed(gs["p"]) - inset
        k = np.clip(above / float(self.data["hair"].get("taper_deg", 9.0)), 0, 1)
        th = th * (0.05 + 0.95 * k * k * (3 - 2 * k))
        pos = gs["p"] + gs["n"] * th[:, None]
        curl = float(self.data["hair"].get("curl", 0))
        if curl > 0.5:
            from raster import vnoise3
            pos += gs["n"] * ((vnoise3(gs["p"], 160) - 0.5) * 0.004 * curl)[:, None]
        pos = topo.smooth(pos, G.tri, 2, 0.4)
        # lat-long UVs (wrapping in u; the texture is periodic)
        az, el, _ = self.hair.frame(pos)
        u = (az / 360.0 + 0.5)
        v = np.clip((70 - el) / 140, 0, 1)
        cu = u[G.tri]
        span = cu.max(1) - cu.min(1)
        cu = np.where((span > 0.5)[:, None] & (cu < 0.5), cu + 1, cu)
        cuv = np.stack([cu, rect_uv(paint.HAIR_SHELL, np.stack([np.zeros_like(v), v], -1))[..., 1][G.tri]], -1)
        md = None
        if lod == "lod0":
            md = [(n, G.ev(d)) for n, d in self.morphs]
        return Part("hair", 2, pos, G.tri, cuv, G.ev(self.Wb), md)

    def face_extras(self):
        b, c = self.b, self.coords
        out = []
        es = self.data.get("eyes", {})
        if es.get("asset"):
            out += self.mh_eyes("lod0")
        # eyes: a sphere fitted to each MakeHuman eye helper, on its eye bone
        ev, et, euv = eyeball(14, 9)
        for s, bone in ((() if es.get("asset") else (("l", "eye.L"), ("r", "eye.R")))):
            hv = b.verts_of("helper-%s-eye" % s)
            cen = c[hv].mean(0); r = np.linalg.norm(c[hv] - cen, axis=1).mean()
            pos = cen + ev * r
            cuv = rect_uv(paint.EYE_RECT, euv)[et]
            out.append(Part("eye_" + s, 0, pos, et, cuv, self.onehot(len(pos), bone), None,
                            kind=np.full(len(et), paint.KIND_EYE)))
        # teeth and tongue (MakeHuman helpers): upper on the head, lower + tongue on the jaw
        for name, groups, bone, rect, kind in (("teeth_up", ["helper-upper-teeth"], "mixamorig_Head", paint.TEETH_RECT, paint.KIND_TEETH),
                                               ("teeth_lo", ["helper-lower-teeth"], "jaw", paint.TEETH_RECT, paint.KIND_TEETH)):
            fi = np.concatenate([b.faces_of(gname) for gname in groups])
            q = b.f[fi]
            vi, inv = np.unique(q.ravel(), return_inverse=True)
            tri = quads_to_tris(inv.reshape(-1, 4))
            pos = c[vi]
            cuv = np.broadcast_to(rect_uv(rect, np.array([0.5, 0.5])), tri.shape + (2,)).copy()
            md = []
            for n, d in self.morphs:
                dd = d[vi].copy()
                if bone == "jaw" and n == "jaw_open":
                    dd[:] = 0          # the jaw bone carries them (cast.gd set_mouth)
                md.append((n, dd))
            out.append(Part(name, 0, pos, tri, cuv, self.onehot(len(pos), bone), md,
                            kind=np.full(len(tri), kind)))
        if self.data.get("lashes", {}).get("asset"):
            return out
        # lashes: the helper strips, each strip mapped into the hair texture's lash band
        groups = ["helper-%s-eyelashes-2" % s for s in "lr"]     # upper lashes only (-1 are the lower)
        fi = np.concatenate([b.faces_of(gname) for gname in groups])
        q = b.f[fi]; qu = b.fuv[fi]
        pairs = np.stack([q.ravel(), qu.ravel()], 1)
        uniq, inv = np.unique(pairs, axis=0, return_inverse=True)
        vi, ti = uniq[:, 0], uniq[:, 1]
        tri = quads_to_tris(inv.ravel().reshape(-1, 4))
        uv = b.uv[ti]
        st = np.zeros_like(uv)
        for gname in groups:
            gv = np.isin(vi, b.verts_of(gname))
            u = uv[gv]
            st[gv] = (u - u.min(0)) / np.maximum(u.max(0) - u.min(0), 1e-6)
        # root at the top of the band: MakeHuman's lash UV runs root (v=0) to tip
        st[:, 1] = 1 - st[:, 1]
        st[:, 1] = 1 - st[:, 1]
        cuv = rect_uv(paint.HAIR_LASH, st)[tri]
        W = self.onehot(len(vi), "mixamorig_Head")
        md = [(n, d[vi]) for n, d in self.morphs]
        lp = Part("lashes", 2, c[vi], tri, cuv, W, md)
        out.append(lp)
        return out

    def mh_eyes(self, lod):
        """MakeHuman's eye mesh (both eyes), each eye on its bone, its texture in the skin atlas."""
        es = self.data["eyes"]
        pr, a = self.mh_part(es["asset"], lod, "eye", atlas="clothes")
        pos, tri = pr["pos"], pr["tri"]
        W = np.zeros((len(pos), len(self.names)))
        W[pos[:, 0] >= 0, self.jidx["eye.L"]] = 1
        W[pos[:, 0] < 0, self.jidx["eye.R"]] = 1
        cuv = rect_uv(paint.EYE_RECT, pr["luv"])
        p = Part("eyes", 0, pos, tri, cuv, W, None, kind=np.full(len(tri), paint.KIND_EYE), huv=pr["luv"])
        return [p]

    def eyes_lo(self):
        if self.data.get("eyes", {}).get("asset"):
            return self.mh_eyes("lod1")
        b, c = self.b, self.coords
        ev, et, euv = eyeball(8, 6)
        out = []
        for s, bone in (("l", "eye.L"), ("r", "eye.R")):
            hv = b.verts_of("helper-%s-eye" % s)
            cen = c[hv].mean(0); r = np.linalg.norm(c[hv] - cen, axis=1).mean()
            cuv = rect_uv(paint.EYE_RECT, euv)[et]
            out.append(Part("eye_" + s, 0, cen + ev * r, et, cuv, self.onehot(len(ev), bone), None,
                            kind=np.full(len(et), paint.KIND_EYE)))
        return out

    # ---- textures (from LOD0's parts)
    def textures(self, parts, prefix):
        sk = []
        for p in parts:
            if p.mat != 0:
                continue
            huv = p.huv if p.huv is not None else np.zeros(p.cuv.shape)
            sk.append({"cuv": p.cuv, "pos": p.pos[p.tri], "nrm": p.nrm[p.tri], "huv": huv, "kind": p.kind})
        paint.paint_skin(self.P, self.hair, self.data, sk, SKIN_TEX, prefix)
        cl = []
        for p in parts:
            if p.mat != 1:
                continue
            luv = getattr(p, "luv", None)
            if getattr(p, "spec", {}).get("type") in ("tie", "nametag", "visor", "cap", "collar"):
                x, y, w, h = clothes.CELLS[{"tie": "tie", "nametag": "tag", "visor": "headwear", "cap": "headwear", "collar": "collar"}[p.spec["type"]]]
                luv = np.stack([(p.cuv[..., 0] - x) / w, (p.cuv[..., 1] - y) / h], -1)
            cl.append({"cuv": p.cuv, "pos": p.pos[p.tri], "nrm": p.nrm[p.tri], "spec": p.spec, "luv": luv})
        paint.paint_clothes(self.P, self.data, cl, CLOTHES_TEX, prefix)
        hp = [{"cuv": p.cuv, "luv": p.luv, "asset": p.spec["asset"], "key": p.name}
              for p in parts if p.mat == 2 and getattr(p, "spec", {}).get("type", "").startswith("mh_")]
        if hp:
            paint.paint_hair_assets(self.data, hp, HAIR_TEX, prefix)
        else:
            paint.paint_hair(self.data, HAIR_TEX, prefix)

    # ---- write
    def build(self):
        t0 = time.time()
        os.makedirs(OUT, exist_ok=True)
        lods = {"lod0": self.lod("lod0"), "lod1": self.lod("lod1")}
        prefix = os.path.join(OUT, self.id)
        self.textures(lods["lod0"], prefix)
        g = gltf.GLB()
        P = self.P
        gb, lt = P.skeleton()
        jn = {}
        for n, p, _ in P.bones:
            q = P.rest_local(n)
            jn[n] = g.node({"name": n, "translation": [float(x) for x in lt[n]],
                            "rotation": [float(x) for x in q / np.linalg.norm(q)]})
        for n, p, _ in P.bones:
            if p is None:
                g.j["scenes"][0]["nodes"].append(jn[n])
            else:
                g.j["nodes"][jn[p]].setdefault("children", []).append(jn[n])
        gbind = {}
        for n, p, _ in P.bones:
            lq = gb[n] if p is None else qmul(qinv(gb[p]), gb[n])
            m = xform(lq, lt[n])
            gbind[n] = m if p is None else gbind[p] @ m
        ibm = [np.linalg.inv(gbind[n]) for n in self.names]
        skin = g.skin([jn[n] for n in self.names], ibm, skeleton=jn[self.names[0]])
        base = os.path.basename(prefix)
        mats = [g.material("%s_skin" % self.id, albedo=base + "_skin_albedo.png", normal=base + "_skin_normal.png",
                           orm=base + "_skin_orm.png", rough=1.0),
                g.material("%s_clothes" % self.id, albedo=base + "_clothes_albedo.png", normal=base + "_clothes_normal.png",
                           orm=base + "_clothes_orm.png", rough=1.0, metal=1.0),
                g.material("%s_hair" % self.id, albedo=base + "_hair_albedo.png", normal=base + "_hair_normal.png",
                           rough=0.7, alpha="mask", double=True)]
        report = {}
        for lname, parts in lods.items():
            pos, nrm, uv, J4, W4, prims, mdict = self.merge(parts, lname == "lod0")
            md = [(n, mdict[n][0], mdict[n][1]) for n, _ in self.morphs] if lname == "lod0" else []
            mi = g.mesh("%s_%s" % (self.id, lname), pos, nrm, uv, [(mats[m], t) for m, t in prims], J4, W4, md, eps=2e-5)
            g.node({"name": "%s_%s" % (self.id, lname), "mesh": mi, "skin": skin}, root=True)
            os.makedirs(topo.MAPS, exist_ok=True)
            np.savez_compressed(os.path.join(topo.MAPS, "%s_%s.npz" % (self.id, lname)), pos=pos, nrm=nrm, uv=uv,
                                tri=np.concatenate([t for _, t in prims]),
                                mat=np.concatenate([np.full(len(t), m) for m, t in prims]),
                                morph_names=np.array([n for n, _, _ in md]),
                                morphs=np.array([d for _, d, _ in md]) if md else np.zeros((0, len(pos), 3)))
            report[lname] = {"tris": int(sum(len(t) for _, t in prims)), "verts": int(len(pos)),
                             "surfaces": len(prims),
                             "parts": {p.name: p.tris() for p in parts}}
        jaw_deg = P.jaw_deg
        meta = {"id": self.id, "hips": float(P.J["mixamorig_Hips"][1]), "height_m": P.height(),
                "morphs": [n for n, _ in self.morphs], "jaw_open_deg": jaw_deg,
                "eyes": {"L": [float(x) for x in P.J["eye.L"]], "R": [float(x) for x in P.J["eye.R"]]},
                "lod_switch_m": float(self.data.get("lod_switch_m", 9.0))}
        size = g.write(prefix + ".glb", extras={"cast": meta})
        report["glb_bytes"] = size
        tex = {}
        for f in sorted(os.listdir(OUT)):
            if f.startswith(self.id + "_") and f.endswith(".png"):
                from PIL import Image
                im = Image.open(os.path.join(OUT, f))
                tex[f] = {"size": list(im.size), "bytes": os.path.getsize(os.path.join(OUT, f))}
        report["textures"] = tex
        meta.update({"store": self.data.get("store"), "period": self.data.get("period"),
                     "status": self.data.get("status", "proposal"), "lod0": report["lod0"], "lod1": report["lod1"],
                     "glb_bytes": size, "textures": tex, "built": time.strftime("%Y-%m-%d"),
                     "source": "tools/blender/cast/%s.json" % self.id})
        json.dump(meta, open(prefix + ".json", "w"), indent=1)
        for l in ("lod0", "lod1"):
            r = report[l]
            flag = "OK" if r["tris"] <= BUDGET[l] or self.full else "OVER BUDGET (%d)" % BUDGET[l]
            print("CAST %s %s: %d tris, %d verts, %d surfaces  %s" % (self.id, l, r["tris"], r["verts"], r["surfaces"], flag))
            print("   ", r["parts"])
        print("CAST %s: %.1f MB glb, jaw %.1f deg (fit %.1f mm), %.0fs" % (self.id, size / 1e6, jaw_deg, P.jaw_fit_mm, time.time() - t0))
        return meta

    def merge(self, parts, with_morphs):
        P_, N_, U_, J_, W_ = [], [], [], [], []
        prims = {0: [], 1: [], 2: []}
        mdict = {n: ([], []) for n, _ in self.morphs}
        off = 0
        for p in parts:
            # split welded vertices by corner UV
            key = np.concatenate([p.tri.reshape(-1, 1).astype(float), np.round(p.cuv.reshape(-1, 2) * 16384)], 1)
            uniq, first, inv = np.unique(key, axis=0, return_index=True, return_inverse=True)
            inv = inv.ravel()
            vi = uniq[:, 0].astype(np.int64)
            uv = p.cuv.reshape(-1, 2)[first]
            P_.append(p.pos[vi]); N_.append(p.nrm[vi]); U_.append(uv)
            idx = np.argsort(-p.W[vi], axis=1)[:, :4]
            w = np.take_along_axis(p.W[vi], idx, 1)
            s = w.sum(1, keepdims=True)
            w = np.where(s > 0, w / np.maximum(s, 1e-12), np.array([1, 0, 0, 0.0]))
            J_.append(idx); W_.append(w)
            prims[p.mat].append(inv.reshape(-1, 3) + off)
            if with_morphs:
                nd = {}
                if p.morphs is not None:
                    for n, d in p.morphs:
                        dp = d[vi]
                        if p.mat == 0 and p.name == "skin" and np.abs(d).max() > 1e-6:
                            n2 = vertex_normals(p.pos + d, p.tri)
                            dn = (n2 - p.nrm)[vi]
                        else:
                            dn = np.zeros_like(dp)
                        nd[n] = (dp, dn)
                for n, _ in self.morphs:
                    dp, dn = nd.get(n, (np.zeros((len(vi), 3)), np.zeros((len(vi), 3))))
                    mdict[n][0].append(dp); mdict[n][1].append(dn)
            off += len(vi)
        pos = np.concatenate(P_); nrm = np.concatenate(N_); uv = np.concatenate(U_)
        J4 = np.concatenate(J_).astype(np.uint16); W4 = np.concatenate(W_).astype(np.float32)
        pr = [(m, np.concatenate(t)) for m, t in prims.items() if t]
        if with_morphs:
            mdict = {n: (np.concatenate(a), np.concatenate(b)) for n, (a, b) in mdict.items()}
        return pos, nrm, uv, J4, W4, pr, mdict

    def jaw_angle(self):
        """The jaw rotation (degrees about +X, the person's left) matching jaw_open on the lower teeth."""
        b = self.b
        vi = b.verts_of("helper-lower-teeth")
        d = dict(self.morphs)["jaw_open"][vi]
        J = self.P.J["jaw"]
        r0 = self.coords[vi] - J
        r1 = r0 + d
        a0 = np.arctan2(r0[:, 1], r0[:, 2]); a1 = np.arctan2(r1[:, 1], r1[:, 2])
        da = np.degrees(np.angle(np.exp(1j * (a1 - a0))))
        # rotation about +X takes +Z toward -Y... sign: angle of (y, z) measured from +Z toward +Y
        return float(-np.median(da))


def decimate_ring(pr):
    return pr


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    for pid in args:
        Builder(pid, full="--full" in sys.argv).build()
