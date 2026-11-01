"""The comb and beak that make the script's C a chicken's head (the chain's 1990s mark), for
tools/stores/cfa/store.gd's letters(). Steven, Nov 1 2026: "as close as possible to the real
1995 mark ... quality over strict trademark caution, with discretion" (design/storefronts/
chick-fil-a.md). Drawn by hand onto the stand-in script C (tools/stores/small/cfa_letters.json,
Mr Dafoe, OFL): a three-lobed comb riding the top of the C's upper arc, and a short pointed beak
at the C's upper terminal. Same units as cfa_letters.json (metres at the json's scale, y up).
Writes cfa_comb.json: {"comb": {tris, loops}, "beak": {tris, loops}}.
  python3 tools/stores/cfa/make_comb.py   (from the project folder)
"""
import json, math, os
import numpy as np
import mapbox_earcut as earcut

HERE = os.path.dirname(os.path.abspath(__file__))
J = json.load(open(os.path.join(HERE, "..", "small", "cfa_letters.json")))
C = np.array(J["letters"][0]["loops"][0])


def ytop(x):
    m = C[np.abs(C[:, 0] - x) < 0.012]
    return float(m[:, 1].max())


def shape(pts):
    pts = [(round(x, 5), round(y, 5)) for x, y in pts]
    a = sum(pts[i][0] * pts[(i + 1) % len(pts)][1] - pts[(i + 1) % len(pts)][0] * pts[i][1] for i in range(len(pts)))
    if a < 0:
        pts = pts[::-1]      # outer loops counter-clockwise, as cfa_letters.json
    v = np.array(pts, dtype=np.float64)
    idx = earcut.triangulate_float64(v, np.array([len(pts)], dtype=np.uint32))
    return {"tris": [list(pts[i]) for i in idx], "loops": [[list(p) for p in pts]]}


# --- the comb: three round lobes, the middle one tallest, leaning back a little like the mark's
lobes = [(0.375, 0.040, 0.020), (0.448, 0.050, 0.036), (0.522, 0.040, 0.016)]   # x, radius, lift
x0, x1 = 0.34, 0.552
base = [(x, ytop(x) - 0.018) for x in np.linspace(x1, x0, 10)]
top = []
for k, (cx, r, lift) in enumerate(lobes):
    cy = ytop(cx) + lift
    a0 = math.radians(205 if k == 0 else 170)
    a1 = math.radians(-25 if k == len(lobes) - 1 else 10)
    for i in range(13):
        a = a0 + (a1 - a0) * i / 12
        top.append((cx + r * math.cos(a), cy + r * math.sin(a)))
comb = shape(base + top)

# --- the beak: a short point off the C's upper terminal, pointing forward (right) and down
tip = C[C[:, 0].argmax()]
beak = shape([(tip[0] - 0.035, tip[1] + 0.035), (tip[0] - 0.005, tip[1] + 0.04), (tip[0] + 0.075, tip[1] - 0.012),
              (tip[0] - 0.004, tip[1] - 0.034), (tip[0] - 0.035, tip[1] - 0.014)])

json.dump({"note": "comb and beak for the C of cfa_letters.json (make_comb.py)", "comb": comb, "beak": beak},
          open(os.path.join(HERE, "cfa_comb.json"), "w"))
print("wrote cfa_comb.json")
