"""Family SOFA-A: Lynn's Interiors stationary three-seat sofas (2026). One generator, one parameter set per
variant (bl_ly_sofa_<variant>.py). Inventory and the frames behind each variant: design/lynns/inventory.md
("SOFA-A"). Shared shapes and finishes: _lynns_common.py.

The parts (Blender axes: x across, -y front, z up; origin bottom centre):
  legs (tapered / turned / block) or a dressmaker skirt to the floor
  the base frame between the arms, its deck under the seat cushions
  two arms: track (square, padded), rolled (a round roll over a panel, flaring out), english (a low
    rolled arm set back), each running the full depth
  the back: loose (n back pillows leaning on a frame) or tight (one crowned upholstered back)
  n seat cushions with crowned tops, a rolled front edge and welts top and bottom
  throw pillows (patterned covers, pillow_mat) leaning on the back
Sizes from the frames against the 9 m column grid and the 0.7 m columns (design/lynns/inventory.md
"How sizes were measured"); a three-seat sofa reads 2.2-2.4 m long, 0.95-1.0 m deep, seat ~0.47 m.
"""
import math
from lib import core, parts, mats
import _lynns_common as C

DEFAULT = {
    "W": 2.28, "D": 0.98, "seat_h": 0.47, "back_h": 0.90,
    "arm": "track", "arm_w": 0.18, "arm_h": 0.62,
    "back": "loose", "n_seat": 3, "n_back": 3,
    "base": "legs", "leg": "tapered", "leg_h": 0.11,
    "welt": True, "cushion_h": 0.15,
    "fabric": ("chenille", "#c9c2b2"), "leg_wood": ("#5a3d2a", "#2e1d14"),
    "pillows": [],
}


def build(**kw):
    P = dict(DEFAULT)
    P.update(kw)
    W, D = P["W"], P["D"]
    aw, ah = P["arm_w"], P["arm_h"]
    kind, col = P["fabric"]
    fab = C.fabric("fabric", col, kind)
    fab_w = C.fabric("welt", C._shade(col, 0.9) if kind != "leather" else C._shade(col, 0.8), kind)
    lw = C.wood("legs", P["leg_wood"][0], P["leg_wood"][1], along="Z", ring_scale=10.0, rough=0.45)
    skirt = P["base"] == "skirt"
    leg_h = 0.0 if skirt else P["leg_h"]
    ch = P["cushion_h"]
    deck_z = P["seat_h"] - ch
    Wi = W - 2 * aw                      # between the arms
    back_d = 0.22 if P["back"] == "loose" else 0.26
    front_y = -D / 2

    # base frame (under the cushions and the arms)
    base_h = deck_z - leg_h
    C.soft_box("base", (W - 0.02, D - 0.02, base_h), r=0.03, res=(14, 6, 3), mat=fab, loc=(0, 0, leg_h + base_h / 2), bulge=0.004)
    # the back frame
    if P["back"] == "loose":
        bh = P["back_h"] - 0.13 - deck_z
        C.soft_box("backframe", (Wi + 0.02, back_d, bh), r=0.05, crown=0.01, res=(14, 5, 6), mat=fab,
                   loc=(0, D / 2 - back_d / 2, deck_z + bh / 2))
    else:
        bh = P["back_h"] - deck_z
        ob = C.soft_box("tightback", (Wi + 0.02, bh, back_d), r=0.06, crown=0.035, res=(16, 8, 5), mat=fab)
        ob.rotation_euler = (math.radians(90 - 8), 0, 0)
        ob.location = (0, D / 2 - back_d / 2 - 0.02, deck_z + bh / 2 - 0.01)
        if P["welt"]:
            # piping across the top front edge of the tight back
            y0 = D / 2 - back_d - 0.01
            pts = [(x, y0 + 0.03, P["back_h"] - 0.035) for x in (-Wi / 2, -Wi / 4, 0, Wi / 4, Wi / 2)]
            parts.tube_path("tb_welt", pts, 0.0045, seg=6, mat=fab_w)
    # arms
    for s in (-1, 1):
        x = s * (W / 2 - aw / 2)
        if P["arm"] == "track":
            h = ah - leg_h
            C.soft_box("arm", (aw, D, h), r=0.035, crown=0.006, res=(5, 12, 8), mat=fab, loc=(x, 0, leg_h + h / 2), bulge=0.004)
            if P["welt"]:
                for z in (ah - 0.012,):
                    pts = [(x - s * (aw / 2 - 0.012), front_y + 0.012, z - 0.02), (x - s * (aw / 2 - 0.012), front_y + 0.008, z),
                           (x, front_y + 0.002, z + 0.002), (x + s * (aw / 2 - 0.012), front_y + 0.008, z), (x + s * (aw / 2 - 0.012), front_y + 0.012, z - 0.02)]
                    parts.tube_path("arm_welt", pts, 0.004, seg=6, mat=fab_w)
        else:
            rr = 0.085 if P["arm"] == "rolled" else 0.065
            set_back = 0.0 if P["arm"] == "rolled" else 0.05
            ph = ah - leg_h - rr
            C.soft_box("armpanel", (aw * 0.8, D - set_back, ph), r=0.03, res=(4, 12, 7), mat=fab,
                       loc=(x - s * aw * 0.08, set_back / 2, leg_h + ph / 2), bulge=0.006)
            # the roll: nearly round in section, flaring a little outward past the panel
            C.soft_box("armroll", (aw + 0.04, D - set_back, 2 * rr), r=rr * 0.96, res=(8, 14, 8), mat=fab,
                       loc=(x + s * 0.02, set_back / 2, ah - rr))
            # the scroll face on the front of the roll (a pleated round panel)
            f = parts.cylinder("scroll", rr * 0.92, 0.012, verts=20, mat=fab_w, bev=0.003)
            f.rotation_euler = (math.radians(90), 0, 0)
            f.location = (x + s * 0.02, front_y + set_back - 0.002, ah - rr)
    # seat cushions
    n = P["n_seat"]
    cw = Wi / n
    cd = D - back_d - 0.01
    cy = front_y + cd / 2 - 0.015
    for i in range(n):
        x = -Wi / 2 + cw * (i + 0.5)
        C.soft_box("seat%d" % i, (cw - 0.006, cd, ch), r=0.04, crown=0.018, front_roll=0.012, sag=0.006, res=(10, 10, 4), mat=fab,
                   loc=(x, cy, deck_z + ch / 2), bulge=0.006)
        if P["welt"]:
            for z in (deck_z + ch - 0.012, deck_z + 0.012):
                C.welt("seatwelt", C.rrect_loop(x, cy, z, cw - 0.012, cd - 0.006, 0.028), 0.0042, fab_w)
    # back pillows
    if P["back"] == "loose":
        nb = P["n_back"]
        bw = Wi / nb
        bt = 0.20
        bhp = P["back_h"] - P["seat_h"] + 0.03
        for i in range(nb):
            x = -Wi / 2 + bw * (i + 0.5)
            ob = C.soft_box("backpillow%d" % i, (bw - 0.01, bhp, bt), r=0.07, crown=0.045, crown_bottom=0.02, res=(9, 9, 4), mat=fab, bulge=0.01)
            ob.rotation_euler = (math.radians(90 - 14), 0, 0)
            ob.location = (x, D / 2 - back_d - bt / 2 + 0.05, P["seat_h"] + bhp / 2 - 0.03)
            if P["welt"]:
                pass   # loose backs on the floor read as knife-edge pillows: no welt
    # throw pillows: [(kind, c1, c2, fabric_kind, size), ...] spread from the arms inward
    pl = P["pillows"]
    for i, spec in enumerate(pl):
        pk, c1, c2, fk, sz = spec
        m = C.pillow_mat("throw%d" % i, pk, c1, c2, fk)
        side = -1 if i % 2 == 0 else 1
        k = i // 2
        x = side * (Wi / 2 - sz / 2 - 0.04 - k * (sz * 0.8))
        y = D / 2 - back_d - 0.13 - k * 0.06
        C.pillow("throw%d" % i, sz, sz, 0.15, m, (x, y, P["seat_h"] + sz / 2 - 0.05 + k * 0.01), (18 - 4 * k, 0, side * (-10 + 6 * k)))
    # legs or skirt
    if skirt:
        sh = deck_z - 0.02
        for (sx, sy, w, d) in ((0, front_y - 0.004, W, 0.016), (0, D / 2 + 0.004, W, 0.016), (-W / 2 - 0.004, 0, 0.016, D), (W / 2 + 0.004, 0, 0.016, D)):
            C.soft_box("skirt", (w, d, sh * 0.62), r=0.007, res=(16 if w > 0.5 else 2, 2 if w > 0.5 else 12, 3), mat=fab_w,
                       loc=(sx, sy, 0.012 + sh * 0.31))
    else:
        for sx in (-1, 1):
            for sy in (-1, 1):
                loc = (sx * (W / 2 - 0.07), sy * (D / 2 - 0.07), 0)
                if P["leg"] == "turned":
                    C.leg_turned("leg", leg_h, 0.03, lw, loc)
                elif P["leg"] == "block":
                    C.leg_tapered("leg", leg_h, 0.034, 0.026, lw, loc, sq=True)
                else:
                    C.leg_tapered("leg", leg_h, 0.022, 0.013, lw, loc, splay=(sx * 6, -sy * 6))
