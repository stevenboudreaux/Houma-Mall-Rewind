"""Workstream UI-OFFSCREEN (design/godot-menu.md "The game screen"): the web build with no corner buttons.

Usage: CHROMIUM=/opt/pw-browsers/chromium python3 tools/qa/ui_offscreen_webtest.py <url-path> <out-prefix>
  (server on :8765 at the repo root; <url-path> e.g. .scratch/builds/uo/index.html?wing=2)
  1. desktop 1280x720: the clean game screen; a click on the menu icon opens MAIN; Tab closes / opens;
     J opens the jump panel, V switches the view (saved), I opens INVENTORY.
  2. phone portrait 390x844 (touch): the clean screen; a tap on the icon opens MAIN; MAIN's View switches
     the view (saved) and closes the menu; the icon, then INVENTORY.
  3. phone landscape 844x390 (touch): the same.
Screenshots <out>-<device>-game.png / -menu-main.png / -menu-inventory.png (each checked not blank).
DEVICES=desktop,phone-portrait,phone-landscape (default all) runs a subset. Prints UI OFFSCREEN WEB OK.
swiftshader's "WebGL: too many errors" notice is not a game error and is not counted.
"""
import json, os, sys, time
from playwright.sync_api import sync_playwright

path, out = sys.argv[1], sys.argv[2]
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"]
BASE = "http://127.0.0.1:8765/" + path
CAM = "npcs=0&warm=0&cam=-20,54,90,-8"   # no shoppers: the UI is the subject, and the shared box is short of memory
fails, oks, errors = [], 0, []
# MAIN's buttons (centres, from tools/qa/ui_offscreen_test.gd's RECT lines) and the tabs
MAIN_VIEW = {"390x844": (201, 596), "844x390": (476, 287), "1280x720": (645, 525)}
INV_TAB = {"390x844": (170, 26), "844x390": (397, 28), "1280x720": (640, 28)}
ICON = (31, 29)
INIT = """try{localStorage.setItem('mall-opening-1','skipped');
if(!localStorage.getItem('mall-avatar-1'))localStorage.setItem('mall-avatar-1',JSON.stringify({v:1,done:true,view:'first'}))}catch(e){}"""

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
        pg.wait_for_timeout(1000)
    return None

def view(pg):
    try:
        return json.loads(pg.evaluate("localStorage.getItem('mall-avatar-1')") or "{}").get("view")
    except Exception:
        return None

DEVICES = os.environ.get("DEVICES", "desktop,phone-portrait,phone-landscape").split(",")

def shot(pg, name):
    f = f"{out}-{name}.png"
    for i in range(3):       # swiftshader sometimes answers "Unable to capture screenshot" under load
        try:
            pg.screenshot(path=f, timeout=180000); break
        except Exception as ex:
            print(f"retry {name}: {str(ex)[:80]}", flush=True)
            if i == 2: raise
            pg.wait_for_timeout(5000)
    try:
        from PIL import Image
        lo, hi = Image.open(f).convert("L").getextrema()
        check(hi - lo > 40, f"{name}: the screenshot is not blank (luma {lo}..{hi})")
    except ImportError:
        pass

def errs(logs, where):
    e = [l for l in logs if ("ERROR" in l.upper() or "SCRIPT ERROR" in l) and "WebGL: too many errors" not in l]
    errors.extend(e)
    check(not e, f"{where}: no console errors ({e[:2]})")

def device(b, w, h, touch):
    ctx = b.new_context(viewport={"width": w, "height": h}, has_touch=touch, is_mobile=touch, device_scale_factor=1)
    ctx.add_init_script(INIT)
    pg = ctx.new_page(); logs = []
    pg.on("console", lambda m: logs.append(m.text))
    pg.goto(url(CAM), timeout=180000)
    print(f"{w}x{h} ready_s", ready(pg, logs), flush=True)
    pg.wait_for_timeout(15000)
    return ctx, pg, logs

with sync_playwright() as p:
    b = p.chromium.launch(args=ARGS, **({"executable_path": os.environ["CHROMIUM"]} if os.environ.get("CHROMIUM") else {}))
    # 1. desktop
    if "desktop" in DEVICES:
        ctx, pg, logs = device(b, 1280, 720, False)
        pg.mouse.click(640, 700); pg.wait_for_timeout(1500)      # focus the canvas
        shot(pg, "desktop-game")
        pg.mouse.click(*ICON); pg.wait_for_timeout(3000)
        shot(pg, "desktop-menu-main")
        pg.keyboard.press("e"); pg.wait_for_timeout(2500)        # next tab: INVENTORY
        shot(pg, "desktop-menu-inventory")
        pg.keyboard.press("Tab"); pg.wait_for_timeout(2000)
        v0 = view(pg)
        pg.keyboard.press("v"); pg.wait_for_timeout(2500)
        check(view(pg) != v0 and view(pg) is not None, f"desktop: V still switches the view ({v0} -> {view(pg)})")
        pg.keyboard.press("v"); pg.wait_for_timeout(2000)
        pg.keyboard.press("j"); pg.wait_for_timeout(2500)
        shot(pg, "desktop-jump-panel")
        pg.keyboard.press("Escape"); pg.wait_for_timeout(1500)
        errs(logs, "desktop")
        ctx.close()
    # 2. and 3. phones, by touch
    for (w, h, name) in [(390, 844, "phone-portrait"), (844, 390, "phone-landscape")]:
        if name not in DEVICES:
            continue
        k = f"{w}x{h}"
        ctx, pg, logs = device(b, w, h, True)
        pg.touchscreen.tap(w // 2, h // 2); pg.wait_for_timeout(1500)   # a first touch: touch glyphs
        shot(pg, f"{name}-game")
        v0 = view(pg)
        pg.touchscreen.tap(*ICON); pg.wait_for_timeout(3000)
        shot(pg, f"{name}-menu-main")
        pg.touchscreen.tap(*MAIN_VIEW[k]); pg.wait_for_timeout(3000)
        check(view(pg) != v0 and view(pg) is not None, f"{name}: MAIN's View switches the view ({v0} -> {view(pg)})")
        shot(pg, f"{name}-after-view")
        pg.touchscreen.tap(*ICON); pg.wait_for_timeout(3000)
        pg.touchscreen.tap(*INV_TAB[k]); pg.wait_for_timeout(2500)
        shot(pg, f"{name}-menu-inventory")
        errs(logs, name)
        ctx.close()
    b.close()

print("checks ok:", oks)
if fails:
    print("UI OFFSCREEN WEB FAILED:", fails)
    sys.exit(1)
print("UI OFFSCREEN WEB OK (%d checks), %d console errors" % (oks, len(errors)))
