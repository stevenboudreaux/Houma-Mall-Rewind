# The old Sears box (Lynn's Interiors in 2026): the skeleton, walkable — workstream E, Nov 1 2026

**Asked for (Steven, Nov 1):** "build the skeleton exactly — walls, partitions, columns, soffit
beams; they never moved; departments later by me." Both years share the skeleton. 1995 = Sears with
the floor left clean for Steven's departments; 2026 = Lynn's Interiors with a light furniture
dressing like the footage.

Code: `prototypes/godot-mall/project/tools/stores/sears/` (`store.gd`, `paint.py` → `tex/sr/`,
materials `sr_*`). Called from `build_mall.gd`'s `anchor_front()` for the store names SEARS and
LYNN'S INTERIORS, after the mall-side fascia and sign; it replaces the old "fake interior" behind the
24 m mouth with the whole box. Wing 1 (both years).

## Sources
| What | Source |
|---|---|
| Columns, ceiling, troffers, threshold, the long main aisle | `refs/new/sears/IMG_4409_t000_001–012` (the opening), notes_A "Old Sears interior" |
| Perimeter panel wall with corbelled ledge | `IMG_4410_t000_001`, `IMG_4411_t000_011` (f006) |
| Separator walls, recliner run, mint door, chase column, mattress gallery, pipe columns, window band | `IMG_4412_t000_*` (f002, f006, f011, f013–014), narration "these walls … have always been in the same orientation" |
| Navy back corner, louvred stockroom door, curtain to back of house | `IMG_4411_t000_023–024` (f012), `IMG_4412_t000_004` |
| Side exit (glass doors, transom, roll shutter, mouldings, fire pull) and the view out | `IMG_4413_t000_001–025` |
| Soffit-beam grid, columns with standards and receptacles, alcoves | `IMG_4413_t000_037–106` (f019, f027) |
| Exterior customer storefront | `IMG_4413_t000_127–133` (notes f033–034); outside: notes_A IMG_4406 f031–035 (Lynn's script sign with black awning on the east face) |
| Axis: the main aisle in line with H2 and Dillard's | `IMG_4413_t000_037` (f009–010) |
| Depth | Morguard site plan `refs/era_1995/layout_screenshot_2026-09-19.jpg` |

## What I chose for the depth: 50 m (the map says 38 m)
- The map rect s1 is x 128–163, y 33–52 = 70 × 38 m (world x −40..30, z −134..−96).
- The footage: from the threshold (IMG_4409 t000_001) about six column lines recede down the main
  aisle to the lit side-exit doors, on a ~9 m grid: 5–6 bays, 45–55 m.
- The site plan: scaled by Dillard's (153,672 SF over 3 levels ≈ 4,760 m² footprint), the plan reads
  ~0.89 m/px; H2 (C1 to C2) comes out ~82 m on the plan against 76 m in the game, so that scale fits
  the game's halls. Lynn's box is ~56 px deep → ~50 m (and ~123 m wide; the game keeps 70 m because
  the H1a/H1b halls fix the width).
- **Built: 70 × 50 m, z −146..−96.** The walk grid opens map rows y 27–51 (six rows deeper than the
  map rect). 76,335 SF on the plan vs ~37,400 SF built: the game's anchors are compressed like the
  rest of the map; only the depth was corrected.
- **For workstream F (outside):** wing 3's Sears shell still ends at z −134 (from the map). It
  should run to z −146, and its north loading dock moves with it. The four new exterior doors
  (below) have no geometry on the outside yet.

## The skeleton (both years)
World metres; +x east, +z south. Front (mall) wall z = −96 (inner face −96.3), back wall z = −146,
west x = −40, east x = 30.

| Element | As built | From |
|---|---|---|
| Lay-in ceiling | 2×2 white, 3.7 m | 3.6–3.8 m (IMG_4409) |
| Troffers | 2×4 deep-cell parabolic, long side N–S, 3 m grid, kept off the beams | IMG_4409, IMG_4411 |
| Columns | square white 0.7 m, grid x = −35.5, −26.5, −17.5, −8.5, 0.5, 9.5, 18.5, 27.5; z = −101, −110, −119, −128, −137; slotted standard strip + receptacle on one face | 0.65–0.75 m, ~9 m grid; the aisle (x −4) sits between the −8.5 and 0.5 lines |
| Soffit beams | 1.2 m wide × 0.5 m deep, white, on every column line (E–W at z −110…−137, N–S from z −110 back); none over the front bay | IMG_4413 f019; IMG_4409 f001 shows a flat ceiling at the entrance |
| Panel walls (perimeter and separators) | 1.2 m panels with joints, reveal at 2.4 m, ledge at 3.15 m projecting 0.3 m on triangular corbels every 1.2 m, plain above to the ceiling | IMG_4410/4411/4412 |
| Separator partitions | full height, 0.16 m, both faces panelled; on the column lines (table below), doorway heads at 2.7 m | IMG_4412; orientation per Steven, positions a guess |
| Chase column | 1.4 m square at (−17.5, −119), panelled to 2.4 m with a moulding | IMG_4412 f006 |
| Pipe columns | 0.26 m round, white, six in R3 (x 14, 19.5, 25; z −133, −140) instead of square ones | IMG_4412 "a different structural bay" |
| Navy back corner | R1's north and west walls navy to the ledge (NW corner) | IMG_4411 f012 |
| Mint door | R4's paired mint/turquoise glazed doors, standing open | IMG_4412 f002 |
| Back of house | R5, closed: beige curtain over a 3 m opening and a white louvred door, EXIT sign | IMG_4411 f012, IMG_4412 f004 |
| Side exit | north wall at the end of the main aisle (x −5.05..−2.95): cream wall with picture-frame mouldings (rails 1.0 and 3.2 m), clear-anodized pair of glass doors + transom (3.4 m), galvanized roll-shutter coil box inside, fire pull, EXIT sign; the lot outside as a card | IMG_4413 t000_001–025 |
| Customer storefront | east wall z −121..−115: aluminium curtain wall 6 × 3 m, 4 bays, glass doors in the middle, the outer two bays' lower panes backed with white board, EXIT sign; no lobby height | IMG_4413 t000_127–133 |
| R3 window band | east wall of R3: tall frosted windows 1.6 m wide, 0.9–3.0 m | IMG_4412 "a band of tall bright windows" |
| R3 stepped soffit | two 0.7 m rings, undersides 3.2 and 3.45 m | IMG_4412 f011 |
| Single level | no escalator, stair or void | notes_A: none seen |

**Which wall is which (a guess where the footage cannot say):** the side exit is at the north end of
the main aisle (IMG_4409 f001 shows the lit doors straight down the aisle; IMG_4413 starts there and
turns to look straight back down H2). The customer storefront is on the east face, where the Lynn's
script sign and the FedEx box are filmed from outside. The navy corner, "TVs and appliances" and the
separator rooms are placed at the back (north); which side (NW vs NE) is not determinable from the
footage — I put the navy/appliance room NW and the mattress gallery NE (the window band suits the
east wall).

## The rooms, for Steven's 1995 departments
Partitions are on the column lines. Sizes are inside dimensions to the wall lines.

| Room | Where (x, z) | Size | Doors | 2026 use (as filmed) |
|---|---|---|---|---|
| R1 northwest | −40..−17.5, −146..−128 | 22.5 × 18 m (405 m²) | 7 m opening south (x −31..−24), 5 m east (z −136..−131) | appliances, TV wall, navy corner |
| R2 west | −40..−26.5, −128..−110 | 13.5 × 18 m (243 m²) | 6 m opening east (z −122..−116) | recliners along its east side |
| R3 northeast | 9.5..30, −146..−128 | 20.5 × 18 m (369 m²) | 6 m west (z −137..−131), 8 m south (x 13..21) | mattress gallery, taupe carpet, slatwall |
| R4 mint-door room | −17.5..−8.5, −146..−137 | 9 × 9 m (81 m²) | the mint double door onto the main aisle | — |
| R5 back of house | 0.5..9.5, −146..−137 | 9 × 9 m (81 m²) | curtain + louvred door; not walkable | stock |
| Open floor, front | −40..30, −110..−96 | 70 × 13.7 m | the mall mouth (x −16..8) | sofa groups |
| Open floor, centre west | −26.5..−8.5, −128..−110 | 18 × 18 m | — | sofa groups |
| Open floor, east | 0.5..30, −128..−110 (and back to −137 west of R3) | ~29.5 × 18 m | the customer storefront on the east wall | sofas, dining sets |
| Main aisle | x −6..−2, the whole depth | 4 × 50 m | mall mouth → side exit | — |

1995: every room and the open floor are empty (no fixtures) and carpeted; the aisles stay vinyl.

## Floors
- **2026:** polished light-grey concrete with mastic ghosts and scuffs (`tex/sr/concrete.png`, 4 m
  repeat); the old tile bed strip at the threshold; R3 on taupe carpet; one alcove of pale marbled
  vinyl (−36..−31, −108..−102).
- **1995 (a guess):** almond 12" vinyl composition tile in the aisles and a dusty blue-grey
  commercial carpet on the rooms and four department pads (`vct95.png`, `carpet95.png`). No photo of
  the 1995 Sears floor exists in the pack; replace when one turns up.

## 2026 dressing (light, generic)
Sofa and sectional groups with ottomans and rugs on the open floor, dining sets east of the aisle
toward the back, eight beds in R3 with a white slatwall, a row of ten recliners along R2's east side,
eight stainless fridges and a TV wall in R1. Dynamic meshes (`dyn_sr_dress`, no lightmap).

**Being replaced by workstream LYNNS (Nov 4 2026):** the furniture research, zones and build plan are in
`design/lynns/` (`inventory.md`, `layout.md` + `layout.png`, `plan.md`). Blender models
(`models/lynns/bl_ly_*`) are placed from `data/lynns/placements.json` by `tools/stores/sears/lynns.gd`,
called first in `dress_2026()`; the boxes above skip the rects it claims. Phase 1: four sofas (SOFA-A) in
the east living area and four bedroom suites (BED-A) on the east and mall walls.
**Pass 2 (Nov 4 evening):** the whole floor is furnished (403 pieces: CC0 Quaternius / Kenney pack models
recoloured onto one palette, `models/lynns/pack/`, plus the generator props; `design/lynns/asset-manifest.md`);
`placements.json` sets `replace_boxes`, so `dress_2026()` now keeps only the R3 slatwall from the boxes above.

## Exits ("Go outside")
`tools/make_exterior.py` adds two Sears doors to `exterior.json` (`s1x` side exit, out (−4, −149);
`s1e` customer storefront, out (32.5, −118)), so standing at them offers "Go outside · the Sears side
exit / customer entrance" ("Lynn's" in 2026), and outside the spots lead back in. Wing 3 has the
east face but no door geometry at these spots and its box is 12 m short: **workstream F**.

## Budget (unbaked, measured on this branch)
| | Lightmap texels (static meshes) | Web pack |
|---|---|---|
| Wing 1 1995 | 4.45 → 4.76 Mpx (+0.37 Mpx `sr_*`, minus the old fake interior) | 83.7 → 84.5 MB |
| Wing 1 2026 | 1.60 → 1.91 Mpx | 20.7 → 22.4 MB |
Ceilings unwrap at 2× the hall texel, floors and walls at 1.25×; meshes are cut in 18 m chunks.
Lights: one spot per 9 m bay (48) + two daylight fills.

## Guesses (to confirm)
- Depth 50 m (above); the exact separator openings; which back corner is navy.
- The 1995 floor finishes.
- The north-wall section either side of the side exit is cream with mouldings (filmed); the rest of
  the back wall is panelled like the perimeter.
- No higher west bulkhead (IMG_4409 mentions one at the west perimeter; not built).

Evidence: `production/qa/evidence/wsE-sears-*.jpg` (unbaked).
