"""Workstream WALK (design/godot-avatar.md "Third person", Nov 3 2026): third-person walking and
running speeds in the web build, headless Chromium (swiftshader).

Usage: python3 tools/qa/walk_webtest.py <url-path> <out-prefix> "<name>:x,z,yaw,pitch[=xmax:-46.5];..."
  (server on :8765 serving the repo root; <url-path> e.g.
   prototypes/godot-mall/project/.scratch/builds/wswalk/index.html?wing=2)
Each spot loads ?view=third&debug=1&warm=0&cam=... on a fresh profile (the default avatar, no
creator; warm=0: the NPC warm-up stands every skin in front of the camera for a few frames behind
the loading card, which on this 0.1-0.2 fps renderer runs on for minutes after the card lifts and
would put other bodies in the frames), then:
  - walks (W held) and runs (W + X held), reading the player's "DBG pos=" lines and the avatar's
    "DBG gait=" lines (scripts/avatar.gd, ?debug=1, one per half game-second, with the position and
    the game clock gt): the ground speed (metres per game second: the headless renderer draws a frame
    every few seconds, so wall time means nothing here, a phone's game second is a real one) against
    TP_WALK = 3.0 and TP_WALK x RUN = 6.6; each hold lasts a number of game seconds, not wall seconds; the clip (a walk clip walking, sprint or run
    running) played at ground speed / the clip's own m/s (npc/anims.json); the camera's horizontal
    distance from the player (it must keep up: under BOOM + SHOULDER + 0.2 in an open hall);
  - during each, a short frame sequence (4 screenshots, game-clock stamped: at ~0.2 fps here every
    screenshot is the next frame or so) composed into one strip <out>-<spot>-walk.png / -run.png;
  - the player's position always on free floor (free_here=true), and inside the spot's bounds
    (=xmax:/xmin:/zmax:/zmin:: a glass pane 1.5 m ahead, walked and run at: the position must reach
    it and never cross it; such a spot gets no speed or clip checks, it stands at the glass);
  - at the first spot, on a phone (844x390, touch): a full-stick touch drag walks at TP_WALK.
Prints WALK WEB OK (n checks), or the failures; 0 console errors expected.
"""
import json, math, os, re, sys, time
from playwright.sync_api import sync_playwright
from PIL import Image, ImageDraw

path, out = sys.argv[1], sys.argv[2]
HERE = os.path.dirname(os.path.abspath(__file__))
ANIMS = json.load(open(os.path.join(HERE, "..", "..", "npc", "anims.json")))["clips"]
TP_WALK, RUN, BOOM, SHOULDER = 3.0, 2.2, 2.4, 0.35
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"]
BASE = "http://127.0.0.1:8765/" + path
fails, oks, errors = [], 0, []

spots = []
for c in sys.argv[3].split(";"):
    nm, rest = c.split(":", 1)
    cam, _, bnd = rest.partition("=")
    bounds = {}
    for b in bnd.split(","):
        if ":" in b:
            k, v = b.split(":"); bounds[k] = float(v)
    spots.append((nm, cam, bounds))

def url(extra):
    return BASE + ("&" if "?" in BASE else "?") + extra

def check(ok, what):
    global oks
    print(("ok   " if ok else "FAIL ") + what, flush=True)
    if ok: oks += 1
    else: fails.append(what)

def ready(pg, logs, t=300):
    t0 = time.time()
    while time.time() - t0 < t:
        if any("DBG" in l[1] or "fps" in l[1] for l in logs) or pg.evaluate(
                "document.querySelector('#status') ? getComputedStyle(document.querySelector('#status')).display==='none' || getComputedStyle(document.querySelector('#status')).visibility==='hidden' : true"):
            return time.time() - t0
        time.sleep(1)
    return None

def errs(logs, where):
    e = [l[1] for l in logs if "ERROR" in l[1].upper() or "SCRIPT ERROR" in l[1]]
    errors.extend(e)
    check(not e, f"{where}: no console errors ({e[:2]})")

POS = re.compile(r"DBG pos=\(([-\d.e]+), ([-\d.e]+), ([-\d.e]+)\).*free_here=(\w+)")
GAIT = re.compile(r"DBG gait=(\S*) x([\d.]+) v=([\d.]+) cam=([\d.]+) boom=([\d.]+) side=(-?\d) pos=([-\d.]+),([-\d.]+) gt=([\d.]+)")

def positions(logs, t0, t1):
    out = []
    for t, l in logs:
        m = POS.search(l)
        if m and t0 <= t <= t1:
            out.append((t, float(m.group(1)), float(m.group(3)), m.group(4) == "true"))
    return out

def gaits(logs, t0, t1):
    return [(t,) + GAIT.search(l).groups() for t, l in logs if GAIT.search(l) and t0 <= t <= t1]

def speed_of(gs):
    """m per game second over the gait samples (first to last): distance walked / the game clock."""
    if len(gs) < 2: return None
    d = sum(math.hypot(float(gs[i + 1][7]) - float(gs[i][7]), float(gs[i + 1][8]) - float(gs[i][8])) for i in range(len(gs) - 1))
    return d / max(1e-6, float(gs[-1][9]) - float(gs[0][9]))

def pause(pg, secs):
    # not time.sleep: the sync API only delivers console events while it is inside a call
    pg.wait_for_timeout(int(secs * 1000))

def strip(frames, name, title):
    """frames: [(t, png path, label)] -> one labelled strip."""
    ims = [Image.open(f[1]).convert("RGB") for f in frames]
    w = 640; h = int(ims[0].height * w / ims[0].width)
    sheet = Image.new("RGB", (w * len(ims), h + 44), (20, 16, 14))
    dr = ImageDraw.Draw(sheet)
    for i, (f, im) in enumerate(zip(frames, ims)):
        sheet.paste(im.resize((w, h)), (i * w, 44))
        dr.text((i * w + 8, 24), f[2], fill=(240, 230, 210))
    dr.text((8, 5), title, fill=(255, 220, 160))
    sheet.save(f"{out}-{name}.png")
    for f in frames: os.remove(f[1])

def hold(pg, logs, keys, samples, name, title, nshots=4, wall_max=420):
    """Hold keys until `samples` gait reports (half game-seconds) have arrived, shooting nshots
    frames meanwhile (the first after one report); returns (t0, t1) wall times."""
    for k in keys: pg.keyboard.down(k)
    t0 = time.time(); frames = []
    while len(gaits(logs, t0, time.time())) < 1 and time.time() - t0 < wall_max: pause(pg, 0.5)
    while time.time() - t0 < wall_max:
        g = gaits(logs, t0, time.time())
        if len(frames) < nshots:
            fn = f"{out}-{name}-f{len(frames)}.png"
            pg.screenshot(path=fn, timeout=180000)
            g = gaits(logs, t0, time.time())
            lab = ("game t=%.1fs pos=(%.1f, %.1f) %s x%s" % (float(g[-1][9]) - float(g[0][9]), float(g[-1][7]), float(g[-1][8]), g[-1][1], g[-1][2])) if g else "no report yet"
            frames.append((time.time(), fn, lab))
        if len(g) >= samples and len(frames) >= nshots: break
        pause(pg, 0.5)
    t1 = time.time()
    for k in keys: pg.keyboard.up(k)
    # let go: wait for two more reports (a game second) so the stop shows
    n = len(gaits(logs, 0, time.time())); t2 = time.time()
    while len(gaits(logs, 0, time.time())) < n + 2 and time.time() - t2 < 120: pause(pg, 0.5)
    strip(frames, name, title)
    return t0, t1

def judge(nm, what, logs, t0, t1, want, clips, bounds, open_hall):
    gs = gaits(logs, t0, t1)[1:]   # the first report can straddle the key press
    allp = positions(logs, t0, t1 + 1.0)
    if open_hall:
        v = speed_of(gs)
        check(v is not None and abs(v - want) < want * 0.15, f"{nm} {what}: ground speed {v if v is None else round(v, 2)} m per game second (want {want}, {len(gs)} samples)")
        g = gs[-1] if gs else None
        check(g is not None and g[1] in clips, f"{nm} {what}: plays {g[1] if g else '-'} (want one of {clips})")
        if g:
            own = float(ANIMS.get(g[1], {}).get("mps", 1.0)); x = float(g[2]); gv = float(g[3])
            check(abs(x - min(2.0, gv / own)) < 0.06, f"{nm} {what}: clip at ground speed: {gv:.2f} / {own:.3f} = x{gv / own:.2f} (playing x{x:.2f})")
            cams = [float(q[4]) for q in gs]
            # BOOM back and SHOULDER aside is 2.43 m across the floor; a lagging pivot showed as more
            check(max(cams) <= math.hypot(BOOM, SHOULDER) + 0.05 and min(cams) > 1.0, f"{nm} {what}: camera keeps up, {min(cams):.2f}-{max(cams):.2f} m behind the player")
    check(allp and all(p[3] for p in allp), f"{nm} {what}: the player always on free floor ({len(allp)} samples)")
    # a bounded spot is a collision test: it walks 1.5 m into a glass pane and must reach it (the
    # grid behind it would allow more) and never cross it
    for k, lim in bounds.items():
        ax = 1 if k[0] == "x" else 2
        bad = [p for p in allp if (p[ax] > lim + 0.01 if k.endswith("max") else p[ax] < lim - 0.01)]
        check(not bad, f"{nm} {what}: stayed {k} {lim} ({len(bad)} crossings; last {allp[-1][1]:.2f},{allp[-1][2]:.2f})")
        check(allp and abs(allp[-1][ax] - lim) < 0.15, f"{nm} {what}: reached the pane ({allp[-1][ax]:.2f} vs {lim})")

with sync_playwright() as p:
    b = p.chromium.launch(args=ARGS, **({"executable_path": os.environ["CHROMIUM"]} if os.environ.get("CHROMIUM") else {}))
    for nm, cam, bounds in spots:
        open_hall = not bounds
        ctx = b.new_context(viewport={"width": 1280, "height": 720})
        pg = ctx.new_page(); logs = []
        pg.on("console", lambda m: logs.append((time.time(), m.text)))
        pg.goto(url(f"view=third&debug=1&warm=0&cam={cam}"))
        print(nm, "ready_s", ready(pg, logs), flush=True); pause(pg, 12)
        pg.mouse.move(640, 360); pg.mouse.click(640, 360)
        gs = gaits(logs, 0, time.time())
        check(bool(gs), f"{nm}: third person (gait report seen: {gs[-1][1] if gs else '-'})")
        t0, t1 = hold(pg, logs, ["w"], 7, f"{nm}-walk", f"{nm}: walking (W), third person, TP_WALK {TP_WALK} m/s")
        judge(nm, "walk", logs, t0, t1, TP_WALK, ["walk_m", "walk_f"], bounds, open_hall)
        t0, t1 = hold(pg, logs, ["w", "x"], 6, f"{nm}-run", f"{nm}: running (W+X), third person, {TP_WALK * RUN:.1f} m/s")
        judge(nm, "run", logs, t0, t1, TP_WALK * RUN, ["sprint", "run"], bounds, open_hall)
        gs = gaits(logs, t1, time.time())
        check(bool(gs) and gs[-1][1] not in ["sprint", "run", "jog", "walk_m", "walk_f"], f"{nm}: idle after the run ({gs[-1][1] if gs else '-'})")
        pg.screenshot(path=f"{out}-{nm}-idle.png", timeout=180000)
        errs(logs, nm)
        with open(f"{out}-{nm}.log", "w") as f:
            f.writelines("%.2f %s\n" % (t, l) for t, l in logs if "DBG" in l)
        ctx.close()
    # a phone: a full-stick touch drag walks at TP_WALK (the first spot)
    nm, cam, bounds = spots[0]
    ctx = b.new_context(viewport={"width": 844, "height": 390}, has_touch=True, is_mobile=True)
    pg = ctx.new_page(); logs = []
    pg.on("console", lambda m: logs.append((time.time(), m.text)))
    pg.goto(url(f"view=third&debug=1&warm=0&cam={cam}")); ready(pg, logs); pause(pg, 12)
    cdp = ctx.new_cdp_session(pg)
    def touch(t, x, y):
        cdp.send("Input.dispatchTouchEvent", {"type": t, "touchPoints": [] if t == "touchEnd" else [{"x": x, "y": y, "id": 1}]})
    touch("touchStart", 200, 300); pause(pg, 0.2)
    for i in range(1, 13):
        touch("touchMove", 200, 300 - i * 6); pause(pg, 0.05)   # 72 px up: past the 46 px full stick
    t0 = time.time()
    while len(gaits(logs, t0, time.time())) < 6 and time.time() - t0 < 300: pause(pg, 0.5)
    pg.screenshot(path=f"{out}-phone-touch-walk.png", timeout=180000)
    t1 = time.time()
    touch("touchEnd", 0, 0); pause(pg, 1.5)
    gs = gaits(logs, t0, t1)[1:]; v = speed_of(gs)
    check(v is not None and abs(v - TP_WALK) < TP_WALK * 0.15, f"phone: a full-stick touch drag walks at {v if v is None else round(v, 2)} m/s (want {TP_WALK}, {len(gs)} samples)")
    check(bool(gs) and gs[-1][1] in ["walk_m", "walk_f"], f"phone: touch walk plays {gs[-1][1] if gs else '-'}")
    errs(logs, "phone")
    with open(f"{out}-phone.log", "w") as f:
        f.writelines("%.2f %s\n" % (t, l) for t, l in logs if "DBG" in l)
    ctx.close(); b.close()
print(("WALK WEB OK (%d checks)" % oks) if not fails else "WALK WEB FAILED: " + str(fails), flush=True)
