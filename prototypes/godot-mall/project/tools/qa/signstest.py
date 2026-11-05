"""Headless check of the owner-editable signs (scripts/signs.gd) in a web export.

Usage: python3 signstest.py <url-path> <out-prefix>   (server on :8765 serving the repo root)
1. Loads as the owner with a draft in localStorage and shoots Pocket Change and Kay-Bee.
2. Turns on "Edit signs", clicks a marquee, answers the prompt, and checks the draft.
"""
import json, sys, time
from playwright.sync_api import sync_playwright

path, out = sys.argv[1], sys.argv[2]
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"]
DRAFT = {"pc.video.01": "SWAMP FIGHTER", "pc.video.03": "BAYOU BLITZ", "kb.dept.1": "DOLL HOUSE", "kb.dept.2": "CARS & TRUCKS"}
CAMS = {"pc": "-106.7,71.8,90,2", "kb": "-9.6,-56.0,90,14"}


def ready(pg, t=240):
    t0 = time.time()
    while time.time() - t0 < t:
        if pg.evaluate("(()=>{var s=document.querySelector('#status');return !s||getComputedStyle(s).display==='none'||getComputedStyle(s).visibility==='hidden'})()"):
            return time.time() - t0
        time.sleep(1)
    return None


with sync_playwright() as p:
    b = p.chromium.launch(args=ARGS)
    for name, cam in CAMS.items():
        ctx = b.new_context(viewport={"width": 1280, "height": 720})
        ctx.add_init_script("localStorage.setItem('southland-editor','1');localStorage.setItem('southland-signs-draft'," + json.dumps(json.dumps(DRAFT)) + ")")
        pg = ctx.new_page(); logs = []
        pg.on("console", lambda m: logs.append(m.text))
        pg.goto(f"http://127.0.0.1:8765/{path}?cam={cam}")
        print(name, "ready", ready(pg)); time.sleep(12)
        pg.screenshot(path=f"{out}-{name}.png", timeout=180000)
        errs = [l for l in logs if "ERROR" in l.upper() or "SCRIPT" in l.upper()]
        print(name, "errors", len(errs), errs[:4], [l for l in logs if "SIGNS" in l])
        ctx.close()
    # the edit flow: Edit signs, click the third cabinet's marquee, type a name
    ctx = b.new_context(viewport={"width": 1280, "height": 720})
    ctx.add_init_script("localStorage.setItem('southland-editor','1');localStorage.removeItem('southland-signs-draft')")
    pg = ctx.new_page(); logs = []
    pg.on("console", lambda m: logs.append(m.text))
    asked = []
    pg.on("dialog", lambda d: (asked.append(d.message), d.accept("TEST TITLE")))
    pg.goto(f"http://127.0.0.1:8765/{path}?cam=-106.7,72.47,90,1")
    ready(pg); time.sleep(10)
    # OWNER (design/godot-owner-mode.md): Edit signs is in the menu's OWNER tab now, not top left:
    # Tab opens MAIN, E three times reaches OWNER, right + Enter shows TOOLS, then the Signs row
    # (rows: view switch, owner HUD, quick jump, year, signs) and Enter turns Edit signs on.
    pg.keyboard.press("Tab"); time.sleep(1)
    for _ in range(3):
        pg.keyboard.press("e"); time.sleep(0.6)
    pg.keyboard.press("ArrowRight"); time.sleep(0.4)
    pg.keyboard.press("Enter"); time.sleep(1)
    for _ in range(4):
        pg.keyboard.press("ArrowDown"); time.sleep(0.3)
    pg.keyboard.press("Enter"); time.sleep(1.5)
    pg.mouse.click(640, 345); time.sleep(3)
    pg.screenshot(path=f"{out}-edit.png", timeout=180000)
    print("prompt:", asked[:1])
    print("draft:", pg.evaluate("localStorage.getItem('southland-signs-draft')"))
    errs = [l for l in logs if "ERROR" in l.upper() or "SCRIPT" in l.upper()]
    print("edit errors", len(errs), errs[:4])
    ctx.close(); b.close()
