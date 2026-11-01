"""An Orange Julius drink (1995 map, store s34). Hand item.

A tapered waxed-paper cup of the period printed with a generic orange swirl (no logo, no name: IP rule),
a clear plastic lid with a raised rim and a straw slot, the frothy orange drink showing under it, and a
striped straw.

References: refs/era_1995/stores/Orange_Julius.jpg (a period Orange Julius counter, colours only; its
printed cup and logo are not copied); design/storefronts/orange-julius.md. Size: a 20 oz cup ~150 mm
tall, 90 mm across the top, 58 mm at the base. Guessed: the swirl print, the lid (clear, so the drink
reads), the straw stripes.
Origin: bottom centre.
"""
import math
from PIL import Image, ImageDraw, ImageFilter
from lib import core, parts, mats, labels

H, RT, RB = 0.150, 0.045, 0.029
SEG = 32
ORANGE = (244, 128, 24, 255)
ORANGE2 = (255, 186, 70, 255)

META = {
    "id": "bl_oj_cup",
    "class": "hand",
    "tex": 1024,
    "ao": 0.3,
    "refs": [["refs/era_1995/stores/Orange_Julius.jpg", None, "Orange Julius, period (colours)"]],
    "item_file": "blender_props_2.json",
    "item": {"name": "Orange Julius", "year": 1995, "store": "ORANGE JULIUS",
             # on the tiled counter's top at its west end, past the register (wave7.gd orange_julius():
             # co = P(W-0.6, 0, 2.4) = (15.4, 0, 8.4), top 1.0, register x 13.5-14.4; customers on the -z side)
             "place": {"wing": 1, "year": 1995, "pos": [12.95, 1.0, 8.66], "yaw": 200}},
}


def wrap_art():
    """The cup's printed wrap: white with orange swirls and a thin band round the top; drawn flat and
    wrapped round the cup by angle."""
    w, h = 2048, 680
    im = Image.new("RGBA", (w, h), (250, 248, 242, 255))
    d = ImageDraw.Draw(im)
    # two broad swirls round the cup, each with a lighter inner ribbon
    for k, (yc, amp, ph) in enumerate(((0.42, 0.16, 0.0), (0.72, 0.13, 2.2))):
        pts = []
        for x in range(0, w + 8, 8):
            pts.append((x, h * yc + h * amp * math.sin(x / w * math.tau * 3 + ph)))
        d.line(pts, fill=ORANGE, width=70)
        d.line([(x, y - 6) for x, y in pts], fill=ORANGE2, width=22)
    d.rectangle((0, 0, w, 40), fill=ORANGE)
    d.rectangle((0, 52, w, 62), fill=ORANGE2)
    d.rectangle((0, h - 30, w, h), fill=ORANGE)
    im = im.filter(ImageFilter.GaussianBlur(1.0))
    return labels.save(im, "oj_cup_wrap")


def cup_mat():
    """The wrap mapped round the cup by angle (atan2) and height: a cylindrical projection in nodes."""
    m = mats.M("cup", "#faf8f2", 0.45)
    tc = m.coords()
    sep = m.node("ShaderNodeSeparateXYZ")
    m.link(tc, sep.inputs[0])
    ang = m.math("ARCTAN2", sep.outputs["Y"], sep.outputs["X"])
    u = m.math("MULTIPLY_ADD", ang, 1.0 / math.tau, 0.5)
    v = m.math("MULTIPLY_ADD", sep.outputs["Z"], 1.0 / (H - 0.010), -0.004 / (H - 0.010))
    cv = m.node("ShaderNodeCombineXYZ")
    m.link(u, cv.inputs[0])
    m.link(v, cv.inputs[1])
    tex = m.node("ShaderNodeTexImage")
    import bpy
    tex.image = bpy.data.images.load(wrap_art(), check_existing=True)
    tex.extension = "EXTEND"
    m.link(cv.outputs[0], tex.inputs["Vector"])
    m.link(tex.outputs["Color"], m.bsdf.inputs["Base Color"])
    m.bump(m.noise(500.0, 2.0).outputs["Fac"], 0.05, 0.0003)
    return m.mat


def build():
    cm = cup_mat()
    # the cup: a tapered wall with a rolled rim and a recessed base
    wall = [(RB - 0.002, 0.0), (RB, 0.003), (RT, H - 0.004), (RT + 0.0016, H - 0.002), (RT + 0.0012, H), (RT - 0.0012, H - 0.001),
            (RB - 0.0015, 0.006), (0.0, 0.006)]
    parts.lathe("cup", [(0.0, 0.0)] + wall, seg=SEG, mat=cm)
    # the drink under the lid: frothy orange
    dm = mats.M("drink", "#f39020", 0.55)
    dm.bump(dm.noise(700.0, 2.0).outputs["Fac"], 0.4, 0.0006)
    n = dm.noise(120.0, 3.0)
    dm.link(dm.ramp(n.outputs["Fac"], [(0.35, "#ec7c10"), (0.65, "#ffb050")]), dm.bsdf.inputs["Base Color"])
    parts.lathe("drink", [(0.0, H - 0.010), (RT - 0.002, H - 0.010), (RT - 0.0015, H - 0.004), (RT * 0.6, H - 0.0035), (0.0, H - 0.003)], seg=SEG, mat=dm.mat)
    # the clear lid: a flat top recessed inside a raised rim that snaps over the cup's rim, a straw boss
    lid = mats.clear_plastic("lid", "#f0f4f4", 0.18, 0.12)
    parts.lathe("lid", [(0.0, H + 0.004), (RT - 0.006, H + 0.004), (RT - 0.004, H + 0.0075), (RT + 0.0005, H + 0.0085),
                        (RT + 0.0028, H + 0.006), (RT + 0.0028, H - 0.003), (RT + 0.0015, H - 0.0035)], seg=SEG, mat=lid, cap=False)
    parts.cylinder("boss", 0.009, 0.004, verts=16, loc=(0.012, -0.010, H + 0.006), mat=lid, bev=0.001)
    # the straw: white with orange stripes, through the boss, leaning a little
    sm = mats.M("straw", "#f6f4ee", 0.35)
    tc = sm.coords()
    sep = sm.node("ShaderNodeSeparateXYZ")
    sm.link(tc, sep.inputs[0])
    ang = sm.math("ARCTAN2", sep.outputs["Y"], sep.outputs["X"])
    stripe = sm.math("GREATER_THAN", sm.math("SINE", sm.math("MULTIPLY_ADD", ang, 3.0, sm.math("MULTIPLY", sep.outputs["Z"], 120.0))), 0.4)
    sm.link(sm.mix(stripe, "#f6f4ee", "#f07a18"), sm.bsdf.inputs["Base Color"])
    st = parts.cylinder("straw", 0.0032, 0.235, verts=10, loc=(0.0135, -0.011, 0.012 + 0.1175), mat=sm.mat, bev=0)
    st.rotation_euler = (math.radians(5), math.radians(6), 0)
