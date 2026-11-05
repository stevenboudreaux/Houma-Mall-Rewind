# Handoff: Demo 52 pre-publish (Nov 5, 2026, afternoon): stand-ins recaptured, baked build exported and looked at

**State: not published.** Branch `int-52` (head in the director's report). Nothing pushed to `main` or `godot-build`,
nothing on R2. The export is on disk at
**`/home/claude/int52/prototypes/godot-mall/project/.scratch/builds/d52/`** (1.5 GB, all 12 wing packs both kinds +
the five shared packs + the page). Keep it for the publish.

**Verdict: wings 1, 2, 4, 5 (both years) and wing 3 1995 are ready. Wing 3 2026 is not: its Mac bake left the
canopy-shadowed pavement at the main entrance pitch black (below).** Steven decides: rebake `wing3_2026` (then
`capture_standin.sh 3 2026`, re-export, publish), or publish as is with the known blemish.

## What I did, in order
1. **Reimported the Mac's lightmaps.** The ten `wing{1..5}{,_2026}_day.exr` from the nov4 bakes were unpacked but
   their imports were stale (Godot's `.md5` named the old sources). `godot --headless --import` ran ~70 min on this
   2-CPU box (BPTC/ASTC of each lightmap; wing 1 / 2 ~7 min each). My first run was cut by a 1700 s `timeout` at 45 %;
   the rerun redid everything (the killed run never wrote its filesystem cache). Afterwards every lightmap's
   `source_md5` matched its file. **Run the import with no timeout.**
2. **Stand-ins**, `tools/capture_standin.sh` in the asked order 4, 4 2026, 5, 5 2026, 3, 3 2026, 1, 1 2026, 2, 2 2026.
   **Found a gap in the tool:** the captures of 1 / 2 render the wing scene, which uses the *imported* opening
   pictures (`tex/standin/from_w4_day.png` etc.), and `capture_standin.sh` writes the new PNGs without reimporting
   them. So wing 1's first capture showed the **old** Lynn's picture (Demo 51's nearly empty room) in its slot. I
   stopped the chain during wing 2, ran `godot --headless --import` (11 s; it took the new 4 / 5 / 3 pictures), and
   recaptured 1, 1 2026, 2, 2 2026, then imported once more. Now the Lynn's and Dillard's slots in the wing 1 / 2
   atlases show the new pictures (furnished Lynn's in 2026). **Suggested fix (not made):** `capture_standin.sh 4|5`
   could run `godot --headless --import` after writing, or the README's order could say "import between 4/5/3 and
   1/2". Without it, every future pre-publish repeats this mistake silently (the stamps still match: the hash reads
   the PNG, not the import).
   - No stand-in change needed a rebake.
   - All ten stamps equal `tools/wing_hash.sh` (checked after the last capture).
   - **Nothing to commit for this step:** `tex/standin/*.png` and `*.stamp` are gitignored (they ship on `godot-build`
     through `publish_build.sh`). The pictures are on disk in this worktree.
   - `.autobake_done` (all ten jobs "ok 1s") disappeared from the project during the import; its content is above.
3. **Export** with `tools/export_web.sh` run wing by wing, so the script's temp folder (it keeps every pack until the
   end) never held the whole build twice on ~3.8 GB free: `SHARED=0` for "1 2", "3", "4", "5", then `SHARED=1` with
   "6" (the shared packs and the final `PACK_SIZES` / `SHARED_PACKS` lines). Web templates were already in
   `~/.local/share/godot/export_templates/4.7.2.stable/` (web only), nothing re-downloaded. 4 min in all.
   - Desktop and mobile packs come out the same byte size; `packformats.py` confirms they differ (w1 desktop: 53
     s3tc + 1 bptc; mobile: 53 etc2 + 1 astc; same block sizes).
4. **Dry run:** `R2=0 DRY_RUN=1 tools/publish_build.sh .scratch/builds/d52 "dry"` → "all checks passed" (stand-in
   stamps, export newer than every picture, room wings 4 5 6, sites main 817 MB / desktop 777 MB). R2 mode cannot dry
   run here: it checks rclone and R2 access before its dry-run exit (rclone is not installed on this box).
   - It first refused: **`missing wing1_night.lmbake`**. The int-52 tree has `wing{1,2}_night.exr(.import)` but not
     the `.lmbake`. I copied Demo 51's two `wing{1,2}_night.lmbake` from `/home/claude/hmr-base` (gitignored; the
     night lightmaps are never shown, `day_only`, and are not in the wing hash). The publish copies them into
     `godot-build/lightmaps/` as before; consider dropping night from the publish checks.
5. Looked at the build (below), ran the web tests.

## Pack sizes (MB, 10^6 bytes; desktop = mobile to the byte)
| Wing | 1995 | 2026 |
|---|---|---|
| 1 | 87.28 | 49.31 |
| 2 | 91.49 | 70.66 |
| 3 outside | 48.27 | 33.39 |
| 4 Sears / Lynn's | 42.63 | **96.07** |
| 5 Dillard's | 43.53 | 38.37 |
| 6 cinema lobby | 24.40 | 24.53 |

Shared: items 72.98, chars 53.38 (UBC), chars_w1 0.56, chars_w2 0.82, chars_w2y26 0.09.
Desktop total 777.8 MB, both kinds 1555.5 MB (Demo 51: 1293). Page files (wasm etc.) ~40 MB.
- **w4y26 is 96.07 MB** (Demo 51: 33.33): Lynn's 403 furniture pieces. Under R2 there is no file limit, but it is a
  96 MB download on a phone to enter Lynn's; `export_web.sh` warns (GitHub's 100 MiB). Worth a look (the furniture's
  textures, or a shared pack for it).
- Wings 1 and 2 came out *smaller* than int-52's unbaked test export (119.5 / 118.1): the nov4 lightmaps are one
  BPTC/ASTC array each (wing 1: 12.6 MB).

## Tests (web, swiftshader, one browser at a time)
| Test | Result |
|---|---|
| movetest from each wing's spawn (`CAMS`/`WALK_CAM` = spawn), all 12 packs | **MOVED 12/12, 0 console errors** |
| doortest 1→3 (main entrance) 1995 / 2026 | CROSSED / CROSSED, 0 errors |
| doortest 1→4 (Sears / Lynn's) 1995 / 2026 | CROSSED / CROSSED, 0 errors |
| doortest 2→5 (Dillard's) 1995 / 2026 | CROSSED / CROSSED, 0 errors |
| doortest 4→3 (Lynn's side exit) 2026 | CROSSED, 0 errors |
| Spencer's 2026: E at `talk_at` (−54.8, 27.0) | the shop opens (5 PLACEHOLDER items, prices, attendant), 0 errors |
| `pictures_publish_test.js` (Node) | PICTURES PUBLISH TEST OK (18) |
| `pictures_pick_webtest.js` | PICTURES PICK WEBTEST OK (9) |
| `arcade_nes_webtest.js` | ARCADE NES WEBTEST OK (14) |
| `signstest.py` (no wing in the URL) | Kay-Bee shows the owner's draft sign text; "Edit signs" turns on through MENU → OWNER → TOOLS ("Tap a sign to change its words"). The Pocket Change shot and the click-a-marquee step fail: **the test is stale since the wing split**, its Pocket Change cam (−106.7, 71.8) is in wing 2 and the test loads one URL, so in wing 1 it stands outside the geometry and the click hits nothing. Needs per-wing URLs (owner-tools updated only its menu path). |
| `avatar_webtest.py` (wing 2) | 4 FAIL of 7, then a page-load timeout at the landscape step. **Stale test:** it expects the creator to open by itself on a first visit, and since ws/items there is no opening, so nothing is saved by Enter / Skip. What it saw is right: the default avatar, V / the View button switching first and third person, 0 console errors (`/home/claude/d52shots/more/avatar2-*.png`). Rewrite it to open the creator from the menu (as the native avatar_test now does). |
| not run (time) | char editor web run, menu_webtest directory step, walk_webtest in the halls |

The first doortest 1→3 2026 failed only because the local server task hit the session's 2-hour background limit
mid-test (the page went to `chrome-error://`); every later test then got "connection refused". Rerun with the
server started inside the same job as the tests: CROSSED. **Lesson:** a background server lasts at most 2 h here;
start it in the same job as the tests it serves.

## Screenshots (`production/qa/evidence/`, baked web build, 1280x720) and my judgement
| File | What | Judgement |
|---|---|---|
| `d52-w1-spawn-baked.jpg` | wing 1 1995, the east hall to the Shoe Dept. court | clean: soft lightmap, no seams, no black or blown areas; floor checker crisp, shine modest |
| `d52-w1y26-spawn-baked.jpg` | wing 1 2026, same spot | clean; grilles, Wax Utopia, the court beyond all lit evenly |
| `d52-w2-spawn-baked.jpg` | wing 2 1995 at Karmelkorn | clean; the hall to the west even, no seam at the arch |
| `d52-w2y26-spawn-baked.jpg` | wing 2 2026 at Cinnamonster | clean |
| `d52-w3-spawn-baked.jpg` | outside 1995 at the main entrance glass | fine (plain glass by design: no pictures from outside) |
| `d52-w3y26-spawn-baked.jpg` | outside 2026, same spot | **BUG: the pavement in front of the doors is pure black** |
| `d52-w3y26-entrance-black-ground-BUG-baked.jpg` | 2026 from the drive / 1995 from the drive / 2026 looking down / 2026 spawn | the black is exactly the canopy's shadow on the sidewalk (stepped edge at the 0.16 m texel); sunlit pavement beside it is fine; 1995 at the same place has no black |
| `d52-w3y26-lot-baked.jpg` | outside 2026, the lot by Hypervelocity | fine |
| `d52-w4-spawn-baked.jpg` | wing 4 1995, inside Sears | clean bake; the Sears box is the empty floor as in Demo 50/51 (not new) |
| `d52-w4y26-spawn-baked.jpg` | Lynn's 2026 inside the mouth | clean; furniture lit, no dark blotches under pieces beyond normal contact shadow |
| `d52-w5-spawn-baked.jpg`, `d52-w5y26-spawn-baked.jpg` | Dillard's level 1 | clean; floor reflections of the ceiling lights show |
| `d52-w6-spawn-baked.jpg`, `d52-w6y26-spawn-baked.jpg` | cinema lobby (spawn faces a wall) | unbaked by design; as before |
| `d52-corner-c2-1995-top-2026-bottom-baked.jpg` | C2 corner from the court patch (left) and from the east hall (right), 1995 top, 2026 bottom | clean: Franks set back with the patch, 2026 Zales over Franks + OJ, lit, no seams between the new court patch and the hall floor |
| `d52-lynns-entrance-mall-and-inside-baked.jpg` | Lynn's from the mall (wing 1 2026: the opening picture) / inside | the opening picture now shows the furnished room (after the reimport fix); the hall floor meets the picture cleanly |
| `d52-spencers-2026-shop-open-baked.jpg` | Spencer's counter shop open | works; the talk camera frames the attendant's face very close (the int-52 native shot was wider) |
| `d52-w3-1995-entrance-sign-doubled-baked.jpg` | the 1995 main entrance sign | minor: "SOUTHLAND MALL" twice, the big parapet letters cut by the canopy beam, the small fascia letters below (also in EXT-B's unbaked evidence; a placeholder entrance) |

Also seen: from inside wing 1 at the main entrance (doortest leg 0) the glass shows only sky and flat ground, both
years. Demo 44's `d44-web-outside-doors.jpg` looks the same, so it is not new.

## The wing 3 2026 black ground
- The sun is `BAKE_STATIC` (`build_mall.gd finish()`), so the black is in the 2026 outside lightmap: shadowed texels of
  the entrance pavement got no sky or bounce light. Same LightmapGI settings and the same `fastday` (Medium) mode as
  1995, which is fine; the 2026 entrance (EXT-B: tile-banded columns, deep canopy) shades more of the walk.
- Both wing 3 lightmaps cover the same atlas area (84 % of the 4096² atlas is empty in both; not a missing bake).
- Seen also in the 2026 door pictures (`y26_door_w1_day.png`, its last tile: the dark wedge on the ground), so a
  player inside wing 1 2026 sees it through the doors too.
- Fix: rebake `wing3_2026` on the Mac (try `day`, Ultra, instead of `fastday`; or look at the entrance meshes' UV2 /
  the canopy's underside), then `tools/capture_standin.sh 3 2026`, `godot --headless --import`, re-export wing 3
  (`SHARED=0 tools/export_web.sh .scratch/builds/d52 "3"`, then the "6" + SHARED=1 step for the size lines), dry run.

## For the publish (when Steven says go)
`R2=1 tools/publish_build.sh .scratch/builds/d52 "<message>"` from the project folder, with rclone and the R2
secrets (this box has no rclone). The stand-ins and night `.lmbake` it needs are in place. If wing 3 2026 is rebaked
first, redo its capture + import + export as above.

## Problems / for Steven
1. **Wing 3 2026 entrance pavement black** (rebake decision).
2. **w4y26 = 96 MB** (Lynn's furniture) for phones.
3. `capture_standin.sh` does not import its own new pictures before the mall wings are captured (worked around here;
   a one-line fix is suggested above, not made).
4. `publish_build.sh` still requires `wing{1,2}_night.lmbake` though night is never shown.
4b. `signstest.py` and `avatar_webtest.py` are stale (one-URL cams across the wing split; the removed opening).
5. Earlier open items stand: the int-52 handoff's questions 1-8, stockrooms_test's three failures, Cuco's bar in
   the browser (Demo 51).
