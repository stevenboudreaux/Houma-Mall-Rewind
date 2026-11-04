# Handoff: Demo 51 (Nov 4, 2026, ~1:20 PM CT): round 2 and packs on R2

**State: published.** `godot-build` = `b9f6d2c` (no packs; its page names R2 build `20261104-d51-4d09e185`),
`main` = int-51 merged (this handoff's commit). Packs: https://pub-848b5102ea0e4d78999797a799545451.r2.dev/builds/20261104-d51-4d09e185/
(1293 MB; sizes checked on the bucket, CORS checked). The desktop repo was not pushed and is no longer used.
**Steven: please look at the live page** (cloud boxes can't reach github.io; the first deploy after the
godot-build push fails its old check until main's new pages.yml arrives, which this merge brings).

What comes next is in the project doc `claude/session-handoff-2026-11-04-noon-READ-FIRST.md` (Steven's
decisions of Nov 4 noon, the sprint plan and its seven workstreams).

## What is in it
- Round 2: SHOPS (Woolworth, Corn Dog 7, RadioShack, B. Dalton counters), FOOD (22 Blender models: food,
  drinks, books, Cuco's kit), PRIZES (fuller counters both years, Games, Inc.'s counter, WHIRLWIND), CUCOS
  (the football lady, the coupon, the bar, the doubloon that travels to 2026).
- Item reconciliation (int-51 `d9558a0`): the counters sell FOOD's models; SHOPS's 10 food/book stand-ins and
  CUCOS's stand-ins are gone (RadioShack's 10 remain); FOOD's top-shelf margarita is `cu_topshelf`; the
  doubloon is a pocket item of both years; `data/story/shops.json` = SHOPS's four + Cuco's.
- Packs on R2 (`ws/r2-hosting`, design/godot-build-hosting.md "Packs on R2").
- Baked on the Air (Godot 4.7.2, Ultra day): wing1, wing2, wing2_2026, ~6 min each. Static meshes that changed:
  wing 1 w8c_small (CUCOS), wing 2 B. Dalton's counter (SHOPS), wing 2 2026 Games, Inc.'s machines (PRIZES).
  Slices: w1 6, w2 5, w2y26 3. All ten stand-ins recaptured, stamps match.

## Packs (MB, desktop)
| Wing | 1995 | 2026 |
|---|---|---|
| 1 | 85.95 | 42.95 |
| 2 | 83.67 | 66.93 |
| 3 outside | 32.77 | 18.01 |
| 4 | 38.50 | 33.33 |
| 5 | 40.19 | 35.20 |
| 6 | 22.37 | 22.50 |
Shared: items 72.35 (FOOD's models), chars 42.23, chars_w1 5.65, chars_w2 4.23.

## Tests
- Headless: SHOP TEST OK (204), CUCOS TEST OK (89), FLAGS (31), INVENTORY (45), REDEMPTION (32), ECON (52),
  MENU UNIT (64), INT D49: all OK. shop_test now checks SHOPS's four counters and "every B. Dalton book $10";
  cucos_test expects FOOD's "Draft beer".
- Web (swiftshader, one browser at a time): walk MOVED in all 12 packs, 0 errors; doors 1->3 both years, 1->4,
  2->5 (2026) CROSSED; directory jump wing 1 -> Dillard's; REDEMPTION WEB OK; shops: Woolworth and RadioShack
  bought, saved, reloaded OK.
- **Known bugs:** (1) Cuco's bar sells nothing in the browser: E at the bar opens no shop list
  (`production/qa/evidence/d51-cucos-bar-no-shop-BUG.jpg`); the coupon chain itself passes. Details and
  suspects in the READ-FIRST doc §1b. (2) shops_webtest timed out on a screenshot at Corn Dog 7; Corn Dog 7 and
  B. Dalton not checked in a browser (they pass headless).
- Evidence: `d51-w1-spawn-baked.jpg`, `d51-w2-spawn-baked.jpg`, `d51-w2y26-spawn-baked.jpg`.

## Lessons
- A local test server must be its own long-running background task: a `nohup … &` inside a shell call died
  with the call and wasted one full browser test run.
- The Air's shell (Nov 4) reaches GitHub and R2 but can't keep background jobs or run past 3 min per call; a
  sparse clone there kept dying. The changed files went over as 19 MB checksummed parts instead (121 MB).
- Bakes on the Air: write `.autobake`, Steven opens the project in Godot; "ok 1s" in `.autobake_done` is normal
  (the wait after the blocking bake call).
