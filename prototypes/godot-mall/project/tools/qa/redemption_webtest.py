"""Web check of Pocket Change's redemption at phone sizes (workstream R; design/godot-prize-counter.md).

Usage: CHROMIUM=/opt/pw-browsers/chromium python3 tools/qa/redemption_webtest.py <build-path>/index.html <out-prefix>
(a server on :8765 serving the repo root). For iPhone portrait (390 x 844) and landscape (844 x 390), with
touch: a saved state of 600 tickets, stand at the long case, tap "Redeem tickets", screenshot the screen;
then Enter buys the selected prize (the first card) and the "You received" card shows; screenshot.
Prints each step and the console errors (expect 0).
"""
import json, os, sys, time
from playwright.sync_api import sync_playwright

path, out = sys.argv[1], sys.argv[2]
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"]
STATE = {"v": 1, "year": 1995, "inventory": [], "tickets": 600, "hand": "", "moved": {}}
CAM = "-104.8,64.2,-90,-18"


def ready(pg, logs, t=300):
    t0 = time.time()
    while time.time() - t0 < t:
        if any("fps" in l or "npcs:" in l for l in logs):
            return time.time() - t0
        time.sleep(1)
    return None


with sync_playwright() as p:
    b = p.chromium.launch(args=ARGS, executable_path=os.environ.get("CHROMIUM") or None)
    total_errs = 0
    for name, (w, h) in {"iphone-portrait": (390, 844), "iphone-landscape": (844, 390)}.items():
        ctx = b.new_context(viewport={"width": w, "height": h}, has_touch=True, is_mobile=True)
        ctx.add_init_script("try{localStorage.setItem('mall-state-1995', %s)}catch(e){}" % json.dumps(json.dumps(STATE)))
        pg = ctx.new_page(); logs = []
        pg.on("console", lambda m: logs.append(m.text))
        pg.goto(f"http://127.0.0.1:8765/{path}?wing=2&cam={CAM}")
        took = ready(pg, logs, 150)
        time.sleep(20)
        cdp = ctx.new_cdp_session(pg)
        # the prompt sits bottom centre, 74-132 px up
        x, y = w / 2, h - 103
        for t in ("touchStart", "touchEnd"):
            cdp.send("Input.dispatchTouchEvent", {"type": t, "touchPoints": [] if t == "touchEnd" else [{"x": x, "y": y, "id": 1}]})
            time.sleep(0.15)
        time.sleep(25)       # swiftshader handles input many seconds late
        pg.screenshot(path=f"{out}-{name}-screen.png", timeout=180000)
        pg.keyboard.press("Enter")          # buy the selected (first) prize (opens the screen if the tap didn't)
        time.sleep(25)
        pg.screenshot(path=f"{out}-{name}-popup.png", timeout=180000)
        errs = [l for l in logs if "ERROR" in l.upper()]
        total_errs += len(errs)
        print(name, "ready_s", took, "errors", len(errs), errs[:3])
        ctx.close()
    b.close()
    print("REDEMPTION WEB", "OK" if total_errs == 0 else "ERRORS %d" % total_errs)
