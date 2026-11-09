"""Workstream UI-OFFSCREEN (design/godot-menu.md "The game screen"): the web build with no corner buttons.

Usage: CHROMIUM=/opt/pw-browsers/chromium python3 tools/qa/ui_offscreen_webtest.py <url-path> <out-prefix>
  (server on :8765 at the repo root; <url-path> e.g. .scratch/builds/uo/index.html?wing=2)
  1. desktop 1280x720: the clean game screen with no menu icon (Steven, Nov 4: touch devices only; the
     corner pixels match before and after a click there); Esc opens MAIN; Tab closes;
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
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist",
        "--disk-cache-size=1"]   # the packs are kept in Cache Storage anyway; the shared box is short of disk
BASE = "http://127.0.0.1:8765/" + path
CAM = "npcs=0&warm=0&cam=-20,54,90,-8"   # no shoppers: the UI is the subject, and the shared box is short of memory
fails, oks, errors = [], 0, []
# MAIN's buttons (centres, from tools/qa/ui_offscreen_test.gd's RECT lines) and the tabs
MAIN_VIEW = {"390x844": (83, 669), "844x390": (326, 363), "1280x720": (487, 623)}   # CHAR-STRIP layout (ui_offscreen_test.gd RECT lines, Nov 8)
INV_TAB = {"390x844": (170, 26), "844x390": (397, 28), "1280x720": (640, 28)}
ICON = (31, 29)
INIT = """try{localStorage.setItem('mall-opening-1','skipped');
if(!localStorage.getItem('mall-player-2'))localStorage.setItem('mall-player-2',JSON.stringify({v:2,cast:'placeholder_1',view:'first'}))}catch(e){}"""

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
        return json.loads(pg.evaluate("localStorage.getItem('mall-player-2')") or "{}").get("view")   # CHAR-STRIP
    except Exception:
        return None

DEVICES = os.environ.get("DEVICES", "desktop,phone-portrait,phone-landscape").split(",")

def shot(pg, name):
    im = _img(pg)
    check(im is not None, f"{name}: the screenshot is not blank")
    if im is not None:
        im.save(f"{out}-{name}.png")

def _img(pg):
    """A screenshot that isn't blank: swiftshader under load sometimes hands back an all-black frame
    (the game still runs), so try again a few times; None when every try is blank."""
    from io import BytesIO
    from PIL import Image
    for i in range(5):
        try:
            im = Image.open(BytesIO(pg.screenshot(timeout=180000))).convert("RGB")
            lo, hi = im.convert("L").getextrema()
            if hi - lo > 40:
                return im
        except Exception as ex:
            print(f"retry shot: {str(ex)[:80]}", flush=True)
        pg.wait_for_timeout(3000)
    return None

def corner(pg):
    """The icon's three white bars: bright pixels in the 42 px square top left (None when every shot is blank)."""
    im = _img(pg)
    if im is None:
        return None
    im = im.crop((10, 8, 52, 50))
    return sum(1 for p in im.getdata() if min(p) > 200)

def has_icon(n):
    return n is not None and n > 30

def menu_open(pg):
    """MAIN's tab is amber (the selected tab) in the top row."""
    im = _img(pg)
    if im is None:
        return False
    w = im.size[0]
    row = [im.getpixel((x, 28)) for x in range(12, min(w // 3, 400), 4)]
    return sum(1 for (r, g, b) in row if r > 190 and 130 < g < 190 and b < 90) > 10

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
        a = corner(pg)
        pg.mouse.click(*ICON); pg.wait_for_timeout(3000)     # nothing there on a desktop
        b2 = corner(pg)
        check(a is not None and not has_icon(a), "desktop: no menu icon top left")
        check(b2 is not None and not has_icon(b2), "desktop: a click where the icon would be opens nothing")
        pg.keyboard.press("Escape"); pg.wait_for_timeout(3000)
        shot(pg, "desktop-menu-main")
        check(menu_open(pg), "desktop: Esc opens the menu (the tab row is drawn)")
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
        a = corner(pg)
        check(a is not None and has_icon(a), f"{name}: the menu icon is drawn top left")
        pg.touchscreen.tap(*ICON); pg.wait_for_timeout(3000)
        shot(pg, f"{name}-menu-main")
        check(menu_open(pg), f"{name}: a tap on the icon opens the menu (the tab row is drawn)")
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
