"""SEAMLESS (Nov 13 2026, scripts/wing_stream.gd): the wing 1 <-> wing 2 border in the web build.

Usage: python3 stream_webtest.py <url-path> <out-prefix> [pack] [start] [walk_s]
   (server on :8765 serving the folder above <url-path>; pack = desktop | mobile, default mobile;
    start = "wing cam yaw-toward-the-seam", default "1 -9,40,180,0"; walk_s = the longest forward is held, seconds, default 120:
    the headless renderer draws a frame every few seconds and the game clock follows the frames)

Loads the start wing beside the seam with ?stream=1, waits for the other wing to come in, holds forward across the
seam and reports:
  - whether the load screen (#status) ever came back, and whether the page navigated (it must not);
  - the handoff: window.__mallStreamState.home changes to the other wing, the address bar's ?wing= follows;
  - the streamer's timings (fetch, mount, load, instance, enter, handoff) and the longest frames seen by the page;
  - memory: the browser's renderer process (resident set, from /proc) and the JS heap, before streaming, with the
    neighbour in, after the handoff;
  - page errors (0 expected); screenshots <out>-before.png (stand-in), -in.png (the real wing), -cross-N.png, -after.png.
Prints STREAM WEB OK or what failed. One browser at a time (2 CPUs).
"""
import json, os, re, sys, time
from playwright.sync_api import sync_playwright

path, out = sys.argv[1], sys.argv[2]
PACK = sys.argv[3] if len(sys.argv) > 3 else "mobile"
START = sys.argv[4] if len(sys.argv) > 4 else "1 -9,40,180,0"
WALK = float(sys.argv[5]) if len(sys.argv) > 5 else 120.0
WING, CAM = START.split()
OTHER = "2" if WING == "1" else "1"
STREAM = os.environ.get("STREAM", "1")
EXTRA = os.environ.get("EXTRA", "")   # e.g. "&npcs=0"
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist", "--enable-precise-memory-info"]
SHOT = int(os.environ.get("SHOT_TIMEOUT", "180000"))
fails = []


def rss_mb():
    """Resident memory of every chrome process (MB): the renderer holds the engine, its file system and the GPU's
    software textures (swiftshader), so the sum is what the tab costs here."""
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


def mem(pg):
    js = pg.evaluate("performance.memory ? Math.round(performance.memory.usedJSHeapSize / 1048576) : -1")
    return {"rss_mb": rss_mb(), "js_heap_mb": js}


with sync_playwright() as p:
    b = p.chromium.launch(args=ARGS)
    ctx = b.new_context(viewport={"width": 1280, "height": 720})
    pg = ctx.new_page()
    logs, errors, navs = [], [], []
    pg.on("console", lambda m: logs.append(f"[{m.type}] {m.text}"))
    pg.on("pageerror", lambda e: errors.append(str(e)))
    pg.on("load", lambda _p: navs.append(pg.url))        # a real page load (the address changing in place is not one)
    sep = "&" if "?" in path else "?"
    pg.goto(f"http://127.0.0.1:8765/{path}{sep}wing={WING}&cam={CAM}&pack={PACK}&stream={STREAM}&warm=0&debug=1{EXTRA}", timeout=180000)
    t0 = time.time()
    while time.time() - t0 < 420:
        if pg.evaluate("!document.getElementById('status')"):
            break
        pg.wait_for_timeout(1000)
    else:
        fails.append("the game did not start in 420 s")
    ready_s = round(time.time() - t0)
    navs0 = len(navs)
    # frame times as the page sees them, and whether the load screen ever comes back
    pg.evaluate("""() => { window.__ft = []; let last = performance.now();
        const f = (t) => { window.__ft.push(Math.round(t - last)); last = t; if (document.getElementById('status')) { window.__sawStatus = true; } requestAnimationFrame(f); };
        requestAnimationFrame(f); }""")
    pg.wait_for_timeout(3000)
    m_before = mem(pg)
    pg.screenshot(path=f"{out}-before.png", timeout=SHOT)
    st = {}
    if STREAM == "1":
        t1 = time.time()
        while time.time() - t1 < 600:
            st = pg.evaluate("window.__mallStreamState || {}")
            s = (st.get("wings") or {}).get(OTHER, "")
            if s in ("in", "failed"):
                break
            pg.wait_for_timeout(1000)
        in_s = round(time.time() - t1)
        if (st.get("wings") or {}).get(OTHER) != "in":
            fails.append(f"wing {OTHER} did not come in: {st}")
        pg.wait_for_timeout(4000)
        m_in = mem(pg)
        ft_in = pg.evaluate("window.__ft.splice(0)")
        pg.screenshot(path=f"{out}-in.png", timeout=SHOT)
        # walk across: forward held
        pg.focus("#canvas")
        pg.keyboard.down("w")
        t2 = time.time(); n = 0; home = WING
        while time.time() - t2 < WALK:
            pg.wait_for_timeout(2000)
            st = pg.evaluate("window.__mallStreamState || {}")
            if str(st.get("home")) != home:
                home = str(st.get("home")); n += 1
                pg.screenshot(path=f"{out}-cross-{n}.png", timeout=SHOT)
                break
        pg.wait_for_timeout(3000)
        pg.keyboard.up("w")
        pg.wait_for_timeout(3000)
        ft_walk = pg.evaluate("window.__ft.splice(0)")
        m_after = mem(pg)
        pg.screenshot(path=f"{out}-after.png", timeout=SHOT)
        st = pg.evaluate("window.__mallStreamState || {}")
        if str(st.get("home")) != OTHER:
            fails.append(f"no handoff to wing {OTHER} after walking {WALK:.0f} s: {st}")
        if f"wing={OTHER}" not in pg.url:
            fails.append(f"the address did not follow the handoff: {pg.url}")
        if pg.evaluate("!!window.__sawStatus"):
            fails.append("the load screen came back")
        if len(navs) != navs0:
            fails.append(f"the page navigated: {navs[navs0:]}")
        srt = lambda a: sorted(a)[-5:]
        print("last position:", [l for l in logs if "DBG pos=" in l][-1:])
        print(json.dumps({"ready_s": ready_s, "neighbour_in_s": in_s, "stats": st.get("stats"), "page_ms": pg.evaluate("window.__mallStreamMs || {}"),
                          "mem_before": m_before, "mem_in": m_in, "mem_after_handoff": m_after,
                          "worst_frames_ms_while_loading": srt(ft_in), "worst_frames_ms_walk_and_handoff": srt(ft_walk),
                          "frames_loading": len(ft_in), "frames_walk": len(ft_walk)}, indent=1))
    else:
        print(json.dumps({"ready_s": ready_s, "mem": m_before}))
    open(f"{out}-console.log", "w").write("\n".join(logs))
    # as the other web tests count them: the engine's own ERROR lines and page exceptions (a 404 for one of main's
    # play/ extras, which a bare export folder does not have, is not one); plus any WebGL error
    errs = [l for l in logs if "ERROR" in l.split("] ", 1)[-1].upper() or "GL_INVALID" in l] + errors
    print("page errors:", len(errs), errs[:5])
    if errs:
        fails.append(f"{len(errs)} page errors")
    ctx.close(); b.close()
print("STREAM WEB OK" if not fails else "STREAM WEB FAILED: " + "; ".join(fails))
