"""Packs on R2 in a browser (design/godot-build-hosting.md "Packs on R2"): a published page whose packs come from
another origin. Loads wing 1 at the main entrance, crosses to the outside (E), reloads; prints every pack request
(all must come from the bucket folder) and the errors (expect none).

Usage: python3 tools/qa/r2_webtest.py <page-url-without-query> <bucket-folder-url>
  e.g. a godot-build's play/ served on :8765 with MALL_R2 pointed at a local CORS server on :8766:
  python3 tools/qa/r2_webtest.py http://127.0.0.1:8765/.../r2page/index.html http://127.0.0.1:8766/builds/t5-pub/
Use the page's own waits (pg.wait_for_timeout), never time.sleep: the sync API delivers console events only
during its own calls.
"""
import time, re, sys
from playwright.sync_api import sync_playwright
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"]
BASE, FOLDER = sys.argv[1], sys.argv[2]
with sync_playwright() as p:
    b = p.chromium.launch(args=ARGS); ctx = b.new_context(viewport={"width": 1280, "height": 720}); pg = ctx.new_page()
    logs, reqs = [], []
    pg.on("console", lambda m: logs.append(m.text))
    pg.on("request", lambda r: reqs.append(r.url) if ".pck" in r.url else None)
    def wait_pos(n0, t=420):
        t0 = time.time()
        while time.time() - t0 < t:
            if any("DBG pos" in l for l in logs[n0:]): return int(time.time() - t0)
            pg.wait_for_timeout(1000*2)
        return None
    pg.goto(BASE + "?wing=1&cam=34.5,0,-90,0&debug=1")
    print("1. wing 1 ready in", wait_pos(0), "s")
    pg.wait_for_timeout(1000*6); pg.screenshot(path="r2web-w1.png", timeout=120000)
    n0 = len(logs); r0 = len(reqs)
    pg.keyboard.press("e")
    t0 = time.time()
    while time.time() - t0 < 120 and "wing=3" not in pg.url: pg.wait_for_timeout(1000)
    print("2. crossed to", re.search(r"wing=\d", pg.url).group(0), "ready in", wait_pos(n0), "s")
    pg.wait_for_timeout(1000*6); pg.screenshot(path="r2web-w3.png", timeout=120000)
    n1 = len(logs); r1 = len(reqs)
    pg.reload(); print("3. reload ready in", wait_pos(n1), "s")
    packs = [u for u in reqs]
    print("pack requests:", len(packs)); [print("   ", u.replace("http://127.0.0.1:", ":")) for u in sorted(set(packs))]
    bad = [u for u in packs if not u.startswith(FOLDER)]
    print("packs not from the bucket:", bad or "none")
    pg.wait_for_timeout(3000); cached = pg.evaluate("caches.keys().then(ks=>Promise.all(ks.map(k=>caches.open(k).then(c=>c.keys()).then(rs=>rs.map(r=>r.url))))).then(a=>a.flat())")
    print("in Cache Storage:", len(cached), [c.replace("http://127.0.0.1:", ":") for c in cached][:6])
    errs = [l for l in logs if ("error" in l.lower() or "cors" in l.lower()) and "TUNNEL" not in l and "signs.json" not in l and "404" not in l]
    print("errors:", errs[:5] or "none")
    b.close()
