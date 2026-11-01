"""Material helpers. Authoring materials may be procedural (noise, voronoi, bump); the bake step turns
every one into a single Principled BSDF with image textures, because Godot reads only that from glTF.

Names: every material is bl_<asset>_<part> (set ASSET before building, or pass full names).
"""
import bpy

ASSET = "asset"


def _name(n):
    return n if n.startswith("bl_") else "bl_%s_%s" % (ASSET, n)


def hexc(h, a=1.0):
    """'#rrggbb' (sRGB) -> linear RGBA tuple for node inputs."""
    h = h.lstrip("#")
    c = [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    lin = [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c]
    return (lin[0], lin[1], lin[2], a)


class M:
    """A small node-graph builder around one material.

    m = M("plastic"); bsdf = m.bsdf; n = m.node("ShaderNodeTexNoise", Scale=40)
    m.link(n.outputs["Fac"], bsdf.inputs["Roughness"])
    """

    def __init__(self, name, base="#808080", rough=0.5, metal=0.0, bake=True, frozen=False):
        self.mat = bpy.data.materials.new(_name(name))
        self.mat.use_nodes = True
        self.nt = self.mat.node_tree
        self.bsdf = self.nt.nodes.get("Principled BSDF")
        self.bsdf.inputs["Base Color"].default_value = hexc(base) if isinstance(base, str) else base
        self.bsdf.inputs["Roughness"].default_value = rough
        self.bsdf.inputs["Metallic"].default_value = metal
        self.mat["bake"] = bake        # False: keep as a flat material (e.g. glass), not baked into the atlas
        self.frozen = frozen           # True: patterns/decals follow core.freeze()'s src_co, not final positions
        self._x = -300

    def node(self, kind, **inputs):
        n = self.nt.nodes.new(kind)
        n.location = (self._x, 0)
        self._x -= 200
        for k, v in inputs.items():
            if k in n.inputs:
                n.inputs[k].default_value = v
            else:
                setattr(n, k, v)
        return n

    def link(self, a, b):
        self.nt.links.new(a, b)

    def coords(self, kind="Object"):
        """Texture coordinates: 'Object' = metres in the final asset space (all transforms applied, as at
        bake time). With frozen=True, 'Object' reads the src_co attribute that core.freeze() stored, so a
        part can be moved or tilted after its labels and patterns were placed."""
        if self.frozen and kind == "Object":
            a = self.node("ShaderNodeAttribute")
            a.attribute_name = "src_co"
            return a.outputs["Vector"]
        tc = self.node("ShaderNodeTexCoord")
        return tc.outputs[kind]

    def ramp(self, fac, stops):
        """ColorRamp from [(pos, '#hex'), ...]; returns the colour output."""
        r = self.node("ShaderNodeValToRGB")
        el = r.color_ramp.elements
        while len(el) > len(stops):
            el.remove(el[-1])
        while len(el) < len(stops):
            el.new(0.5)
        for e, (p, c) in zip(el, stops):
            e.position = p
            e.color = hexc(c) if isinstance(c, str) else c
        self.link(fac, r.inputs["Fac"])
        return r.outputs["Color"]

    def noise(self, scale=10.0, detail=4.0, rough=0.5, coord=None, w=None):
        n = self.node("ShaderNodeTexNoise", Scale=scale, Detail=detail, Roughness=rough)
        self.link(coord or self.coords(), n.inputs["Vector"])
        return n

    def voronoi(self, scale=10.0, feature="F1", coord=None):
        n = self.node("ShaderNodeTexVoronoi", Scale=scale)
        n.feature = feature
        self.link(coord or self.coords(), n.inputs["Vector"])
        return n

    def bump(self, height, strength=0.3, distance=0.002):
        b = self.node("ShaderNodeBump", Strength=strength, Distance=distance)
        self.link(height, b.inputs["Height"])
        self.link(b.outputs["Normal"], self.bsdf.inputs["Normal"])
        return b

    def math(self, op, a, b=None, c=None):
        """A Math node; each input is a number or a socket. Returns the output socket."""
        n = self.node("ShaderNodeMath")
        n.operation = op
        for i, v in enumerate((a, b, c)):
            if v is None:
                continue
            if isinstance(v, (int, float)):
                n.inputs[i].default_value = v
            else:
                self.link(v, n.inputs[i])
        return n.outputs[0]

    def mix(self, fac, a, b):
        """Mix two colours (sockets or '#hex')."""
        n = self.node("ShaderNodeMix")
        n.data_type = "RGBA"
        self.link(fac, n.inputs["Factor"])
        for sock, v in ((n.inputs[6], a), (n.inputs[7], b)):
            if isinstance(v, str):
                sock.default_value = hexc(v)
            else:
                self.link(v, sock)
        return n.outputs[2]

    def image(self, path, coord="UV", non_color=False):
        n = self.node("ShaderNodeTexImage")
        n.image = bpy.data.images.load(path, check_existing=True)
        if non_color:
            n.image.colorspace_settings.name = "Non-Color"
        self.link(self.coords(coord), n.inputs["Vector"])
        return n


def flat(name, base="#808080", rough=0.5, metal=0.0, bake=True):
    """A plain Principled material."""
    return M(name, base, rough, metal, bake).mat


def clear_plastic(name, tint="#e8eef0", alpha=0.22, rough=0.08):
    """Transparent blister/window plastic. Not baked (bake=False): exported as its own glTF material with
    alphaMode BLEND, which Godot imports as a transparent StandardMaterial3D."""
    m = M(name, tint, rough, 0.0, bake=False)
    m.bsdf.inputs["Alpha"].default_value = alpha
    for attr, val in (("surface_render_method", "BLENDED"), ("blend_method", "BLEND")):
        if hasattr(m.mat, attr):
            try:
                setattr(m.mat, attr, val)
            except Exception:
                pass
    return m.mat


def plastic(name, base="#1a1a1a", rough=0.45, grain=0.06, scale=900.0):
    """Moulded plastic with a faint texture (bump from fine noise)."""
    m = M(name, base, rough)
    n = m.noise(scale, 2.0)
    m.bump(n.outputs["Fac"], grain, 0.0004)
    return m.mat


def brushed_metal(name, base="#b8b8b8", rough=0.3, along="X", metal=0.75):
    """Brushed metal: stretched noise drives roughness. metal 0.75 by default: the game's own metals use
    0.6-0.8 (build_mall.gd), because stores have no reflection probes and full metal reads black there."""
    m = M(name, base, rough, metal)
    tc = m.coords()
    sc = m.node("ShaderNodeMapping")
    sc.inputs["Scale"].default_value = (2.0, 300.0, 300.0) if along == "X" else (300.0, 300.0, 2.0)
    m.link(tc, sc.inputs["Vector"])
    n = m.noise(1.0, 6.0, 0.6, coord=sc.outputs["Vector"])
    r = m.math("MULTIPLY_ADD", n.outputs["Fac"], 0.12)
    m.nt.links.new(r, m.bsdf.inputs["Roughness"])
    m.nt.nodes[r.node.name].inputs[2].default_value = rough - 0.06
    return m.mat


def decal(m, path, center, size, plane="XZ", base=None, flip_u=False, facing=None):
    """Put an image (RGBA PNG) on a flat area of a material, mapped by position, not by UVs (the bake
    re-unwraps everything, so source UVs do not survive). center/size are in final object space (metres),
    plane 'XZ' = a face looking -Y (Godot +Z, the front), 'XY' = a face looking up, 'YZ' = a side.
    The image is mixed over `base` (a colour socket or '#hex'; default the material's base colour value)
    by its alpha, and the result goes to Base Color. Returns the mixed colour socket.
    facing ('-Y', '+X', ...) limits it to faces pointing that way (a planar projection otherwise also
    lands on the opposite face of a box). Chain several decals by passing the previous result as base."""
    a, b = {"XZ": ("X", "Z"), "XY": ("X", "Y"), "YZ": ("Y", "Z")}[plane]
    ia, ib = "XYZ".index(a), "XYZ".index(b)
    sep = m.node("ShaderNodeSeparateXYZ")
    m.link(m.coords("Object"), sep.inputs[0])
    su = -1.0 if flip_u else 1.0
    u = m.math("MULTIPLY_ADD", sep.outputs[a], su / size[0], 0.5 - su * center[ia] / size[0])
    v = m.math("MULTIPLY_ADD", sep.outputs[b], 1.0 / size[1], 0.5 - center[ib] / size[1])
    cv = m.node("ShaderNodeCombineXYZ")
    m.link(u, cv.inputs[0])
    m.link(v, cv.inputs[1])
    tex = m.node("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(path, check_existing=True)
    tex.extension = "CLIP"
    m.link(cv.outputs[0], tex.inputs["Vector"])
    if base is None:
        base = tuple(m.bsdf.inputs["Base Color"].default_value)
        n = m.node("ShaderNodeRGB")
        n.outputs[0].default_value = base
        base = n.outputs[0]
    alpha = tex.outputs["Alpha"]
    if facing:
        nrm = m.node("ShaderNodeSeparateXYZ")
        m.link(m.node("ShaderNodeTexCoord").outputs["Normal"], nrm.inputs[0])
        comp = nrm.outputs[facing[1]]
        side = m.math("MULTIPLY", comp, -1.0 if facing[0] == "-" else 1.0)
        alpha = m.math("MULTIPLY", alpha, m.math("GREATER_THAN", side, 0.5))
    out = m.mix(alpha, base, tex.outputs["Color"])
    m.link(out, m.bsdf.inputs["Base Color"])
    return out
