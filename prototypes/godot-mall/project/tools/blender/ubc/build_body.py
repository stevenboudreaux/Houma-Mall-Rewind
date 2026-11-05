"""UBC body build (design/godot-ubc-characters.md). One base body per sex from the Quaternius
Universal Base Characters kit (CC0), made into a CharBody-compatible game body:

  * bones renamed to our Mixamo names (ubc_common.mixamo_name); the kit's rest is a T-pose, as Ch01's;
  * the superhero build TONED DOWN in the base mesh (Steven: a normal default): the torso and limbs are
    Taubin-smoothed (volume kept) and 60 % of that is applied, so abs and pecs soften; muscle+ brings
    the kit's sculpt back, muscle- smooths further;
  * shape keys named as the editor's sliders ("<slider>+" / "<slider>-"): height, weight, muscle,
    shoulders, chest (male) / bust (female), waist, belly, hips, butt, thigh, calf, arms, neck_length,
    head_size, jaw, chin (the face pass);
  * region ids (characters.json "regions") in a second UV map, for the clothes' region hiding and the
    painted base layer (the clothed rule);
  * textures: the skin albedo divided by its own mean skin colour (near-white, so the material tint is
    the tone, as on the B1 bodies), eyes greyed (the iris tint), hair / brows greyed (the hair tint);
  * the eyes and eyebrows follow every shape through a proxy binding.

  BPY tools/blender/ubc/build_body.py [male|female]
"""
import os
import sys

import numpy as np
import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ubc_common as U  # noqa: E402
from PIL import Image  # noqa: E402

REGIONS = ['head', 'neck', 'chest_f', 'chest_b', 'belly_f', 'belly_b', 'pelvis_f', 'pelvis_b',
           'shoulder_l', 'shoulder_r', 'upperarm_l', 'upperarm_r', 'forearm_l', 'forearm_r',
           'hand_l', 'hand_r', 'thigh_l', 'thigh_r', 'shin_l', 'shin_r', 'foot_l', 'foot_r', 'crotch']
TONE = {"male": 0.9, "female": 0.75}     # share of the smoothing applied to the base (the default build)
TONE_ITERS = {"male": 40, "female": 25}


def gauss(d, s):
    return np.exp(-0.5 * (d / s) ** 2)


def ramp(x, a, b):
    """0 at a, 1 at b (either order), smooth."""
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


class Fields:
    def __init__(self, arm, body):
        self.arm = arm
        self.names = U.bone_names(arm)
        self.W = U.weights(body, self.names)
        self.V = U.verts(body)
        self.T = U.tris(body)
        self.E = U.adjacency(body)
        self.N = U.vnormals(self.V, self.T)
        self.head = {b.name: np.array(arm.matrix_world @ b.head_local) for b in arm.data.bones}
        self.tail = {b.name: np.array(arm.matrix_world @ b.tail_local) for b in arm.data.bones}

    def w(self, *names, prefix=False):
        out = np.zeros(len(self.V))
        for j, n in enumerate(self.names):
            for q in names:
                if (n.startswith(q) if prefix else n == q):
                    out += self.W[:, j]
        return out

    def side(self, base):
        return self.w("mixamorig_Left" + base) + self.w("mixamorig_Right" + base)

    def limb_radial(self, bones, amount):
        """Push vertices out from the axis of the named bones (radius x (1 + amount x weight))."""
        D = np.zeros_like(self.V)
        for bn in bones:
            j = self.names.index(bn)
            wj = self.W[:, j]
            a, b = self.head[bn], self.tail[bn]
            ax = b - a
            L = np.linalg.norm(ax)
            if L < 1e-6:
                continue
            ax = ax / L
            rel = self.V - a
            t = rel @ ax
            perp = rel - np.outer(t, ax)
            D += perp * (amount * wj)[:, None]
        return D


def regions(F):
    names = F.names
    dom = np.argmax(F.W, axis=1)
    V = F.V
    hips_z = F.head["mixamorig_Hips"][2]
    sp_y = {k: F.head[k][1] for k in ["mixamorig_Hips", "mixamorig_Spine", "mixamorig_Spine1", "mixamorig_Spine2"]}
    out = np.zeros(len(V), dtype=int)
    for i in range(len(V)):
        n = names[dom[i]].replace("mixamorig_", "")
        x, y, z = V[i]
        lr = "l" if x >= 0 else "r"
        front = y < np.interp(z, [hips_z, F.head["mixamorig_Spine2"][2]], [sp_y["mixamorig_Hips"], sp_y["mixamorig_Spine2"]])
        if n == "Head":
            r = "head"
        elif n == "Neck":
            r = "neck"
        elif n == "Spine2":
            r = "chest_f" if front else "chest_b"
        if (n == "Spine2" or "Shoulder" in n or n == "Spine1") and front and abs(x) < 0.17 \
                and F.head["mixamorig_Spine1"][2] < z < F.head["mixamorig_Neck"][2] - 0.04:
            r = "chest_f"      # the whole chest front (breasts weighted to the shoulders too): the base layer
        elif n in ("Spine1", "Spine"):
            r = "belly_f" if front else "belly_b"
        elif n in ("Hips", "root"):
            r = "pelvis_f" if front else "pelvis_b"
            if abs(x) < 0.075 and z < hips_z - 0.05:
                r = "crotch"
        elif "Shoulder" in n:
            r = "shoulder_" + lr
        elif "ForeArm" in n:
            r = "forearm_" + lr
        elif n.endswith("Arm"):
            r = "upperarm_" + lr
        elif "Hand" in n:
            r = "hand_" + lr
        elif "UpLeg" in n:
            r = "thigh_" + lr
            if abs(x) < 0.06 and z > hips_z - 0.16:
                r = "crotch"
        elif n.endswith("Leg"):
            r = "shin_" + lr
        else:
            r = "foot_" + lr
        out[i] = REGIONS.index(r)
    return out


def write_region_uv(o, reg):
    me = o.data
    uv = me.uv_layers.new(name="regions")
    loops = np.zeros(len(me.loops), dtype=np.int64)
    me.loops.foreach_get("vertex_index", loops)
    co = np.zeros((len(me.loops), 2))
    co[:, 0] = reg[loops] + 0.5          # the shader reads int(UV2.x)
    uv.data.foreach_set("uv", co.reshape(-1))


# ------------------------------------------------------------------ textures
def neutral_skin(src, dst):
    im = np.asarray(Image.open(src).convert("RGB")).astype(np.float32) / 255.0
    lum = im.mean(2)
    skin = (lum > 0.35) & (im[:, :, 0] > im[:, :, 2])
    mean = im[skin].mean(0)
    out = np.clip(im / mean * 0.92, 0, 1)
    # the painted underwear (dark) stays dark grey: the clothed rule's base layer reads as fabric
    Image.fromarray((out * 255).astype(np.uint8)).save(dst)
    return mean


NORMAL_KEEP = {"male": 0.25, "female": 0.4}    # share of the normal map's broad forms kept (muscle relief)
ALBEDO_KEEP = {"male": 0.45, "female": 0.6}    # share of the albedo's broad painted shading kept


def _box(a, r, axis):
    c = np.cumsum(np.pad(a, [(r + 1, r) if k == axis else (0, 0) for k in range(a.ndim)], mode="edge"), axis=axis)
    hi = np.take(c, np.arange(2 * r + 1, c.shape[axis]), axis=axis)
    lo = np.take(c, np.arange(0, c.shape[axis] - 2 * r - 1), axis=axis)
    return (hi - lo) / (2 * r + 1)


def _blur(a, r):
    """~Gaussian blur of an (h, w, c) float array: three box passes each way, radius r/2 px."""
    b = max(1, int(r // 2))
    out = a.astype(np.float64)
    for _ in range(3):
        out = _box(out, b, 0)
        out = _box(out, b, 1)
    return out.astype(np.float32)


def soften_normal(src, dst, keep=0.3, r=28):
    """The kit's normal map carries the superhero muscle relief (abs, pecs) as broad forms: keep the fine
    detail (pores, folds) and only `keep` of the broad forms, so the default build reads normal."""
    n = np.asarray(Image.open(src).convert("RGB")).astype(np.float32) / 255.0 * 2 - 1
    low = _blur(n, r)
    flat = np.zeros_like(n); flat[:, :, 2] = 1
    out = n - low + flat + (low - flat) * keep
    out /= np.maximum(np.linalg.norm(out, axis=2, keepdims=True), 1e-6)
    Image.fromarray(((out * 0.5 + 0.5) * 255).clip(0, 255).astype(np.uint8)).save(dst)


def soften_albedo(src, dst, keep=0.5, r=28):
    """Same for the painted shading in the albedo (broad luminance only; the colour stays)."""
    a = np.asarray(Image.open(src).convert("RGB")).astype(np.float32) / 255.0
    l = a.mean(2, keepdims=True)
    low = _blur(l, r)
    mean = float(np.median(l))
    out = a * ((low * keep + mean * (1 - keep)) / np.maximum(low, 1e-3))
    Image.fromarray((out.clip(0, 1) * 255).astype(np.uint8)).save(dst)


def grey(src, dst, gain=1.0, rgba=False):
    im = Image.open(src)
    a = np.asarray(im.convert("RGBA")).astype(np.float32) / 255.0
    l = (a[:, :, :3] @ np.array([0.299, 0.587, 0.114]))
    hi = np.percentile(l[a[:, :, 3] > 0.5], 95) if (a[:, :, 3] > 0.5).any() else 1.0
    l = np.clip(l / max(hi, 1e-3) * gain, 0, 1)
    out = np.dstack([l, l, l, a[:, :, 3]]) if rgba else np.dstack([l, l, l])
    Image.fromarray((out * 255).astype(np.uint8)).save(dst)


def set_image(mat, kind, path):
    """Point the material's base colour / normal / roughness image at `path`."""
    for n in mat.node_tree.nodes:
        if n.type != "TEX_IMAGE" or n.image is None:
            continue
        nm = n.image.name.lower()
        if (kind == "base" and ("basecolor" in nm or "ligh" in nm or "dark" in nm or "brown" in nm)) \
                or (kind == "normal" and "normal" in nm) or (kind == "rough" and "rough" in nm):
            n.image = bpy.data.images.load(path, check_existing=True)


def find_image(*names):
    for n in names:
        for root in ("Base Characters/Textures/Normals Unity - Godot", "Base Characters/Textures", "Base Characters/Godot - UE"):
            p = os.path.join(U.KIT, root, n)
            if os.path.exists(p):
                return p
    raise FileNotFoundError(names)


# ------------------------------------------------------------------ shapes
def shapes(F, sex, base, orig):
    V = base
    N = U.vnormals(V, F.T)
    S = {}
    torso = F.w("mixamorig_Spine", prefix=True) + F.w("mixamorig_Hips")
    arms = F.side("Arm") + F.side("ForeArm") + F.side("Shoulder") * 0.6
    legs = F.side("UpLeg") + F.side("Leg")
    headm = F.w("mixamorig_Head")
    neck = F.w("mixamorig_Neck")
    hands = F.w("mixamorig_LeftHand", prefix=True) + F.w("mixamorig_RightHand", prefix=True)
    feet = F.side("Foot") + F.side("ToeBase")
    hz = F.head["mixamorig_Hips"][2]
    s1z = F.head["mixamorig_Spine1"][2]
    s2z = F.head["mixamorig_Spine2"][2]
    nz = F.head["mixamorig_Neck"][2]
    headz = F.head["mixamorig_Head"][2]
    x, y, z = V[:, 0], V[:, 1], V[:, 2]
    front = np.clip(-N[:, 1], 0, 1)
    back = np.clip(N[:, 1], 0, 1)
    body_only = np.clip(1 - headm - hands - feet, 0, 1)

    # muscle: the kit's sculpt back (+), smoother and a little leaner (-)
    S["muscle+"] = orig
    mask = U.smooth_field(np.clip(torso + arms + legs, 0, 1) * (1 - headm), F.E, 4)
    more = U.smooth(V, F.E, mask, iters=25)
    S["muscle-"] = V + (more - V) * 0.9 - N * (0.003 * mask)[:, None]

    # weight (build): plus adds soft volume where people carry it; slim takes it off
    belly = gauss(np.hypot(x / 1.3, (z - (s1z * 0.6 + hz * 0.4))), 0.13) * front * torso
    hipsv = gauss(z - (hz - 0.05), 0.12) * (torso + legs)
    thighs = F.side("UpLeg") * gauss(z - (hz - 0.2), 0.18)
    uarm = F.side("Arm")
    chestv = gauss(z - s2z, 0.08) * torso
    neckv = neck + headm * ramp(z, headz + 0.06, headz - 0.02) * 0.6
    fat = (0.016 * torso + 0.045 * belly + 0.028 * hipsv + 0.03 * thighs + 0.018 * uarm
           + 0.01 * F.side("ForeArm") + 0.012 * F.side("Leg") + 0.012 * chestv + 0.012 * neckv
           + 0.002 * (hands + feet))
    fat = U.smooth_field(fat, F.E, 6)
    S["weight+"] = V + N * fat[:, None] + np.array([0, -1, 0]) * (0.02 * belly)[:, None]
    lean = (0.012 * torso + 0.01 * (arms + legs) * (1 - hands - feet) + 0.008 * belly) * body_only
    S["weight-"] = V - N * U.smooth_field(lean, F.E, 6)[:, None]

    # height: the legs and the torso stretch (feet stay on the floor; the head keeps its size)
    def stretch(f):
        Z = z.copy()
        top = headz
        k = np.where(z < top, z * f, top * f + (z - top))
        out = V.copy(); out[:, 2] = k
        out[:, 0] = x * (1 + (f - 1) * 0.25); out[:, 1] = y * (1 + (f - 1) * 0.25)
        return out
    S["height+"] = stretch(1.12)
    S["height-"] = stretch(0.89)

    # shoulders: the arms and the shoulder caps move out
    armchain = np.clip(F.side("Arm") + F.side("ForeArm") + F.w("mixamorig_LeftHand", prefix=True)
                       + F.w("mixamorig_RightHand", prefix=True) + F.side("Shoulder") * 0.7, 0, 1)
    armchain = U.smooth_field(armchain, F.E, 3)
    sx = np.sign(x) * armchain
    S["shoulders+"] = V + np.c_[sx * 0.035, 0 * sx, sx * 0 + armchain * 0.006]
    S["shoulders-"] = V + np.c_[-sx * 0.028, 0 * sx, -armchain * 0.004]

    # chest / bust: the front of the chest forward and fuller
    if sex == "female":
        cx = 0.085
        bz = s2z - 0.01
        bust = (gauss(np.hypot(np.abs(x) - cx, (z - bz) * 1.1), 0.065)) * front * torso
        bust = U.smooth_field(bust, F.E, 3)
        S["bust+"] = V + N * (0.03 * bust)[:, None] + np.array([0, -1, 0]) * (0.012 * bust)[:, None]
        S["bust-"] = V - N * (0.018 * bust)[:, None]
    pec = gauss(np.hypot(np.abs(x) - 0.08, z - (s2z + 0.02)), 0.08) * front * torso
    pec = U.smooth_field(pec, F.E, 3)
    S["chest+"] = V + N * (0.022 * pec)[:, None]
    S["chest-"] = V - N * (0.014 * pec)[:, None]

    # waist / hips: radial about the body's axis at those heights
    def radial(center_z, sz, amt, mask):
        f = gauss(z - center_z, sz) * mask
        D = np.c_[x, y - np.interp(z, [hz, s2z], [F.head["mixamorig_Hips"][1], F.head["mixamorig_Spine2"][1]]), 0 * x]
        return V + D * (amt * f)[:, None]
    tl = np.clip(torso + legs * ramp(z, hz - 0.25, hz - 0.05), 0, 1) * (1 - armchain)
    S["waist+"] = radial((hz + s1z) / 2 + 0.03, 0.07, 0.16, tl)
    S["waist-"] = radial((hz + s1z) / 2 + 0.03, 0.07, -0.12, tl)
    S["hips+"] = radial(hz - 0.07, 0.09, 0.14, tl)
    S["hips-"] = radial(hz - 0.07, 0.09, -0.1, tl)
    S["belly+"] = V + N * (0.04 * belly)[:, None] + np.array([0, -1, 0]) * (0.025 * belly)[:, None]
    S["belly-"] = V - N * (0.02 * belly)[:, None]
    butt = gauss(np.hypot(np.abs(x) - 0.07, z - (hz - 0.08)), 0.09) * back * (torso + legs)
    butt = U.smooth_field(butt, F.E, 3)
    S["butt+"] = V + N * (0.03 * butt)[:, None]
    S["butt-"] = V - N * (0.02 * butt)[:, None]

    # limbs: radial about their bones
    S["thigh+"] = V + F.limb_radial(["mixamorig_LeftUpLeg", "mixamorig_RightUpLeg"], 0.16)
    S["thigh-"] = V + F.limb_radial(["mixamorig_LeftUpLeg", "mixamorig_RightUpLeg"], -0.12)
    S["calf+"] = V + F.limb_radial(["mixamorig_LeftLeg", "mixamorig_RightLeg"], 0.15)
    S["calf-"] = V + F.limb_radial(["mixamorig_LeftLeg", "mixamorig_RightLeg"], -0.12)
    ab = ["mixamorig_LeftArm", "mixamorig_RightArm", "mixamorig_LeftForeArm", "mixamorig_RightForeArm"]
    S["arms+"] = V + F.limb_radial(ab, 0.18)
    S["arms-"] = V + F.limb_radial(ab, -0.14)

    # neck length and head size
    up = ramp(z, nz, nz + 0.07)
    S["neck_length+"] = V + np.c_[0 * z, 0 * z, up * 0.03]
    S["neck_length-"] = V + np.c_[0 * z, 0 * z, -up * 0.025]
    hc = np.array([0, F.head["mixamorig_Head"][1], headz + 0.09])
    hm = ramp(z, nz + 0.02, headz + 0.02)
    S["head_size+"] = V + (V - hc) * (0.08 * hm)[:, None]
    S["head_size-"] = V + (V - hc) * (-0.07 * hm)[:, None]

    # the face pass: jaw width and chin length (the lower face)
    jawm = headm * ramp(z, headz + 0.07, headz + 0.0) * np.clip(-y / 0.1 + 0.5, 0, 1)
    jawm = U.smooth_field(jawm, F.E, 3)
    S["jaw+"] = V + np.c_[x * 0.12 * jawm, 0 * x, 0 * x]
    S["jaw-"] = V + np.c_[-x * 0.1 * jawm, 0 * x, 0 * x]
    chin = headm * gauss(np.hypot(x, z - (headz + 0.0)), 0.035) * front
    S["chin+"] = V + np.c_[0 * x, -0.012 * chin, -0.01 * chin]
    S["chin-"] = V + np.c_[0 * x, 0.008 * chin, 0.006 * chin]
    return S


def main(sex):
    U.reset()
    arm, body, extra = U.load(sex)
    body.name = "body"
    arm.name = "Armature"
    F = Fields(arm, body)
    orig = F.V.copy()
    # the default build: toned down
    mask = U.smooth_field(np.clip(F.w("mixamorig_Spine", prefix=True) + F.w("mixamorig_Hips")
                                  + F.side("Arm") + F.side("ForeArm") + F.side("UpLeg") + F.side("Leg")
                                  + F.side("Shoulder"), 0, 1) * (1 - F.w("mixamorig_Head")), F.E, 4)
    # plain Laplacian smoothing takes the muscle relief off (Taubin keeps it: abs and pecs are broad
    # forms); the broad shrink it causes is then given back along the normals, so the body keeps its size
    sm = U.smooth(orig, F.E, mask, iters=TONE_ITERS[sex], mu=0.0)
    N0 = U.vnormals(orig, F.T)
    dn = ((sm - orig) * N0).sum(1)
    broad = U.smooth_field(dn, F.E, 60)
    sm = sm - N0 * (broad * mask)[:, None]
    base = orig + (sm - orig) * TONE[sex]
    U.set_verts(body, base)
    F.V = base
    reg = regions(F)
    write_region_uv(body, reg)
    # textures and materials
    os.makedirs(U.OUT, exist_ok=True)
    tag = "Male" if sex == "male" else "Female"
    alb = find_image("T_Superhero_Male_Ligh.png" if sex == "male" else "T_Superhero_Female_Light_BaseColor.png")
    out_alb = os.path.join(U.OUT, "ubc_skin_%s_albedo.png" % sex)
    mean = neutral_skin(alb, out_alb)
    print("UBC skin mean colour", sex, np.round(mean, 3))
    bm = body.data.materials[0]
    bm.name = "skin_body"
    set_image(bm, "base", out_alb)
    out_n = os.path.join(U.OUT, "ubc_skin_%s_normal.png" % sex)
    soften_normal(find_image("T_Superhero_%s_Normal.png" % tag), out_n, keep=NORMAL_KEEP[sex])
    set_image(bm, "normal", out_n)
    out_a2 = out_alb
    soften_albedo(out_alb, out_alb, keep=ALBEDO_KEEP[sex])
    for o in extra:
        m = o.data.materials[0]
        if "Eye" in m.name:
            o.name = "eyes"
            m.name = "eye_iris"
            p = os.path.join(U.OUT, "ubc_eye_albedo.png")
            grey(find_image("T_Eye_Brown.png"), p, 1.0)
            set_image(m, "base", p)
        else:
            o.name = "brows"
            m.name = "hair_brows"
            p = os.path.join(U.OUT, "ubc_hair%s_albedo.png" % ("1" if "1" in m.name or sex == "male" else "2"))
            src = "T_Hair_1_BaseColor.png" if sex == "male" else "T_Hair_2_BaseColor.png"
            p = os.path.join(U.OUT, "ubc_" + src.lower().replace("t_", "").replace("_basecolor", "_albedo"))
            grey(find_image(src), p, 1.0, rgba=True)
            set_image(m, "base", p)
    # the head's box (tools/blender/ubc/build_pieces.py moves a hairstyle from one kit head to the other)
    os.makedirs(U.SCRATCH, exist_ok=True)
    hv = base[F.w("mixamorig_Head") > 0.9]
    import json
    json.dump([hv.min(0).tolist(), hv.max(0).tolist()], open(os.path.join(U.SCRATCH, "headbox_%s.json" % sex), "w"))
    # shape keys
    S = shapes(F, sex, base, orig)
    for name in sorted(S):
        U.add_key(body, name, S[name])
    keys = U.body_keys(body)
    for o in extra:
        U.follow(body, o, keys=keys)
    for o in [body] + extra:
        o.data.shape_keys.use_relative = True
    print("UBC %s: %d verts, %d shape keys, regions %s" % (sex, len(base), len(S),
          {REGIONS[i]: int((reg == i).sum()) for i in range(len(REGIONS))}))
    U.export([arm, body] + extra, os.path.join(U.OUT, "body_%s.gltf" % sex))
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(U.SCRATCH, "body_%s.blend" % sex)) if os.makedirs(U.SCRATCH, exist_ok=True) is None else None


if __name__ == "__main__":
    for s in (sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]) or ["male", "female"]:
        main(s)
