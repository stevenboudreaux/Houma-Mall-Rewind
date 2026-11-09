# Handoff: int-53 integrated, tested, waiting for the Air bake (Nov 8–9, 2026, director session)

**State: `int-53` pushed, not merged to main, nothing published.** Live is still Demo 52. Demo 53 ships after the
bakes below and a re-export.

## What is in int-53 (nine branches, merged in this order)
| Branch | Job | What |
|---|---|---|
| ws/packs | PACKS | Demo 52's missing content: 81 meshes dropped at export because wing scenes committed after the Nov 5 Mac bake carried UIDs that resolve only on the Mac. `tools/fix_stale_uids.gd` runs in `export_web.sh`; `tools/qa/packcontents.py` refuses a pack missing references. Stores: Champs 3D letters, Babbage's, 579 clothes, Sports Avenue, Sears/Lynn's doors, Concepts smooth. |
| ws/char-strip (contains ws/talk) | CHAR-STRIP + TALK | Editor and both avatar systems deleted (−56 MB source, −53 MB download); one loader `Cast.body(id)`, one save key `mall-player-2`, Character row (4 placeholders), counting test. TALK: shared talk camera, two-light rig on render layer 20, look-at. |
| ws/food3d | FOOD3D | 3D cookies + cookie cakes (pan cake 2026 only), GAC 1990s finish **B** (dark oak and brass), Corn Dog 7 case + cheese on a stick (display only), Auntie Anne's mark + open nugget cups, trash cans with lids. |
| ws/lot | LOT | Lot is jointed concrete (as filmed), no black tar grid; mipmaps on all outside textures (the "rainbow sheen"); procedural sabals/oaks/shrubs (trees **A**); landscaped planters; bank pad shrunk to 7,758 SF; facade smears (hidden faces) fixed; Ground Pat'i across Bayou Gardens opposite Dillard's. |
| ws/ext-layout | EXT-LAYOUT | Cinema-wing exit at the end of its ~20 m channel with a real soffit and the 3-loop wave rack; cinema west/north walls as filmed; Sears dock with sunk truck well; **Sears north entrance s1n** into a new vestibule in wing 4; Unitech at the plan's footprint, unsigned. |
| ws/smallfix | SMALLFIX | Dillard's escalators moved to the Bayou Gardens end as a crisscross pair; in-store directory to the south vestibule; the doubled 1990s "SOUTHLAND MALL" sign built once. |
| ws/char-sources | CHAR-SOURCES | Research + Rocketbox converter; `design/godot-characters-sources.md`. |
| ws/ext-layout-notes | — | Steven's annotated site plan `design/exterior/site-plan-annotated-2026-11-08.png`. |
| ws/char-build | CHAR-BUILD | Rocketbox cast pipeline (`tools/blender/cast/`), five people in `cast/`. **RadioShack and the Cuco's owner approved and wired**; GAC, Auntie Anne's, Spencer's built but not wired (flagged; Demo 54). `CREDITS.md` (Rocketbox MIT). |

## Integration decisions
- `export_presets.cfg`: CHAR-STRIP's side (cast/*, the kept crowd skins) + PACKS's `tex/items/*` include.
- Wing `.tscn` conflicts (LOT, EXT-LAYOUT, SMALLFIX): taken theirs, then **all 12 scenes rebuilt** from the merged code (`b2c4241a`). No `gen/` reference carries a UID.
- `scripts/cast.gd` add/add: **both kept**. CHAR-STRIP's roster layer stays `Cast` (menu, player, attendants, save). CHAR-BUILD's `.glb` loader is now `scripts/cast_glb.gd`, class `CastGlb` (LODs, morphs, eye bones); `Cast.body()` delegates to it for entries with `"glb"`. BUILD's QA tools retargeted to `CastGlb`.
- `scripts/npc_look.gd`: CHAR-BUILD's (TALK's + eye bones/blink shapes when a body has them).
- `data/cast.json`: + `radioshack_1995`, `cucos_owner_1995` (glb; attendants only, not in the player row). `data/story/attendants.json` radioshack and `data/story/cucos/cucos.json` bartender: `"look": "cast"`.
- `data/story/shops.json`: sells `gac_choc_chip_cookie` and `aa_pretzel_nuggets` instead of the stand-ins; `shop_interiors_test.gd` updated.

## Tests on int-53 (cloud box, unbaked export `.scratch/builds/int53`)
- Native OK: SHOP, SHOP INTERIORS, TALK RIG, CUCOS, ITEMS, INVENTORY, INT D49, OWNER (xvfb), MENU UNIT, INTERACT, AVATAR, CAST (177), **CAST COUNT OK (48; ≤1 player skeleton in 320 frames; xvfb)**, FLAGS, REDEMPTION, ECON, UI OFFSCREEN (xvfb).
- MENU (xvfb, wing 2): 76 checks pass, 0 fail, then the process is OOM-killed by this box's cgroup (~3.2 GB) at the 2026 time-travel load, twice at the same point. CHAR-STRIP reported the full suite green on its box. Rerun on the Air or a bigger box before publish if there is time.
- Export: 24 packs, `packcontents: 12 wing + 1 shared packs, every reference shipped`. Pack sizes (desktop = mobile, incl. index files as printed by export_web.sh): w1 150.2 / w1y26 107.5, w2 154.2 / 138.8, outside 115.6 / 102.5, sears 98.6 / 152.0, dillards 99.4 / 94.6, cinema 80.3 / 80.4 MB. `w5.mobile.pck` 99.4 MB (fine on R2).
- Web (swiftshader): every wing pack loads with 0 errors both years; walk MOVED in 10/10 (wings 1–5 × 2 years, each from its own spawn: `WALK_CAM`); doortest main entrance CROSSED 1995 and 2026 (2026 logs one benign QuotaExceededError from pre-caching).
- Not run here: shops/cucos web tests (passed on ws/char-strip with the new loader), stockrooms (3 known Woolworth fails), pictures/arcade.

## Bakes needed (Steven's Air, Godot 4.7.2, project = int-53 head)
```
echo "wing2:day wing2_2026:day wing3:fastday wing3_2026:fastday wing4:day wing4_2026:day wing5:day wing5_2026:day" > .autobake
```
Then open the project in Godot; it bakes and quits (~6–8 min a wing; 8 jobs ≈ 1 hour). Wing 1 (both years) and wing 6 need no bake.
Why: wing 2 (GAC oak finish, Auntie Anne's warmer), wing 3 (every outside mesh changed), wing 4 (north vestibule, R1 walls), wing 5 (escalators).
After the bake, in the cloud (next director session): bring the EXRs **and their `.exr.import`** back, `godot --headless --import`, `capture_standin.sh 3`, `3 2026`, `4`, `4 2026`, `5`, `5 2026`, then recapture 1 and 2 (wing 2's picture through the Dillard's opening shows the old escalator spot; wing 1's door atlas gets s1n's row), export, web tests, `publish_build.sh`, merge `int-53` → `main`.

## Open for Steven
- Facade-smear check after the wing 3 bake (LOT diagnosed from the old lightmap): Dillard's, JCPenney west entrance and south parapet, Lynn's.
- CHAR-BUILD's three remaining people (GAC, Auntie Anne's, Spencer's) when it reports; the playable cast (3–4 lines).
- Unitech's 1990s sign (historian). Cuco's owner's name and lines (story).
- Demo 52 cleanup still pending: `tmp/publish` on GitHub, `rclone.conf` and `_to_delete_d52` on the Air.

## Lessons
- Native suites that take screenshots or `await RenderingServer.frame_post_draw` (owner, menu, ui_offscreen, cast_count) need `xvfb-run … godot --rendering-driver opengl3`; the headless dummy renderer never fires the signal.
- `movetest.py`'s walk starts at `WALK_CAM` (default wing 1's 0,14); set it per wing from `gen/w<n>/wing.json` `spawn`, or the walk reports DID NOT MOVE for any other wing.
- Two heavy Godot processes on this box starve each other and the menu test OOMs at ~3.2 GB RSS; run the long ones alone.
- The ten-lightmap reimport took ~50 min; the 24-pack export ~9 min.
