"""Web check of money and tickets end to end (workstream ECON, Steven Nov 3 2026; design/godot-economy.md).

Usage: CHROMIUM=/opt/pw-browsers/chromium python3 tools/qa/econ_webtest.py <build-path>/index.html <out-prefix>
(a server on :8765 serving the repo root; the build folder must also hold play/'s pages: *.html, lib/,
pusher/, claw/, skeeball/, whirlwind/ linked in, as for the pusher in the Demo 49 handoff).
Wing 2, 1995, desktop 1280 x 720, a new player:
  1. Skee-Ball the mall's way: stand at alley 1, press E; the frame opens skeeball.html with year=1995
     (scripts/signs.gd); play a game of 9 balls; Back closes the frame.
  2. WHIRLWIND, the claw and COIN COMET in the same frame, at the URLs signs.gd / pusher_play.gd build: win
     tickets in each (the claw from a machine of 200-ticket capsules on its strong play; the pusher from
     cabinet bumps with the lip down, as tests/unit/pusher/page_test.py), then Back.
  3. The money: $100.00 less 25c + $1.00 + 25c + the pusher's drops; the tickets: the sum of what each game says
     it paid, in mall.tickets-1995 only.
  4. Stand at the long case, press E: the redemption screen opens; screenshot ("Your tickets: <sum>").
Prints each step, then ECON WEB OK or FAILED, and the console errors (expect 0).
"""
import json, os, sys, time
from playwright.sync_api import sync_playwright

path, out = sys.argv[1], sys.argv[2]
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"]
SKEE_CAM = "-105.93,68.18,90,-10"          # alley 1's front (signs.gd SKEE_FRONT_X / SKEE_Z0 / SKEE_W), facing up it
COUNTER_CAM = "-104.8,64.2,-90,-18"        # the long case (tools/qa/redemption_webtest.py)
fails = []
NO_W1 = True        # the scratch build has only wing 2: the shell's prefetch of wing 1 for later fails (not ECON's)


def check(ok, what):
    print(("ok   " if ok else "FAIL ") + what, flush=True)
    if not ok:
        fails.append(what)


def ready(pg, t=600):
    """The wing is up: web/shell.html has removed its loading overlay (#status)."""
    t0 = time.time()
    while time.time() - t0 < t:
        try:
            if pg.evaluate("!!window.mallRoms && !document.getElementById('status')"):   # shell.html removes it when the game starts
                return round(time.time() - t0)
        except Exception:
            pass
        time.sleep(2)
    return None


def open_game(pg, url, name, hook):
    """Open a game in the mall's frame (as signs.gd does) and wait for its page to be up (swiftshader: slow)."""
    pg.evaluate("u => window.mallRoms.open(u)", url)
    g = Game(pg)
    ok = wait(lambda: name in g.src() and g.evaluate("!!window." + hook), 600)
    check(ok, "%s opens in the mall's frame" % name)
    return g if ok else None


def wait(fn, t=180):
    t0 = time.time()
    while time.time() - t0 < t:
        try:
            if fn():
                return True
        except Exception:
            pass
        time.sleep(0.5)
    return False


class Game:
    """The game page in the mall's frame, driven through window.mallRoms.frame.contentWindow (same origin), the
    frame web/shell.html makes. (Playwright's own frame list proved unreliable for a frame that replaces another.)"""
    def __init__(self, pg):
        self.pg = pg

    def evaluate(self, expr):
        return self.pg.evaluate("e => { const f = window.mallRoms.frame; if (!f || !f.contentWindow) throw new Error('no frame'); return f.contentWindow.eval(e); }", expr)

    def src(self):
        return self.pg.evaluate("window.mallRoms.frame ? window.mallRoms.frame.src : ''")


def ls(pg, k):
    v = pg.evaluate("k => localStorage.getItem(k)", k)
    return int(v) if v not in (None, "") else 0


def close_frame(pg, f):
    f.evaluate("document.getElementById('back').click(); 1")
    return wait(lambda: pg.evaluate("window.mallRoms.isOpen()") == "0", 30)


with sync_playwright() as p:
    b = p.chromium.launch(args=ARGS, executable_path=os.environ.get("CHROMIUM") or None)
    ctx = b.new_context(viewport={"width": 1280, "height": 720})
    caps = [{"id": "c%d" % i, "kind": "t200", "x": -0.20 + 0.12 * (i % 5), "z": 0.50 + 0.14 * (i // 5), "y": 0.955, "rot": 0} for i in range(10)]
    ctx.add_init_script("try{if(!sessionStorage.getItem('econ-seeded')){localStorage.clear();localStorage.setItem('claw.pile.1', %s);sessionStorage.setItem('econ-seeded','1')}}catch(e){}"
                        % json.dumps(json.dumps({"seed": 1, "plays": 6, "items": caps})))
    pg = ctx.new_page(); logs = []; errs_all = []
    pg.on("console", lambda m: (logs.append(m.text), errs_all.append(m.text) if (m.type == "error" or "ERROR" in m.text.upper()) and "Failed to load resource" not in m.text and not ("could not keep the next files" in m.text and NO_W1) else None))
    pg.on("pageerror", lambda e: errs_all.append("pageerror " + str(e)))
    # a missing file is an error, except this scratch build's absent wing 1 (only wing 2 is exported), the favicon and
    # play/prize_text.json (scripts/prizes.gd asks for the owner's published prize words; none are published yet)
    pg.on("response", lambda r: errs_all.append("%d %s" % (r.status, r.url)) if r.status >= 400 and not r.url.endswith("favicon.ico") and "/w1." not in r.url and "/prize_text.json" not in r.url else None)
    url = f"http://127.0.0.1:8765/{path}?wing=2"
    pg.goto(url + "&cam=" + SKEE_CAM)
    took = ready(pg)
    check(took is not None, "the mall loads (%s s)" % took)
    time.sleep(20)
    paid = {}

    # ---- 1. Skee-Ball through the mall's own Play
    pg.keyboard.press("e")
    g = Game(pg)
    opened = wait(lambda: "skeeball.html" in g.src() and g.evaluate("!!window.__skee"), 600)
    src = g.src()
    check(opened and "year=1995" in src and "lane=1" in src, "E at alley 1 opens Skee-Ball with year=1995 (%s)" % src)
    f = g if opened else None
    if f:
        f.evaluate("__skee.start()")
        for i in range(9):
            f.evaluate("__skee.roll(%f, %f)" % ((i % 3 - 1) * 0.04, 0.55 + 0.05 * (i % 4))); time.sleep(0.5)
        wait(lambda: f.evaluate("__skee.S.counted >= 9"), 180)
        paid["skee"] = f.evaluate("__skee.SK.tickets(__skee.S.score, __skee.S.pockets)")
        pg.screenshot(path=f"{out}-skeeball.png", timeout=180000)
        check(close_frame(pg, f), "Back closes Skee-Ball (%d tickets)" % paid["skee"])

    # ---- 2. the other three, at the URLs the mall builds
    f = open_game(pg, "whirlwind.html?year=1995&name=WHIRLWIND", "whirlwind.html", "__ww")
    if f:
        time.sleep(1)
        won = 0
        for k in range(4):
            f.evaluate("__ww.action(performance.now(), 'click')"); time.sleep(1.5)     # START / next play
            f.evaluate("__ww.action(performance.now(), 'click')"); time.sleep(0.3)     # stop
            won += f.evaluate("__ww.S.won")
            f.evaluate("__ww.skip()"); time.sleep(0.3)
        paid["whirlwind"] = won
        pg.screenshot(path=f"{out}-whirlwind.png", timeout=180000)
        check(close_frame(pg, f), "Back closes WHIRLWIND after 4 plays (%d tickets)" % won)

    f = open_game(pg, "claw.html?year=1995&machine=1&name=CLAW", "claw.html", "__claw")
    if f:
        time.sleep(1)
        f.evaluate("__claw.start()")
        f.evaluate("__claw.setPos(%f, %f)" % (caps[2]["x"], caps[2]["z"]))
        f.evaluate("__claw.drop()")
        wait(lambda: f.evaluate("__claw.ST.mode === 'over'"), 200)
        paid["claw"] = f.evaluate("(__claw.ST.won && __claw.ST.won.tickets) || 0")
        pg.screenshot(path=f"{out}-claw.png", timeout=180000)
        check(paid["claw"] == 200 and close_frame(pg, f), "the claw wins a 200-ticket capsule; Back closes it")

    # a plush from the claw: into the bag when the frame closes, with the "You received" card (Steven, Nov 3)
    gators = [dict(c, id="g%d" % i, kind="gator") for i, c in enumerate(caps)]
    pg.evaluate("p => localStorage.setItem('claw.pile.1', p)", json.dumps({"seed": 2, "plays": 13, "items": gators}))
    f = open_game(pg, "claw.html?year=1995&machine=1&name=CLAW", "claw.html", "__claw")
    if f:
        time.sleep(1)
        f.evaluate("__claw.start()"); f.evaluate("__claw.setPos(%f, %f)" % (gators[2]["x"], gators[2]["z"])); f.evaluate("__claw.drop()")
        wait(lambda: f.evaluate("__claw.ST.mode === 'over'"), 200)
        won = f.evaluate("(__claw.ST.won && __claw.ST.won.kind) || ''")
        check(won == "plush" and close_frame(pg, f), "the claw wins a Gator plush; Back closes it")
        inbag = wait(lambda: any(e.get("id") == "pc_claw_gator" for e in json.loads(pg.evaluate("localStorage.getItem('mall-state-1995')") or "{}").get("inventory", [])), 120)
        time.sleep(15)
        pg.screenshot(path=f"{out}-claw-received.png", timeout=180000)
        check(inbag and not pg.evaluate("localStorage.getItem('mall.inbox-1995')"), "the mall puts the Gator plush in the bag (mall-state-1995) and empties the inbox; screenshot: the card")
        pg.keyboard.press("Space"); time.sleep(10)

    f = open_game(pg, "pusher.html?pos=1&year=1995&name=COIN%20COMET&test=1", "pusher.html", "PUSHER_PAGE")
    if f:
        time.sleep(2)
        f.evaluate("PUSHER_PAGE.drop()"); time.sleep(1)
        r = f.evaluate("""(() => { const P = PUSHER_PAGE, s = P.sim; let got = 0; P.paused = true; P.applyLip(0);
          for (let i = 0; i < 30 && got < 2; i++) { s.nudge(0, 1, 1); s.run(0.8); for (const e of s.step(0)) { P.onEvent(e); if (e.type === 'cup') got++; } }
          P.paused = false; return got; })()""")
        paid["pusher"] = r * f.evaluate("window.PUSHER.CONFIG.ticketsPerCoin")
        time.sleep(1)
        pg.screenshot(path=f"{out}-pusher.png", timeout=180000)
        check(r >= 1 and close_frame(pg, f), "COIN COMET: one drop, %d coins into the cup (%d tickets); Back closes it" % (r, paid["pusher"]))

    # ---- 3. the bank
    total = sum(paid.values())
    t95, t26, money = ls(pg, "mall.tickets-1995"), ls(pg, "mall.tickets-2026"), ls(pg, "mall.money")
    check(t95 == total and t26 == 0, "every win is in the 1995 tickets, once: %s = %d (bank %d; 2026 %d)" % (paid, total, t95, t26))
    check(money == 10000 - 25 - 100 - 25 - 25 - 25, "the wallet: $100.00 - Skee-Ball 0.25 - WHIRLWIND 1.00 - claw 2 x 0.25 - one drop 0.25 = %d (%d)" % (10000 - 200, money))

    # ---- 4. the counter
    pg.goto(url + "&cam=" + COUNTER_CAM)
    ready(pg); time.sleep(30)
    pg.keyboard.press("e")
    time.sleep(25)                      # swiftshader handles input many seconds late
    pg.screenshot(path=f"{out}-redemption.png", timeout=180000)
    check(ls(pg, "mall.tickets-1995") == total, "after a reload the bank still holds %d (the screenshot shows 'Your tickets: %s')" % (total, format(total, ",")))
    st = json.loads(pg.evaluate("localStorage.getItem('mall-state-1995')") or "{}")
    check(sum(e.get("count", 0) for e in st.get("inventory", []) if e.get("id") == "pc_claw_gator") + (1 if st.get("hand") == "pc_claw_gator" else 0) == 1,
          "after the reload the bag holds one Gator plush, not two")
    check(not errs_all, "0 console errors, the mall and every game (%d) %s" % (len(errs_all), errs_all[:3]))
    b.close()
print("ECON WEB", "OK" if not fails else "FAILED %d" % len(fails))
sys.exit(1 if fails else 0)
