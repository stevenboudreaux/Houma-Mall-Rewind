"""Build one Blender asset end to end. Run through tools/blender/run.sh <asset>.

  assets_src/<asset>.py  defines META (dict) and build() (makes the parts in an empty scene)
  -> clean (weld, triangulate, join) -> budget check -> UV0 + bake -> models/<asset>/<asset>.glb + PNGs
  -> re-import the .glb -> turntable renders + icon -> .scratch/blender/<asset>-sheet.png
  -> data/items/blender_props.json entry (when META has "item")

Flags: --fast (low samples, 512 px sheet tiles: for iterating), --no-sheet.
"""
import importlib.util
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.abspath(os.path.join(HERE, "..", ".."))
REPO = os.path.abspath(os.path.join(PROJ, "..", "..", ".."))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "assets_src"))   # shared helpers (_plush.py)

import bpy  # noqa: E402
from lib import core, mats, clean, bake, render  # noqa: E402


def load_asset(name):
    p = os.path.join(HERE, "assets_src", name + ".py")
    if not os.path.exists(p):
        raise SystemExit("no asset source %s" % p)
    spec = importlib.util.spec_from_file_location("asset_" + name, p)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


KEEP_ORIG = True


def export_glb(path, objs):
    core.select_only(objs, objs[0])
    with bpy.context.temp_override(selected_objects=objs, active_object=objs[0]):
        bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_yup=True,
                                  export_apply=True, export_texcoords=True, export_normals=True,
                                  export_tangents=False, export_materials="EXPORT", export_image_format="AUTO",
                                  export_keep_originals=KEEP_ORIG, export_cameras=False, export_lights=False, export_animations=False)


def set_emissive(path, strength):
    """META["emissive"]: the baked material glows faintly with its own albedo (emissive texture = the
    albedo, factor = strength), e.g. Folse's stick, whose stand-in had emission 0.9 on white."""
    import struct
    with open(path, "rb") as f:
        d = f.read()
    n = struct.unpack("<I", d[12:16])[0]
    j = json.loads(d[20:20 + n])
    for m in j.get("materials", []):
        bc = m.get("pbrMetallicRoughness", {}).get("baseColorTexture")
        if bc is not None:
            m["emissiveTexture"] = {"index": bc["index"]}
            m["emissiveFactor"] = [strength] * 3
    js = json.dumps(j, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    rest = d[20 + n:]
    out = d[:12] + struct.pack("<I", len(js)) + d[16:20] + js + rest
    out = out[:8] + struct.pack("<I", len(out)) + out[12:]
    with open(path, "wb") as f:
        f.write(out)


def fix_glb_uris(path):
    """Blender's GLB + keep-originals export gives each image both a URI and a 250-byte placeholder
    bufferView. Keep only the URI, so Godot loads the PNGs that sit beside the .glb (one copy of each
    texture in the repo, imported and compressed by Godot like every other texture)."""
    import struct
    with open(path, "rb") as f:
        d = f.read()
    n = struct.unpack("<I", d[12:16])[0]
    j = json.loads(d[20:20 + n])
    for im in j.get("images", []):
        if "uri" in im:
            im.pop("bufferView", None)
            im.pop("mimeType", None)
    js = json.dumps(j, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    rest = d[20 + n:]
    out = d[:12] + struct.pack("<I", len(js)) + d[16:20] + js + rest
    out = out[:8] + struct.pack("<I", len(out)) + out[12:]
    with open(path, "wb") as f:
        f.write(out)


def split_kept(ob, keys):
    """META["hipoly_keep"]: faces whose material name contains one of these strings (e.g. a plinth already
    built low-poly) are split off before the low-poly remesh/decimation and joined back after. Returns the
    split-off object or None."""
    import bmesh
    if not keys:
        return None
    idx = {i for i, m in enumerate(ob.data.materials) if m and any(k in m.name for k in keys)}
    if not idx:
        return None
    kept = core.duplicate(ob, ob.name + "_kept")
    for o, drop_kept in ((ob, True), (kept, False)):
        bm = bmesh.new()
        bm.from_mesh(o.data)
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if (f.material_index in idx) == drop_kept], context="FACES")
        bm.to_mesh(o.data)
        bm.free()
    return kept


def compose_sheet(meta, tiles, out, info, tile=400):
    from PIL import Image, ImageDraw, ImageFont
    refs = []
    for r in meta.get("refs", []):
        p = os.path.join(REPO, r[0])
        if not os.path.exists(p):
            print("REF MISSING (fetch the refs branch): " + r[0])
            continue
        im = Image.open(p).convert("RGB")
        if len(r) > 1 and r[1]:
            w, h = im.size
            x0, y0, x1, y1 = r[1]
            im = im.crop((int(x0 * w), int(y0 * h), int(x1 * w), int(y1 * h)))
        refs.append((im, r[2] if len(r) > 2 else os.path.basename(r[0])))
    if not refs:
        info += "  |  NO REFERENCE IMAGE" + (" (missing: fetch refs)" if meta.get("refs") else " (none given)")
    cells = [(im, cap) for im, cap in refs] + [(Image.open(t).convert("RGB"), lab) for t, lab in zip(tiles, render.LABELS)]
    cols = 4
    rows = (len(cells) + cols - 1) // cols
    bar = 44
    sheet = Image.new("RGB", (cols * tile, rows * tile + bar), (24, 24, 28))
    d = ImageDraw.Draw(sheet)
    try:
        f = ImageFont.truetype(os.path.join(PROJ, "fonts", "sans.otf"), 16)
        fb = ImageFont.truetype(os.path.join(PROJ, "fonts", "sans.otf"), 20)
    except Exception:
        f = fb = ImageFont.load_default()
    for i, (im, cap) in enumerate(cells):
        im.thumbnail((tile, tile))
        x, y = (i % cols) * tile, (i // cols) * tile
        sheet.paste(im, (x + (tile - im.width) // 2, y + (tile - im.height) // 2))
        tag = ("REF: " if i < len(refs) else "") + cap
        d.rectangle((x, y, x + min(tile, 10 + 9 * len(tag)), y + 22), fill=(0, 0, 0))
        d.text((x + 5, y + 3), tag, fill=(255, 220, 90) if i < len(refs) else (230, 230, 230), font=f)
    d.text((10, rows * tile + 11), info, fill=(240, 240, 240), font=fb)
    sheet.save(out)
    ev = meta.get("evidence")
    return out


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    name = argv[0]
    fast = "--fast" in argv
    t0 = time.time()
    mod = load_asset(name)
    meta = mod.META
    aid = meta["id"]
    cls = meta["class"]
    out_dir = os.path.join(PROJ, "models", aid)
    scratch = os.path.join(PROJ, ".scratch", "blender")
    os.makedirs(scratch, exist_ok=True)
    os.makedirs(out_dir, exist_ok=True)

    core.reset()
    mats.ASSET = aid.replace("bl_", "", 1)
    mod.build()
    main_ob, cols = clean.finalize(aid)
    high = None
    if meta.get("hipoly"):
        # sculpt-style asset: build() made a dense mesh; a budget copy gets its detail as baked maps
        high = main_ob
        high.name = aid + "_high"
        main_ob = core.duplicate(high, aid)
        main_ob.data.name = aid
        print("HIPOLY %s: %d triangles -> decimating a copy to %d" % (aid, clean.tri_count(high), meta["hipoly"]))
        # the copy inherits the sculpt's custom normals, which no longer fit after decimation
        with bpy.context.temp_override(object=main_ob, active_object=main_ob):
            bpy.ops.mesh.customdata_custom_splitnormals_clear()
        kept = split_kept(main_ob, meta.get("hipoly_keep", []))
        if meta.get("lowpoly_voxel"):
            # a smooth coarse remesh first: even topology, so the decimated copy unwraps into big UV islands
            # instead of confetti, and its normals are soft (the detail comes back in the normal map)
            rm = main_ob.modifiers.new("Remesh", "REMESH")
            rm.mode = "VOXEL"
            rm.voxel_size = meta["lowpoly_voxel"]
            sm = main_ob.modifiers.new("Smooth", "LAPLACIANSMOOTH")
            sm.iterations = 4
            sm.use_volume_preserve = True
            core.apply_all(main_ob)
            print("LOWPOLY remeshed at %.4f m: %d triangles" % (meta["lowpoly_voxel"], clean.tri_count(main_ob)))
        clean.decimate(main_ob, meta["hipoly"] - (clean.tri_count(kept) if kept else 0))
        tr = main_ob.modifiers.new("Tri", "TRIANGULATE")     # the remesh's quads and the decimation's n-gons
        core.apply_all(main_ob)
        if kept:
            core.select_only([main_ob, kept], main_ob)
            with bpy.context.temp_override(active_object=main_ob, selected_editable_objects=[main_ob, kept], selected_objects=[main_ob, kept]):
                bpy.ops.object.join()
        for p in main_ob.data.polygons:
            p.use_smooth = True
        main_ob.data.set_sharp_from_angle(angle=3.1)   # smooth shading on the sculpt
    elif meta.get("decimate"):
        clean.decimate(main_ob, clean.budgets()["classes"][cls]["tris"])
    tris, lim = clean.check_budget(main_ob, cls)
    ng = clean.ngons(main_ob)
    if ng:
        raise SystemExit("EXPORT CHECK: %d n-gons left in %s" % (ng, aid))
    size = meta.get("tex", 1024)
    if size & (size - 1) or not 256 <= size <= 2048:
        raise SystemExit("tex must be a power of two, 512-2048 (got %d)" % size)
    written = bake.bake_object(main_ob, aid, out_dir, size=size, ao=meta.get("ao", 0.0),
                               normal=meta.get("normal", True), uv=meta.get("uv", "smart"),
                               samples=8 if fast else 16, source=high, cage=meta.get("cage", 0.02),
                               uv_shrink=meta.get("uv_shrink"))
    if high is not None:
        bpy.data.objects.remove(high)
        bpy.context.view_layer.update()
    glb = os.path.join(out_dir, aid + ".glb")
    export_glb(glb, [main_ob] + cols)
    fix_glb_uris(glb)
    if meta.get("emissive"):
        set_emissive(glb, float(meta["emissive"]))
    t_build = time.time() - t0
    # the review renders, from the exported file
    tiles = []
    if "--no-sheet" not in argv:
        tiles = render.turntable(glb, scratch, aid, res=320 if fast else 480, samples=16 if fast else 48)
    icon = None
    if meta.get("item") or meta.get("icon"):    # "icon": an icon without an item entry (the item lives elsewhere)
        icon = render.icon(glb, os.path.join(out_dir, aid + "_icon.png"), samples=24 if fast else 64)
    kb = sum(os.path.getsize(p) for p in written) // 1024
    info = "%s  |  %s  |  %d tris (budget %s)  |  textures %d px x %d maps (%d KB)  |  glb %d KB" % (
        aid, cls, tris, lim, size, len(written), kb, os.path.getsize(glb) // 1024)
    if tiles:
        sheet = compose_sheet(meta, tiles, os.path.join(scratch, aid + "-sheet.png"), info)
        print("SHEET " + sheet)
    if meta.get("item"):
        write_item(meta, aid, cls)
    report = {"id": aid, "class": cls, "tris": tris, "budget": lim, "tex": size, "maps": [os.path.basename(p) for p in written],
              "glb_kb": os.path.getsize(glb) // 1024, "tex_kb": kb, "seconds": round(time.time() - t0, 1), "build_seconds": round(t_build, 1)}
    with open(os.path.join(scratch, aid + "-report.json"), "w") as f:
        json.dump(report, f, indent=1)
    print("BUILD OK " + json.dumps(report))


def write_item(meta, aid, cls):
    # META["item_file"]: which data/items/ file holds the entry (workstream T2 writes blender_props_2.json)
    p = os.path.join(PROJ, "data", "items", meta.get("item_file", "blender_props.json"))
    data = {"_": "Items modelled in Blender (tools/blender/, design/godot-blender-pipeline.md). Same shape as the "
                 "Godot-built item list: id, name, class (hand|pocket), scene, icon, year, place (optional). "
                 "Written by tools/blender/build.py from each asset's META['item'].", "items": []}
    if os.path.exists(p):
        with open(p) as f:
            data = json.load(f)
    it = {"id": aid, "name": meta["item"]["name"], "class": cls,
          "scene": "res://models/%s/%s.glb" % (aid, aid), "icon": "res://models/%s/%s_icon.png" % (aid, aid),
          "year": meta["item"].get("year", 1995)}
    for k, v in meta["item"].items():
        if k not in ("name", "year", "copies"):
            it[k] = v
    # "copies": more pick-ups of the same model, [{"id": ..., "place": {...}}, ...] (e.g. a table of paperbacks)
    new = [it] + [dict(it, **c) for c in meta["item"].get("copies", [])]
    ids = set(x["id"] for x in new)
    data["items"] = [x for x in data["items"] if x["id"] not in ids] + new
    data["items"].sort(key=lambda x: x["id"])
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w") as f:
        json.dump(data, f, indent=1)
        f.write("\n")


if __name__ == "__main__":
    main()
