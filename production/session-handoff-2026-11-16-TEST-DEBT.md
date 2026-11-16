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
