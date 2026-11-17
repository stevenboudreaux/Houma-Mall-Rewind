# TEST-DEBT: the stockrooms and Rougarou suites (Mon Nov 16, 2026)

Branch `ws/test-debt`, from `ws/seamless-upfront` @ `74cef19e`. Tests only: **no game code changed**,
no bake, no publish, no merge. Shots are unbaked.

## The headline
**The Rougarou is not in the game.** Since Oct 16 2026 `scripts/player.gd` makes the Runner instead
("He replaced the Rougarou (scripts/rougarou_ai.gd, kept but no longer made)"), and `stockrooms.gd`
opens the door for everyone ("the Rougarou is gone"). So no player meets it in Woolworth's aisles or
anywhere else. The two Rougarou suites hung because they waited for a node the game deliberately no
longer makes. They now make it themselves (`tools/qa/rg_spawn.gd`, the way player.gd used to), so a
pass means **the parked code still works on today's wing**, not that it is in the game.

**For Steven (not decided here):** (A) keep the Rougarou parked with the suites as they are now;
(B) delete `rougarou_ai.gd`, `rougarou.gd`, `rougarou.json` and the four Rougarou suites;
(C) bring it back (your story call: where, which mode, alongside the Runner or not).

## Each failure

| Suite | Failure | Verdict | What changed |
|---|---|---|---|
| stockrooms_test | "locked before the Rougarou has gone through" | **stale test**: open for everyone since Oct 16 (Steven) | checks the door is open from the start |
| stockrooms_test | "the caption shows within 2 m of the stick" | **stale test**: the stick is a pick-up since Nov 1 (B+C); the caption is off on purpose | checks the action prompt reads "Pick up Martin Folse's stick" (caption only without the item) |
| stockrooms_test | "buttons and Jump back" | **stale test**: corner buttons are the owner's since Nov 4 (`owner_hud_sync`), hidden for a visitor in the mall too | checks the HUD is as it was before going in |
| stockrooms_test | "the mall is hidden (1 visible)", on this branch only | **stale test order, plus a minor game finding F1**: the old lock step went in, was pulled out by the "left by Jump" restore, went in again while wing 2 streamed in | test now goes in once; adds "still hidden before leaving" and "second visit"; streaming off by default, `--stream` to keep it |
| rougarou_test | never finished | **stale test**: waits for `RougarouAI` | makes it via `rg_spawn.gd`; 60 s load timeout |
| rougarou_stalk_test | never finished | **stale test**: same | same |

### F1 (game, low, not fixed: `scripts/wing_stream.gd` is PHONE-MEMORY's)
When a wing finishes streaming in while the player is in the Stockrooms, `wing_stream._resync()` shows
again every node it had hidden as a cross-wing duplicate, after the Stockrooms hid the mall. Seen: wing 1's
"Information" plaque (`@Label3D@505`, (-52, 3.05, 54)) visible while inside. Inside it is ~2.9 km from the
camera (far plane 200 m), so nothing is drawn. In a rarer order (a resync while inside after the stream had
hidden the *other* copy) both copies of a label could show at the same spot after leaving until the next
resync. On computers the load screen holds until the interior is in; phones do not stream; so this needs a
wing to arrive during a visit. Smallest fix (wing_stream.gd, ~3 lines): skip `_resync()` while the player is
away (`not _idle()` by position) and run it in the existing `_was_away and not away_now` branch.
Wing 2's streamed root also sits under the tree root, so the Stockrooms never hide it; it is beyond the far
plane too. Evidence: the old suite's log line `VISIBLE @Label3D@505 Label3D text=Information`.

## The new check: `tools/qa/rougarou_woolworth_test.gd`
Story stage 3 in Woolworth after the Demo 54 layout, wing 1 at night, streaming off:
148 lurk spots in the back half, **every one joined to the store's front on free floor** (the player can
reach it, it can reach the player) and **every one with a route to the back corner**; 145 shelf rects feed
its line of sight, 0 fixture obstacles in the store. Live: the player walks in along free floor; three ducks
(3 tiles each), the exit walk (17 steps) reaches the corner (0.00 m), it steps into the wall, the route ends
(stage 0) and the Stockrooms door is open. On free floor in all 33 running frames; longest run 2.4 s (stuck
= 6 s). The harness's own walk snagged once on a shelf end and stepped to the next tile (counted, printed).

## Counts
| Suite | Before (this branch) | After |
|---|---|---|
| stockrooms_test | 8 / 12 (main: 9 / 12) | **14 / 14** (also 14 / 14 with `--stream`) |
| rougarou_test | never finishes | **12 / 12** |
| rougarou_stalk_test `--fast` | never finishes | **10 / 10** |
| rougarou_woolworth_test (new) | n/a | **12 / 12** |
| 8 headless | | SHOP 200, CUCOS 89, FLAGS 31, INVENTORY 45, REDEMPTION 32, ECON 52, MENU UNIT 64, INT D49: all OK |

Not run: `rougarou_story_test.gd` (same dead-node wait; out of scope, one `rg_spawn` call fixes it), web tests.

## Files
- `tools/qa/stockrooms_test.gd`, `rougarou_test.gd`, `rougarou_stalk_test.gd` (edited, `TEST-DEBT` comments)
- `tools/qa/rg_spawn.gd`, `tools/qa/rougarou_woolworth_test.gd` (new)
- `tools/qa/README.md`, `design/godot-stockrooms.md`, `design/godot-rougarou.md`
- Evidence `production/qa/evidence/wsTEST-DEBT-*-unbaked.jpg` (11)

## For other workstreams
- No shared game file touched. No wing needs a rebake.
- Native tests: a software-GL frame of the mall with a second wing streamed in takes minutes on 2–4 CPUs;
  set `Engine.set_meta("mall_stream", false)` in tests that stay in one wing.
- Setup note: CLAUDE-CLOUD.md's `git archive origin/godot-build lightmaps standin` must run from the repo
  root (paths are repo-relative); from the project folder it fails. Lightmap reimport took ~80 min here.

---

# Part 2: the Rougarou deleted (Tue Nov 17, 2026; Steven's decision, option B)

## 1. Every reference before the deletion (`git grep -i rougarou`, file names, uids, `rg_mannequin`)

**Only the Rougarou's (deleted, see 2):** `scripts/rougarou_ai.gd` (+ `.uid`), `scripts/rougarou.gd` (+ `.uid`),
`scripts/rougarou.json`, `tools/qa/rg_spawn.gd`, `tools/qa/rougarou_test.gd`, `rougarou_stalk_test.gd`,
`rougarou_story_test.gd`, `rougarou_woolworth_test.gd`, `rougarou_shot.gd` (each test + `.uid`). Nothing
referenced the two scripts' uids (`uid://bu27hbjt430ny`, `uid://bai8q4bt05625`); no scene, preset or
`project.godot` named them.

**Game code (dead references, edited in 2):** `scripts/player.gd:280` (comment);
`scripts/stockrooms.gd` lines 2, 17-18 (header), 81-85 (`unlock()`, called only by the Rougarou, with
`_load_unlock` / `_save_unlock`), 134 and 141-144 (`RougarouAI` skipped / paused on the way in), 185
(`RougarouAI` resumed on the way out).

**Export lists (edited in 2):** `tools/qa/pack_manifest/w1, w1y26, w2, w2y26, w3, w3y26, w4, w4y26, w5,
w5y26, w6, w6y26.txt`: three lines each (`scripts/rougarou.gd`, `.json`, `_ai.gd`). `publish_build.sh`
refuses a build whose packs differ from these lists. No export filter or preset names the Rougarou.

**Tests and tools (edited in 2):** `tools/qa/stockrooms_test.gd` (three `RougarouAI` exceptions, the
lock-check wording, the `mall_stockrooms` meta); `tools/qa/README.md`.

**Left alone: STOP for Steven (story data, scenes, models, a store's prize, the Runner):**
| Where | What |
|---|---|
| `data/items/pocket_change.json` (`pc_claw_rougarou`, "Rougarou plush"), `models/pc_claw_rougarou.scn`, `tex/items/pc_claw_rougarou.png(.import)` | Pocket Change's claw-machine prize, a mall character plush. Item data and a model. |
| `play/claw.html:346`, `play/claw/logic.js:56,69`, `tests/unit/claw/logic.test.js:55` | the claw game's prize kinds and fill (the plush) |
| `tools/claw_prizes/build_claw_prizes.gd`, `claw_prizes_shot.gd`, `export_claw_prizes.py`, `tools/stores/pocket_change/paint_claw_game.py`, `tools/qa/econ_test.gd:191`, `tools/qa/fixtures/item_ids_int51.txt:85` | builders and checks of the same plush |
| `wing2.tscn` node `Dynamic/dyn_rg_mannequin`, `gen/w2/dyn_rg_mannequin.res` (and in `pack_manifest/w2.txt`) | Merry-Go-Round's right-hand window form, made its own mesh for the Rougarou; **the Runner uses it now** (`runner_ai.gd:68`, `runner_test.gd:68`). Scene and baked wing. |
| `tools/stores/small/wave7.gd:93-95`, `tools/stores/apparel/kit.gd:217,221`, `tools/stores/apparel/more.gd:117` | the builder comments that explain why that form is its own mesh (they name `rougarou_ai.gd`); changing them rebuilds nothing, but they are scene builders |
| `scripts/runner_ai.gd:1,5`, `design/godot-runner.md:3-9,45` | the Runner ("the Rougarou's replacement"; the doc still says the scripts "are kept for reference") |
| `scripts/npcs.gd:7,367` | two comments comparing the shoppers' grid with "the Rougarou's" (history; not in this job's two files) |
| `design/godot-economy.md:158`, `design/storefronts/pocket-change.md:141`, `design/corner-2026-c2.md:180` | the plush; an old test note |
| `production/` handoffs and `production/qa/evidence/d25`-`d33` Rougarou shots and logs, `wsPACKS-diagnosis.md`, `wsSEAMLESS-findings.md` | the record; left as is |

**Questions for Steven:** keep the Rougarou plush in the claw machine (it is a toy of the folklore figure,
not the NPC)? Rename `dyn_rg_mannequin` some day (a wing 2 rebuild and rebake, and `runner_ai.gd`)? Update
`godot-runner.md`'s "kept for reference" line?

## 2. Deleted and edited (commit on `ws/test-debt`)
- Deleted: the five scripts/data files and the six QA files above (+ their `.uid`s). `rougarou_shot.gd` was not on
  the list but is Rougarou-only and loads `rougarou.gd`, so it would break: deleted with the rest.
- `scripts/player.gd`: one comment line (the Rougarou "removed Nov 16 2026").
- `scripts/stockrooms.gd`: header reworded; `unlock()` / `_load_unlock()` / `_save_unlock()` removed (dead since
  Oct 16, only caller deleted); the `RougarouAI` exception, pause and resume removed; each with a short comment.
  The Runner is resumed on the way out exactly as before; it is still not paused on the way in (unchanged).
  The `localStorage` key "mall-stockrooms" stays in old browsers, unread.
- `tools/qa/stockrooms_test.gd`: the three `RougarouAI` exceptions and the `mall_stockrooms` meta gone; the door
  check reads "the door is open from the start".
- `tools/qa/pack_manifest/*.txt`: the three script lines out of each of the 12 wing lists.
- `tools/qa/README.md`; `design/godot-rougarou.md` marked REMOVED (Nov 16, Steven), kept as history;
  `design/godot-stockrooms.md` two history notes.

## 3. Tests (part 2)
| Check | Result |
|---|---|
| `stockrooms_test.gd` | **STOCKROOMS TEST OK (14 checks)**; no check names the Rougarou now |
| 8 headless | SHOP 200, CUCOS 89, FLAGS 31, INVENTORY 45, REDEMPTION 32, ECON 52, MENU UNIT 64, INT D49: all OK, 0 script errors |
| Web export, all 12 wing packs (`.scratch/builds/td`, unbaked) | `packcontents: 12 wing + 2 shared packs, every reference shipped, contents match tools/qa/pack_manifest/`: the hand-edited manifests are exactly what the export gives |
| Wing 1, 1995, web (`movetest.py`, `?wing=1&stream=0`) | 3 cameras **0 errors**, touch walk **MOVED** |
| Wing 1, 2026, web (`?wing=1&stream=0&year=2026`) | 3 cameras **0 errors**, touch walk **MOVED** |

- With streaming on (the computer default) movetest's 240 s wait ends behind the load card ("Getting the shoppers
  ready… 22/22", 0 errors, the walk does not move): UPFRONT holds the card until the whole interior is in, 18-35 min
  on this software renderer (UPFRONT handoff). So the load checks use `?stream=0`, as doortest / seamtest do.
  An earlier wings-1-and-2-only export also showed two "could not bring wing 4 / 5 in: HTTP 404" errors: those
  wings were not exported then; with all 12 packs, 0.
- Evidence: `production/qa/evidence/wsTEST-DEBT-p2-web-wing1-1995-2026-unbaked.jpg` (1995 above, 2026 below).
- Setup note: python Playwright is not preinstalled in this container (only Node's); `pip install playwright==1.63.0`
  matches the browsers in `/opt/pw-browsers`.

## 4. Rebake
**None.** No scene, mesh, material, layout or baked wing changed; the stand-in pictures' hashes do not involve the
deleted scripts. The next export must use the updated `pack_manifest` (it does: checked above).
