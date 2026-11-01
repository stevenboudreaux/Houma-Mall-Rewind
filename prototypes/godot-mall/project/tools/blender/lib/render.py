"""Turntable sheet and icon renders (Cycles CPU, AgX, neutral studio light).

The sheet is rendered from the exported .glb re-imported into an empty scene, so it shows exactly what
Godot receives (baked textures, normals, triangulation), not the authoring scene.
"""
import math
import os
import bpy
from mathutils import Vector

from . import core

# (yaw, elevation, zoom) in degrees; yaw 0 = the front (Blender -Y = Godot +Z)
ANGLES = [(0, 12, 1.0), (40, 28, 1.0), (90, 8, 1.0), (180, 18, 1.0), (-130, 45, 1.0), (25, 20, 2.2)]
LIGHT_GAIN = 1.0
LABELS =["front", "front 3/4", "side", "back", "back 3/4, above", "close-up"]


def studio(world_grey=0.20, strength=1.0):
    sc = bpy.context.scene
    w = bpy.data.worlds.new("studio")
    w.use_nodes = True
    bg = w.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (world_grey, world_grey, world_grey, 1)
    bg.inputs["Strength"].default_value = strength
    sc.world = w
    sc.view_settings.view_transform = "AgX"
    sc.view_settings.look = "None"
    sc.view_settings.exposure = 0.0
    sc.view_settings.gamma = 1.0
    sc.render.engine = "CYCLES"
    sc.cycles.samples = 48
    sc.cycles.use_denoising = True
    try:
        sc.cycles.denoiser = "OPENIMAGEDENOISE"
    except Exception:
        pass
    sc.render.film_transparent = False


def _light(name, kind, energy, loc, size=1.0, color=(1, 1, 1)):
    ld = bpy.data.lights.new(name, kind)
    ld.energy = energy
    ld.color = color
    if kind == "AREA":
        ld.size = size
    ob = bpy.data.objects.new(name, ld)
    core.link(ob)
    ob.location = loc
    d = -Vector(loc)
    ob.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    return ob


def rig(center, radius):
    """Key, fill and rim area lights scaled to the object."""
    s = max(radius, 0.05)
    k = 4.0 * s
    for name, e, off in (("key", 60, (-1.0, -1.2, 1.3)), ("fill", 18, (1.4, -0.8, 0.4)), ("rim", 35, (0.4, 1.5, 1.0))):
        # power grows with distance squared so a 5 cm pager and a 1 m register get the same exposure
        _light(name, "AREA", e * k * k * LIGHT_GAIN, center + Vector(off) * k, size=k * 0.8)


def camera(fov=30.0):
    cd = bpy.data.cameras.new("cam")
    cd.lens_unit = "FOV"
    cd.angle = math.radians(fov)
    cd.clip_start = 0.001
    cd.clip_end = 100
    cam = bpy.data.objects.new("cam", cd)
    core.link(cam)
    bpy.context.scene.camera = cam
    return cam


def aim(cam, center, radius, yaw, elev, zoom=1.0, fov=30.0):
    d = radius / math.sin(math.radians(fov) / 2) * 1.08 / zoom
    y, e = math.radians(yaw), math.radians(elev)
    pos = center + Vector((math.sin(y) * math.cos(e), -math.cos(y) * math.cos(e), math.sin(e))) * d
    cam.location = pos
    cam.rotation_euler = (center - pos).to_track_quat("-Z", "Y").to_euler()


def import_glb(path):
    core.reset()
    bpy.ops.import_scene.gltf(filepath=path)
    objs = core.mesh_objects()
    vis = [o for o in objs if not o.name.endswith(("-col", "-convcol", "-colonly"))]
    for o in objs:
        if o not in vis:
            o.hide_render = True
    return vis


def floor(z, size):
    import bmesh
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=size)
    ob = core.obj_from_bmesh("floor", bm)
    ob.location.z = z
    m = bpy.data.materials.new("floor")
    m.use_nodes = True
    m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.16, 0.16, 0.16, 1)
    m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.8
    ob.data.materials.append(m)
    return ob


def turntable(glb, out_dir, prefix, res=480, samples=48):
    """Renders the six ANGLES to <out_dir>/<prefix>-tt<i>.png; returns paths."""
    vis = import_glb(glb)
    lo, hi = core.bounds(vis)
    c = (lo + hi) / 2
    r = (hi - lo).length / 2
    studio()
    bpy.context.scene.cycles.samples = samples
    floor(lo.z - 0.0005, r * 20)
    rig(c, r)
    cam = camera()
    sc = bpy.context.scene
    sc.render.resolution_x = sc.render.resolution_y = res
    sc.render.image_settings.file_format = "PNG"
    paths = []
    for i, (yaw, el, zm) in enumerate(ANGLES):
        aim(cam, c, r, yaw, el, zm)
        p = os.path.join(out_dir, "%s-tt%d.png" % (prefix, i))
        sc.render.filepath = p
        bpy.ops.render.render(write_still=True)
        paths.append(p)
    return paths


def icon(glb, path, res=256, yaw=30, elev=25, samples=64):
    """A 256 px inventory icon with a transparent background."""
    vis = import_glb(glb)
    lo, hi = core.bounds(vis)
    c = (lo + hi) / 2
    r = (hi - lo).length / 2
    studio(0.35, 1.0)
    sc = bpy.context.scene
    sc.cycles.samples = samples
    sc.render.film_transparent = True
    rig(c, r)
    cam = camera(26.0)
    aim(cam, c, r, yaw, elev, 1.12, 26.0)
    sc.render.resolution_x = sc.render.resolution_y = res
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path
