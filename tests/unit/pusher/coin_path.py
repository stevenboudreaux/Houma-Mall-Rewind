"""Record one coin's path through COIN COMET (prototypes/godot-mall/play/pusher.html): from the
drop, onto the top shelf while it is out, swept off its edge onto the main tier, pushed to the
lip and over into the payout slot. The page runs in headless Chromium with its test hooks
(?test=1, window.PUSHER_PAGE); the machine is primed first by fast-forwarding drops, then the
tracked coin is dropped into the open gap and the sim is run on, a drop at a time (up to 900: a
primed pusher turns its field over slowly), taking a frame whenever the coin has moved to a new
stage (and every 40 drops in between), with the coin ringed in red in the picture. A contact sheet of the frames is the evidence
(production/qa/evidence/wsPUSHER-coin-path.jpg).

Usage (from the repo root, with the play folder served):
    (cd prototypes/godot-mall/play && python3 -m http.server 8766 &)
    PW_CHROME=/opt/pw-browsers/chromium-1243/chrome-linux64/chrome python3 tests/unit/pusher/coin_path.py <out-prefix>
Prints the stages reached with the sim time of each, then ALL OK when the coin went all the way,
else FAILED (exit 1).
"""
import os, sys, time
from playwright.sync_api import sync_playwright

OUT = sys.argv[1] if len(sys.argv) > 1 else "/tmp/pusher-path"
URL = "http://localhost:8766/pusher.html?test=1&fresh=1&pos=6"
ARGS = ["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"]
W, H = 720, 900

PRIME = """() => { const P = PUSHER_PAGE, s = P.sim; P.paused = true;
  let rs = 777; const rnd = () => { rs = (rs * 1664525 + 1013904223) >>> 0; return rs / 4294967296; };
  for (let i = 0; i < %d; i++) { s.drop((rnd() * 2 - 1) * 16); s.run(1.6, true); }
  s.step(0); return s.count(); }"""

DROP = """() => { const P = PUSHER_PAGE, s = P.sim;
  while (s.outness() < 0.9) s.run(1 / 60, true);
  const id = s.drop(0); P.track(id); s.run(0.3, true); return { id, t: s.t }; }"""

# run on a drop at a time (random x, the deck phase free) and report where the tracked coin is
STEP = """() => { const P = PUSHER_PAGE, s = P.sim;
  let rs = 4242 + Math.round(s.t * 1000); const rnd = () => { rs = (rs * 1664525 + 1013904223) >>> 0; return rs / 4294967296; };
  s.drop((rnd() * 2 - 1) * 14); s.run(1.6, true); s.step(0);
  return P.tracked(); }"""


def stage(w):
    """The stage of the tracked coin from its pose: deck / falling / main / lip / gone."""
    if w is None:
        return "slot"
    x, y, z, G = w["x"], w["y"], w["z"], w["G"]
    if y > G["deckY"] - 0.4 and z > w["deckZ"] - 0.6:
        return "deck"
    if y > G["deckY"] - 0.4:
        return "falling"
    if z < 2.6:
        return "lip"
    return "main"


with sync_playwright() as p:
    b = p.chromium.launch(args=ARGS, executable_path=os.environ.get("PW_CHROME") or None)
    ctx = b.new_context(viewport={"width": W, "height": H}, device_scale_factor=1)
    pg = ctx.new_page()
    errors = []
    pg.on("pageerror", lambda e: errors.append(str(e)))
    pg.goto(URL, wait_until="load", timeout=120000)
    pg.wait_for_function("window.PUSHER_PAGE", timeout=120000)
    time.sleep(1)
    n = pg.evaluate(PRIME % 120)
    print("primed: %d coins on the field" % n)
    d = pg.evaluate(DROP)
    print("dropped coin %d into the open gap at t=%.2f" % (d["id"], d["t"]))
    frames, seen, last_stage, since = [], {}, None, 0
    t_sim0 = d["t"]
    # a coin's residence in a primed pusher is long (hundreds of drops: the whole field turns over
    # once for every field's worth of coins in), so this runs up to 900 drops, fast-forwarded
    for i in range(900):
        w = pg.evaluate("PUSHER_PAGE.tracked()")
        st = stage(w)
        if st != last_stage or since >= 40:
            pg.evaluate("PUSHER_PAGE.draw()")
            f = "%s-%02d-%s.png" % (OUT, len(frames), st)
            pg.screenshot(path=f)
            frames.append((f, st, (w["t"] if w else pg.evaluate("PUSHER_PAGE.sim.t")) - t_sim0))
            since = 0
            if st != last_stage:
                seen.setdefault(st, len(frames) - 1)
                print("  %-8s at +%.1f s  (%s)" % (st, frames[-1][2], "x %.1f y %.1f z %.1f" % (w["x"], w["y"], w["z"]) if w else "in the slot"))
            last_stage = st
        else:
            since += 1
        if st == "slot":
            break
        pg.evaluate(STEP)
    got = pg.evaluate("PUSHER_PAGE.trackedEvent")
    b.close()

ok = all(k in seen for k in ("deck", "main", "lip", "slot")) and got == "cup" and not errors
print("stages:", " > ".join(k for k in ("deck", "falling", "main", "lip", "slot") if k in seen), "| booked:", got, "| frames:", len(frames), "| errors:", len(errors))

# the contact sheet: every stage's first frame plus a few in between, labelled
try:
    from PIL import Image, ImageDraw
    keep = set(seen.values())
    rest = [i for i in range(len(frames)) if i not in keep]
    step = max(1, len(rest) // max(1, 12 - len(keep)))
    pick = sorted(keep | set(rest[::step]))[:12]
    cols = 4
    rows = (len(pick) + cols - 1) // cols
    tw, th = 400, 500
    sheet = Image.new("RGB", (cols * tw, rows * th), (8, 6, 12))
    dr = ImageDraw.Draw(sheet)
    for k, i in enumerate(pick):
        f, st, t = frames[i]
        im = Image.open(f).resize((tw, th))
        sheet.paste(im, ((k % cols) * tw, (k // cols) * th))
        dr.rectangle([(k % cols) * tw, (k // cols) * th, (k % cols) * tw + 230, (k // cols) * th + 22], fill=(0, 0, 0))
        dr.text(((k % cols) * tw + 6, (k // cols) * th + 5), "%d  +%.0f s  %s" % (i, t, st), fill=(255, 210, 60))
    sheet.save(OUT + ".jpg", quality=82)
    print("sheet:", OUT + ".jpg")
except ImportError:
    print("(no PIL: no contact sheet)")
print("ALL OK" if ok else "FAILED")
sys.exit(0 if ok else 1)
