"""Scene and object basics for the Blender asset scripts (tools/blender/).

Axes: Blender is Z-up. The glTF exporter converts to Godot's +Y up on export (export_yup), so assets are
modelled in Blender's own axes:  Blender X = Godot X,  Blender Z (up) = Godot Y,  Blender -Y (the "front"
in Blender's front view) = Godot +Z (toward a player standing in front of a prop that faces +Z... i.e. the
player stands at +Z and looks toward -Z, as in tools/qa/preview.gd). Units are metres.
Origins: bottom centre of the item in its resting/held pose unless the asset says otherwise.
"""
import math
import bmesh
import bpy
from mathutils import Matrix, Vector

TAU = math.tau


def reset():
    """Empty the scene (factory settings, metres, Cycles)."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.unit_settings.system = "METRIC"
    sc.unit_settings.scale_length = 1.0
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    return sc


def link(obj, coll=None):
    (coll or bpy.context.scene.collection).objects.link(obj)
    return obj


def obj_from_bmesh(name, bm, mat=None, smooth=False):
    """Make a linked mesh object from a bmesh (frees the bmesh)."""
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    link(ob)
    if mat is not None:
        me.materials.append(mat)
    if smooth:
        for p in me.polygons:
            p.use_smooth = True
    return ob


def set_mat(ob, mat):
    ob.data.materials.clear()
    ob.data.materials.append(mat)
    return ob


def place(ob, loc=(0, 0, 0), rot=(0, 0, 0), scale=None):
    """Set location (m) and rotation (degrees, XYZ Euler)."""
    ob.location = Vector(loc)
    ob.rotation_euler = [math.radians(a) for a in rot]
    if scale is not None:
        ob.scale = Vector(scale) if hasattr(scale, "__len__") else Vector((scale,) * 3)
    return ob


def bevel(ob, width=0.002, segments=2, angle=35.0, profile=0.5, harden=True):
    """Bevel modifier limited by angle: the house rule is 'Bevel always on hard edges'."""
    m = ob.modifiers.new("Bevel", "BEVEL")
    m.width = width
    m.segments = segments
    m.limit_method = "ANGLE"
    m.angle_limit = math.radians(angle)
    m.profile = profile
    m.harden_normals = harden
    m.use_clamp_overlap = True
    return m


def subsurf(ob, levels=1):
    """Subdivision, only where the shape is curved."""
    m = ob.modifiers.new("Subdivision", "SUBSURF")
    m.levels = levels
    m.render_levels = levels
    return m


def array(ob, count, offset=(1, 0, 0), relative=True, constant=None):
    m = ob.modifiers.new("Array", "ARRAY")
    m.count = count
    if constant is not None:
        m.use_relative_offset = False
        m.use_constant_offset = True
        m.constant_offset_displace = constant
    else:
        m.relative_offset_displace = offset
    return m


def mirror(ob, axes=(True, False, False), merge=0.0005):
    m = ob.modifiers.new("Mirror", "MIRROR")
    m.use_axis = axes
    m.use_mirror_merge = True
    m.merge_threshold = merge
    return m


def solidify(ob, thickness=0.002, offset=-1.0):
    m = ob.modifiers.new("Solidify", "SOLIDIFY")
    m.thickness = thickness
    m.offset = offset
    return m


def weighted_normals(ob):
    m = ob.modifiers.new("WeightedNormal", "WEIGHTED_NORMAL")
    m.keep_sharp = True
    return m


def apply_all(ob):
    """Bake every modifier and the object transform into the mesh."""
    dg = bpy.context.evaluated_depsgraph_get()
    ev = ob.evaluated_get(dg)
    me = bpy.data.meshes.new_from_object(ev, preserve_all_data_layers=True, depsgraph=dg)
    old = ob.data
    ob.modifiers.clear()
    ob.data = me
    if old.users == 0:
        bpy.data.meshes.remove(old)
    me.transform(ob.matrix_basis)
    ob.matrix_basis = Matrix.Identity(4)
    return ob


def duplicate(ob, name=None, linked=False):
    n = ob.copy()
    if not linked:
        n.data = ob.data.copy()
    n.name = name or ob.name + "_dup"
    link(n)
    return n


def bounds(objs):
    """World-space (min, max) of a list of objects."""
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    dg = bpy.context.evaluated_depsgraph_get()
    for ob in objs:
        ev = ob.evaluated_get(dg)
        for c in ev.bound_box:
            w = ob.matrix_world @ Vector(c)
            lo = Vector(map(min, lo, w))
            hi = Vector(map(max, hi, w))
    return lo, hi


def mesh_objects():
    return [o for o in bpy.context.scene.objects if o.type == "MESH"]


def select_only(objs, active=None):
    for o in bpy.context.view_layer.objects:
        if o is not None:
            o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = active or (objs[0] if objs else None)


def freeze(objs):
    """Apply modifiers and transforms, then store every vertex's current position in a 'src_co' point
    attribute. Materials made with mats.M(..., frozen=True) map patterns and decals from it, so the parts
    can then be moved, tilted or arrayed and their labels travel with them."""
    for ob in objs:
        apply_all(ob)
        me = ob.data
        at = me.attributes.get("src_co") or me.attributes.new("src_co", "FLOAT_VECTOR", "POINT")
        for v, d in zip(me.vertices, at.data):
            d.vector = v.co
    return objs
