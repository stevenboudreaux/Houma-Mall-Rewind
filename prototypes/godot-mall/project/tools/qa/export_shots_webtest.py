"""PHONE-MEMORY stage 2 (Nov 18 2026; production/qa/evidence/wsPHONE-MEMORY-options.md): matched before/after shots
from two real web exports (as shipped against an option's build), the same camera, the same lighting, so the
pictures are what a phone will draw from those packs. Replaces tools/qa/phone_options_shots.gd's run-time swap.

  python3 tools/qa/export_shots_webtest.py <out-prefix> <year> <label-a>=<url-a> <label-b>=<url-b> [packs]
    url: a build's index.html on a local server, e.g. http://127.0.0.1:8765/build59/index.html
    packs: "desktop,mobile" (default): each build is shot with its desktop pack (S3TC, what an iPhone takes since
           Nov 17) and its phone pack (ETC2 / ASTC)

Each shot is one page load: ?wing=<w>&cam=x,z,yaw,pitch&hour=13&time=day&stream=0&device=desktop&pack=<p>, people
off (?npcs=0) except where a shot is of a person. One wing, no streaming: only what the camera sees differs. The
page waits for the load screen to lift, then 12 s, then the canvas is saved as <out>-<shot>-<label>-<pack>.png.
Prints EXPORT SHOTS OK, or the failures.
"""
import os, sys, time
from playwright.sync_api import sync_playwright

out, year = sys.argv[1], sys.argv[2]
builds = [a.split("=", 1) for a in sys.argv[3:5]]
packs = (sys.argv[5] if len(sys.argv) > 5 else "desktop,mobile").split(",")
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"]
# [name, wing, x, z, yaw, pitch, people]: the brief's spots (wing 1 spawn looking at the wing 2 border, a storefront
# sign up close, a floor with lightmap shadow, Dillard's, Sears / Lynn's) and two close-ups (an item, a person)
SHOTS = {
    "1995": [
        ("border", 1, -9, 40, 180, 0, False),
        ("floor", 1, -9, 24, 180, -38, False),
        ("sears", 1, -4, -84, 0, 0, False),
        ("sign", 1, -2.4, -47.4, 69.4, 36, False),
        ("item", 1, 6.0, 31.15, 69.4, -19, False),
        ("cast", 1, 24.45, -73.83, 69.4, 2, True),
        ("dillards", 2, -4, 70, 180, 0, False),
    ],
    "2026": [
        ("border", 1, -9, 40, 180, 0, False),
        ("floor", 1, -9, 24, 180, -38, False),
        ("lynns", 1, -4, -84, 0, 0, False),
        ("sign", 1, -46.7, -85.32, 69.4, -5, False),
        ("item", 2, -35.4, 61.12, 69.4, -10, False),
        ("dillards", 2, -4, 70, 180, 0, False),
    ],
}[year]
if os.environ.get("ONLY"):        # ONLY=border,sign: just these shots
    SHOTS = [s for s in SHOTS if s[0] in os.environ["ONLY"].split(",")]
fails = []
with sync_playwright() as p:
    exe = os.environ.get("CHROMIUM") or ("/opt/pw-browsers/chromium" if os.path.exists("/opt/pw-browsers/chromium") else None)
    b = p.chromium.launch(args=ARGS, executable_path=exe) if exe else p.chromium.launch(args=ARGS)
    for label, url in builds:
        ctx = b.new_context(viewport={"width": 1280, "height": 720})     # one context a build: its packs stay cached
        for pack in packs:
            for (name, wing, x, z, yaw, pitch, people) in SHOTS:
                pg = ctx.new_page()
                errs = []
                pg.on("pageerror", lambda e: errs.append(str(e)))
                q = (f"wing={wing}&cam={x},{z},{yaw},{pitch}&hour=13&time=day&stream=0&device=desktop&pack={pack}"
                     + ("&year=2026" if year == "2026" else "") + ("" if people else "&npcs=0"))
                t0 = time.time()
                pg.goto(f"{url}?{q}", timeout=300000)
                while time.time() - t0 < 1800:
                    if pg.evaluate("!document.getElementById('status')"):
                        break
                    pg.wait_for_timeout(2000)
                else:
                    fails.append(f"{name} {label} {pack}: the load screen did not lift")
                pg.wait_for_timeout(12000)
                f = f"{out}-{name}-{label}-{pack}.png"
                pg.locator("#canvas").screenshot(path=f, timeout=300000)
                got = pg.evaluate("window.__mallPack")
                if got != pack:
                    fails.append(f"{name} {label}: asked for the {pack} pack, got {got}")
                if errs:
                    fails.append(f"{name} {label} {pack}: page errors {errs[:2]}")
                print(f"wrote {f} ({round(time.time() - t0)} s)", flush=True)
                pg.close()
        ctx.close()
    b.close()
print("EXPORT SHOTS OK" if not fails else "EXPORT SHOTS FAILED (%d)\n  " % len(fails) + "\n  ".join(fails))
