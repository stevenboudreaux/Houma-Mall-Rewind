#!/usr/bin/env python3
"""Load phases and the first 30 s of frame times of a web export, in headless Chromium (SwiftShader).

usage: python3 tools/qa/frametimes.py <url-path> <out.json> [--secs 30] [--runs 1] [--label name] [--size 480x270] [--noflip]
       (server on :8765 serving the repo root; <url-path> may carry ?wing=, &pack=, &warm=0 …)

Workstream H (Nov 1 2026, design/godot-performance.md). Records, relative to navigation start:
  wasm_ms / pck_ms    resource timing responseEnd of index.wasm and of the .pck
  engine_ms           engine.startGame() resolved (web/shell.html window.__mallEngineAt; 0 on older builds)
  card_ms             the loading card was removed
  setup_ms            npcs.gd printed "npcs: grid ..." (the wing's scene, grid and shoppers are set up);
                      wings without that node (2026) use the card's removal for setup and control
  control_ms          the first frame after both = time-to-control
  log                 every console line with its time (Godot's own prints: npcs, npc_warmup …)
then every requestAnimationFrame interval for --secs seconds after control (Godot's web main
loop runs on rAF, so these are its frame times). SwiftShader renders on the CPU: compare runs
with each other, not with a phone.
"""
import json
import statistics
import sys
import time

from playwright.sync_api import sync_playwright

ARGS = ["--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"]
INIT = """
(() => {
  window.__ftLog = [];
  for (const k of ['log', 'warn', 'error', 'info']) {
    const o = console[k].bind(console);
    console[k] = (...a) => {
      try {
        const line = a.join(' ');
        window.__ftLog.push([performance.now(), line.slice(0, 300)]);
        // npcs.gd prints this once the wing's setup (and, since workstream H, the warm-up) is done
        if (line.startsWith('npcs: grid') && !window.__ftSetupAt) window.__ftSetupAt = performance.now();
      } catch (e) {}
      o(...a);
    };
  }
  window.__ftFrames = [];
  let last = 0;
  new MutationObserver(() => {
    if (!window.__ftCardAt && document.body && !document.getElementById('status')) window.__ftCardAt = performance.now();
  }).observe(document, {childList: true, subtree: true});
  const tick = () => {
    // performance.now(), not the rAF argument: callbacks of one frame share its start time, which
    // hides a long frame (the scene load) from every callback after Godot's own
    const t = performance.now();
    // the card lifting (builds before workstream H lift it when the engine starts, before the scene loads)
    if (!window.__ftCardAt && document.readyState !== 'loading' && !document.getElementById('status')) window.__ftCardAt = t;
    // wings without the shopper node (the 2026 year) never print it: the card lifting is the mark
    if (!window.__ftSetupAt && window.__ftCardAt && t - window.__ftCardAt > 5000) { window.__ftSetupAt = window.__ftCardAt; window.__ftPlayAt = window.__ftCardAt; window.__ftNoNpcs = true; }
    // playable: the first frame after the wing's setup finished, with the card gone
    if (!window.__ftPlayAt && window.__ftSetupAt && window.__ftCardAt) window.__ftPlayAt = t;
    if (window.__ftPlayAt) {
      if (last) window.__ftFrames.push([t, t - last]);
      last = t;
    }
    requestAnimationFrame(tick);
  };
  requestAnimationFrame(tick);
})();
"""


def stats(d):
    if not d:
        return {}
    s = sorted(d)
    med = statistics.median(s)
    pick = lambda q: s[min(len(s) - 1, int(q * len(s)))]
    return {"frames": len(s), "median_ms": round(med, 1), "p95_ms": round(pick(0.95), 1),
            "p99_ms": round(pick(0.99), 1), "max_ms": round(s[-1], 1),
            "over_3x_median": sum(1 for x in s if x > 3 * med),
            "over_250ms": sum(1 for x in s if x > 250), "over_500ms": sum(1 for x in s if x > 500),
            "sum_over_median_ms": round(sum(max(0.0, x - med) for x in s), 0)}


def run(pg, url, secs):
    pg.goto(url)
    t0 = time.time()
    while time.time() - t0 < 400:
        try:
            if pg.evaluate("!!window.__ftPlayAt"):
                break
        except Exception:
            pass
        time.sleep(0.5)
    else:
        return {"error": "not playable in 400 s"}
    time.sleep(secs + 1)
    r = pg.evaluate("""(() => {
      const res = performance.getEntriesByType('resource');
      // the first .pck is this wing; later ones are the shell's prefetch of the next wing
      const f = (s) => { const e = res.filter(x => x.name.includes(s)); return e.length ? Math.round(e[0].responseEnd) : null; };
      return {wasm_ms: f('.wasm'), pck_ms: f('.pck'), engine_ms: Math.round(window.__mallEngineAt || 0),
              godot_ms: (window.__ftLog.find(x => x[1].startsWith('Godot Engine')) || [null])[0],
              card_ms: Math.round(window.__ftCardAt || 0), setup_ms: Math.round(window.__ftSetupAt || 0),
              control_ms: Math.round(window.__ftPlayAt || 0), pack: window.__mallPack,
              packs: res.filter(x => x.name.includes('.pck')).map(x => [x.name.split('/').pop(), Math.round(x.startTime), Math.round(x.responseEnd)]),
              frames: window.__ftFrames, log: window.__ftLog.map(x => [Math.round(x[0]), x[1]])};
    })()""")
    c = r["control_ms"]
    d = [x[1] for x in r["frames"] if x[0] - c <= secs * 1000]
    r["stats"] = stats(d)
    r["frames"] = [[round(t - c), round(dt, 1)] for t, dt in r["frames"] if t - c <= secs * 1000]
    return r


def main(argv):
    path, out = argv[0], argv[1]
    secs = float(argv[argv.index("--secs") + 1]) if "--secs" in argv else 30.0
    runs = int(argv[argv.index("--runs") + 1]) if "--runs" in argv else 1
    label = argv[argv.index("--label") + 1] if "--label" in argv else path
    # SwiftShader's frame time is mostly fill: a small view makes frames short enough for stalls to show
    size = [int(x) for x in argv[argv.index("--size") + 1].split("x")] if "--size" in argv else [1280, 720]
    res = []
    with sync_playwright() as p:
        b = p.chromium.launch(args=ARGS)
        for i in range(runs):
            ctx = b.new_context(viewport={"width": size[0], "height": size[1]})
            ctx.add_init_script(INIT)
            if "--noflip" in argv:
                # SwiftShader has no BPTC: keep the desktop pack instead of mall_runtime.gd's one switch
                ctx.add_init_script("try { sessionStorage.setItem('southland-pack-flip', '1'); } catch (e) {}")
            pg = ctx.new_page()
            r = run(pg, "http://127.0.0.1:8765/" + path, secs)
            r["label"] = label
            res.append(r)
            s = r.get("stats", {})
            print("%s run %d: wasm %s pck %s godot %s engine %s card %s setup %s control %s ms | %s" % (label, i + 1, r.get("wasm_ms"), r.get("pck_ms"), r.get("godot_ms"), r.get("engine_ms"), r.get("card_ms"), r.get("setup_ms"), r.get("control_ms"), s))
            for t, line in r.get("log", []):
                if any(k in line for k in ("npcs:", "npc_warmup", "ERROR", "load:")):
                    print("   %7d ms  %s" % (t, line[:160]))
            ctx.close()
        b.close()
    json.dump(res, open(out, "w"), indent=1)


if __name__ == "__main__":
    main(sys.argv[1:])
