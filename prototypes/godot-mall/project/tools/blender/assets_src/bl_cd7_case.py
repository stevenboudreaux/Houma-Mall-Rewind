"""Corn Dog 7's warmer stock, both years (workstream FOOD3D, Nov 8 2026): a KIT (tools/blender/assets_src/_kit.py)
split into pieces the counter cases instance (tools/stores/corn_dog_7.gd, food3d/kit.gd):

  dog     a corn dog standing batter-down in the warmer's holder, stick up (the case's old tapered cylinders
          stood the same way); the hand corn dog's cornmeal crust (bl_cd7_corndog.batter_mat), no mustard,
          fewer segments (a case holds 14 of them)
  cheese  cheese on a stick: a battered block of cheese (the same batter, paler) on a birch stick, one end
          bitten-looking where the cheese shows; lies flat in the pan
  pan     a stainless steam-table pan (1/4 size, 0.26 x 0.32 x 0.065 m) that replaces the yellow block

References: as bl_cd7_corndog (the stand only: refs/derived/signs/corndog_IMG_4461_f005.jpg; no photo of the
food); design/storefronts/corn-dog-7.md (cases 0.5 m tall, 0.55 m deep). Guessed: cheese on a stick at all (a
period corn-dog-stand item; Corn Dog 7's 1990s menu is not documented, so it is not added to the menu box or
sold: Steven's call), the pan, the sizes (dog as the hand item: 0.165 m of batter on a 0.2 m stick).
Origins: dog = the batter's bottom tip, stick up (+Z); cheese = bottom centre lying along X; pan = bottom centre.
"""
import math
import bpy
from lib import core, parts, mats
import bl_cd7_corndog as CD

POS = {"dog": [-0.3, 0.0], "cheese": [0.0, 0.0], "pan": [0.4, 0.0]}
META = {
    "id": "bl_cd7_case",
    "class": "small_fixture",
    "tex": 1024,
    "ao": 0.3,
    "refs": [["refs/derived/signs/corndog_IMG_4461_f005.jpg", [0.12, 0.18, 1.0, 0.62], "IMG_4461 f005 (the stand)"]],
    "kit": {"pieces": POS, "max_tris": 800},
    "icon": False,
}


def build():
    bat = CD.batter_mat("batter")
    x, y = POS["dog"]
    # the hand dog's profile, turned over: batter tip at z 0, the stick out of the top
    top = max(z for r, z in CD.BODY)
    lo = min(z for r, z in CD.BODY)
    prof = [(r, top - z) for r, z in reversed(CD.BODY)]
    dog = parts.lathe("dog", prof, seg=12, loc=(x, y, 0), mat=bat, cap=False)
    tex = bpy.data.textures.new("dlumps", "CLOUDS")
    tex.noise_scale = CD.LUMP_SIZE
    d = dog.modifiers.new("Lumps", "DISPLACE")
    d.texture = tex
    d.texture_coords = "OBJECT"
    d.strength = CD.LUMP_DEPTH * 0.8
    stick_out = 0.10
    parts.cylinder("dog_stick", CD.STICK_R, stick_out + 0.04, verts=6, loc=(x, y, top - lo + stick_out / 2 - 0.02),
                   mat=CD.wood_mat(), bev=0)
    # cheese on a stick, lying along X: a lumpy battered block, the stick out of its +X end
    x, y = POS["cheese"]
    cm = CD.batter_mat("cheese_batter")
    blk = parts.box("cheese", (0.085, 0.03, 0.026), loc=(x - 0.03, y, 0.013), mat=cm, bev=0.009, seg=2)
    t2 = bpy.data.textures.new("clumps", "CLOUDS")
    t2.noise_scale = 0.012
    d2 = blk.modifiers.new("Lumps", "DISPLACE")
    d2.texture = t2
    d2.texture_coords = "OBJECT"
    d2.strength = 0.0025
    # a split in the batter where the melted cheese shows
    ch = mats.M("cheese_melt", "#f2c94a", 0.35)
    parts.sphere("cheese_ooze", 0.009, seg=8, rings=5, loc=(x - 0.068, y, 0.014), mat=ch.mat, scale=(0.7, 1.1, 0.9))
    parts.cylinder("cheese_stick", CD.STICK_R, 0.11, verts=6, loc=(x + 0.04, y, 0.013), rot=(0, 90, 0), mat=CD.wood_mat(), bev=0)
    # the pan: a 1/4 steam-table pan with a flat rim (flat steel, not in the atlas)
    x, y = POS["pan"]
    steel = mats.M("pan", "#c4c6ca", 0.32, 0.6, bake=False).mat
    w, dd, h, t = 0.26, 0.32, 0.065, 0.0015
    parts.box("pan", (w - 0.02, dd - 0.02, t), loc=(x, y, 0), mat=steel, bev=0, origin="bottom")
    for (sx, sy, cx, cy) in ((w, t, 0, dd / 2), (w, t, 0, -dd / 2), (t, dd, w / 2, 0), (t, dd, -w / 2, 0)):
        wall = parts.box("pan_wall", (sx, sy, h), loc=(x + cx * 0.94, y + cy * 0.94, 0), mat=steel, bev=0, origin="bottom")
    rim = 0.012
    for (sx, sy, cx, cy) in ((w + 2 * rim, rim, 0, dd / 2 + rim / 2), (w + 2 * rim, rim, 0, -dd / 2 - rim / 2),
                             (rim, dd, w / 2 + rim / 2, 0), (rim, dd, -w / 2 - rim / 2, 0)):
        parts.box("pan_rim", (sx, sy, t), loc=(x + cx, y + cy, h - t), mat=steel, bev=0, origin="bottom")
