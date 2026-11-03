"""Side-by-side review sheet: a reference picture beside two builds of one model at the same angles
(e.g. a new pass and the previous one), rendered with the turntable's studio light (lib/render.py).

  /home/claude/bvenv/bin/python tools/blender/compare.py -- <out.png> <ref.png> <new.glb> <old.glb> \
      [--zmin Z] [--title TEXT] [--new-label A] [--old-label B]

--zmin frames the front view on the part of the model above Z (Blender metres), e.g. the statue above its
plinth so it matches a reference that shows only the statue. Rows: reference | new front | old front | new
face | old face, then new/old 3/4, new/old side, new back. Used for the Lion's Share lion (workstream L).
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402
from lib import core, render  # noqa: E402

TILE = 320


def shots(glb, prefix, zmin, samples):
    vis = render.import_glb(glb)
    lo, hi = core.bounds(vis)
    c = (lo + hi) / 2
    r = (hi - lo).length / 2
    render.studio()
    sc = bpy.context.scene
    sc.cycles.samples = samples
    render.floor(lo.z - 0.0005, r * 20)
    render.rig(c, r)
    cam = render.camera()
    sc.render.resolution_x = sc.render.resolution_y = TILE * 2
    sc.render.image_settings.file_format = "PNG"
    # the statue above zmin, framed like the reference (straight on, near eye level)
    zl = max(lo.z, zmin)
    sc_c = Vector((c.x, c.y, (zl + hi.z) / 2))
    sr = (hi.z - zl) / 2 * 1.04
    face = Vector((c.x, lo.y, zl + (hi.z - zl) * 0.80))
    views = [("front", sc_c, sr, 0, 3), ("face", face, sr * 0.33, 8, 6), ("3/4", c, r, 40, 20), ("side", c, r, 90, 8), ("back", c, r, 180, 18)]
    out = {}
    for name, cc, rr, yaw, el in views:
        render.aim(cam, cc, rr, yaw, el)
        p = os.path.join(os.path.dirname(prefix), "%s-%s.png" % (os.path.basename(prefix), name.replace("/", "")))
        sc.render.filepath = p
        bpy.ops.render.render(write_still=True)
        out[name] = p
    return out


def main():
    a = sys.argv[sys.argv.index("--") + 1:]
    out, ref, new, old = a[:4]
    opt = dict(zip(a[4::2], a[5::2]))
    zmin = float(opt.get("--zmin", -1e9))
    samples = int(opt.get("--samples", 32))
    tmp = os.path.join(os.path.dirname(os.path.abspath(out)), "cmp")
    os.makedirs(tmp, exist_ok=True)
    N = shots(new, os.path.join(tmp, "new"), zmin, samples)
    O = shots(old, os.path.join(tmp, "old"), zmin, samples)
    from PIL import Image, ImageDraw, ImageFont
    nl, ol = opt.get("--new-label", "new"), opt.get("--old-label", "previous")
    r = Image.open(ref).convert("RGBA")
    bg = Image.new("RGBA", r.size, (0, 0, 0, 255))
    bg.alpha_composite(r)
    cells = [(bg.convert("RGB"), "REF: Steven's lion"), (N["front"], nl + " front"), (O["front"], ol + " front"),
             (N["face"], nl + " face"), (O["face"], ol + " face"),
             (N["3/4"], nl + " 3/4"), (O["3/4"], ol + " 3/4"), (N["side"], nl + " side"), (O["side"], ol + " side"), (N["back"], nl + " back")]
    cols, bar = 5, 40
    sheet = Image.new("RGB", (cols * TILE, 2 * TILE + bar), (24, 24, 28))
    d = ImageDraw.Draw(sheet)
    try:
        f = ImageFont.truetype(os.path.join(PROJ, "fonts", "sans.otf"), 16)
        fb = ImageFont.truetype(os.path.join(PROJ, "fonts", "sans.otf"), 19)
    except Exception:
        f = fb = ImageFont.load_default()
    for i, (im, cap) in enumerate(cells):
        im = im if isinstance(im, Image.Image) else Image.open(im).convert("RGB")
        im.thumbnail((TILE, TILE), Image.LANCZOS)
        x, y = (i % cols) * TILE, (i // cols) * TILE
        sheet.paste(im, (x + (TILE - im.width) // 2, y + (TILE - im.height) // 2))
        d.rectangle((x, y, x + min(TILE, 10 + 9 * len(cap)), y + 22), fill=(0, 0, 0))
        d.text((x + 5, y + 3), cap, fill=(255, 220, 90) if i == 0 else (230, 230, 230), font=f)
    d.text((10, 2 * TILE + 10), opt.get("--title", ""), fill=(240, 240, 240), font=fb)
    sheet.save(out)
    print("COMPARE " + out)


if __name__ == "__main__":
    main()
