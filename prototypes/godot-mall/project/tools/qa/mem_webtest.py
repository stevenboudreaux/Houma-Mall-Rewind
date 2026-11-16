"""PHONE-MEMORY (Nov 16 2026; production/qa/evidence/wsPHONE-MEMORY-findings.md, scripts/mall_mem.gd): memory on the
web with the phone pack, one wing (streaming off) or two (streaming on), read from window.__mallMem.

  python3 tools/qa/mem_webtest.py <url-path> <out-prefix> [year]     (the build served on :8765)
  env: STREAM=0|1 (default 1), HOLD_S (seconds to keep sampling after the second wing is in, or after the lift
       when STREAM=0; default 180), VIEW (default 390x844: a phone held upright), WAIT_S (most to wait for the
       second wing, default 3600).

The page is opened with ?pack=mobile&qa=1&stream=<STREAM>. Every 5 s: window.__mallMem (the engine's texture,
buffer and video memory, the wasm heap, the wings in) and the resident memory of every Chromium process. At the end
the menu is opened on its QA tab and photographed (<out>-qa.png). Writes <out>-mem.json; prints MEM WEB OK.
Swiftshader keeps textures in ordinary memory, so the Chromium total is far above a phone's; the wasm heap and the
engine's counters are the same numbers a phone would show (the wasm heap is the page's own; the engine counts what it
uploads).
"""
import json, os, sys, time
from playwright.sync_api import sync_playwright

path, out = sys.argv[1], sys.argv[2]
YEAR = sys.argv[3] if len(sys.argv) > 3 else "1995"
STREAM = os.environ.get("STREAM", "1")
HOLD_S = float(os.environ.get("HOLD_S", "180"))
WAIT_S = float(os.environ.get("WAIT_S", "3600"))
VIEW = [int(v) for v in os.environ.get("VIEW", "390x844").split("x")]
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist", "--enable-precise-memory-info"]


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


fails = []
series = []
with sync_playwright() as p:
    exe = os.environ.get("CHROMIUM") or ("/opt/pw-browsers/chromium" if os.path.exists("/opt/pw-browsers/chromium") else None)
    b = p.chromium.launch(args=ARGS, executable_path=exe) if exe else p.chromium.launch(args=ARGS)
    ctx = b.new_context(viewport={"width": VIEW[0], "height": VIEW[1]}, has_touch=False)
    pg = ctx.new_page()
    errors = []
    pg.on("pageerror", lambda e: errors.append(str(e)))
    sep = "&" if "?" in path else "?"
    q = f"pack=mobile&qa=1&stream={STREAM}" + ("&year=2026" if YEAR == "2026" else "")
    t0 = time.time()
    pg.goto(f"http://127.0.0.1:8765/{path}{sep}{q}", timeout=180000)

    def snap(tag):
        m = pg.evaluate("window.__mallMem || null")
        r = {"tag": tag, "s": round(time.time() - t0), "rss_mb": rss_mb(), "mem": m}
        series.append(r)
        if m:
            print(json.dumps({"tag": tag, "s": r["s"], "rss_mb": r["rss_mb"], "wings": m.get("wings"), "states": m.get("states"),
                              "tex_mb": m.get("tex_mb"), "buf_mb": m.get("buf_mb"), "video_mb": m.get("video_mb"),
                              "wasm_mb": m.get("wasm_mb"), "wasm_grew": m.get("wasm_grew"), "packs_mb": m.get("packs_mb"),
                              "js_heap_mb": m.get("js_heap_mb")}), flush=True)
        return m

    lift = None
    two_at = None
    while time.time() - t0 < WAIT_S + HOLD_S + 1200:
        up = pg.evaluate("!document.getElementById('status')")
        if up and lift is None:
            lift = time.time()
            snap("lift")
        m = snap("t")
        if lift is not None:
            if STREAM == "1":
                if two_at is None and m and len(m.get("wings") or []) >= 2:
                    two_at = time.time()
                    snap("two-wings-in")
                if two_at is not None and time.time() - two_at > HOLD_S:
                    break
                if two_at is None and time.time() - lift > WAIT_S:
                    fails.append("the second wing never came in")
                    break
            elif time.time() - lift > HOLD_S:
                break
        pg.wait_for_timeout(5000)
    else:
        fails.append("timed out")
    snap("end")
    # the menu, on its QA tab (Tab opens it on MAIN; E steps to the next tab: MAIN, INVENTORY, CONTROLS, QA)
    pg.focus("#canvas")
    pg.keyboard.press("Tab")
    pg.wait_for_timeout(3000)
    for _ in range(3):
        pg.keyboard.press("e")
        pg.wait_for_timeout(2500)
    pg.wait_for_timeout(4000)
    pg.screenshot(path=f"{out}-qa.png", timeout=300000)
    peak = max(r["rss_mb"] for r in series)
    json.dump({"stream": STREAM, "year": YEAR, "peak_rss_mb": peak, "errors": errors, "series": series}, open(f"{out}-mem.json", "w"), indent=1)
    if errors:
        fails.append(f"{len(errors)} page errors: {errors[:3]}")
    b.close()
print(json.dumps({"peak_rss_mb": peak, "fails": fails}))
print("MEM WEB OK" if not fails else "MEM WEB FAILED")
