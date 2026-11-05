# Lynn's Interiors (2026): where everything stands — workstream LYNNS (Nov 4 2026)

Plan drawing: `layout.png` (north/back at the top, the mall at the bottom; 16 px = 1 m), drawn from
the data by `prototypes/godot-mall/project/tools/stores/sears/lynns_layout_png.py`:
- zones: `prototypes/godot-mall/project/data/lynns/zones.json`
- placed furniture: `prototypes/godot-mall/project/data/lynns/placements.json`, instanced by
  `tools/stores/sears/lynns.gd` (called from `store.gd dress_2026()`).

The skeleton is workstream E's (`design/godot-sears.md`): box x −40..30, z −146..−96 (world m, +x east,
+z south), 9 m column grid (x −35.5 … 27.5, z −101 … −137), main aisle x −6..−2 from the mall mouth
(x −16..8) to the side exit, rooms R1–R5, the east customer storefront (z −121..−115), pipe columns in
R3. Nothing here moves a wall.

## Zones

| Zone | Rect(s) (x0, z0, x1, z1) | Contents (inventory.md families) | Why here | Confidence |
|---|---|---|---|---|
| Z1 Entry showcase | −26.5,−110,−6,−96.3 and −2,−110,9.5,−96.3 | SOFA-B `cloud` U and modulars with cocktail ottomans, OCC-B rustic end tables | IMG_4409: the first thing either side of the aisle from the threshold | high |
| Z2 West perimeter | −40,−110,−26.5,−96.3 | CHAIR-A black swivel run, SOFA-A white, STOR bookcase wall + curio, ART leaning, DECO urns | IMG_4410: a perimeter aisle with the panel wall on the left; the west wall is the only one that fits a first turn left from the entry | medium |
| Z3 R2 motion | −40,−128,−26.5,−110 | SOFA-C groups on OCC-A round tables, RUG | IMG_4411 t037–047 (motion groups beyond the columns in a walled room) | medium |
| Z4 Centre-west living | −26.5,−128,−6,−110 | CHAIR-A wingbacks + ottomans, OCC-C consoles with LAMPs, STOR grey-wash hutch, SOFA-B cognac chaise | IMG_4411 t007–035: the aisle west of the main one, columns on the right | medium |
| Z5 R1 recliner gallery | −40,−146,−17.5,−128 | CHAIR-B two facing runs along a cross aisle, lift chairs | IMG_4412 t001–011 + "this was like TVs and appliances" (R1 held the appliances, E's note); the recliner aisle ends at the beige curtain | medium |
| Z6 R4 counter room | −17.5,−146,−8.5,−137 | DIN-B stools in rows, a counter table, BED-B white iron bed by the mint door | IMG_4412 t013–021, right after the separator wall and the mint door | low |
| Z7 R3 mattress gallery | 9.5,−146,30,−128 | MAT sets on the taupe carpet, BED-B iron and upholstered beds, adjustable bases, slatwall alcove (SIGN brand panels), pillow tower | IMG_4412 t023–047; E built the taupe carpet and the pipe columns here | high (E's room), medium (which corner) |
| Z8 Dining hall | −2,−137,9.5,−110 and −17.5,−137,−6,−128 | DIN-A ~20 sets in rows, STOR sideboards and curios on R5's and R3's walls (corbel wall), DECO tiered trays | IMG_4412 t049–083: straight on from the gallery, many columns, the corbel wall with sideboards | medium |
| Z9 East living | 9.5,−128,27,−99.4 | **SOFA-A (phase 1)**, SOFA-B grey chenille / cream leather, the glam group with OCC burl tables, leather group | IMG_4413 t051–117, t127–143: the living groups between the side-exit walk and the east storefront | medium |
| Z10 Bedroom vignettes | 27,−128,30,−99.4 (east wall) and 9.5,−99.4,30,−96.3 (mall wall, east part) | **BED-A (phase 1)**, later the ogee and canopy beds | IMG_4413 t029, t085–091, t119–125: suites against white panel walls under the ledge, the storefront glass beyond (t127–133) | medium (east wall), low (mall wall) |
| Z12 Appliances (pass 2) | 27,−114.6,30,−110.4 | fridge, range, washer, dryer against the east wall, just north of the customer storefront | **Steven's Nov 4 spec** ("appliances near the exterior customer entrance"); the 2026 footage has none ("back here used to be appliances", IMG_4411) — question in the report | spec |
| Z11 Side-exit corner | −8.5,−146,0.5,−137 | FIX sales desk + task chair + monitors, STOR black arched sideboard, cream chest, CHAIR-A toile swivel, RUG | IMG_4413 t001–015, t031, t041 | high |
| Main aisle | −6,−146,−2,−96.3 | kept clear (4 m) | IMG_4409, 4413 t031–037 | high |

**Confidence.** The footage never shows a heading, so each zone is placed by the order of the camera's
walk and what is visible beyond it (the side exit at the aisle's north end and the storefront on the
east face are E's; the rest follows). "high" = the frame shows the zone's position against a fixed
feature; "medium" = the walk order fits only this spot in E's rooms; "low" = a guess that fills a room.
Steven can move a zone by editing `zones.json` / `placements.json` (no code).

## Phase 1 placements (28 pieces)

| Group | Pieces | Where |
|---|---|---|
| glam suite | dresser + mirror, 2 nightstands, bed (headboard on the east wall, foot west), chest | east wall, bay z −110..−101 |
| espresso suite | dresser + mirror, 2 nightstands, bed, chest on R3's south wall | east wall, z −128..−121 (north of the storefront) |
| oak suite | dresser + mirror, 2 nightstands, bed (headboard on the mall wall, foot north), chest | mall wall, bay x 18.5..27.5 |
| sage suite | the same, in grey wash | mall wall, bay x 9.5..18.5 |
| sofa pairs | `sage` + `sage`, `cream` + `cream`, `leather` facing `taupe` (twice), each pair across a rug | Z9, the four bays x 9.5..27, z −128..−110 |

Rugs are flat coloured quads until the RUG family is built. The old box dressing (`store.gd`) still
fills everything else and skips these groups' rects; phase 2 starts replacing it zone by zone.

## Walking room
Every piece is a walk obstacle (its rotated footprint). Gaps kept: ≥ 1.0 m between a group and the next
column, 1.2 m between a bed's foot and the next group, the 4 m main aisle and the storefront doors clear.

## Pass 2 (Nov 4, evening): the floor filled with the pack furniture

Steven's spec of Nov 4: sofas and living vignettes at the mall entrance and along the main aisle, a mattress
wall along a partition, bedroom sets in the partitioned rooms, appliances near the exterior customer entrance,
lamps / plants / rugs as dressing, density as in the walkthrough; placements as data. Models and the
generator-vs-pack decisions: `asset-manifest.md`.

- **Data:** `data/lynns/placements.json`, 66 groups, 407 pieces (28 phase-1 generator pieces + generator sofas
  reused in Z1/Z2/Z4 + 83 pack models). Pass-2 groups carry `"pass": 2` and are written by
  `tools/stores/sears/lynns_fill.py` (templates: living group, sectional group, rect / round dining set); after a
  hand nudge, change that group's `"pass"` to 3 so a re-run keeps it. An item is `[model, x, z, yaw]` or
  `[model, x, z, yaw, y]` for a lamp or plant standing on a table. `"replace_boxes": true` turns off the old box
  dressing in `store.gd` (the R3 slatwall stays).
- **Checks** (`lynns_fill.py`, run every time): every footprint against the columns, the pipe columns, the chase,
  the partitions, 1 m either side of every doorway, the main aisle, the mouth threshold, the storefront doors and
  the side exit, and against every other piece (chairs tucked under tables allowed): 0 problems.
- **Where things went:** Z1 three sectionals + two sofa groups + a front row facing the mall; Z2 bookcases on the
  west wall, a five-chair swivel run, two white sofas, a sofa group; Z3 (R2) two motion groups + a run of motion
  sofas on the west wall; Z4 four living groups and four chair/console vignettes; Z5 (R1) ~40 recliners in a north
  and south run either side of the cross aisle plus a row on the north wall, the beige curtain at the back; Z6 (R4)
  two counter tables with stools, a stool row, the white iron bed; Z7 (R3) **the mattress wall**: nine sets with
  their heads on the slatwall (back wall), an island row of six between the pipe columns, two adjustable bases on
  the west partition, two iron beds and the glam upholstered bed on the south partition, the pillow tower;
  Z8 twelve rectangular and four round dining sets, six sideboards with lamps on R5's and R4's walls; Z9 tables
  and lamps for the phase-1 pairs, the glam group, the grey sectional; Z11 the sales desk with two monitors and a
  task chair, black sideboard, cream chest; Z12 the appliances.
- **Guesses:** the mattress wall is R3's **back** wall (where workstream E built the slatwall), not a
  partition; bedroom suites stay on the east and mall walls (phase 1) rather than in a partitioned room;
  Steven's spec reads differently on both (questions in the report).
