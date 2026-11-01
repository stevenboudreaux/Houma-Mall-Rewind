"""Clean-up, triangulation and the polygon budget check.

finalize(asset) : every mesh part gets a Weld (merge by distance) at the top of its stack and a
Triangulate (keeping custom normals from Bevel's harden-normals) at the bottom, all modifiers are applied,
and the non-collision parts are joined into one object named <asset>. Collision parts (names ending in
-col, -convcol, -colonly: Godot's import suffixes) stay separate, without materials.
"""
import json
import math
import os
import bpy

from . import core

COL_SUFFIXES = ("-col", "-convcol", "-colonly")
HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def is_collision(ob):
    return ob.name.endswith(COL_SUFFIXES)


def budgets():
    with open(os.path.join(HERE, "budgets.json")) as f:
        return json.load(f)


def prep_part(ob, weld=0.00005):
    """Merge-by-distance first, triangulate last, then apply."""
    w = ob.modifiers.new("Weld", "WELD")
    w.merge_threshold = weld
    # move the weld to the top of the stack
    while ob.modifiers.find("Weld") > 0:
        bpy.context.view_layer.objects.active = ob
        with bpy.context.temp_override(object=ob):
            bpy.ops.object.modifier_move_up(modifier="Weld")
    t = ob.modifiers.new("Triangulate", "TRIANGULATE")
    t.quad_method = "BEAUTY"
    t.ngon_method = "BEAUTY"
    t.keep_custom_normals = True
    core.apply_all(ob)


def finalize(asset):
    parts = [o for o in core.mesh_objects()]
    for o in parts:
        prep_part(o)
    vis = [o for o in parts if not is_collision(o)]
    cols = [o for o in parts if is_collision(o)]
    core.select_only(vis, vis[0])
    with bpy.context.temp_override(active_object=vis[0], selected_editable_objects=vis, selected_objects=vis):
        bpy.ops.object.join()
    main = vis[0]
    main.name = asset
    main.data.name = asset
    for c in cols:
        c.data.materials.clear()
    # drop unused material slots
    used = {p.material_index for p in main.data.polygons}
    for i in reversed(range(len(main.data.materials))):
        if i not in used:
            main.data.materials.pop(index=i)
    return main, cols


def tri_count(ob):
    ob.data.calc_loop_triangles()
    return len(ob.data.loop_triangles)


def ngons(ob):
    return sum(1 for p in ob.data.polygons if len(p.vertices) > 3)


def check_budget(ob, cls):
    """Returns (tris, limit). Raises SystemExit with a clear message when over."""
    b = budgets()
    lim = b["classes"][cls]["tris"]
    n = tri_count(ob)
    if lim is None:
        print("BUDGET NOT ASSESSED: class '%s' has no triangle budget yet (budgets.json); %s has %d triangles" % (cls, ob.name, n))
    elif n > lim:
        raise SystemExit("OVER BUDGET: %s has %d triangles; the '%s' budget is %d. Lower segment counts, "
                         "drop hidden faces or bevel segments (tools/blender/assets_src). Decimation is the "
                         "last resort (META['decimate'])." % (ob.name, n, cls, lim))
    return n, lim


def decimate(ob, target):
    """Last resort: collapse-decimate to `target` triangles. The build log says when it was used."""
    n = tri_count(ob)
    if n <= target:
        return False
    m = ob.modifiers.new("Decimate", "DECIMATE")
    m.ratio = target / n * 0.98
    core.apply_all(ob)
    print("DECIMATED %s: %d -> %d triangles" % (ob.name, n, tri_count(ob)))
    return True
