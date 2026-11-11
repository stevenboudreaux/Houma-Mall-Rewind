#!/usr/bin/env python3
"""FLOOR-FIX (Nov 11 2026, design/godot-floor-lighting-diagnosis.md): Steven's two floor walks on a web
export, in headless Chromium (SwiftShader), once with ?floorspec=0.25 (Demos 51-53) and once as built.

usage: python3 tools/qa/floor_webwalk.py <url-path> <out-prefix> [1995|2026 ...]
       (python3 -m http.server 8765 at the repo root; <url-path> e.g.
        prototypes/godot-mall/project/.scratch/builds/<name>/index.html)

Per year, camera and variant: load at ?cam=, then STEPS times: screenshot, hold W for 0.6 s. Frame 00 is
the same pose in both variants. Also counts rAF frames over the walk (SwiftShader: compare the two
variants with each other, not with a phone). One browser, one page at a time; prints errors per load.
Writes <out>-<year>-<cam>-<before|after>-<nn>.png.
"""
import json
import sys

from playwright.sync_api import sync_playwright

path, out = sys.argv[1], sys.argv[2]
years = sys.argv[3:] or ["1995", "2026"]
CAMS = {"a": "-7,16,0,-14", "b": "-4,-44,0,-10"}   # H4 at Woolworth toward court C2; H2 Kay-Bee / Sound Shop
VARIANTS = {"before": "&floorspec=0.25", "after": ""}
STEPS = 6
ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"]
RAF = """(() => { window.__fw = []; let last = performance.now();
  const tick = (t) => { window.__fw.push(t - last); last = t; requestAnimationFrame(tick); };
  requestAnimationFrame(tick); })();"""

res = {}
with sync_playwright() as p:
    b = p.chromium.launch(args=ARGS)
    for y in years:
        for cn, cam in CAMS.items():
            for vn, vq in VARIANTS.items():
                ctx = b.new_context(viewport={"width": 960, "height": 540})
                pg = ctx.new_page()
                logs = []
                pg.on("console", lambda m: logs.append(m.text))
                pg.add_init_script(RAF)
                yq = "&year=2026" if y == "2026" else ""
                pg.goto(f"http://127.0.0.1:8765/{path}?wing=1{yq}&pack=desktop&cam={cam}{vq}", timeout=180000)
                for _ in range(400):   # web/shell.html sets __mallControlAt when the loading card lifts
                    if pg.evaluate("!!window.__mallControlAt"):
                        break
                    pg.wait_for_timeout(1000)
                pg.wait_for_timeout(15000)
                pg.evaluate("document.querySelector('canvas').focus()")
                pg.wait_for_timeout(1500)
                pg.evaluate("window.__fw = []")
                for n in range(STEPS):
                    pg.screenshot(path=f"{out}-{y}-{cn}-{vn}-{n:02d}.png", timeout=180000)
                    pg.keyboard.down("w")
                    pg.wait_for_timeout(600)
                    pg.keyboard.up("w")
                    pg.wait_for_timeout(1200)
                fw = sorted(pg.evaluate("window.__fw"))
                errs = [l for l in logs if "ERROR" in l.upper()]
                med = fw[len(fw) // 2] if fw else 0
                res[f"{y}-{cn}-{vn}"] = {"frames": len(fw), "median_ms": round(med, 1), "mean_ms": round(sum(fw) / max(1, len(fw)), 1), "errors": len(errs)}
                print(y, cn, vn, res[f"{y}-{cn}-{vn}"], errs[:3], flush=True)
                ctx.close()
    b.close()
json.dump(res, open(out + "-frames.json", "w"), indent=1)
