# UPFRONT: the whole interior behind the load screen on computers (Sat Nov 14, 2026)

Worker job for the director. Branch `ws/seamless-upfront` from `int-55` (`5ba126d`). Not merged, not baked, not
published, nothing uploaded. Design: `design/godot-wings.md` "Everything up front". Numbers:
`production/qa/evidence/wsSEAMLESS-findings.md` "UPFRONT".

## Why
Steven tried the Nov 14 preview (R2 build `20261114-1715-5ba126d8`) and could not walk the interior without loads.
- **Computers:** the other wings came in after the load screen lifted (on his Air: wing 2 in 47 s after the page
  started, Dillard's 92 s, Sears 122 s). Walk straight off and you reach a border that is not ready. He had said on
  Nov 13: "I'd rather the load be as big as possible up front."
- **The test that passed** placed the player before each line and waited for the wing. It was not a walk.
- **iPhone Safari** crashed within seconds with streaming on.

## What changed
| | State |
|---|---|
| a. Computers: every interior wing in, settled and peopled before the load screen lifts | **Done.** `data/stream.json` `"upfront": {"desktop": true, "mobile": false}`. The start, a year switch and coming back inside are all page loads and all do it. The cinema lobby only if its gate is already open; otherwise it comes in in the background when the gate opens, as before. |
| b. Phones and tablets: streaming off | **Done.** `"enabled": {"desktop": true, "mobile": false}`: a phone loads one wing at a time, as in Demo 54. `?stream=1` still forces the phone path. Checked on the web build with the phone pack: nothing is asked for, nothing streams. |
| c. A truthful walk test | **Done.** `tools/qa/stream_natural_walk_webtest.py`. Results below. The old `stream_walk_webtest.py` is kept and described as what it is: crossings once the wing is in. |
| d. "Engine error: at: open (core/io/resource_format_binary.cpp:1028)" on the load screen | **Explained, and no longer shown.** Below. |
| e. Export | **Done.** `/home/claude/build56` (36 files, 1,659.5 MB). |
| f. Docs | **Done.** `design/godot-wings.md`, the findings doc, `tools/qa/README.md`, this file. |

## The natural walk (the page's own address plus `?qa=1`; the computer pack; forward held from the lift)
Route: the start → across the seam → into Dillard's → out → back across the seam → into Sears / Lynn's → out →
Corn Dog 7. About 560 m. No placing, no waiting for a wing.

| Year | Result | Load screen lifted after | Wings in at the lift | Walk | Prompt / hold / load screen / page error | Peak memory (all Chromium processes) |
|---|---|---|---|---|---|---|
| 1990s | **NATURAL WALK OK** | 2,018 s | 2, 4, 5 in and peopled | 560 m in 2,627 s | none / none / none / 0 | 5,539 MB |
| 2026 | **NATURAL WALK OK** | 1,110 s | 2, 4, 5 in and peopled | 550 m in 1,828 s | none / none / none / 0 | 5,080 MB |

These are **test-box numbers** (2 CPUs, software renderer, about a frame every four seconds with four wings
drawn). 1,903 of the 2,018 s are the department stores' 480-frame probe wait at that frame rate; at 30 to 60 frames
a second that wait is 8 to 16 s. Nothing here was run on a real machine.

## Time to control and download on a computer
| | Before (int-55, wings in the background) | After (this branch) |
|---|---|---|
| Test box, 1990s, page start → load screen lifts | 44 to 46 s (then about 10 to 25 minutes more before the last wing was in, behind held borders: the Nov 13 walk logs) | 2,018 s (everything in) |
| Steven's Air, 1990s (director's measurement of the int-55 preview) | load screen about 40 s; last wing in at 122 s | **not measured.** Expect less than 122 s: the packs now download side by side from the first second and load with ten times the per-frame share; the fixed part is the 480-frame probe wait. |
| First download, 1990s | 235 MB (wing 1, items, common), then 174 MB in the background | 408 MB |
| First download, 2026 | 192 MB, then 207 MB in the background | 399 MB |
| Phone pack | one wing at a time | one wing at a time (unchanged from Demo 54); load screen 41 s on the box |

If the wings are not in 15 minutes after the engine starts, the card lifts anyway and the rest comes in behind
held borders, as before.

## The "engine error"
It is the last line of a **warning**, not an error:
`WARNING: 'res://cast/radioshack_1995.glb': In external resource #2, invalid UID: 'uid://…' - using text path
instead: 'res://cast/…_head.png'.` then `at: open (core/io/resource_format_binary.cpp:1028)`.
A model that ships in a shared pack (items, common) names its textures by an id; the wing pack's id list does not
know ids from another pack, so the engine uses the path, which works. The page showed every engine line as "Engine
error", and the last one stuck.
- **Demo 54 (main) has it too:** 40 warnings (the Blender items in the items pack). The common pack added 15 (the
  cast's bodies). Nothing fails to load.
- **Fixed in the page:** warnings and their "at:" line go to the console (`[engine] …`), not the load screen.
  Real engine errors still show. Checked on the build: the load screen's error line stays empty.
- **Not done:** silencing the warnings at the source (ship each shared pack's id list and register it at mount).
  Small, optional, its own job.

## Tests
- `stream_natural_walk_webtest.py`: 1990s OK; 2026 **NATURAL WALK OK**.
- `stream_upfront_test.gd` (native): OK for 1990s, 2026, `--open` (the lobby comes in too), `--kind=mobile`
  (streaming off, nothing comes in).
- `stream_test.gd` desktop, mobile, `--fail`: OK (they now run with upfront off: the background path).
- Web, phone pack default address: no pack asked for, no streaming, load screen 41 s.
- `packcontents` at export: every reference shipped.
- **Not rerun on this build:** the 8 headless suites, `stream_walk_test.gd`, `stream_walk_webtest.py`,
  movetest, doortest, menu trip, redemption, shops, seamtest, `wsS_webtest`, packtest. `doortest.py`,
  `seamtest.py` and `wsS_webtest.py` already pass `?stream=0`, so the phone default is what they test.

## For the director
- **Integration:** `ws/seamless-upfront` is three commits on `int-55`; fast-forward. Files touched:
  `scripts/wing_stream.gd`, `data/stream.json`, `web/shell.html`, `tools/export_web.sh` (writes `MALL_UPFRONT` into
  `index.html`), `tools/qa/*`, docs. No store, sign, exterior, character, story or HUD file. `publish_build.sh`
  untouched.
- **Upload:** compared with `/home/claude/build55` by md5, **27 files differ**: `index.html`, both `items` packs
  and all 24 wing packs (1,500.5 MB). **Same, need no upload:** `common.desktop.pck`, `common.mobile.pck`,
  `index.wasm`, `index.js`, the two worklets and the three pictures. (A second export of the same sources also
  changed every wing pack's md5: the export is not byte-for-byte repeatable, so "differs" does not mean "has new
  content". The wing packs do have new content: `wing_stream.gd` and `stream.json` ship in each.)
- **Bake:** none. No mesh, lightmap or texture changed; the stand-ins are not stale.
- **Check on a real machine first:** how long the load screen stays up on the Air (the one number this job could
  not measure), then the walk.

## Not verified
- Anything on a real GPU, a real phone, or with a gamepad. The time the load screen stays up on a real computer.
- A year switch and coming back inside from the lot behind their load screens: same code path as the start (a
  page load into an inside wing), tested natively for both years from the start only.
- The cinema lobby coming in up front with the gate open: native test only (`--open`).
- A slow or failing line on the web (the 15-minute lift, a pack that cannot be fetched during the up-front load).
