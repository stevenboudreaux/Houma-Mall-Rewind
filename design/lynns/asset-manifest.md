# Lynn's Interiors (2026): asset manifest — workstream LYNNS, pass 2 (Nov 4 2026)

Steven's Nov 4 spec: fill wing4_2026's Lynn's floor with the two CC0 packs he supplied (Quaternius "Ultimate
House Interior Pack" June 2020 as the primary source, Kenney "Furniture Kit 2.0" for gaps), recoloured to the
store's palette, keeping the generator props where they look better side by side. 1995 Sears is out of scope;
the skeleton (walls, columns, rooms) is unchanged. Research: `inventory.md`; floor plan: `layout.md`.

## Which source won, family by family (decided by looking)

Sheets (footage | generator | pack, same light): `production/qa/evidence/lynns-compare-{sofa,bedroom,chairs,mattress,dining,occasional}.jpg`;
every pack conversion: `production/qa/evidence/lynns-pack-sheet-{a,b}.jpg`.

| Family | Winner | Why (what the sheet shows) |
|---|---|---|
| SOFA-A stationary sofas | **generator** (`bl_ly_sofa_*`, 4) | loose seat and back cushions with welts, throw pillows, tapered/turned legs, fabric grain: reads as the 4413 t078–117 sofas. The pack couches are blocks with square pillows. |
| SOFA-B sectionals | **pack** `Couch_L` ×4 colours | no generator mode yet; the L with chaise has the right plan (2.9 × 2.1) and loose back cushions. Generator sectional mode is pass 3. |
| SOFA-C motion sofas / loveseats | **pack** `Couch_Large2` (fabric), `Couch_Large1` (leather) | the chunky track arm and pillow back read like the power sofas in 4411 t037–047; no recline mechanism shown. |
| BED-A suites (bed, nightstand, dresser + mirror, chest) | **generator** (`bl_ly_*`, 4 suites) | Louis-Philippe crowns, raised panels, bun feet, mirrors, dressed bedding vs the pack's mid-century drawers (`Drawer_*`, `NightStand_*`) that match nothing in the footage. |
| BED-B iron beds | **pack** `Bed_King` (frame recoloured black / bronze / white, bedding white + grey, blue runner) | a simple metal bed is what the gallery shows (4412 t027–045); the pack frame is right at low cost. Upholstered and canopy beds: generator (glam bed reused). |
| MAT mattress sets, adjustable base, pillow tower | **script-built** (`gen:` in the converter) | neither pack has a bare mattress on a foundation; boxes in the palette (navy quilt, grey, white; yellow law card). |
| CHAIR-A accent chairs | **pack** `Couch_Small1` (5 colours) | close to the tub/barrel chairs on legs; wingbacks and chair-and-a-half are not in either pack (gap list). |
| CHAIR-B recliners | **pack** Kenney `loungeChairRelax` (footrest out, 6 colours) + Quaternius `Couch_Small2` (closed, 3) | blocky, but the silhouette (high back, padded arms, footrest) reads as a recliner from the aisle; a generator recliner is the upgrade. |
| OTT ottomans | **pack** Kenney `loungeSofaOttoman` | plain upholstered block, right size. |
| DIN-A / DIN-B dining and counter | **pack**: Kenney `table` (rect, 3 finishes), Quaternius `Table_RoundSmall` (pedestal, 3), `Chair_1–4`, `Stool` | the ladder-back, slat-back and cushioned chairs match 4412 t049–083 well; trestle tables and benches are the upgrade. |
| OCC tables, consoles | **pack**: Kenney `tableCoffee`, `tableCoffeeGlass`; Quaternius `Table_RoundSmall2` (round, walnut / burl), `NightStand_1–3` (end tables), `Drawer_5` (console) | fine at a glance; burl round with a cream base matches the glam group (4413 t078). |
| STOR sideboards, chest, bookcase | **pack** `Drawer_1` (3 finishes), `Drawer_4`, `Bookshelf` | mid-century legs are not quite the footage's (carved / arched glass), acceptable as filler along the walls; the bookcases are empty (books: pass 3). |
| LAMP table lamps | **pack** `Light_Floor2–4` (ceramic white, brass, glass bases; linen shades, off) | right size and shape on end tables and sideboards. The floor lamp (`Light_Floor1`) was dropped: its shade is a metal cup. |
| RUG | **pack** `Carpet_1/2` (bordered, 4 colourways) + a script-built round rug (the pack's round carpet triangulates badly) | flat printed rugs in the store's greys, taupes and creams. |
| DECO plants | **pack** `Houseplant_1/4/7/8` | faux plants in white pots by the columns and on sideboards. |
| FIX curtain, sales desk, appliances | **pack**: `Curtains_Double` (beige, R1's back curtain), Kenney `desk`, `computerScreen`, `chairDesk`, `kitchenFridgeLarge`, `kitchenStove`, `washer`, `dryer` | appliances only because Steven's spec asks for them (see the question in `layout.md`). |

## How the packs are converted (`tools/blender/import_quaternius.py`, config `data/lynns/pack_models.json`)

- Headless Blender (`/home/claude/bvenv/bin/python tools/blender/import_quaternius.py [-- ids] [--sheet out.png]`).
- **Scale:** the Quaternius FBX are ~2.5× real size and Kenney's ~0.45×; each model is scaled to the target
  [w, d, h] in the config, per axis (the packs are chunky: a sofa is made lower than a uniform scale gives).
  Spot checks: sofas 2.15–2.36 m long, the L sectional 2.9 × 2.1, iron bed 1.75 × 2.25 (queen; the pack's "King"
  is a bed + runner, scaled to the gallery's queen), mattress 1.53 × 2.03 (queen), dining chair seat ~0.47.
- **Axes:** metres, origin at the floor centre, the front on Blender −Y (Godot +Z): the same as the `bl_ly_*` props.
- **Recolour by material swap:** each source material maps to a swatch of one shared 128 px palette
  (`models/lynns/pack/ly_palette.png` + `ly_palette_orm.png`: roughness and metal per swatch; colours from
  `inventory.md`). Every face is UV'd to its swatch's centre, so a model is **one material, one draw call**, and the
  packs' flat-shaded look is kept. No per-prop textures: the 83 models are 1.8 MB together (the generator props are ~94 MB).
- **Triangles:** 60–1,460 per model (sofas ~1–1.5k, chairs 200–850, lamps ~250, rugs 100–240).
- **Not done (and why):** no baked contact AO on pack models (they are flat-coloured; the wing's probes light them);
  price tags not yet on them.

## Gap list for the next asset pass

Checked against Kenney first (Kenney has it → named; otherwise "Steven to download (CC0)" or our generator).

| Missing | Kenney? | Plan |
|---|---|---|
| bare mattresses / mattress stacks, mattress in a bag | no | **done** script-built (`pk_mat_*`); stacks are the same piece placed at y = 0.56 |
| power recliner, lift chair (proper) | `loungeChairRelax` (used, blocky) | generator recliner mode (planned) or **Steven to download (CC0)** a recliner model |
| wingback + ottoman, chair-and-a-half, round swivel barrel | no | generator (sofa code) or **Steven to download (CC0)** |
| rectangular dining tables + chairs | `table` (used), `chair`, `chairCushion` | done; trestle / farmhouse tables and **benches** (`bench`, `benchCushion` in Kenney) next |
| fridge / range / washer / dryer | yes (used) | done |
| TV consoles | `cabinetTelevision`, `televisionModern` | available; not placed (no TVs in the 2026 footage) |
| curio cabinet (lit glass), hutch / china, étagère | `bookcaseClosedDoors` (hutch stand-in) | generator case mode or **Steven to download (CC0)** |
| books for the bookcases, throw pillows | `books`, `pillow`, `pillowBlue(Long)` | place in pass 3 |
| mirrors (round wall, irregular, arched floor) | no (Quaternius `Bathroom_Mirror1/2` are round wall mirrors) | try the Quaternius mirrors; arched floor mirror: generator |
| wall art / leaning canvases | no | PIL-painted canvases (plan.md) |
| price tags, FINAL MARKDOWN / FALL SAVINGS cards, slatwall brand panels | no | `lib/labels.py` (plan.md "SIGN") |
| urns, vases, tiered trays, faux cotton stems | no | generator lathe or **Steven to download (CC0)** a decor pack |
| floor lamps (wood tripod, brass arc) | `lampRoundFloor`, `lampSquareFloor` (modern) | generator lathe |
| drapery / fabric sample racks | no | generator |
| canopy bed, upholstered panel beds | no | generator (`_lynns_bedroom.py`) |

## Models in the repository

Only the models placed are kept (`pk_love_taupe` and `pk_lamp_floor` were made and dropped). The table is
written by `tools/stores/sears/lynns_fill.py` from `models/lynns/pack/manifest.json` and `data/lynns/placements.json`.

<!-- AUTO: tools/stores/sears/lynns_fill.py -->
| Model (`models/lynns/pack/`) | Family | Source file | Licence | Size W x D x H (m) | Tris | glb KB | Placed (zone x count) |
|---|---|---|---|---|---|---|---|
| `pk_accent_black.glb` | CHAIR-A accent / barrel chair | Quaternius `FBX/Couch_Small1.fbx` | CC0 1.0 | 0.82 x 0.82 x 0.80 | 852 | 22 | Z1 x1, Z2 x3 |
| `pk_accent_cognac.glb` | CHAIR-A accent / barrel chair | Quaternius `FBX/Couch_Small1.fbx` | CC0 1.0 | 0.82 x 0.82 x 0.80 | 852 | 22 | Z4 x2 |
| `pk_accent_cream.glb` | CHAIR-A accent / barrel chair | Quaternius `FBX/Couch_Small1.fbx` | CC0 1.0 | 0.82 x 0.82 x 0.80 | 852 | 22 | Z1 x1, Z11 x1, Z4 x2, Z9 x1 |
| `pk_accent_green.glb` | CHAIR-A accent / barrel chair | Quaternius `FBX/Couch_Small1.fbx` | CC0 1.0 | 0.82 x 0.82 x 0.80 | 852 | 22 | Z2 x2, Z9 x2 |
| `pk_accent_navy.glb` | CHAIR-A accent / barrel chair | Quaternius `FBX/Couch_Small1.fbx` | CC0 1.0 | 0.82 x 0.82 x 0.80 | 852 | 22 | Z2 x2 |
| `pk_bediron_black.glb` | BED-B iron bed (queen) | Quaternius `FBX/Bed_King.fbx` | CC0 1.0 | 1.75 x 2.25 x 1.15 | 676 | 26 | Z7 x1 |
| `pk_bediron_bronze.glb` | BED-B iron bed (queen) | Quaternius `FBX/Bed_King.fbx` | CC0 1.0 | 1.75 x 2.25 x 1.15 | 676 | 26 | Z7 x1 |
| `pk_bediron_white.glb` | BED-B iron bed (queen) | Quaternius `FBX/Bed_King.fbx` | CC0 1.0 | 1.75 x 2.25 x 1.15 | 676 | 26 | Z6 x1 |
| `pk_bookcase_walnut.glb` | STOR bookcase | Quaternius `FBX/Bookshelf.fbx` | CC0 1.0 | 1.80 x 0.40 x 2.10 | 120 | 11 | Z2 x3 |
| `pk_chair_cush_grey.glb` | DIN-A cushioned chair | Quaternius `FBX/Chair_3.fbx` | CC0 1.0 | 0.46 x 0.52 x 0.98 | 428 | 26 | Z8 x16 |
| `pk_chair_cush_white.glb` | DIN-A cushioned chair | Quaternius `FBX/Chair_2.fbx` | CC0 1.0 | 0.46 x 0.52 x 0.98 | 352 | 21 | Z8 x28 |
| `pk_chair_ladder_black.glb` | DIN-A ladder-back chair | Quaternius `FBX/Chair_1.fbx` | CC0 1.0 | 0.46 x 0.52 x 0.98 | 216 | 17 | Z8 x28 |
| `pk_chair_ladder_espresso.glb` | DIN-A slat-back chair | Quaternius `FBX/Chair_4.fbx` | CC0 1.0 | 0.46 x 0.52 x 0.98 | 264 | 18 | Z8 x16 |
| `pk_chest_cream.glb` | STOR chest | Quaternius `FBX/Drawer_4.fbx` | CC0 1.0 | 1.00 x 0.48 x 1.32 | 464 | 19 | Z11 x1, Z2 x1 |
| `pk_cocktail_burl.glb` | OCC-A round burl cocktail table | Quaternius `FBX/Table_RoundSmall2.fbx` | CC0 1.0 | 1.00 x 1.00 x 0.46 | 744 | 32 | Z9 x3 |
| `pk_cocktail_glass.glb` | OCC-A metal + glass cocktail table | Kenney `tableCoffeeGlass.glb` | CC0 1.0 | 1.20 x 0.70 x 0.45 | 140 | 10 | Z3 x1 |
| `pk_cocktail_oak.glb` | OCC-A cocktail table | Kenney `tableCoffee.glb` | CC0 1.0 | 1.30 x 0.75 x 0.45 | 124 | 9 | Z4 x1, Z9 x2 |
| `pk_cocktail_round.glb` | OCC-A round cocktail table | Quaternius `FBX/Table_RoundSmall2.fbx` | CC0 1.0 | 1.00 x 1.00 x 0.46 | 744 | 32 | Z2 x1, Z3 x1 |
| `pk_cocktail_walnut.glb` | OCC-A cocktail table | Kenney `tableCoffee.glb` | CC0 1.0 | 1.30 x 0.75 x 0.45 | 124 | 9 | Z4 x1 |
| `pk_console_oak.glb` | OCC-C console | Quaternius `FBX/Drawer_5.fbx` | CC0 1.0 | 1.60 x 0.40 x 0.78 | 352 | 21 | Z4 x1 |
| `pk_curtain_beige.glb` | FIX curtain | Quaternius `FBX/Curtains_Double.fbx` | CC0 1.0 | 3.40 x 0.30 x 2.80 | 320 | 16 | Z5 x1 |
| `pk_desk_white.glb` | FIX sales desk | Kenney `desk.glb` | CC0 1.0 | 1.50 x 0.70 x 0.76 | 198 | 14 | Z11 x1 |
| `pk_dryer_white.glb` | APPL dryer | Kenney `dryer.glb` | CC0 1.0 | 0.69 x 0.75 x 0.98 | 262 | 16 | Z12 x1 |
| `pk_end_black.glb` | OCC-B end table | Quaternius `FBX/NightStand_1.fbx` | CC0 1.0 | 0.55 x 0.45 x 0.60 | 172 | 12 | Z3 x3, Z9 x2 |
| `pk_end_oak.glb` | OCC-B end table | Quaternius `FBX/NightStand_3.fbx` | CC0 1.0 | 0.55 x 0.45 x 0.60 | 272 | 17 | Z1 x2, Z4 x2, Z9 x4 |
| `pk_end_white.glb` | OCC-B end table | Quaternius `FBX/NightStand_2.fbx` | CC0 1.0 | 0.55 x 0.45 x 0.62 | 184 | 13 | Z2 x2, Z4 x2, Z9 x4 |
| `pk_fridge_steel.glb` | APPL refrigerator | Kenney `kitchenFridgeLarge.glb` | CC0 1.0 | 0.91 x 0.75 x 1.78 | 436 | 26 | Z12 x1 |
| `pk_lamp_brass.glb` | LAMP table lamp, brass | Quaternius `FBX/Light_Floor2.fbx` | CC0 1.0 | 0.29 x 0.30 x 0.70 | 276 | 12 | Z2 x2, Z4 x2, Z8 x1, Z9 x4 |
| `pk_lamp_glass.glb` | LAMP table lamp, glass | Quaternius `FBX/Light_Floor4.fbx` | CC0 1.0 | 0.31 x 0.31 x 0.68 | 244 | 12 | Z11 x1, Z3 x2, Z8 x1, Z9 x2 |
| `pk_lamp_gourd.glb` | LAMP table lamp, white ceramic | Quaternius `FBX/Light_Floor3.fbx` | CC0 1.0 | 0.32 x 0.34 x 0.72 | 244 | 12 | Z4 x4, Z8 x4, Z9 x4 |
| `pk_love_brown.glb` | SOFA-C loveseat | Quaternius `FBX/Couch_Large1.fbx` | CC0 1.0 | 1.65 x 1.00 x 1.00 | 1460 | 36 | Z3 x1 |
| `pk_love_cognac.glb` | SOFA-C loveseat | Quaternius `FBX/Couch_Large1.fbx` | CC0 1.0 | 1.65 x 1.00 x 1.00 | 1460 | 36 | Z3 x1 |
| `pk_love_grey.glb` | SOFA-C loveseat | Quaternius `FBX/Couch_Large2.fbx` | CC0 1.0 | 1.65 x 1.00 x 1.00 | 1332 | 45 | Z3 x1 |
| `pk_mat_adjustable.glb` | MAT adjustable base | built in the script (`adjustable`) | project | 1.53 x 2.04 x 0.96 | 120 | 11 | Z7 x5 |
| `pk_mat_grey.glb` | MAT mattress on foundation (queen) | built in the script (`mattress`) | project | 1.53 x 2.04 x 0.56 | 60 | 7 | Z7 x3 |
| `pk_mat_navy.glb` | MAT mattress on foundation (queen) | built in the script (`mattress`) | project | 1.53 x 2.04 x 0.56 | 60 | 7 | Z7 x7 |
| `pk_mat_white.glb` | MAT mattress on foundation (queen) | built in the script (`mattress`) | project | 1.53 x 2.04 x 0.56 | 60 | 7 | Z7 x2 |
| `pk_monitor.glb` | FIX sales desk monitor | Kenney `computerScreen.glb` | CC0 1.0 | 0.55 x 0.15 x 0.42 | 72 | 7 | Z11 x2 |
| `pk_motion_brown.glb` | SOFA-C motion sofa | Quaternius `FBX/Couch_Large1.fbx` | CC0 1.0 | 2.15 x 1.00 x 1.00 | 1460 | 36 | Z3 x1 |
| `pk_motion_cognac.glb` | SOFA-C motion sofa | Quaternius `FBX/Couch_Large1.fbx` | CC0 1.0 | 2.15 x 1.00 x 1.00 | 1460 | 36 | Z3 x1 |
| `pk_motion_grey.glb` | SOFA-C motion sofa | Quaternius `FBX/Couch_Large2.fbx` | CC0 1.0 | 2.15 x 1.00 x 1.00 | 1332 | 45 | Z3 x1 |
| `pk_motion_taupe.glb` | SOFA-C motion sofa | Quaternius `FBX/Couch_Large2.fbx` | CC0 1.0 | 2.15 x 1.00 x 1.00 | 1332 | 45 | Z3 x1 |
| `pk_ott_cream.glb` | OTT cocktail ottoman | Kenney `loungeSofaOttoman.glb` | CC0 1.0 | 1.20 x 0.90 x 0.42 | 84 | 8 | Z1 x1, Z4 x1 |
| `pk_ott_grey.glb` | OTT cocktail ottoman | Kenney `loungeSofaOttoman.glb` | CC0 1.0 | 1.20 x 0.90 x 0.42 | 84 | 8 | Z1 x1, Z9 x1 |
| `pk_ott_tweed.glb` | OTT cocktail ottoman | Kenney `loungeSofaOttoman.glb` | CC0 1.0 | 1.20 x 0.90 x 0.42 | 84 | 8 | Z1 x1, Z4 x2 |
| `pk_pillowtower.glb` | FIX pillow tower | built in the script (`pillowtower`) | project | 0.90 x 0.50 x 1.60 | 276 | 22 | Z7 x1 |
| `pk_plant_monstera.glb` | DECO faux plant | Quaternius `FBX/Houseplant_7.fbx` | CC0 1.0 | 1.26 x 1.31 x 0.95 | 449 | 19 | Z2 x1 |
| `pk_plant_small.glb` | DECO faux plant | Quaternius `FBX/Houseplant_1.fbx` | CC0 1.0 | 0.59 x 0.53 x 0.55 | 245 | 11 | Z8 x3 |
| `pk_plant_snake.glb` | DECO faux plant | Quaternius `FBX/Houseplant_4.fbx` | CC0 1.0 | 0.33 x 0.33 x 0.90 | 316 | 16 | Z1 x1 |
| `pk_plant_tall.glb` | DECO faux plant | Quaternius `FBX/Houseplant_8.fbx` | CC0 1.0 | 0.50 x 0.50 x 1.50 | 310 | 23 | Z1 x1 |
| `pk_range_steel.glb` | APPL range | Kenney `kitchenStove.glb` | CC0 1.0 | 0.76 x 0.70 x 0.95 | 830 | 48 | Z12 x1 |
| `pk_recl_beige.glb` | CHAIR-B recliner (footrest out) | Kenney `loungeChairRelax.glb` | CC0 1.0 | 0.95 x 1.25 x 1.05 | 188 | 14 | not placed yet |
| `pk_recl_black.glb` | CHAIR-B recliner (footrest out) | Kenney `loungeChairRelax.glb` | CC0 1.0 | 0.95 x 1.25 x 1.05 | 188 | 14 | Z5 x2 |
| `pk_recl_brown.glb` | CHAIR-B recliner (footrest out) | Kenney `loungeChairRelax.glb` | CC0 1.0 | 0.95 x 1.25 x 1.05 | 188 | 14 | Z5 x2 |
| `pk_recl_cognac.glb` | CHAIR-B recliner (footrest out) | Kenney `loungeChairRelax.glb` | CC0 1.0 | 0.95 x 1.25 x 1.05 | 188 | 14 | Z5 x2 |
| `pk_recl_grey.glb` | CHAIR-B recliner (footrest out) | Kenney `loungeChairRelax.glb` | CC0 1.0 | 0.95 x 1.25 x 1.05 | 188 | 14 | Z5 x2 |
| `pk_recl_quilt.glb` | CHAIR-B recliner (footrest out) | Kenney `loungeChairRelax.glb` | CC0 1.0 | 0.95 x 1.25 x 1.05 | 188 | 14 | Z5 x2 |
| `pk_reclc_beige.glb` | CHAIR-B recliner (closed) | Quaternius `FBX/Couch_Small2.fbx` | CC0 1.0 | 0.95 x 1.00 x 1.02 | 468 | 18 | Z5 x10 |
| `pk_reclc_brown.glb` | CHAIR-B recliner (closed) | Quaternius `FBX/Couch_Small2.fbx` | CC0 1.0 | 0.95 x 1.00 x 1.02 | 468 | 18 | Z5 x10 |
| `pk_reclc_grey.glb` | CHAIR-B recliner (closed) | Quaternius `FBX/Couch_Small2.fbx` | CC0 1.0 | 0.95 x 1.00 x 1.02 | 468 | 18 | Z5 x8 |
| `pk_rug_cream.glb` | RUG | Quaternius `FBX/Carpet_2.fbx` | CC0 1.0 | 2.70 x 3.00 x 0.01 | 98 | 6 | Z1 x1, Z9 x1 |
| `pk_rug_round.glb` | RUG | built in the script (`roundrug`) | project | 2.40 x 2.40 x 0.01 | 240 | 15 | Z1 x1, Z2 x1, Z4 x1 |
| `pk_rug_sisal.glb` | RUG | Quaternius `FBX/Carpet_2.fbx` | CC0 1.0 | 2.70 x 3.00 x 0.01 | 98 | 6 | Z4 x1 |
| `pk_rug_taupe.glb` | RUG | Quaternius `FBX/Carpet_1.fbx` | CC0 1.0 | 2.40 x 3.00 x 0.01 | 108 | 7 | Z11 x1, Z3 x1, Z4 x1 |
| `pk_rug_vintage.glb` | RUG | Quaternius `FBX/Carpet_1.fbx` | CC0 1.0 | 2.40 x 3.00 x 0.01 | 108 | 7 | Z1 x1, Z3 x1, Z4 x1, Z9 x1 |
| `pk_sect_bluegrey.glb` | SOFA-B sectional (L with chaise) | Quaternius `FBX/Couch_L.fbx` | CC0 1.0 | 2.90 x 2.10 x 0.88 | 1428 | 36 | Z1 x1 |
| `pk_sect_cream.glb` | SOFA-B sectional (L with chaise) | Quaternius `FBX/Couch_L.fbx` | CC0 1.0 | 2.90 x 2.10 x 0.88 | 1428 | 36 | Z1 x1 |
| `pk_sect_creamleather.glb` | SOFA-B sectional (L with chaise) | Quaternius `FBX/Couch_L.fbx` | CC0 1.0 | 2.90 x 2.10 x 0.88 | 1428 | 36 | Z4 x1 |
| `pk_sect_grey.glb` | SOFA-B sectional (L with chaise) | Quaternius `FBX/Couch_L.fbx` | CC0 1.0 | 2.90 x 2.10 x 0.88 | 1428 | 36 | Z1 x1, Z9 x1 |
| `pk_sideboard_black.glb` | STOR sideboard | Quaternius `FBX/Drawer_1.fbx` | CC0 1.0 | 1.70 x 0.45 x 0.85 | 404 | 16 | Z11 x1, Z8 x2 |
| `pk_sideboard_greywash.glb` | STOR sideboard | Quaternius `FBX/Drawer_1.fbx` | CC0 1.0 | 1.70 x 0.45 x 0.85 | 404 | 16 | Z8 x2 |
| `pk_sideboard_white.glb` | STOR sideboard | Quaternius `FBX/Drawer_1.fbx` | CC0 1.0 | 1.70 x 0.45 x 0.85 | 404 | 16 | Z8 x2 |
| `pk_stool_black.glb` | DIN-B counter stool | Quaternius `FBX/Stool.fbx` | CC0 1.0 | 0.44 x 0.46 x 0.68 | 500 | 22 | Z6 x6 |
| `pk_stool_oak.glb` | DIN-B counter stool | Quaternius `FBX/Stool.fbx` | CC0 1.0 | 0.44 x 0.46 x 0.68 | 500 | 22 | Z6 x6 |
| `pk_taskchair.glb` | FIX task chair | Kenney `chairDesk.glb` | CC0 1.0 | 0.60 x 0.60 x 0.95 | 588 | 36 | Z11 x1 |
| `pk_tcounter_oak.glb` | DIN-B counter table | Kenney `table.glb` | CC0 1.0 | 1.50 x 0.90 x 0.92 | 120 | 9 | Z6 x2 |
| `pk_trect_black.glb` | DIN-A rectangular dining table | Kenney `table.glb` | CC0 1.0 | 1.90 x 0.95 x 0.76 | 120 | 9 | Z8 x4 |
| `pk_trect_greyoak.glb` | DIN-A rectangular dining table | Kenney `table.glb` | CC0 1.0 | 1.90 x 0.95 x 0.76 | 120 | 9 | Z8 x4 |
| `pk_trect_oak.glb` | DIN-A rectangular dining table | Kenney `table.glb` | CC0 1.0 | 1.90 x 0.95 x 0.76 | 120 | 9 | Z8 x4 |
| `pk_tround_espresso.glb` | DIN-A round pedestal table | Quaternius `FBX/Table_RoundSmall.fbx` | CC0 1.0 | 1.20 x 1.20 x 0.76 | 592 | 24 | Z8 x2 |
| `pk_tround_oak.glb` | DIN-A round pedestal table | Quaternius `FBX/Table_RoundSmall.fbx` | CC0 1.0 | 1.20 x 1.20 x 0.76 | 592 | 24 | Z8 x1 |
| `pk_tround_white.glb` | DIN-A round pedestal table | Quaternius `FBX/Table_RoundSmall.fbx` | CC0 1.0 | 1.20 x 1.20 x 0.76 | 592 | 24 | Z8 x1 |
| `pk_washer_white.glb` | APPL washer | Kenney `washer.glb` | CC0 1.0 | 0.69 x 0.75 x 0.98 | 720 | 42 | Z12 x1 |

Generator models (own, `models/lynns/bl_ly_*`, baked 3-map textures) placed in the store:

- `bed_espresso`: Z10 x1
- `bed_glam`: Z10 x1, Z7 x1
- `bed_oak`: Z10 x1
- `bed_sage`: Z10 x1
- `chest_espresso`: Z10 x1
- `chest_glam`: Z10 x1
- `chest_oak`: Z10 x1
- `chest_sage`: Z10 x1
- `dresser_espresso`: Z10 x1
- `dresser_glam`: Z10 x1
- `dresser_oak`: Z10 x1
- `dresser_sage`: Z10 x1
- `night_espresso`: Z10 x2
- `night_glam`: Z10 x2
- `night_oak`: Z10 x2
- `night_sage`: Z10 x2
- `sofa_cream`: Z2 x1, Z9 x2
- `sofa_leather`: Z4 x1, Z9 x2
- `sofa_sage`: Z4 x1, Z9 x3
- `sofa_taupe`: Z4 x1, Z9 x2
<!-- /AUTO -->
