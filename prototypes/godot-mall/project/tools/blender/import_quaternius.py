"""Lynn's Interiors (2026): convert the CC0 furniture packs into mall props — workstream LYNNS (Nov 4 2026).

Sources (both CC0 1.0, credit in models/lynns/pack/CREDITS.md):
  Quaternius "Ultimate House Interior Pack" (June 2020), FBX     -> "src": "q:<Name>"
  Kenney "Furniture Kit 2.0", glTF binary                        -> "src": "k:<name>"
  a few simple pieces built here (mattress sets, adjustable base) -> "src": "gen:<kind>"

Config: data/lynns/pack_models.json (one entry per output model: target size, turn, material -> palette swatch).
Every model:
  - metres, origin at the floor centre of its bounding box, Blender -Y = the front (Godot +Z, yaw 0 faces south),
    the same convention as the bl_ly_* generator props;
  - scaled to the entry's target size [w, d, h] (per axis: the packs' proportions are chunky, so a sofa can be
    made lower than a uniform scale would give);
  - recoloured by MATERIAL swap onto one shared palette: every face gets UVs at the centre of its swatch in
    models/lynns/pack/ly_palette.png (albedo) and ly_palette_orm.png (AO/roughness/metal), so a model is one
    material, one draw call, and the flat-shaded look of the packs is kept;
  - exported as models/lynns/pack/<id>.gltf + <id>.bin, the palette PNGs shared beside them (one texture in Godot).
Writes models/lynns/pack/manifest.json: id -> source, size [w, d, h], tris (read by placements and the asset manifest).

Run (headless, from the project):
  /home/claude/bvenv/bin/python tools/blender/import_quaternius.py [-- id id ...] [--sheet out.png]
"""
import bpy, bmesh, sys, os, json, math

PROJ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ASSETS = os.environ.get("LY_PACKS", "/home/claude/assets/Furniture")
QDIR = os.path.join(ASSETS, "Ultimate House Interior Pack - June 2020", "FBX")
KDIR = os.path.join(ASSETS, "kenney_furniture-kit", "Models", "GLTF format")
CFG = os.path.join(PROJ, "data", "lynns", "pack_models.json")
OUT = os.path.join(PROJ, "models", "lynns", "pack")
GRID = 8          # 8 x 8 swatches
SW = 16           # px per swatch -> 128 px palette


def srgb_to_lin(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def hexrgb(h):
    h = h.lstrip("#")
    return [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]


def write_palette(pal):
    """pal: ordered {name: [hex, roughness, metal]} -> two PNGs; returns {name: (u, v)} swatch centres."""
    from PIL import Image
    names = list(pal.keys())
    assert len(names) <= GRID * GRID, "palette full"
    alb = Image.new("RGB", (GRID * SW, GRID * SW), (255, 0, 255))
    orm = Image.new("RGB", (GRID * SW, GRID * SW), (255, 230, 0))
    uv = {}
    for i, n in enumerate(names):
        hx, rough, metal = pal[n]
        gx, gy = i % GRID, i // GRID
        box = (gx * SW, gy * SW, gx * SW + SW, gy * SW + SW)
        alb.paste(tuple(int(round(c * 255)) for c in hexrgb(hx)), box)
        orm.paste((255, int(rough * 255), int(metal * 255)), box)
        uv[n] = ((gx + 0.5) / GRID, 1.0 - (gy + 0.5) / GRID)
    os.makedirs(OUT, exist_ok=True)
    alb.save(os.path.join(OUT, "ly_palette.png"))
    orm.save(os.path.join(OUT, "ly_palette_orm.png"))
    return uv


def palette_material():
    m = bpy.data.materials.get("ly_palette")
    if m:
        return m
    m = bpy.data.materials.new("ly_palette")
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    ta = nt.nodes.new("ShaderNodeTexImage")
    ta.image = bpy.data.images.load(os.path.join(OUT, "ly_palette.png"))
    ta.interpolation = "Closest"
    to = nt.nodes.new("ShaderNodeTexImage")
    to.image = bpy.data.images.load(os.path.join(OUT, "ly_palette_orm.png"))
    to.image.colorspace_settings.name = "Non-Color"
    to.interpolation = "Closest"
    sep = nt.nodes.new("ShaderNodeSeparateColor")
    nt.links.new(ta.outputs["Color"], b.inputs["Base Color"])
    nt.links.new(to.outputs["Color"], sep.inputs["Color"])
    nt.links.new(sep.outputs["Green"], b.inputs["Roughness"])
    nt.links.new(sep.outputs["Blue"], b.inputs["Metallic"])
    return m


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def import_src(src):
    kind, name = src.split(":", 1)
    before = set(bpy.data.objects)
    if kind == "q":
        bpy.ops.import_scene.fbx(filepath=os.path.join(QDIR, name + ".fbx"))
    elif kind == "k":
        bpy.ops.import_scene.gltf(filepath=os.path.join(KDIR, name + ".glb"))
    elif kind == "gen":
        GEN[name]()
    obs = [o for o in bpy.data.objects if o not in before and o.type == "MESH"]
    for o in [o for o in bpy.data.objects if o not in before and o.type != "MESH"]:
        for c in o.children:
            pass
    # apply every transform (parents included), then join into one mesh
    bpy.ops.object.select_all(action="DESELECT")
    for o in obs:
        mw = o.matrix_world.copy()
        o.parent = None
        o.matrix_world = mw
    for o in [o for o in bpy.data.objects if o.type != "MESH"]:
        bpy.data.objects.remove(o)
    for o in obs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = obs[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if len(obs) > 1:
        bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    return ob


# ---------------------------------------------------------------- simple pieces the packs do not have
def _box(bm, x0, y0, z0, x1, y1, z1, mi):
    r = bmesh.ops.create_cube(bm, size=1.0)
    vs = r["verts"]
    for v in vs:
        v.co.x = x0 if v.co.x < 0 else x1
        v.co.y = y0 if v.co.y < 0 else y1
        v.co.z = z0 if v.co.z < 0 else z1
    faces = {f for v in vs for f in v.link_faces}
    for f in faces:
        f.material_index = mi
    return faces


def _gen_obj(name, mats, build):
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    build(bm)
    bm.to_mesh(me)
    bm.free()
    for m in mats:
        me.materials.append(bpy.data.materials.get(m) or bpy.data.materials.new(m))
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def gen_mattress():
    """A mattress on a black foundation (no frame): foundation 0.23, mattress 0.33 with a pillow top, the
    border panel a separate material (navy quilted in the footage, 4412 t023-045). Unit queen size."""
    W, L = 1.53, 2.03
    def b(bm):
        _box(bm, -W / 2, -L / 2, 0.0, W / 2, L / 2, 0.20, 0)          # foundation
        _box(bm, -W / 2 + 0.01, -L / 2 + 0.01, 0.20, W / 2 - 0.01, L / 2 - 0.01, 0.23, 0)
        _box(bm, -W / 2, -L / 2, 0.23, W / 2, L / 2, 0.47, 1)         # border panel
        _box(bm, -W / 2 + 0.02, -L / 2 + 0.02, 0.47, W / 2 - 0.02, L / 2 - 0.02, 0.56, 2)  # pillow top
        # the yellow law/price card on the foot corner
        _box(bm, W / 2 - 0.30, -L / 2 - 0.005, 0.30, W / 2 - 0.12, -L / 2 + 0.0, 0.43, 3)
    _gen_obj("mattress", ["Foundation", "Border", "Top", "Card"], b)


def gen_adjustable():
    """A mattress on a black adjustable base: low base on short legs, the head section raised ~25 degrees."""
    W, L = 1.53, 2.03
    def b(bm):
        for sx in (-1, 1):
            for sy in (-1, 1):
                _box(bm, sx * (W / 2 - 0.15) - 0.03, sy * (L / 2 - 0.2) - 0.03, 0.0, sx * (W / 2 - 0.15) + 0.03, sy * (L / 2 - 0.2) + 0.03, 0.12, 0)
        _box(bm, -W / 2, -L / 2, 0.12, W / 2, L / 2, 0.30, 0)
        # foot part of the mattress flat, head part tilted (built flat then rotated)
        f = _box(bm, -W / 2, -L / 2, 0.30, W / 2, 0.15, 0.58, 1)
        _box(bm, -W / 2 + 0.02, -L / 2 + 0.02, 0.58, W / 2 - 0.02, 0.15, 0.64, 2)
        head = list(_box(bm, -W / 2, 0.15, 0.30, W / 2, L / 2, 0.58, 1)) + list(_box(bm, -W / 2 + 0.02, 0.15, 0.58, W / 2 - 0.02, L / 2 - 0.02, 0.64, 2))
        vs = {v for fc in head for v in fc.verts}
        a = math.radians(25)
        for v in vs:
            y, z = v.co.y - 0.15, v.co.z - 0.30
            v.co.y = 0.15 + y * math.cos(a) - z * math.sin(a)
            v.co.z = 0.30 + y * math.sin(a) + z * math.cos(a)
        _box(bm, W / 2 - 0.30, -L / 2 - 0.005, 0.36, W / 2 - 0.12, -L / 2, 0.50, 3)
    _gen_obj("adjustable", ["Foundation", "Border", "Top", "Card"], b)


def gen_pillowtower():
    """The pillow display tower in the mattress gallery: a white open cube shelf with bagged pillows."""
    def b(bm):
        _box(bm, -0.45, -0.25, 0.0, 0.45, 0.25, 0.05, 0)
        for x in (-0.45, 0.43):
            _box(bm, x, -0.25, 0.05, x + 0.02, 0.25, 1.6, 0)
        for i in range(1, 5):
            _box(bm, -0.45, -0.25, i * 0.38, 0.45, 0.25, i * 0.38 + 0.02, 0)
        for i in range(4):
            z = 0.05 + i * 0.38 if i == 0 else i * 0.38 + 0.02
            for j in range(2):
                _box(bm, -0.40 + j * 0.42, -0.22, z, -0.03 + j * 0.42, 0.20, z + 0.14, 1)
                _box(bm, -0.40 + j * 0.42, -0.22, z + 0.14, -0.03 + j * 0.42, 0.20, z + 0.27, 2)
    _gen_obj("pillowtower", ["Shelf", "PillowA", "PillowB"], b)


def gen_roundrug():
    """A round area rug (the pack's Carpet_Round is one concave n-gon that triangulates badly): a 48-gon
    field and a border ring, 12 mm thick, radius 1 (scaled by the entry's size)."""
    def b(bm):
        n = 48
        def ring(r0, r1, z, mi):
            for i in range(n):
                a0, a1 = 2 * math.pi * i / n, 2 * math.pi * (i + 1) / n
                vs = [bm.verts.new((r0 * math.cos(a0), r0 * math.sin(a0), z)), bm.verts.new((r1 * math.cos(a0), r1 * math.sin(a0), z)),
                      bm.verts.new((r1 * math.cos(a1), r1 * math.sin(a1), z)), bm.verts.new((r0 * math.cos(a1), r0 * math.sin(a1), z))]
                f = bm.faces.new(vs)
                f.material_index = mi
        ring(0.0, 0.88, 0.012, 0)
        ring(0.88, 1.0, 0.012, 1)
        # the edge, so it reads as a pile with some thickness
        for i in range(n):
            a0, a1 = 2 * math.pi * i / n, 2 * math.pi * (i + 1) / n
            vs = [bm.verts.new((math.cos(a0), math.sin(a0), 0.0)), bm.verts.new((math.cos(a1), math.sin(a1), 0.0)),
                  bm.verts.new((math.cos(a1), math.sin(a1), 0.012)), bm.verts.new((math.cos(a0), math.sin(a0), 0.012))]
            f = bm.faces.new(vs)
            f.material_index = 1
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    _gen_obj("roundrug", ["Field", "Border"], b)


GEN = {"roundrug": gen_roundrug, "mattress": gen_mattress, "adjustable": gen_adjustable, "pillowtower": gen_pillowtower}


# ---------------------------------------------------------------- conversion
def convert(e, uvmap, pmat):
    ob = import_src(e["src"])
    me = ob.data
    # turn so the front faces -Y
    if e.get("turn"):
        a = math.radians(e["turn"])
        for v in me.vertices:
            x, y = v.co.x, v.co.y
            v.co.x = x * math.cos(a) - y * math.sin(a)
            v.co.y = x * math.sin(a) + y * math.cos(a)
    # drop parts by material (e.g. a bed's rug)
    drop = set(e.get("drop", []))
    if drop:
        bm = bmesh.new()
        bm.from_mesh(me)
        names = [m.name.split(".")[0] if m else "" for m in me.materials]
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if names[f.material_index] in drop], context="FACES")
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
        bm.to_mesh(me)
        bm.free()
    xs = [v.co.x for v in me.vertices]; ys = [v.co.y for v in me.vertices]; zs = [v.co.z for v in me.vertices]
    cx, cy, z0 = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, min(zs)
    sx, sy, sz = max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)
    tw, td, th = e["size"]
    kx = tw / sx if tw else None
    ky = td / sy if td else None
    kz = th / sz if th else None
    k = [c for c in (kx, ky, kz) if c]
    u = sum(k) / len(k) if k else 1.0
    kx, ky, kz = kx or u, ky or u, kz or u
    for v in me.vertices:
        v.co.x = (v.co.x - cx) * kx
        v.co.y = (v.co.y - cy) * ky
        v.co.z = (v.co.z - z0) * kz
    # material swap -> palette UVs, one material
    mm = e["mats"]
    names = [m.name.split(".")[0] if m else "" for m in me.materials]
    for n in names:
        if n not in mm and "*" not in mm:
            print("LYPACK WARN %s: material %s not mapped" % (e["id"], n))
    if not me.uv_layers:
        me.uv_layers.new(name="UVMap")
    while len(me.uv_layers) > 1:
        me.uv_layers.remove(me.uv_layers[-1])
    uvl = me.uv_layers[0].data
    for p in me.polygons:
        n = names[p.material_index] if p.material_index < len(names) else ""
        sw = mm.get(n, mm.get("*", "magenta"))
        u_, v_ = uvmap[sw]
        for li in p.loop_indices:
            uvl[li].uv = (u_, v_)
    me.materials.clear()
    me.materials.append(pmat)
    for p in me.polygons:
        p.material_index = 0
    if e.get("smooth") is not None:
        for p in me.polygons:
            p.use_smooth = bool(e["smooth"])
    ob.name = e["id"]
    me.name = e["id"]
    tris = sum(len(p.vertices) - 2 for p in me.polygons)
    # .gltf + .bin with the palette as an external file next to them: Godot then shares ONE imported palette
    # texture between all the pack models (a .glb would embed and extract a copy per model)
    path = os.path.join(OUT, e["id"] + ".gltf")
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLTF_SEPARATE", export_texture_dir="", use_selection=True, export_yup=True,
                              export_apply=True, export_texcoords=True, export_normals=True, export_tangents=False,
                              export_materials="EXPORT", export_image_format="AUTO", export_cameras=False,
                              export_lights=False, export_animations=False)
    xs = [v.co.x for v in me.vertices]; ys = [v.co.y for v in me.vertices]; zs = [v.co.z for v in me.vertices]
    size = [round(max(xs) - min(xs), 3), round(max(ys) - min(ys), 3), round(max(zs) - min(zs), 3)]
    print("LYPACK %s %s tris=%d size=%s" % (e["id"], e["src"], tris, size))
    return ob, {"src": e["src"], "size": size, "tris": tris, "family": e.get("family", ""), "kb": round((os.path.getsize(path) + os.path.getsize(path[:-5] + ".bin")) / 1024)}


def sheet(ids, out, cols=6):
    """Render each converted model (front 3/4, Cycles, neutral studio) into one labelled contact sheet."""
    from PIL import Image, ImageDraw
    tiles = []
    tmp = os.path.join(PROJ, ".scratch", "lyq")
    os.makedirs(tmp, exist_ok=True)
    for i in ids:
        clear()
        bpy.ops.import_scene.gltf(filepath=os.path.join(OUT, i + ".gltf"))
        obs = [o for o in bpy.context.scene.objects if o.type == "MESH"]
        mx = max(max(abs(v[0]) for v in o.bound_box) for o in obs)
        my = max(max(abs(v[1]) for v in o.bound_box) for o in obs)
        mz = max(max(v[2] for v in o.bound_box) for o in obs)
        r = max(mx, my, mz * 0.6) + 0.2
        sc = bpy.context.scene
        sc.render.engine = "CYCLES"
        sc.cycles.samples = 24
        sc.cycles.device = "CPU"
        sc.render.resolution_x = sc.render.resolution_y = 320
        sc.view_settings.view_transform = "AgX"
        w = bpy.data.worlds.new("w"); sc.world = w
        w.use_nodes = True
        w.node_tree.nodes["Background"].inputs[0].default_value = (0.55, 0.55, 0.55, 1)
        w.node_tree.nodes["Background"].inputs[1].default_value = 0.9
        bpy.ops.mesh.primitive_plane_add(size=40)
        fl = bpy.context.object
        fm = bpy.data.materials.new("fl"); fm.use_nodes = True
        fm.node_tree.nodes["Principled BSDF"].inputs[0].default_value = (0.42, 0.42, 0.42, 1)
        fl.data.materials.append(fm)
        ld = bpy.data.lights.new("k", "AREA"); ld.energy = 900 * r * r; ld.size = 3 * r
        lo = bpy.data.objects.new("k", ld); sc.collection.objects.link(lo)
        lo.location = (-1.5 * r, -2.5 * r, 3 * r); lo.rotation_euler = (math.radians(40), 0, math.radians(-30))
        cd = bpy.data.cameras.new("c"); cd.lens = 50
        co = bpy.data.objects.new("c", cd); sc.collection.objects.link(co); sc.camera = co
        d = r * 3.2
        co.location = (d * 0.55, -d * 0.83, mz * 0.5 + d * 0.38)
        dx, dy, dz = -co.location[0], -co.location[1], mz * 0.4 - co.location[2]
        co.rotation_euler = (math.atan2(math.hypot(dx, dy), -dz), 0, math.atan2(dy, dx) - math.pi / 2)
        p = os.path.join(tmp, i + ".png")
        sc.render.filepath = p
        bpy.ops.render.render(write_still=True)
        tiles.append((i, p))
    rows = (len(tiles) + cols - 1) // cols
    S = 320
    im = Image.new("RGB", (cols * S, rows * (S + 22)), (24, 24, 28))
    dr = ImageDraw.Draw(im)
    for n, (i, p) in enumerate(tiles):
        x, y = (n % cols) * S, (n // cols) * (S + 22)
        im.paste(Image.open(p).convert("RGB"), (x, y + 22))
        dr.text((x + 6, y + 5), i, fill=(240, 220, 120))
        os.remove(p)
    im.save(out)
    print("SHEET", out)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    sheet_out = None
    if "--sheet" in argv:
        k = argv.index("--sheet"); sheet_out = argv[k + 1]; argv = argv[:k] + argv[k + 2:]
    only_sheet = "--sheet-only" in argv
    argv = [a for a in argv if a != "--sheet-only"]
    cfg = json.load(open(CFG))
    uvmap = write_palette(cfg["palette"])
    mpath = os.path.join(OUT, "manifest.json")
    man = json.load(open(mpath)) if os.path.exists(mpath) else {}
    ents = [e for e in cfg["models"] if not argv or e["id"] in argv]
    if not only_sheet:
        for e in ents:
            clear()
            pmat = palette_material()
            _, info = convert(e, uvmap, pmat)
            man[e["id"]] = info
        man = {k: man[k] for k in sorted(man) if any(e["id"] == k for e in cfg["models"])}
        json.dump(man, open(mpath, "w"), indent=1)
    if sheet_out:
        sheet([e["id"] for e in ents], sheet_out)


main()
