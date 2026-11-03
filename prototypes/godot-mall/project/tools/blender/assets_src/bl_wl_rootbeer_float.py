"""A root beer float from the Woolworth lunch counter (1995 map, store s13). Hand item.

Steven (Nov 1, 2026): "root beer, not cola". A tall fluted soda-fountain glass on a short foot, dark
amber-brown root beer, a scoop of vanilla ice cream riding a head of creamy foam that spills over the rim
and runs down the glass, a red straw and a long soda spoon, on a white saucer. Plain glass: no brand, no
lettering (IP rule).

References: refs/era_1995/stores/Woolworth.jpg (a period Woolworth lunch counter, for the setting only);
design/storefronts/woolworth.md (the back bar's soda fountain, malt mixers and stacked glasses). No photo of
the drink: a period type. Size: a 12 oz ice-cream-soda glass ~0.19 m tall, rim 86 mm; saucer 140 mm.
Guessed: the glass shape (a classic flared "soda" tulip with 12 flutes on the lower bowl), the straw colour,
the saucer.

Materials: the glass is its own transparent glTF material (not baked); root beer, foam, ice cream, straw,
spoon and saucer are baked into the atlas.
Origin: bottom centre of the saucer.
"""
import math
import bmesh
import bpy
from mathutils import Vector
from lib import core, parts, mats

SAUCER_R, SAUCER_H = 0.070, 0.016
Z0 = SAUCER_H - 0.004            # the glass's foot sits in the saucer's well
# the glass's outer profile (radius, height above its foot)
GLASS = [(0.032, 0.0), (0.033, 0.003), (0.030, 0.005), (0.014, 0.010), (0.010, 0.018), (0.012, 0.024), (0.019, 0.030),
         (0.025, 0.050), (0.029, 0.080), (0.033, 0.110), (0.037, 0.140), (0.040, 0.165), (0.0425, 0.185), (0.0430, 0.190)]
WALL = 0.0022
FLUTES, FLUTE_DEPTH, FLUTE_TOP = 12, 0.0018, 0.115
SEG = 32
LIQ_TOP = 0.168                   # the root beer's level (above the foot)
ROOTBEER = "#3a1a08"
FOAM = ["#b48a58", "#e6cfa6"]
VANILLA = ["#efe2c0", "#fbf3dc"]

META = {
    "id": "bl_wl_rootbeer_float",
    "class": "hand",
    "tex": 1024,
    "ao": 0.4,
    "refs": [["refs/era_1995/stores/Woolworth.jpg", None, "a Woolworth lunch counter (setting)"]],
    "item_file": "blender_props_2.json",
    "item": {"name": "Root beer float", "year": 1995, "store": "WOOLWORTH",
             # on the lunch counter's black top (woolworth/store.gd: LC_U 2.45 face, LC_DP 0.68 deep, LC_H 1.0),
             # in front of the stool at d 8.01: P(u 2.12, d 8.01) = (-10 - d, 1.0, -14 + u)
             "display": {"wing": 1, "year": 1995, "pos": [-18.01, 1.0, -11.88], "yaw": 0, "runtime": True}},
}


def r_at(prof, z):
    for (r0, z0), (r1, z1) in zip(prof, prof[1:]):
        if z0 <= z <= z1:
            return r0 + (r1 - r0) * (z - z0) / max(1e-9, z1 - z0)
    return prof[-1][0]


def fluted_lathe(name, prof, seg, inward, mat, flute=True, cap_bottom=False):
    """A lathe whose radius dips in FLUTES vertical flutes below FLUTE_TOP (fading out above it)."""
    bm = bmesh.new()
    rings = []
    for (r, z) in prof:
        ring = []
        for i in range(seg):
            a = math.tau * i / seg
            rr = r
            if flute and 0.026 < z < FLUTE_TOP + 0.02:
                fade = min(1.0, (FLUTE_TOP + 0.02 - z) / 0.03, (z - 0.026) / 0.008)
                rr -= FLUTE_DEPTH * fade * (0.5 + 0.5 * math.cos(FLUTES * a))
            ring.append(bm.verts.new((rr * math.cos(a), rr * math.sin(a), z)))
        rings.append(ring)
    for a, b in zip(rings, rings[1:]):
        for i in range(seg):
            q = (a[i], a[(i + 1) % seg], b[(i + 1) % seg], b[i])
            bm.faces.new(tuple(reversed(q)) if inward else q)
    if cap_bottom:
        f = bm.faces.new(list(reversed(rings[0])))
        bmesh.ops.poke(bm, faces=[f])
    ob = core.obj_from_bmesh(name, bm, mat, smooth=True)
    return ob


def glass():
    gm = mats.clear_plastic("glass", "#f4faf8", 0.08, 0.05)
    outer = [(r, z + Z0) for r, z in GLASS]
    o = fluted_lathe("glass_out", outer, SEG, False, gm, cap_bottom=True)
    # one shell only: the foam covers the rim, so the wall's inside face would only stack a second grey
    # layer over the root beer (two transparent layers read near-opaque in the studio render)
    return [o]


def liquid_mat():
    m = mats.M("rootbeer", ROOTBEER, 0.12)
    tc = m.coords()
    n = m.noise(80.0, 2.0, coord=tc)
    m.link(m.ramp(n.outputs["Fac"], [(0.4, "#2c1205"), (0.6, "#4a240c")]), m.bsdf.inputs["Base Color"])
    return m.mat


def foam_mat():
    m = mats.M("foam", FOAM[1], 0.7)
    tc = m.coords()
    v = m.voronoi(900.0, coord=tc)
    col = m.ramp(v.outputs["Distance"], [(0.0, FOAM[0]), (0.35, FOAM[1])])
    m.link(col, m.bsdf.inputs["Base Color"])
    m.bump(v.outputs["Distance"], 0.6, 0.0006)
    return m.mat


def vanilla_mat():
    m = mats.M("vanilla", VANILLA[1], 0.6)
    tc = m.coords()
    n = m.noise(300.0, 4.0, coord=tc)
    m.link(m.ramp(n.outputs["Fac"], [(0.35, VANILLA[0]), (0.65, VANILLA[1])]), m.bsdf.inputs["Base Color"])
    # vanilla bean flecks
    f = m.noise(1600.0, 1.0, coord=tc)
    fl = m.math("GREATER_THAN", f.outputs["Fac"], 0.74)
    m.link(m.mix(fl, m.bsdf.inputs["Base Color"].links[0].from_socket, "#3a2a1a"), m.bsdf.inputs["Base Color"])
    m.bump(n.outputs["Fac"], 0.5, 0.0012)
    return m.mat


def build():
    glass()
    # the root beer: the inside profile, a hair smaller, up to the level
    liq = [(0.0, 0.029 + Z0)] + [(r_at(GLASS, z) - WALL - 0.0004, z + Z0) for z in (0.029, 0.04, 0.06, 0.09, 0.12, 0.15, LIQ_TOP)] + [(0.0, LIQ_TOP + Z0)]
    parts.lathe("rootbeer", liq, seg=SEG, mat=liquid_mat())
    # the head of foam: from the liquid up past the rim, bulging out over it, domed under the scoop
    fz = Z0 + LIQ_TOP
    rr = r_at(GLASS, LIQ_TOP) - WALL - 0.0004
    foam_prof = [(rr, fz), (0.0402, Z0 + 0.184), (0.0440, Z0 + 0.1885), (0.0478, Z0 + 0.1925), (0.0482, Z0 + 0.197),
                 (0.0455, Z0 + 0.2015), (0.038, Z0 + 0.2045), (0.026, Z0 + 0.2075), (0.012, Z0 + 0.209), (0.0, Z0 + 0.2095)]
    fo = parts.lathe("foam", foam_prof, seg=SEG, mat=foam_mat(), cap=False)
    tex = bpy.data.textures.new("foamlumps", "CLOUDS")
    tex.noise_scale = 0.008
    d = fo.modifiers.new("Lumps", "DISPLACE")
    d.texture = tex
    d.texture_coords = "OBJECT"
    d.strength = 0.0035
    # drips of foam running down the outside of the glass from the rim
    fm = fo.data.materials[0]
    for k, (ang, ln) in enumerate(((20, 0.022), (95, 0.012), (160, 0.030), (250, 0.016), (320, 0.008))):
        a = math.radians(ang)
        pts = []
        # a lobe of foam over the lip, then a teardrop running down the glass, both hugging it
        ob = parts.sphere("lobe", 0.0065, 10, 6, loc=(0.0468 * math.cos(a), 0.0468 * math.sin(a), Z0 + 0.1915), mat=fm,
                          scale=(1.0, 1.0, 0.8))
        ob.rotation_euler = (0, 0, a)
        half = 0.0042 * (1.0 + ln / 0.008)
        z = 0.1915 - half * 0.95             # its top tucked under the lobe
        r = r_at(GLASS, z) + 0.0016
        ob = parts.sphere("drip", 0.0042, 10, 8, loc=(r * math.cos(a), r * math.sin(a), Z0 + z), mat=fm,
                          scale=(0.55, 1.0, 1.0 + ln / 0.008))
        ob.rotation_euler = (0, math.radians(-4), a)
    # the scoop of vanilla, sunk a little into the foam, with the scoop's ridge
    ic = parts.sphere("icecream", 0.031, 20, 12, loc=(0.002, -0.002, Z0 + 0.222), mat=vanilla_mat(), scale=(1.0, 1.0, 0.86))
    t2 = bpy.data.textures.new("scoop", "CLOUDS")
    t2.noise_scale = 0.012
    t2.noise_depth = 2
    d2 = ic.modifiers.new("Lumps", "DISPLACE")
    d2.texture = t2
    d2.texture_coords = "OBJECT"
    d2.strength = 0.004
    ridge = parts.tube_path("ridge", [(-0.028, 0.004, Z0 + 0.214), (-0.012, 0.012, Z0 + 0.226), (0.010, 0.010, Z0 + 0.228), (0.028, -0.004, Z0 + 0.214)],
                            0.003, seg=6, mat=ic.data.materials[0])
    # the straw, leaning back-right out of the float; the long soda spoon leaning front-left
    sm = mats.M("straw", "#c8202a", 0.35)
    s0, s1 = Vector((0.012, 0.010, Z0 + 0.05)), Vector((0.030, 0.034, Z0 + 0.285))
    dv = s1 - s0
    st = parts.cylinder("straw", 0.0028, dv.length, verts=10, mat=sm.mat, bev=0)
    st.location = (s0 + s1) / 2
    st.rotation_euler = dv.to_track_quat("Z", "Y").to_euler()
    steel = mats.brushed_metal("spoon", "#c9c9cc", 0.28, along="Z")
    p0, p1 = Vector((-0.010, -0.004, Z0 + 0.10)), Vector((-0.040, -0.030, Z0 + 0.300))
    dv = p1 - p0
    hd = parts.box("spoon_handle", (0.0055, 0.0016, dv.length), mat=steel, bev=0.0006, seg=1)
    hd.location = (p0 + p1) / 2
    hd.rotation_euler = dv.to_track_quat("Z", "Y").to_euler()
    hd.rotation_euler.rotate_axis("Z", math.radians(45))
    end = parts.sphere("spoon_end", 0.0045, 12, 6, loc=tuple(p1), mat=steel, scale=(1.0, 0.4, 1.4))
    # the saucer: white ceramic with a well for the foot and a raised rim
    cer = mats.M("saucer", "#f4f1ea", 0.18)
    cer.bump(cer.noise(200.0, 2.0).outputs["Fac"], 0.05, 0.0003)
    parts.lathe("saucer", [(0.0, 0.0), (0.040, 0.0), (0.044, 0.003), (0.036, 0.009), (0.034, 0.0095), (0.0425, 0.0105),
                           (0.062, 0.013), (0.0695, 0.016), (0.0700, 0.0165), (0.0690, 0.017), (0.061, 0.0145), (0.040, 0.0125),
                           (0.0335, 0.0115), (0.0, 0.0115)], seg=SEG, mat=cer.mat)
