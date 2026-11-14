# SEAMLESS: findings (stage 1), the first border (stage 2) and stage 3

Workstream SEAMLESS, branch `ws/seamless` from main `81cb3ba9` (Demo 54). Fri Nov 13, 2026.
Brief: `claude/briefs-2026-11-13-seamless.md` (project doc). Design note: `design/godot-wings.md` "Seamless streaming".

Measured on the cloud box (2 CPUs, 7 GB, no GPU). Browser numbers are headless Chromium on swiftshader, which draws
a frame every 2 to 10 s here and keeps every texture decoded in ordinary memory, so its **memory is far above a
real device's and its frame times mean nothing**; they are for comparing one state with another. Engine timings
marked "native" are the Linux editor binary, headless: CPU work only, no texture upload.
**Nothing here was run on an iPhone or on Steven's Mac.**

## The short version
1. The wings can stream. With `?stream=1` the wing 1 / wing 2 seam in the 1990s has no load screen, no page load
   and no pictures: the real wing is there before you reach it (`wsSEAMLESS-seam-from-wing1-before-after.jpg`,
   `wsSEAMLESS-seam-from-wing2-before-after.jpg`, `wsSEAMLESS-crossing-*-sequence.jpg`). Both pack kinds, 0 page errors.
2. It is **off by default**. Two things stand between this and "on for everyone": the neighbour's people and loose
   items only appear as you step over (section d), and the phone's memory is not proven (section b).
3. The biggest surprise: the five 1990s interior packs are 582 MB, but only 227 MB of that is different files.
   Every pack carries the same 80 MB (mostly the cast's bodies). A neighbour should cost 64 MB to bring in, not 154.
4. Lighting at this border needs no fix and no rebake (section e).

## a. Packs, per wing and year (Demo 54 build on R2, `20261113-1915-df378f57`; desktop = mobile to the byte)

| Pack | MB | Only in this pack (MB) | Scene: nodes / meshes / vertices | Native: resources, load ms, instance ms |
|---|---|---|---|---|
| `w1` Wing 1 (Sears halls, east hall, main entrance) | 150.6 | 54.4 | 724 / 184 / 551,937 | 197, 1230, 2 |
| `w2` Wing 2 (Dillard's court, Concourse, JCPenney) | 154.2 | 58.5 | 801 / 168 / 833,141 | 185, 1303, 4 |
| `w4` Wing 4 (Sears) | 98.6 | 5.7 | 484 / 76 / 44,193 | 83, 179, 2 |
| `w5` Wing 5 (Dillard's level 1) | 99.4 | 6.5 | 472 / 61 / 72,386 | 67, 332, 3 |
| `w6` Wing 6 (cinema lobby) | 80.3 | 0.1 | 14 / 1 / 236 | 5, 90, 0 |
| `w1y26` Wing 1, 2026 | 107.8 | not broken down | 362 / 60 / 162,158 | 71, 434, 2 |
| `w2y26` Wing 2, 2026 | 138.9 | not broken down | 523 / 86 / 499,854 | 108, 1113, 2 |
| `w4y26` Wing 4, 2026 (Lynn's) | 152.0 | not broken down | 1201 / 465 / 628,412 | 178, 2169, 3 |
| `w5y26` Wing 5, 2026 | 94.7 | not broken down | 413 / 62 / 81,638 | 68, 247, 2 |
| `w6y26` Wing 6, 2026 | 80.4 | not broken down | 14 / 1 / 236 | 5, 82, 0 |
| `w3` / `w3y26` the outside (not streamed: stays a load) | 119.4 / 104.4 | | | |
| `items` (shared, loaded once at the start) | 84.0 | | | |

- "Native" = headless on this box, a cold start of that scene alone: the files the scene names, the time to load
  them, the time to instance. (Wing 4 in 2026, Lynn's, is the heaviest room wing by far: 1,201 nodes, 2.2 s.)
- "Only in this pack": files no other 1990s interior pack has (2026 not broken down). The rest is shared with at
  least one other pack; 79.7 MB is identical in all five (the cast's heads and bodies 71.7 MB, shopper skins 3.1,
  animations 2.9, scripts, data). Only `project.binary` and `.godot/uid_cache.bin` differ in bytes.
- 1990s interior as downloaded today: 582.4 MB + `items` 84.0. Counted once: 227.0 + 84.0 = **311 MB**.
- What a neighbour adds to what is already there: w2 over w1 64.3 MB, w4 over w1 11.3, w5 over w2 12.5, w6 over w1 0.1.
- **Download time** is the pack size over the line speed: 154 MB is 25 s at 50 Mbit/s, about a minute on good
  LTE (20 Mbit/s), two minutes at 10. As 64 MB it would be 10 s / 26 s / 51 s. The old prefetch already starts
  fetching the other wing 6 s after the game starts, so on a second visit, or after a short stay, it comes from the cache.
- The page fetches a neighbour's pack once (the old prefetch and the streamer share the download).
- **Mount:** 6 to 17 ms in the browser. **Copy into the engine's file system:** about 100 to 130 ms for 154 MB (one stall).
- **Load and instance in the browser** (single-threaded wasm, this box): wing 2 20 to 38 s of wall time at 0.2 fps,
  which is the renderer, not the work: the same load is 1.1 to 1.3 s of CPU natively.
- **Memory in the browser once loaded** (all Chromium processes, mobile pack, swiftshader): wing 1 alone 2.8 to 3.0 GB,
  wing 2 alone 3.0 to 3.2 GB. Not measured per wing for 4, 5, 6 or 2026: each run is 6 to 10 minutes here and they
  do not stream yet; their scenes are much smaller (table).

## b. Two wings together, then all
| State (1990s, mobile pack, swiftshader) | Browser processes, MB | JS heap, MB |
|---|---|---|
| wing 1 alone | 2811 to 2974 | 237 to 395 |
| wing 1 + wing 2 streamed in | 4087 to 4132 | 551 to 558 |
| after the handoff to wing 2 (both still in) | 4107 to 4190 | 403 |
| wing 2 alone | 3034 to 3245 | 243 to 410 |
| wing 2 + wing 1 streamed in | 4340 to 4389 | 550 |
| after the handoff to wing 1 (both still in) | 4473 to 4498 | 401 |

- A neighbour adds **about 1.15 to 1.3 GB here, 40 to 45 % on top of one wing**. About 150 MB of it is the pack file
  itself sitting in the page's memory (the JS heap column, which drops when the fetch buffer is collected; the
  engine's copy stays). The rest is the neighbour's meshes and textures, which swiftshader holds uncompressed.
- **All interior wings together was not measured**: only this border streams. From the packs: wings 4, 5 and 6 add
  11, 13 and 0.1 MB of their own files, so their cost is small next to wings 1 and 2, **except** that each is
  mounted whole today (99 + 99 + 80 MB of mostly duplicate bytes held in memory). All five mounted whole: 666 MB of
  pack bytes in memory with `items`; counted once: 311 MB.
- **What to expect on an iPhone (a judgement, not a measurement).** `design/godot-build-hosting.md` puts Safari's
  limit for a tab near 1 to 1.5 GB, and "iPhone wing 1 memory" is already an open check with one wing. One wing
  today holds 234 MB of pack bytes (150 + 84) before anything is decoded. A streamed wing 2 adds 154 MB of pack
  bytes plus its textures and lightmap. I expect current iPhones to be at the edge and older ones to reload the
  tab. With the shared files split out (section f, option 1) the neighbour's pack bytes fall to 64 MB.
  **So: I do not have evidence that a phone holds a wing plus a neighbour, and I do not have evidence that it
  cannot.** Phones stay off until Steven tries `?stream=1` on his.
- Frame time with two wings: not measurable here (0.2 fps). Both wings' meshes are in the scene; each mesh is
  culled by the camera as before, so the cost in view is what is in view. The floor mirror renders the scene a
  second time and now sees both wings.

## c. The hitch when a wing comes in
| Step | Native (headless) | Browser here | In one frame? |
|---|---|---|---|
| copy the pack into the file system | – | 98 to 133 ms | yes |
| mount | – | 6 to 7 ms | yes |
| load the scene's resources (185 files for wing 2) | 1.1 to 1.3 s in all | 20 to 38 s wall | no: `load_budget_ms` (6) per frame |
| the largest single resource | 170 to 204 ms | 207 to 339 ms | **yes: one stall** |
| load the scene file and instance it | 109 to 134 ms | 15 to 25 ms | yes |
| nodes entering the tree | 47 to 69 ms in all | 2.4 to 6.2 s wall | no: `nodes_per_frame` (24) per frame; worst batch 0.5 to 0.8 s here |
| the handoff | 29 to 139 ms | 60 to 115 ms | yes |
| the frame after the handoff (shoppers' grid and roles, items, attendants) | worst frame 520 to 575 ms | – | yes |

- What is already spread across frames: the resource loads and the nodes entering the tree.
- What still stalls: (1) the single largest resource: for wing 2, Pocket Change's machine meshes (`gen/w2/pc0_mach.res` 249 ms, `pc1_mach` 174 ms) and the Blender lion (225 ms); (2) instancing; (3) the handoff and the systems that
  start in the frame after it. On a desktop I expect two stalls of 0.1 to 0.3 s while the wing comes in (far from
  the border, so mostly unseen) and one of 0.3 to 0.6 s at the border itself; on a phone several times that.
  The first draw of the neighbour's materials (shader compiles, texture uploads) is on top and cannot be seen here.
- How I would spread the rest: load the lightmap texture in the frame the lightmap is set, split from the scene's
  other resources and behind a one-frame blank of nothing visible; instance in two halves (`Static`, `Dynamic`);
  for the handoff, keep the shoppers alive across it (they are the biggest part of that frame) instead of respawning.

## d. What assumes one wing at a time, and what I did
| Thing | Where | Today | Done in stage 2 | Left |
|---|---|---|---|---|
| The crossing is a page reload | `player.gd` `_cross`, `_go_to_wing`; `shell.html` `mallGoWing` | fade, new page, loading card | with the neighbour in, the border is floor; `_go_to_wing` into a wing that is in is a handoff | thresholds (4, 5, 6), 2026 |
| Walk grid closes the other wing's tiles | `gen/w<n>/wing.json` `walk` | the seam is a wall | union of both grids while the neighbour is in; restored on unload | – |
| Obstacles | `gen/w<n>/collide.json` | this wing's | both wings' | – |
| The seam prompt | `player.gd` `_update_prompt` | "Enter Wing 2 …" | hidden while the neighbour is in; unchanged when it is not (the fallback) | what a slow line shows (section f) |
| Stand-in halls and storefront pictures | `build_mall.gd`, `dyn_standin` | always drawn | hidden in both wings while the real one is in | still built, captured and stamped |
| Whole-mall parts built into every wing | `outside`, `dyn_glass_frames`, `lanterns`, `dyn_info`, `misc`, labels, reflection probes | one copy per wing | duplicates hidden at run time | `dyn_glass` is drawn twice where the wings share skylights; the clean fix is in the builder (rebake) |
| One Player, Runtime, Signs, sky and sun per scene | the wing `.tscn` | – | the neighbour is instanced without them; the handoff moves them | – |
| Floor shader and mirror | `mall_runtime.gd` `_ready` | walks `current_scene` | `adopt(root)` for a neighbour | – |
| Day / night and the lightmap swap | `time_of_day.gd` | `current_scene` | applied to the neighbour when it enters | a lighting change while a neighbour is in does not reach it (day-only today, so not visible) |
| "Benches & plants" | `player.gd` | `current_scene`'s `dyn_fixtures` | the neighbour's follows | – |
| Shops and their attendants | `shop.gd`, `dialogue/story.gd`, `story/cucos.gd` | made at start for `player.wing` | remade at the handoff | not there while you look across the border |
| Pick-up items | `interact.gd` `_spawn` | this wing's | remade at the handoff | same |
| Shoppers | `npcs.gd` | spawned round the player on this wing's grid | respawned at the handoff, on the union grid | a visible pop at the border; they should live across it |
| The Runner | `runner_ai.gd` | wing 2 only | follows the handoff | – |
| The Rougarou | `rougarou_ai.gd` (`player.wing == w`), `stockrooms.gd` | wing 1 | follows the handoff; the Stockrooms level is unchanged (still inside wing 1, entered as today) | a chase across a border is not designed |
| Prize counters | `prizes.gd`, `prizes_gi.gd` | wing 2 only | follows the handoff (tested) | – |
| Signs: owner edits, cabinet play | `signs.gd` (`gen/w<n>/signs.json`) | this wing's | remade at the handoff | the neighbour shows its built-in sign text until then |
| Directory | `directory_kiosk.gd`, `directory_ui.gd` | one reader per scene | works per wing; the reader's reference is cleared at the handoff | a jump into a streamed wing is instant, others load as before |
| Saved position / reload | `?wing=&cam=` | from the URL | `?wing=` follows the handoff | – |
| Year switch | `player.gd`, `timetravel_trip.gd` | reloads into `wing` | uses the new home wing | stays a load (decided) |
| Inside ↔ outside | doors, wing 3 | reload | unchanged | stays a load (decided) |
| VR | `vr.gd` | `current_scene` Signs | not tested with streaming | – |
| Prefetch | `shell.html` `mallPrefetchOther` | caches the other wing after 6 s | the streamer reads the same cache | desktop "everything" order |
| `wing_hash.sh`, stand-in stamps, `capture_standin.sh` | publish gate | per wing | untouched | retire the interior ones only if the fallback goes |
| Pack-content gate | `tools/qa/pack_manifest/` | every pack's file list | – | two new files in every pack: `packcontents.py write` at the next export |
| Web tests | `seamtest.py`, `doortest.py`, `wsS_webtest.py` | expect a page load at each border | unchanged (streaming is off by default) | when it turns on: seam and threshold tests expect no load |

## e. Lighting at the border
Both sides, both wings in, baked (the Demo 54 lightmaps), nothing between them:
`wsSEAMLESS-seam-from-wing1-before-after.jpg` (right half), `wsSEAMLESS-seam-from-wing2-before-after.jpg` (right half).

- **No step is visible on the floor, walls or ceiling in either direction.** The reason is how the wings are baked:
  each wing's bake already contains the other wing's halls and courts (the stand-in, at a coarser texel) and its
  lit shop pictures, so each wing's own surfaces were lit with the neighbour there. Hiding the stand-in after
  the bake leaves that light in place.
- The floor pattern changes at the seam (hall tile to court checker, with a dark border strip), which would also
  hide a small step if there were one.
- People and other dynamic things are lit by each wing's light probes; both wings' probes cover the border. The
  attendant and the shopper in the court read correctly after the handoff. Not checked: someone standing exactly
  on the line while the two probe sets disagree.
- Not looked at: the Sears, Dillard's and cinema openings (stage 3). There the mall wing shows the room as a picture
  in the opening and the room wing has the mall as a stand-in, so the same reasoning should hold, but the room's
  own light does not reach the mall's bake except through that picture.

**Recommendation: no seam fix and no rebake for wings 1 and 2.** Keep baking each wing with its neighbours' halls
as they are now. The options, should a step show up at an opening in stage 3:
1. Leave it: the opening has a bulkhead and a floor change like the seam (no rebake).
2. Match the two sides in the bake: bake the room wing with the mall wing's court at full texel for a few metres
   past the opening, and the reverse (rebakes the two wings at that opening: 1 and 4, or 2 and 5, both years).
3. A short neutral threshold: a darker floor strip and soffit at the line (a builder change; rebakes the same wings).

## f. Choices for the director (options, with what I would pick)

**1. The phone's memory**
- A. *Split what every wing shares into a "common" pack* (like `items`; `tools/shared_packs.json`). Wing packs
  become about 70, 74, 18, 19 and under 1 MB in the 1990s; a neighbour costs 64 MB instead of 154 in download and
  in memory; the whole 1990s interior is 311 MB instead of 666. No picture changes. Cost: the pack lists
  (`pack_manifest/`), one export and upload, and the publish checks see one more shared pack. **My pick; do it
  before turning phones on.** It also shortens every load screen that remains.
- B. Phones keep one neighbour at most and unload sooner (settings only). Already how it is built.
- C. Smaller textures for far wings, or VRAM-compressing the WebP textures: lowers picture quality, needs
  before/after shots and Steven's yes. Not started.
- D. Phones keep a brief load at the department stores and stream only the seam.

**2. Slow line: the next wing is not ready at the border**
- A. As built: the pictures and the seam's wall stay, and the old prompt offers the old load. It has words on the
  game screen (it always did).
- B. No prompt: the wall holds for the seconds it takes and a wordless cue shows at the border (a soft pulse along
  the floor line); the old load happens by itself only if the fetch fails. **My pick**, once streaming is on by default.
- C. Slow the walk over the last metres so the wing wins the race. Feels like a fault.

**3. When to turn it on**
- A. Desktop on now (`"enabled": {"desktop": true, "mobile": false}`), phones after option 1A and a look on
  Steven's iPhone. The neighbour's people and items still pop at the border.
- B. Wait for stage 3 (people and items spanning wings, thresholds, 2026), then turn both on. **My pick** for the
  live page; A is fine for a preview link (`?stream=1` works on any build from this branch without the setting).

**4. The stand-in after stage 3**
- A. Keep it as the fallback and as the bake's lit context (no pipeline change; today's choice).
- B. Keep the neighbours' halls in the bake but stop capturing storefront pictures once every border streams and
  the fallback is a wall (2B): saves the 17 to 40 minute recapture per bake; the bake loses the lit shop pictures,
  so the halls near a border would bake slightly darker (rebake of every interior wing to see it).

## Tests on this branch
- `tools/qa/stream_test.gd`: `STREAM TEST OK (desktop)` and `(mobile)` (unload).
- `tools/qa/stream_webtest.py`: `STREAM WEB OK` from wing 1 into wing 2 and from wing 2 into wing 1 (mobile pack),
  0 page errors, no load screen, no page load.
- The 8 headless suites: SHOP 200, CUCOS 89, FLAGS 31, INVENTORY 45, REDEMPTION 32, ECON 52, MENU UNIT 64,
  INT D49: all OK.
- `stockrooms_test.gd` (xvfb): **3 of 12 checks fail** ("locked before the Rougarou has gone through", "the caption
  shows within 2 m of the stick", "buttons and Jump back"). **The same three fail with main's `player.gd` and
  `mall_runtime.gd` put back** (run on this box, same build), so they are not from this branch; the Nov 4 status
  doc already lists "stockrooms_test 3 fails". 0 script errors.
- `rougarou_test.gd`, `rougarou_stalk_test.gd` (xvfb): **do not finish** (15 and 7 minutes, no check printed). Both wait
  for a node named `RougarouAI`, which `player.gd` no longer makes ("the Runner ... replaced the Rougarou, kept but no
  longer made"): they cannot pass on main either. `rougarou_story_test.gd` not run for the same reason.
- `tests/unit/hosting/pack_base_test.js`: PACK BASE OK. `tools/qa/packcontents_test.py`: OK.
- Desktop pack: one web run from wing 2 into wing 1 with `pack=desktop`: `STREAM WEB OK`.
- Not run: the other web suites (walk 12/12, doors, directory jump, redemption, shops). Streaming is off by
  default and those paths are untouched; the director's integration run covers them.

---

## Stage 3 (added Nov 13 to 14): every border, the common pack, on by default

Sections a to f above are the stage 1 and 2 record and are left as written. What changed since:
streaming is **on by default** for both pack kinds; every interior border streams in both years; the neighbour's
people and things are there before the border. Full status: `production/session-handoff-2026-11-13-SEAMLESS.md`.

### Packs before and after the common pack (MB; before = Demo 54 on R2, after = this branch, same lightmaps)
| | Before | After |
|---|---|---|
| `w1` / `w2` | 150.6 / 154.2 | 91.0 / 94.7 |
| `w4` / `w5` / `w6` | 98.6 / 99.4 / 80.3 | 39.0 / 39.9 / 20.7 |
| `w1y26` / `w2y26` / `w4y26` / `w5y26` / `w6y26` | 107.8 / 138.9 / 152.0 / 94.7 / 80.4 | 48.3 / 79.3 / 92.5 / 35.1 / 20.9 |
| `w3` / `w3y26` | 119.4 / 104.4 | 59.9 / 44.8 |
| `items` / `common` (each once) | 84.0 / none | 84.0 / 59.6 |
| Whole 1990s interior with both shared packs | 667.1 | 428.9 |
| Everything, one kind of device | 1,464.7 | 809.7 |

Section f's guess of 311 MB for the 1990s interior was too low: only what is byte-identical in every pack and safe
to mount first was moved (the cast's bodies and the animation library, 59.6 MB).

### Browser memory on the walk from Dillard's to Sears to Corn Dog 7
Headless Chromium with the software renderer on the cloud box, every Chromium process added up: inflated, for
comparing runs only. Stage 1 measured one wing at 2.8 to 3.2 GB and two at 4.1 to 4.5 GB the same way.

| Pack, year | Peak | Wings in at the end | Page errors | Load screen |
|---|---|---|---|---|
| mobile, 1990s | 5,446 MB | 2, 1 | 0 | never |
| mobile, 2026 | 4,339 MB | 2, 1, 5 | 0 | never |
| desktop, 1990s | 5,525 MB | 1, 2, 4, 5 (all but the gated cinema lobby) | 0 | never |
| desktop, 2026 | 4,909 MB | 1, 2, 4, 5 | 0 | never |

The mobile 1990s peak is as high as desktop's because a far wing is unloaded only after the next one is in, so
three wings overlap for a moment. All four interior wings together cost about 0.1 to 0.6 GB more than two here.
**Not measured: any real device.**

### The blue floor in a streamed department store
`wsSEAMLESS-floor-tint-settle.jpg`. Just streamed in, a store's polished floor mirrors the sky (a cool cast) until
its reflection probes have taken their pictures, 360 to 400 frames after the last node enters. It is not a bake
step. The probes now enter after the meshes and a room wing stays "coming" for 480 frames (`settle_frames` in
`data/stream.json`). **What a player sees during the wait: the store's opening still shows its storefront picture,
then the real store; never the tinted floor.** A player who reaches the line first is held there behind the cue.
On this box, at under one frame a second, that wait was 585 to 1,357 s at the Sears / Lynn's opening; at 30 to 60
frames a second it is 8 to 16 s. Whether a walking player can outrun it on a real machine is not verified.

### Tests with streaming on by default (build of `a4334dd`)
Native: the 8 headless suites, `stream_test.gd` (desktop, mobile, `--fail`) and `stream_walk_test.gd`: all OK.
Web: the walk x4 OK; movetest MOVED 4 of 4; doortest CROSSED 3 of 3 (outside doors); MENU TRIP WEB OK (20);
REDEMPTION WEB OK; SHOPS WEB OK (21); 0 page errors throughout. `stockrooms_test.gd` and the Rougarou tests are
as in "Tests on this branch" above: failing the same way on main, not repaired. Details in the handoff.
