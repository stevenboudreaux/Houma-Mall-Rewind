"""CHAR-STRIP (Nov 8 2026; design/godot-avatar.md "The counting test"): the player's character in the web
build, headless Chromium (swiftshader), one browser at a time. The web half of tools/qa/cast_count_test.gd
(which also does the time-travel trip natively). Replaces V's creator test (the creator is gone).

Usage: python3 tools/qa/avatar_webtest.py <url-path> <out-prefix>
  (server on :8765 at the repo root; <url-path> e.g. .scratch/builds/strip/index.html)
The game runs with ?debug=1, which prints "CASTCOUNT skel=<n> body=<id> saved=<id>" once a second
(scripts/avatar.gd) and "CASTPORTRAIT id=<id>" when MAIN is built (scripts/menu/menu.gd).
  0. the old records (mall-avatar-1, mall-avatar-preset-1 with a name) are planted before the first load:
     they must be gone after it and the name must be in mall.player_name;
  1. load (wing WING, third person): one skeleton, the default cast member;
  2. Tab, the Character row (d-pad down, right, Enter): the second cast member is saved and worn, MAIN's
     portrait shows it; Tab closes; still one;
  3. a reload: the same id, one skeleton;
  4. a wing crossing (window.mallGoWing, as scripts/player.gd _go_to_wing does): frames every 0.5 s from
     before the crossing to after (<out>-crossing-NN.png), one skeleton on the other side;
  5. a year crossing (?year=2026): the same id, one skeleton;
  6. a phone (390x844, touch): MAIN's Character row tapped.
Prints AVATAR WEB OK (n checks) or the failures. swiftshader's WebGL notices are not counted as errors.
"""
import json, os, re, sys, time
from playwright.sync_api import sync_playwright

path, out = sys.argv[1], sys.argv[2]
WING = int(os.environ.get("WING", "1"))
OTHER = int(os.environ.get("OTHER", "2"))
CAMS = {1: "30,0,90,-8", 2: "-20,54,90,-8", 4: "0,0,0,-8", 6: "0,0,0,-8"}   # a hall spot per wing
CAM = os.environ.get("CAM", "npcs=0")
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist", "--disk-cache-size=1"]
BASE = "http://127.0.0.1:8765/" + path
fails, oks = [], 0
OLD = """try{localStorage.setItem('mall-opening-1','skipped');
localStorage.setItem('mall-avatar-1',JSON.stringify({v:1,done:true,view:'third',body:'Ch21'}));
localStorage.setItem('mall-avatar-preset-1',JSON.stringify({id:'',name:'OLDNAME',body:'female'}));}catch(e){}"""

def url(q):
    return BASE + ("&" if "?" in BASE else "?") + q

def check(ok, what):
    global oks
    print(("ok   " if ok else "FAIL ") + what, flush=True)
    if ok: oks += 1
    else: fails.append(what)

def ls(pg, k):
    return pg.evaluate(f"localStorage.getItem({json.dumps(k)})")

def ready(pg, logs, t=420):
    t0 = time.time()
    while time.time() - t0 < t:
        if any(l.startswith("CASTCOUNT") for l in logs):
            return time.time() - t0
        pg.wait_for_timeout(1000)
    return None

def counts(logs, n=3, t=40, pg=None):
    """The last n CASTCOUNT lines (waits for n new ones)."""
    have = len([l for l in logs if l.startswith("CASTCOUNT")])
    t0 = time.time()
    while time.time() - t0 < t and len([l for l in logs if l.startswith("CASTCOUNT")]) < have + n:
        pg.wait_for_timeout(500)
    out_ = []
    for l in [l for l in logs if l.startswith("CASTCOUNT")][-n:]:
        m = re.match(r"CASTCOUNT skel=(\d+) body=(\S+) saved=(\S+)", l)
        if m: out_.append((int(m.group(1)), m.group(2), m.group(3)))
    return out_

def one(logs, pg, step, want_id=None):
    c = counts(logs, 3, pg=pg)
    allc = [x for l in logs if l.startswith("CASTCOUNT") for x in [int(re.search(r"skel=(\d+)", l).group(1))]]
    check(len(c) > 0 and all(x[0] == 1 for x in c), f"{step}: exactly one player skeleton ({[x[0] for x in c]})")
    check(len(c) > 0 and all(x[1] == x[2] for x in c), f"{step}: the body is the saved cast id ({c[-1][1:] if c else '-'})")
    if want_id:
        check(len(c) > 0 and c[-1][2] == want_id, f"{step}: saved = {want_id}")
    check(max(allc or [0]) <= 1, f"{step}: never two in any report so far (max {max(allc or [0])})")
    return c[-1][1] if c else None

def shot(pg, name):
    try:
        pg.screenshot(path=f"{out}-{name}.png", timeout=180000)
    except Exception as ex:
        print("shot failed", name, str(ex)[:80])

def key(pg, k, wait=1.0):
    pg.keyboard.press(k); pg.wait_for_timeout(int(wait * 1000))

def portrait(logs):
    p = [l for l in logs if l.startswith("CASTPORTRAIT")]
    return p[-1].split("=", 1)[1] if p else None

def errors(logs):
    return [l for l in logs if ("ERROR" in l or "SCRIPT ERROR" in l) and "WebGL" not in l and "GL_INVALID" not in l]

with sync_playwright() as p:
    b = p.chromium.launch(args=ARGS, **({"executable_path": os.environ["CHROMIUM"]} if os.environ.get("CHROMIUM") else {}))
    ctx = b.new_context(viewport={"width": 1280, "height": 720})
    pg = ctx.new_page(); logs = []
    pg.on("console", lambda m: logs.append(m.text))
    # 0. the old records, planted on the page's origin before the game runs
    pg.goto(url(f"wing={WING}&view=third&debug=1&{CAM}&cam={CAMS[WING]}&warm=0"), wait_until="commit")
    pg.evaluate(OLD)
    pg.goto(url(f"wing={WING}&view=third&debug=1&{CAM}&cam={CAMS[WING]}"))
    print("load ready_s", ready(pg, logs), flush=True)
    pg.wait_for_timeout(4000)
    check(ls(pg, "mall-avatar-1") is None and ls(pg, "mall-avatar-preset-1") is None, "the old avatar records are deleted")
    check(ls(pg, "mall.player_name") == "OLDNAME", f"the name came over ({ls(pg, 'mall.player_name')})")
    first = one(logs, pg, "load", "placeholder_1")
    shot(pg, "load-third")
    # 2. the Character row by keys
    pg.mouse.click(640, 700); pg.wait_for_timeout(800)
    key(pg, "Tab", 3)
    check(portrait(logs) == "placeholder_1", f"MAIN's portrait = the saved id ({portrait(logs)})")
    shot(pg, "menu-main-before")
    key(pg, "ArrowDown", 0.6); key(pg, "ArrowRight", 0.6); key(pg, "Enter", 4)
    check(json.loads(ls(pg, "mall-player-2") or "{}").get("cast") == "placeholder_2", f"the pick is saved ({ls(pg, 'mall-player-2')})")
    check(portrait(logs) == "placeholder_2", f"MAIN's portrait follows the pick ({portrait(logs)})")
    shot(pg, "menu-main-picked")
    key(pg, "Tab", 2)
    one(logs, pg, "after the pick", "placeholder_2")
    shot(pg, "picked-third")
    # 3. reload
    logs.clear()
    pg.reload()
    print("reload ready_s", ready(pg, logs), flush=True)
    one(logs, pg, "reload", "placeholder_2")
    # 4. a wing crossing, the game's own way (mallGoWing), frames all through it
    logs.clear()
    target = url(f"wing={OTHER}&view=third&debug=1&{CAM}&cam={CAMS[OTHER]}")
    for i in range(4):
        shot(pg, "crossing-%02d" % i); pg.wait_for_timeout(500)
    pg.evaluate(f"window.mallGoWing ? window.mallGoWing({json.dumps(target)}) : location.replace({json.dumps(target)})")
    t0 = time.time(); i = 4
    while time.time() - t0 < 420 and not any(l.startswith("CASTCOUNT") for l in logs):
        shot(pg, "crossing-%02d" % i); i += 1
        pg.wait_for_timeout(2000)
    for j in range(4):
        shot(pg, "crossing-%02d" % i); i += 1; pg.wait_for_timeout(1000)
    one(logs, pg, f"wing crossing {WING} -> {OTHER}", "placeholder_2")
    # 5. year crossing
    logs.clear()
    pg.goto(url(f"wing={OTHER}&year=2026&view=third&debug=1&{CAM}&cam={CAMS[OTHER]}"))
    print("2026 ready_s", ready(pg, logs), flush=True)
    one(logs, pg, "year crossing to 2026", "placeholder_2")
    shot(pg, "y2026-third")
    errs = errors(logs)
    check(not errs, f"no errors in the console ({errs[:3]})")
    ctx.close()
    # 6. phone portrait: tap a portrait in the Character row
    ctx = b.new_context(viewport={"width": 390, "height": 844}, has_touch=True, is_mobile=True, device_scale_factor=2)
    pg = ctx.new_page(); logs = []
    pg.on("console", lambda m: logs.append(m.text))
    pg.goto(url(f"wing={WING}&view=third&debug=1&pack=desktop&{CAM}&cam={CAMS[WING]}"))
    print("phone ready_s", ready(pg, logs), flush=True)
    pg.wait_for_timeout(3000)
    pg.touchscreen.tap(31, 29); pg.wait_for_timeout(3000)
    shot(pg, "phone-menu-main")
    rows = os.environ.get("PHONE_ROW", "244,569")   # "x,y" of the third portrait (from tools/qa/ui_offscreen_test.gd RECT lines)
    if rows:
        x, y = [float(v) for v in rows.split(",")]
        pg.touchscreen.tap(x, y); pg.wait_for_timeout(4000)
        check(json.loads(ls(pg, "mall-player-2") or "{}").get("cast") == "placeholder_3", f"phone: a tap on the third portrait picks it ({ls(pg, 'mall-player-2')})")
        shot(pg, "phone-menu-picked")
        pg.touchscreen.tap(31, 29)
    ctx.close()
    b.close()
print(("AVATAR WEB OK (%d checks)" % oks) if not fails else "AVATAR WEB FAILED: %s" % fails)
