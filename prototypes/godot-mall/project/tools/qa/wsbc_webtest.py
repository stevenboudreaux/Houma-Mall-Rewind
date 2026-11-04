"""Web check of the interaction system, the bag and the owner-only HUD (design/godot-interaction.md).

Usage: python3 wsbc_webtest.py <build-url-path> <out-prefix>   (server on :8765 serving the repo root)
  e.g. python3 tools/qa/wsbc_webtest.py prototypes/godot-mall/project/.scratch/builds/bc/index.html /tmp/bc/web
Runs, each in a fresh browser profile:
  desktop visitor: HUD, the prompt at a loose prize, E picks it up (held), I opens the bag, reload keeps it
  desktop owner (?owner=1): HUD with fps and toggles
  phone visitor (844 x 390, touch): the touch Use button, tap it, tap Bag, a touch-drag walk
  phone portrait (390 x 844): the bag
  phone secret: at the restroom-hall dead end, swipes U U D D L R L R and two taps unlock owner mode
Prints one line per run with its console errors, then ALL OK or FAILED.
"""
import json, os, re, sys, time
from playwright.sync_api import sync_playwright

path, out = sys.argv[1], sys.argv[2]
HERE = os.path.dirname(os.path.abspath(__file__))
ITEMS = json.load(open(os.path.join(HERE, "../../data/items/pocket_change.json")))["items"]
SPRING = next(i for i in ITEMS if i["id"] == "spring")["place"]["pos"]
POGS = next(i for i in ITEMS if i["id"] == "pogs")["place"]["pos"]
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"]
fails = []

def url(q):
    return f"http://127.0.0.1:8765/{path}?{q}"

def cam_facing(pos, back=1.0, pitch=-35):
    return f"{pos[0] + back:.2f},{pos[2]:.2f},90,{pitch}"

def ready(pg, logs, t=300):
    t0 = time.time()
    while time.time() - t0 < t:
        if pg.evaluate("document.querySelector('#status') ? getComputedStyle(document.querySelector('#status')).display==='none' || getComputedStyle(document.querySelector('#status')).visibility==='hidden' : true"):
            time.sleep(12)
            return True
        time.sleep(1)
    return False

def shot(pg, name):
    pg.screenshot(path=f"{out}-{name}.png", timeout=180000)

def errors(logs):
    return [l for l in logs if "ERROR" in l.upper() and "favicon" not in l]

def check(ok, what):
    print(("ok   " if ok else "FAIL ") + what)
    if not ok:
        fails.append(what)

def state(pg):
    s = pg.evaluate("localStorage.getItem('mall-state-1995') || ''")
    return json.loads(s) if s else {}

def page(b, w, h, touch=False):
    ctx = b.new_context(viewport={"width": w, "height": h}, has_touch=touch, is_mobile=touch)
    pg = ctx.new_page(); logs = []
    pg.on("console", lambda m: logs.append(m.text))
    pg.set_default_timeout(180000)
    return ctx, pg, logs

def taps(ctx, pg):
    cdp = ctx.new_cdp_session(pg)
    def t(kind, x=0, y=0, i=1):
        pts = [] if kind == "touchEnd" else [{"x": x, "y": y, "id": i}]
        cdp.send("Input.dispatchTouchEvent", {"type": kind, "touchPoints": pts})
    def tap(x, y):
        t("touchStart", x, y); time.sleep(0.08); t("touchEnd"); time.sleep(0.35)
    def swipe(x0, y0, x1, y1):
        t("touchStart", x0, y0)
        for k in range(1, 6):
            time.sleep(0.03); t("touchMove", x0 + (x1 - x0) * k / 5, y0 + (y1 - y0) * k / 5)
        time.sleep(0.03); t("touchEnd"); time.sleep(0.3)
    return t, tap, swipe

with sync_playwright() as p:
    # CHROMIUM=/opt/pw-browsers/chromium when the Python Playwright has no browser of its own
    b = p.chromium.launch(args=ARGS, **({"executable_path": os.environ["CHROMIUM"]} if os.environ.get("CHROMIUM") else {}))

    # ---- desktop visitor
    ctx, pg, logs = page(b, 1280, 720)
    pg.goto(url(f"wing=2&cam={cam_facing(SPRING)}"))
    check(ready(pg, logs), "desktop visitor loaded")
    shot(pg, "desktop-visitor-prompt")
    pg.keyboard.press("e"); time.sleep(2)
    pg.goto(url(f"wing=2&cam={cam_facing(POGS, 1.0, -5)}")); ready(pg, logs)
    check(state(pg).get("hand") == "spring", "E picked up the spring; a reload still holds it")
    shot(pg, "desktop-visitor-held")
    pg.keyboard.press("i"); time.sleep(2)
    shot(pg, "desktop-visitor-bag")
    pg.keyboard.press("i"); time.sleep(1)
    print("desktop visitor errors", len(errors(logs)), errors(logs)[:3])
    check(not errors(logs), "desktop visitor: 0 errors")
    ctx.close()

    # ---- desktop owner
    ctx, pg, logs = page(b, 1280, 720)
    pg.goto(url(f"wing=2&owner=1&cam={cam_facing(SPRING)}"))
    check(ready(pg, logs), "desktop owner loaded")
    time.sleep(2)
    shot(pg, "desktop-owner")
    print("desktop owner errors", len(errors(logs)), errors(logs)[:3])
    check(not errors(logs), "desktop owner: 0 errors")
    ctx.close()

    # ---- phone visitor, landscape
    ctx, pg, logs = page(b, 844, 390, True)
    pg.goto(url(f"wing=2&debug=1&cam={cam_facing(POGS)}"))
    check(ready(pg, logs), "phone visitor loaded")
    t, tap, swipe = taps(ctx, pg)
    tap(300, 200); time.sleep(1.5)        # a first touch: the game now shows touch glyphs
    shot(pg, "phone-visitor-use")
    tap(844 - 80, 390 - 192); time.sleep(1.5)   # the round Use button
    check(state(pg).get("inventory", [{}])[0].get("id") == "pogs", "phone: the Use button took the Pog pack")
    # UI-OFFSCREEN (design/godot-menu.md): no Bag button on the game screen; the menu icon, then INVENTORY
    tap(31, 29); time.sleep(2)            # the menu icon (top left)
    tap(397, 28); time.sleep(1.5)         # the INVENTORY tab
    shot(pg, "phone-visitor-bag")
    tap(844 - 34, 28); time.sleep(1)      # the menu's close button
    # a touch-drag walk (movetest's)
    before = [l for l in logs if l.startswith("DBG")][-1:]
    t("touchStart", 200, 300); time.sleep(0.2)
    for i in range(1, 11):
        t("touchMove", 200, 300 - i * 6); time.sleep(0.05)
    time.sleep(4)
    during = [l for l in logs if l.startswith("DBG")][-1:]
    t("touchEnd"); time.sleep(1)
    pos = lambda s: re.search(r"pos=\(([^)]*)\)", s[0]).group(1) if s else None
    check(pos(before) is not None and pos(before) != pos(during), "phone: touch-drag walk moved")
    print("phone visitor errors", len(errors(logs)), errors(logs)[:3])
    check(not errors(logs), "phone visitor: 0 errors")
    ctx.close()

    # ---- phone portrait: the bag at its narrowest
    ctx, pg, logs = page(b, 390, 844, True)
    pg.goto(url(f"wing=2&cam={cam_facing(SPRING)}"))
    check(ready(pg, logs), "phone portrait loaded")
    t, tap, swipe = taps(ctx, pg)
    tap(200, 500); time.sleep(1)
    shot(pg, "phone-portrait-use")
    tap(390 - 80, 844 - 192); time.sleep(1.5)
    tap(31, 29); time.sleep(2)            # UI-OFFSCREEN: the menu icon, then the INVENTORY tab
    tap(170, 26); time.sleep(1.5)
    shot(pg, "phone-portrait-bag")
    check(not errors(logs), "phone portrait: 0 errors")
    ctx.close()

    # ---- phone secret code at the restroom-hall dead end
    ctx, pg, logs = page(b, 844, 390, True)
    pg.goto(url("wing=1&cam=-49.0,91.0,0,0"))
    check(ready(pg, logs), "phone secret loaded")
    t, tap, swipe = taps(ctx, pg)
    shot(pg, "phone-secret-spot")
    cx, cy = 620, 200
    for d in "UUDDLRLR":
        dx, dy = {"U": (0, -110), "D": (0, 110), "L": (-110, 0), "R": (110, 0)}[d]
        swipe(cx - dx // 2, cy - dy // 2, cx + dx // 2, cy + dy // 2)
    tap(cx, cy); time.sleep(1.0); tap(cx, cy)
    t0 = time.time()
    while time.time() - t0 < 90 and not any("owner: secret code" in l for l in logs):
        time.sleep(1)       # a software-rendered browser handles touches seconds late
    hit = any("owner: secret code" in l for l in logs)
    check(hit, "phone: the swipe code is recognised at the spot")
    time.sleep(8)
    ed = pg.evaluate("localStorage.getItem('southland-editor')")
    check(ed == "1", "phone: owner mode is on (southland-editor = %r)" % ed)
    ctx.close()
    b.close()

print("ALL OK" if not fails else "FAILED: " + "; ".join(fails))
