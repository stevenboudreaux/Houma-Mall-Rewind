# Handoff: EXT-DOCKS (Nov 11, 2026)

Branch `ws/ext-docks` from `int-54` (pushed; not merged, not baked, not published). A scheduled run: Steven was
away, so every call below was made from the footage and is listed. All shots are **unbaked**.

## What shipped
- **Frame study:** `design/exterior/docks-2026-11-11.md` with two labelled contact sheets and two annotated key
  frames (measurements against the 2.1 m doors and a 2.6 m trailer).
- **A. Dillard's:** the wing wall now ends at x -52. Behind its line is a dock court (14 m wide to Dillard's, 18 m
  deep): a two-bay dock under a low brown canopy on the back wall, the trailer backed into bay 1, the roll-off
  beside it, a wood-plank enclosure at the mouth. The old dock, trailer and green box in front of the wall are
  gone. Dillard's west face south of the court has its white base, two doors and the FDC.
- **B. JCPenney:** docks 1-2, the red canopy and the compactor moved from the face with the sign to the side
  (east) face at the NE corner, with the raised dock, steps, the galvanized rail, and a live oak with hollies
  between the apron and the tank.
- **C. The green boxes:** one Blender model, `bl_ex_dumpster` (a steel roll-off container: ribbed sides, lids,
  rust and stains; 700 triangles, one 1024 texture), on a concrete pad at both docks.
- Both years. New code is `tools/exterior/docks.gd`; `exterior.gd` has small hunks marked EXT-DOCKS;
  `wall_fixes.py` one fill; `exterior.json` regenerated. New test `tools/qa/ext_docks_test.gd`.
- `design/godot-exterior.md` "Workstream EXT-DOCKS"; a row in `design/godot-blender-pipeline.md`.

## What to check
| Look at | File |
|---|---|
| Steven's Dillard's viewpoint (flag poles), footage / before / after | `production/qa/evidence/wsDOCK-dillards-steven-view-{1995,2026}-unbaked.jpg` |
| The court at the footage's viewpoint | `wsDOCK-dillards-court-{1995,2026}-unbaked.jpg` |
| Steven's JCPenney viewpoint (the sign face) | `wsDOCK-jcpenney-steven-view-{1995,2026}-unbaked.jpg` |
| The docks on the side face at the footage's viewpoint | `wsDOCK-jcpenney-dock-{1995,2026}-unbaked.jpg` |
| Top views, before / after | `wsDOCK-top-{1995,2026}-unbaked.jpg` |
| The mouth, the roll-off, the tree | `wsDOCK-details-{1995,2026}-unbaked.jpg` |
| The model's turntable | `wsDOCK-bl_ex_dumpster-sheet.jpg` |
| In the web build | `wsDOCK-web-movetest-unbaked.jpg` |

## Every call made
1. **Steven's two screenshots were not available** (not in the repo, the refs pack or the project). The "same
   viewpoints" are rebuilt from the brief's description: at the flag poles looking to the dock (camera -40, 150,
   yaw 30) and facing JCPenney's sign face from the lot (-166, -48, yaw 180). The "frame" column is the nearest
   footage frame, not his screenshot.
2. **The opening is the court's whole mouth,** not a truck-width gap in a continuous wall: the wall ends at x -52
   (the brief's red line, the trailer's right end as it was built) and the 14 m from there to Dillard's is open.
   That is what f026 shows and it fits "an opening around where the red line is"; the brief's "truck-width" was
   the director's reading. One number in `wall_fixes.py` and `docks.gd COURT` if Steven wants it narrower.
3. **Note vs footage:** they agree at both docks (the dock behind the wall line; JCPenney's docks on the side
   face; trees between the dock and the tank). Steven's note overrode the footage once: the containers stay
   **green** in both years (he said keep them); the filmed ones are tan.
4. The service lane (doors 3026-3029) stays open beside the dock (Steven's Nov 4 decision), although in the
   footage the dock's canopy closes the lane's end.
5. JCPenney's docks start right at the NE corner (door 2 nearest the corner, as filmed), so the apron sits just
   south of the tank yard; the tree bed is off the corner between the two.
6. Dillard's west face got the white base to 4.8 m only from the court southward (the part the old dock covered).
7. The dumpster is a dynamic mesh like the 3D signs and ships only its albedo, to keep to one 1024 texture and to
   spare wing 3's pack.
8. No customer walk, curb or fire lane on the dock faces (JCPenney's east face had a fire lane); one stall keep-out
   moved with the dock. No stall or lot marking was otherwise touched.
9. A, B and C were pushed as two build commits (the model; then both docks, which share `docks.gd`), after the
   frame study's own push.

## Guesses
The court's depth (18 m); the enclosure's size and the door in the wing block's wall; the containers' lids; both
docks in the 1990s (no period picture: built as filmed in both years); JCPenney's dock-face parapet left at 9.5 m
(the footage reads about 7.5 m).

## Known gaps
- JCPenney's truck apron is flat; the filmed one is a shallow well below the walk.
- The court and the apron use the lot's concrete, not a darker slab of their own.
- The enclosure's planks are the dark fence wood (filmed: weathered grey). Benches at Dillard's base and the dome
  camera at JCPenney's corner are not built.

## Tests
- Wing 3 builds, both years: BUILD OK.
- `ext_door_test.gd`, both years: PASS. `ext_docks_test.gd`, both years: PASS (the wall cannot be walked through
  except at the opening; court, lane and apron are reachable; the new things block).
- `movetest.py` wing 3, 1990s and 2026: 0 errors at four cameras; the touch walk goes through the opening.
- Packs here (no lightmaps): `w3` +0.22 MB, `w3y26` +0.22 MB. **`w3y26` was 103.8 MB with its lightmap at
  EXT-SIGNS against GitHub's 104.9 MB limit: check it after the bake.**

## For integration
- **Rebuild wing 3 (both years) and rebake `wing3` and `wing3_2026`.** `gen/w3`, `gen/w3y26`, `wing3.tscn` and
  `wing3_2026.tscn` are not committed on this branch.
- Shared files: `tools/exterior/exterior.gd` (hunks marked EXT-DOCKS, none inside an EXT-ENTRANCES region),
  `tools/exterior/wall_fixes.py`, `exterior.json` (regenerate with `python3 tools/make_exterior.py
  ../../../index.html` after merging `wall_fixes.py` rather than hand-merging).
- The cloud box had no lightmaps or stand-in pictures (the `godot-build` fetch in `CLAUDE-CLOUD.md` step 3 fails
  when run from the project folder); nothing here needed them.

## Open for Steven
1. Is the 14 m opening right, or should the wall carry on past a narrower gap?
2. Green containers in both years, or tan in 2026 as filmed?
3. Should JCPenney's truck apron be sunk like the Sears well?
