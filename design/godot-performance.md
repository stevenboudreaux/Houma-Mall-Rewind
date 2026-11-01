# Godot mall: performance (warm-up, load time, baking on Linux)

Workstream H, Nov 1, 2026 (branch `ws/h-engine-debt`). Packs and texture formats are in
`design/godot-build-hosting.md`. Evidence: `production/qa/evidence/wsH-*.md|jpg`.

**How it was measured.** `tools/qa/frametimes.py` loads a web export in headless Chromium on SwiftShader
(the cloud box's software GPU, 4 CPUs), 480x270, the mobile pack (SwiftShader has ETC2/ASTC but no BPTC), and
records each load phase and every frame interval (Godot's web main loop runs on `requestAnimationFrame`) for 30 s
after control. "Control" is the first frame after both the loading card is gone and `npcs.gd` has printed its
`npcs: grid …` line (the wing is set up). SwiftShader draws on the CPU, so a frame here is ~1 s where a phone
takes ~20-30 ms: compare runs with each other, never with a phone. "Live" is the Demo 46 build on `godot-build`
(Oct 29) with the same lightmaps; "new" is this branch's export. Raw numbers: `production/qa/evidence/wsH-perf.md`.

## 1. NPC warm-up (first appearance stalls)

**What stalled.** Every shopper's first appearance cost the frame it happened in:
- `npc_body.gd` `load()`s the skin's `.scn` (meshes, VRAM textures) and, for the first body, `npc/anims.res`
  (2.9 MB, ~70 clips) on the main thread;
- each new body builds its AnimationPlayer's track caches for the ~70 clips (the biggest share: ~300 ms a body
  in SwiftShader, still ~100+ ms after its skin is cached);
- the first draw of each skinned material compiles its shader variant (skinning + lightmap probes; the night
  self-light would be another) and uploads its textures.
- All of this landed in the first seconds of play: the drunk, the pairs and the arcade players spawn in
  `npcs.gd` `_ready`, and the crowd's first `_balance()` (11 people in Wing 1, 6 in Wing 2) one second in.

**What the warm-up does** (`scripts/npc_warmup.gd`, started from `npcs.gd` `_ready` on the web):
1. The loading card stays up (`web/shell.html` waits for `window.__mallWarm == 1`, at most 30 s).
2. Loads `npc/anims.res` and every skin `.scn` the pack carries (19 today: the Mixamo group, `Ch*`, `Remy*`),
   400 ms of plain `load()`s per frame (the web build has no threads; the threaded loader would finish one file
   per frame), with the render loop paused (nothing behind the card is seen). The resources are held for the
   session (`NpcWarmup.held`), so every later `load()` of a skin is a cache hit. No extra memory: the crowd
   loads them all within a minute anyway ("one of each character").
3. Stands every skin as a real `NpcBody` (same tint, same self-light as the crowd) in a 5-wide block 3-6 m in front
   of the camera for 2 frames, so every material's shader is compiled and its textures are on the GPU. When
   `lighting.json` allows night (`day_only: false`), a second pass compiles the self-lit variant. Then frees them.
4. `npcs.gd` spawns the roles and the first crowd (still behind the card), then lifts the card.
- `?warm=0` turns it off (A/B tests). Native runs (editor, QA scripts) never warm up.
- Nothing is visible: the bodies exist only while the card covers the canvas (screenshots `wsH-look-*.jpg`).

**Measured** (SwiftShader, mobile pack, 2 runs each; first 30 s after control):

| Wing | Build | Time to control | Worst frame | Frames over 3x the median | Stall time (sum of frame time above the median) |
|---|---|---|---|---|---|
| 1 | live | 9.1-12.3 s | 13.5-16.1 s | 1-2 | 17.2-19.4 s |
| 1 | new, `?warm=0` | 8.2-11.0 s | 11.4-13.1 s | 2 | 17.2-17.7 s |
| 1 | new, warm-up | 24.0-27.7 s | 2.1 s | 0 | 3.9-5.7 s |
| 2 | live | 13.6-18.4 s | 23.7-23.9 s | 3-4 | 27.1-27.7 s |
| 2 | new, `?warm=0` | 17.9-20.3 s | 13.4-23.3 s | 4-8 | 23.8-26.8 s |
| 2 | new, warm-up | 35.2-43.4 s | 3.4-4.8 s | 0-1 | 7.4-8.7 s |

- The warm-up moves the stalls behind the card: the worst frame in the first 30 s of play drops from 13-24 s to
  2-5 s in SwiftShader (5-7x), and the total stall time by 3-4x. What remains are ordinary frames with the whole
  crowd on stage (SwiftShader skins every character on the CPU) and later spawns (a retired shopper's
  replacement, each a new AnimationPlayer).
- The cost is time behind the card: in SwiftShader the warm-up itself takes 20-37 s (load 0.1-0.3 s, bodies
  4-16 s, drawing them 15-24 s: SwiftShader compiles shaders slowly). Measured from opening the page to a
  smooth mall, the total is about the same as before; the difference is that the waiting happens on the loading
  card with a progress line ("Getting the shoppers ready… 12/20") instead of as freezes while you walk.
- Wing 2's numbers are larger because it also spawns the five arcade players in Pocket Change.

**What to expect on an iPhone** (estimate, not measured; no device here). Safari runs WebGL2 on Metal through
ANGLE, where a new shader program typically costs 50-300 ms to compile and link, and a body's set-up (scene
instance + AnimationPlayer caches for ~70 clips) perhaps 20-60 ms on an A15-A17 in WebAssembly.
- Before: the first few seconds of play had hitches of roughly 0.3-1 s (the first crowd of 11 at the one-second
  mark: ~11 x 40 ms of set-up plus the first draws' compiles), then single 50-300 ms hitches as each new skin's
  material first came into view.
- After: those move to the loading card, which should get longer by roughly 1-3 s (19 loads from memory, 19 body
  set-ups, 1-3 shader variants, texture uploads), and play should start without them. Respawns while walking
  still cost one body set-up each (~20-60 ms, out of sight).
- Worth checking on the phone: the loading card's progress line, then the first 30 s walking from the main
  entrance with Safari's Web Inspector timeline (frames over 50 ms).

**Not done (possible next steps).**
- Pool bodies instead of creating one per spawn (the warm-up's bodies could become the crowd's): removes the
  per-spawn AnimationPlayer cost entirely. Needs `npcs.gd` to reuse `NpcBody` nodes; a bigger change to a file
  other sessions may touch.
- The AnimationPlayer's ~70-clip library could be split so a body only caches the clips its sex and type use.

## 2. Load time (time to control per wing and year)

Measured per wing, year and pack (one run each, SwiftShader, packs from localhost so download is ~0; raw
numbers and every phase in `production/qa/evidence/wsH-perf.md`). "Setup" is the wing's scene loaded and its
shoppers set up; "control" the first frame you can walk, card gone.

| Wing | Year | Pack MB | Live: setup / control (s) | New: setup / control (s) | Why it changed |
|---|---|---|---|---|---|
| 1 | 1995 | 83.7 | 4.6-5.2 / 11.3-11.9 | 24.9-27.6 / 25.1-27.8 | warm-up behind the card (+); grid (-1 s) |
| 2 | 1995 | 80.4 | 4.8-5.2 / 17.9-18.5 | 40.2-42.2 / 42.2-44.5 | warm-up behind the card (+); grid (-1 s) |
| 3 (outside) | 1995 | 12.6 | 10.2-10.5 / 12.2 | 2.3-2.5 / 4.1-4.3 | no shopper grid where there are no shoppers |
| 1 | 2026 | 20.7 | 5.7 / 5.7 | 5.5-5.6 / 5.5-5.6 | unchanged |
| 2 | 2026 | 51.6 | 13.6-14.0 / 13.6-14.0 | 14.4 / 14.4 | unchanged (within run-to-run noise) |

Both packs load alike (desktop vs mobile within noise; SwiftShader decodes the desktop pack's BPTC lightmap on the
CPU, which a real desktop GPU does not). Without the warm-up (`?warm=0`), Wing 1 reached control in 8.2-11.0 s
and Wing 2 in 17.9-20.3 s (live: 9.1-12.3 and 13.6-18.4 s): the faster grid, then the same stalls as live.

**Where the time goes, biggest first** (for an iPhone on a real line; SwiftShader shows only the CPU-side parts):
1. **Download.** Wing 1's pack is 83.7 MB (+ the 39.5 MB engine `index.wasm`, 10.1 MB gzipped, if Pages compresses it as it usually does wasm):
   ~27 s at 25 Mbit/s (LTE), ~13 s at 50, ~7 s at 100. Nothing else comes close. The packs gzip to 55-58 % of
   their size (Wing 1: 83.7 → 48.2 MB), but GitHub Pages normally sends `.pck` (application/octet-stream)
   uncompressed (not checkable from the cloud box: github.io is blocked by its proxy). **Not done; the biggest
   win left:** export a `.pck.gz` beside each pack and have `web/shell.html`'s existing pack `fetch` hook read it
   through `DecompressionStream('gzip')` (Safari 16.4+, Chrome 80+), keeping the plain `.pck` as fallback;
   `tools/publish_build.sh` must copy the `.gz` files and the prefetch (`mallPrefetchOther`) must cache them.
   First check what Pages actually sends: `curl -sI -H 'Accept-Encoding: gzip' …/play/w3.mobile.pck` from a
   computer (if it already says `content-encoding: gzip`, there is nothing to win).
2. **Shoppers' first appearance** (load, AnimationPlayer set-up, shader compiles): now behind the card,
   section 1. Estimated +1-3 s of card on an iPhone, minus the same in hitches.
3. **First frames: the mall's own shaders and texture uploads** (live: 7-13 s in SwiftShader between setup and
   the card lifting; it includes the shoppers' first spawn). On a phone probably 1-3 s; not measured here.
4. **Scene instancing and texture decoding:** Wing 1's scene is set up ~1.1 s after start natively. Of that,
   decoding its 152 WebP textures takes 0.44 s natively (51 ETC2 textures: 0.013 s); ~1 s in WebAssembly. Making
   them VRAM textures would remove most of it and ~110 MB of GPU memory, but changes the look slightly
   (`design/godot-build-hosting.md`, proposal; needs Steven's yes).
5. **The shoppers' path grid:** was 0.85 s native / 1.4 s SwiftShader in Wing 1 and ~8 s in the outside (a
   402x402 grid for nobody). **Fixed:** 70-105 ms native with identical cells in Wings 1 and 2, skipped in packs
   without shopper skins (`scripts/npcs.gd`; `production/qa/evidence/wsH-npcgrid.md`).

**Also fixed:** the loading card's lifting is now tied to the game being ready (`window.__mallWarm`, set by the
warm-up path, by `npcs.gd` when it has nothing to warm, or by `mall_runtime.gd` right after the first deferred
calls in wings without shoppers), with a 30 s cap and a 10-frame fallback for a pack that never says.

## 3. Baking on Linux: `tools/bake_inplace.sh`

For the next bake on a Linux box (a cloud session, or a Linux machine instead of Steven's Mac). It wraps what
Demo 45/46 did by hand and leaves the work tree as it was, except for the new lightmap files.

```bash
cd prototypes/godot-mall/project
tools/bake_inplace.sh 3 fastday --make-swap        # wing 3 (outside), Medium; 1/2 = the inside wings
tools/bake_inplace.sh 2 fastday --year=2026         # Wing 2's 2026 scene
tools/bake_inplace.sh 1 day --dry-run               # every step except the bake
```

**Before it runs** (it checks each and stops with the fix):
- Godot 4.7.2 on PATH, `xvfb-run`, and a software Vulkan driver for the lightmapper: `apt-get install -y
  mesa-vulkan-drivers` (lavapipe). The editor itself runs on OpenGL (the project is GL Compatibility).
- **Swap: about 12 GB.** Wing bakes at High/Ultra are killed by the OOM killer without it (a 15 GB box).
  `--make-swap` makes `/swapfile` (root; containers may refuse `swapon`; this one allowed it). Medium (fast) bakes
  of the outside fit in RAM, so the script only warns for them.
- The stand-in pictures and the other lightmaps from `godot-build` (CLAUDE-CLOUD.md setup step 3), a finished
  import (step 4), and no uncommitted changes to tracked files under the project (the editor's side effects
  could not be told apart from your work).

**What it does:** build the wing (`tools/build_mall.gd`) → bake in place (`AUTOBAKE="<scene>:<mode>"`, the
editor under xvfb with `addons/autobake`) → `git checkout` everything the editor changed after the build (the
`.import` flips from `detect_3d`, `project.godot`, `gen/env_day.tres`, `gen/env_night.tres`, re-saved `gen/`
meshes, the re-saved scene) and delete untracked files it created → drop the stale `.godot/imported` copy of the
new `.exr` and `godot --headless --import` → rebuild the wing so the scene is in build form → put back every
lightmap file except `<scene>_<mode>.{exr,exr.import,lmbake}`. Logs in `/tmp/bake_inplace_<scene>/`
(`BAKE_LOG=` to move them).

**Tested Nov 1, 2026** on the cloud box (4 CPUs, 15 GB RAM, lavapipe), wing 3 at Medium (`fastday`):
- editor run 434 s (import scan, bake, save), no OOM with 12 GB swap on;
- the editor changed 455 tracked files: **449 `.import` flips** (not ~206: a fresh box's first editor launch
  flips every texture it sees in 3D), `project.godot`, `gen/env_day.tres`, `gen/env_night.tres` and three
  `gen/w3` meshes; all reverted; 0 tracked changes left beyond the build;
- only `wing3_day.exr` and `.lmbake` changed (the `.exr.import` keeps its settings); exported and shot against
  the live bake: same layout and shadows, the cloud bake a little warmer on the pavement
  (`production/qa/evidence/wsH-bake-inplace-wing3-fastday.jpg`). Look at that before shipping any Linux bake;
  the shipped bakes stay Ultra on the Mac. The test lightmap was not kept or committed.
- The rebuilt scene differs from the committed one only in node `unique_id`s (every build makes new ones); the
  script says so, and you `git checkout` it unless you are committing the wing.
- Afterwards, as always: `tools/capture_standin.sh` for the wing(s) that see the rebaked one, export, check.
