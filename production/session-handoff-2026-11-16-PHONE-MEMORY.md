# PHONE-MEMORY: phones stream seamlessly (Mon Nov 16, 2026), stage 1 of 3

Worker job for the director. Branch `ws/phone-memory` from `ws/seamless-upfront` (`74cef19e`). Not merged, not
baked, not published, nothing uploaded. Findings: `production/qa/evidence/wsPHONE-MEMORY-findings.md`. Design:
`design/godot-wings.md` "Phone memory", `design/godot-build-hosting.md` "The phone pack's texture memory".

**Stopped at the end of stage 1, as the brief says:** the director puts a phone preview on R2 and Steven reads the
numbers off his iPhone. Stage 2 (options with shots) starts from those numbers.

## Done / partly / not started
| Item | State |
|---|---|
| Baseline: the 8 headless suites on `74cef19e` | **Done.** All OK (SHOP 200, CUCOS 89, FLAGS 31, INVENTORY 45, REDEMPTION 32, ECON 52, MENU UNIT 64, INT D49). Same on this branch. |
| 1a. Every texture and lightmap per mobile pack and common pack, both years, with totals by kind | **Done.** Findings section a; every file in `wsPHONE-MEMORY-textures.md`; `tools/qa/packmemory.py`. |
| 1b. Where one wing's memory goes, then two | **Done** (native engine counters plus the browser; the split of about 300 MB of engine-side texture memory is estimated). |
| 1c. `?qa=1` readout in the menu, `window.__mallMem` | **Done.** The QA tab; crash crumb in localStorage. Looked at in Chromium at phone width (shots in evidence). |
| 1d. Is it memory | **Done as a method:** what differs 4 s in, how to tell from the readout, Web Inspector and the iPhone's `JetsamEvent` logs. Not proven: needs the phone. |
| 1e. iPhone / iPad Safari formats and Godot | **Done** (from documentation and Godot's source; the readout's formats line checks it on the devices). |
| Stage 2: options with shots and numbers | Not started (waits for the iPhone numbers). |
| Stage 3: build Steven's choice | Not started. |

## The findings in five lines
1. One 1990s mall wing on the phone pack: about 0.8 to 0.9 GB of textures; with the neighbour about 1.2 to 1.4 GB.
   Plus a wasm heap of 142 MB going to 204 MB, and the neighbour's pack held twice in the page. 2026 is about half.
2. The mobile lightmaps (ASTC HDR) are decompressed on every phone to 8 times their size (Godot's web renderer never
   uses ASTC HDR): 100.7 MB per 1990s mall wing instead of 12.6.
3. Most of the rest is lossless WebP decoded to 4 bytes a pixel: surface pictures, the Blender items' 2048 maps (up
   to 50 MB for one item), the cast's 2048 heads.
4. The department stores are cheap (30 to 40 MB each); the second mall wing is the cost.
5. An iPad with S3TC + BPTC would take the desktop pack and the desktop path (everything up front).

## For the director
- **The phone preview:** export this branch as usual (`tools/export_web.sh`; nothing in export or publish changed) and
  upload it. Steven's steps: findings section c, "What Steven reads off his iPhone" (`?qa=1`, then
  `?qa=1&stream=1`, the QA tab, LAST VISIT after a crash, the same on the iPad).
- **Export:** a test export is at `/home/claude/build57` on this box (wings 1, 2, 4, 5, both years, both kinds,
  shared packs; no outside, no cinema lobby). Make your own full export for R2.
- **Rebake:** none. No scene, mesh, lightmap or texture changed; the stand-ins are not stale.
- **Shared files touched** (small hunks): `scripts/wing_stream.gd` (`_init` makes `MallMem` with `?qa=1`),
  `scripts/menu/menu.gd` (a QA tab only while `MallMem` exists). New: `scripts/mall_mem.gd`,
  `tools/qa/packmemory.py`, `tools/qa/mem_native.gd`, `tools/qa/mem_webtest.py`. `data/stream.json`,
  `web/shell.html`, `export_presets.cfg`, `tools/export_web.sh`, desktop packs: unchanged.
- `CLAUDE-CLOUD.md` setup step 3 fails as written when run from the project folder (`git archive` paths are
  relative to the current folder): run `git archive origin/godot-build lightmaps standin` from the repository root
  and untar into the project. Not changed here.
- Python Playwright was not installed on this box (only Node's); `pip install playwright` and the pre-installed
  Chromium (`/opt/pw-browsers/chromium`, which `mem_webtest.py` uses) were enough.

## Not verified
- Anything on an iPhone, an iPad or a real GPU. Whether the crash is memory.
- `stream_natural_walk_webtest.py`, packtest, seamtest: not rerun (stage 1 changed no behaviour; the readout is made
  only with `?qa=1`). They are stage 3's gates.
