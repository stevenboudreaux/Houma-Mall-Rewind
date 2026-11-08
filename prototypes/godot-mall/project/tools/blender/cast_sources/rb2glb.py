# Rocketbox (MIT, github.com/microsoft/Microsoft-Rocketbox) facial FBX -> one .glb for the Godot mall's
# NpcBody / NpcRig. Workstream CHAR-SOURCES, design/godot-characters-sources.md. DEV ONLY: nothing in the
# game loads its output yet; the .glb files stay out of the repo until Steven picks a source.
#   pip install bpy==5.2.3 numpy   (Python 3.13; use `uv venv` if pip stalls), Pillow on the system python
#   git clone --filter=blob:none --no-checkout https://github.com/microsoft/Microsoft-Rocketbox rb
#   (cd rb && git sparse-checkout set /Assets/Avatars/Adults/Male_Adult_08/ && git checkout)
#   [HEAVY=1.0] python rb2glb.py rb/Assets/Avatars/Adults/Male_Adult_08 /abs/out/rb_male08.glb
# Prints STATS (tris, materials, morphs, hips height in m: pass it as --hips to the QA scripts).
# 1. bones renamed Bip01 -> mixamorig:* (eyes -> LeftEye/RightEye, jaw -> Jaw)
# 2. re-posed to a Mixamo-style T-pose and that pose applied as rest (shape keys carried through)
# 3. only the ARKit 52 (AK_*) + 15 visemes (AA_VI_*) shape keys kept, renamed without prefix
# 2b. every Mixamo-named bone given Ch01's rest orientation (npc/anims.json 'rest'), so NpcRig has nothing
#     to retarget and TALK's eye_point / look (which read the un-retargeted pose) work as on a Mixamo skin
# 2c. optional HEAVY=<k>: a heavier build, the trunk pushed out along smoothed normals by skin weight
# 4. textures: head colour 2048, body / hair 1024, normals 1024; specular dropped (via Pillow: some
#    Rocketbox colour TGAs don't load in Blender)
import bpy, sys, os, math, glob
from mathutils import Vector, Matrix
import numpy as np

src, out = sys.argv[-2], sys.argv[-1]
name = os.path.basename(src.rstrip('/'))
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=f"{src}/Export/{name}_facial.fbx", automatic_bone_orientation=False)
arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
mesh = next(o for o in bpy.data.objects if o.type == 'MESH')
for o in list(bpy.data.objects):
    if o not in (arm, mesh): bpy.data.objects.remove(o)

for o in (arm, mesh):
    o.animation_data_clear()
if mesh.data.shape_keys: mesh.data.shape_keys.animation_data_clear()
# ---- 1. names
M = {'Pelvis': 'Hips', 'Spine': 'Spine', 'Spine1': 'Spine1', 'Spine2': 'Spine2', 'Neck': 'Neck', 'Head': 'Head',
     'LEye': 'LeftEye', 'REye': 'RightEye', 'MJaw': 'Jaw'}
for s, S in (('L', 'Left'), ('R', 'Right')):
    M.update({f'{s} Clavicle': f'{S}Shoulder', f'{s} UpperArm': f'{S}Arm', f'{s} Forearm': f'{S}ForeArm',
              f'{s} Hand': f'{S}Hand', f'{s} Thigh': f'{S}UpLeg', f'{s} Calf': f'{S}Leg', f'{s} Foot': f'{S}Foot',
              f'{s} Toe0': f'{S}ToeBase'})
    for fi, fn in enumerate(['Thumb', 'Index', 'Middle', 'Ring', 'Pinky']):
        M[f'{s} Finger{fi}'] = f'{S}Hand{fn}1'
        M[f'{s} Finger{fi}1'] = f'{S}Hand{fn}2'
        M[f'{s} Finger{fi}2'] = f'{S}Hand{fn}3'
for b in arm.data.bones:
    k = b.name.replace('Bip01 ', '')
    if k in M:
        new = 'mixamorig:' + M[k]
        vg = mesh.vertex_groups.get(b.name)
        if vg: vg.name = new
        b.name = new

# ---- 3. shape keys: keep AK_ and AA_VI_
kb = mesh.data.shape_keys.key_blocks
for k in list(kb)[1:]:
    if not (k.name.startswith('AK_') or k.name.startswith('AA_VI_')):
        mesh.shape_key_remove(k)
for k in list(mesh.data.shape_keys.key_blocks)[1:]:
    k.name = k.name.split('_', 2)[2] if k.name.startswith('AK_') else 'viseme_' + k.name.split('_', 3)[3]

# ---- scale to metres, standing on z=0
bpy.context.view_layer.update()
mw = arm.matrix_world
print('arm scale', arm.scale[:], 'rot', arm.rotation_euler[:], 'mesh parent', mesh.parent, mesh.scale[:])
for o in bpy.context.view_layer.objects: o.select_set(o in (arm, mesh))
bpy.context.view_layer.objects.active = arm
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bpy.context.view_layer.update()
w = mesh.matrix_world.copy()
mesh.matrix_parent_inverse.identity()
mesh.matrix_basis = arm.matrix_world.inverted() @ w
for o in bpy.context.view_layer.objects: o.select_set(o == mesh)
bpy.context.view_layer.objects.active = mesh
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bpy.context.view_layer.update()
print('after apply', arm.scale[:], mesh.matrix_world.to_scale()[:])

# ---- 2. T-pose
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='POSE')
def aim(bn, d):
    pb = arm.pose.bones.get(bn)
    if pb is None: return
    bpy.context.view_layer.update()
    m = arm.matrix_world @ pb.matrix
    kids = [c for c in pb.children if not c.name.endswith('Thumb1')]
    if not kids: return
    tgt = kids[0]
    for c in kids:
        if 'Middle1' in c.name: tgt = c
    cur = (arm.matrix_world @ tgt.head) - (arm.matrix_world @ pb.head)
    q = cur.normalized().rotation_difference(Vector(d).normalized())
    loc = m.to_translation()
    R = q.to_matrix().to_4x4()
    newm = Matrix.Translation(loc) @ R @ Matrix.Translation(-loc) @ m
    pb.matrix = arm.matrix_world.inverted() @ newm
    bpy.context.view_layer.update()
for S, sx in (('Left', 1), ('Right', -1)):
    # which side is +x? decided from the rest positions below
    pass
lx = (arm.matrix_world @ arm.pose.bones['mixamorig:LeftHand'].head).x
side = {'Left': 1 if lx > 0 else -1, 'Right': -1 if lx > 0 else 1}
for S in ('Left', 'Right'):
    sx = side[S]
    for b in ('Arm', 'ForeArm', 'Hand'):
        aim(f'mixamorig:{S}{b}', (sx, 0, 0))
    for f in ('Index', 'Middle', 'Ring', 'Pinky'):
        for i in (1, 2):
            aim(f'mixamorig:{S}Hand{f}{i}', (sx, 0, 0))
    for b in ('UpLeg', 'Leg'):  # straight down
        aim(f'mixamorig:{S}{b}', (0, 0, -1))
bpy.context.view_layer.update()

# carry the pose into the mesh, key by key
dg = bpy.context.evaluated_depsgraph_get()
keys = mesh.data.shape_keys.key_blocks
n = len(mesh.data.vertices)
def posed():
    dg.update()
    ev = mesh.evaluated_get(dg)
    a = np.empty(n * 3); ev.data.vertices.foreach_get('co', a); return a
for k in keys: k.value = 0.0
mesh.show_only_shape_key = False
base = posed()
res = {}
for k in list(keys)[1:]:
    k.value = 1.0
    res[k.name] = posed()
    k.value = 0.0
keys[0].data.foreach_set('co', base)
for k in list(keys)[1:]:
    k.data.foreach_set('co', res[k.name])
mesh.data.vertices.foreach_set('co', base)
mesh.data.update()
bpy.ops.pose.armature_apply(selected=False)
bpy.ops.object.mode_set(mode='OBJECT')

# ---- 2b. bone rests = Ch01's (npc/anims.json 'rest', Godot global quats [x,y,z,w]) so NpcRig has
# nothing to fix and every reader of the un-retargeted pose (TALK's eye_point, look) sees a Mixamo skin
import json
from mathutils import Quaternion
ANIMS = os.environ.get('ANIMS_JSON', os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../../npc/anims.json'))
REST = json.load(open(ANIMS))['rest']
C = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))     # Godot (Y up) -> Blender (Z up)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='EDIT')
for eb in arm.data.edit_bones:
    k = eb.name.replace(':', '_')
    if k not in REST: continue
    x, y, z, w = REST[k]
    Rg = Quaternion((w, x, y, z)).to_matrix()
    Rb = C @ (Rg @ Matrix.Rotation(math.radians(90), 3, "X")) @ C.inverted()
    L = eb.length
    M = Rb.to_4x4(); M.translation = eb.head.copy()
    eb.matrix = M
    eb.length = L
bpy.ops.object.mode_set(mode='OBJECT')

# ---- 2c. optional heavier build (HEAVY=<k> env): push the skin out along its normals by the weight of the
# trunk bones, so belly, chest, hips, thighs and upper arms fill out; same offset on every shape key
HEAVY = float(os.environ.get('HEAVY', '0'))
if HEAVY > 0:
    G = {'Spine': 0.060, 'Spine1': 0.055, 'Spine2': 0.022, 'Hips': 0.045, 'LeftUpLeg': 0.028, 'RightUpLeg': 0.028,
         'LeftArm': 0.016, 'RightArm': 0.016, 'LeftShoulder': 0.012, 'RightShoulder': 0.012,
         'LeftForeArm': 0.006, 'RightForeArm': 0.006, 'LeftLeg': 0.008, 'RightLeg': 0.008}
    gi = {mesh.vertex_groups['mixamorig:' + k].index: v for k, v in G.items() if 'mixamorig:' + k in mesh.vertex_groups}
    mesh.data.update()
    off = np.zeros((n, 3))
    # one normal per position (welds the shirt/jeans and collar seams), smoothed over 3 cm
    co = np.empty(n * 3); mesh.data.vertices.foreach_get('co', co); co = co.reshape(-1, 3)
    nr = np.empty(n * 3); mesh.data.vertices.foreach_get('normal', nr); nr = nr.reshape(-1, 3)
    amt = np.array([sum(g.weight * gi.get(g.group, 0.0) for g in v.groups) for v in mesh.data.vertices])
    cell = np.floor(co / 0.03).astype(np.int64)
    keyc = cell[:, 0] * 1000003 + cell[:, 1] * 1009 + cell[:, 2]
    _, inv = np.unique(keyc, return_inverse=True)
    acc = np.zeros((inv.max() + 1, 3)); np.add.at(acc, inv, nr)
    am = np.zeros(inv.max() + 1); cnt = np.zeros(inv.max() + 1); np.add.at(am, inv, amt); np.add.at(cnt, inv, 1)
    sn = acc[inv]; sn /= np.maximum(np.linalg.norm(sn, axis=1, keepdims=True), 1e-6)
    samt = (am / cnt)[inv]
    for v in mesh.data.vertices:
        a = samt[v.index]
        if a > 0:
            nz = Vector(sn[v.index])
            # belly forward more than sideways; nothing pushed backwards past the spine much
            f = 1.0 + 0.8 * max(0.0, -nz.y) - 0.4 * max(0.0, nz.y)
            off[v.index] = np.array(nz) * a * f * HEAVY
    off = off.reshape(-1)
    for k in mesh.data.shape_keys.key_blocks:
        c = np.empty(n * 3); k.data.foreach_get('co', c); k.data.foreach_set('co', c + off)
    c = np.empty(n * 3); mesh.data.vertices.foreach_get('co', c); mesh.data.vertices.foreach_set('co', c + off)
    mesh.data.update()

# ---- 4. textures and materials
tex = glob.glob(f"{src}/Textures/*_color.tga")
work = os.path.abspath(os.path.dirname(out)) + f"/{name}_tex"; os.makedirs(work, exist_ok=True)
def img(path, size, alpha=False):
    import subprocess
    fn = f"{work}/{os.path.basename(path)[:-4]}.png"
    subprocess.run(['/usr/bin/python3', '-I', '-c', 'import sys;from PIL import Image;im=Image.open(sys.argv[1]);im=im.resize((int(sys.argv[3]),)*2, Image.LANCZOS);im.save(sys.argv[2])', path, fn, str(size)], check=True)
    return bpy.data.images.load(fn, check_existing=False)
for m in mesh.data.materials:
    key = m.name.split('_')[-1]           # body / head / opacity
    cpath = glob.glob(f"{src}/Textures/*_{key}_color.tga")
    npath = glob.glob(f"{src}/Textures/*_{key}_normal.tga")
    m.use_nodes = True
    nt = m.node_tree; nt.nodes.clear()
    bsdf = nt.nodes.new('ShaderNodeBsdfPrincipled'); outn = nt.nodes.new('ShaderNodeOutputMaterial')
    nt.links.new(bsdf.outputs[0], outn.inputs[0])
    bsdf.inputs['Roughness'].default_value = 0.62 if key != 'opacity' else 0.7
    bsdf.inputs['Specular IOR Level'].default_value = 0.35
    if cpath:
        t = nt.nodes.new('ShaderNodeTexImage'); t.image = img(cpath[0], 2048 if key == 'head' else 1024)
        nt.links.new(t.outputs['Color'], bsdf.inputs['Base Color'])
        if key == 'opacity':
            nt.links.new(t.outputs['Alpha'], bsdf.inputs['Alpha'])
            m.blend_method = 'CLIP' if hasattr(m, 'blend_method') else None
    if npath:
        t2 = nt.nodes.new('ShaderNodeTexImage'); t2.image = img(npath[0], 1024); t2.image.colorspace_settings.name = 'Non-Color'
        nm = nt.nodes.new('ShaderNodeNormalMap'); nt.links.new(t2.outputs['Color'], nm.inputs['Color'])
        nt.links.new(nm.outputs['Normal'], bsdf.inputs['Normal'])

mesh.name = name; arm.name = 'Armature'
mesh.data.calc_loop_triangles()
bpy.context.view_layer.update()
hips = (arm.matrix_world @ arm.data.bones['mixamorig:Hips'].head_local)
zs = [ (mesh.matrix_world @ v.co).z for v in mesh.data.vertices]
print(f"STATS tris={len(mesh.data.loop_triangles)} mats={len(mesh.data.materials)} keys={len(keys)-1} "
      f"hips_z={hips.z:.4f} height={max(zs)-min(zs):.3f} minz={min(zs):.3f}")
bpy.ops.wm.save_as_mainfile(filepath=out.replace('.glb', '.blend'))
bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', export_animations=False, export_morph=True,
                          export_morph_normal=False, export_image_format='AUTO', export_skins=True,
                          export_apply=False, export_yup=True)
print('WROTE', out)
