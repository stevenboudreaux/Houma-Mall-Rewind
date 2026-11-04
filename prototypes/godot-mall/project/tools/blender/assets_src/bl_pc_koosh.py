"""A rubber-strand ball (Koosh-type), a Pocket Change ticket prize (1995 map; workstream PRIZES, Steven Nov 3
2026). Hand item, 150-300 tickets (design/research/redemption-items.md T3; the type launched 1987).
Generic, no name or tag. About 7 cm across: a small core with a few hundred soft rubber filaments, each
tipped a little darker; colours in four sectors (pink, cyan, lime, yellow), as the multicolour ones were.
Filaments are thin three-sided cones, 900 of them, thick at the root, so the ball reads dense and soft. Origin: bottom
centre.
"""
import math
from lib import core, parts, mats

R_OUT = 0.035
R_CORE = 0.010
N = 900
COLS = ["#ff3c96", "#3cdcff", "#9cff3c", "#ffdc28"]

META = {
    "id": "bl_pc_koosh",
    "class": "hand",
    "tex": 512,
    "ao": 0.5,
    "refs": [],
    "item": {"name": "Rubber-strand ball", "year": 1995, "store": "POCKET CHANGE", "tickets": 250, "prize": "koosh"},
}


def build():
    import bmesh, bpy
    ms = [mats.M("strand%d" % i, c, 0.55).mat for i, c in enumerate(COLS)]
    parts.sphere("core", R_CORE, 12, 6, loc=(0, 0, R_OUT), mat=ms[0])
    golden = math.pi * (3 - math.sqrt(5))
    groups = [[] for _ in COLS]
    for i in range(N):
        z = 1 - 2 * (i + 0.5) / N
        r = math.sqrt(1 - z * z)
        th = golden * i
        d = (math.cos(th) * r, math.sin(th) * r, z)
        k = (0 if d[0] >= 0 else 1) + (0 if d[1] >= 0 else 2)
        groups[k].append(d)
    for k, dirs in enumerate(groups):
        bm = bmesh.new()
        for d in dirs:
            L = R_OUT * (0.88 + 0.12 * (((len(dirs) * 37 + int(1000 * d[0])) % 100) / 100.0))
            base = [x * R_CORE * 0.8 for x in d]
            tip = [x * L for x in d]
            # a perpendicular frame
            up = (0, 0, 1) if abs(d[2]) < 0.9 else (1, 0, 0)
            ax = (d[1] * up[2] - d[2] * up[1], d[2] * up[0] - d[0] * up[2], d[0] * up[1] - d[1] * up[0])
            la = math.sqrt(sum(a * a for a in ax)); ax = tuple(a / la for a in ax)
            bx = (d[1] * ax[2] - d[2] * ax[1], d[2] * ax[0] - d[0] * ax[2], d[0] * ax[1] - d[1] * ax[0])
            w = 0.0021
            vs = []
            for j in range(3):
                a = j * math.tau / 3
                p = [base[q] + (ax[q] * math.cos(a) + bx[q] * math.sin(a)) * w for q in range(3)]
                vs.append(bm.verts.new((p[0], p[1], p[2] + R_OUT)))
            t = bm.verts.new((tip[0], tip[1], tip[2] + R_OUT))
            for j in range(3):
                bm.faces.new((vs[j], vs[(j + 1) % 3], t))
        ob = core.obj_from_bmesh("strands%d" % k, bm, ms[k], smooth=False)
