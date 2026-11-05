"""A lava lamp for Gumballs (1995 map). Hand item; Gumballs sold them (design/storefronts/gumballs.md:
"the lava lamps: not seen in the video, but Steven remembers them, and they were sold widely again by
1995"). Replaces the three-cylinder lamp of tools/stores/gumballs/store.gd lava() when integrated.

The classic rocket shape of the period, same proportions as store.gd's lamp at s = 1 (~0.47 m): a tapered
silver base, a glass bottle widest a third of the way up, a short silver cone cap. Inside: a pool of wax on
the bottom coil, one rising blob, one at the top. Generic, unbranded.

Materials: the metal is baked into the atlas; the liquid and the wax stay as two flat glowing materials
(bl_gb_lavalamp_liquid: transparent, bl_gb_lavalamp_wax: opaque), so Godot can recolour a lamp with a
surface material override to store.gd's six colours (red, blue, green, purple, orange, pink) without a
second model. Built red here (store.gd's "red": #ff3a20).
Origin: bottom centre. No reference photo: Steven's memory + the store's existing lamp.
"""
import math
import bpy
from lib import core, parts, mats

WAX = "#ff3a20"           # store.gd lava_red
LIQUID = "#ff8a4a"        # the lit liquid: warm, lighter than the wax
GLOW_WAX = 2.2           # emission energy, as store.gd lava materials (2.2; night 2.4)
GLOW_LIQ = 1.0
BASE = [(0.062, 0.0), (0.063, 0.006), (0.060, 0.012), (0.052, 0.060), (0.043, 0.112), (0.040, 0.124), (0.041, 0.130), (0.0, 0.130)]
BOTTLE = [(0.0, 0.130), (0.037, 0.130), (0.050, 0.170), (0.057, 0.215), (0.056, 0.250), (0.048, 0.300), (0.038, 0.360),
          (0.031, 0.408), (0.0, 0.408)]
CAP = [(0.0, 0.405), (0.034, 0.405), (0.032, 0.412), (0.020, 0.460), (0.012, 0.468), (0.0, 0.469)]

META = {
    "id": "bl_gb_lavalamp",
    "class": "hand",
    "tex": 512,
    "ao": 0.4,
    "refs": [],
    "item": {"name": "Lava lamp", "year": "both", "store": "GUMBALLS",   # "both": also sold at Spencer's in 2026 (ws/interiors, Steven Nov 4)
             "recolor": {"bl_gb_lavalamp_wax": ["#ff3a20", "#3a8cff", "#4cff5a", "#c04cff", "#ff9a1a", "#ff5ab4"]}},
}


def glow(name, col, strength, alpha=1.0):
    m = mats.M(name, col, 0.08, 0.0, bake=False)
    m.bsdf.inputs["Emission Color"].default_value = mats.hexc(col)
    m.bsdf.inputs["Emission Strength"].default_value = strength
    if alpha < 1.0:
        m.bsdf.inputs["Alpha"].default_value = alpha
        for attr, val in (("surface_render_method", "BLENDED"), ("blend_method", "BLEND")):
            if hasattr(m.mat, attr):
                try:
                    setattr(m.mat, attr, val)
                except Exception:
                    pass
    return m.mat


def blob(name, prof, z, mat, wob=0.004, sx=1.0):
    ob = parts.lathe(name, prof, seg=16, loc=(0, 0, z), mat=mat)
    ob.scale = (sx, 1.0, 1.0)
    t = bpy.data.textures.new(name + "_n", "CLOUDS")
    t.noise_scale = 0.02
    d = ob.modifiers.new("Wobble", "DISPLACE")
    d.texture = t
    d.strength = wob
    return ob


def build():
    metal = mats.brushed_metal("metal", "#c9cacc", 0.25, along="Z", metal=0.7)
    parts.lathe("base", BASE, seg=32, mat=metal, sharp_angle=30)
    parts.lathe("cap", CAP, seg=32, mat=metal, sharp_angle=30)
    parts.lathe("bottle", BOTTLE, seg=32, mat=glow("liquid", LIQUID, GLOW_LIQ, 0.38))
    wax = glow("wax", WAX, GLOW_WAX)
    # the pool on the bottom, a rising blob, a blob that has reached the top
    blob("pool", [(0.0, 0.0), (0.034, 0.0), (0.036, 0.010), (0.026, 0.024), (0.012, 0.034), (0.0, 0.036)], 0.132, wax, 0.003)
    blob("rise", [(0.0, 0.0), (0.012, 0.006), (0.018, 0.022), (0.016, 0.040), (0.009, 0.052), (0.0, 0.056)], 0.200, wax, 0.004, 1.1)
    b = blob("top", [(0.0, 0.0), (0.014, 0.004), (0.020, 0.014), (0.016, 0.026), (0.0, 0.030)], 0.350, wax, 0.003, 0.9)
    b.location.x = 0.006
