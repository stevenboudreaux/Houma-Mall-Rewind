"""Kits (workstream FOOD3D, Nov 8 2026): several small models built side by side in ONE asset, so they share
one bake and one atlas (the cookie case: 8 cookie kinds and 4 cookie cakes on one 1024 px set), then split
into one glTF node per piece, so the game can instance each kind on its own (MultiMesh in the case).

    tools/blender/run.sh <id>                                   # the normal build: one joined mesh, baked
    /home/claude/bvenv/bin/python tools/blender/assets_src/_kit.py <id>   # this: split + re-export

The asset's META["kit"] = {"pieces": {name: [x, y], ...}, "max_tris": 600, "skip_tris": [names]}: each
piece was modelled with its bottom centre at (x, y, 0) in Blender coordinates. Every face goes to the
piece whose (x, y) is nearest its centre (keep pieces > 2x their radius apart). Each piece's mesh is
re-centred on its own origin; its node keeps the layout offset, so the .glb still shows the laid-out kit
(the sheet, previews) while the game reads each node's mesh alone. Fails with OVER BUDGET when a piece
(not in skip_tris) has more than max_tris triangles. Writes .scratch/blender/<id>-kit.json (tris per piece).
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
BL = os.path.dirname(HERE)
sys.path.insert(0, BL)
sys.path.insert(0, HERE)


def main(aid):
    import bpy
    import bmesh
    from mathutils import Vector
    import build as B
    from lib import core, clean
    mod = B.load_asset(aid)
    kit = mod.META["kit"]
    pieces = kit["pieces"]
    out_dir = os.path.join(B.PROJ, "models", aid)
    glb = os.path.join(out_dir, aid + ".glb")
    core.reset()
    bpy.ops.import_scene.gltf(filepath=glb)
    srcs = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    for o in srcs:
        o.parent = None
        core.apply_all(o)
    if len(srcs) > 1:
        core.select_only(srcs, srcs[0])
        with bpy.context.temp_override(active_object=srcs[0], selected_editable_objects=srcs, selected_objects=srcs):
            bpy.ops.object.join()
    src = srcs[0]
    names = list(pieces)
    cents = [Vector((pieces[n][0], pieces[n][1])) for n in names]
    out, report = [], {}
    for k, name in enumerate(names):
        ob = core.duplicate(src, name)
        ob.data.name = name
        bm = bmesh.new()
        bm.from_mesh(ob.data)
        drop = []
        for f in bm.faces:
            c = f.calc_center_median()
            d = [(Vector((c.x, c.y)) - p).length for p in cents]
            if d.index(min(d)) != k:
                drop.append(f)
        bmesh.ops.delete(bm, geom=drop, context="FACES")
        off = Vector((cents[k].x, cents[k].y, 0.0))
        bmesh.ops.translate(bm, vec=-off, verts=bm.verts)
        bm.to_mesh(ob.data)
        bm.free()
        ob.location = off
        n = clean.tri_count(ob)
        report[name] = n
        if not len(ob.data.polygons):
            raise SystemExit("KIT: piece %s got no faces (check its position in META['kit'])" % name)
        if n > kit.get("max_tris", 10 ** 9) and name not in kit.get("skip_tris", []):
            raise SystemExit("OVER BUDGET: kit piece %s has %d triangles; the kit's per-piece budget is %d" % (name, n, kit["max_tris"]))
        out.append(ob)
    bpy.data.objects.remove(src)
    B.export_glb(glb, out)
    B.fix_glb_uris(glb)
    with open(os.path.join(B.PROJ, ".scratch", "blender", aid + "-kit.json"), "w") as f:
        json.dump(report, f, indent=1)
    print("KIT OK %s %s" % (aid, json.dumps(report)))


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    main(argv[0])
