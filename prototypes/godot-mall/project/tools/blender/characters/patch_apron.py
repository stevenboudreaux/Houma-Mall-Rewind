"""B2 stopgap for B1's store-apron defect (design/godot-characters.md "Known defects";
design/godot-character-editor.md): the bib's top-row outer vertices missed the torso ray, sat in the
armpit and took the arm's weights, so a stray panel hung at one side. loose.apron_part is fixed for the
next full rebuild (garments.py); until that runs on a machine with Blender, this patches the exported
full_storeapron_<sex>.glb files in place (plain Python + numpy, no Blender):

    python3 tools/blender/characters/patch_apron.py models/characters/full_storeapron_*.glb

The apron grid is 12 x 12, row-major from the top (vertex i*12 + j). A top-row vertex well behind its row (> 2 cm behind the row's median depth) is re-made
from the vertex below it (row 1, same column) lifted to the row's height, for the rest position and
every blend shape, with that vertex's normal, joints and weights. A second run finds nothing to patch.
"""
import json
import struct
import sys

import numpy as np

COLS = 12


CT = {5126: "<f4", 5123: "<u2", 5125: "<u4", 5121: "u1"}
NC = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def patch(path):
    b = open(path, "rb").read()
    jlen = struct.unpack("<I", b[12:16])[0]
    j = json.loads(b[20:20 + jlen])
    blen = struct.unpack("<I", b[20 + jlen:24 + jlen])[0]
    bin_ = bytearray(b[28 + jlen:28 + jlen + blen])


    def dense(i):
        a = j["accessors"][i]
        ct, nc = CT[a["componentType"]], NC[a["type"]]
        if "bufferView" in a:
            bv = j["bufferViews"][a["bufferView"]]
            if bv.get("byteStride", 0) not in (0, np.dtype(ct).itemsize * nc):
                raise SystemExit("interleaved buffer: not handled")
            off = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
            v = np.frombuffer(bytes(bin_), dtype=ct, count=a["count"] * nc, offset=off).reshape(a["count"], nc).copy()
        else:
            v = np.zeros((a["count"], nc), dtype=ct)
        sp = a.get("sparse")
        if sp:
            ib = j["bufferViews"][sp["indices"]["bufferView"]]
            idx = np.frombuffer(bytes(bin_), dtype=CT[sp["indices"]["componentType"]], count=sp["count"],
                                offset=ib.get("byteOffset", 0) + sp["indices"].get("byteOffset", 0))
            vb = j["bufferViews"][sp["values"]["bufferView"]]
            vals = np.frombuffer(bytes(bin_), dtype=ct, count=sp["count"] * nc,
                                 offset=vb.get("byteOffset", 0) + sp["values"].get("byteOffset", 0)).reshape(-1, nc)
            v[idx.astype(np.int64)] = vals
        return v

    def append(data):
        while len(bin_) % 4:
            bin_.append(0)
        off = len(bin_)
        bin_.extend(data)
        j["bufferViews"].append({"buffer": 0, "byteOffset": off, "byteLength": len(data)})
        return len(j["bufferViews"]) - 1

    def store(i, v):
        a = j["accessors"][i]
        ct, nc = CT[a["componentType"]], NC[a["type"]]
        v = v.astype(ct)
        if "bufferView" in a and "sparse" not in a:
            bv = j["bufferViews"][a["bufferView"]]
            off = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
            bin_[off:off + v.nbytes] = v.tobytes()
        else:
            # a sparse accessor (B1's blend shapes): re-encode its non-zero rows, appended
            base = np.zeros_like(v) if "bufferView" not in a else None
            nz = np.nonzero(np.any(v != (base if base is not None else 0), axis=1))[0].astype("<u4")
            a["sparse"] = {"count": int(len(nz)),
                           "indices": {"bufferView": append(nz.tobytes()), "componentType": 5125},
                           "values": {"bufferView": append(v[nz].tobytes())}}
        if "min" in a:
            a["min"] = [float(x) for x in v.min(0)]
            a["max"] = [float(x) for x in v.max(0)]

    mesh = [m for m in j["meshes"] if m["name"].startswith("apron")]
    if not mesh:
        raise SystemExit(path + ": no apron mesh")
    prim = mesh[0]["primitives"][0]
    att = prim["attributes"]
    if j["accessors"][att["POSITION"]]["count"] != COLS * COLS:
        raise SystemExit(path + ": not the 12 x 12 apron grid")
    # the bad top-row vertices: well behind the rest of the row (the missed rays); each is re-made
    # from the vertex below it (row 1, same column), lifted to the row's height
    P0 = dense(att["POSITION"])
    row = P0[:COLS]
    zmed = float(np.median(row[:, 2]))
    ymed = float(np.median(row[:, 1]))
    bad = [k for k in range(COLS) if row[k, 2] < zmed - 0.02]
    if not bad:
        print("%s: nothing to patch" % path)
        return

    def extrap(arr, rest=False):
        a = arr.astype(np.float64)
        for k in bad:
            a[k] = a[k + COLS]
            if rest:
                a[k, 1] = ymed
        return a

    def copy(arr):
        a = arr.copy()
        for k in bad:
            a[k] = a[k + COLS]
        return a

    edits = [(att["POSITION"], lambda a: extrap(a, True))]
    for key in ("NORMAL", "TANGENT", "JOINTS_0", "WEIGHTS_0", "JOINTS_1", "WEIGHTS_1"):
        if key in att:
            edits.append((att[key], copy))
    for t in prim.get("targets", []):
        if "POSITION" in t:
            edits.append((t["POSITION"], extrap))
        if "NORMAL" in t:
            edits.append((t["NORMAL"], copy))
    before = dense(att["POSITION"])[bad]
    for acc, fn in edits:
        store(acc, fn(dense(acc)))
    after = dense(att["POSITION"])[bad]
    j["buffers"][0]["byteLength"] = len(bin_)
    while len(bin_) % 4:
        bin_.append(0)
    js = json.dumps(j, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    out = b"glTF" + struct.pack("<II", 2, 12 + 8 + len(js) + 8 + len(bin_)) + struct.pack("<I", len(js)) + b"JSON" + js \
        + struct.pack("<I", len(bin_)) + b"BIN\x00" + bytes(bin_)
    open(path, "wb").write(out)
    print("%s: top-row vertices %s: %s -> %s" % (path, bad, np.round(before, 3).tolist(), np.round(after, 3).tolist()))


if __name__ == "__main__":
    for f in sys.argv[1:]:
        patch(f)
