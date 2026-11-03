"""Poke-through check on the EXPORTED files: for each piece and each test body (neutral + the
cast-sheet extremes), apply the slider blend-shape weights to the body's full skin and to the
piece (read back from the .glb, sparse morphs and all), then measure every piece vertex's signed
distance to the skin (+ outside). Reports per piece / extreme how many vertices end up inside
the skin (< -1 mm), i.e. where the body would poke through if its region were not hidden.

  BPY python fitcheck.py [female|male] > .scratch/chars/fitcheck.txt
Also writes .scratch/chars/fitcheck.json (read by manifest.py: each piece's worst case).
"""
import glob
import json
import os
import struct
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: F401,E402
import sliders  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
MOD = os.path.join(PROJ, "models", "characters")


def read_glb(path):
    d = open(path, "rb").read()
    n = struct.unpack("<I", d[12:16])[0]
    j = json.loads(d[20:20 + n])
    binoff = 20 + n + 8
    B = d[binoff:]
    def acc(i, count=None):
        a = j["accessors"][i]
        comp = {5126: np.float32, 5125: np.uint32, 5123: np.uint16, 5121: np.uint8}[a["componentType"]]
        k = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}[a["type"]]
        if "bufferView" in a:
            bv = j["bufferViews"][a["bufferView"]]
            out = np.frombuffer(B, comp, a["count"] * k, bv.get("byteOffset", 0) + a.get("byteOffset", 0)).reshape(a["count"], k).astype(np.float64)
        else:
            out = np.zeros((a["count"], k))
        if "sparse" in a:
            s = a["sparse"]
            ib = j["bufferViews"][s["indices"]["bufferView"]]; vb = j["bufferViews"][s["values"]["bufferView"]]
            ic = {5125: np.uint32, 5123: np.uint16}[s["indices"]["componentType"]]
            idx = np.frombuffer(B, ic, s["count"], ib.get("byteOffset", 0))
            val = np.frombuffer(B, np.float32, s["count"] * k, vb.get("byteOffset", 0)).reshape(-1, k)
            out[idx] = val
        return out
    meshes = []
    for m in j["meshes"]:
        p = m["primitives"][0]
        pos = acc(p["attributes"]["POSITION"])
        names = m.get("extras", {}).get("targetNames", [])
        morphs = {nm: acc(t["POSITION"]) for nm, t in zip(names, p.get("targets", []))}
        tris = np.concatenate([acc(q["indices"]).astype(np.int64).reshape(-1, 3) for q in m["primitives"]])
        meshes.append((m["name"], pos, morphs, tris))
    return meshes


def shaped(meshes, w, skip=()):
    out = []
    for name, pos, morphs, tris in meshes:
        if name in skip:
            continue
        p = pos.copy()
        for k, x in w.items():
            if k in morphs:
                p += morphs[k] * x
        out.append((name, p, tris))
    return out


def main(sexes):
    from mathutils.bvhtree import BVHTree
    from mathutils import Vector
    tests = {"neutral": {}}
    tests.update({k: v for k, v in sliders.PRESETS["extremes"].items()})
    report = {}
    for sex in sexes:
        body = read_glb(os.path.join(MOD, "body_%s_hi.glb" % sex))
        for tname, vals in tests.items():
            w = sliders.shape_weights(vals, sex)
            sk = shaped(body, w, skip=("teeth", "tongue", "lashes", "eye_l", "eye_r"))
            V = np.concatenate([p for _, p, _ in sk]); off = 0; T = []
            for _, p, t in sk:
                T.append(t + off); off += len(p)
            T = np.concatenate(T)
            bvh = BVHTree.FromPolygons(V.tolist(), T.tolist(), all_triangles=True)
            for f in sorted(glob.glob(os.path.join(MOD, "*_%s.glb" % sex))):
                pid = os.path.basename(f)[:-4]
                if pid.startswith("body_") or pid.startswith("hair_"):
                    continue
                pm = shaped(read_glb(f), w)
                P = np.concatenate([p for _, p, _ in pm])
                P = np.unique(np.round(P, 6), axis=0)
                inside = 0; worst = 0.0
                for p in P:
                    loc, nrm, _, dist = bvh.find_nearest(Vector(p))
                    s = (Vector(p) - loc).dot(nrm)
                    if s < -0.001:
                        inside += 1; worst = min(worst, s)
                r = report.setdefault(pid, {})
                r[tname] = {"inside": inside, "of": int(len(P)), "worst_mm": round(worst * 1000, 1)}
                print("%-28s %-14s inside %4d / %5d  worst %6.1f mm" % (pid, tname, inside, len(P), worst * 1000), flush=True)
    json.dump(report, open(os.path.join(PROJ, ".scratch", "chars", "fitcheck.json"), "w"), indent=1)


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    main([a for a in argv if a in ("female", "male")] or ["female", "male"])
