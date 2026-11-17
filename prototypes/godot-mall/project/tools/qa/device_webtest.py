"""PHONE-MEMORY (Nov 17 2026; web/shell.html mallDeviceKind, scripts/wing_stream.gd kind): the streaming behaviour
follows the kind of device, not the texture pack.

Steven's iPhone offers S3TC + BPTC, so the page gives it the desktop pack; before Nov 17 the streamer took its
behaviour from the pack and loaded every interior wing behind the load screen (UPFRONT), which crashed the phone.

  python3 tools/qa/device_webtest.py <url-path> <out-prefix>      (the build served on :8765)

1. A fake iPhone (touch, 390 x 844, an iPhone user agent) on a GPU that offers S3TC + BPTC (swiftshader does): the
   page must pick the desktop pack AND the phone behaviour: no up-front load (window.__mallUpfrontOn false, no other
   wing's pack asked for), the load screen lifts with wing 1 alone, the streamer's kind is mobile and streaming is off
   (data/stream.json "enabled" mobile false), and for 60 s after the lift no other wing comes in or is fetched.
   The menu's QA tab is photographed (<out>-phone-qa.png): pack "desktop", behaviour "phone / tablet".
2. A computer (mouse, 1280 x 720, the default user agent): the desktop pack and the computer behaviour (the up-front
   load is on and asks for the other interior wings). Stops once that is seen (the up-front load itself is
   stream_natural_walk_webtest.py's).
Prints DEVICE WEB OK, or the failures.
"""
import json, os, sys, time
from playwright.sync_api import sync_playwright

path, out = sys.argv[1], sys.argv[2]
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"]
IPHONE_UA = ("Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) "
             "Version/18.6 Mobile/15E148 Safari/604.1")
fails = []


def fail(s):
    fails.append(s)
    print("FAIL", s, flush=True)


with sync_playwright() as p:
    exe = os.environ.get("CHROMIUM") or ("/opt/pw-browsers/chromium" if os.path.exists("/opt/pw-browsers/chromium") else None)
    b = p.chromium.launch(args=ARGS, executable_path=exe) if exe else p.chromium.launch(args=ARGS)
    # ---- 1. the fake iPhone
    ctx = b.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=1, is_mobile=True, has_touch=True,
                        user_agent=IPHONE_UA)
    pg = ctx.new_page()
    errors, packs = [], []
    pg.on("pageerror", lambda e: errors.append(str(e)))
    pg.on("request", lambda r: packs.append(r.url.rsplit("/", 1)[-1]) if r.url.endswith(".pck") else None)
    t0 = time.time()
    pg.goto(f"http://127.0.0.1:8765/{path}?qa=1", timeout=180000)
    early = pg.evaluate("({pack: window.__mallPack, device: window.__mallDevice, upfront: window.__mallUpfrontOn,"
                        " wings: window.__mallUpfrontWings, coarse: matchMedia('(pointer: coarse)').matches,"
                        " hover_none: matchMedia('(hover: none)').matches})")
    print(json.dumps({"phone_page": early}), flush=True)
    if early["pack"] != "desktop":
        fail(f"the fake phone got the {early['pack']} pack (this test needs a GPU that offers S3TC + BPTC)")
    if early["device"] != "mobile":
        fail(f"the fake phone was taken for a {early['device']}")
    if early["upfront"] or early["wings"]:
        fail(f"the fake phone asked for the whole interior up front: {early['wings']}")
    while time.time() - t0 < 900:
        if pg.evaluate("!document.getElementById('status')"):
            break
        pg.wait_for_timeout(2000)
    else:
        fail("the load screen did not lift in 900 s")
    lift_s = round(time.time() - t0)
    seen = []
    t1 = time.time()
    while time.time() - t1 < 60:
        m = pg.evaluate("window.__mallMem || {}")
        seen.append({"wings": m.get("wings"), "states": m.get("states"), "kind": m.get("kind"), "streaming": m.get("streaming")})
        pg.wait_for_timeout(5000)
    last = seen[-1]
    print(json.dumps({"phone_lift_s": lift_s, "phone_after": last, "packs_asked": sorted(set(packs))}), flush=True)
    if last.get("kind") != "mobile":
        fail(f"the streamer's behaviour on the fake phone is {last.get('kind')}")
    if last.get("streaming"):
        fail("streaming is on on the fake phone (data/stream.json enabled.mobile is false)")
    if any((s.get("wings") or [1]) != [1] or s.get("states") for s in seen):
        fail(f"another wing came in on the fake phone: {seen}")
    others = [n for n in set(packs) if n.startswith("w") and not n.startswith("w1.")]
    # the old prefetch keeps the next files in Cache Storage (disk), as on Demo 54: allowed; a wing fetched for the
    # streamer would show as window.__mallStream
    st = pg.evaluate("window.__mallStream || {}")
    if st:
        fail(f"the page fetched wings for the streamer on the fake phone: {st}")
    pg.focus("#canvas")
    pg.keyboard.press("Tab")
    pg.wait_for_timeout(3000)
    for _ in range(3):
        pg.keyboard.press("e")
        pg.wait_for_timeout(2500)
    pg.wait_for_timeout(3000)
    pg.screenshot(path=f"{out}-phone-qa.png", timeout=300000)
    txt = pg.evaluate("window.__mallMem ? 1 : 0")
    if errors:
        fail(f"{len(errors)} page errors on the fake phone: {errors[:3]}")
    ctx.close()
    # ---- 2. a computer
    ctx = b.new_context(viewport={"width": 1280, "height": 720})
    pg = ctx.new_page()
    pg.goto(f"http://127.0.0.1:8765/{path}?qa=1", timeout=180000)
    comp = pg.evaluate("({pack: window.__mallPack, device: window.__mallDevice, upfront: window.__mallUpfrontOn, wings: window.__mallUpfrontWings})")
    print(json.dumps({"computer_page": comp}), flush=True)
    if comp["device"] != "desktop" or comp["pack"] != "desktop":
        fail(f"the computer got {comp}")
    if not comp["upfront"] or sorted(comp["wings"] or []) != [2, 4, 5]:
        fail(f"the computer did not ask for the interior up front: {comp}")
    ctx.close()
    b.close()
print("DEVICE WEB OK" if not fails else "DEVICE WEB FAILED (%d)" % len(fails))
