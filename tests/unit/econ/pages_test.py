"""The ticket games pay what they win, once, into the right year (workstream ECON, Steven Nov 3 2026;
design/godot-economy.md). Headless Chromium on the pages themselves (prototypes/godot-mall/play/*.html).

Usage (from the repo root, with the play folder served):
    (cd prototypes/godot-mall/play && python3 -m http.server 8766 &)
    PW_CHROME=/opt/pw-browsers/chromium python3 tests/unit/econ/pages_test.py [out-prefix]
Each game, in a fresh browser profile:
  WHIRLWIND  START takes $1.00; the win of play 1 is in the 1995 tickets the moment the light stops; a reload
             during the payout keeps it (once) and the 3 plays left are still on the machine
  SKEE-BALL  a game takes 25 cents; a reload mid-game keeps the tickets the score has earned; a full game of
             9 balls ends with exactly SK.tickets(score) in the bank
  CLAW       a play takes 25 cents; a 200-ticket capsule won goes to the 1995 tickets once
  all three  ?year=2026 pays into 2026, not 1995; at 10 cents the start is refused, nothing is taken, and the
             card says what it costs; an old save (claw "mall.tickets", mall-state quarters/tickets) is folded in
Prints one line per check, then ECON PAGES OK or FAILED (exit 1). Screenshots to <out-prefix>-*.png.
"""
import json, os, sys, time
from playwright.sync_api import sync_playwright

OUT = sys.argv[1] if len(sys.argv) > 1 else "/tmp/econ-pages"
BASE = "http://localhost:8766/"
ARGS = ["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"]
fails, errors = [], []


def check(ok, what):
    print(("ok   " if ok else "FAIL ") + what, flush=True)
    if not ok:
        fails.append(what)


def ctx_page(b, storage=None, w=390, h=844):
    ctx = b.new_context(viewport={"width": w, "height": h}, device_scale_factor=1)
    pg = ctx.new_page()
    pg.on("pageerror", lambda e: errors.append("pageerror: " + str(e)))
    pg.on("console", lambda m: errors.append(m.type + ": " + m.text) if m.type == "error" and "Failed to load resource" not in m.text else None)
    # a missing file is an error, except the browser's own favicon request (the pages have none)
    pg.on("response", lambda r: errors.append("404 " + r.url) if r.status >= 400 and not r.url.endswith("favicon.ico") else None)
    pg.goto(BASE + "lib/mallbank.js")              # same origin, to seed localStorage
    if storage:
        pg.evaluate("s => { for (const k in s) localStorage.setItem(k, s[k]); }", storage)
    return ctx, pg


def go(pg, url, hook):
    pg.goto(BASE + url, wait_until="load", timeout=180000)
    pg.wait_for_function("window." + hook, timeout=180000)
    time.sleep(0.5)


def ls(pg, k):
    return pg.evaluate("k => localStorage.getItem(k)", k)


def num(pg, k):
    v = ls(pg, k)
    return int(v) if v not in (None, "") else 0


def wait(pg, cond, t=120):
    t0 = time.time()
    while time.time() - t0 < t:
        if pg.evaluate(cond):
            return True
        time.sleep(0.3)
    return False


with sync_playwright() as p:
    b = p.chromium.launch(args=ARGS, executable_path=os.environ.get("PW_CHROME") or None)

    # ------------------------------------------------------------ WHIRLWIND
    ctx, pg = ctx_page(b)
    go(pg, "whirlwind.html?year=1995", "__ww")
    check(num(pg, "mall.money") == 10000, "WHIRLWIND: a new player has $100.00")
    pg.evaluate("__ww.action(performance.now(), 'click')")
    check(num(pg, "mall.money") == 9900 and pg.evaluate("__ww.S.mode") == "chase", "WHIRLWIND: START takes $1.00 and play 1 runs")
    time.sleep(1.2)
    pg.evaluate("__ww.action(performance.now(), 'click')")
    won = pg.evaluate("__ww.S.won")
    check(pg.evaluate("__ww.S.mode") == "stopped" and won >= 1, "WHIRLWIND: the light stops and wins %d" % won)
    check(num(pg, "mall.tickets-1995") == won and pg.evaluate("__ww.S.total") == 0,
          "WHIRLWIND: the %d tickets are in the 1995 bank before any is fed out (%d)" % (won, num(pg, "mall.tickets-1995")))
    pg.screenshot(path=OUT + "-whirlwind-win.png")
    pg.reload(wait_until="load"); pg.wait_for_function("window.__ww", timeout=180000); time.sleep(0.5)
    check(num(pg, "mall.tickets-1995") == won, "WHIRLWIND: a reload during the payout keeps them, once (%d)" % num(pg, "mall.tickets-1995"))
    check(pg.evaluate("__ww.S.mode") == "ready" and pg.evaluate("__ww.S.credits") == 3 and num(pg, "mall.money") == 9900,
          "WHIRLWIND: the 3 plays left are still on the machine; no second dollar taken")
    ctx.close()

    # 2026 and no money
    ctx, pg = ctx_page(b, {"mall.econ": "1", "mall.money": "10"})
    go(pg, "whirlwind.html?year=2026", "__ww")
    pg.evaluate("__ww.action(performance.now(), 'click')")
    check(num(pg, "mall.money") == 10 and pg.evaluate("__ww.S.mode") == "title", "WHIRLWIND: with 10 cents START is refused, nothing taken")
    card = pg.evaluate("document.getElementById('msg').textContent")
    check("You need $1.00" in card and pg.evaluate("document.getElementById('go').disabled"), "WHIRLWIND: the card says 'You need $1.00 ... You have $0.10' and START is greyed")
    pg.screenshot(path=OUT + "-whirlwind-nomoney.png")
    pg.evaluate("localStorage.setItem('mall.money', '500')")
    pg.evaluate("__ww.action(performance.now(), 'click')"); time.sleep(1.2); pg.evaluate("__ww.action(performance.now(), 'click')")
    w26 = pg.evaluate("__ww.S.won")
    check(num(pg, "mall.tickets-2026") == w26 and num(pg, "mall.tickets-1995") == 0, "WHIRLWIND ?year=2026 pays 2026 (%d), not 1995" % w26)
    ctx.close()

    # ------------------------------------------------------------ SKEE-BALL
    ctx, pg = ctx_page(b)
    go(pg, "skeeball.html?year=1995&lane=1", "__skee")
    pg.evaluate("__skee.start()")
    check(num(pg, "mall.money") == 9975 and pg.evaluate("__skee.S.mode") == "play", "SKEE-BALL: a game takes 25 cents")
    for i in range(4):
        pg.evaluate("__skee.roll(%f, %f)" % ((i % 3 - 1) * 0.04, 0.55 + 0.05 * (i % 4))); time.sleep(0.4)
    wait(pg, "__skee.S.counted >= 4", 90)
    sc = pg.evaluate("[__skee.S.score, __skee.S.pockets, __skee.SK.tickets(__skee.S.score, __skee.S.pockets)]")
    check(num(pg, "mall.tickets-1995") == sc[2], "SKEE-BALL: after 4 balls (%d points) the bank holds what they earned (%d = %d)" % (sc[0], num(pg, "mall.tickets-1995"), sc[2]))
    pg.reload(wait_until="load"); pg.wait_for_function("window.__skee", timeout=180000); time.sleep(0.5)
    check(sc[2] > 0 and num(pg, "mall.tickets-1995") == sc[2] and num(pg, "mall.money") == 9975, "SKEE-BALL: leaving mid-game keeps them (%d), nothing more taken" % sc[2])
    base = num(pg, "mall.tickets-1995")
    pg.evaluate("__skee.start()")
    for i in range(9):
        pg.evaluate("__skee.roll(%f, %f)" % ((i % 3 - 1) * 0.04, 0.55 + 0.05 * (i % 4))); time.sleep(0.35)
    ok = wait(pg, "__skee.S.counted >= 9 && __skee.S.mode !== 'play'", 120)
    full = pg.evaluate("[__skee.S.score, __skee.SK.tickets(__skee.S.score, __skee.S.pockets)]")
    check(ok and num(pg, "mall.tickets-1995") - base == full[1], "SKEE-BALL: a full game of 9 balls, %d points, pays exactly %d (%d)" % (full[0], full[1], num(pg, "mall.tickets-1995") - base))
    wait(pg, "__skee.S.mode === 'over'", 60)
    check(num(pg, "mall.tickets-1995") - base == full[1], "SKEE-BALL: the ticket strip at the end adds nothing more")
    pg.screenshot(path=OUT + "-skeeball-over.png")
    ctx.close()

    ctx, pg = ctx_page(b, {"mall.econ": "1", "mall.money": "10"})
    go(pg, "skeeball.html?year=2026&lane=2", "__skee")
    pg.evaluate("__skee.start()")
    check(num(pg, "mall.money") == 10 and pg.evaluate("__skee.S.mode") == "title" and "You need $0.25" in pg.evaluate("document.getElementById('msg').textContent"),
          "SKEE-BALL: with 10 cents no game, and the card says it costs $0.25")
    pg.screenshot(path=OUT + "-skeeball-nomoney.png")
    pg.evaluate("localStorage.setItem('mall.money', '25')"); pg.evaluate("__skee.start()")
    for i in range(9):
        pg.evaluate("__skee.roll(0, 0.6)"); time.sleep(0.35)
    wait(pg, "__skee.S.counted >= 9", 120)
    t26 = pg.evaluate("__skee.SK.tickets(__skee.S.score, __skee.S.pockets)")
    check(num(pg, "mall.tickets-2026") == t26 and num(pg, "mall.tickets-1995") == 0 and num(pg, "mall.money") == 0,
          "SKEE-BALL ?year=2026 pays 2026 (%d), not 1995; the last quarter spent" % t26)
    ctx.close()

    # ------------------------------------------------------------ CLAW
    # an old save: the claw's own "mall.tickets", a 1995 record with tickets and the pusher's quarters; and a
    # machine with ten 200-ticket capsules, the next play the strong one (every 7th)
    caps = [{"id": "c%d" % i, "kind": "t200", "x": -0.20 + 0.12 * (i % 5), "z": 0.50 + 0.14 * (i // 5), "y": 0.955, "rot": 0} for i in range(10)]
    old = {"mall.tickets": "35", "mall-state-1995": json.dumps({"v": 1, "year": 1995, "inventory": [], "tickets": 100, "hand": "", "moved": {}, "quarters": 4}),
           "claw.pile.1": json.dumps({"seed": 1, "plays": 6, "items": caps})}
    ctx, pg = ctx_page(b, old)
    go(pg, "claw.html?year=1995&machine=1", "__claw")
    check(num(pg, "mall.tickets-1995") == 135 and num(pg, "mall.money") == 10100 and ls(pg, "mall.tickets") is None,
          "CLAW: the old save is folded in once: 100 + 35 tickets, $100.00 + 4 quarters ($101.00)")
    pg.evaluate("__claw.start()")
    check(num(pg, "mall.money") == 10075, "CLAW: a play takes 25 cents")
    pg.evaluate("__claw.setPos(%f, %f)" % (caps[2]["x"], caps[2]["z"]))
    pg.evaluate("__claw.drop()")
    ok = wait(pg, "__claw.ST.mode === 'over'", 150)
    won = pg.evaluate("__claw.ST.won && __claw.ST.won.tickets")
    check(ok and won == 200 and num(pg, "mall.tickets-1995") == 335, "CLAW: the capsule is won and its 200 tickets are in the 1995 bank (%s, %d)" % (won, num(pg, "mall.tickets-1995")))
    pg.screenshot(path=OUT + "-claw-win.png")
    pg.reload(wait_until="load"); pg.wait_for_function("window.__claw", timeout=180000); time.sleep(0.5)
    check(num(pg, "mall.tickets-1995") == 335 and pg.evaluate("document.getElementById('tk').textContent") == "335", "CLAW: a reload counts it once; the chip shows the year's 335")
    pg.evaluate("localStorage.setItem('mall.money', '10')"); pg.evaluate("__claw.start()")
    check(num(pg, "mall.money") == 10 and "You need $0.25" in pg.evaluate("document.getElementById('msg').textContent"), "CLAW: with 10 cents no play, and the card says why")
    pg.screenshot(path=OUT + "-claw-nomoney.png")
    ctx.close()

    b.close()
check(not errors, "0 page errors (%d) %s" % (len(errors), errors[:3]))
print("ECON PAGES OK" if not fails else "FAILED: %d" % len(fails))
sys.exit(1 if fails else 0)
