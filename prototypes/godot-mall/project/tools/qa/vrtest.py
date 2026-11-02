"""Check the VR mode (scripts/vr.gd, design/godot-vr.md) in a headless browser with an emulated
Meta Quest 2 (IWER, Meta's WebXR emulator: `npm i iwer`, pass the path of iwer.min.js).

Usage: python3 vrtest.py <url-path> <out-prefix> <iwer.min.js> <webxr-layers-polyfill.min.js>
       (server on :8765 serving the repo root; `npm i iwer webxr-layers-polyfill`, each in build/)

Godot draws through WebXR Layers, which the Quest browser has and the emulator lacks, so the test
adds the layers polyfill. The live page does not ship it.

It cannot say how the mall runs or feels in a real headset. It checks the wiring:
  enter   - the Enter VR button shows, a press starts the session, the head stands where the
            flat camera stood at the headset's height, both eyes draw;
  walk    - the left stick walks the way the head faces; the right stick turns 30 degrees;
  menu    - B opens the menu; the stick and A jump to Sears;
  play    - at WHIRLWIND, A leaves VR and opens the game's flat page;
  seam    - at the seam, A loads the other wing and the page offers "Back into VR".
"""
import sys, time, json
from playwright.sync_api import sync_playwright

path, out, iwer, layers = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"]
INIT = open(iwer).read() + """
;(() => { const d = new IWER.XRDevice(IWER.metaQuest2); d.installRuntime({ forceInstall: true }); d.stereoEnabled = true;
  d.position.set(0.3, 1.7, 0.2); window.__xr = d; })();""" + open(layers).read() + ";new WebXRLayersPolyfill();"
ok_all = True
def check(name, cond, info=""):
    global ok_all
    ok_all = ok_all and bool(cond)
    print(("ok   " if cond else "FAIL ") + name, info)

def wait(pg, js, secs):
    t0 = time.time()
    while time.time() - t0 < secs:
        try:
            v = pg.evaluate(js)
            if v:
                return v
        except Exception:
            pass
        time.sleep(1)
    return None

def at(pg):
    time.sleep(1.5)
    return pg.evaluate("window.mallVR.at")

def press(pg, hand, btn, hold=1.2):
    pg.evaluate(f"window.__xr.controllers.{hand}.updateButtonValue('{btn}', 1)")
    time.sleep(hold)
    pg.evaluate(f"window.__xr.controllers.{hand}.updateButtonValue('{btn}', 0)")
    time.sleep(hold)

def stick(pg, hand, x, y, hold):
    pg.evaluate(f"window.__xr.controllers.{hand}.updateAxes('thumbstick', {x}, {y})")
    time.sleep(hold)
    pg.evaluate(f"window.__xr.controllers.{hand}.updateAxes('thumbstick', 0, 0)")
    time.sleep(1.0)

def start(b, query):
    ctx = b.new_context(viewport={"width": 1280, "height": 720})
    ctx.add_init_script(INIT)
    pg = ctx.new_page(); logs = []
    pg.on("console", lambda m: logs.append(m.text))
    pg.on("pageerror", lambda e: logs.append("PAGEERROR " + str(e)))
    pg.goto(f"http://127.0.0.1:8765/{path}?{query}")
    shown = wait(pg, "window.mallVR && window.mallVR.offered && getComputedStyle(document.getElementById('vr-enter')).display === 'block'", 400)
    return ctx, pg, logs, shown

def enter(pg):
    pg.evaluate("document.getElementById('vr-enter').click()")   # a real click waits on frames; headless draws 2 a second
    return wait(pg, "window.mallVR.state === 'in' && window.mallVR.at", 60)

def errors(logs):
    return [l for l in logs if "ERROR" in l or "SCRIPT" in l or "PAGEERROR" in l]

with sync_playwright() as p:
    b = p.chromium.launch(args=ARGS)
    # ---- enter, walk, turn, menu (wing 1, at the entrance looking west)
    ctx, pg, logs, shown = start(b, "cam=31,0,90,0&time=night")
    check("enter: button shows", shown)
    pg.screenshot(path=f"{out}-1-button.png", timeout=180000)
    a0 = enter(pg)
    check("enter: session starts", a0, a0)
    if a0:
        time.sleep(4); a0 = at(pg)
        check("enter: head stands at the camera's spot", abs(a0[0] - 31) < 0.1 and abs(a0[2]) < 0.1, a0)
        check("enter: head at the headset's height", abs(a0[1] - 1.7) < 0.05, a0)
        check("enter: faces the way the camera did", abs(a0[3] - 90) < 2, a0)
        check("enter: button hidden in VR", pg.evaluate("getComputedStyle(document.getElementById('vr-enter')).display") == "none")
        check("enter: the hint shows", "Left stick walks" in (pg.evaluate("window.mallVR.board") or ""))
        pg.screenshot(path=f"{out}-2-in-vr.png", timeout=180000)
        stick(pg, "left", 0, -1, 6)          # WebXR: pushing a stick away is -1
        a1 = at(pg)
        check("walk: forward goes west", a1[0] < a0[0] - 0.5 and abs(a1[2] - a0[2]) < 0.3, a1)
        stick(pg, "right", 1, 0, 2)
        a2 = at(pg)
        check("turn: one 30 degree snap to the right", abs(((a2[3] - a1[3] + 180) % 360 - 180) + 30) < 2, a2)
        check("turn: the head stays in place", abs(a2[0] - a1[0]) < 0.05 and abs(a2[2] - a1[2]) < 0.05, a2)
        press(pg, "right", "b-button")
        time.sleep(2)
        bd = pg.evaluate("window.mallVR.board") or ""
        check("menu: B opens it", "Menu" in bd and "Go to Sears" in bd and "Leave VR" in bd, json.dumps(bd))
        pg.screenshot(path=f"{out}-3-menu.png", timeout=180000)
        press(pg, "right", "a-button")
        a3 = at(pg); time.sleep(2); a3 = at(pg)
        check("menu: A jumps to Sears", abs(a3[0] + 4) < 0.1 and abs(a3[2] + 90) < 0.1 and abs(abs(a3[3]) - 180) < 2, a3)
        pg.screenshot(path=f"{out}-4-sears.png", timeout=180000)
        press(pg, "left", "y-button")
        stick(pg, "left", 0, -1, 1.5)          # up from the first line wraps to the last: Leave VR
        bd = pg.evaluate("window.mallVR.board") or ""
        check("menu: stick up selects Leave VR", "›  Leave VR" in bd, json.dumps(bd))
        press(pg, "right", "trigger", 1.5)
        left = wait(pg, "window.mallVR.state === 'out'", 30)
        check("menu: Leave VR ends the session and shows the button", left and pg.evaluate("getComputedStyle(document.getElementById('vr-enter')).display") == "block")
        time.sleep(3)
        pg.screenshot(path=f"{out}-5-left.png", timeout=180000)
        again = enter(pg)
        check("enter: a second time works", again, again)
    check("no errors (wing 1)", not errors(logs), errors(logs)[:5])
    ctx.close()
    # ---- play a machine (wing 2, at WHIRLWIND's console)
    ctx, pg, logs, shown = start(b, "wing=2&cam=-106.3,60.6,180,-25&time=night")
    check("play: button shows in wing 2", shown)
    if shown and enter(pg):
        got = wait(pg, "(window.mallVR.board || '').indexOf('PLAY') >= 0 && window.mallVR.board", 30)
        check("play: the board offers the game", got, json.dumps(got))
        pg.screenshot(path=f"{out}-6-whirlwind.png", timeout=180000)
        press(pg, "right", "a-button")
        opened = wait(pg, "window.mallVR.state === 'out' && window.mallRoms.frame && window.mallRoms.frame.src", 30)
        check("play: A leaves VR and opens the flat game", opened and "whirlwind.html" in opened, opened)
        check("play: no Enter VR over the game", pg.evaluate("getComputedStyle(document.getElementById('vr-enter')).display") == "none")
    check("no errors (wing 2)", not errors(logs), errors(logs)[:5])
    ctx.close()
    # ---- cross the seam (wing 1, standing just before it, facing it)
    seam = json.load(open("gen/w1/wing.json"))["seam"]
    sx, sz = (seam[0] + seam[2]) / 2, seam[1] - 1.5
    ctx, pg, logs, shown = start(b, f"cam={sx},{sz},180,0&time=night")
    if shown and enter(pg):
        got = wait(pg, "(window.mallVR.board || '').indexOf('Enter Wing 2') >= 0", 30)
        check("seam: the board offers the other wing", got, pg.evaluate("window.mallVR.board"))
        pg.screenshot(path=f"{out}-7-seam.png", timeout=180000)
        press(pg, "right", "a-button", 0.6)
        back = wait(pg, "new URLSearchParams(location.search).get('wing') === '2' && window.mallVR && window.mallVR.offered && document.getElementById('vr-enter').textContent", 400)
        check("seam: wing 2 loads and offers to go back into VR", back == "Back into VR", back)
        pg.screenshot(path=f"{out}-8-arrived.png", timeout=180000)
        a = enter(pg)
        check("seam: back in VR in wing 2, past the seam", a and a[2] > seam[1], a)
    check("no errors (seam)", not errors(logs), errors(logs)[:5])
    ctx.close()
    # ---- workstream S (Nov 2 2026): the Sears opening, wing 1 -> wing 4 (design/godot-wings.md "Wings 4-6")
    ctx, pg, logs, shown = start(b, "cam=-4,-94.6,0,0&time=night")
    if shown and enter(pg):
        got = wait(pg, "(window.mallVR.board || '').indexOf('Enter Sears') >= 0", 30)
        check("threshold: the board offers Sears", got, pg.evaluate("window.mallVR.board"))
        pg.screenshot(path=f"{out}-9-sears-threshold.png", timeout=180000)
        press(pg, "right", "a-button", 0.6)
        back = wait(pg, "new URLSearchParams(location.search).get('wing') === '4' && window.mallVR && window.mallVR.offered && document.getElementById('vr-enter').textContent", 400)
        check("threshold: wing 4 loads and offers to go back into VR", back == "Back into VR", back)
        a = enter(pg)
        check("threshold: back in VR in wing 4, inside Sears", a and a[2] < -96.0, a)
        pg.screenshot(path=f"{out}-10-in-sears.png", timeout=180000)
    check("no errors (threshold)", not errors(logs), errors(logs)[:5])
    ctx.close(); b.close()
print("ALL OK" if ok_all else "SOME FAILED")
sys.exit(0 if ok_all else 1)
