# Worker handoff: SEAMLESS (Fri Nov 13, 2026), stages 1 to 3

Branch `ws/seamless` from main `81cb3ba9` (Demo 54). Brief: `claude/briefs-2026-11-13-seamless.md` (project doc), plus
the director's calls of Nov 13 on findings section f (the common pack; a wordless cue on a slow line; on by default
after stage 3; keep the stand-in). Not merged, not baked, not published, nothing uploaded.

Stage 3 was written by four worker runs: two were killed by restarts of the cloud box and one by the usage limit.
Every item below was pushed when it passed its check; nothing is left only on the box except raw test shots.

## Done / partly / not started
| Item | State |
|---|---|
| Stage 1, measure and report | Done. `production/qa/evidence/wsSEAMLESS-findings.md`. |
| Stage 2, wing 1 ↔ wing 2 | Done. |
| 3a. People and things before the border; skylight glass once | **Done.** Attendants, items and shop stock are made for every wing that is in; the crowd is one node that outlives a crossing; the shared skylight panes are drawn once. |
| 3b. The common pack | **Done, smaller than estimated.** The cast's bodies and the animation library ship once (`common`, 59.6 MB). Each wing pack is 59.6 MB lighter. Shopper skins, scripts, data and what wings share pairwise are still duplicated (see "Packs"). |
| 3c. Every interior border, 1990s | **Done:** the seam, Sears, Dillard's, the cinema lobby (once its gate is open). The Stockrooms stay a load (a level inside wing 1, unchanged; brief allowed it; streaming them would need their own pack boundary and saves nothing today). |
| 3d. The same borders, 2026 | **Done.** |
| 3e. Desktop everything, phones neighbours | **Done.** Browser memory with the wings in: see "Web walk". |
| 3f. Wordless cue; on by default | **Done.** `data/stream.json` `"enabled": true` for desktop and mobile. |
| 3g. Tests | **Done except where the Tests section says otherwise.** Web walk OK on all four packs and years; web suites run with streaming on; doortest, seamtest and wsS_webtest updated. |
| Border shots, both years | **Partly.** 1990s: a before/after pair at every border on the web walk (`wsSEAMLESS-borders-1990s-webwalk.jpg`), the seam pairs and crossings from stage 2, the floor-tint pair. 2026: no sheet in the repo; the walk passed and its raw shots are on the box only. The cinema lobby border has no shot. |

## Borders
| Border | 1990s | 2026 |
|---|---|---|
| wing 1 ↔ wing 2 (the seam) | streams | streams |
| wing 1 ↔ wing 4 (Sears / Lynn's) | streams, after a probe wait | streams, after a probe wait |
| wing 2 ↔ wing 5 (Dillard's) | streams, after a probe wait | streams, after a probe wait |
| wing 1 ↔ wing 6 (cinema lobby) | streams once the gate is open | streams once the gate is open |
| inside ↔ outside, year switch, Stockrooms, mini-games, conversations | a load, as before | a load, as before |

## The blue floor (the director's question 1)
A streamed department store's polished floor mirrored the sky (a cool, bluish cast) until its reflection probes had
taken their pictures: 360 to 400 frames after the last node entered (about 7 s at 60 frames a second, 13 s at 30).
It is not a bake step. Fix: the probes enter after the meshes, and a room wing stays "coming" for 480 frames
(`settle_frames`). **What the player sees: the store's opening shows its storefront picture a few seconds longer,
then the real store; never a tinted floor.** If the player reaches the line first, the border holds behind the
wordless cue. On desktop the wait happens in the background after the first card.
Evidence: `production/qa/evidence/wsSEAMLESS-floor-tint-settle.jpg` (inside Dillard's just streamed in, and 480 frames
later; from the court during the wait, and after). Not checked: whether 480 frames is enough on a slow phone
(the count is frames, not seconds, so a slow device waits longer, which is the safe direction).

## Web walk: Dillard's → Sears → Corn Dog 7 (`tools/qa/stream_walk_webtest.py`, build of `a4334dd`, streaming on by default)
All four runs: `STREAM WALK WEB OK`, the load screen never shown, no page load, 0 page errors.

| Pack, year | Result | Peak memory (all Chromium processes) | Wings in at the end | Longest wait for a wing at a border |
|---|---|---|---|---|
| mobile, 1990s | OK | 5,446 MB | 2, 1 (far wings unloaded) | Sears 616 s |
| mobile, 2026 | OK | 4,339 MB | 2, 1, 5 | Lynn's 52 s |
| desktop, 1990s | OK | 5,525 MB | 1, 2, 4, 5 (every interior wing but the gated cinema lobby) | Sears 585 s |
| desktop, 2026 | OK | 4,909 MB | 1, 2, 4, 5 | Lynn's 1,357 s |

**The long waits are the probe wait counted in frames on a box drawing under one frame a second** (480 frames; the
software renderer with two to four wings in). The other borders came in within 4 to 62 s. On a real GPU 480 frames is
8 to 16 s. During the wait the test stood at the line behind the cue; nothing loaded or reloaded. This is the number
to check first on Steven's machines: if the Sears or Lynn's opening holds a walking player, lower `settle_frames`
or start the store earlier.

Memory is every Chromium process on the cloud box with the software renderer: inflated, and not a phone's number.

## Packs (MB; before = Demo 54 on R2, after = this branch, same lightmaps)
| | Before | After |
|---|---|---|
| `w1` / `w2` | 150.6 / 154.2 | 91.0 / 94.7 |
| `w4` / `w5` / `w6` | 98.6 / 99.4 / 80.3 | 39.0 / 39.9 / 20.7 |
| `w1y26` / `w2y26` / `w4y26` / `w5y26` / `w6y26` | 107.8 / 138.9 / 152.0 / 94.7 / 80.4 | 48.3 / 79.3 / 92.5 / 35.1 / 20.9 |
| `w3` / `w3y26` | 119.4 / 104.4 | 59.9 / 44.8 |
| `items` / `common` (each once) | 84.0 / none | 84.0 / 59.6 |
| Whole 1990s interior with both shared packs | 667.1 | 428.9 |
| Everything, one kind of device | 1,464.7 | 809.7 |

Section f guessed 311 MB for the 1990s interior; it is 428.9. Only what is byte-identical in every pack and safe to
mount first was moved. A second split (scripts, data and shopper skins into `common`; a pack for what wings 1 and 2
share) would get closer; `design/godot-build-hosting.md` "The common pack" says why it was not done here.

## Tests
All on the build of `a4334dd` (no project file has changed since), streaming on by default.

Native (headless):
- The 8 suites: SHOP 200, CUCOS 89, FLAGS 31, INVENTORY 45, REDEMPTION 32, ECON 52, MENU UNIT 64, INT D49: all OK.
- `stream_test.gd`: OK desktop, OK mobile (unload), OK `--fail` (a pack that cannot be fetched: no prompt, the old
  crossing starts by itself).
- `stream_walk_test.gd`: OK (desktop, 1990s) and OK (mobile, 2026), including the cue.

Web (headless Chromium, one browser at a time):
- `stream_walk_webtest.py`: OK x4 (table above).
- movetest (walk): MOVED, 0 errors, in wing 1 and wing 2, 1990s and 2026 (4 of 4).
- doortest: CROSSED, 0 errors: main entrance 1990s, Sears outside door 1990s, main entrance 2026 (3 of 3). These
  are inside ↔ outside, still a load.
- `menu_trip_webtest.js` (directory jump and the year trip): MENU TRIP WEB OK, 20 checks.
- `redemption_webtest.py`: REDEMPTION WEB OK, 0 errors (iPhone portrait and landscape sizes).
- `shops_webtest.py both`: SHOPS WEB OK, 21 checks, 0 console errors (Woolworth, RadioShack, Corn Dog 7, B. Dalton).

Not run on this build: seamtest and wsS_webtest (updated to `?stream=0`, not rerun), the stream border web test
from stage 2 (superseded by the walk), `packtest.py`, the cast count and full MENU web suites.

Failing, and failing the same way on main (not repaired, outside this job): `stockrooms_test.gd` 3 of 12;
`rougarou_test.gd` and `rougarou_stalk_test.gd` never finish (they wait for a `RougarouAI` node the game no longer
makes); `rougarou_story_test.gd` not run.

## Lighting at the borders
No lighting step seen at any border in the walk shots (1990s and 2026): each wing's bake already includes its
neighbours' halls. **No rebake asked for.** Not looked at: night (the build is day only), a real GPU.

## Rebake
None. `gen/` is untouched, so every stand-in stamp stays valid.

## For the director
- **Integration:** `export_presets.cfg` and `tools/qa/pack_manifest/*` were rewritten by script on this branch. If
  another branch in int-55 touches them, regenerate (`tools/make_presets.py`; export; `python3
  tools/qa/packcontents.py write <builddir>`), never hand-merge. Small marked hunks (SEAMLESS) are in
  `scripts/player.gd`, `mall_runtime.gd`, `npcs.gd`, `interact.gd`, `shop.gd`, `dialogue/story.gd`, `story/cucos.gd`,
  `cinema_gate.gd`, `web/shell.html`. `data/stream.json` `wing2_zones` must stay equal to `tools/build_mall.gd`
  `WING2_ZONES`.
- **Export:** as before (`tools/export_web.sh`); it now also writes `common.desktop.pck` and `common.mobile.pck`.
- **Upload / publish:** as before. `tools/publish_build.sh` is unchanged and already checks every shared pack the
  page lists; two more files go to R2 per build. The stand-in pictures are still required and stamped.
- **Bake:** none for this branch.
- **To turn it off** without a new build: `?stream=0`. For a build: `data/stream.json` `"enabled"`.
- **`ws/seamless-wip`** (070db52): the same common-pack files, superseded by `32be6dc`. It can be deleted now.

## Changed outside the brief's scope
- `tools/qa/doortest.py`, `seamtest.py`, `wsS_webtest.py`: an inside border is checked with `?stream=0` (the brief
  asked for doortest; the other two test the same old crossing).
- `scripts/npcs.gd`, `interact.gd`, `shop.gd`, `dialogue/story.gd`, `story/cucos.gd`, `cinema_gate.gd`: small marked
  hunks so people and things exist for every wing that is in. No store interior, sign, exterior, character look,
  story data or HUD file was touched. `tools/publish_build.sh` was not touched.

## Not verified
- Anything on a real phone or a real GPU: memory, frame times, the 480-frame wait, the cue's look.
- The cinema lobby border in a browser (the web walk does not go there; native walk test only).
- VR with streaming; a night lighting change with neighbours in (the build is day only).
- `stockrooms_test.gd` (3 of 12 fail, the same on main) and the Rougarou tests (wait for a node the game no longer
  makes; the same on main): not repaired, outside this job.

## Open for Steven (through the director)
- On the iPhone: does the walk from Dillard's to Sears hold, and how long does the store's opening show its picture?
- The cue is a soft pulse along the floor line. Right, or something else?
