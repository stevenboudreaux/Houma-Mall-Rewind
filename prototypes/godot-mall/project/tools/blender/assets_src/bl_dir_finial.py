"""The 2026 mall directory kiosk's Art-Deco fan finial (workstream A builds the kiosk; this is a separate
.glb A drops on top of the arch).

Reference: refs/new/directory/IMG_4408_t050_017-027 (straight on), t050_011 (scale in the hall).
Five folded (V-ridged) diamond blades fan out from a ball on a short collar. The centre blade is tallest
and in front; each outer pair is shorter, turned further out and set further back.
Size is scaled from the cabinet: the finial is ~165 px tall and ~135 px wide in a frame where the cabinet
face is ~915 px wide; with a ~1.25 m cabinet that is ~0.23 x 0.18 m. (Guessed: the cabinet width.)
Colour: the brief calls it silver; under the hall's warm LEDs the blades read pewter and the ball reads
warmer (brass-like), so the ball gets a warmer satin metal. (Guessed: the exact finishes.)

Origin: bottom centre of the collar = the point that sits on the top of the kiosk arch. Faces Godot +Z.
"""
import math
from lib import core, parts, mats

# ---- numbers (metres, degrees) ------------------------------------------------------------------
BLADES = [  # (angle from vertical, length, max width, depth offset toward the back, fold depth)
    (0.0, 0.195, 0.078, 0.000, 0.016),
    (25.0, 0.172, 0.070, 0.009, 0.014),
    (-25.0, 0.172, 0.070, 0.009, 0.014),
    (52.0, 0.130, 0.064, 0.018, 0.012),
    (-52.0, 0.130, 0.064, 0.018, 0.012),
]
WIDEST_AT = 0.52          # where along the blade it is widest (0 = bottom tip, 1 = top)
SHEET = 0.0022            # blade metal thickness
PIVOT_Z = 0.040           # blades fan out from here (just above the ball centre)
BALL_R = 0.021
BALL_Z = 0.030            # ball centre
COLLAR = (0.013, 0.012)   # radius, height (sits on the kiosk)
BLADE_COLOR = "#a9a9a6"   # satin pewter-silver
BALL_COLOR = "#b49a66"    # warmer satin metal

META = {
    "id": "bl_dir_finial",
    "class": "small_fixture",
    "tex": 512,          # seen from 1.5 m+ on top of the kiosk
    "ao": 0.45,
    "refs": [
        ["refs/new/directory/IMG_4408_t050_020.jpg", [0.38, 0.21, 0.62, 0.33], "IMG_4408 t050_020"],
        ["refs/new/directory/IMG_4408_t050_027.jpg", [0.38, 0.21, 0.62, 0.33], "IMG_4408 t050_027"],
    ],
}


def blade(name, ang, length, width, back, fold, mat):
    import bmesh
    from mathutils import Matrix
    bm = bmesh.new()
    # in the blade's own frame: u across (x), v along (z), ridge pushed to -y (front)
    w = width / 2
    v_w = length * WIDEST_AT
    b = bm.verts.new((0, 0, 0))
    l = bm.verts.new((-w, 0, v_w))
    t = bm.verts.new((0, 0, length))
    r = bm.verts.new((w, 0, v_w))
    # the fold: the ridge from tip to tip stands forward; a mid ridge point keeps the facets planar-ish
    m = bm.verts.new((0, -fold, v_w))
    for f in ((b, m, l), (l, m, t), (b, r, m), (r, t, m)):
        bm.faces.new(f)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    ob = core.obj_from_bmesh(name, bm, mat)
    core.solidify(ob, SHEET, 1.0)
    core.bevel(ob, 0.0006, 1, angle=25)
    ob.location = (0, back, PIVOT_Z)
    ob.rotation_euler = (0, math.radians(ang), 0)
    return ob


def build():
    mb = mats.brushed_metal("blade", BLADE_COLOR, 0.32, along="Z", metal=0.6)
    mball = mats.brushed_metal("ball", BALL_COLOR, 0.28, along="Z")
    for i, (a, L, W, back, fold) in enumerate(BLADES):
        blade("blade%d" % i, a, L, W, back, fold, mb)
    parts.sphere("ball", BALL_R, 20, 10, loc=(0, 0, BALL_Z), mat=mball, scale=(1, 1, 0.92))
    parts.lathe("collar", [(0, 0), (COLLAR[0], 0), (COLLAR[0], COLLAR[1] * 0.4), (COLLAR[0] * 0.8, COLLAR[1]), (0, COLLAR[1])],
                seg=20, mat=mball, cap=False)
