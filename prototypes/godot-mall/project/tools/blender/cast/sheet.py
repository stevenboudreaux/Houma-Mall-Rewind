"""Turntable + face close-up sheet for one cast member (Blender Cycles, CPU), beside the research render.

    /home/claude/bvenv/bin/python tools/blender/cast/sheet.py <id> [--fast] [--out path.jpg]

Renders LOD0 in its modelled (bind) pose straight from the build's arrays (.scratch/cast/<id>_lod0.npz,
written by build.py) with the same textures as the .glb: four turntable angles, LOD1 at the side, and
three close-ups (neutral; smile + brows up; talking: jaw_open + blink). Lighting imitates the mall:
warm overhead fluorescent key, cool fill, warm rim. Path tracing adds bounce light the game's
Compatibility renderer won't; the in-game shot is the honest one (tools/qa/cast_shot.gd).
"""
import json
import math
import os
import subprocess
import sys

import bpy
import numpy as np
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import person  # noqa: E402,F401
import mh  # noqa: E402

PROJ = mh.PROJ
CAST = os.path.join(PROJ, "cast")
SCR = os.path.join(PROJ, ".scratch", "cast")
REF = os.path.join(PROJ, "..", "..", "..", ".scratch", "ref.jpg")


def g2b(p):
    p = np.asarray(p)
    return np.stack([p[..., 0], -p[..., 2], p[..., 1]], -1)


def image(path, colour=True):
    im = bpy.data.images.load(path, check_existing=True)
    if not colour:
        im.colorspace_settings.name = "Non-Color"
    return im


def material(name, prefix, kind):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = image(prefix + "_%s_albedo.png" % kind)
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    if kind == "hair":
        nt.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
        bsdf.inputs["Roughness"].default_value = 0.7
    else:
        orm = nt.nodes.new("ShaderNodeTexImage"); orm.image = image(prefix + "_%s_orm.png" % kind, False)
        sep = nt.nodes.new("ShaderNodeSeparateColor")
        nt.links.new(orm.outputs["Color"], sep.inputs["Color"])
        nt.links.new(sep.outputs["Green"], bsdf.inputs["Roughness"])
        nt.links.new(sep.outputs["Blue"], bsdf.inputs["Metallic"])
    nm = nt.nodes.new("ShaderNodeTexImage"); nm.image = image(prefix + "_%s_normal.png" % kind, False)
    nmap = nt.nodes.new("ShaderNodeNormalMap")
    nt.links.new(nm.outputs["Color"], nmap.inputs["Color"])
    nt.links.new(nmap.outputs["Normal"], bsdf.inputs["Normal"])
    bsdf.inputs["Specular IOR Level"].default_value = 0.35
    return m


def make_mesh(z, prefix, name, with_keys=True):
    pos = g2b(z["pos"]); nrm = g2b(z["nrm"])
    uv = z["uv"].copy(); uv[:, 1] = 1 - uv[:, 1]
    tri = z["tri"]; mat = z["mat"]
    me = bpy.data.meshes.new(name)
    me.from_pydata(pos.tolist(), [], tri.tolist())
    me.polygons.foreach_set("material_index", mat.astype(np.int32))
    me.polygons.foreach_set("use_smooth", np.ones(len(tri), bool))
    ul = me.uv_layers.new(name="UV")
    ul.data.foreach_set("uv", uv[tri].reshape(-1))
    me.normals_split_custom_set_from_vertices(nrm.tolist())
    for k in ("skin", "clothes", "hair"):
        me.materials.append(bpy.data.materials.get("m_" + k) or material("m_" + k, prefix, k))
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    if with_keys and "morph_names" in z:
        ob.shape_key_add(name="Basis")
        for i, n in enumerate(z["morph_names"]):
            k = ob.shape_key_add(name=str(n))
            d = g2b(z["morphs"][i])
            k.data.foreach_set("co", (pos + d).astype(np.float32).ravel())
            k.value = 0.0
    return ob


def lights(scene):
    def area(name, loc, rot, size, energy, color):
        l = bpy.data.lights.new(name, "AREA"); l.size = size; l.energy = energy; l.color = color
        o = bpy.data.objects.new(name, l); o.location = loc; o.rotation_euler = rot
        scene.collection.objects.link(o)
    area("key", (0.3, -1.6, 3.2), (math.radians(35), 0, math.radians(10)), 2.0, 130, (1.0, 0.93, 0.82))
    area("fill", (-2.2, -1.2, 1.6), (math.radians(70), 0, math.radians(-60)), 2.0, 40, (0.82, 0.88, 1.0))
    area("rim", (1.4, 1.8, 2.0), (math.radians(-60), 0, math.radians(150)), 1.0, 70, (1.0, 0.8, 0.6))
    w = scene.world or bpy.data.worlds.new("w"); scene.world = w
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs["Color"].default_value = (0.075, 0.062, 0.05, 1)
    w.node_tree.nodes["Background"].inputs["Strength"].default_value = 1.0


def render(scene, cam, path, w, h, loc, target, lens):
    cam.location = loc
    d = Vector(target) - Vector(loc)
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    cam.data.lens = lens
    scene.render.resolution_x = w; scene.render.resolution_y = h
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    pid = [a for a in argv if not a.startswith("--")][0]
    fast = "--fast" in argv
    out = os.path.join(PROJ, "..", "..", "..", "production", "qa", "evidence", "wsCAST-%s-sheet.jpg" % pid)
    if "--out" in argv:
        out = argv[argv.index("--out") + 1]
    prefix = os.path.join(CAST, pid)
    meta = json.load(open(prefix + ".json"))
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 24 if fast else 64
    scene.cycles.use_denoising = True
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Base Contrast"
    lights(scene)
    z0 = np.load(os.path.join(SCR, pid + "_lod0.npz"), allow_pickle=True)
    z1 = np.load(os.path.join(SCR, pid + "_lod1.npz"), allow_pickle=True)
    ob = make_mesh(z0, prefix, "lod0")
    ob1 = make_mesh(z1, prefix, "lod1", False)
    ob1.hide_render = True
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    scene.collection.objects.link(cam); scene.camera = cam
    H = meta["height_m"]
    eyes = np.array(meta["eyes"]["L"]) * 0.5 + np.array(meta["eyes"]["R"]) * 0.5
    ez = eyes[1]
    tmp = os.path.join(SCR, "sheet_" + pid)
    os.makedirs(tmp, exist_ok=True)
    frames = []
    # turntable: rotate the person, not the camera (lights stay put, as in the mall)
    for i, ang in enumerate((0, 35, 90, 180)):
        ob.rotation_euler = (0, 0, math.radians(ang))
        p = os.path.join(tmp, "t%d.png" % i)
        render(scene, cam, p, 300, 640, (0, -4.6, H * 0.55), (0, 0, H * 0.5), 50)
        frames.append(p)
    ob.rotation_euler = (0, 0, math.radians(35))
    ob.hide_render = True; ob1.hide_render = False; ob1.rotation_euler = (0, 0, math.radians(35))
    p = os.path.join(tmp, "lod1.png")
    render(scene, cam, p, 300, 640, (0, -4.6, H * 0.55), (0, 0, H * 0.5), 50)
    frames.append(p)
    ob.hide_render = False; ob1.hide_render = True
    # close-ups
    ob.rotation_euler = (0, 0, math.radians(18))
    keys = ob.data.shape_keys.key_blocks
    shots = [("neutral", {}), ("smile + brows up", {"smile": 0.8, "brow_up": 0.6, "eyes_wide": 0.2}),
             ("talking: jaw_open + blink_L/R", {"jaw_open": 0.55, "blink_L": 1.0, "blink_R": 1.0, "brow_inner_up": 0.4})]
    close = []
    scene.view_settings.exposure = -0.35
    for i, (lab, vals) in enumerate(shots):
        for k in keys[1:]:
            k.value = vals.get(k.name, 0.0)
        p = os.path.join(tmp, "c%d.png" % i)
        render(scene, cam, p, 360, 600, (0.0, -1.15, ez + 0.0), (0.0, 0.0, ez - 0.12), 62)
        close.append((p, lab))
    compose(pid, meta, frames, close, out)


def compose(pid, meta, frames, close, out):
    from PIL import Image, ImageDraw, ImageFont
    W = 1600
    sheet = Image.new("RGB", (W, 640 + 600 + 70), (24, 21, 18))
    d = ImageDraw.Draw(sheet)
    try:
        f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 17)
    except Exception:
        f = ImageFont.load_default()
    x = 0
    labels = ["front", "3/4", "side", "back", "LOD1 (%d tris)" % meta["lod1"]["tris"]]
    for p, lab in zip(frames, labels):
        im = Image.open(p).convert("RGB")
        sheet.paste(im, (x, 0)); d.text((x + 8, 610), lab, fill=(230, 220, 200), font=f)
        x += 300
    # right column of the top row: the numbers
    tx = 1510 - 0
    info = ["%s" % pid, "LOD0 %d tris" % meta["lod0"]["tris"], "  %d surfaces" % meta["lod0"]["surfaces"],
            "LOD1 %d tris" % meta["lod1"]["tris"], "%d morphs" % len(meta["morphs"]), "height %.2f m" % meta["height_m"],
            "PROPOSAL" if meta.get("status") != "approved" else "approved"]
    for i, s in enumerate(info):
        d.text((1505, 20 + i * 24), s, fill=(230, 220, 200), font=ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 13) if os.path.exists("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf") else f)
    y = 640
    x = 0
    # the research render's pipeline-B frame for comparison
    if os.path.exists(REF):
        r = Image.open(REF).convert("RGB")
        rw, rh = r.size
        crop = r.crop((int(rw * 0.385), 0, int(rw * 0.69), int(rh * 0.93)))
        crop = crop.resize((int(600 * crop.size[0] / crop.size[1]), 600))
        sheet.paste(crop, (0, y)); d.text((8, y + 604), "reference: CHAR-RESEARCH render (Cycles)", fill=(200, 190, 170), font=f)
        x = crop.size[0] + 10
    for p, lab in close:
        im = Image.open(p).convert("RGB")
        if x + im.size[0] > W:
            im = im.resize((W - x, int(im.size[1] * (W - x) / im.size[0])))
        sheet.paste(im, (x, y)); d.text((x + 8, y + 604), lab, fill=(230, 220, 200), font=f)
        x += im.size[0] + 4
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out, quality=88)
    print("SHEET", os.path.abspath(out))


if __name__ == "__main__":
    main()
