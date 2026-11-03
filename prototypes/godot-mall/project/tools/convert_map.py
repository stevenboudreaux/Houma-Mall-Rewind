"""Convert the game's mall-data (index.html) into a Godot build layout.

Reads the 1995 map from the live game file and writes layout_mall.json:
  - zones: halls and courts (hand-listed below, in map tiles) in metres
  - leftovers: walkable tiles not in a zone (flat ceiling, plain floor)
  - court_walls: what enters each court side (for the vault notches)
  - hall_ends: which hall ends are closed (arched end wall)
  - edges: every boundary between floor and not-floor, merged into runs and
    classified as storefront / wall / exit / entrance / restroom
  - stores: everything the builder needs per store
  - walk: the walkable grid for the player
Run: python3 tools/convert_map.py ../Houma-Mall-Rewind/index.html
"""
import json, re, sys, os

S = 2.0                # metres per map tile
OX, OY = 148.0, 100.0  # map tile that becomes world (0, 0)

# Zones in map tiles (inclusive). Halls carry an axis ('x' east-west, 'z'
# north-south); courts carry a style used for their ceilings.
ZONES = [
    dict(id="C1", type="court", style="sears", x0=140, y0=52, x1=151, y1=56, name="Sears court"),
    dict(id="H1a", type="hall", axis="x", x0=110, y0=52, x1=139, y1=56, name="Sears hall west"),
    dict(id="H1b", type="hall", axis="x", x0=152, y0=52, x1=165, y1=56, name="Sears hall east"),
    dict(id="H2", type="hall", axis="z", x0=143, y0=57, x1=148, y1=94, name="East hall north"),
    dict(id="C2", type="court", style="shoe", x0=143, y0=95, x1=153, y1=104, name="Shoe Dept. court"),
    dict(id="H3", type="hall", axis="x", x0=154, y0=97, x1=165, y1=102, name="Main entrance hall"),
    dict(id="H4", type="hall", axis="z", x0=143, y0=105, x1=148, y1=123, name="East hall south"),
    dict(id="C3", type="court", style="dillards", x0=138, y0=124, x1=148, y1=136, name="Dillard's court"),
    dict(id="H8", type="hall", axis="z", x0=143, y0=137, x1=148, y1=139, name="Dillard's entry"),
    dict(id="H5", type="hall", axis="x", x0=80, y0=124, x1=137, y1=129, name="Concourse"),
    dict(id="C4", type="court", style="penney", x0=71, y0=122, x1=79, y1=133, name="JCPenney court"),
    dict(id="H6", type="hall", axis="z", x0=75, y0=134, x1=78, y1=143, name="South exit hall"),
    dict(id="H7", type="hall", axis="z", x0=123, y0=130, x1=123, y1=147, name="Restroom hall", narrow=True),
]

# Display text and lettering style for signs whose data name is all caps.
SIGN_TEXT = {
    "JCPENNEY": "JCPenney", "DILLARD'S": "Dillard's", "SEARS": "Sears",
    "K&B": "K&B", "JW": "JW", "5-7-9": "5-7-9", "GENERAL NUTRITION CENTER": "GNC",
    "CLAIRE'S BOUTIQUES": "Claire's", "GREAT AMERICAN COOKIE CO": "Great American Cookie Co.",
    "T.J.'S ONE HOUR PHOTO": "T.J.'s 1 Hour Photo", "TERREBONNE GENERAL OUTREAC": "Terrebonne General",
    "B. DALTON BOOKSELLER": "B. Dalton Bookseller", "WICKS 'N' STICKS": "Wicks 'n' Sticks",
    "GOLD 'N' GIFTS UNLIMITED": "Gold 'n' Gifts", "LION'S SHARE RESTAURANT": "Lion's Share",
    "CHICK-FIL-A": "Chick-fil-A", "KAY-BEE TOYS": "Kay-Bee Toys", "MILLER'S OUTPOST": "Miller's Outpost",
    "SOUTHLAND CINEMA": "Southland Cinema", "ATHLETE'S FOOT": "Athlete's Foot",
    "KARMELKORN": "Karmelkorn", "MASTERCUTS": "MasterCuts", "RADIO SHACK": "Radio Shack",
    "REGIS HAIRSTYLISTS": "Regis Hairstylists", "BLOCKBUSTER MUSIC": "Blockbuster Music",
}
SERIF = {"GORDON'S JEWELERS", "MITCHELL'S FORMAL WEAR", "ZALES", "WOOLWORTH", "COACH HOUSE GIFTS",
         "LERNER SHOP", "B. DALTON BOOKSELLER", "GOLDEN CHAIN GANG", "SAADI'S", "DILLARD'S",
         "AMERICAN BANK", "WESLEY AUSTIN", "GOLD 'N' GIFTS UNLIMITED", "NATURALIZER"}
SCRIPT = {"CLAIRE'S BOUTIQUES", "JEAN NICOLE", "ORANGE JULIUS", "THE AVENUE", "AFTERTHOUGHTS",
          "CONCEPTS", "COUNTRY FAIR", "WICKS 'N' STICKS", "LANE BRYANT"}


def title(n):
    if n.upper() in SIGN_TEXT:
        return SIGN_TEXT[n.upper()]
    small = {"of", "and", "the", "'n'", "&"}
    out = []
    for i, w in enumerate(n.lower().split(" ")):
        if w in small and i > 0:
            out.append(w if w != "&" else "&")
        else:
            out.append(w[:1].upper() + w[1:])
    return " ".join(out)


def wx(tx):
    return (tx - OX) * S


def wz(ty):
    return (ty - OY) * S


def main(src, out):
    s = open(src, encoding="utf-8").read()
    d = json.loads(re.search(r'<script[^>]*id="mall-data"[^>]*>(.*?)</script>', s, re.S).group(1))
    rows = d["floor"]
    H, W = len(rows), len(rows[0])
    walk = lambda x, y: 0 <= y < H and 0 <= x < W and rows[y][x] == "1"
    stores = d["stores"]

    owner = {}
    for i, st in enumerate(stores):
        for y in range(st["y"], st["y"] + st["h"]):
            for x in range(st["x"], st["x"] + st["w"]):
                owner.setdefault((x, y), i)

    zone_of = {}
    for z in ZONES:
        for y in range(z["y0"], z["y1"] + 1):
            for x in range(z["x0"], z["x1"] + 1):
                assert walk(x, y), f"zone {z['id']} covers non-floor tile {x},{y}"
                assert (x, y) not in zone_of, f"zones overlap at {x},{y}"
                zone_of[(x, y)] = z["id"]
    zmap = {z["id"]: z for z in ZONES}

    # ---- zones in metres
    zones_out = []
    for z in ZONES:
        r = [wx(z["x0"]), wz(z["y0"]), wx(z["x1"] + 1), wz(z["y1"] + 1)]
        o = dict(id=z["id"], type=z["type"], name=z["name"], rect=r)
        if z["type"] == "hall":
            o["axis"] = z["axis"]
            width = (r[3] - r[1]) if z["axis"] == "x" else (r[2] - r[0])
            o["width"] = width
            o["vault_half"] = 0 if z.get("narrow") or width < 6 else width * 0.25
        else:
            o["style"] = z["style"]
        zones_out.append(o)

    # ---- leftover floor tiles: merge row runs, then stack equal runs vertically
    runs = []
    for y in range(H):
        x = 0
        while x < W:
            if walk(x, y) and (x, y) not in zone_of:
                x0 = x
                while x < W and walk(x, y) and (x, y) not in zone_of:
                    x += 1
                runs.append([x0, y, x - 1, y])
            else:
                x += 1
    merged = []
    for r in runs:
        for m in merged:
            if m[0] == r[0] and m[2] == r[2] and m[3] == r[1] - 1:
                m[3] = r[1]
                break
        else:
            merged.append(r)
    leftovers = [[wx(a), wz(b), wx(c + 1), wz(e + 1)] for a, b, c, e in merged]

    # ---- court sides: which hall vaults enter
    court_walls = []
    for z in ZONES:
        if z["type"] != "court":
            continue
        sides = {
            "n": [(x, z["y0"] - 1) for x in range(z["x0"], z["x1"] + 1)],
            "s": [(x, z["y1"] + 1) for x in range(z["x0"], z["x1"] + 1)],
            "w": [(z["x0"] - 1, y) for y in range(z["y0"], z["y1"] + 1)],
            "e": [(z["x1"] + 1, y) for y in range(z["y0"], z["y1"] + 1)],
        }
        for side, tiles in sides.items():
            ent = set()
            for t in tiles:
                zid = zone_of.get(t)
                if zid and zmap[zid]["type"] == "hall":
                    hz = zmap[zid]
                    perp = (side in "ns" and hz["axis"] == "z") or (side in "we" and hz["axis"] == "x")
                    if perp:
                        ent.add(zid)
            court_walls.append(dict(zone=z["id"], side=side, halls=sorted(ent)))

    # ---- hall ends
    hall_ends = []
    for z in ZONES:
        if z["type"] != "hall":
            continue
        if z["axis"] == "x":
            ends = {"lo": [(z["x0"] - 1, y) for y in range(z["y0"], z["y1"] + 1)],
                    "hi": [(z["x1"] + 1, y) for y in range(z["y0"], z["y1"] + 1)]}
        else:
            ends = {"lo": [(x, z["y0"] - 1) for x in range(z["x0"], z["x1"] + 1)],
                    "hi": [(x, z["y1"] + 1) for x in range(z["x0"], z["x1"] + 1)]}
        for k, tiles in ends.items():
            open_ = any(zone_of.get(t) for t in tiles)
            hall_ends.append(dict(zone=z["id"], end=k, closed=not open_))

    # ---- boundary edges
    DIRS = {"N": (0, -1), "S": (0, 1), "W": (-1, 0), "E": (1, 0)}
    OPP = {"N": "S", "S": "N", "W": "E", "E": "W"}
    raw = []  # (dir_from_walk, line_key, pos, owner_key)
    for y in range(H):
        for x in range(W):
            if not walk(x, y):
                continue
            for dname, (dx, dy) in DIRS.items():
                nx, ny = x + dx, y + dy
                if walk(nx, ny):
                    continue
                si = owner.get((nx, ny))
                kind, key = "wall", None
                if si is not None:
                    st = stores[si]
                    face = OPP[dname]  # store faces back toward the walk tile
                    nm = st["name"]
                    if st.get("face") == face or st.get("face2") == face:
                        if nm == "MAIN ENTRANCE":
                            kind = "entrance"
                        elif nm == "EXIT":
                            kind = "exit"
                        elif nm in ("MEN", "WOMEN"):
                            kind = "restroom"
                        else:
                            kind = "store"
                        key = si
                raw.append((dname, x, y, kind, key))
    # merge along lines
    edges = []
    groups = {}
    for dname, x, y, kind, key in raw:
        if dname in "NS":
            line = (dname, y)
            pos = x
        else:
            line = (dname, x)
            pos = y
        groups.setdefault((line, kind, key), []).append(pos)
    for (line, kind, key), ps in groups.items():
        ps.sort()
        start = prev = ps[0]
        for p in ps[1:] + [None]:
            if p is not None and p == prev + 1:
                prev = p
                continue
            dname, c = line
            # segment from tile 'start' to tile 'prev' on this line
            if dname == "N":
                a, b, n = [wx(start), wz(c)], [wx(prev + 1), wz(c)], [0, 1]
            elif dname == "S":
                a, b, n = [wx(start), wz(c + 1)], [wx(prev + 1), wz(c + 1)], [0, -1]
            elif dname == "W":
                a, b, n = [wx(c), wz(start)], [wx(c), wz(prev + 1)], [1, 0]
            else:
                a, b, n = [wx(c + 1), wz(start)], [wx(c + 1), wz(prev + 1)], [-1, 0]
            e = dict(a=a, b=b, n=n, kind=kind)
            if key is not None:
                st = stores[key]
                e["store"] = st["id"]
                # depth of the store behind this frontage, in metres
                if dname in "NS":
                    e["depth"] = st["h"] * S
                else:
                    e["depth"] = st["w"] * S
            edges.append(e)
            if p is not None:
                start = prev = p

    # ---- stores
    stores_out = {}
    for st in stores:
        nm = st["name"]
        disp = st.get("sign") or nm
        disp = disp.replace("\n", " ").strip()
        if not disp and st.get("vacant"):
            disp = ""
        font = "serif" if nm in SERIF else "script" if nm in SCRIPT else "sans"
        stores_out[st["id"]] = dict(
            name=nm, sign=title(disp) if disp else disp,
            bg=st.get("signBg", "#333333"), fg=st.get("signFg", "#ffffff"),
            merch=st.get("merch") or ["#cccccc"], anchor=bool(st.get("anchor")),
            vacant=bool(st.get("vacant")), unit=st.get("unit"), open=bool(st.get("open")),
            awning=bool(st.get("awning")), awningColor=st.get("awningColor"),
            entry=st.get("entry"), plain=bool(st.get("plain")), noSign=bool(st.get("noSign")),
            carpet=st.get("carpet"), font=font, has_front_image=bool(st.get("front")),
        )

    # ---- hall skylights (map props "skylight"): only those inside a hall zone
    skylights = []
    for pr in d.get("props", []):
        if pr.get("t") != "skylight":
            continue
        zid = zone_of.get((pr["x"], pr["y"]))
        if not zid or zmap[zid]["type"] != "hall":
            continue
        hz = zmap[zid]
        along = wz(pr["y"] + 0.5) if hz["axis"] == "z" else wx(pr["x"] + 0.5)
        skylights.append(dict(zone=zid, at=along))

    walk_rows = ["".join("1" if walk(x, y) else "0" for x in range(W)) for y in range(H)]
    out_d = dict(scale=S, origin=[OX, OY], zones=zones_out, leftovers=leftovers,
                 court_walls=court_walls, hall_ends=hall_ends, edges=edges, stores=stores_out,
                 walk=walk_rows, era=d.get("era"), skylights=skylights)
    json.dump(out_d, open(out, "w"), indent=1)
    kinds = {}
    for e in edges:
        kinds[e["kind"]] = kinds.get(e["kind"], 0) + 1
    fronted = {e["store"] for e in edges if e.get("store")}
    missing = [st["name"] for st in stores if st["id"] not in fronted and st.get("face") != "none"]
    print("zones", len(zones_out), "leftover rects", len(leftovers), "edges", len(edges), kinds)
    print("stores with a frontage:", len(fronted), "of", len(stores), "; missing:", missing)
    print("hall skylights:", len(skylights))
    print("closed hall ends:", [(h["zone"], h["end"]) for h in hall_ends if h["closed"]])
    print("court sides with halls:", [(c["zone"], c["side"], c["halls"]) for c in court_walls if c["halls"]])


if __name__ == "__main__":
    src = sys.argv[1] if len(sys.argv) > 1 else "../Houma-Mall-Rewind/index.html"
    main(src, os.path.join(os.path.dirname(__file__), "..", "layout_mall.json"))
