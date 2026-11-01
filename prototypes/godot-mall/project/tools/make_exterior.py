"""The mall's outside, from the 1995 map: tools/exterior/exterior.gd builds the exterior scene
(wing 3, "Outside") from what this writes to exterior.json.

  - segments: the building's outline, one run per (store, side), with the outward normal, in
    metres (+x east, +z south, the same frame as layout_mall.json)
  - roofs: the building's footprint as rectangles (one per run of map rows), for the roof slab
  - doors: every exterior door of the walkable mall (the exits and the main entrance), with the
    spot just outside it, the spot just inside it, the wing that spot is in and the facing
  - standalone: footprints of buildings on the map that do not touch the mall (n2, the
    nameless block west of the back lot: by Steven's account the original 1969 standalone Sears,
    Unitech in 2026)
  - walk: the wing's walkable grid (every map tile outside the building; the lot's obstacles
    come from the scene's collide.json)
Run: python3 tools/make_exterior.py ../../../index.html
"""
import json, os, re, sys
from collections import deque

# Workstream F (Nov 1 2026): the footprint's corrections (filled notches, Unitech's position,
# the Sears door spots for Workstream E), design/godot-exterior.md "Fake walls"
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "exterior"))
import wall_fixes as WF

S = 2.0
OX, OY = 148.0, 100.0


def wx(tx):
    return (tx - OX) * S


def wz(ty):
    return (ty - OY) * S


def main(src, out_path):
    s = open(src, encoding="utf-8").read()
    d = json.loads(re.search(r'<script[^>]*id="mall-data"[^>]*>(.*?)</script>', s, re.S).group(1))
    rows = d["floor"]
    H, W = len(rows), len(rows[0])
    stores = d["stores"]
    lay = json.load(open("layout_mall.json"))
    zone_of = {}
    for z in lay["zones"]:
        r = z["rect"]
        for ty in range(int(r[1] / S + OY), int(r[3] / S + OY)):
            for tx in range(int(r[0] / S + OX), int(r[2] / S + OX)):
                zone_of[(tx, ty)] = z["id"]
    wing2 = {"C3", "H8", "H5", "C4", "H6", "H7"}

    # ---- the mask: floor tiles and store rects, holes filled
    owner = {}
    solid = [[0] * W for _ in range(H)]
    for y in range(H):
        for x in range(W):
            if rows[y][x] == "1":
                solid[y][x] = 1
    for i, st in enumerate(stores):
        for y in range(st["y"], st["y"] + st["h"]):
            for x in range(st["x"], st["x"] + st["w"]):
                if 0 <= y < H and 0 <= x < W:
                    solid[y][x] = 1
                    owner.setdefault((x, y), i)
    # Workstream F: the filled notches (tools/exterior/wall_fixes.py FILLS)
    for fx in WF.FILLS:
        r = fx["rect"]
        si = None
        if fx["owner"]:
            si = [k for k, st in enumerate(stores) if st["id"] == fx["owner"]][0]
        else:
            stores.append(dict(id="fix_" + (fx["name"] or "wall").replace(" ", "_").lower(), name=fx["name"], x=0, y=0, w=0, h=0))
            si = len(stores) - 1
        for ty in range(int(r[1] / S + OY), int(r[3] / S + OY)):
            for tx in range(int(r[0] / S + OX), int(r[2] / S + OX)):
                solid[ty][tx] = 1
                owner.setdefault((tx, ty), si)
    # fill holes: anything not reachable from the map border is inside
    outside = [[0] * W for _ in range(H)]
    q = deque()
    for y in range(H):
        for x in range(W):
            if (y in (0, H - 1) or x in (0, W - 1)) and not solid[y][x]:
                outside[y][x] = 1
                q.append((x, y))
    while q:
        x, y = q.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < W and 0 <= ny < H and not solid[ny][nx] and not outside[ny][nx]:
                outside[ny][nx] = 1
                q.append((nx, ny))
    mask = [[0 if outside[y][x] else 1 for x in range(W)] for y in range(H)]
    # connected components of the mask: the biggest is the mall, the rest stand alone
    comp = [[-1] * W for _ in range(H)]
    comps = []
    for y in range(H):
        for x in range(W):
            if mask[y][x] and comp[y][x] < 0:
                k = len(comps)
                tiles = []
                q = deque([(x, y)])
                comp[y][x] = k
                while q:
                    cx, cy = q.popleft()
                    tiles.append((cx, cy))
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < W and 0 <= ny < H and mask[ny][nx] and comp[ny][nx] < 0:
                            comp[ny][nx] = k
                            q.append((nx, ny))
                comps.append(tiles)
    main_k = max(range(len(comps)), key=lambda k: len(comps[k]))
    standalone = []
    for k, tiles in enumerate(comps):
        if k == main_k:
            continue
        xs = [t[0] for t in tiles]; ys = [t[1] for t in tiles]
        nm = ""
        for t in tiles:
            if t in owner:
                nm = stores[owner[t]]["name"] or stores[owner[t]]["id"]
                break
        standalone.append(dict(name=nm, rect=[wx(min(xs)), wz(min(ys)), wx(max(xs) + 1), wz(max(ys) + 1)]))

    def inb(x, y):
        return 0 <= x < W and 0 <= y < H and comp[y][x] == main_k

    # ---- outline segments: each building tile side that faces outside
    DIRS = {"N": (0, -1), "S": (0, 1), "W": (-1, 0), "E": (1, 0)}
    raw = {}
    for y in range(H):
        for x in range(W):
            if not inb(x, y):
                continue
            for dn, (dx, dy) in DIRS.items():
                nx, ny = x + dx, y + dy
                if inb(nx, ny):
                    continue
                si = owner.get((x, y))
                zid = zone_of.get((x, y))
                if si is not None:
                    st = stores[si]
                    key = st["id"]; name = st["name"]
                else:
                    key = zid or "?"; name = zid or ""
                if dn in "NS":
                    line = ("h", y if dn == "N" else y + 1, dn)
                    raw.setdefault((line, key), []).append(x)
                else:
                    line = ("v", x if dn == "W" else x + 1, dn)
                    raw.setdefault((line, key), []).append(y)
    segments = []
    for (line, key), pos in raw.items():
        pos.sort()
        runs = []
        for p in pos:
            if runs and runs[-1][1] == p - 1:
                runs[-1][1] = p
            else:
                runs.append([p, p])
        kind, at, dn = line
        n = {"N": [0, -1], "S": [0, 1], "W": [-1, 0], "E": [1, 0]}[dn]
        nm = ""
        for st in stores:
            if st["id"] == key:
                nm = st["name"]
        for r0, r1 in runs:
            if kind == "h":
                a = [wx(r0), wz(at)]; b = [wx(r1 + 1), wz(at)]
            else:
                a = [wx(at), wz(r0)]; b = [wx(at), wz(r1 + 1)]
            segments.append(dict(a=a, b=b, n=n, side=dn, store=key, name=nm))
    # a stable order: by side, then position
    segments.sort(key=lambda g: (g["side"], g["a"][1], g["a"][0]))

    # ---- roof rectangles: merge runs of equal rows
    runs = []
    for y in range(H):
        x = 0
        while x < W:
            if inb(x, y):
                x0 = x
                while x < W and inb(x, y):
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
    roofs = [[wx(a), wz(b), wx(c + 1), wz(e + 1)] for a, b, c, e in merged]

    # ---- doors: the mall's exits and main entrance (layout edges), with the spots each side
    doors = []
    for e in lay["edges"]:
        if e["kind"] not in ("exit", "entrance"):
            continue
        a, b, n = e["a"], e["b"], e["n"]          # n points into the hall
        mid = [(a[0] + b[0]) * 0.5, (a[1] + b[1]) * 0.5]
        depth = float(e.get("depth", 4.0))
        # the exit's own tiles run `depth` out from the hall edge; outside begins past them
        out = [mid[0] - n[0] * (depth + 1.5), mid[1] - n[1] * (depth + 1.5)]
        inside = [mid[0] + n[0] * 1.5, mid[1] + n[1] * 1.5]
        # the hall tile just inside tells the wing
        tx, ty = int(inside[0] / S + OX), int(inside[1] / S + OY)
        zid = zone_of.get((tx, ty), "")
        w = 2 if zid in wing2 else 1
        # yaw (degrees) facing +n is the direction into the mall: yaw 90 looks -x, 180 looks +z
        import math
        yaw_in = math.degrees(math.atan2(-n[0], n[1])) if False else None
        # player.gd: forward = (-sin(yaw), 0, -cos(yaw)); solve for n
        yaw_in = math.degrees(math.atan2(-n[0], -n[1]))
        yaw_out = math.degrees(math.atan2(n[0], n[1]))
        doors.append(dict(store=e["store"], kind=e["kind"], a=a, b=b, n=n, mid=mid, width=abs(b[0] - a[0]) + abs(b[1] - a[1]),
                          depth=depth, wing=w, zone=zid, out=out, inside=inside, yaw_in=yaw_in, yaw_out=yaw_out))

    # ---- the walk grid: every map tile outside any building
    walk = []
    for y in range(H):
        walk.append("".join("0" if mask[y][x] else "1" for x in range(W)))
    # Workstream F: the map's standalone block n2 is not where the map puts it (west of JCPenney's
    # back lot: parking); Unitech stands north of Sears by Armour Dr (wall_fixes.STANDALONE)
    walk = [list(r) for r in walk]
    for k, tiles in enumerate(comps):
        if k != main_k:
            for (tx, ty) in tiles:
                walk[ty][tx] = "1"
    for sa in WF.STANDALONE:
        r = sa["rect"]
        for ty in range(int(r[1] / S + OY), int(r[3] / S + OY)):
            for tx in range(int(r[0] / S + OX), int(r[2] / S + OX)):
                walk[ty][tx] = "0"
    walk = ["".join(r) for r in walk]
    standalone = [dict(name=sa["name"], rect=sa["rect"]) for sa in WF.STANDALONE]

    xs = [t[0] for t in comps[main_k]]; ys = [t[1] for t in comps[main_k]]
    bounds = [wx(min(xs)), wz(min(ys)), wx(max(xs) + 1), wz(max(ys) + 1)]
    json.dump(dict(scale=S, origin=[OX, OY], bounds=bounds, map=[wx(0), wz(0), wx(W), wz(H)], segments=segments, roofs=roofs,
                   doors=doors, standalone=standalone, walk=walk,
                   bay=WF.BAY, door_spots=WF.DOOR_SPOTS), open(out_path, "w"), indent=1)
    print("segments", len(segments), "roofs", len(roofs), "doors", len(doors), "standalone", standalone, "bounds", bounds)
    for dr in doors:
        print(" door", dr["store"], dr["kind"], "wing", dr["wing"], dr["zone"], "out", dr["out"], "in", dr["inside"], "yaw_in", round(dr["yaw_in"]))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "../../../index.html", "exterior.json")
