"""UPFRONT (Nov 14 2026, scripts/wing_stream.gd, design/godot-wings.md "Everything up front"): a visitor who just walks.

The Nov 13 walk test (stream_walk_webtest.py) placed the player a few metres before each border and waited for the
wing beyond to be in before walking: it checks a crossing once the wing is in, not a walk. On the Nov 14 preview a
real visitor met borders that were not ready. This test does what a visitor does on a computer:

  the page's own address (no stream= or upfront= in it; only ?qa=1 for the test's hooks, and ?year=2026), the
  computer's pack (whatever the page picks for this browser), the usual warm-up;
  the moment the load screen lifts, forward is held and never let go;
  the player walks at walking speed from where the game starts: across the seam into wing 2, into Dillard's and
  back out, back across the seam, down the hall into Sears / Lynn's and back out, then to Corn Dog 7.

The route is found on the walk grids in gen/ (a path of 2 m cells); the game only turns the player toward the next
waypoint each frame (?qa=1, window.__mallWalk). The player is never placed anywhere and no wing's state is waited for.

It fails if: the load screen shows again or the page loads again; an "Enter ..." prompt shows (a border asking for
the old load); the old crossing's fade starts; the player stops for a second within 3 m of a border line, or for 4 s
anywhere; a page error; the route's stops (wing 2, Dillard's, Sears / Lynn's, Corn Dog 7) are not all reached.

Usage: python3 stream_natural_walk_webtest.py <url-path> <out-prefix> [year]   (serve the build folder on :8765;
run from the project folder, for gen/). Env: WALK_S (the longest the walk may take, seconds, default 7200), VIEW
(the page's size, default 640x360).
Prints NATURAL WALK OK, or the failures.
"""
import heapq, json, math, os, sys, time
from playwright.sync_api import sync_playwright

path, out = sys.argv[1], sys.argv[2]
YEAR = sys.argv[3] if len(sys.argv) > 3 else "1995"
WALK_S = float(os.environ.get("WALK_S", "7200"))
VIEW = [int(v) for v in os.environ.get("VIEW", "640x360").split("x")]   # a small picture: the test box draws in software
SHOT = int(os.environ.get("SHOT_TIMEOUT", "180000"))
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist", "--enable-precise-memory-info"]
Y = "y26" if YEAR == "2026" else ""
OX, OZ, CELL = 148.0, 100.0, 2.0          # scripts/wing_stream.gd _on_grid

# ---- the route, on the wings' own walk grids
rows = None
obst = []
for w in (1, 2, 4, 5):
    wj = json.load(open(f"gen/w{w}{Y}/wing.json"))
    r = wj["walk"]
    rows = [list(x) for x in r] if rows is None else [[("1" if a == "1" or b == "1" else "0") for a, b in zip(ra, rb)] for ra, rb in zip(rows, r)]
    cj = json.load(open(f"gen/w{w}{Y}/collide.json"))
    obst += cj.get("static", [])
    if w == 1:
        SPAWN = wj["spawn"]
H, W = len(rows), len(rows[0])


def cell(x, z):
    return int(math.floor(x / CELL + OX)), int(math.floor(z / CELL + OZ))


def centre(tx, ty):
    return ((tx - OX + 0.5) * CELL, (ty - OZ + 0.5) * CELL)


def blocked(tx, ty):
    if not (0 <= ty < H and 0 <= tx < W) or rows[ty][tx] != "1":
        return True
    x, z = centre(tx, ty)
    for o in obst:
        if len(o) == 3 and not isinstance(o[0], str):
            if math.hypot(x - o[0], z - o[1]) < o[2] + 1.2:
                return True
        elif o[0] == "rect" and o[1] - 1.0 < x < o[3] + 1.0 and o[2] - 1.0 < z < o[4] + 1.0:
            return True
    return False


free = [[not blocked(tx, ty) for tx in range(W)] for ty in range(H)]
# a cell with a wall beside it costs more: the path keeps to the middle of the halls
edge = [[free[ty][tx] and any(not (0 <= ty + dy < H and 0 <= tx + dx < W and free[ty + dy][tx + dx]) for dx in (-1, 0, 1) for dy in (-1, 0, 1)) for tx in range(W)] for ty in range(H)]


def nearest_free(x, z):
    tx, ty = cell(x, z)
    best = None
    for r in range(0, 6):
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                a, b = tx + dx, ty + dy
                if 0 <= b < H and 0 <= a < W and free[b][a] and not edge[b][a]:
                    d = math.hypot(dx, dy)
                    if best is None or d < best[0]:
                        best = (d, a, b)
        if best:
            return best[1], best[2]
    raise SystemExit(f"no walkable cell near ({x}, {z})")


def astar(a, b):
    pq = [(0.0, a)]; g = {a: 0.0}; came = {}
    while pq:
        _, c = heapq.heappop(pq)
        if c == b:
            out = [c]
            while c in came:
                c = came[c]; out.append(c)
            return out[::-1]
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                if not (dx or dy):
                    continue
                n = (c[0] + dx, c[1] + dy)
                if not (0 <= n[1] < H and 0 <= n[0] < W) or not free[n[1]][n[0]]:
                    continue
                if dx and dy and not (free[c[1]][n[0]] and free[n[1]][c[0]]):
                    continue      # no cutting a corner
                cost = g[c] + math.hypot(dx, dy) * (4.0 if edge[n[1]][n[0]] else 1.0)
                if cost < g.get(n, 1e18):
                    g[n] = cost; came[n] = c
                    heapq.heappush(pq, (cost + math.hypot(n[0] - b[0], n[1] - b[1]), n))
    raise SystemExit(f"no way from {centre(*a)} to {centre(*b)} on the walk grids")


# [x, z, what, the home wing the player must be in there (0: any)]
STOPS = [
    (-9.0, 58.0, "wing 2, past the seam", 2),
    (-4.0, 90.0, "inside Dillard's", 5),
    (-9.0, 58.0, "back in the Dillard's court", 2),
    (-9.0, 38.0, "back in wing 1, past the seam", 1),
    (-4.0, -104.0, "inside Sears / Lynn's", 4),
    (-4.0, -88.0, "back in wing 1", 1),
    (-97.6, 54.5, "Corn Dog 7", 2),
]
legs = []
at = nearest_free(SPAWN[0], SPAWN[1])
total_m = 0.0
for (x, z, what, home) in STOPS:
    to = nearest_free(x, z)
    cells = astar(at, to)
    pts = [list(centre(*c)) for c in cells[1:]]
    total_m += sum(math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]) for i in range(1, len(pts)))
    legs.append((pts, what, home))
    at = to
print(f"route: {len(legs)} legs, about {total_m:.0f} m from the start at ({SPAWN[0]}, {SPAWN[1]})", flush=True)

fails = []


def rss_mb():
    tot = 0
    for pid in os.listdir("/proc"):
        if not pid.isdigit():
            continue
        try:
            cmd = open(f"/proc/{pid}/cmdline", "rb").read()
            if b"chrom" not in cmd and b"headless_shell" not in cmd:
                continue
            for ln in open(f"/proc/{pid}/status"):
                if ln.startswith("VmRSS:"):
                    tot += int(ln.split()[1])
        except Exception:
            pass
    return round(tot / 1024)


with sync_playwright() as p:
    exe = os.environ.get("CHROMIUM") or ("/opt/pw-browsers/chromium" if os.path.exists("/opt/pw-browsers/chromium") else None)   # a box's pre-installed Chromium
    b = p.chromium.launch(args=ARGS, executable_path=exe) if exe else p.chromium.launch(args=ARGS)
    ctx = b.new_context(viewport={"width": VIEW[0], "height": VIEW[1]})
    pg = ctx.new_page()
    logs, errors, navs = [], [], []
    pg.on("console", lambda m: logs.append(f"[{m.type}] {m.text}"))
    pg.on("pageerror", lambda e: errors.append(str(e)))
    pg.on("load", lambda _p: navs.append(pg.url))
    sep = "&" if "?" in path else "?"
    q = "qa=1" + ("&year=2026" if YEAR == "2026" else "")
    t0 = time.time()
    pg.goto(f"http://127.0.0.1:8765/{path}{sep}{q}", timeout=180000)
    bar = []
    while time.time() - t0 < 5400:
        if pg.evaluate("!document.getElementById('status')"):
            break
        w = pg.evaluate("(document.getElementById('load-bar') || {style: {}}).style.width || ''")
        if not bar or bar[-1] != w:
            bar.append(w)
        pg.wait_for_timeout(1000)
    else:
        fails.append("the load screen did not lift in 5400 s")
    control_s = round(time.time() - t0, 1)
    # ---- the walk starts now: forward goes down and stays down
    pg.evaluate("""() => { window.__sawStatus = false; const f = () => { if (document.getElementById('status')) { window.__sawStatus = true; } requestAnimationFrame(f); }; requestAnimationFrame(f); }""")
    navs0 = len(navs)
    pg.focus("#canvas")
    pg.keyboard.down("w")
    st0 = pg.evaluate("window.__mallStreamState || {}")
    pack = pg.evaluate("window.__mallPack")
    print(json.dumps({"control_s": control_s, "pack": pack, "at_lift": {"home": st0.get("home"), "wings": st0.get("wings"), "peopled": st0.get("peopled"), "upfront": st0.get("upfront")},
                      "bar": bar[:3] + ["..."] + bar[-3:] if len(bar) > 6 else bar}), flush=True)
    if pack != "desktop":
        fails.append(f"the page picked the {pack} pack")
    pg.screenshot(path=f"{out}-lift.png", timeout=SHOT)
    peak = rss_mb()
    t1 = time.time()
    reached = []
    for i, (pts, what, home) in enumerate(legs):
        if fails:
            break
        pg.evaluate(f"window.__mallWalk = {json.dumps(pts)}")
        pg.wait_for_timeout(300)
        while True:
            left = pg.evaluate("window.__mallWalkLeft")
            log = pg.evaluate("window.__mallWalkLog || {}")
            for k in ("held", "prompt", "leaving", "stuck"):
                if k in log:
                    fails.append(f"on the way to {what}: {log[k]}")
            if pg.evaluate("!!window.__sawStatus"):
                fails.append(f"on the way to {what}: the load screen came back")
            if len(navs) != navs0:
                fails.append(f"on the way to {what}: the page loaded again: {navs[navs0:]}")
            if errors:
                fails.append(f"page errors: {errors[:3]}")
            if fails or left == 0:
                break
            if time.time() - t1 > WALK_S:
                fails.append(f"on the way to {what}: the walk took more than {WALK_S:.0f} s (at {pg.evaluate('window.__mallPos || null')}, {left} waypoints left)")
                break
            pg.wait_for_timeout(500)
        peak = max(peak, rss_mb())
        pos = pg.evaluate("window.__mallPos || null")
        st = pg.evaluate("window.__mallStreamState || {}")
        if not fails:
            if home and st.get("home") != home:
                # the handoff comes a metre past the line: give it the moment a walking visitor would
                pg.wait_for_timeout(1500)
                st = pg.evaluate("window.__mallStreamState || {}")
            if home and st.get("home") != home:
                fails.append(f"{what}: reached, but the home wing is {st.get('home')}, not {home} (at {pos})")
            reached.append(what)
            print(json.dumps({"reached": what, "after_s": round(time.time() - t1), "pos": pos, "home": st.get("home"), "rss_mb": rss_mb()}), flush=True)
            if i in (1, 4, 6):
                pg.screenshot(path=f"{out}-stop{i}.png", timeout=SHOT)
    pg.keyboard.up("w")
    walk_s = round(time.time() - t1)
    st = pg.evaluate("window.__mallStreamState || {}")
    print(json.dumps({"year": YEAR, "pack": pack, "control_s": control_s, "walk_s": walk_s, "route_m": round(total_m), "reached": reached,
                      "wings_in_at_end": [st.get("home")] + sorted(int(k) for k, v in (st.get("wings") or {}).items() if v == "in"),
                      "peak_rss_mb": peak, "page_ms": pg.evaluate("window.__mallStreamMs || {}"), "stats": st.get("stats")}, indent=1))
    open(f"{out}-console.log", "w").write("\n".join(logs))
    b.close()

print("page errors:", len(errors), errors[:3])
if fails:
    print("NATURAL WALK FAILED (%s):" % YEAR)
    for f in dict.fromkeys(fails):
        print("  FAIL", f)
    sys.exit(1)
print("NATURAL WALK OK (%s): the load screen lifted after %.0f s; %d m walked in %d s with forward held; no load screen, no prompt, no stop at a border" % (YEAR, control_s, round(total_m), walk_s))
