"""The 2026 layout: the same building as layout_mall.json (1995: zones, halls, edges' geometry,
leftovers, the Oct 7-8 corrections), with the store frontages relabelled to the tenants of
October 2026 (Steven's site visit, Oct 23 2026: data/eras_2026.json, which is mall-data's
eras["2026"] on the map-2026 branch).

Each 1995 store frontage is sampled every 0.25 m just inside the store; each sample takes the
2026 unit whose rect holds that tile. Runs of one unit become one frontage, so merged units
(Claire's over Gordon's + Claire's, Hypervelocity over K&B + MasterCuts + Father & Son) get one
front and split units (Neek & Co. out of K&B) get their own. Store interiors built in full 3D for
1995 are shut in the walk grid (the 2026 fronts are generic) except Corn Dog 7, which is still
there and unchanged.

  python3 tools/make_layout_2026.py   (from the project folder) -> layout_2026.json
"""
import json, math, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.join(HERE, "..")
sys.path.insert(0, HERE)
from convert_map import title, SERIF, SCRIPT  # noqa: E402

S = 2.0
L = json.load(open(os.path.join(PROJ, "layout_mall.json")))
OX, OY = L["origin"]
ST26 = json.load(open(os.path.join(PROJ, "data", "eras_2026.json")))
KEEP_OPEN = {"s54", "s52"}   # Corn Dog 7 (the same shop in 2026) and games, inc. (s52, built Oct 28): their interiors stay walkable
KEEP_OPEN |= {"s1", "s2"}    # workstream E (Nov 1): the old Sears box (Lynn's) and Dillard's level 1 are walkable in both years
KEEP_OPEN |= {"s64"}         # workstream G (Nov 1): Wicked Wingz (the 1995 Chick-fil-A unit), tools/stores/wingz/store.gd


def tile(x, z):
    return int(math.floor(x / S + OX)), int(math.floor(z / S + OY))


owner = {}
for i, st in enumerate(ST26):
    for y in range(st["y"], st["y"] + st["h"]):
        for x in range(st["x"], st["x"] + st["w"]):
            owner.setdefault((x, y), i)

edges = []
for e in L["edges"]:
    if e["kind"] != "store" or e["store"] == "cs1":
        if e["kind"] == "store":
            # the 1995 "Coming Soon" stall (narrow_stores.py): plain wall in 2026 too
            e = dict(e); e["kind"] = "wall"; e.pop("store", None); e.pop("depth", None)
        edges.append(e)
        continue
    a = e["a"]; b = e["b"]; n = e["n"]
    ln = math.hypot(b[0] - a[0], b[1] - a[1])
    tx = (b[0] - a[0]) / ln; tz = (b[1] - a[1]) / ln
    steps = max(1, int(round(ln / 0.25)))
    runs = []
    for k in range(steps):
        s = (k + 0.5) * ln / steps
        px = a[0] + tx * s - n[0] * 0.5
        pz = a[1] + tz * s - n[1] * 0.5
        o = owner.get(tile(px, pz))
        if runs and runs[-1][0] == o:
            runs[-1][2] = (k + 1) * ln / steps
        else:
            runs.append([o, k * ln / steps, (k + 1) * ln / steps])
    for o, s0, s1 in runs:
        ne = dict(a=[round(a[0] + tx * s0, 3), round(a[1] + tz * s0, 3)],
                  b=[round(a[0] + tx * s1, 3), round(a[1] + tz * s1, 3)], n=n)
        if o is None:
            ne["kind"] = "wall"
        else:
            st = ST26[o]
            ne["kind"] = {"MAIN ENTRANCE": "entrance", "EXIT": "exit", "EAST ENTRANCE": "exit"}.get(st["name"], "store")
            if st["name"] in ("MEN", "WOMEN"):
                ne["kind"] = "restroom"
            ne["store"] = st["id"]
            ne["depth"] = (st["h"] if n[0] == 0 else st["w"]) * S
        edges.append(ne)

# merge collinear neighbours of the same unit (two 1995 fronts now one shop)
merged = []
for e in edges:
    m = merged[-1] if merged else None
    if (m and e["kind"] == "store" and m["kind"] == "store" and m.get("store") == e.get("store")
            and m["n"] == e["n"] and abs(m["b"][0] - e["a"][0]) < 0.01 and abs(m["b"][1] - e["a"][1]) < 0.01):
        m["b"] = e["b"]
        continue
    merged.append(dict(e))
# a second pass for neighbours that were not adjacent in the list
changed = True
while changed:
    changed = False
    for i, p in enumerate(merged):
        if p["kind"] != "store":
            continue
        for j, q in enumerate(merged):
            if i == j or q["kind"] != "store" or q.get("store") != p.get("store") or q["n"] != p["n"]:
                continue
            if abs(p["b"][0] - q["a"][0]) < 0.01 and abs(p["b"][1] - q["a"][1]) < 0.01:
                # collinear?
                d1 = (p["b"][0] - p["a"][0], p["b"][1] - p["a"][1]); d2 = (q["b"][0] - q["a"][0], q["b"][1] - q["a"][1])
                if abs(d1[0] * d2[1] - d1[1] * d2[0]) < 1e-6:
                    p["b"] = q["b"]; merged.pop(j); changed = True
                    break
        if changed:
            break

# ws/corner-2026 (Nov 4 2026, design/corner-2026-c2.md): once tools/layout_corner_c2.py has put
# Orange Julius' 4 m court side (x = 12, z 6..10) into the shell as a 1995 wall, that side is Zales'
# third bay in 2026 (IMG_4437 f001, IMG_4436, IMG_4492 t026_001). Inert while the wall is absent.
CORNER_RETURN = ([12.0, 6.0], [12.0, 10.0])
ZALES3 = False
for e in merged:
    if e["kind"] == "wall" and [round(v, 2) for v in e["a"]] == CORNER_RETURN[0] and [round(v, 2) for v in e["b"]] == CORNER_RETURN[1]:
        o = owner.get(tile(e["a"][0] + 0.5, e["a"][1] + 0.5))
        if o is not None and ST26[o]["name"] == "ZALES":
            e["kind"] = "store"; e["store"] = ST26[o]["id"]; e["depth"] = 4.0
            ZALES3 = True

stores = {}
for st in ST26:
    nm = st["name"]
    disp = (st.get("sign") or nm).replace("\n", " ").strip()
    font = "serif" if nm in SERIF or nm in ("THE BILLIARD ROOM", "DJS JEWELERS", "FIRE HAUS 3.0", "LYNN'S INTERIORS") else \
        "script" if nm in SCRIPT or nm in ("RAINBOW", "CAKELICIOUS", "MAURICES", "RHEA LANA'S", "CLAIRE'S", "LOLA LABELLE BRIDAL") else "sans"
    stores[st["id"]] = dict(
        name=nm, sign=(title(disp) if disp.isupper() else disp) if disp else "",
        bg=st.get("signBg", "#333333"), fg=st.get("signFg", "#ffffff"),
        merch=st.get("merch") or ["#cccccc"], anchor=bool(st.get("anchor")),
        vacant=bool(st.get("vacant")), unit=st.get("unit"), open=bool(st.get("open")),
        awning=bool(st.get("awning")), awningColor=st.get("awningColor"),
        entry=st.get("entry"), plain=bool(st.get("plain")), noSign=bool(st.get("noSign")),
        carpet=st.get("carpet"), font=font, has_front_image=False)
if ZALES3:
    for st in ST26:
        if st["name"] == "ZALES":
            stores[st["id"]]["bays"] = 3     # fronts26/store.gd zales(): one bay per front
# the 1995 layout's own bookkeeping stores (exits, restrooms) the 2026 list may lack
for sid, sd in L["stores"].items():
    if sid not in stores and sd["name"] in ("MEN", "WOMEN", "EXIT", "MAIN ENTRANCE"):
        stores[sid] = sd

# walk grid: shut the 1995 walk-in interiors, except the shops that are still built in 2026
walk = [list(r) for r in L["walk"]]
ST95 = {}
src = os.path.join(PROJ, "..", "..", "..", "index.html")
import re  # noqa: E402
d95 = json.loads(re.search(r'<script[^>]*id="mall-data"[^>]*>(.*?)</script>', open(src, encoding="utf-8").read(), re.S).group(1))
for st in d95["stores"]:
    ST95[st["id"]] = st
shut = 0
# mall floor patches (leftovers) are never a shop's inside, whatever the 2D map's rect says
# (ws/corner-2026: the 2D map's Orange Julius rect, x 10..16, overlaps the court patch x 2..12)
FLOOR = set()
for r in L.get("leftovers", []):
    for ty in range(int(r[1] / S + OY), int(r[3] / S + OY)):
        for tx in range(int(r[0] / S + OX), int(r[2] / S + OX)):
            FLOOR.add((tx, ty))
for sid in L.get("interiors_open", []):
    if sid in KEEP_OPEN or sid not in ST95:
        continue
    st = ST95[sid]
    for y in range(st["y"], st["y"] + st["h"]):
        for x in range(st["x"], st["x"] + st["w"]):
            if walk[y][x] == "1" and (x, y) not in FLOOR:
                walk[y][x] = "0"; shut += 1

# workstream GI (Nov 2 2026): games, inc. (s52) is walked end to end in the footage, but Blockbuster
# Music (1995 s52) had no walk-in interior, so KEEP_OPEN alone never opened its tiles. Open its rect
# for 2026; its walls, counter and machines are obstacles (tools/stores/games_inc/store.gd).
OPEN_2026 = {"s52"}
for sid in OPEN_2026:
    st = ST95[sid]
    for y in range(st["y"], st["y"] + st["h"]):
        for x in range(st["x"], st["x"] + st["w"]):
            walk[y][x] = "1"

out = dict(L)
out["edges"] = merged
out["stores"] = stores
out["walk"] = ["".join(r) for r in walk]
out["era"] = "2026"
out["interiors_open"] = sorted(KEEP_OPEN)
json.dump(out, open(os.path.join(PROJ, "layout_2026.json"), "w"), indent=1)
kinds = {}
for e in merged:
    kinds[e["kind"]] = kinds.get(e["kind"], 0) + 1
named = sorted({stores[e["store"]]["name"] for e in merged if e.get("store") and stores[e["store"]]["name"]})
print("edges", len(merged), kinds, "; walk tiles shut", shut)
print("fronted 2026 tenants:", len(named))
print(", ".join(named))
