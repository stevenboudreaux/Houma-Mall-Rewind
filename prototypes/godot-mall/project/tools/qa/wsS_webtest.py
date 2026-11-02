"""Web check of the room wings (workstream S, Nov 2 2026; design/godot-wings.md "Wings 4-6") on an
export served from :8765 (python3 -m http.server 8765 at the repo root).

usage: python3 tools/qa/wsS_webtest.py <url-path to index.html> <out-prefix> [1995|2026] [legs]
legs (comma list, default all): sears, dillards, cinema, jump

  sears / dillards: stand in the mall at the opening, screenshot the picture in it, E -> the crossing
    card (screenshot) -> the room wing (screenshot, URL, player position) -> E -> back (the same).
  cinema: wing 1 at the doors with the gate down; E empty-handed -> the locked message (screenshot);
    the stick put in the hand (localStorage mall-state-1995 "hand"), reload, E -> the gate rolls up
    (screenshot); E -> wing 6 (screenshot); a fresh load of wing 1 at the doors -> the gate still up
    (the flag survived the reload).
  jump: ?wing=4 / ?wing=5 at the directory jump spots (map_data.gd ROOM_JUMPS), screenshots.
Prints one line per check and the console errors; "WSS WEB OK" when all passed.
"""
import json, os, re, sys, time
from playwright.sync_api import sync_playwright

path, out = sys.argv[1], sys.argv[2]
YEAR = sys.argv[3] if len(sys.argv) > 3 else "1995"
LEGS = (sys.argv[4] if len(sys.argv) > 4 else "sears,dillards,cinema,jump").split(",")
YQ = "&year=2026" if YEAR == "2026" else ""
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"]
BASE = "http://127.0.0.1:8765/" + path
fails = []


def check(ok, what):
    print(("ok   " if ok else "FAIL ") + what, flush=True)
    if not ok:
        fails.append(what)


def ready(pg, t=400):
    t0 = time.time()
    while time.time() - t0 < t:
        try:
            if pg.evaluate("!document.getElementById('status')"):
                return round(time.time() - t0)
        except Exception:
            pass
        time.sleep(1)
    return None


def shot(pg, name):
    pg.screenshot(path=f"{out}-{name}.png", timeout=180000)


def last_pos(logs):
    d = [l for l in logs if l.startswith("DBG pos=")]
    m = re.search(r"pos=\(([^)]*)\)", d[-1]) if d else None
    return [round(float(v), 2) for v in m.group(1).split(",")] if m else None


def press_e(pg):
    pg.focus("#canvas")
    pg.keyboard.down("e"); time.sleep(0.6); pg.keyboard.up("e")


def wait_url(pg, want, t=150, card=None):
    t0 = time.time(); cur = ""; took_card = False
    while time.time() - t0 < t:
        try:
            cur = pg.evaluate("location.href")
            if card and not took_card and want in cur:
                time.sleep(1.0)
                shot(pg, card); took_card = True
        except Exception:
            cur = ""
        if want in cur and (not card or took_card):
            return cur
        time.sleep(0.25)
    return cur


def cross_leg(pg, logs, name, wing, cam, to, back):
    pg.goto(f"{BASE}?wing={wing}&cam={cam}&debug=1{YQ}")
    print(name, "ready_s", ready(pg), flush=True); time.sleep(8)
    p0 = last_pos(logs)
    shot(pg, f"{name}-1-mall-opening")
    press_e(pg)
    cur = wait_url(pg, f"wing={to}", card=f"{name}-2-card")
    check(f"wing={to}" in cur, f"{name}: E at the opening loads wing {to} ({cur.split('?')[-1]})")
    logs.clear(); print(name, "ready_s", ready(pg), flush=True); time.sleep(8)
    p1 = last_pos(logs)
    shot(pg, f"{name}-3-inside")
    print(f"     before {p0} -> inside {p1}")
    press_e(pg)
    cur = wait_url(pg, f"wing={back}")
    check(f"wing={back}" in cur, f"{name}: E inside the opening goes back to wing {back}")
    logs.clear(); ready(pg); time.sleep(8)
    p2 = last_pos(logs)
    shot(pg, f"{name}-4-back")
    print(f"     inside {p1} -> back {p2}")


with sync_playwright() as p:
    b = p.chromium.launch(args=ARGS)
    ctx = b.new_context(viewport={"width": 1280, "height": 720})
    pg = ctx.new_page(); logs = []
    pg.on("console", lambda m: logs.append(m.text))
    errs = []
    pg.on("console", lambda m: errs.append(m.text) if "ERROR" in m.text.upper() else None)
    if "sears" in LEGS:
        cross_leg(pg, logs, "sears", 1, "-4,-94.6,0,-2", 4, 1)
    if "dillards" in LEGS:
        cross_leg(pg, logs, "dillards", 2, "-4,78.6,180,-2", 5, 2)
    if "cinema" in LEGS:
        pg.goto(f"{BASE}?wing=1&cam=-56,-87,180,0&debug=1{YQ}")
        pg.evaluate("localStorage.removeItem('mall-flags-1')")
        pg.goto(f"{BASE}?wing=1&cam=-56,-87.6,180,4&debug=1{YQ}")
        print("cinema ready_s", ready(pg), flush=True); time.sleep(8)
        shot(pg, "cinema-1-gate-down")
        press_e(pg); time.sleep(1.0)
        shot(pg, "cinema-2-locked-message")
        time.sleep(3)
        check("wing=1" in pg.evaluate("location.href") and "cinema_unlocked" not in (pg.evaluate("localStorage.getItem('mall-flags-1')") or ""),
              "cinema: empty-handed E stays in wing 1, flag unset")
        if YEAR == "1995":
            # the stick in the hand, as picking it up in the Stockrooms leaves it
            key = "mall-state-1995"
            st = json.loads(pg.evaluate(f"localStorage.getItem('{key}')") or '{"v":1,"year":1995,"inventory":[],"tickets":0}')
            st["hand"] = "folse_stick"; st.setdefault("moved", {})["folse_stick"] = {}
            pg.evaluate(f"localStorage.setItem('{key}', {json.dumps(json.dumps(st))})")
        else:
            # the stick is a 1995 item; the flags are one store for both years
            pg.evaluate("localStorage.setItem('mall-flags-1', JSON.stringify({v: 1, flags: {cinema_unlocked: true}}))")
        pg.reload(); logs.clear()
        print("cinema ready_s", ready(pg), flush=True); time.sleep(8)
        shot(pg, "cinema-3-holding-stick")
        if YEAR == "1995":
            press_e(pg); time.sleep(3)
            check("cinema_unlocked" in (pg.evaluate("localStorage.getItem('mall-flags-1')") or ""), "cinema: E holding the stick sets cinema_unlocked (saved)")
            check("wing=1" in pg.evaluate("location.href"), "cinema: the first press only opens the gate")
        shot(pg, "cinema-4-gate-up")
        press_e(pg)
        cur = wait_url(pg, "wing=6", card="cinema-5-card")
        check("wing=6" in cur, "cinema: E at the open doors loads wing 6")
        logs.clear(); ready(pg); time.sleep(8)
        print("     lobby at", last_pos(logs))
        shot(pg, "cinema-6-lobby")
        pg.goto(f"{BASE}?wing=1&cam=-56,-91,180,2&debug=1{YQ}")
        ready(pg); time.sleep(8)
        shot(pg, "cinema-7-after-reload-gate-up")
        check("cinema_unlocked" in (pg.evaluate("localStorage.getItem('mall-flags-1')") or ""), "cinema: the flag survives a fresh load")
    if "jump" in LEGS:
        for w, cam in [(4, "-4,-98.2,0,0"), (5, "-4,82.2,180,0")]:
            pg.goto(f"{BASE}?wing={w}&cam={cam}&debug=1{YQ}")
            r = ready(pg); time.sleep(8)
            shot(pg, f"jump-w{w}")
            check(r is not None, f"wing {w} loads at the directory's jump spot ({r} s)")
    print("console errors", len(errs), errs[:5])
    print("WSS WEB OK" if not fails else "WSS WEB FAILED: " + "; ".join(fails))
    b.close()
