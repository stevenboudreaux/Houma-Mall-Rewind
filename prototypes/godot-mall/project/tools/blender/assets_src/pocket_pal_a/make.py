"""Route A driver: builds pocket_pal_a with the project's Blender pipeline (tools/blender/lib), the one
difference from tools/blender/build.py being that the in-game mesh is modelled (not decimated) and the dense
source is baked onto it. Run:  /home/claude/bvenv/bin/python tools/blender/assets_src/pocket_pal_a/make.py [--fast]
Writes models/hud/pocket_pal_a.glb + _albedo/_orm/_normal.png, .scratch/blender/pocket_pal_a-sheet.png and
-report.json. design/godot-device-bakeoff.md."""
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
BL = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, BL)
sys.path.insert(0, HERE)

import bpy  # noqa: E402
import numpy as np  # noqa: E402
import build as drv  # noqa: E402  (tools/blender/build.py: export_glb, fix_glb_uris, compose_sheet)
from lib import core, mats, clean, bake, render  # noqa: E402
import device  # noqa: E402

AID = "pocket_pal_a"
BUDGET = 8000
TEX = 2048
META = {"id": AID, "class": "hud device", "tex": TEX,
        "refs": [["production/qa/evidence/wsDEV-ref-064.jpg", [0.22, 0.0, 0.78, 1.0], "the reference organizer (0:63): materials only"],
                 ["production/qa/evidence/wsDEV-ref-247.jpg", [0.12, 0.2, 0.82, 0.95], "keys in wells (4:06)"]]}


def join(objs, name):
    core.select_only(objs, objs[0])
    with bpy.context.temp_override(active_object=objs[0], selected_editable_objects=objs, selected_objects=objs):
        bpy.ops.object.join()
    objs[0].name = name
    objs[0].data.name = name
    return objs[0]


def finish_maps(mp):
    """Edge wear and grime, kept subtle: the source's curvature lightens and polishes the convex edges a
    little; the baked occlusion darkens the wells and seams."""
    alb, ao, curv = mp["albedo"], mp["ao"], mp["curv"]
    edge = np.clip((curv - 0.5) / max(1e-4, np.percentile(curv, 99.5) - 0.5), 0, 1) ** 1.5
    lum = alb[..., :3].mean(-1)
    dark = np.clip(1.0 - lum * 2.5, 0, 1)                    # wear shows on the dark plastic, not on print
    alb[..., :3] = alb[..., :3] * (0.42 + 0.58 * ao[..., None]) + (edge * dark * 0.035)[..., None]
    mp["rough"] = np.clip(mp["rough"] - edge * 0.10, 0.05, 1.0)
    return mp


def main():
    fast = "--fast" in sys.argv
    t0 = time.time()
    proj = drv.PROJ
    out_dir = os.path.join(proj, "models", "hud")
    scratch = os.path.join(proj, ".scratch", "blender")
    os.makedirs(out_dir, exist_ok=True)
    os.makedirs(scratch, exist_ok=True)
    core.reset()
    mats.ASSET = AID
    # 1. the in-game mesh
    low_parts, lcd = device.make(False)
    lcd.name = "lcd_keep"
    core.select_only([], None)
    lcd.hide_set(False)
    bpy.context.scene.collection.objects.unlink(lcd)         # kept out of finalize's join
    low, _ = clean.finalize(AID)
    tris = clean.tri_count(low)
    if tris > BUDGET:
        raise SystemExit("OVER BUDGET: %d triangles; the device budget is %d" % (tris, BUDGET))
    if clean.ngons(low):
        raise SystemExit("EXPORT CHECK: n-gons left")
    # 2. the dense source, with the scanned materials and the legends
    hi_parts, lcd_hi = device.make(True, device.materials(device.art()))
    bpy.data.objects.remove(lcd_hi)
    for o in hi_parts:
        core.apply_all(o)
    high = join(hi_parts, AID + "_high")
    print("HIPOLY %s: %d triangles baked onto %d" % (AID, clean.tri_count(high), tris))
    # 3. bake source -> in-game mesh (albedo, roughness, metal, normal, AO, curvature)
    written = bake.bake_object(low, AID, out_dir, size=TEX // 2 if fast else TEX, ao=0.5, source=high, cage=0.0012,
                               uv_shrink={"lowunder": 0.42}, curvature=True, finish=finish_maps, scratch=scratch,
                               samples=8 if fast else 16, ao_samples=32 if fast else 96)
    bpy.data.objects.remove(high)
    # 4. the LCD: its own material slot, UVs 0-1 across the screen, for the game to draw on
    bpy.context.scene.collection.objects.link(lcd)
    lm = mats.M("lcd", device.LCD_OLIVE, 0.25, bake=False).mat
    core.set_mat(lcd, lm)
    me = lcd.data
    up = max(me.polygons, key=lambda p: p.area * (1 if p.normal.z > 0 else 0))
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.faces.ensure_lookup_table()
    keep = bm.faces[up.index]
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f is not keep], context="FACES")
    uvl = bm.loops.layers.uv.new("UVMap")
    xs = [l.vert.co.x for l in keep.loops]
    for l in keep.loops:
        # u: left to right as the player sees it; v: bottom (hinge side) to top
        far = max(keep.loops, key=lambda k: k.vert.co.y).vert.co.y
        near = min(keep.loops, key=lambda k: k.vert.co.y).vert.co.y
        l[uvl].uv = ((l.vert.co.x - min(xs)) / (max(xs) - min(xs)), (l.vert.co.y - near) / (far - near))
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    low = join([low, lcd], AID)
    tris = clean.tri_count(low)
    glb = os.path.join(out_dir, AID + ".glb")
    drv.export_glb(glb, [low])
    drv.fix_glb_uris(glb)
    t_build = time.time() - t0
    tiles = []
    if "--no-sheet" not in sys.argv:
        tiles = render.turntable(glb, scratch, AID, res=320 if fast else 480, samples=16 if fast else 48)
    kb = sum(os.path.getsize(p) for p in written) // 1024
    info = "%s  |  %d tris (budget %d)  |  textures %d px x %d maps (%d KB)  |  glb %d KB" % (
        AID, tris, BUDGET, TEX, len(written), kb, os.path.getsize(glb) // 1024)
    if tiles:
        print("SHEET " + drv.compose_sheet(META, tiles, os.path.join(scratch, AID + "-sheet.png"), info))
    rep = {"id": AID, "tris": tris, "budget": BUDGET, "tex": TEX, "maps": [os.path.basename(p) for p in written],
           "glb_kb": os.path.getsize(glb) // 1024, "tex_kb": kb, "seconds": round(time.time() - t0, 1), "build_seconds": round(t_build, 1)}
    with open(os.path.join(scratch, AID + "-report.json"), "w") as f:
        json.dump(rep, f, indent=1)
    print("BUILD OK " + json.dumps(rep))


if __name__ == "__main__":
    main()
