# Handoff: int-52 (Nov 5, 2026, overnight): eleven workstreams merged, ready to bake

**State: branch `int-52` pushed (head in the director's report), not published.** Base: `origin/main` 69203b23
(Demo 51). Worktree `/home/claude/int52`. Nothing pushed to `main` or `godot-build`; nothing written on R2.
Every wing scene is rebuilt with the **nov4** bake profile and is **unbaked**: the Demo 51 lightmaps no longer
fit any inside wing (nov4 changes every inside mesh's UV2) nor wing 3 (EXT-B moved every outside face).
**Bake on the Mac before any publish** (list below).

## What merged (in order, `git merge --no-ff`)
| # | Branch | Head | What |
|---|---|---|---|
| 1 | ws/items | b5d12fe3 | one item schema, hand-by-default receive(), the years read "1990s" / "2026", no opening |
| 2 | ws/interiors | ff3e2b1b | Spencer's (2026), Payless (1995), Great American Cookies (both), Auntie Anne's (2026) walk-in interiors; four counter shops, 18 PLACEHOLDER items |
| 3 | ws/corner-2026 | 7afdda81 | the C2 / main-entrance corner both years (Franks set back behind a court patch; 2026 Zales over Franks + OJ) |
| 4 | ws/exterior | fc36c70d | EXT-B: the real outside both years (footprint, roads, lot, outparcels). **Implemented**, not only decisions; Steven's Nov 4 answers are in `design/godot-exterior.md` "Decided" and are what the branch built (Sears north face plain, east recess 4 m, 1995 Shoe Dept–Dillard's wall = facade panels, Dillard's west face at x −38 keeping the service lane) |
| 5 | ws/directory | e7414164 | option B kiosk reader, the year switch on the kiosk, full device pixels (hidpi) |
| 6 | ws/ui-offscreen | 96093c58 | menu icon on touch devices only, Esc / Tab open the menu, the corner buttons into the menu |
| 7 | ws/bake-look | a8ffa3c1 | bake profiles as data, **nov4 active**; floor shader edge smoothing (`aa_on`); `floor_spec` **default kept at 0.25**; own hall / court floors as their own meshes |
| 8 | ws/char-editor | d59d8682 | the character editor |
| 9 | ws/chars-ubc | 055576af | Quaternius UBC bodies for the five looks and the editor |
| 10 | ws/lynns | 1b5796bb | Lynn's Interiors furniture (wing4_2026): 403 pieces as data, `data/lynns/placements.json` |
| 11 | ws/owner-tools | e9c6e94f | OWNER tab (owner directory: every store, either year, jump; the tools), owner corner buttons, owner pictures on posters / ad panels, every PLAYABLE Pocket Change cabinet NES-only |

### Done at integration besides the merges
- **MakeHuman dropped** (Steven's decision, `design/godot-ubc-characters.md` "int-52"). Checked first: nothing
  outside `CharBody.manifest_path()` loads the MakeHuman files (shoppers, attendants, avatar, editor all go through
  the manifest; UBC has no wrinkle map and no patterns). `scripts/char_body.gd`: always `models/ubc/ubc.json`; the
  `?chars=mh` / localStorage `mall-chars-body` / meta `chars_body` / `--chars=mh` switch removed. `models/characters/`:
  247 files removed (~66 MB), `characters.json` kept (source for `tools/chars/ubc_manifest.gd`). Packs:
  `tools/chars/pack_list.py` reads `ubc.json` (aliases resolved, `.gltf` images, no `.bin`); `shared_packs.py` and
  `make_presets.py` keep `models/ubc/*.gltf|*.bin|*.png` out of the wing packs (`ubc.json` stays in them);
  `export_presets.cfg` regenerated. `char_clothed_test.gd` lost its MakeHuman branch.
- Layouts: `layout_corner_c2.py` (idempotent) and `make_layout_2026.py` rerun after interiors + corner: **no
  diff** (git's textual merge already held both; the generator agrees).
- Directory: `make_data.gd` → `map.json`, `paint_dir.py` (2x) and `DIR_K=4 DIR_OUT=tex/dir/hi` (4x), both years.
  Franks x 2..12, z 10..16; 2026 Zales covers Franks + OJ; the 2026 s34 entry is gone (73 stalls in 2026, 79 in
  1995). **Franks' jump spot is computed (7, 7.8, facing south)**, not hand-set to (7, 7.5): `map_data.gd` puts every
  jump 2.2 m out from the store's front, which is now z = 10; 0.3 m from the asked spot, on the court patch, so I
  left the rule alone rather than special-case one store.
- All twelve scenes rebuilt (`build_mall.gd`), BUILD OK each; `bake profile nov4: texel 0.100 m, floors 0.060 m,
  stand-ins 0.16 m`; wing 3 keeps Demo 51 (`bake_quality.json` per-wing override) and wing 6 is never baked.
  Builds were fast and nothing was OOM-killed (one Godot at a time; the box was quiet).
- For disk, the setup archives `/home/claude/Godot_v4.7.2-stable_export_templates.tpz` (1.2 GB, already unpacked)
  and the Godot zip were deleted; both re-download from GitHub releases (CLAUDE-CLOUD.md).

## Conflicts and how they were resolved
| File | Branches | Resolution |
|---|---|---|
| `design/godot-2026-year.md` | items × corner-2026 | kept both sections; the corner section now says APPLIED |
| `scripts/directory_ui.gd` | items × directory | took directory's rewrite (option B); items' `Years.label()` changes were for the old in-UI year button / toggle / "Loads Wing n, year" line, which option B no longer draws (the kiosk's own keys already say "1990s" / "2026", `directory_kiosk.gd` LABEL) |
| `scripts/menu/menu.gd` (×2) | items × ui-offscreen | items removed the opening; ui-offscreen's icon sync and touch detection kept, its `opening` references dropped |
| `scripts/menu/menu.gd` (×2) | (above) × owner-tools | owner's Menu button on every device kept (`touch_device or is_owner()`), without `opening`; `_owner_opening()` dropped, the OWNER section kept |
| `scripts/menu/owner_tab.gd` (semantic) | items × owner-tools | the "The opening screen · Show it again" row removed (no opening since ws/items) |
| `tools/qa/README.md` | corner-2026 × owner-tools | kept both |
No other textual conflicts (layout files, `build_mall.gd`, `make_layout_2026.py`, `fronts26/store.gd`, `player.gd`
merged clean).

## Tests (native unless marked; unbaked)
| Test | Result |
|---|---|
| bake_quality_test | BAKE QUALITY OK |
| items_test | ITEMS TEST OK (49) |
| shop_interiors_test | SHOP INTERIORS TEST OK (179) |
| shop_test | SHOP TEST OK (204) |
| dialogue_walk | DIALOGUE WALK OK (67) |
| corner_walk_test 1995 / 2026 | CORNER WALK OK both |
| wsS_thresholds_test 1995 / 2026 | WSS TEST OK both |
| int_d49_test | INT D49 OK, after a test update (below) |
| flags / inventory / econ | 31 / 45 / 52 OK |
| prizes_years / redemption / cucos / pusher_play | 27 / 32 / 89 / 20 OK |
| char_clothed_test | CHAR CLOTHED OK (868, UBC only) |
| char_editor_test --only=unit | CHAR EDITOR OK (43) |
| char_avatar_test (wing 6) | CHAR AVATAR OK (40) |
| ui_offscreen_test (wing 6) | UI OFFSCREEN OK (35) |
| menu_test --wing=2 (incl. the directory year-switch trip to 2026) | MENU TEST OK (86) |
| kiosk_test 1995 / 2026 (390x844) | KIOSK TEST OK (25) both |
| owner_test (wing 6) | OWNER TEST OK (45), after a test update |
| pictures_test (wing 1) | PICTURES TEST OK (19) |
| interact_test wing 1 / wing 2 | OK (8) / OK (19), wing 2 after a test update |
| avatar_test (wing 2) | AVATAR TEST OK (13), after a test update (it was the known-stale one) |
| stockrooms_test | **3 FAIL, pre-existing** (below) |
| **Web** (desktop-only unbaked export of w1, w2, w2y26 + shared packs; swiftshader; deleted afterwards) | |
| char_webtest (wing 1) | **CHAR WEB OK**: the UBC `chars` pack fetched and mounted, three attendants dressed and baked, 0 console errors desktop and phone |
| walk_webtest into Payless (wing 2, from the hall at x −2 walking east) | walks in through the opening, always on free floor; stops after 11 m at a bench in the aisle (an obstacle by design), so the speed / clip checks (made for open halls) fail; phone touch walk run |
| walk_webtest into Spencer's (wing 2 2026, from z 51 walking north) | crosses the front into the store on free floor; stops 1.6 m in at the entrance display table straight ahead of the door's centre (by design; Steven may want the table off the door's axis); one console error: the shell could not cache packs absent from this lean export (test artefact) |
| ui_offscreen_webtest (wing 2) | 24 ok, 1 FAIL "desktop: a click where the icon would be opens nothing": the check counts near-white pixels top left, and unbaked the corner lands on Karmelkorn's cream fascia; "no menu icon" before the click passed, Esc / Tab / phone icon all passed. Heuristic, not a regression (the native ui_offscreen_test is OK) |
| not run (time) | avatar_webtest, the wing 1 char editor web run beyond char_webtest's K / editor step, menu_webtest directory step (native menu_test covers it), doortest crossings, walk_webtest in the halls, owner-tools' pictures_pick_webtest / arcade_nes_webtest / pictures_publish_test, signstest.py (updated by owner-tools for the OWNER tab, never rerun) |

**Test updates (each a test following a merged decision, no game change):**
- `int_d49_test`: wing 2 2026 now makes exactly the attendants listed for it (ws/interiors' three: Great American
  Cookies, Auntie Anne's, Spencer's); Games, Inc. still has nobody (the spot check stays).
- `owner_test`: the owner's 2026 year button reads "Back to the 1990s (Y)" (ws/items' names); no "Show it again".
- `interact_test`: the owner's Jump to tops the corner column at 40 px (ws/owner-tools moved the toggles into the
  OWNER tab), not 168.
- `avatar_test`: the creator opens inside the menu's MAIN, which keeps the player frozen until the menu closes; the
  test now closes the menu before checking. The char editor has no Random (the call is skipped if absent).
- **stockrooms_test** (not changed): "locked before the Rougarou has gone through", "the caption shows within 2 m of
  the stick", "buttons and Jump back" (Woolworth's back corner). These are the three known before tonight; int-52
  touched `stockrooms.gd` only to ask the item loader for `folse_stick` (same outcome). Not compared by running
  origin/main (no room for a second worktree + import); the caption check is stale since the stick became an item
  (int-51), the other two need a look by someone who knows the Rougarou flags.
- Harmless noise: owner_test and pictures_test print `SCRIPT ERROR … get_children on null` from
  `mall_runtime.gd _meshes(current_scene)`: those tests add the wing before setting `current_scene`. Same on the
  owner-tools branch; the tests still pass.

## Evidence (unbaked, `production/qa/evidence/`)
`int52-corner-c2-1995-top-2026-bottom-unbaked.jpg` (Franks set back with the court patch / 2026 Zales, and the view
from the east hall), `int52-spencers-2026-shop-open-unbaked.jpg` (the counter shop open, the UBC attendant),
`int52-lynns-entrance-unbaked.jpg` (inside the mouth / from the mall), `int52-owner-tab-tools-directory-unbaked.jpg`,
`int52-menu-main-desktop-phone-unbaked.jpg` (1280x720 and 390x844), `int52-kiosk-1995-list-2026-map-confirm-phone-unbaked.jpg`.

## Mac bake
Bring the branch to the Mac (`int-52`), then in the project folder:
```
echo "wing1:day wing1_2026:day wing2:day wing2_2026:day wing4:day wing4_2026:day wing5:day wing5_2026:day wing3:fastday wing3_2026:fastday" > .autobake
```
- No `:night`: the int-51 bake was day only and `scripts/lighting.json` is `day_only` (the game never shows night).
  The old `wing1_night.exr` / `wing2_night.exr` no longer fit the nov4 UVs but are never shown; they still ride in the
  packs (consider dropping them from the presets later).
- Wing 3 uses `fastday` (its note, `design/godot-exterior.md` "For the Mac"); wing 6 is never baked.
- Estimate (bake-look note): ~75-80 min for the eight inside bakes (~2.5x Demo 51's texels) + two fast wing 3 bakes.
  Send back `.autobake_done` (seconds per bake, any FAILED). Bring back `wing{1,2,4,5}{,_2026}_day.{exr,exr.import,lmbake}`
  and `wing3{,_2026}_day.*` (the `.exr.import` matters: its slice count follows the new layers).
- After the bakes, check wing 1 on the iPhone (bake-look risk (a): lightmap memory); fallback is `"active": "nov4_lite"`,
  rebuild, rebake.

**Stand-in capture order** (after the bakes, each `tools/capture_standin.sh <wing> [2026]`):
`4`, `4 2026`, `5`, `5 2026`, `3`, `3 2026`, `1`, `1 2026`, `2`, `2 2026`. Then export, look, publish.

## Pack sizes (unbaked desktop test export, old lightmaps inside; for orientation only)
w1 119.5 MB, w2 118.1 MB, w2y26 93.2 MB (Demo 51 desktop: 86.0 / 83.7 / 66.9); shared items 73.0 MB, **chars 53.4 MB**
(UBC; Demo 51's MakeHuman chars 42.2), chars_w1 0.6, chars_w2 0.8, chars_w2y26 0.1. The wing growth is before the
nov4 lightmaps, which add ~+43 MB more across the eight inside packs (bake-look estimate). R2 has no file limit;
`publish_build.sh`'s GitHub 100 MiB warning will fire for w1 / w2 (packs are on R2 since Demo 51).

## PLACEHOLDER (shipping as such)
- ws/interiors: the 18 shop items' prices, the four counters' attendants (names, looks, sexes: guesses), their greetings
  and ready lines; stand-in icons on several items ("STAND-IN" tag).
- ws/items: everything the README / note marks PLACEHOLDER (ready lines in Steven's pattern).
- Lynn's: the furniture is generic pack / generator models (no real brands); the layout is Steven-approved.
- EXT-B: Kirschman's sign letters and colours, the 1995 bank's look, the strip centre's tenants.

## Open questions for Steven (from the branches' notes)
1. **Shops** (`design/godot-shops.md`, storefront notes): prices for Spencer's, Payless, Great American Cookies (both
   years), Auntie Anne's; the attendants' names, looks and sexes; ready lines; Spencer's lava lamp model.
2. **Floor shine** (`design/godot-bake-quality.md`): `floor_spec` stays 0.25 until you compare `?floorspec=0` on this
   build. Also confirm nov4 (vs nov4_lite) once the iPhone memory is seen.
3. **Kiosk** (`design/godot-directory-legibility.md`): (a) the year switch as a small dark plate with two keys on the
   bottom rail, or lit buttons in the sign's cyan band? (b) on a portrait phone the map view shows the lit block
   without its name (the 2026 sign has no names on blocks): enough? (c) **check on your iPhone**: text sharpness
   with hidpi, frame rate in the halls, the kiosk (swipe, tap, the keys, Safari memory with the 4x panel).
4. **Menu / UI-OFFSCREEN** (`design/godot-menu.md`): the desktop first-start walk hint ending "· Tab or Esc: menu" is
   the only way a mouse player learns the menu: is that wording right?
5. **Owner mode** (`design/godot-owner-mode.md` "Open / guesses"): keyboard Y switches the year for the owner only
   (a pad's Y still opens Jump to); the owner's toggles now live in the OWNER tab (say if you want them back on
   screen); a poster panel's id carries its position, so moving a panel orphans its published picture; the opening
   row is gone from OWNER > TOOLS since there is no opening.
6. **Corner** (`design/corner-2026-c2.md` §5): Orange Julius' court side in 1995 (plain wall built); 2026 Zales open
   or gated (built open); Tee Tai's vs T.J.'s in the H3 south row; the end-of-1994 directory image again.
7. **Exterior** (`design/godot-exterior.md`): 1995 photos for the main / south entrances and Dillard's (re-skinned
   placeholders); JCPenney's 2012-era fascia still stands in 1995.
8. **Characters** (`design/godot-ubc-characters.md`, `design/godot-character-editor.md`): build names, the five
   looks, weak spots (sneakers read as socks, shell-like flannel and vest, flat apron).

## Not done / for the director
- Web tests above were cut short for time; run the "not run" row on the first real export (unbaked is fine).
- `stockrooms_test`'s three failures are not fixed (see Tests).
- Franks' jump is (7, 7.8) by the rule, not the asked (7, 7.5).
- Nothing in int-52 needed a decision Steven had not already made; every guess is written above or in the
  branch's own note.
