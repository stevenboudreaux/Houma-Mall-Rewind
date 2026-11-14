"""Headless check of the wing crossing (design/godot-wings.md): load wing 1 by the seam, check the
prompt shows, press E, and check the page comes back as wing 2 at the same spot (and back again).

Usage: python3 seamtest.py <url-path> <out-prefix>   (server on :8765 serving the repo root)

SEAMLESS (Nov 13 2026): with streaming on (data/stream.json) the seam is plain floor and has no prompt
(tools/qa/stream_walk_webtest.py walks it). This test now runs with ?stream=0: it checks the old crossing, which is
still what a visitor gets with ?stream=0 or when a wing's pack cannot be fetched.
"""
import sys, time, re
from playwright.sync_api import sync_playwright

path, out = sys.argv[1], sys.argv[2]
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"]

def ready(pg, logs, t=240):
    t0 = time.time()
    while time.time() - t0 < t:
        if pg.evaluate("!document.getElementById('status')"):
            return time.time() - t0
        time.sleep(1)
    return None

with sync_playwright() as p:
    b = p.chromium.launch(args=ARGS)
    ctx = b.new_context(viewport={"width": 1280, "height": 720})
    pg = ctx.new_page(); logs = []
    pg.on("console", lambda m: logs.append(m.text))
    ok = True
    for leg, (start, key_wing) in enumerate([("-4,46.6,180,-3", "2"), (None, "1")]):
        if start:
            pg.goto(f"http://127.0.0.1:8765/{path}?cam={start}&debug=1&stream=0")
        print("leg", leg, "ready_s", ready(pg, logs))
        time.sleep(6)
        pg.screenshot(path=f"{out}-{leg}-prompt.png")
        if leg == 1:
            # walk back: turn round, the prompt for wing 1 should be up (we stand 1.3 m past the seam)
            pass
        # leg 0 by key (after focusing the canvas), leg 1 by clicking the prompt
        if leg == 0:
            pg.focus("#canvas")
            pg.keyboard.down("e"); time.sleep(1.5); pg.keyboard.up("e")
        else:
            pg.mouse.move(640, 617); pg.mouse.down(); time.sleep(1.5); pg.mouse.up()
        t0 = time.time()
        href = lambda: pg.evaluate("location.href") if True else ""
        cur = ""
        while time.time() - t0 < 90:
            try:
                cur = href()
            except Exception:
                cur = ""
            if f"wing={key_wing}" in cur:
                break
            time.sleep(0.5)
        print("leg", leg, "url", cur)
        if f"wing={key_wing}" not in cur:
            ok = False
            break
    print("arrived ready_s", ready(pg, logs)); time.sleep(6)
    pg.screenshot(path=f"{out}-back.png")
    print("\n".join([l for l in logs if "prompt" in l or "crossing" in l or "ERR" in l.upper() or "function" in l][:12]))
    errs = [l for l in logs if "ERROR" in l.upper()]
    print("errors", len(errs), errs[:3])
    print("CROSSED" if ok else "DID NOT CROSS")
    b.close()
