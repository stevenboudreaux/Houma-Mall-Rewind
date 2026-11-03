"""MENU2 (design/godot-menu.md "Time travel at the directory"): the year toggle on a mall directory, in
the web build, headless Chromium (swiftshader). One trip in each direction at the H2 kiosk (wing 1):

  1995 -> 2026: stand 1.6 m in front of the kiosk, E opens the directory, Y (its toggle) travels;
  2026 -> 1995: the same from where you landed.

Each trip checks:
  - the load screen (#load-card) is never visible on any animation frame of the page that loads the
    other year (a watcher installed in every page records every frame);
  - the vortex veil covers the reload (#tt-veil seen) and the game picks the trip up (Godot side);
  - you land within 1 m of the kiosk's twin spot (data/directory_twins.json, the same maths as
    scripts/timetravel_trip.gd landing()), facing the same way (within 2 degrees);
  - 0 console errors.
A frame sequence of the transition is kept (CDP screencast, through the reload): <out>-<dir>-NN.jpg,
and a contact sheet <out>-<dir>-sheet.jpg.

Usage (a server on :8765 serving the repo root):
  CHROMIUM=/opt/pw-browsers/chromium python3 tools/qa/menu_trip_webtest.py <url-path-to-index.html> <out-prefix>
Prints MENU TRIP WEB OK, or the failures.
"""
import base64, json, math, os, re, sys, time
from playwright.sync_api import sync_playwright

path, out = sys.argv[1], sys.argv[2]
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"]
BASE = "http://127.0.0.1:8765/" + path
HERE = os.path.dirname(os.path.abspath(__file__))
TWINS = json.load(open(os.path.join(HERE, "..", "..", "data", "directory_twins.json")))
fails, oks = [], 0

# the H2 kiosk, wing 1
K = TWINS["kiosks"][0]

def check(ok, what):
    global oks
    print(("ok   " if ok else "FAIL ") + what, flush=True)
    if ok: oks += 1
    else: fails.append(what)

def landing(k, frm, px, pz, yaw_deg):
    """= scripts/timetravel_trip.gd landing(): the player's place relative to the kiosk, carried to the twin."""
    to = "2026" if frm == "1995" else "1995"
    h, t = k[frm], k[to] or k[frm]
    a = math.atan2(t["face"][1], t["face"][0]) - math.atan2(h["face"][1], h["face"][0])
    rx, rz = px - h["x"], pz - h["z"]
    return (t["x"] + rx * math.cos(a) - rz * math.sin(a), t["z"] + rx * math.sin(a) + rz * math.cos(a), yaw_deg - math.degrees(a))

# every page this context opens: record, every animation frame, whether the load screen is visible
WATCH = """
(() => {
  const W = window.__ttWatch = {frames: 0, loadShown: 0, veil: 0, tt: 0};
  const vis = (el) => { if (!el) return false; const s = getComputedStyle(el); return s.display !== 'none' && s.visibility !== 'hidden' && parseFloat(s.opacity) > 0.01; };
  const tick = () => {
    W.frames++;
    const card = document.getElementById('load-card'), st = document.getElementById('status');
    if (card && vis(card) && vis(st)) W.loadShown++;
    if (document.getElementById('tt-veil')) W.veil++;
    if (document.documentElement.classList.contains('tt')) W.tt++;
    requestAnimationFrame(tick);
  };
  requestAnimationFrame(tick);
})();
"""

def sheet(kept, fn, title, n=16, cols=4):
    """Pick n frames evenly over the trip, label each with its time, in a grid (JPEG <= 1600 px)."""
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        return
    if not kept:
        return
    pick = [kept[round(i * (len(kept) - 1) / max(1, n - 1))] for i in range(min(n, len(kept)))]
    ims = [Image.open(f).convert("RGB") for f, _ in pick]
    w, h = 400, int(400 * ims[0].height / ims[0].width)
    rows = (len(ims) + cols - 1) // cols
    out_im = Image.new("RGB", (cols * w, rows * h + 30), (20, 16, 12))
    d = ImageDraw.Draw(out_im)
    d.text((8, 8), f"{title}: {len(kept)} frames, t from the toggle press", fill=(240, 220, 170))
    for i, (im, (_, t)) in enumerate(zip(ims, pick)):
        x, y = (i % cols) * w, 30 + (i // cols) * h
        out_im.paste(im.resize((w, h)), (x, y))
        d.rectangle([x + 4, y + 4, x + 64, y + 20], fill=(0, 0, 0))
        d.text((x + 8, y + 6), f"{t:5.2f} s", fill=(255, 255, 255))
    out_im.save(fn, quality=85)

def wait_ready(pg, logs, t=300):
    t0 = time.time()
    while time.time() - t0 < t:
        try:
            if pg.evaluate("!document.getElementById('status') && !!window.__mallControlAt"):
                return time.time() - t0
        except Exception:
            pass
        pg.wait_for_timeout(500)
    return None

with sync_playwright() as p:
    b = p.chromium.launch(args=ARGS, **({"executable_path": os.environ["CHROMIUM"]} if os.environ.get("CHROMIUM") else {}))
    ctx = b.new_context(viewport={"width": 1280, "height": 720})
    ctx.add_init_script(WATCH)
    pg = ctx.new_page()
    logs = []
    pg.on("console", lambda m: logs.append(m.text))
    cdp = ctx.new_cdp_session(pg)
    frames = []
    def on_frame(ev):
        frames.append((time.time(), ev["data"]))
        try:
            cdp.send("Page.screencastFrameAck", {"sessionId": ev["sessionId"]})
        except Exception:
            pass
    cdp.on("Page.screencastFrame", on_frame)

    h = K["1995"]
    f = h["face"]
    sx, sz = h["x"] + f[0] * 1.6 - f[1] * 0.3, h["z"] + f[1] * 1.6 + f[0] * 0.3
    syaw = math.degrees(math.atan2(f[0], f[1]))
    pg.goto(BASE + f"?wing={K['wing']}&cam={sx:.2f},{sz:.2f},{syaw:.1f},-4")
    print("1995 ready_s", wait_ready(pg, logs)); pg.wait_for_timeout(8000)
    pg.mouse.click(640, 700); pg.wait_for_timeout(800)
    pos = (sx, sz, syaw)
    year = "1995"
    for leg in ["1995-2026", "2026-1995"]:
        logs_before = len(logs)
        pg.keyboard.press("e"); pg.wait_for_timeout(2500)
        pg.screenshot(path=f"{out}-{leg}-directory.png", timeout=180000)
        frames.clear()
        cdp.send("Page.startScreencast", {"format": "jpeg", "quality": 70, "maxWidth": 640, "maxHeight": 360, "everyNthFrame": 1})
        t0 = time.time()
        pg.keyboard.press("y")
        # wait for the other year's page and the trip's end
        done, landed = False, None
        while time.time() - t0 < 360:
            pg.wait_for_timeout(250)
            m = [re.search(r"time travel: arrived in (\d+) at (-?[\d.]+),(-?[\d.]+) yaw (-?[\d.]+)", l) for l in logs[logs_before:]]
            m = [x for x in m if x]
            if m:
                landed = m[-1]; done = True
                break
        pg.wait_for_timeout(1500)
        cdp.send("Page.stopScreencast")
        dt = time.time() - t0
        to = "2026" if year == "1995" else "1995"
        check(done, f"{leg}: the trip arrives ({dt:.0f} s)")
        try:
            w = pg.evaluate("window.__ttWatch")
        except Exception:
            w = None
        print(f"{leg}: watcher {w}")
        check(w is not None and w["frames"] > 30 and w["loadShown"] == 0, f"{leg}: the load screen never shows ({w and w['loadShown']} of {w and w['frames']} frames)")
        check(w is not None and w["veil"] > 0, f"{leg}: the vortex veil covered the reload ({w and w['veil']} frames)")
        check(any("time travel: " + year in l or ("time travel: %s -> %s" % (year, to)) in l for l in logs[logs_before:]), f"{leg}: the trip began in {year}")
        if landed:
            ex, ez, eyaw = landing(K, year, pos[0], pos[1], pos[2])
            ax, az, ayaw = float(landed.group(2)), float(landed.group(3)), float(landed.group(4))
            d = math.hypot(ax - ex, az - ez)
            dy = abs((ayaw - eyaw + 180) % 360 - 180)
            check(landed.group(1) == to, f"{leg}: in {to} (got {landed.group(1)})")
            check(d < 1.0, f"{leg}: landed within 1 m of the twin spot ({d:.2f} m; at {ax:.2f},{az:.2f}, twin spot {ex:.2f},{ez:.2f})")
            check(dy < 2.0, f"{leg}: the same facing ({ayaw:.1f} vs {eyaw:.1f})")
            pos = (ax, az, ayaw)
        url_now = pg.url
        check(("year=2026" in url_now) == (to == "2026"), f"{leg}: the page is the {to} file ({url_now.split('?')[-1]})")
        e = [l for l in logs[logs_before:] if "ERROR" in l.upper()]
        check(not e, f"{leg}: no console errors ({e[:2]})")
        # the frame sequence
        t_first = frames[0][0] if frames else t0
        kept = []
        for i, (ts, data) in enumerate(frames):
            fn = f"{out}-{leg}-{len(kept):02d}.jpg"
            open(fn, "wb").write(base64.b64decode(data))
            kept.append((fn, ts - t0))
        print(f"{leg}: {len(kept)} frames over {dt:.1f} s")
        json.dump(kept, open(f"{out}-{leg}-frames.json", "w"))
        sheet(kept, f"{out}-{leg}-sheet.jpg", leg)
        pg.screenshot(path=f"{out}-{leg}-arrived.png", timeout=180000)
        year = to
        pg.wait_for_timeout(3000)
        pg.mouse.click(640, 700); pg.wait_for_timeout(500)
    b.close()

print("checks ok:", oks)
if fails:
    print("MENU TRIP WEB FAILED:", fails)
    sys.exit(1)
print("MENU TRIP WEB OK (%d checks)" % oks)
