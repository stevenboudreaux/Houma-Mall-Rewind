#!/usr/bin/env python3
"""B-FIX (Steven, Nov 2, final: every character is clothed at all times). The bodies' permanent base
layer, applied to the SHIPPED files in models/characters/ (numpy + Pillow, no Blender):

1. Flatten: the body mesh's chest (front) and groin regions are smoothed (Laplacian, vertices
   welded by position so UV seams don't crack, each vertex moved at most MAX_MOVE, never pushed out
   along its normal) on the rest mesh and on every blend shape that touches them (the sparse values,
   in place). No nipples or groin shape under any slider.
2. Paint: the same body regions (BASE_REGIONS, as scripts/char_body.gd) are painted into the shared
   skin maps as plain fabric: skin_albedo.png flat grey (no areolae), skin_normal.png flat,
   skin_orm.png rough. In the game scripts/spatial_char_region.gdshader also draws those regions as
   untinted fabric (base_mask); the paint is the fallback for any plain material.

Idempotent: a flattened .glb carries asset.extras.bfix_flattened, the maps a marker file
(skin_base_painted.txt), and both are skipped when present.

    python3 tools/blender/characters/flatten.py          # from the project folder
"""
import json
import os
import struct
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

MC = "models/characters"
BODIES = ["body_female", "body_female_hi", "body_male", "body_male_hi"]
FLATTEN_REGIONS = ["chest_f", "pelvis_f", "crotch"]
BASE_REGIONS = ["chest_f", "chest_b", "pelvis_f", "pelvis_b", "crotch"]
ITER = 12
LAMBDA = 0.5
MAX_MOVE = 0.004          # metres
PAINT_ALBEDO = (150, 149, 145)
PAINT_ROUGH = 235
MARK = os.path.join(MC, "skin_base_painted.txt")

CT = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
NC = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


class Glb:
    def __init__(self, path):
        b = open(path, "rb").read()
        jl = struct.unpack("<I", b[12:16])[0]
        self.j = json.loads(b[20:20 + jl])
        o = 20 + jl
        bl = struct.unpack("<I", b[o:o + 4])[0]
        self.bin = bytearray(b[o + 8:o + 8 + bl])
        self.path = path

    def _view(self, bv, off, ct, n):
        v = self.j["bufferViews"][bv]
        start = v.get("byteOffset", 0) + off
        dt = np.dtype(CT[ct])
        stride = v.get("byteStride", 0)
        return start, dt, stride

    def read(self, ai):
        """dense values of accessor ai (sparse applied); returns (array, where-to-write info)"""
        a = self.j["accessors"][ai]
        n, c = a["count"], NC[a["type"]]
        if "bufferView" in a:
            start, dt, stride = self._view(a["bufferView"], a.get("byteOffset", 0), a["componentType"], n)
            assert stride in (0, dt.itemsize * c), "interleaved buffers not supported"
            arr = np.frombuffer(self.bin, dt, n * c, start).reshape(n, c).astype(np.float64)
        else:
            arr = np.zeros((n, c))
        sp = a.get("sparse")
        if sp:
            idx = self._sparse_idx(sp)
            vals = self._sparse_vals(sp, c)
            arr[idx] = vals
        return arr

    def _sparse_idx(self, sp):
        i = sp["indices"]
        start, dt, _ = self._view(i["bufferView"], i.get("byteOffset", 0), i["componentType"], sp["count"])
        return np.frombuffer(self.bin, dt, sp["count"], start).astype(np.int64)

    def _sparse_vals(self, sp, c):
        v = sp["values"]
        start, dt, _ = self._view(v["bufferView"], v.get("byteOffset", 0), 5126, sp["count"])
        return np.frombuffer(self.bin, np.float32, sp["count"] * c, start).reshape(-1, c).astype(np.float64)

    def write_dense(self, ai, arr):
        a = self.j["accessors"][ai]
        assert "bufferView" in a and "sparse" not in a and a["componentType"] == 5126
        start, _, _ = self._view(a["bufferView"], a.get("byteOffset", 0), 5126, a["count"])
        data = arr.astype(np.float32).tobytes()
        self.bin[start:start + len(data)] = data
        if "min" in a:
            a["min"] = [float(x) for x in arr.min(0)]
            a["max"] = [float(x) for x in arr.max(0)]

    def write_sparse_vals(self, ai, vals):
        a = self.j["accessors"][ai]
        sp = a["sparse"]
        v = sp["values"]
        start, _, _ = self._view(v["bufferView"], v.get("byteOffset", 0), 5126, sp["count"])
        data = vals.astype(np.float32).tobytes()
        self.bin[start:start + len(data)] = data
        if "min" in a:
            dense = self.read(ai)
            a["min"] = [float(x) for x in dense.min(0)]
            a["max"] = [float(x) for x in dense.max(0)]

    def save(self, path=None):
        js = json.dumps(self.j, separators=(",", ":")).encode()
        js += b" " * ((4 - len(js) % 4) % 4)
        bn = bytes(self.bin) + b"\0" * ((4 - len(self.bin) % 4) % 4)
        total = 12 + 8 + len(js) + 8 + len(bn)
        out = struct.pack("<III", 0x46546C67, 2, total) + struct.pack("<II", len(js), 0x4E4F534A) + js
        out += struct.pack("<II", len(bn), 0x004E4942) + bn
        open(path or self.path, "wb").write(out)


def regions():
    return json.load(open(os.path.join(MC, "characters.json")))["regions"]


def body_prim(g):
    for m in g.j["meshes"]:
        if m["name"] == "body":
            return m["primitives"][0]
    raise SystemExit("no body mesh in " + g.path)


def tris(g, pr):
    return g.read(pr["indices"]).reshape(-1, 3).astype(np.int64)


def weld(P):
    """id per vertex, shared by vertices at the same position (UV seams)"""
    q = np.round(P / 1e-5).astype(np.int64)
    _, inv = np.unique(q, axis=0, return_inverse=True)
    return inv.reshape(-1)


def smooth(P, T, wid, movable):
    """Laplacian smoothing of welded vertices flagged movable; others fixed. Returns new P."""
    nW = wid.max() + 1
    W = np.zeros((nW, 3)); cnt = np.zeros(nW)
    np.add.at(W, wid, P); np.add.at(cnt, wid, 1)
    W /= cnt[:, None]
    e = np.concatenate([T[:, [0, 1]], T[:, [1, 2]], T[:, [2, 0]]])
    e = wid[e]
    e = np.unique(np.sort(e, 1), axis=0)
    e = e[e[:, 0] != e[:, 1]]
    mov = np.zeros(nW, bool)
    mov[wid[movable]] = True
    W0 = W.copy()
    for _ in range(ITER):
        acc = np.zeros_like(W); deg = np.zeros(nW)
        np.add.at(acc, e[:, 0], W[e[:, 1]]); np.add.at(acc, e[:, 1], W[e[:, 0]])
        np.add.at(deg, e[:, 0], 1); np.add.at(deg, e[:, 1], 1)
        avg = acc / np.maximum(deg, 1)[:, None]
        W = np.where(mov[:, None], W + LAMBDA * (avg - W), W)
    d = W - W0
    L = np.linalg.norm(d, axis=1)
    s = np.minimum(1.0, MAX_MOVE / np.maximum(L, 1e-12))
    W = W0 + d * s[:, None]
    return W[wid]


def normals(P, T):
    n = np.zeros_like(P)
    f = np.cross(P[T[:, 1]] - P[T[:, 0]], P[T[:, 2]] - P[T[:, 0]])
    for k in range(3):
        np.add.at(n, T[:, k], f)
    return n / np.maximum(np.linalg.norm(n, axis=1), 1e-12)[:, None]


def flatten(name, reg):
    path = os.path.join(MC, name + ".glb")
    g = Glb(path)
    if g.j.get("asset", {}).get("extras", {}).get("bfix_flattened"):
        print("FLATTEN %s: already done" % name); return
    pr = body_prim(g)
    P = g.read(pr["attributes"]["POSITION"])
    N0 = g.read(pr["attributes"]["NORMAL"])
    T = tris(g, pr)
    R = np.round(g.read(pr["attributes"]["TEXCOORD_1"])[:, 0]).astype(int)
    ids = [reg.index(r) for r in FLATTEN_REGIONS]
    movable = np.isin(R, ids)
    wid = weld(P)
    Ps = smooth(P, T, wid, movable)
    # never outward: keep only the inward part of the move along the original normal
    d = Ps - P
    out = np.einsum("ij,ij->i", d, N0)
    d -= np.maximum(out, 0)[:, None] * N0
    Ps = P + d
    # normals of the moved vertices, averaged over welded duplicates
    Nn = normals(Ps, T)
    nW = wid.max() + 1
    acc = np.zeros((nW, 3)); np.add.at(acc, wid, Nn)
    acc /= np.maximum(np.linalg.norm(acc, axis=1), 1e-12)[:, None]
    moved = np.linalg.norm(d, axis=1) > 1e-7
    N1 = np.where(moved[:, None], acc[wid], N0)
    g.write_dense(pr["attributes"]["POSITION"], Ps)
    g.write_dense(pr["attributes"]["NORMAL"], N1)
    # blend shapes: the same smoothing of (rest + delta), less the rest's, on the sparse entries
    nt = 0
    for t in pr.get("targets", []):
        ai = t["POSITION"]
        sp = g.j["accessors"][ai].get("sparse")
        if not sp: continue
        idx = g._sparse_idx(sp)
        if not movable[idx].any(): continue
        D = g.read(ai)
        Q = smooth(P + D, T, wid, movable)
        dq = Q - (P + D)
        oq = np.einsum("ij,ij->i", dq, N0)
        dq -= np.maximum(oq, 0)[:, None] * N0
        newD = (P + D + dq) - Ps
        g.write_sparse_vals(ai, newD[idx])
        nt += 1
    g.j.setdefault("asset", {}).setdefault("extras", {})["bfix_flattened"] = {
        "regions": FLATTEN_REGIONS, "iter": ITER, "max_move_m": MAX_MOVE}
    g.save()
    print("FLATTEN %s: %d of %d body vertices movable, %d moved, max %.2f mm, %d blend shapes" % (
        name, int(movable.sum()), len(P), int(moved.sum()), float(np.linalg.norm(d, axis=1).max() * 1000), nt))


def paint(reg):
    if os.path.exists(MARK):
        print("PAINT: already done"); return
    ids = [reg.index(r) for r in BASE_REGIONS]
    alb = Image.open(os.path.join(MC, "skin_albedo.png")).convert("RGBA")
    W, H = alb.size
    mask = Image.new("L", (W, H), 0)
    dr = ImageDraw.Draw(mask)
    for name in BODIES:
        g = Glb(os.path.join(MC, name + ".glb"))
        pr = body_prim(g)
        UV = g.read(pr["attributes"]["TEXCOORD_0"])
        R = np.round(g.read(pr["attributes"]["TEXCOORD_1"])[:, 0]).astype(int)
        T = tris(g, pr)
        sel = np.isin(R[T], ids).any(1)
        for t in T[sel]:
            dr.polygon([(float(UV[k, 0] * W), float(UV[k, 1] * H)) for k in t], fill=255)
    mask = mask.filter(ImageFilter.MaxFilter(5))
    flat = Image.new("RGBA", (W, H), PAINT_ALBEDO + (255,))
    Image.composite(flat, alb, mask).save(os.path.join(MC, "skin_albedo.png"))
    nrm = Image.open(os.path.join(MC, "skin_normal.png")).convert("RGB")
    m2 = mask.resize(nrm.size)
    Image.composite(Image.new("RGB", nrm.size, (128, 128, 255)), nrm, m2).save(os.path.join(MC, "skin_normal.png"))
    orm = Image.open(os.path.join(MC, "skin_orm.png")).convert("RGB")
    m3 = mask.resize(orm.size)
    o = np.array(orm); m = np.array(m3) > 127
    o[m, 1] = PAINT_ROUGH
    Image.fromarray(o).save(os.path.join(MC, "skin_orm.png"))
    cov = float((np.array(mask) > 127).mean() * 100)
    open(MARK, "w").write("B-FIX: skin_albedo / skin_normal / skin_orm painted with the base layer over %s "
                          "(tools/blender/characters/flatten.py). %.1f %% of the map.\n" % (", ".join(BASE_REGIONS), cov))
    print("PAINT: base layer painted over %.1f %% of the skin maps" % cov)


if __name__ == "__main__":
    if not os.path.isdir(MC):
        sys.exit("run from the project folder")
    reg = regions()
    for b in BODIES:
        flatten(b, reg)
    paint(reg)
