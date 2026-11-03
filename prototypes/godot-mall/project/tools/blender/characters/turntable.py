"""Turntable renders of character .glb files (Cycles CPU, neutral studio light), imported fresh into an
empty scene so the picture is what Godot receives.

  python turntable.py OUT.png SPEC.json
SPEC: {"items": [{"glbs": ["models/characters/body_female.glb", ...], "shapes": {"weight+": 0.8, ...},
                  "pose": "apose" | "rest", "label": "..."}], "angles": [0, 90, 180], "tile": 360,
       "colors": {"skin": [r,g,b], "<material name>": [r,g,b]}, "title": "..."}
Each item is one column group (all angles); items are laid out left to right.
"""
import json
import math
import os
import sys

import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.abspath(os.path.join(HERE, "..", "..", ".."))


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def studio():
    sc = bpy.context.scene
    w = bpy.data.worlds.new("w"); w.use_nodes = True
    w.node_tree.nodes["Background"].inputs["Color"].default_value = (0.32, 0.32, 0.33, 1)
    w.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.35
    sc.world = w
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = int(os.environ.get("TT_SAMPLES", "24"))
    sc.cycles.use_denoising = True
    sc.view_settings.view_transform = "AgX"
    sc.render.film_transparent = False
    for name, e, loc in (("key", 380, (-2.5, -3.5, 3.2)), ("fill", 120, (3.5, -2.0, 1.5)), ("rim", 260, (1.0, 4.0, 3.0))):
        ld = bpy.data.lights.new(name, "AREA"); ld.energy = e; ld.size = 2.5
        ob = bpy.data.objects.new(name, ld); sc.collection.objects.link(ob)
        ob.location = loc
        ob.rotation_euler = (-Vector(loc) + Vector((0, 0, 1))).to_track_quat("-Z", "Y").to_euler()
    # floor
    bpy.ops.mesh.primitive_plane_add(size=8)
    fl = bpy.context.active_object
    m = bpy.data.materials.new("floor"); m.use_nodes = True
    m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.16, 0.16, 0.17, 1)
    fl.data.materials.append(m)


def load(items, colors):
    objs = []
    for p in items["glbs"]:
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=os.path.join(PROJ, p) if not os.path.isabs(p) else p)
        objs += [o for o in bpy.data.objects if o not in before]
    for o in objs:
        if o.type == "MESH" and o.data.shape_keys:
            for kb in o.data.shape_keys.key_blocks:
                kb.slider_min = -2; kb.slider_max = 2
                kb.value = float(items.get("shapes", {}).get(kb.name, 0.0))
        if o.type == "MESH":
            for ms in o.material_slots:
                mt = ms.material
                if not mt or not mt.use_nodes:
                    continue
                key = None
                for k in colors:
                    if k == mt.name or mt.name.startswith(k + "_") or (k == "skin" and mt.name.startswith("skin_")) \
                            or mt.name.endswith("_" + k):
                        key = k
                if key:
                    bsdf = next((n for n in mt.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
                    c = colors[key]
                    if isinstance(c, str):   # sRGB hex -> linear
                        h = c.lstrip("#"); c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
                        c = [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c]
                    tex_in = bsdf.inputs["Base Color"].links
                    if tex_in:
                        mix = mt.node_tree.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"; mix.blend_type = "MULTIPLY"
                        mix.inputs["Factor"].default_value = 1.0
                        mt.node_tree.links.new(tex_in[0].from_socket, mix.inputs[6])
                        mix.inputs[7].default_value = (c[0], c[1], c[2], 1)
                        mt.node_tree.links.new(mix.outputs[2], bsdf.inputs["Base Color"])
                    else:
                        bsdf.inputs["Base Color"].default_value = (c[0], c[1], c[2], 1)
    arms = [o for o in objs if o.type == "ARMATURE"]
    arm = arms[0] if arms else None
    if items.get("pose") == "apose":
        for a in arms:
            for pb in a.pose.bones:
                pb.matrix_basis.identity()
    for arm in (arms if items.get("turns") else []):
        # skeleton sliders: turn bones about the body's left-right axis (Blender X), parents first
        from mathutils import Matrix
        for pb in arm.pose.bones:
            deg = items["turns"].get(pb.name)
            if deg:
                bpy.context.view_layer.update()
                m = pb.matrix.copy()
                head = m.translation.copy()
                R = Matrix.Rotation(math.radians(deg), 4, "X")
                m2 = Matrix.Translation(head) @ R @ Matrix.Translation(-head) @ m
                pb.matrix = m2
    bpy.context.view_layer.update()
    return objs


def setattr_axis(pb, ax, deg):
    e = list(pb.rotation_euler); e["xyz".index(ax)] += math.radians(deg); pb.rotation_euler = e


def bounds(objs):
    lo = Vector((1e9, 1e9, 1e9)); hi = -lo
    dg = bpy.context.evaluated_depsgraph_get()
    for o in objs:
        if o.type != "MESH":
            continue
        ev = o.evaluated_get(dg)
        me = ev.to_mesh()
        for v in me.vertices:
            w = ev.matrix_world @ v.co
            lo = Vector(map(min, lo, w)); hi = Vector(map(max, hi, w))
        ev.to_mesh_clear()
    return lo, hi


def main(out, spec):
    from PIL import Image, ImageDraw
    tile = spec.get("tile", 360)
    angles = spec.get("angles", [0, 90, 180])
    tiles = []
    H = spec.get("height", 2.0)
    for it in spec["items"]:
        reset(); studio()
        cols = dict(spec.get("colors", {})); cols.update(it.get("colors", {}))
        objs = load(it, cols)
        lo, hi = bounds(objs)
        c = (lo + hi) / 2
        sc = bpy.context.scene
        sc.render.resolution_x = tile; sc.render.resolution_y = int(tile * spec.get("aspect", 1.6))
        cd = bpy.data.cameras.new("cam"); cd.lens = 85
        cam = bpy.data.objects.new("cam", cd); sc.collection.objects.link(cam); sc.camera = cam
        zoom = it.get("zoom", spec.get("zoom"))
        frame_h = (zoom or max(hi.z - lo.z, 0.5)) * 1.12
        focus = Vector((c.x, c.y, it.get("focus_z", c.z if zoom else (lo.z + hi.z) / 2)))
        cd.sensor_fit = "VERTICAL"; cd.sensor_height = 36.0
        dist = frame_h / (36 / 85)
        row = []
        for a in angles:
            r = math.radians(a)
            cam.location = focus + Vector((math.sin(r) * dist, -math.cos(r) * dist, 0.05 * dist))
            cam.rotation_euler = (focus - cam.location).to_track_quat("-Z", "Y").to_euler()
            p = os.path.join(PROJ, ".scratch", "chars", "tt_tmp.png")
            sc.render.filepath = p
            bpy.ops.render.render(write_still=True)
            row.append(Image.open(p).convert("RGB"))
        tiles.append((it.get("label", ""), row))
    w = tile * len(angles)
    hh = int(tile * spec.get("aspect", 1.6))
    cols = spec.get("cols", len(tiles))
    rows = (len(tiles) + cols - 1) // cols
    sheet = Image.new("RGB", (w * cols, (hh + 28) * rows + 34), (30, 30, 30))
    d = ImageDraw.Draw(sheet)
    d.text((8, 8), spec.get("title", ""), fill=(240, 240, 240))
    for i, (lab, row) in enumerate(tiles):
        x0 = (i % cols) * w; y0 = 34 + (i // cols) * (hh + 28)
        for j, im in enumerate(row):
            sheet.paste(im, (x0 + j * tile, y0 + 24))
        d.text((x0 + 6, y0 + 4), lab, fill=(255, 230, 160))
    sheet.save(out)
    print("SHEET", out)


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    main(argv[0], json.load(open(argv[1])))
