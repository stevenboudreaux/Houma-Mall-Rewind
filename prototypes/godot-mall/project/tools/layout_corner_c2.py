"""ws/corner-2026, Nov 4 2026 (design/corner-2026-c2.md): the Shoe Dept. court's south-east
corner, the same shell in both years. APPLIED Nov 4 after Steven's yes (layout_mall.json,
data/eras_2026.json, posters.gd as committed); safe to run again. After it: rebuild
layout_2026.json and the wings.

  python3 tools/layout_corner_c2.py            (from the project folder; idempotent)
  python3 tools/make_layout_2026.py
  then build wings 1-6 in both years (the stand-in slots change with the edges)

What it does (layout_mall.json, the shell both years share):
- The court bulges 4 m south in front of Franks again: a floor patch x 2..12, z 6..10 (a
  leftover: flat lay-in ceiling at the lane height, as IMG_4435 shows over the Zales bays).
- Franks (s33) fronts the court at z = 10 from x 2 to 12 (10 m, as now), 6 m deep (z 10..16).
- Orange Julius (s34) keeps x 12..16 at z = 6 on the entrance hall (4 m) and gets its 4 m side
  on the court at x = 12, z 6..10 (a plain wall in 1995: no picture of it; Steven to say).
- The east hall's wall beside Franks is x = 2, z 10..16 (6 m); the two framed ads move with it.
- Walk grid: tiles x 2..12, z 6..10 open.
And data/eras_2026.json: Zales (s33) takes Franks + Orange Julius (tiles 149..155 x 103..107);
the separate 2026 "vacant s34" goes. make_layout_2026.py turns OJ's court side into Zales' third
front (CORNER_RETURN there).
Sources: the 2026 footage (IMG_4437 f001-f002, IMG_4435, IMG_4436, IMG_4432, IMG_4424,
refs/new/woolworth_corner IMG_4492 t026_001-005), the Courier's Mar 20 1994 Merchant List & Map
(57 Franks set back from the row 56-52, 56 Orange Julius on the corner), and the game's own 1995
2D map (index.html mall-data: s33 Franks 149,105 4x3 behind s34 Orange Julius 153,103 3x5).
"""
import json, os

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.join(HERE, "..")
P = os.path.join(PROJ, "layout_mall.json")
P26 = os.path.join(PROJ, "data", "eras_2026.json")
POST = os.path.join(HERE, "stores", "posters", "posters.gd")


def same(e, a, b):
    return [round(v, 2) for v in e["a"]] == a and [round(v, 2) for v in e["b"]] == b


def main():
    L = json.load(open(P))
    out = []
    for e in L["edges"]:
        if e.get("store") == "s33":
            e = dict(e, a=[2.0, 10.0], b=[12.0, 10.0], depth=6.0)
        if e["kind"] == "wall" and (same(e, [2.0, 6.0], [2.0, 16.0]) or same(e, [12.0, 6.0], [12.0, 10.0])
                                    or same(e, [2.0, 10.0], [2.0, 16.0])):
            continue
        out.append(e)
    out.append({"a": [2.0, 10.0], "b": [2.0, 16.0], "n": [-1, 0], "kind": "wall"})
    # OJ's court side: walkable floor on both sides in 1995 (OJ's walk-up front), so a collider
    out.append({"a": [12.0, 6.0], "b": [12.0, 10.0], "n": [-1, 0], "kind": "wall", "solid": True})
    L["edges"] = out
    lo = [r for r in L["leftovers"] if [float(v) for v in r] != [2.0, 6.0, 12.0, 10.0]]
    lo.append([2.0, 6.0, 12.0, 10.0])
    L["leftovers"] = lo
    W = [list(r) for r in L["walk"]]
    for ty in (103, 104):                 # z 6..10 (tz = z / 2 + 100)
        for tx in range(149, 154):        # x 2..12 (tx = x / 2 + 148)
            W[ty][tx] = "1"
    L["walk"] = ["".join(r) for r in W]
    json.dump(L, open(P, "w"), indent=1)

    S = json.load(open(P26))
    keep = []
    for s in S:
        if s["id"] == "s34":
            continue                      # Orange Julius' unit is Zales' in 2026 (three bays)
        if s["id"] == "s33":
            s.update(x=149, y=103, w=7, h=5)
            s["notes"] = ("Zales over Franks + Orange Julius (both stalls): bay C on the court (Franks' "
                          "front, z = 10), bay B on OJ's court side (x = 12), bay A on the entrance hall "
                          "(OJ's front). IMG_4437, IMG_4435-4436, IMG_4432; design/corner-2026-c2.md")
        keep.append(s)
    json.dump(keep, open(P26, "w"), indent=1, ensure_ascii=False)

    src = open(POST).read()
    old = '{"a": [2.0, 6.0], "b": [2.0, 16.0], "ads": [[0.27, "dippin_dots"], [0.73, "gumballs"]]}'
    new = '{"a": [2.0, 10.0], "b": [2.0, 16.0], "ads": [[0.28, "dippin_dots"], [0.72, "gumballs"]]}'
    if old in src:
        open(POST, "w").write(src.replace(old, new).replace("Franks' side wall on the east hall (10 m)",
                                                           "Franks' side wall on the east hall (6 m, z 10..16)"))
    print("corner C2 applied: edges", len(out), "leftovers", len(lo), "2026 units", len(keep))


if __name__ == "__main__":
    main()
