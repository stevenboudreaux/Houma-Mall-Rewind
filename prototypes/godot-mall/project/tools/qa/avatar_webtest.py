"""Workstream V (design/godot-avatar.md): the avatar in the web build, headless Chromium (swiftshader).

Usage: python3 tools/qa/avatar_webtest.py <url-path> <out-prefix>
  (server on :8765 serving the repo root; <url-path> e.g. prototypes/godot-mall/project/.scratch/builds/wsv/index.html?wing=2)
Checks, each in a fresh browser profile:
  1. desktop 1280x720, first visit: the creator opens by itself; Enter = Done; saved (done, third person);
     the third-person view; V = first person (saved); a reload keeps the look and the view.
  2. phone portrait 390x844 (touch), first visit: the creator fits; Escape = Skip gives the default
     avatar in first person; tapping the View button switches to third person.
  3. phone landscape 844x390 (touch) with ?view=third: the creator; a touch-drag walk moves the player.
  4. desktop with ?cam= (a test / shared spot): no creator.
Prints AVATAR WEB OK, or the failures; 0 console errors expected.
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
        if any("npcs:" in l or "fps" in l or "DBG" in l for l in logs) or pg.evaluate(
                "document.querySelector('#status') ? getComputedStyle(document.querySelector('#status')).display==='none' || getComputedStyle(document.querySelector('#status')).visibility==='hidden' : true"):
            return time.time() - t0
        time.sleep(1)
    return None

def saved(pg):
    s = pg.evaluate("localStorage.getItem('mall-avatar-1')")
    return json.loads(s) if s else None

def shot(pg, name):
    pg.screenshot(path=f"{out}-{name}.png", timeout=180000)

def errs(logs, where):
    e = [l for l in logs if "ERROR" in l.upper() or "SCRIPT ERROR" in l]
    errors.extend(e)
    check(not e, f"{where}: no console errors ({e[:2]})")

def key(pg, k, wait=1.5):
    pg.keyboard.press(k); time.sleep(wait)

with sync_playwright() as p:
    # CHROMIUM=/opt/pw-browsers/chromium when the Python Playwright has no browser of its own
    b = p.chromium.launch(args=ARGS, **({"executable_path": os.environ["CHROMIUM"]} if os.environ.get("CHROMIUM") else {}))
    # 1. desktop, first visit
    ctx = b.new_context(viewport={"width": 1280, "height": 720})
    pg = ctx.new_page(); logs = []
    pg.on("console", lambda m: logs.append(m.text))
    pg.goto(url())
    print("desktop ready_s", ready(pg, logs)); time.sleep(15)
    pg.mouse.move(640, 360)
    check(saved(pg) is None, "desktop: nothing saved before the creator closes")
    shot(pg, "creator-desktop")
    key(pg, "Enter", 3)
    s = saved(pg)
    check(s is not None and s.get("done") and s.get("view") == "third", f"desktop: Enter = Done, saved third person ({s and s.get('body')})")
    time.sleep(4); shot(pg, "tp-desktop")
    key(pg, "v", 3)
    s = saved(pg)
    check(s is not None and s.get("view") == "first", "desktop: V switches to first person and saves it")
    shot(pg, "fp-desktop")
    key(pg, "v", 1)
    pg.goto(url("cam=-20,54,90,-8")); ready(pg, logs); time.sleep(12)
    s2 = saved(pg)
    check(s2 is not None and s2.get("body") == s.get("body") and s2.get("view") == "third", "desktop: a reload keeps the look and the view")
    shot(pg, "tp-reload")
    errs(logs, "desktop")
    ctx.close()
    # 2. phone portrait, first visit, touch
    ctx = b.new_context(viewport={"width": 390, "height": 844}, has_touch=True, is_mobile=True)
    pg = ctx.new_page(); logs = []
    pg.on("console", lambda m: logs.append(m.text))
    pg.goto(url())
    print("portrait ready_s", ready(pg, logs)); time.sleep(15)
    shot(pg, "creator-phone-portrait")
    key(pg, "Escape", 3)
    s = saved(pg)
    check(s is not None and s.get("done") and s.get("view") == "first" and s.get("body") == "Ch01", f"phone: Skip = the default avatar, first person ({s})")
    # UI-OFFSCREEN (design/godot-menu.md): no View button on the game screen; the menu icon, then MAIN's View
    pg.touchscreen.tap(31, 29); time.sleep(3)
    pg.touchscreen.tap(201, 596); time.sleep(3)
    s = saved(pg)
    check(s is not None and s.get("view") == "third", "phone: tapping View switches to third person")
    shot(pg, "tp-phone-portrait")
    errs(logs, "phone portrait")
    ctx.close()
    # 3. phone landscape, third person, touch walk
    ctx = b.new_context(viewport={"width": 844, "height": 390}, has_touch=True, is_mobile=True)
    pg = ctx.new_page(); logs = []
    pg.on("console", lambda m: logs.append(m.text))
    pg.goto(url("avatar=1"))
    print("landscape ready_s", ready(pg, logs)); time.sleep(15)
    shot(pg, "creator-phone-landscape")
    key(pg, "Enter", 3)
    pg.goto(url("view=third&debug=1&cam=-20,54,90,-8")); ready(pg, logs); time.sleep(12)
    cdp = ctx.new_cdp_session(pg)
    def touch(t, x, y):
        cdp.send("Input.dispatchTouchEvent", {"type": t, "touchPoints": [] if t == "touchEnd" else [{"x": x, "y": y, "id": 1}]})
    before = [l for l in logs if l.startswith("DBG pos")][-1:]
    touch("touchStart", 200, 300); time.sleep(0.2)
    for i in range(1, 11):
        touch("touchMove", 200, 300 - i * 6); time.sleep(0.05)
    time.sleep(4)
    shot(pg, "tp-phone-walk")
    touch("touchEnd", 0, 0); time.sleep(3)
    after = [l for l in logs if l.startswith("DBG pos")][-1:]
    print("walk before", before, "after", after)
    check(before != after and bool(after), "phone landscape: a touch-drag walks in third person")
    shot(pg, "tp-phone-landscape")
    errs(logs, "phone landscape")
    ctx.close()
    # 4. a ?cam= link on a fresh profile: no creator, first person as before
    ctx = b.new_context(viewport={"width": 1280, "height": 720})
    pg = ctx.new_page(); logs = []
    pg.on("console", lambda m: logs.append(m.text))
    pg.goto(url("cam=-20,54,90,-8")); ready(pg, logs); time.sleep(12)
    check(saved(pg) is None, "a ?cam= link: no creator, nothing saved")
    shot(pg, "fp-camlink")
    errs(logs, "cam link")
    ctx.close()
    b.close()
print(("AVATAR WEB OK (%d checks)" % oks) if not fails else "AVATAR WEB FAILED: " + str(fails))
