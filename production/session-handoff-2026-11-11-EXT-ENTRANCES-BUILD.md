# Session handoff: EXT-ENTRANCES-BUILD (Nov 11 2026)

Branch **`ws/ext-entrances-build`** from `int-54` (cc2191b), pushed. Not merged, not baked, not published, nothing
uploaded. Unattended run (Steven away; the director's brief was the approval).

## Read this first

**The main entrance is built to different massing than the blockout the director approved.** Measured off 4406
f002-f003 (camera solved from the frame's vanishing points), the real tower is a slim one standing **in the facade's
plane**: two piers 3.9 m apart, a roof slab ~8.4 x 8.1 m at ~9.2 m, a tan bay and a banded pylon either side, 12 m
pylon to pylon. The Nov 9 blockout had piers 14.4 m apart, 8 m out on the lot, under a 20 m slab. The porch is the
recess **behind** the piers (the 8 m to the doors at x 36 that the map always gave this door), and wing 3 now builds
it and lets the player walk into it. Look at `production/qa/evidence/wsEXTE-main-2026.jpg` row 1 before anything
else: frame | blockout | now from the frame's own viewpoint.

If the director or Steven would rather have the approved blockout, it is int-54's `exterior.gd`; nothing else
depends on this branch.

## What shipped

- **Main entrance s39, both years** (`tools/exterior/exterior.gd` `ent_main`, `_main_doors`, `_tmobile_porch`):
  piers with caps, necks, banded bases (2026 tile with joints; 1990s peach / cream stucco), sconces (2026), the
  white roof slab, the shoulders (set-back tan panel bay, flank pylon with its flared cap, two-tier cornice running
  back over the roof), the black lantern (clear glass, tan 3 x 3 centre panel, small lights, fins), the canopy with
  **"SOUTHLAND MALL" as channel-letter geometry** standing on its fascia, the navy fan banner (2026), the porch
  (pavers / concrete, tan walls with a white base, low soffit with cans), the two-storey void (panel grids, wash
  bars, lay-in ceiling), and real doors on the porch's back wall: 2026 a four-panel sliding package under an arched
  transom with sidelights, 1990s three bronze swing pairs between sidelights. T-Mobile's porch door (2026, visual).
- **East entrance s43, both years** (`ent_side`, `_storefront`, `_leaf`): bowed wedge eyebrow, fascia pilasters and
  two-step cornice, beige soffit with cans and the access panel, capped brick pylons, gooseneck lamps, the 8-module
  storefront with real leaves (10 cm bottom rails, bow pulls, push bars), sidelights on a slim sill, two transom
  rows, a threshold; a flush saw-cut apron and **no curb across the recess**.
- **`exterior.json`** (via `tools/exterior/wall_fixes.py` PORCH / DOOR_OUT and `tools/make_exterior.py`): `porch`
  [36, -6, 44, 6] (new key), its 24 walk tiles, s39's `out` (45.5, 0) -> (38, 0). Nothing else differs.
- **Letters**: `tools/exterior/make_entrance_letters.py`, `ent_letters_2026.json`, `ent_letters_1990s.json`.
- **Docs**: `design/exterior/entrances-2026-11-09.md` (status, the director's answers, "The main entrance,
  measured", "The east entrance, as built"), `design/godot-exterior.md` (new section EXT-ENTRANCES-BUILD).
- **Evidence** (`production/qa/evidence/`, unbaked): `wsEXTE-main-2026.jpg`, `wsEXTE-main-1990s.jpg`,
  `wsEXTE-side-2026.jpg`, `wsEXTE-side-1990s.jpg` (frame | before | after, same cameras), `wsEXTE-web-porch-1990s.jpg`
  (the web build in the porch with the door prompt; stale lightmap).

## Every call I made

1. **Rebuilt the main entrance's massing from a measurement instead of finishing the approved blockout.** Reason:
   the brief asks for correct proportions against the frames and quotes Steven ("get the heightened area perfect");
   the blockout was ~3x too wide and 8 m too far out. Method, numbers and checks are in the entrances note.
2. **Opened the porch in wing 3 and moved s39's outside spot into it** (x 38). The door record still works both
   ways (tests below); wing 1 is untouched. This is the one change outside "geometry": `exterior.json`,
   `wall_fixes.py`, `make_exterior.py`, and a cut in `exterior.gd build()`'s footprint obstacle.
3. **Porch depth scaled to the map's 8 m** (filmed ~3-4 m), the same ruling the director gave for s43; the void
   keeps its filmed size at the front.
4. **Side bays open at porch level** (my reading of 4492 f050 / 4426 f001; 4426 f007 could argue for walls).
5. **Heights**: slab underside 9.15 m (blockout 9.9), pier caps 7.8, cornice 7.1-7.8, pylon caps 6.6, lantern to
   7.5, soffit 3.4 (blockout 3.6), bands 0.55. All hang on a camera height of 1.7 m.
6. **Letters**: ~3.2 m long and 0.5 m tall is what the frame gives, so they are a condensed heavy sans (Archivo
   Black squeezed; the real face is not identified). 1990s: Libre Caslon squeezed to 3.3 m, cream. Both lit at night
   (a guess for the 1990s).
7. **The arched transom is kept under the 3.4 m porch soffit** (filmed taller).
8. **T-Mobile's porch door built** (filmed, 2026 only, visual only); the 1990s wall is plain.
9. **1990s storefront**: three swing pairs, no sliders (guess).
10. **A dim room behind the glass at both entrances** (before, the far lot showed through the building).
11. **Lot**: two guarded lines in `lot()`'s walks loop: s43 gets no walk strip, curb or fire-lane ladder (the
    director's answer 3); **s39 gets no curb either** (my call: 4492 f051-f054 show flush pavement from the doors
    to the lane). Random draws untouched; the rest of the lot verified identical mesh by mesh.
12. **Door wall at x 35.9**, 10 cm behind wing 1's edge, so the door-picture cameras at x 36 are in front of it.
13. **The gold fan (2026) and the Cucos neon (1990s, scale 1.25 -> 1.1) stand on the eyebrow's top**, half way out, where
    the fan is in f038 (on the wall behind, the eyebrow's edge hid them from the lot).
14. s43 questions 4 and 5 (not answered by the director) left as the note proposed: 1990s pylons in red-brown
    brick, bronze storefront, no kick plates.
15. Evidence row 1 uses the solved viewpoint, where one of the lot's poles stands in front of the tower; row 2 is
    2 m to the side.

## Tests (cloud, unbaked)

- **Build**: `build_mall.gd --wing=3` and `--wing=3 --year=2026`: BUILD OK, no script errors, no unknown material.
- **`tools/qa/ext_door_test.gd`**, `--door=s39` and `--door=s43`, 1990s and `--year=2026` (4 runs): **PASS**, 0 FAIL.
  s39's outside spot (38, 0) and the spot 2 m further out are on the grid and clear; the player there finds the
  door; wing 1 -> "Go outside" -> wing 3 at the spot -> "Enter the mall" -> wing 1.
- **`tools/qa/doortest.py`** (web export `.scratch/builds/exte`, wings 1-3, both years, lightmaps in the packs):
  main entrance and east entrance, 1990s and 2026: **CROSSED** all four, out and back. Game errors: 0. The 2026
  main-entrance run logs 0 errors; the other three log one line each, "could not keep the next files for later:
  QuotaExceededError", which is the page's pre-cache hitting the headless browser's storage quota with the 150 MB
  1990s packs (lightmaps included this time), not the game.
- **`tools/qa/movetest.py`** wing 3, 1990s and 2026: cameras at the drive, in the porch, at the doors, at the east
  entrance, and night: **0 errors** each; the touch walk from the porch (`WALK_CAM=38,0,-90,0`) goes out between the
  piers to x 44.2: **MOVED**, both years.
- **The lot is unchanged**: int-54's generated meshes against this build's, vertex by vertex: `ex_props`, `ex_far`,
  `ex_signs`, `ex_ground` identical; `ex_lot` only the curb boxes at the two entrances; `ex_walks` and the paint
  only at the two entrances.
- The web shots carry the old wing-3 lightmap (smeared over the new geometry) until the rebake.
- After the web tests one decorative change went in (the fan / neon moved onto the eyebrow): both years rebuilt
  (BUILD OK), `ext_door_test --door=s43` PASS again, the side evidence re-shot; the web export was not repeated.

## Needs a rebake

**`wing3` and `wing3_2026`** (`wing3:day wing3_2026:day`), after the director rebuilds them: `gen/w3`, `gen/w3y26`,
`wing3.tscn`, `wing3_2026.tscn` are **not committed**. Then `tools/capture_standin.sh 3` and `3 2026` (wing 1's door
pictures at s39 are now taken from inside the porch). Wings 1, 2, 4, 5, 6: no change.

## Known gaps

- The 1990s main entrance skin is a guess; so are the side bays being open and the void's exact plan.
- The lot's pole in front of the tower at the frame's viewpoint, the stop sign and the crosswalk are the lot's and
  were not touched. The facade either side is as it was (whiter and yellower than the footage).
- The arch transom is lower than filmed; the sliding doors do not move.
- Wing 1 still draws its 12 m vestibule stand-in past s39's doors.
- `w3y26` pack 104.15 MB here (lightmaps included): 0.7 MB under GitHub's 100 MiB (only matters for `R2=0`).
- `east_entrance()` in `exterior.gd` (the pre-Nov 9 s43) is dead code, left alone.

## Open for Steven

1. Does the slim tower, flush in the facade, match what you remember? Is walking into the porch right?
2. Between each pier and its pylon: open at ground level (built) or a wall?
3. A 1990s picture of this entrance, if one turns up, settles the skin and the letters.

## For whoever merges

Shared files touched: `tools/exterior/exterior.gd` (the EXT-ENTRANCES region, the `ent_*` block in `fill_mat`, two
lines in `lot()`'s walks loop, the porch cut in `build()`, one preload), `tools/exterior/exterior_2026.gd`
(`main_entrance` now only T-Mobile and Shoe Dept.), `tools/exterior/wall_fixes.py`, `tools/make_exterior.py`,
`exterior.json`. New Python need for the letters only: `shapely`.
