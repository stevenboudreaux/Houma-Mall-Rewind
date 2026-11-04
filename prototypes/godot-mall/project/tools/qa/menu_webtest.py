"""Workstream M (design/godot-menu.md): the menu in the web build, headless Chromium (swiftshader).

Usage: CHROMIUM=/opt/pw-browsers/chromium python3 tools/qa/menu_webtest.py <url-path> <out-prefix>
  (server on :8765 serving the repo root; <url-path> e.g.
   prototypes/godot-mall/project/.scratch/builds/wsm/index.html?wing=2)
Checks, each in a fresh browser profile:
  MENU2 (Nov 3): the tabs are MAIN (the character, money, tickets; Edit inside), INVENTORY, CONTROLS.
  ws/items (Nov 4 2026): no opening; a first visit starts in the mall.
  1. desktop 1280x720, first visit: in the mall; C opens MAIN's editing, Enter on NAME types;
     typing a name saves localStorage "mall.player_name"; Tab closes; Tab opens MAIN; E walks the tabs
     (a shot of each); CONTROLS: Action remapped to F with the keyboard (saved in "mall-controls-1");
     a reload keeps F.
  2. phone portrait 390x844 (touch), first visit: in the mall; the Menu button opens MAIN; swipes
     through the tabs (a shot of each); the close button.
  3. phone landscape 844x390 (touch): a first start.
Prints MENU WEB OK, or the failures; 0 console errors expected.
"""
import json, os, sys, time
from playwright.sync_api import sync_playwright

path, out = sys.argv[1], sys.argv[2]
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"]
BASE = "http://127.0.0.1:8765/" + path
fails, oks, errors = [], 0, []

def url(extra=""):
    return BASE + ("&" if "?" in BASE else "?") + extra if extra else BASE

def check(ok, what):
    global oks
    print(("ok   " if ok else "FAIL ") + what, flush=True)
    if ok: oks += 1
    else: fails.append(what)

def ready(pg, logs, t=300):
    t0 = time.time()
    while time.time() - t0 < t:
        if any("npcs:" in l or "fps" in l for l in logs) or pg.evaluate(
                "document.querySelector('#status') ? getComputedStyle(document.querySelector('#status')).display==='none' || getComputedStyle(document.querySelector('#status')).visibility==='hidden' : true"):
            return time.time() - t0
        time.sleep(1)
    return None

def ls(pg, k):
    return pg.evaluate(f"localStorage.getItem({json.dumps(k)})")

def shot(pg, name):
    pg.screenshot(path=f"{out}-{name}.png", timeout=180000)

def errs(logs, where):
    e = [l for l in logs if "ERROR" in l.upper() or "SCRIPT ERROR" in l]
    errors.extend(e)
    check(not e, f"{where}: no console errors ({e[:2]})")

def key(pg, k, wait=1.5):
    pg.keyboard.press(k); time.sleep(wait)

def tap(pg, x, y, wait=1.5):
    pg.touchscreen.tap(x, y); time.sleep(wait)

def swipe(pg, cdp, x0, y0, x1, y1, wait=2.0):
    steps = 8
    cdp.send("Input.dispatchTouchEvent", {"type": "touchStart", "touchPoints": [{"x": x0, "y": y0}]})
    for i in range(1, steps + 1):
        t = i / steps
        cdp.send("Input.dispatchTouchEvent", {"type": "touchMove", "touchPoints": [{"x": x0 + (x1 - x0) * t, "y": y0 + (y1 - y0) * t}]})
        time.sleep(0.05)
    cdp.send("Input.dispatchTouchEvent", {"type": "touchEnd", "touchPoints": []})
    time.sleep(wait)

with sync_playwright() as p:
    b = p.chromium.launch(args=ARGS, **({"executable_path": os.environ["CHROMIUM"]} if os.environ.get("CHROMIUM") else {}))
    # 1. desktop, first visit
    ctx = b.new_context(viewport={"width": 1280, "height": 720})
    pg = ctx.new_page(); logs = []
    pg.on("console", lambda m: logs.append(m.text))
    pg.goto(url())
    print("desktop ready_s", ready(pg, logs)); time.sleep(15)
    pg.mouse.click(640, 700); time.sleep(1)     # focus the canvas (a click on empty background)
    shot(pg, "web-first-start-desktop")    # ws/items (Nov 4): no opening; the game starts in the mall
    key(pg, "c", 3)                         # C: MAIN's avatar editing (what START used to open)
    key(pg, "Enter", 2)                     # the NAME row: start typing
    shot(pg, "web-main-edit-name-focused-desktop")
    pg.keyboard.type("TESTER", delay=120); time.sleep(1)
    key(pg, "Enter", 2)
    check(ls(pg, "mall.player_name") == "TESTER", f"desktop: the name is saved ({ls(pg, 'mall.player_name')})")
    shot(pg, "web-main-edit-desktop")
    key(pg, "Tab", 2)
    check(ls(pg, "mall-avatar-1") is not None, "desktop: Tab closes the menu (the creator's look kept)")
    shot(pg, "web-closed-desktop")
    key(pg, "Tab", 3)
    shot(pg, "web-main-desktop")           # the menu opens on MAIN (far left)
    for t in ["inventory", "controls"]:
        key(pg, "e", 3)
        shot(pg, f"web-{t}-desktop")
    # the remappable rows: forward, back, left, right, run, interact (6th)
    for _ in range(5):
        key(pg, "ArrowDown", 0.6)
    key(pg, "Enter", 2)
    shot(pg, "web-controls-capture-desktop")
    key(pg, "f", 2)
    c = ls(pg, "mall-controls-1")
    check(c is not None and json.loads(c).get("interact", {}).get("keys") == [70], f"desktop: Action remapped to F and saved ({c})")
    shot(pg, "web-controls-remapped-desktop")
    errs(logs, "desktop")
    logs.clear()
    pg.goto(url("cam=-20,54,90,-8")); ready(pg, logs); time.sleep(12)
    pg.mouse.click(640, 700); time.sleep(1)
    shot(pg, "web-reload-closed-desktop")
    key(pg, "Tab", 3); key(pg, "e", 3); key(pg, "e", 3)
    shot(pg, "web-controls-after-reload-desktop")
    check(json.loads(ls(pg, "mall-controls-1") or "{}").get("interact", {}).get("keys") == [70], "desktop: a reload keeps F")
    pg.goto(url()); ready(pg, logs); time.sleep(12)
    shot(pg, "web-start-once-named")
    errs(logs, "desktop reload")
    ctx.close()

    # 2. phone portrait, touch
    ctx = b.new_context(viewport={"width": 390, "height": 844}, has_touch=True, is_mobile=True, device_scale_factor=1)
    pg = ctx.new_page(); logs = []
    pg.on("console", lambda m: logs.append(m.text))
    cdp = ctx.new_cdp_session(pg)
    pg.goto(url()); print("portrait ready_s", ready(pg, logs)); time.sleep(15)
    shot(pg, "web-first-start-phone-portrait")   # ws/items: no opening
    tap(pg, 65, 24, 3)                             # the Menu button (top left): MAIN
    shot(pg, "web-main-phone-portrait")
    for t in ["inventory", "controls"]:
        swipe(pg, cdp, 300, 30, 120, 30, 3)
        shot(pg, f"web-{t}-phone-portrait")
    tap(pg, 390 - 30, 26, 2)       # the close button
    shot(pg, "web-closed-phone-portrait")
    errs(logs, "portrait")
    ctx.close()

    # 3. phone landscape, touch
    ctx = b.new_context(viewport={"width": 844, "height": 390}, has_touch=True, is_mobile=True, device_scale_factor=1)
    pg = ctx.new_page(); logs = []
    pg.on("console", lambda m: logs.append(m.text))
    cdp = ctx.new_cdp_session(pg)
    pg.goto(url()); print("landscape ready_s", ready(pg, logs)); time.sleep(15)
    shot(pg, "web-first-start-phone-landscape")
    errs(logs, "landscape")
    ctx.close()
    b.close()

print("checks ok:", oks)
if fails:
    print("MENU WEB FAILED:", fails)
    sys.exit(1)
print("MENU WEB OK (%d checks), %d console errors" % (oks, len(errors)))
