"""Web check of the four shops (workstream SHOPS, Steven Nov 3 2026; design/godot-shops.md).

Usage: CHROMIUM=/opt/pw-browsers/chromium python3 tools/qa/shops_webtest.py <url-path of the build's index.html> <out-prefix> [w1|w2|both] [phone]
(a server on :8765 serving the repo root). 1995, desktop 1280 x 720 (or 390 x 844 with "phone"), a new player:
for each counter: stand at its talk spot (?cam=), press E (the attendant's TALK): the shop's list opens beside the
attendant's face (screenshot -open); Enter buys the first thing (the "You received" card: screenshot -bought);
E dismisses the card; Esc closes the list. Checks localStorage: the wallet went down by exactly the price, once,
and the item is in mall-state-1995's bag; after a reload both are still there. Prints SHOPS WEB OK or FAILED and
the console errors (expect 0).
"""
import json, os, sys, time
from playwright.sync_api import sync_playwright

path, out = sys.argv[1], sys.argv[2]
which = sys.argv[3] if len(sys.argv) > 3 else "both"
phone = len(sys.argv) > 4 and sys.argv[4] == "phone"
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"]
HERE = os.path.dirname(os.path.abspath(__file__))
SHOPS = json.load(open(os.path.join(HERE, "../../data/story/shops.json")))["shops"]
# ?cam=x,z,yaw,pitch (yaw 0 faces -z, 90 faces -x, 180 faces +z): a step back from each talk spot, facing the counter
COUNTERS = [
    ("woolworth", 1, "-17.5,-10.15,0,-8"),
    ("radioshack", 1, "8.2,30.2,180,-8"),
    ("corn_dog_7", 2, "-136.35,75.6,-90,-8"),
    ("b_dalton", 2, "-106.95,44.2,90,-8"),
]
fails = []


def check(ok, what):
    print(("ok   " if ok else "FAIL ") + what, flush=True)
    if not ok:
        fails.append(what)


def ready(pg, t=900):
    t0 = time.time()
    while time.time() - t0 < t:
        try:
            if pg.evaluate("!!window.mallRoms && !document.getElementById('status')"):
                return round(time.time() - t0)
        except Exception:
            pass
        time.sleep(2)
    return None


def state(pg):
    return pg.evaluate("""() => ({money: localStorage.getItem('mall.money'),
        st: JSON.parse(localStorage.getItem('mall-state-1995') || '{}')})""")


def count(st, item):
    n = 1 if st.get("hand") == item else 0
    for e in st.get("inventory", []):
        if e.get("id") == item:
            n += int(e.get("count", 0))
    return n


def key(pg, k, wait=1.5):
    pg.keyboard.down(k)
    time.sleep(0.15)
    pg.keyboard.up(k)
    time.sleep(wait)


def shot(pg, name):
    p = "%s-%s.png" % (out, name)
    pg.screenshot(path=p)
    try:
        from PIL import Image
        im = Image.open(p).convert("RGB")
        im.thumbnail((1600, 1600))
        im.save(p[:-4] + ".jpg", quality=86)
        os.remove(p)
    except Exception:
        pass


errors = []
with sync_playwright() as p:
    b = p.chromium.launch(args=ARGS, executable_path=os.environ.get("CHROMIUM") or None)
    vp = {"width": 390, "height": 844} if phone else {"width": 1280, "height": 720}
    ctx = b.new_context(viewport=vp, device_scale_factor=1)
    pg = ctx.new_page()
    pg.set_default_timeout(180000)
    pg.on("console", lambda m: errors.append(m.text) if m.type == "error" else None)
    pg.on("pageerror", lambda e: errors.append(str(e)))
    first = True
    for sid, wing, cam in COUNTERS:
        if which != "both" and which != "w%d" % wing:
            continue
        shop = [s for s in SHOPS if s["id"] == sid][0]
        url = "http://localhost:8765/%s?wing=%d&year=1995&cam=%s&time=day" % (path, wing, cam)
        if first:
            pg.goto(url)
            pg.evaluate("localStorage.clear()")   # a new player
            first = False
        pg.goto(url)
        t = ready(pg)
        check(t is not None, "%s: wing %d loads (%ss)" % (sid, wing, t))
        time.sleep(12)    # the attendants are placed deferred; the character pack mounts after the card lifts
        s0 = state(pg)
        m0 = int(s0["money"]) if s0["money"] else 10000
        shot(pg, "%s-approach" % sid)
        pg.mouse.click(vp["width"] // 2, vp["height"] // 3) if not phone else None
        time.sleep(0.5)
        key(pg, "e", 2.5)
        shot(pg, "%s-open" % sid)
        # the first thing on the list this wallet covers; anything before it is greyed out and Enter on it does nothing
        k = next(i for i, x in enumerate(shop["items"]) if int(x["price_cents"]) <= m0)
        item, price = shop["items"][k]["item"], int(shop["items"][k]["price_cents"])
        n0 = count(s0["st"], item)
        if k > 0:
            key(pg, "Enter", 2.0)
            sx = state(pg)
            check((int(sx["money"]) if sx["money"] else 10000) == m0 and count(sx["st"], shop["items"][0]["item"]) == count(s0["st"], shop["items"][0]["item"]),
                  "%s: can't afford %s (%d): Enter takes nothing, gives nothing" % (sid, shop["items"][0]["item"], int(shop["items"][0]["price_cents"])))
            for _ in range(k):
                key(pg, "ArrowRight", 0.4)
        key(pg, "Enter", 2.5)
        s1 = state(pg)
        m1 = int(s1["money"]) if s1["money"] else -1
        check(m1 == m0 - price, "%s: E then Enter buys %s: the wallet %s -> %s (price %d)" % (sid, item, m0, m1, price))
        check(count(s1["st"], item) == n0 + 1, "%s: %s is in the bag (%d)" % (sid, item, count(s1["st"], item)))
        shot(pg, "%s-bought" % sid)
        key(pg, "e", 1.5)          # dismiss the card
        shot(pg, "%s-line" % sid)
        key(pg, "Escape", 2.0)     # close the list
        s2 = state(pg)
        check(int(s2["money"]) == m1 and count(s2["st"], item) == n0 + 1, "%s: closing takes nothing more" % sid)
        pg.reload()
        ready(pg)
        time.sleep(4)
        s3 = state(pg)
        check(int(s3["money"]) == m1 and count(s3["st"], item) == n0 + 1, "%s: after a reload the wallet and the bag hold" % sid)
    b.close()
# a scratch build has no site files (roms.json, signs.json, shirt_text.json beside the live index.html): their 404s are not the shops'
real = [e for e in errors if "favicon" not in e and "404" not in e]
print("404s (site files a scratch build lacks): %d" % sum(1 for e in errors if "404" in e))
print("console errors: %d" % len(real))
for e in real[:20]:
    print("  " + e[:300])
print("SHOPS WEB OK" if not fails else "SHOPS WEB FAILED: %s" % fails)
sys.exit(0 if not fails else 1)
