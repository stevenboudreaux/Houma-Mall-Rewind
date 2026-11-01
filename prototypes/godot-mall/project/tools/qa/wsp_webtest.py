"""Web check of COIN COMET's in-mall hook (scripts/pusher_play.gd, workstream P).

Usage: python3 wsp_webtest.py <build-url-path> <out-prefix>   (server on :8765 serving the repo root)
  e.g. CHROMIUM=/opt/pw-browsers/chromium-1243/chrome-linux64/chrome \\
       python3 tools/qa/wsp_webtest.py prototypes/godot-mall/project/.scratch/builds/wsp/index.html /tmp/wsp/web
Runs, in one browser profile: wing 2 (1995) with the player at position 1 (the +x side) facing the
machine: the Play prompt shows (screenshot); E opens play/pusher.html?pos=1 in the game frame; the
page loads (its test hook), a drop pays a quarter into mall-state-1995; Back closes the frame and
the mall is back (screenshot). Then position 4 on the other side, by the touch Use button.
Prints one line per check, then ALL OK or FAILED.
"""
import json, os, sys, time
from playwright.sync_api import sync_playwright

path, out = sys.argv[1], sys.argv[2]
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"]
fails = []
# the six positions' fronts (tools/qa/pusher_play_test.gd): x of the front face, z of the centre
POS1 = (-105.68, 66.03)     # faces +x: the player stands at x + 0.8, looking toward -x (yaw 90)
POS4 = (-107.32, 64.97)     # faces -x: the player at x - 0.8, yaw 270


def url(q):
    return f"http://127.0.0.1:8765/{path}?{q}"


def ready(pg, t=300):
    t0 = time.time()
    while time.time() - t0 < t:
        if pg.evaluate("document.querySelector('#status') ? getComputedStyle(document.querySelector('#status')).display==='none' || getComputedStyle(document.querySelector('#status')).visibility==='hidden' : true"):
            time.sleep(12)
            return True
        time.sleep(1)
    return False


def check(ok, what):
    print(("ok   " if ok else "FAIL ") + what)
    if not ok:
        fails.append(what)


def frame_src(pg):
    return pg.evaluate("window.mallRoms && window.mallRoms.frame ? window.mallRoms.frame.src : ''")


def state(pg):
    s = pg.evaluate("localStorage.getItem('mall-state-1995') || ''")
    return json.loads(s) if s else {}


with sync_playwright() as p:
    b = p.chromium.launch(args=ARGS, **({"executable_path": os.environ["CHROMIUM"]} if os.environ.get("CHROMIUM") else {}))
    ctx = b.new_context(viewport={"width": 1280, "height": 720})
    pg = ctx.new_page(); logs = []
    pg.on("console", lambda m: logs.append(m.text))
    pg.set_default_timeout(180000)

    # ---- position 1, keyboard
    pg.goto(url(f"wing=2&cam={POS1[0] + 0.8:.2f},{POS1[1]:.2f},90,-20"))
    check(ready(pg), "wing 2 loaded at position 1")
    time.sleep(2)
    pg.screenshot(path=f"{out}-pos1-prompt.png")
    pg.keyboard.press("e"); time.sleep(3)
    src = frame_src(pg)
    check("pusher.html?pos=1" in src, "E opened the game frame: " + src.split("/")[-1])
    fr = next((f for f in pg.frames if "pusher.html" in f.url), None)
    check(fr is not None, "the frame is on the page")
    if fr:
        fr.wait_for_function("window.PUSHER_PAGE", timeout=180000)
        time.sleep(3)
        pg.screenshot(path=f"{out}-pos1-game.png")
        fr.evaluate("document.getElementById('msg').innerHTML = ''; PUSHER_PAGE.paused = false; PUSHER_PAGE.drop()")
        time.sleep(1)
        check(state(pg).get("quarters") == 19, "a drop in the frame paid a quarter into mall-state-1995 (%s)" % state(pg).get("quarters"))
        fr.evaluate("document.getElementById('back').click()")
        time.sleep(2)
    check(frame_src(pg) == "", "Back closed the frame: the mall is back")
    pg.screenshot(path=f"{out}-pos1-back.png")

    # ---- position 4, the other side, touch
    ctx2 = b.new_context(viewport={"width": 844, "height": 390}, has_touch=True, is_mobile=True)
    pg2 = ctx2.new_page(); pg2.set_default_timeout(180000)
    pg2.on("console", lambda m: logs.append(m.text))
    pg2.goto(url(f"wing=2&cam={POS4[0] - 0.8:.2f},{POS4[1]:.2f},270,-20"))
    check(ready(pg2), "wing 2 loaded at position 4 (phone)")
    cdp = ctx2.new_cdp_session(pg2)
    def tap(x, y):
        cdp.send("Input.dispatchTouchEvent", {"type": "touchStart", "touchPoints": [{"x": x, "y": y, "id": 1}]}); time.sleep(0.08)
        cdp.send("Input.dispatchTouchEvent", {"type": "touchEnd", "touchPoints": []}); time.sleep(0.35)
    tap(300, 200); time.sleep(1.5)
    pg2.screenshot(path=f"{out}-pos4-prompt.png")
    tap(844 - 80, 390 - 192); time.sleep(3)      # the round Use button (interact.gd)
    src = frame_src(pg2)
    check("pusher.html?pos=4" in src, "the Use button opened position 4: " + src.split("/")[-1])
    fr = next((f for f in pg2.frames if "pusher.html" in f.url), None)
    if fr:
        fr.wait_for_function("window.PUSHER_PAGE", timeout=180000)
        time.sleep(3)
        pg2.screenshot(path=f"{out}-pos4-game.png")
        fr.evaluate("document.getElementById('back').click()")
        time.sleep(2)
    check(frame_src(pg2) == "", "Back closed the frame (phone)")
    errs = [l for l in logs if "ERROR" in l.upper() and "favicon" not in l and "deprecated" not in l]
    print("errors", len(errs), errs[:3])
    check(not errs, "0 errors")
    b.close()

print("ALL OK" if not fails else "FAILED: " + "; ".join(fails))
sys.exit(1 if fails else 0)
