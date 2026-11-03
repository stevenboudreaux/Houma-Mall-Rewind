"""Headless check of a Godot web export: load, screenshot at fixed cameras, touch-drag walk test.

Usage: python3 movetest.py <url-path> <out-prefix>   (server on :8765 serving the repo root)
Optional env CAMS='{"name":"x,z,yaw,pitch",...}' overrides the camera spots.
"""
import re, sys, time
from playwright.sync_api import sync_playwright

path, out = sys.argv[1], sys.argv[2]
import os, json
CAMS = json.loads(os.environ["CAMS"]) if os.environ.get("CAMS") else {"shoe": "0,14,0,-8", "sears": "-60,-90,90,-5", "floor": "-6,10,30,-25"}
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"]

def wait_ready(page, logs, t=240):
    t0 = time.time()
    while time.time() - t0 < t:
        if any("fps" in l or "DBG" in l for l in logs) or page.evaluate("document.querySelector('#status') ? getComputedStyle(document.querySelector('#status')).display==='none' || getComputedStyle(document.querySelector('#status')).visibility==='hidden' : true"):
            return time.time() - t0
        time.sleep(1)
    return None

with sync_playwright() as p:
    b = p.chromium.launch(args=ARGS)
    for name, cam in CAMS.items():
        ctx = b.new_context(viewport={"width": 1280, "height": 720})
        pg = ctx.new_page(); logs = []
        pg.on("console", lambda m: logs.append(m.text))
        pg.goto(f"http://127.0.0.1:8765/{path}{'&' if '?' in path else '?'}cam={cam}")
        took = wait_ready(pg, logs)
        time.sleep(12)
        pg.screenshot(path=f"{out}-{name}.png", timeout=int(os.environ.get("SHOT_TIMEOUT", "120000")))
        errs = [l for l in logs if "ERROR" in l.upper()]
        print(name, "ready_s", took, "errors", len(errs), errs[:3])
        ctx.close()
    # walk test with touch
    ctx = b.new_context(viewport={"width": 844, "height": 390}, has_touch=True, is_mobile=True)
    pg = ctx.new_page(); logs = []
    pg.on("console", lambda m: logs.append(m.text))
    pg.goto(f"http://127.0.0.1:8765/{path}{'&' if '?' in path else '?'}cam={os.environ.get('WALK_CAM', '0,14,0,0')}&debug=1")
    wait_ready(pg, logs); time.sleep(10)
    cdp = ctx.new_cdp_session(pg)
    def touch(t, x, y):
        pts = [] if t == "touchEnd" else [{"x": x, "y": y, "id": 1}]
        cdp.send("Input.dispatchTouchEvent", {"type": t, "touchPoints": pts})
    before = [l for l in logs if l.startswith("DBG pos=")][-1:]
    touch("touchStart", 200, 300); time.sleep(0.2)
    for i in range(1, 11):
        touch("touchMove", 200, 300 - i * 6); time.sleep(0.05)
    time.sleep(4)
    during = [l for l in logs if l.startswith("DBG pos=")][-1:]
    touch("touchEnd", 0, 0); time.sleep(1)
    print("walk before:", before); print("walk during:", during)
    pos = lambda s: re.search(r"pos=\(([^)]*)\)", s[0]).group(1) if s else None
    print("MOVED" if pos(before) and pos(during) and pos(before) != pos(during) else "DID NOT MOVE")
    ctx.close(); b.close()
