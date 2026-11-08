"""Web check of workstream CUCOS (design/godot-cucos.md) in an exported build (unbaked).

Usage: python3 tools/qa/cucos_webtest.py <build-url-path> <out-prefix>   (server on :8765 at the repo root)
  e.g. python3 tools/qa/cucos_webtest.py prototypes/godot-mall/project/.scratch/builds/cucos/index.html /tmp/cu/web
Runs (wing 1; owner mode only for the console helper mallLady(), which walks the player up to her):
  lady:    1995, a fresh profile: mallLady(), E talks, 2 / 1 / 3 down the Cuco's path; the coupon is in
           mall-state-1995 and cu_coupon_given in mall-flags-1
  bar:     the coupon put in the hand (saved state), a reload at the bar: E, Steven's lines, the coupon gone,
           the top-shelf margarita and the doubloon in the bag; E again: the shop; 1 buys a beer for $2.00
  repeat:  her flags survive a reload; a second Cuco's answer gives no second coupon
  2026:    the same profile in 2026: the doubloon is in mall-state-2026
  phone:   390 x 844, touch: her face shot and the three answers at iPhone width
Prints one line per check and the console errors of each run, then ALL OK or FAILED.
"""
import json, os, sys, time
from playwright.sync_api import sync_playwright

path, out = sys.argv[1], sys.argv[2]
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"]
BAR = "24.85,-75.35,90,-6"      # the bartender's talk spot, facing the bar (-x)
fails = []

def url(q):
    return f"http://127.0.0.1:8765/{path}?wing=1&owner=1&{q}"

def ready(pg, t=500):
    t0 = time.time()
    while time.time() - t0 < t:
        if pg.evaluate("document.querySelector('#status') ? getComputedStyle(document.querySelector('#status')).display==='none' || getComputedStyle(document.querySelector('#status')).visibility==='hidden' : true"):
            time.sleep(15)
            return True
        time.sleep(1)
    return False

def shot(pg, name):
    pg.screenshot(path=f"{out}-{name}.png", timeout=180000)

def errors(logs):
    return [l for l in logs if ("ERROR" in l.upper() or "SCRIPT ERROR" in l) and "favicon" not in l]

def check(ok, what):
    print(("ok   " if ok else "FAIL ") + what, flush=True)
    if not ok:
        fails.append(what)

def ls(pg, key):
    s = pg.evaluate(f"localStorage.getItem('{key}') || ''")
    try:
        return json.loads(s) if s else {}
    except ValueError:
        return s

def inv(pg, year=1995):
    st = ls(pg, f"mall-state-{year}")
    d = {e.get("id"): e.get("count") for e in st.get("inventory", [])}
    if st.get("hand"):
        d[st["hand"]] = d.get(st["hand"], 0) + 1
    return d

def flags(pg):
    return ls(pg, "mall-flags-1").get("flags", {})

def page(b, w, h, touch=False):
    ctx = b.new_context(viewport={"width": w, "height": h}, has_touch=touch, is_mobile=touch)
    pg = ctx.new_page(); logs = []
    pg.on("console", lambda m: logs.append(m.text))
    pg.set_default_timeout(180000)
    return ctx, pg, logs

def key(pg, k, wait=2.5):
    pg.keyboard.press(k); time.sleep(wait)

def find_lady(pg, tries=12):
    for i in range(tries):
        pg.evaluate("window.mallLadyAt = null; window.mallLady ? window.mallLady() : null")
        time.sleep(0.5)
        r = pg.evaluate("window.mallLady ? String(window.mallLadyAt) : 'nohelper'")
        print("  mallLady:", r, flush=True)
        if r and r not in ("nohelper", "null", ""):
            return r
        time.sleep(5)
    return ""

def talk_to_lady(pg, tag, answers):
    where = find_lady(pg)
    check(where != "", f"{tag}: the lady is in the crowd (at {where})")
    time.sleep(0.6)
    shot(pg, f"{tag}-approach")
    key(pg, "e", 20.0)             # swiftshader runs ~1 fps: let each line finish typing (a digit
    shot(pg, f"{tag}-face")        # pressed while it types is ignored; Enter would pick answer 1)
    for i, a in enumerate(answers):
        key(pg, a, 20.0)
        shot(pg, f"{tag}-after-{i + 1}")

with sync_playwright() as p:
    b = p.chromium.launch(args=ARGS, **({"executable_path": os.environ["CHROMIUM"]} if os.environ.get("CHROMIUM") else {}))

    # ---- the lady, down the Cuco's path
    ctx, pg, logs = page(b, 1280, 720)
    pg.goto(url("year=1995"))
    ready(pg, 60)
    pg.evaluate("localStorage.setItem('mall-opening-1', 'skipped'); localStorage.setItem('mall-player-2', JSON.stringify({v: 2, cast: 'placeholder_1', view: 'first'}))")   # past the opening (MENU)
    pg.reload()
    check(ready(pg), "lady: loaded")
    # she wanders: where another prompt owns the action button (the cinema doors, a seam door) E can't
    # reach her, so a failed try starts over from a clean story and bag
    for attempt in range(4):
        pg.mouse.click(640, 200); time.sleep(1)
        talk_to_lady(pg, "desktop-lady", ["2", "1", "3"])
        for i in range(4):         # the "You received" card, END
            key(pg, "Enter", 3.0)
        time.sleep(1)
        if inv(pg).get("cu_coupon") == 1:
            break
        print("  try %d: no coupon, again" % (attempt + 1), flush=True)
        pg.evaluate("localStorage.removeItem('mall-flags-1'); localStorage.removeItem('mall-state-1995')")
        pg.reload(); ready(pg)
    check(inv(pg).get("cu_coupon") == 1, "lady: the coupon is in mall-state-1995: " + str(inv(pg)))
    check(flags(pg).get("cu_coupon_given") is True, "lady: cu_coupon_given in mall-flags-1")
    shot(pg, "desktop-lady-after")

    # ---- a second time: no second coupon
    pg.keyboard.press("Escape"); time.sleep(1)
    talk_to_lady(pg, "desktop-lady-again", ["2", "1", "3"])
    key(pg, "Enter", 3.0); key(pg, "Enter", 3.0)
    check(inv(pg).get("cu_coupon") == 1, "repeat: still one coupon: " + str(inv(pg)))

    # ---- the coupon in the hand (as the bag's Hold does), at the bar after a reload
    pg.evaluate("""(function(){var k='mall-state-1995';var d=JSON.parse(localStorage.getItem(k)||'{"v":1,"year":1995,"inventory":[],"hand":"","moved":{}}');
        d.inventory=d.inventory.filter(function(e){return e.id!=='cu_coupon'});d.hand='cu_coupon';
        localStorage.setItem(k,JSON.stringify(d))})()""")
    pg.goto(url(f"year=1995&cam={BAR}"))
    check(ready(pg), "bar: loaded")
    check(flags(pg).get("cu_coupon_given") is True, "repeat: her flag survives the reload")
    pg.mouse.click(640, 200); time.sleep(1)
    shot(pg, "desktop-bar-approach")
    key(pg, "e", 6.0)
    shot(pg, "desktop-bar-coupon-line")
    key(pg, "Enter", 5.0)          # "Here you go." (the margarita's card)
    shot(pg, "desktop-bar-here-you-go")
    key(pg, "Enter", 5.0)          # the gift line (the doubloon)
    shot(pg, "desktop-bar-gift")
    key(pg, "Enter", 4.0)          # END
    for i in range(6):             # the two "You received" cards take a key each (swiftshader: ~1 fps)
        key(pg, "Enter", 3.0)
    iv = inv(pg)
    check("cu_coupon" not in iv, "bar: the coupon is used up: " + str(iv))
    check(iv.get("cu_topshelf") == 1 and iv.get("cu_doubloon") == 1, "bar: the top-shelf margarita and the doubloon: " + str(iv))
    check(flags(pg).get("cu_coupon_used") is True and flags(pg).get("cu_doubloon_given") is True, "bar: cu_coupon_used, cu_doubloon_given")
    money0 = int(pg.evaluate("localStorage.getItem('mall.money') || '10000'"))
    # ---- the shop: a beer
    key(pg, "e", 6.0)
    shot(pg, "desktop-shop-list")
    key(pg, "1", 6.0)
    shot(pg, "desktop-shop-bought")
    key(pg, "Enter", 3.0); key(pg, "Enter", 3.0); key(pg, "Escape", 2.0)
    money1 = int(pg.evaluate("localStorage.getItem('mall.money') || '0'"))
    check(money0 - money1 == 200 and inv(pg).get("cu_beer") == 1, f"shop: a beer for $2.00 (wallet {money0} -> {money1}): " + str(inv(pg)))
    e = errors(logs); print("1995 errors", len(e), e[:5]); check(not e, "1995: 0 console errors")

    # ---- 2026: the doubloon travels
    logs.clear()
    pg.goto(url("year=2026"))
    check(ready(pg), "2026: loaded")
    pg.mouse.click(640, 200); time.sleep(3)
    check(inv(pg, 2026).get("cu_doubloon") == 1, "2026: the doubloon is in mall-state-2026: " + str(inv(pg, 2026)))
    key(pg, "i", 2.5)
    shot(pg, "desktop-2026-bag")
    e = errors(logs); print("2026 errors", len(e), e[:5]); check(not e, "2026: 0 console errors")
    ctx.close()

    # ---- phone
    ctx, pg, logs = page(b, 390, 844, touch=True)
    pg.goto(url("year=1995"))
    ready(pg, 60)
    pg.evaluate("localStorage.setItem('mall-opening-1', 'skipped'); localStorage.setItem('mall-player-2', JSON.stringify({v: 2, cast: 'placeholder_1', view: 'first'}))")
    pg.reload()
    check(ready(pg), "phone: loaded")
    for attempt in range(4):       # she walks on between frames at ~1 fps: try again until E reaches her
        where = find_lady(pg)
        key(pg, "e", 20.0)
        shot(pg, "phone-lady-face")
        key(pg, "3", 20.0)         # C: "No, I don't watch football."
        shot(pg, "phone-lady-cold")
        if flags(pg).get("cu_lady_cold") is True:
            break
    check(where != "", f"phone: the lady is in the crowd (at {where})")
    check(flags(pg).get("cu_lady_cold") is True, "phone: talked at 390 x 844, answer C saved cu_lady_cold")
    e = errors(logs); print("phone errors", len(e), e[:5]); check(not e, "phone: 0 console errors")
    ctx.close()
    b.close()

print("ALL OK" if not fails else "FAILED: " + str(fails))
