"""Web check of the dialogue engine, the attendants, the Dillard's gate and the book reader
(design/godot-dialogue.md, design/godot-quests.md) in an exported build.

Usage: python3 wsq_webtest.py <build-url-path> <out-prefix>   (server on :8765 serving the repo root)
  e.g. python3 tools/qa/wsq_webtest.py prototypes/godot-mall/project/.scratch/builds/q/index.html /tmp/q/web
Runs, each in a fresh browser profile (wing 2, 1995):
  desktop: at the Pocket Change attendant, E talks; Enter / 2 / 2 / Enter… walks the right path; the
           Candy necklace is in mall-state-1995 and the flag in mall-flags-1; a reload keeps the flag
  phone (390 x 844, touch): the same conversation laid out at iPhone width; taps continue
  gate: walking into Dillard's stops with the message
  book: the paperback in the bag (seeded), I opens the bag, Enter reads, Enter turns, 1 chooses
Prints one line per run with its console errors, then ALL OK or FAILED.
"""
import json, os, sys, time
from playwright.sync_api import sync_playwright

path, out = sys.argv[1], sys.argv[2]
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"]
PC = "-104.0,68.9,-25,-6"     # the Pocket Change attendant's talk spot (the counter's north end), facing them
fails = []

def url(q):
    return f"http://127.0.0.1:8765/{path}?wing=2&{q}"

def ready(pg, t=400):
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
    return json.loads(s) if s else {}

def page(b, w, h, touch=False):
    ctx = b.new_context(viewport={"width": w, "height": h}, has_touch=touch, is_mobile=touch)
    pg = ctx.new_page(); logs = []
    pg.on("console", lambda m: logs.append(m.text))
    pg.set_default_timeout(180000)
    return ctx, pg, logs

def key(pg, k, wait=2.5):
    pg.keyboard.press(k); time.sleep(wait)

with sync_playwright() as p:
    b = p.chromium.launch(args=ARGS, **({"executable_path": os.environ["CHROMIUM"]} if os.environ.get("CHROMIUM") else {}))

    # ---- desktop: the right path
    ctx, pg, logs = page(b, 1280, 720)
    pg.goto(url(f"cam={PC}&npcs=0"))
    check(ready(pg), "desktop: loaded")
    pg.mouse.click(640, 200); time.sleep(1)       # focus the canvas
    shot(pg, "desktop-approach")
    key(pg, "e", 4.0)
    shot(pg, "desktop-face-line")
    key(pg, "Enter", 4.0)                          # line 2, the question, and its three responses
    shot(pg, "desktop-three-choices")
    key(pg, "2", 4.0)                              # line 3 and the second level
    key(pg, "Down", 1.0)
    shot(pg, "desktop-second-level")
    key(pg, "2", 4.0)                              # line 4
    key(pg, "Enter", 3.0)                          # line 5: the give has happened
    shot(pg, "desktop-give")
    key(pg, "Enter", 3.0)                          # END
    time.sleep(1)
    st = ls(pg, "mall-state-1995"); fl = ls(pg, "mall-flags-1")
    check(any(e.get("id") == "candy_neck" for e in st.get("inventory", [])), "desktop: the give put candy_neck in mall-state-1995")
    check(fl.get("flags", {}).get("placeholder_pocket_change_done") is True, "desktop: placeholder_pocket_change_done in mall-flags-1")
    shot(pg, "desktop-after")
    pg.reload(); ready(pg)
    check(ls(pg, "mall-flags-1").get("flags", {}).get("placeholder_pocket_change_done") is True, "desktop: the flag survives a reload")
    pg.mouse.click(640, 200); time.sleep(1)
    key(pg, "e", 4.0)
    shot(pg, "desktop-already-done")
    e = errors(logs); print("desktop errors", len(e), e[:5]); check(not e, "desktop: 0 console errors")
    ctx.close()

    # ---- phone portrait (iPhone width), touch
    ctx, pg, logs = page(b, 390, 844, touch=True)
    pg.goto(url(f"cam={PC}&npcs=0"))
    check(ready(pg), "phone: loaded")
    cdp = ctx.new_cdp_session(pg)
    def tap(x, y):
        cdp.send("Input.dispatchTouchEvent", {"type": "touchStart", "touchPoints": [{"x": x, "y": y, "id": 1}]}); time.sleep(0.1)
        cdp.send("Input.dispatchTouchEvent", {"type": "touchEnd", "touchPoints": []}); time.sleep(2.5)
    shot(pg, "phone-approach")
    key(pg, "e", 4.0)                               # (the Use button's place varies; the key starts it)
    shot(pg, "phone-face-line")
    tap(195, 400); time.sleep(2)                    # continue by tapping: line 2 and its responses
    shot(pg, "phone-three-choices")
    e = errors(logs); print("phone errors", len(e), e[:5]); check(not e, "phone: 0 console errors")
    ctx.close()

    # ---- the Dillard's gate
    ctx, pg, logs = page(b, 1280, 720)
    pg.goto(url("cam=-4,77.0,180,0&npcs=0"))
    check(ready(pg), "gate: loaded")
    pg.mouse.click(640, 200); time.sleep(1)
    pg.keyboard.down("w"); time.sleep(2.5); pg.keyboard.up("w"); time.sleep(0.3)
    shot(pg, "dillards-locked")
    e = errors(logs); print("gate errors", len(e), e[:5]); check(not e, "gate: 0 console errors")
    ctx.close()

    # ---- the book, from the bag
    ctx, pg, logs = page(b, 1280, 720)
    pg.goto(url("cam=-104,70,0,0&npcs=0"))
    ready(pg, 60)
    pg.evaluate("""localStorage.setItem('mall-state-1995', JSON.stringify({v:1, year:1995, inventory:[{id:'bl_bd_paperback', count:1}], tickets:0, hand:'', moved:{bl_bd_paperback:{}}}))""")
    pg.reload()
    check(ready(pg), "book: loaded")
    pg.mouse.click(640, 200); time.sleep(1)
    key(pg, "i", 2.0)
    shot(pg, "bag-read")
    key(pg, "Enter", 3.0)                         # the row's first button: Read
    shot(pg, "book-page")
    key(pg, "Enter", 2.0)
    shot(pg, "book-choices")
    key(pg, "1", 2.0); key(pg, "Enter"); key(pg, "Enter"); key(pg, "Enter")
    shot(pg, "book-end")
    check(ls(pg, "mall-flags-1").get("flags", {}).get("placeholder_book_finished") is True, "book: the ending set placeholder_book_finished")
    e = errors(logs); print("book errors", len(e), e[:5]); check(not e, "book: 0 console errors")
    ctx.close()
    b.close()

print("ALL OK" if not fails else "FAILED: " + str(fails))
