#!/usr/bin/env python3
"""Every texture in Godot .pck files: format, size, mips, bytes on disk and bytes in GPU memory on the web.

usage: tools/qa/packmemory.py <a.pck> [b.pck ...] [--files] [--json out.json] [--md out.md]

Why (workstream PHONE-MEMORY, Nov 16 2026, production/qa/evidence/wsPHONE-MEMORY-findings.md): iPhone Safari
crashed with two wings in memory. This says where the texture memory of each pack goes, by kind.

GPU bytes are what Godot's Compatibility renderer (WebGL 2) uploads, read from the engine source of 4.7.2
(drivers/gles3/storage/texture_storage.cpp `_get_gl_image_and_format`, config.cpp):
  - PNG / WebP (lossless or lossy) are decoded on the CPU and uploaded uncompressed: L8 1 B/px, LA8 2,
    RGB8 counted as 4 (WebGL RGB8 is stored as 4 bytes a pixel on Apple GPUs and most others), RGBA8 4.
  - ETC2 / ASTC LDR / S3TC / BPTC stay compressed when the browser has the extension (iPhone: ETC2, ASTC LDR).
  - ASTC HDR (the mobile lightmaps) is NEVER treated as supported on the web: astc_hdr_supported needs the GL
    extension name GL_KHR_texture_compression_astc_hdr, which WebGL does not list (HDR is a profile of
    WEBGL_compressed_texture_astc). Godot decompresses it on the CPU (astcenc) to RGBAH: 8 B/px.
  - Mipmaps: the whole chain when the file has one.
"""
import json
import re
import struct
import sys

sys.path.insert(0, __file__.rsplit("/", 1)[0])
import packformats as pf  # noqa: E402

# bytes per pixel, uploaded (web), by Image format name
BPP_UP = {"L8": 1, "LA8": 2, "R8": 1, "RG8": 2, "RGB8": 4, "RGBA8": 4, "RGBA4444": 2, "RGB565": 2,
          "RF": 4, "RGF": 8, "RGBF": 16, "RGBAF": 16, "RH": 2, "RGH": 4, "RGBH": 8, "RGBAH": 8,
          "RGBE9995": 4, "DXT1": 0.5, "DXT3": 1, "DXT5": 1, "RGTC_R": 0.5, "RGTC_RG": 1,
          "BPTC_RGBA": 1, "BPTC_RGBF": 1, "BPTC_RGBFU": 1, "ETC": 0.5, "ETC2_R11": 0.5, "ETC2_R11S": 0.5,
          "ETC2_RG11": 1, "ETC2_RG11S": 1, "ETC2_RGB8": 0.5, "ETC2_RGBA8": 1, "ETC2_RGB8A1": 0.5,
          "ETC2_RA_AS_RG": 2, "DXT5_RA_AS_RG": 2,  # the *_RA_AS_RG are decompressed to RG8 on the web
          "ASTC_4x4": 1, "ASTC_4x4_HDR": 8, "ASTC_8x8": 0.25, "ASTC_8x8_HDR": 8}  # HDR: decompressed to RGBAH


def chain(w, h, mips):
    """pixels in a mip chain of `mips` extra levels"""
    px = 0
    for _ in range(mips + 1):
        px += w * h
        w, h = max(1, w // 2), max(1, h // 2)
    return px


def kind_of(src, fmt):
    s = src.lower()
    if s.endswith(".exr") or "lightmap" in s:
        return "lightmap"
    if s.startswith(("cast/", "npc/")):
        return "cast" + (" normal" if "normal" in s else "")
    if "normal" in s or "_nrm" in s:
        return "normal"
    if s.startswith("tex/standin/"):
        return "stand-in"
    if s.startswith(("tex/items/", "tex/dir/", "tex/ui", "addons/", "fonts/", "icon", "tex/hud", "prizes/")):
        return "ui"
    if s.startswith("models/bl_"):
        return "items 3D"
    return "albedo"


def read_pack(path):
    rows = []
    with open(path, "rb") as f:
        ver, files = pf.read_dir(f)
        # imported file -> source file, from the .import stubs inside the pack
        src = {}
        for p, off, size, _ in files:
            if p.endswith(".import"):
                f.seek(off)
                t = f.read(size).decode("utf-8", "replace")
                for m in re.finditer(r'^path(?:\.\w+)?="res://([^"]+)"', t, re.M):
                    src[m.group(1)] = p[:-len(".import")]
        for p, off, size, _ in files:
            if not p.endswith((".ctex", ".ctexarray", ".ctex3d", ".ccube", ".ccubearray")):
                continue
            f.seek(off)
            head = f.read(64)
            layers = 1
            if head[:4] == b"GST2":
                data, w, h, mips, fmt = struct.unpack("<IHHII", head[36:52])
            elif head[:4] == b"GSTL":
                layers = struct.unpack("<I", head[8:12])[0]
                data, w, h, mips, fmt = struct.unpack("<IHHII", head[36:52])
            else:
                continue
            name = pf.FMT.get(fmt, str(fmt))
            d = pf.DATA.get(data, str(data))
            if d == "webp":
                f.seek(off + (52 if head[:4] == b"GST2" else 52))
                d = "webp-lossless" if b"VP8L" in f.read(40) else "webp-lossy"
            gpu = int(chain(w, h, mips) * BPP_UP.get(name, 4) * layers)
            s = src.get(p, p)
            rows.append({"src": s, "file": p, "store": d, "format": name, "w": w, "h": h, "mips": mips,
                         "layers": layers, "disk": size, "gpu": gpu, "kind": kind_of(s, name),
                         "family": pf.family(name, d)})
        total = sum(s for _, _, s, _ in files)
    return {"pack": path, "bytes": total, "textures": rows}


def summary(r):
    k = {}
    for t in r["textures"]:
        a = k.setdefault(t["kind"], {"n": 0, "disk": 0, "gpu": 0})
        a["n"] += 1
        a["disk"] += t["disk"]
        a["gpu"] += t["gpu"]
    return k


def main(argv):
    pcks = [a for a in argv if a.endswith(".pck")]
    out = argv[argv.index("--json") + 1] if "--json" in argv else None
    md = argv[argv.index("--md") + 1] if "--md" in argv else None
    res = [read_pack(p) for p in pcks]
    lines = []
    for r in res:
        s = summary(r)
        td = sum(v["disk"] for v in s.values())
        tg = sum(v["gpu"] for v in s.values())
        lines.append("### %s: %.1f MB pack; textures %d files, %.1f MB on disk, %.1f MB in GPU memory"
                     % (r["pack"].rsplit("/", 1)[-1], r["bytes"] / 1e6, len(r["textures"]), td / 1e6, tg / 1e6))
        lines.append("")
        lines.append("| Kind | Files | MB on disk | MB in GPU memory (web) |")
        lines.append("|---|---|---|---|")
        for kk in sorted(s, key=lambda x: -s[x]["gpu"]):
            v = s[kk]
            lines.append("| %s | %d | %.1f | %.1f |" % (kk, v["n"], v["disk"] / 1e6, v["gpu"] / 1e6))
        fams = {}
        for t in r["textures"]:
            key = "%s %s" % (t["store"] if t["store"] != "image" else "vram", t["format"])
            a = fams.setdefault(key, [0, 0, 0])
            a[0] += 1
            a[1] += t["disk"]
            a[2] += t["gpu"]
        lines.append("")
        lines.append("| Stored as | Files | MB on disk | MB in GPU memory (web) |")
        lines.append("|---|---|---|---|")
        for kk in sorted(fams, key=lambda x: -fams[x][2]):
            a = fams[kk]
            lines.append("| %s | %d | %.1f | %.1f |" % (kk, a[0], a[1] / 1e6, a[2] / 1e6))
        lines.append("")
        if "--files" in argv:
            lines.append("| Source | Kind | Stored | Format | Size | Mips | Layers | Bytes on disk | Bytes in GPU |")
            lines.append("|---|---|---|---|---|---|---|---|---|")
            for t in sorted(r["textures"], key=lambda t: -t["gpu"]):
                lines.append("| %s | %s | %s | %s | %dx%d | %d | %d | %d | %d |" % (
                    t["src"], t["kind"], t["store"], t["format"], t["w"], t["h"], t["mips"], t["layers"],
                    t["disk"], t["gpu"]))
            lines.append("")
    text = "\n".join(lines)
    print(text)
    if md:
        open(md, "w").write(text + "\n")
    if out:
        json.dump(res, open(out, "w"), indent=1)


if __name__ == "__main__":
    main(sys.argv[1:])
