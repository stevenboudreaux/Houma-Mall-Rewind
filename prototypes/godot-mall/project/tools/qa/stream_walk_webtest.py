"""SEAMLESS stage 3 (Nov 13 2026, scripts/wing_stream.gd): the whole interior in the web build, one page, no load.

Usage: python3 stream_walk_webtest.py <url-path> <out-prefix> [pack] [year]
   (server on :8765 serving the folder above <url-path>; pack = desktop | mobile, default mobile; year 1995 | 2026)

Starts in Dillard's (wing 5) beside its opening and goes: the Dillard's court (wing 2) -> across the seam into wing 1
-> into Sears / Lynn's (wing 4) -> back out to wing 1 -> across the seam into wing 2 -> Corn Dog 7.
Each border is walked (forward held from a few metres before the line until the handoff). Between borders the test
places the player a few metres before the next one (?qa=1, window.__mallTeleport): the long halls are not walked,
the headless renderer draws a frame every few seconds here.
It records, and fails on:
  - the load screen (#status) coming back, or the page loading again (it must be one page from start to end);
  - a border that does not open (the wing beyond not in within the wait) or a handoff that does not happen;
  - a prompt showing at a border the streamer holds;
  - page errors (0 expected).
It reports the streamer's timings, the wings in at each step, and memory (every chrome process, and the JS heap)
at the start, at its peak and at the end. Screenshots: <out>-start.png, -leg<N>-before.png, -leg<N>-after.png, -end.png.
Prints STREAM WALK WEB OK or what failed. One browser at a time (2 CPUs).
Streaming must be on: the build's default (data/stream.json), or STREAM=1 to force ?stream=1.
"""
import json, os, sys, time
from playwright.sync_api import sync_playwright

path, out = sys.argv[1], sys.argv[2]
PACK = sys.argv[3] if len(sys.argv) > 3 else "mobile"
YEAR = sys.argv[4] if len(sys.argv) > 4 else "1995"
STREAM = os.environ.get("STREAM", "")
EXTRA = os.environ.get("EXTRA", "")
WAIT_IN = float(os.environ.get("WAIT_IN", "900"))     # the longest a wing may take to come in, seconds (here)
WALK = float(os.environ.get("WALK", "240"))           # the longest forward is held at one border, seconds
SHOT = int(os.environ.get("SHOT_TIMEOUT", "180000"))
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist", "--enable-precise-memory-info"]
# [to wing, x, z a few metres before the line, yaw (deg) to walk, what]
LEGS = [
    (2, -4.0, 84.0, 0.0, "Dillard's -> the Dillard's court"),
    (1, -9.0, 52.0, 0.0, "wing 2 -> wing 1 (the seam)"),
    (4, -4.0, -92.0, 0.0, "wing 1 -> Sears / Lynn's"),
    (1, -4.0, -99.5, 180.0, "Sears / Lynn's -> wing 1"),
    (2, -9.0, 44.0, 180.0, "wing 1 -> wing 2 (the seam)"),
]
CD7 = (-97.6, 54.5, 180.0)       # in front of Corn Dog 7 (wing 2)
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
    pg.on("load", lambda _p: navs.append(pg.url))
    sep = "&" if "?" in path else "?"
    q = f"wing=5&cam={LEGS[0][1]},{LEGS[0][2]},{LEGS[0][3]},0&pack={PACK}&warm=0&qa=1"
    if YEAR == "2026":
        q += "&year=2026"
    if STREAM:
        q += f"&stream={STREAM}"
    pg.goto(f"http://127.0.0.1:8765/{path}{sep}{q}{EXTRA}", timeout=180000)
    t0 = time.time()
    while time.time() - t0 < 600:
        if pg.evaluate("!document.getElementById('status')"):
            break
        pg.wait_for_timeout(1000)
    else:
        fails.append("the game did not start in 600 s")
    ready_s = round(time.time() - t0)
    navs0 = len(navs)
    pg.evaluate("""() => { window.__ft = []; let last = performance.now();
        const f = (t) => { window.__ft.push(Math.round(t - last)); last = t; if (document.getElementById('status')) { window.__sawStatus = true; } requestAnimationFrame(f); };
        requestAnimationFrame(f); }""")
    pg.wait_for_timeout(3000)
    m_start = mem(pg)
    peak = dict(m_start)
    pg.screenshot(path=f"{out}-start.png", timeout=SHOT)
    steps = []

    def state():
        return pg.evaluate("window.__mallStreamState || {}")

    def note_mem():
        m = mem(pg)
        for k in m:
            peak[k] = max(peak[k], m[k])
        return m

    for i, (to, x, z, yaw, what) in enumerate(LEGS):
        if fails:
            break
        pg.evaluate(f"window.__mallTeleport = [{x}, {z}, {yaw}]")
        t1 = time.time()
        st = {}
        saw_prompt = False
        while time.time() - t1 < WAIT_IN:
            st = state()
            pos = pg.evaluate("window.__mallPos || null")
            if pos and pos[4] and str(st.get("home")) != str(to):
                saw_prompt = True
            w = (st.get("wings") or {}).get(str(to), "")
            if w == "in" and to in (st.get("peopled") or []):
                break
            if w == "failed":
                break
            pg.wait_for_timeout(1500)
        in_s = round(time.time() - t1)
        if (st.get("wings") or {}).get(str(to)) != "in":
            fails.append(f"{what}: wing {to} did not come in within {WAIT_IN:.0f} s: {st.get('wings')}")
            break
        if saw_prompt:
            fails.append(f"{what}: a prompt showed while wing {to} was coming in")
        note_mem()
        pg.screenshot(path=f"{out}-leg{i}-before.png", timeout=SHOT)
        pg.focus("#canvas")
        pg.keyboard.down("w")
        t2 = time.time()
        crossed = False
        while time.time() - t2 < WALK:
            pg.wait_for_timeout(1500)
            st = state()
            if str(st.get("home")) == str(to):
                crossed = True
                break
        pg.wait_for_timeout(1500)
        pg.keyboard.up("w")
        pg.wait_for_timeout(2500)
        m = note_mem()
        pg.screenshot(path=f"{out}-leg{i}-after.png", timeout=SHOT)
        pos = pg.evaluate("window.__mallPos || null")
        steps.append({"leg": what, "in_after_s": in_s, "crossed": crossed, "walk_s": round(time.time() - t2), "pos": pos,
                      "wings_in": [st.get("home")] + sorted(int(k) for k, v in (st.get("wings") or {}).items() if v == "in"), "mem": m})
        print(json.dumps(steps[-1]), flush=True)
        if not crossed:
            fails.append(f"{what}: no handoff to wing {to} after walking {WALK:.0f} s (at {pos})")
        if pos and pos[4]:
            fails.append(f"{what}: a prompt shows after the crossing")
    if not fails:
        pg.evaluate(f"window.__mallTeleport = [{CD7[0]}, {CD7[1]}, {CD7[2]}]")
        pg.wait_for_timeout(6000)
        pos = pg.evaluate("window.__mallPos || null")
        if not pos or abs(pos[0] - CD7[0]) > 1.0 or pos[2] != 2:
            fails.append(f"not at Corn Dog 7 in wing 2 at the end: {pos}")
        pg.screenshot(path=f"{out}-end.png", timeout=SHOT)
    m_end = note_mem()
    st = state()
    if pg.evaluate("!!window.__sawStatus"):
        fails.append("the load screen came back")
    if len(navs) != navs0:
        fails.append(f"the page loaded again: {navs[navs0:]}")
    ft = pg.evaluate("window.__ft.splice(0)")
    print(json.dumps({"pack": PACK, "year": YEAR, "ready_s": ready_s, "stats": st.get("stats"), "page_ms": pg.evaluate("window.__mallStreamMs || {}"),
                      "mem_start": m_start, "mem_peak": peak, "mem_end": m_end, "wings_in_at_end": [st.get("home")] + sorted(int(k) for k, v in (st.get("wings") or {}).items() if v == "in"),
                      "frames": len(ft), "worst_frames_ms": sorted(ft)[-5:]}, indent=1))
    open(f"{out}-console.log", "w").write("\n".join(logs))
    errs = [l for l in logs if "ERROR" in l.split("] ", 1)[-1].upper() or "GL_INVALID" in l] + errors
    print("page errors:", len(errs), errs[:5])
    if errs:
        fails.append(f"{len(errs)} page errors")
    ctx.close(); b.close()
print("STREAM WALK WEB OK" if not fails else "STREAM WALK WEB FAILED: " + "; ".join(fails))
