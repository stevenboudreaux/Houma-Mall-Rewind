"""Headless runs of the COIN COMET page (prototypes/godot-mall/play/pusher.html) in Chromium.

Usage (from the repo root, with the play folder served):
    (cd prototypes/godot-mall/play && python3 -m http.server 8766 &)
    python3 tests/unit/pusher/page_test.py [out-prefix]
Runs, each in a fresh browser profile, with the page's test hooks (?test=1, window.PUSHER_PAGE):
  1. a fresh machine: a drop pays a quarter in, the coin lands on the deck and stays on the field
  2. a cascade into the cup: the lip at 0 and hard bumps; coins reach the cup and the quarters go up
     by what fell (after the 350 ms chute delay)
  3. a tilt: nudges in a burst trip it; the alarm and the gate time out as logic.js says; coins
     falling meanwhile are booked to the house
  4. state survives a reload: the coin poses and the quarters come back from localStorage
  5. frame times for each quality level (the physics step cost in Chromium's wasm; the
     renderer here is software, so only the sim figure is comparable to a phone)
  6. 0 page errors over all of it
Prints one line per check, then ALL OK or FAILED (exit 1). Screenshots to <out-prefix>-*.png.
"""
import json, os, sys, time
from playwright.sync_api import sync_playwright

OUT = sys.argv[1] if len(sys.argv) > 1 else "/tmp/pusher-page"
URL = "http://localhost:8766/pusher.html"
ARGS = ["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"]
fails = []
errors = []


def check(ok, what):
    print(("ok   " if ok else "FAIL ") + what)
    if not ok:
        fails.append(what)


def page(b, q, w=390, h=844, storage=None):
    ctx = b.new_context(viewport={"width": w, "height": h}, device_scale_factor=1)
    pg = ctx.new_page()
    pg.on("pageerror", lambda e: errors.append("pageerror: " + str(e)))
    pg.on("console", lambda m: errors.append(m.type + ": " + m.text) if m.type == "error" else None)
    if storage:
        pg.goto("http://localhost:8766/lib/rapier.LICENSE")
        pg.evaluate("s => { for (const k in s) localStorage.setItem(k, s[k]); }", storage)
    pg.goto(URL + "?test=1&" + q, wait_until="load", timeout=120000)
    pg.wait_for_function("window.PUSHER_PAGE", timeout=120000)
    return ctx, pg


def st(pg):
    return pg.evaluate("""() => { const P = PUSHER_PAGE, s = P.sim; let d = 0, sh = 0;
      for (const c of s.coins.values()) { if (c.body.translation().y > 3) d++; else sh++; }
      return { coins: s.count(), deck: d, shelf: sh, awake: s.awake(), q: P.quarters(), cup: P.cupTotal, ledger: P.ledger, gate: P.gate, t: s.t,
               frames: P.stats.frames, ms: P.stats.ms / Math.max(1, P.stats.frames), simMs: P.stats.simMs / Math.max(1, P.stats.frames), steps: P.stats.steps }; }""")


with sync_playwright() as p:
    # the cloud container has Chromium at /opt/pw-browsers (CLAUDE-CLOUD.md); elsewhere Playwright's own
    b = p.chromium.launch(args=ARGS, executable_path=os.environ.get("PW_CHROME") or None)

    # ---- 1. a drop lands
    ctx, pg = page(b, "fresh=1&pos=1")
    time.sleep(2)
    s0 = st(pg)
    check(s0["coins"] == 450, "a fresh machine on a phone-sized page holds the medium count on 'mobile', else high: %d coins" % s0["coins"])
    check(s0["q"] == 20, "a new player has 20 quarters (%d)" % s0["q"])
    pg.evaluate("PUSHER_PAGE.setSlider(5); PUSHER_PAGE.drop()")
    time.sleep(0.2)
    check(st(pg)["q"] == 19, "a drop pays one quarter in")
    time.sleep(3)
    s1 = st(pg)
    check(s1["coins"] == s0["coins"] + 1 and s1["deck"] == s0["deck"] + 1, "the coin landed on the deck and stayed (%d deck, %d shelf)" % (s1["deck"], s1["shelf"]))
    check(s1["ledger"]["in"] == 1 and s1["ledger"]["lost"] == 0, "the ledger counts it in")
    pg.screenshot(path=OUT + "-1-drop.png")
    ctx.close()

    # ---- 2. a cascade into the cup: the lip at 0 and hard bumps on the cabinet (the sim's own, no tilt)
    ctx, pg = page(b, "fresh=1&pos=2", 1280, 800)
    time.sleep(1)
    pg.evaluate("PUSHER_PAGE.applyLip(0)")
    r = pg.evaluate("""() => { const P = PUSHER_PAGE, s = P.sim; let n = 0, got = 0; P.paused = true;
      for (let i = 0; i < 30 && got < 3; i++) { s.nudge(0, 1, 1); n++; s.run(0.8);
        for (const e of s.step(0)) { if (e.type === 'cup') got++; } }
      P.paused = false; return { n, got, coins: s.count() }; }""")
    check(r["got"] >= 3, "coins fell over the front edge into the chute after %d bumps (%d)" % (r["n"], r["got"]))
    time.sleep(2.5)
    s2 = st(pg)
    check(s2["ledger"]["cup"] >= 3 and s2["q"] == 20 + s2["ledger"]["cup"], "the ledger books them to the cup and the quarters go up (%d, %d quarters)" % (s2["ledger"]["cup"], s2["q"]))
    pg.screenshot(path=OUT + "-2-cascade.png")
    ctx.close()

    # ---- 3. a tilt
    ctx, pg = page(b, "fresh=1&pos=3")
    time.sleep(1)
    tripped = pg.evaluate("""() => { const P = PUSHER_PAGE; let k = 0;
      return new Promise(res => { const iv = setInterval(() => { P.nudge(1, 'test'); k++; if (P.tiltAt !== null || k > 8) { clearInterval(iv); res({ k, tilt: P.tiltAt !== null, gate: P.gate }); } }, 240); }); }""")
    check(tripped["tilt"], "a burst of %d full nudges trips the tilt" % tripped["k"])
    time.sleep(0.3)
    check(st(pg)["gate"] == "house", "the gate swings to the house side")
    # coins bumped over the edge now go to the house (the sim's bumps: the page's would be ignored while it rocks)
    r = pg.evaluate("""() => { const P = PUSHER_PAGE, s = P.sim; let h = 0, c = 0; P.paused = true; P.applyLip(0);
      for (let i = 0; i < 30 && h + c < 2; i++) { s.nudge(0, 1, 1); s.run(0.8); for (const e of s.step(0)) { if (e.type === 'house-tilt') h++; if (e.type === 'cup') c++; } }
      P.paused = false; return { h, c }; }""")
    check(r["h"] >= 1 and r["c"] == 0, "coins over the edge while the gate is over go to the house (%d house, %d cup)" % (r["h"], r["c"]))
    pg.screenshot(path=OUT + "-3-tilt.png")
    time.sleep(4.5)
    s3 = st(pg)
    check(s3["gate"] == "player" and pg.evaluate("PUSHER_PAGE.tiltAt") is None, "the alarm and the gate time out (gate %s)" % s3["gate"])
    ctx.close()

    # ---- 4. a reload keeps the machine and the quarters
    ctx, pg = page(b, "fresh=1&pos=4")
    time.sleep(1)
    pg.evaluate("PUSHER_PAGE.drop(); PUSHER_PAGE.drop()")
    time.sleep(3)
    before = st(pg)
    saved = pg.evaluate("() => { PUSHER_PAGE.saveMachine(); return { m: localStorage.getItem('pusher.machine.4'), s: localStorage.getItem('mall-state-1995') }; }")
    pose0 = pg.evaluate("() => { const c = PUSHER_PAGE.sim.coins.values().next().value.body.translation(); return [c.x, c.y, c.z]; }")
    ctx.close()
    ctx, pg = page(b, "pos=4", storage={"pusher.machine.4": saved["m"], "mall-state-1995": saved["s"]})
    after = st(pg)
    restored = pg.evaluate("PUSHER_PAGE.restored")
    pose1 = pg.evaluate("() => { const c = PUSHER_PAGE.sim.coins.values().next().value.body.translation(); return [c.x, c.y, c.z]; }")
    check(restored and after["coins"] == before["coins"] and after["q"] == 18, "the reload restores %d coins and 18 quarters (%s, %d, %d)" % (before["coins"], restored, after["coins"], after["q"]))
    check(all(abs(a - b) < 0.6 for a, b in zip(pose0, pose1)), "the first coin is back where it was (%s vs %s)" % ([round(v, 2) for v in pose0], [round(v, 2) for v in pose1]))
    check(json.loads(saved["s"]).get("quarters") == 18, "the quarters are in the mall state record (mall-state-1995.quarters)")
    ctx.close()

    # ---- 5. frame times per quality
    for q in ("low", "medium", "high"):
        ctx, pg = page(b, "fresh=1&pos=5", storage={"pusher.quality": json.dumps(q)})
        time.sleep(1)
        pg.evaluate("() => { PUSHER_PAGE.stats.frames = 0; PUSHER_PAGE.stats.ms = 0; PUSHER_PAGE.stats.simMs = 0; PUSHER_PAGE.stats.steps = 0; }")
        time.sleep(6)
        s5 = st(pg)
        per_step = s5["simMs"] * s5["frames"] / max(1, s5["steps"])
        print("     %s: %d coins, %d awake: sim %.2f ms/step (%.1f ms a frame at 120 Hz), whole frame %.1f ms with the software renderer" % (q, s5["coins"], s5["awake"], per_step, per_step * 2, s5["ms"]))
        check(s5["coins"] == {"low": 450, "medium": 600, "high": 750}[q], "%s quality fills %d coins" % (q, s5["coins"]))
        ctx.close()

    b.close()

errs = [e for e in errors if "deprecated" not in e]
check(len(errs) == 0, "0 page errors (%d)" % len(errs))
for e in errs[:8]:
    print("     " + e[:200])
print("ALL OK" if not fails else "FAILED: " + "; ".join(fails))
sys.exit(1 if fails else 0)
