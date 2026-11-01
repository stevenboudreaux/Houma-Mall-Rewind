#!/usr/bin/env python3
"""List the imported textures inside Godot .pck files and the formats they are stored in.

usage: tools/qa/packformats.py <a.pck> [b.pck ...] [--files] [--json out.json]

Why (workstream H, Nov 1 2026, design/godot-build-hosting.md): the desktop and mobile packs are
meant to differ only in texture formats (desktop S3TC/BPTC, mobile ETC2/ASTC). This reads the pack
directory (PCK format 2 or 3) and the header of every .ctex / .ctexarray / .ctex3d inside it and
sums bytes per storage kind:
  lossless/lossy  - PNG/WebP inside the ctex: the same bytes in both packs, decoded on the CPU at load
  s3tc, bptc      - desktop VRAM formats        etc2, astc - mobile VRAM formats
  raw             - uncompressed pixels (VRAM Uncompressed, or HDR the importer kept raw)
A correct desktop pack has no etc2/astc; a correct mobile pack has no s3tc/bptc.
"""
import json
import struct
import sys

FMT = {0: "L8", 1: "LA8", 2: "R8", 3: "RG8", 4: "RGB8", 5: "RGBA8", 6: "RGBA4444", 7: "RGB565",
       8: "RF", 9: "RGF", 10: "RGBF", 11: "RGBAF", 12: "RH", 13: "RGH", 14: "RGBH", 15: "RGBAH",
       16: "RGBE9995", 17: "DXT1", 18: "DXT3", 19: "DXT5", 20: "RGTC_R", 21: "RGTC_RG",
       22: "BPTC_RGBA", 23: "BPTC_RGBF", 24: "BPTC_RGBFU", 25: "ETC", 26: "ETC2_R11",
       27: "ETC2_R11S", 28: "ETC2_RG11", 29: "ETC2_RG11S", 30: "ETC2_RGB8", 31: "ETC2_RGBA8",
       32: "ETC2_RGB8A1", 33: "ETC2_RA_AS_RG", 34: "DXT5_RA_AS_RG", 35: "ASTC_4x4",
       36: "ASTC_4x4_HDR", 37: "ASTC_8x8", 38: "ASTC_8x8_HDR"}
DATA = {0: "image", 1: "png", 2: "webp", 3: "basis"}


def family(fmt_name, data):
    if data == "png":
        return "lossless"
    if data == "webp-lossless":
        return "lossless"
    if data == "webp-lossy":
        return "lossy"
    if data == "basis":
        return "basis"
    if fmt_name.startswith(("DXT", "RGTC")):
        return "s3tc"
    if fmt_name.startswith("BPTC"):
        return "bptc"
    if fmt_name.startswith("ETC"):
        return "etc2"
    if fmt_name.startswith("ASTC"):
        return "astc"
    return "raw"


def read_dir(f):
    magic = f.read(4)
    if magic != b"GDPC":
        raise SystemExit("not a pck: %r" % magic)
    ver, vmaj, vmin, vpat, flags = struct.unpack("<5I", f.read(20))
    file_base = struct.unpack("<Q", f.read(8))[0]
    if ver >= 3:
        dir_off = struct.unpack("<Q", f.read(8))[0]
        f.seek(dir_off)
    else:
        f.read(16 * 4)
    if flags & 1:
        raise SystemExit("encrypted pack directory")
    count = struct.unpack("<I", f.read(4))[0]
    files = []
    for _ in range(count):
        n = struct.unpack("<I", f.read(4))[0]
        path = f.read(n).rstrip(b"\0").decode("utf-8", "replace")
        off, size = struct.unpack("<QQ", f.read(16))
        f.read(16)
        fflags = struct.unpack("<I", f.read(4))[0] if ver >= 2 else 0
        if flags & 2:
            off += file_base
        files.append((path.replace("res://", ""), off, size, fflags))
    return (vmaj, vmin, vpat), files


def tex_info(f, off, path):
    f.seek(off)
    head = f.read(64)
    if head[:4] == b"GST2":
        _v, w, h, _df, _ml = struct.unpack("<5I", head[4:24])
        data, _w, _h, mips, fmt = struct.unpack("<IHHII", head[36:52])
        d = DATA.get(data, str(data))
        name = FMT.get(fmt, str(fmt))
        if d == "webp":
            # first mip: u32 size, then a RIFF/WEBP file whose chunk says VP8L (lossless) or VP8 (lossy)
            f.seek(off + 52)
            blob = f.read(40)
            d = "webp-lossless" if b"VP8L" in blob else "webp-lossy"
        return family(name, d), name, d, w, h, mips
    # layered (lightmaps: .ctexarray) and 3D textures: name tells the VRAM family
    for k in ("s3tc", "bptc", "etc2", "astc"):
        if "." + k + "." in path:
            return k, "?", "layered", 0, 0, 0
    return "other", "?", head[:4].decode("latin1"), 0, 0, 0


def main(argv):
    pcks = [a for a in argv if a.endswith(".pck")]
    show = "--files" in argv
    out = argv[argv.index("--json") + 1] if "--json" in argv else None
    report = {}
    for p in pcks:
        with open(p, "rb") as f:
            ver, files = read_dir(f)
            fam = {}
            rows = []
            total = sum(s for _, _, s, _ in files)
            for path, off, size, _ in files:
                if not path.endswith((".ctex", ".ctexarray", ".ctex3d", ".ccube", ".ccubearray")):
                    continue
                k, name, d, w, h, mips = tex_info(f, off, path)
                a = fam.setdefault(k, [0, 0])
                a[0] += 1
                a[1] += size
                rows.append((path, k, name, d, w, h, mips, size))
        tex = sum(v[1] for v in fam.values())
        print("%s  (Godot %d.%d.%d pack, %d files, %.1f MB; textures %.1f MB)" % (p, *ver, len(files), total / 1e6, tex / 1e6))
        for k in sorted(fam, key=lambda k: -fam[k][1]):
            print("  %-9s %5d files %8.1f MB" % (k, fam[k][0], fam[k][1] / 1e6))
        if show:
            for r in sorted(rows, key=lambda r: -r[-1]):
                print("    %-9s %-12s %-7s %5dx%-5d mips=%-2d %9d  %s" % (r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[0]))
        report[p] = {"bytes": total, "texture_bytes": tex,
                     "families": {k: {"files": v[0], "bytes": v[1]} for k, v in fam.items()}}
    if out:
        json.dump(report, open(out, "w"), indent=1)
    return report


if __name__ == "__main__":
    main(sys.argv[1:])
