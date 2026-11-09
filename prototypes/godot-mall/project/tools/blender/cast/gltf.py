"""A small glTF 2.0 (.glb) writer for the cast (copied from B1's tools/blender/characters/glb.py, which
CHAR-STRIP deletes): skinned meshes with sparse morph targets.

Written by hand (not Blender's exporter) so the skeleton is exactly what we compute: each joint
node's TRS is the REST pose (the Mixamo T-pose with Ch01's bone orientations), while the
inverse bind matrices are the BIND pose the mesh was modelled and weighted in (the A-pose).
Godot builds Skeleton3D rests from the node TRS, so the NPC clips retarget with no fix-up.

Morph targets are stored sparse (only vertices that move more than `eps`), with normal deltas,
and carry their names in mesh.extras.targetNames (Godot reads them as blend shape names).
Images are referenced by URI (PNG files beside the .glb), as the prop pipeline does.
"""
import json
import struct

import numpy as np

FLOAT, UINT, USHORT, UBYTE = 5126, 5125, 5123, 5121


class GLB:
    def __init__(self):
        self.j = {"asset": {"version": "2.0", "generator": "houma tools/blender/cast"},
                  "scene": 0, "scenes": [{"nodes": []}], "nodes": [], "meshes": [], "accessors": [],
                  "bufferViews": [], "buffers": [], "materials": [], "skins": [], "images": [],
                  "textures": [], "samplers": [{"magFilter": 9729, "minFilter": 9987, "wrapS": 10497, "wrapT": 10497}]}
        self.bin = bytearray()
        self._img = {}

    # ---- raw data
    def _view(self, data, target=None):
        while len(self.bin) % 4:
            self.bin.append(0)
        off = len(self.bin)
        self.bin += data
        v = {"buffer": 0, "byteOffset": off, "byteLength": len(data)}
        if target:
            v["target"] = target
        self.j["bufferViews"].append(v)
        return len(self.j["bufferViews"]) - 1

    def accessor(self, a, kind, target=None, minmax=False, normalized=False):
        a = np.ascontiguousarray(a)
        ct = {np.float32: FLOAT, np.uint32: UINT, np.uint16: USHORT, np.uint8: UBYTE}[a.dtype.type]
        bv = self._view(a.tobytes(), target)
        acc = {"bufferView": bv, "componentType": ct, "count": int(a.shape[0]), "type": kind}
        if normalized:
            acc["normalized"] = True
        if minmax:
            acc["min"] = [float(x) for x in a.min(0)]
            acc["max"] = [float(x) for x in a.max(0)]
        self.j["accessors"].append(acc)
        return len(self.j["accessors"]) - 1

    def sparse(self, delta, count, eps):
        """A VEC3 float accessor of `count` zeros with sparse values where |delta| > eps."""
        idx = np.nonzero(np.abs(delta).max(1) > eps)[0].astype(np.uint32)
        acc = {"componentType": FLOAT, "count": int(count), "type": "VEC3"}
        if len(idx):
            vals = delta[idx].astype(np.float32)
            acc["sparse"] = {"count": int(len(idx)),
                             "indices": {"bufferView": self._view(idx.tobytes()), "componentType": UINT},
                             "values": {"bufferView": self._view(vals.tobytes())}}
            acc["min"] = [float(x) for x in vals.min(0).clip(max=0)]
            acc["max"] = [float(x) for x in vals.max(0).clip(min=0)]
        else:
            acc["min"] = [0.0, 0.0, 0.0]
            acc["max"] = [0.0, 0.0, 0.0]
        self.j["accessors"].append(acc)
        return len(self.j["accessors"]) - 1

    # ---- scene
    def node(self, d, root=False):
        self.j["nodes"].append(d)
        i = len(self.j["nodes"]) - 1
        if root:
            self.j["scenes"][0]["nodes"].append(i)
        return i

    def image(self, uri):
        if uri not in self._img:
            self.j["images"].append({"uri": uri})
            self.j["textures"].append({"sampler": 0, "source": len(self.j["images"]) - 1})
            self._img[uri] = len(self.j["textures"]) - 1
        return self._img[uri]

    def material(self, name, color=(1, 1, 1, 1), rough=0.6, metal=0.0, albedo=None, normal=None, orm=None,
                 double=False, alpha=None, extras=None):
        m = {"name": name, "pbrMetallicRoughness": {"baseColorFactor": list(color), "roughnessFactor": rough,
                                                     "metallicFactor": metal}}
        if albedo:
            m["pbrMetallicRoughness"]["baseColorTexture"] = {"index": self.image(albedo)}
        if orm:
            m["pbrMetallicRoughness"]["metallicRoughnessTexture"] = {"index": self.image(orm)}
            m["occlusionTexture"] = {"index": self.image(orm)}
        if normal:
            m["normalTexture"] = {"index": self.image(normal)}
        if double:
            m["doubleSided"] = True
        if alpha == "blend":
            m["alphaMode"] = "BLEND"
        if alpha == "mask":
            m["alphaMode"] = "MASK"
            m["alphaCutoff"] = 0.35
        if extras:
            m["extras"] = extras
        self.j["materials"].append(m)
        return len(self.j["materials"]) - 1

    def mesh(self, name, pos, nrm, uv, prims, joints=None, wts=None, morphs=(), eps=1e-4, color=None, uv2=None,
             extras=None):
        """prims: [(material index, triangle indices (K,3))]. morphs: [(name, dpos, dnrm)].
        joints/wts: (N,4). color: (N,4) float 0..1 (COLOR_0, e.g. body region ids). One vertex buffer
        shared by every primitive."""
        n = len(pos)
        attr = {"POSITION": self.accessor(pos.astype(np.float32), "VEC3", 34962, minmax=True),
                "NORMAL": self.accessor(nrm.astype(np.float32), "VEC3", 34962)}
        if uv is not None:
            attr["TEXCOORD_0"] = self.accessor(uv.astype(np.float32), "VEC2", 34962)
        if uv2 is not None:
            attr["TEXCOORD_1"] = self.accessor(uv2.astype(np.float32), "VEC2", 34962)
        if color is not None:
            attr["COLOR_0"] = self.accessor(color.astype(np.float32), "VEC4", 34962)
        if joints is not None:
            attr["JOINTS_0"] = self.accessor(joints.astype(np.uint16), "VEC4", 34962)
            attr["WEIGHTS_0"] = self.accessor(wts.astype(np.float32), "VEC4", 34962)
        targets = []
        for _, dp, dn in morphs:
            t = {"POSITION": self.sparse(dp, n, eps)}
            if dn is not None:
                t["NORMAL"] = self.sparse(dn, n, eps * 10)
            targets.append(t)
        P = []
        for mat, tris in prims:
            p = {"attributes": attr, "indices": self.accessor(tris.astype(np.uint32).ravel(), "SCALAR", 34963),
                 "material": mat, "mode": 4}
            if targets:
                p["targets"] = targets
            P.append(p)
        m = {"name": name, "primitives": P}
        if morphs:
            m["weights"] = [0.0] * len(morphs)
            m["extras"] = {"targetNames": [k for k, _, _ in morphs]}
        if extras:
            m.setdefault("extras", {}).update(extras)
        self.j["meshes"].append(m)
        return len(self.j["meshes"]) - 1

    def skin(self, joints, ibms, skeleton=None, name="skin"):
        a = self.accessor(np.array([np.asarray(m, np.float32).T.ravel() for m in ibms], np.float32), "MAT4")
        s = {"name": name, "joints": joints, "inverseBindMatrices": a}
        if skeleton is not None:
            s["skeleton"] = skeleton
        self.j["skins"].append(s)
        return len(self.j["skins"]) - 1

    def write(self, path, extras=None):
        for k in ("materials", "skins", "images", "textures"):
            if not self.j[k]:
                self.j.pop(k)
        if "textures" not in self.j:
            self.j.pop("samplers", None)
        if extras:
            self.j["scenes"][0]["extras"] = extras
        while len(self.bin) % 4:
            self.bin.append(0)
        self.j["buffers"] = [{"byteLength": len(self.bin)}]
        js = json.dumps(self.j, separators=(",", ":")).encode()
        js += b" " * ((4 - len(js) % 4) % 4)
        out = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(self.bin))
        out += struct.pack("<II", len(js), 0x4E4F534A) + js
        out += struct.pack("<II", len(self.bin), 0x004E4942) + bytes(self.bin)
        with open(path, "wb") as f:
            f.write(out)
        return len(out)


# ---- small math helpers (quaternions as x, y, z, w, like Godot and glTF)
def qmul(a, b):
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return np.array([aw * bx + ax * bw + ay * bz - az * by, aw * by - ax * bz + ay * bw + az * bx,
                     aw * bz + ax * by - ay * bx + az * bw, aw * bw - ax * bx - ay * by - az * bz])


def qinv(q):
    return np.array([-q[0], -q[1], -q[2], q[3]]) / np.dot(q, q)


def qrot(q, v):
    p = np.array([v[0], v[1], v[2], 0.0])
    return qmul(qmul(q, p), qinv(q))[:3]


def qmat(q):
    x, y, z, w = q / np.linalg.norm(q)
    return np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                     [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
                     [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])


def qarc(a, b):
    """Shortest rotation taking direction a to b."""
    a = a / np.linalg.norm(a)
    b = b / np.linalg.norm(b)
    c = np.cross(a, b)
    d = float(np.dot(a, b))
    if d < -0.999999:
        ax = np.cross(a, [1, 0, 0])
        if np.linalg.norm(ax) < 1e-6:
            ax = np.cross(a, [0, 1, 0])
        ax /= np.linalg.norm(ax)
        return np.array([ax[0], ax[1], ax[2], 0.0])
    q = np.array([c[0], c[1], c[2], 1 + d])
    return q / np.linalg.norm(q)


def qaxis(axis, ang):
    axis = np.asarray(axis, float) / np.linalg.norm(axis)
    s = np.sin(ang / 2)
    return np.array([axis[0] * s, axis[1] * s, axis[2] * s, np.cos(ang / 2)])


def xform(q, t):
    m = np.eye(4)
    m[:3, :3] = qmat(q)
    m[:3, 3] = t
    return m
