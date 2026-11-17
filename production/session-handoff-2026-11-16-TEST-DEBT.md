# TEST-DEBT handoff (Nov 16–17, 2026)

Branch **`ws/test-debt`** @ `4af9489`, from `ws/seamless-upfront` @ `74cef19e`. Two commits:
`d065c03` (the suites fixed and a Woolworth check) and `4af9489` (the Rougarou deleted, Steven's decision).
Pushed. **Not merged, not baked, not published.** Shots are unbaked.

## Where it stands
- **The Rougarou is gone from the project** (Steven, Nov 16: option B). It had been out of the game since
  Oct 16, when the Runner (`scripts/runner_ai.gd`) replaced it; its code was kept, unused, and its suites hung
  waiting for a node the game no longer made.
- **`stockrooms_test` passes 14 of 14** (was 8 of 12 on this branch, 9 of 12 on main). Its failures were stale
  tests, not game bugs.
- **One minor game finding (F1) is written up, not fixed:** it lives in `scripts/wing_stream.gd`, which
  PHONE-MEMORY owns.
- **No wing needs a rebake.** No scene, mesh, material, layout or baked wing changed.

## For the integration session (read before merging)
1. **Pack manifests changed.** The three deleted scripts are out of all 12 wing lists in
   `tools/qa/pack_manifest/`. A full export on this branch reports `every reference shipped, contents match
   tools/qa/pack_manifest/`. If PHONE-MEMORY also rewrote the manifests, regenerate them after merging with
   `packcontents.py write`; don't hand-merge them. `publish_build.sh` refuses a build that differs.
2. **Shared game files touched, small commented hunks only:** `scripts/player.gd` (one comment line) and
   `scripts/stockrooms.gd` (header; `unlock()` / `_load_unlock()` / `_save_unlock()` removed; the `RougarouAI`
   exception, pause and resume removed). The Runner's handling in `stockrooms.gd` is unchanged: resumed on the
   way out, not paused on the way in.
3. **Not touched:** `wing_stream.gd`, `data/stream.json`, export presets, `export_web.sh`, `publish_build.sh`, any
   scene, the Runner, story data, dialogue.

## What was wrong, and the fix

| Suite | Failure | Verdict | Fix |
|---|---|---|---|
| stockrooms_test | "locked before the Rougarou has gone through" | Stale test: the door has been open for everyone since Oct 16 | Checks the door is open from the start |
| stockrooms_test | "the caption shows within 2 m of the stick" | Stale test: the stick has been a pick-up item since Nov 1; the caption is off on purpose | Checks the prompt reads "Pick up Martin Folse's stick" |
| stockrooms_test | "buttons and Jump back" | Stale test: the corner buttons have been owner-only since Nov 4, hidden for a visitor everywhere | Checks the HUD is as it was before going in |
| stockrooms_test | "the mall is hidden (1 visible)" (this branch only) | Stale step order, which exposed finding F1 | Goes in once; adds "still hidden before leaving" and "a second visit"; streaming off by default, `--stream` keeps it on |
| rougarou_test, rougarou_stalk_test | never finished | Stale: waited for `RougarouAI` | Made to pass on Nov 16 (12/12 and 10/10, see history), then **deleted** with the Rougarou on Nov 17 |

### F1: a wing arriving during a Stockrooms visit (game, low, not fixed)
- **What happens:** if a wing finishes streaming in while the player is in the Stockrooms,
  `wing_stream._resync()` re-shows the cross-wing duplicates it had hidden. That happens after the Stockrooms
  hid the mall.
- **Seen:** wing 1's "Information" plaque (`@Label3D@505` at (-52, 3.05, 54)) was visible while the player was
  inside. It is about 2.9 km from the camera, and the far plane indoors is 200 m, so nothing is drawn.
- **Rarer case:** both copies of a label could show at the same spot after leaving, until the next resync.
- **Why it's unlikely in play:** it needs a wing to arrive during a visit. On computers the load screen holds
  until the whole interior is in, and phones don't stream wings.
- **Smallest fix (`wing_stream.gd`, about 3 lines):** skip `_resync()` while the player is away, and run it in the
  existing `_was_away and not away_now` branch.
- **Related:** a streamed wing's root sits under the tree root, so the Stockrooms never hide it either. It is
  also beyond the far plane.

## The Rougarou deletion (commit `4af9489`)

**Deleted:**
- **Scripts and data:** `scripts/rougarou_ai.gd`, `scripts/rougarou.gd` (each with its `.uid`),
  `scripts/rougarou.json`.
- **QA files:** `tools/qa/rg_spawn.gd`, `rougarou_test.gd`, `rougarou_stalk_test.gd`,
  `rougarou_story_test.gd`, `rougarou_woolworth_test.gd`, `rougarou_shot.gd` (with their `.uid`s).
- **Not on Steven's list:** `rougarou_shot.gd`. It is Rougarou-only and loaded `rougarou.gd`, so it would have
  broken.
- **References checked:** nothing referenced the two scripts by path or by Godot ID (`uid://bu27hbjt430ny`,
  `uid://bai8q4bt05625`). No scene, export preset or `project.godot` named them.

**Edited:**
- `scripts/player.gd` and `scripts/stockrooms.gd`, as above.
- `tools/qa/stockrooms_test.gd`: no check names the Rougarou now.
- `tools/qa/pack_manifest/*.txt`: the three script lines out of each of the 12 wing lists.
- `tools/qa/README.md`.
- `design/godot-rougarou.md`: marked "REMOVED on Nov 16, 2026, by Steven's decision" and kept as history.
- `design/godot-stockrooms.md`: two history notes.

**Left alone: Steven to decide.**

| Where | What |
|---|---|
| `data/items/pocket_change.json` (`pc_claw_rougarou`, "Rougarou plush"), `models/pc_claw_rougarou.scn`, `tex/items/pc_claw_rougarou.png(.import)`, `tools/qa/pack_manifest/w1.txt` (its texture) | Pocket Change's claw-machine prize. Item data and a model. |
| `play/claw.html:346`, `play/claw/logic.js:56,69`, `tests/unit/claw/logic.test.js:55` | The claw game's prize list (the plush) |
| `tools/claw_prizes/build_claw_prizes.gd`, `claw_prizes_shot.gd`, `export_claw_prizes.py`, `tools/stores/pocket_change/paint_claw_game.py`, `tools/qa/econ_test.gd:191`, `tools/qa/fixtures/item_ids_int51.txt:85` | Builders and checks of the same plush |
| `wing2.tscn` node `Dynamic/dyn_rg_mannequin`, `gen/w2/dyn_rg_mannequin.res`, `pack_manifest/w2.txt` | Merry-Go-Round's right-hand window form. **The Runner uses it now** (`runner_ai.gd:68`, `runner_test.gd:68`). Scene and baked wing. |
| `tools/stores/small/wave7.gd:93-95`, `tools/stores/apparel/kit.gd:217,221`, `tools/stores/apparel/more.gd:117` | Scene-builder comments explaining why that form is its own mesh |
| `scripts/runner_ai.gd:1,5`, `design/godot-runner.md:3-9,45` | The Runner ("the Rougarou's replacement"). The doc still says the Rougarou's scripts are "kept for reference". |
| `scripts/npcs.gd:7,367` | Two history comments |
| `design/godot-economy.md:158`, `design/storefronts/pocket-change.md:141`, `design/corner-2026-c2.md:180` | The plush; an old test note |
| `production/` handoffs; `production/qa/evidence/d25`–`d33` and `wsTEST-DEBT-rg-*` | The record, including the Nov 16 shots of the Rougarou in Woolworth's aisles (code now deleted) |

## Open questions for Steven
1. Keep the **Rougarou plush** in Pocket Change's claw machine? It's a toy of the folklore figure, not the
   creature itself.
2. Rename **`dyn_rg_mannequin`** some day? That means a wing 2 rebuild and rebake, plus a `runner_ai.gd`
   change.
3. Fix `design/godot-runner.md`'s "kept for reference" line? It's the Runner's doc, so it was left alone.
4. Hand **F1** to PHONE-MEMORY, or fix it after their merge?

## Tests (final state, `4af9489`)

| Check | Result |
|---|---|
| `stockrooms_test.gd` | **STOCKROOMS TEST OK (14 checks)**; also 14 / 14 with `--stream` (Nov 16) |
| 8 headless suites | SHOP 200, CUCOS 89, FLAGS 31, INVENTORY 45, REDEMPTION 32, ECON 52, MENU UNIT 64, INT D49: all OK, 0 script errors |
| Web export, all 12 wing packs (unbaked) | Every reference shipped; contents match `tools/qa/pack_manifest/` |
| Wing 1, 1995, web (`movetest.py`, `?wing=1&stream=0`) | 3 cameras, **0 errors**; touch walk **MOVED** |
| Wing 1, 2026, web (`?wing=1&stream=0&year=2026`) | 3 cameras, **0 errors**; touch walk **MOVED** |

- **Web loads ran with streaming off (`?stream=0`, the phone setting)**, as doortest and seamtest do. With
  streaming on, the load screen waits for the whole interior: 18–35 minutes on this software renderer, longer
  than movetest's 240 s wait. That run showed 0 errors, still behind the load card.
- **Not run:** the full computer-build walk (`stream_natural_walk_webtest.py`), other web suites.

**History, Nov 16** (before the deletion; those suites are gone now):
- `rougarou_test` 12/12 and `rougarou_stalk_test --fast` 10/10, with the Rougarou created by the test.
- A new `rougarou_woolworth_test` 12/12, on the Demo 54 Woolworth layout:
  - All 148 hiding spots joined the front on free floor, and each had a route to the back corner.
  - It ducked 3 times, walked 17 steps to the corner and went into the wall.
  - It stayed on free floor in every running frame; its longest run was 2.4 s.

## Evidence (`production/qa/evidence/`, unbaked)
- **Stockrooms:** `wsTEST-DEBT-sr-start-room`, `-sr-stick-prompt`, `-sr-back-in-woolworth`, `-sr-second-visit`.
- **Wing 1 web load (after the deletion):** `wsTEST-DEBT-p2-web-wing1-1995-2026` (1995 above, 2026 below).
- **The Rougarou, Nov 16 (code now deleted):** `wsTEST-DEBT-rg-wool-1` … `-5`, `-rg-sightings-far`,
  `-rg-stalk-ahead`.

## Notes for the next cloud session
- **Fetching lightmaps:** CLAUDE-CLOUD.md's `git archive origin/godot-build lightmaps standin | tar -x` only
  works from the repo root (the paths are repo-relative). After the archive, move them into the project folder.
  The lightmap reimport took about 80 min.
- **Web export templates** are needed for `tools/export_web.sh`. All 12 wings export in about 5 min. Exporting
  only some wings fails unless wings 1 and 2 are present, and the page then reports 404s for wings it can't
  fetch.
- **Python Playwright** isn't preinstalled (only Node's). `pip install --break-system-packages
  playwright==1.63.0` matches the browsers in `/opt/pw-browsers`. Serve only the build folder, on 127.0.0.1:8765.
- **Native tests:** with a second wing streamed in, one software-GL frame of the mall can take minutes. Use
  `Engine.set_meta("mall_stream", false)` in tests that stay in one wing.
