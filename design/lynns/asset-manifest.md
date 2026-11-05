# Lynn's Interiors (2026): asset manifest — workstream LYNNS, pass 2 (Nov 4 2026)

Steven's Nov 4 spec: fill wing4_2026's Lynn's floor with the two CC0 packs he supplied (Quaternius "Ultimate
House Interior Pack" June 2020 as the primary source, Kenney "Furniture Kit 2.0" for gaps), recoloured to the
store's palette, keeping the generator props where they look better side by side. 1995 Sears is out of scope;
the skeleton (walls, columns, rooms) is unchanged. Research: `inventory.md`; floor plan: `layout.md`.

## Which source won, family by family (decided by looking)

Sheets (footage | generator | pack, same light): `production/qa/evidence/lynns-compare-{sofa,bedroom,chairs,mattress,dining,occasional}.jpg`;
every pack conversion: `production/qa/evidence/lynns-pack-sheet-{a,b}.jpg` (rendered before three fixes: the round rug is now script-built, `pk_plant_tall` is the leafy tree, the navy mattress has a navy top).

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
  `inventory.md`). Every face is UV'd to its swatch's centre, so a model is **one material, one draw call**, all sharing one imported texture (`.gltf` + `.bin`, the palette beside them), and the
  packs' flat-shaded look is kept. No per-prop textures: the 83 models are 2.0 MB together (the generator props are ~94 MB).
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
| Model (`models/lynns/pack/`) | Family | Source file | Licence | Size W x D x H (m) | Tris | KB | Placed (zone x count) |
|---|---|---|---|---|---|---|---|
| `pk_accent_black.gltf` | CHAIR-A accent / barrel chair | Quaternius `FBX/Couch_Small1.fbx` | CC0 1.0 | 0.82 x 0.82 x 0.80 | 852 | 21 | Z1 x1, Z2 x3, Z4 x1 |
| `pk_accent_cognac.gltf` | CHAIR-A accent / barrel chair | Quaternius `FBX/Couch_Small1.fbx` | CC0 1.0 | 0.82 x 0.82 x 0.80 | 852 | 21 | Z1 x2, Z4 x4 |
| `pk_accent_cream.gltf` | CHAIR-A accent / barrel chair | Quaternius `FBX/Couch_Small1.fbx` | CC0 1.0 | 0.82 x 0.82 x 0.80 | 852 | 21 | Z1 x3, Z11 x1, Z4 x3, Z9 x1 |
| `pk_accent_green.gltf` | CHAIR-A accent / barrel chair | Quaternius `FBX/Couch_Small1.fbx` | CC0 1.0 | 0.82 x 0.82 x 0.80 | 852 | 21 | Z1 x1, Z2 x2, Z4 x2, Z9 x2 |
| `pk_accent_navy.gltf` | CHAIR-A accent / barrel chair | Quaternius `FBX/Couch_Small1.fbx` | CC0 1.0 | 0.82 x 0.82 x 0.80 | 852 | 21 | Z1 x2, Z2 x2 |
| `pk_bediron_black.gltf` | BED-B iron bed (queen) | Quaternius `FBX/Bed_King.fbx` | CC0 1.0 | 1.75 x 2.25 x 1.15 | 676 | 26 | Z7 x1 |
| `pk_bediron_bronze.gltf` | BED-B iron bed (queen) | Quaternius `FBX/Bed_King.fbx` | CC0 1.0 | 1.75 x 2.25 x 1.15 | 676 | 25 | Z7 x1 |
| `pk_bediron_white.gltf` | BED-B iron bed (queen) | Quaternius `FBX/Bed_King.fbx` | CC0 1.0 | 1.75 x 2.25 x 1.15 | 676 | 26 | Z6 x1 |
| `pk_bookcase_walnut.gltf` | STOR bookcase | Quaternius `FBX/Bookshelf.fbx` | CC0 1.0 | 1.80 x 0.40 x 2.10 | 120 | 10 | Z2 x3 |
| `pk_chair_cush_grey.gltf` | DIN-A cushioned chair | Quaternius `FBX/Chair_3.fbx` | CC0 1.0 | 0.46 x 0.52 x 0.98 | 428 | 25 | Z8 x16 |
| `pk_chair_cush_white.gltf` | DIN-A cushioned chair | Quaternius `FBX/Chair_2.fbx` | CC0 1.0 | 0.46 x 0.52 x 0.98 | 352 | 20 | Z8 x28 |
| `pk_chair_ladder_black.gltf` | DIN-A ladder-back chair | Quaternius `FBX/Chair_1.fbx` | CC0 1.0 | 0.46 x 0.52 x 0.98 | 216 | 16 | Z8 x28 |
| `pk_chair_ladder_espresso.gltf` | DIN-A slat-back chair | Quaternius `FBX/Chair_4.fbx` | CC0 1.0 | 0.46 x 0.52 x 0.98 | 264 | 17 | Z8 x16 |
| `pk_chest_cream.gltf` | STOR chest | Quaternius `FBX/Drawer_4.fbx` | CC0 1.0 | 1.00 x 0.48 x 1.32 | 464 | 18 | Z11 x1, Z2 x1 |
| `pk_cocktail_burl.gltf` | OCC-A round burl cocktail table | Quaternius `FBX/Table_RoundSmall2.fbx` | CC0 1.0 | 1.00 x 1.00 x 0.46 | 744 | 31 | Z9 x3 |
| `pk_cocktail_glass.gltf` | OCC-A metal + glass cocktail table | Kenney `tableCoffeeGlass.glb` | CC0 1.0 | 1.20 x 0.70 x 0.45 | 140 | 9 | Z3 x1 |
| `pk_cocktail_oak.gltf` | OCC-A cocktail table | Kenney `tableCoffee.glb` | CC0 1.0 | 1.30 x 0.75 x 0.45 | 124 | 8 | Z1 x1, Z4 x1, Z9 x2 |
| `pk_cocktail_round.gltf` | OCC-A round cocktail table | Quaternius `FBX/Table_RoundSmall2.fbx` | CC0 1.0 | 1.00 x 1.00 x 0.46 | 744 | 31 | Z2 x1, Z3 x1, Z4 x1 |
| `pk_cocktail_walnut.gltf` | OCC-A cocktail table | Kenney `tableCoffee.glb` | CC0 1.0 | 1.30 x 0.75 x 0.45 | 124 | 8 | Z1 x1, Z4 x2 |
| `pk_console_oak.gltf` | OCC-C console | Quaternius `FBX/Drawer_5.fbx` | CC0 1.0 | 1.60 x 0.40 x 0.78 | 352 | 20 | Z4 x2 |
| `pk_curtain_beige.gltf` | FIX curtain | Quaternius `FBX/Curtains_Double.fbx` | CC0 1.0 | 3.40 x 0.30 x 2.80 | 320 | 15 | Z5 x1 |
| `pk_desk_white.gltf` | FIX sales desk | Kenney `desk.glb` | CC0 1.0 | 1.50 x 0.70 x 0.76 | 198 | 13 | Z11 x1 |
| `pk_dryer_white.gltf` | APPL dryer | Kenney `dryer.glb` | CC0 1.0 | 0.69 x 0.75 x 0.98 | 262 | 16 | Z12 x1 |
| `pk_end_black.gltf` | OCC-B end table | Quaternius `FBX/NightStand_1.fbx` | CC0 1.0 | 0.55 x 0.45 x 0.60 | 172 | 12 | Z1 x2, Z3 x3, Z4 x2, Z9 x2 |
| `pk_end_oak.gltf` | OCC-B end table | Quaternius `FBX/NightStand_3.fbx` | CC0 1.0 | 0.55 x 0.45 x 0.60 | 272 | 17 | Z1 x4, Z4 x4, Z9 x4 |
| `pk_end_white.gltf` | OCC-B end table | Quaternius `FBX/NightStand_2.fbx` | CC0 1.0 | 0.55 x 0.45 x 0.62 | 184 | 12 | Z1 x3, Z2 x3, Z4 x2, Z9 x4 |
| `pk_fridge_steel.gltf` | APPL refrigerator | Kenney `kitchenFridgeLarge.glb` | CC0 1.0 | 0.91 x 0.75 x 1.78 | 436 | 26 | Z12 x1 |
| `pk_lamp_brass.gltf` | LAMP table lamp, brass | Quaternius `FBX/Light_Floor2.fbx` | CC0 1.0 | 0.29 x 0.30 x 0.70 | 276 | 11 | Z1 x1, Z2 x2, Z4 x4, Z8 x1, Z9 x4 |
| `pk_lamp_glass.gltf` | LAMP table lamp, glass | Quaternius `FBX/Light_Floor4.fbx` | CC0 1.0 | 0.31 x 0.31 x 0.68 | 244 | 11 | Z1 x2, Z11 x1, Z3 x2, Z4 x2, Z8 x1, Z9 x2 |
| `pk_lamp_gourd.gltf` | LAMP table lamp, white ceramic | Quaternius `FBX/Light_Floor3.fbx` | CC0 1.0 | 0.32 x 0.34 x 0.72 | 244 | 11 | Z1 x4, Z2 x1, Z4 x6, Z8 x4, Z9 x4 |
| `pk_love_brown.gltf` | SOFA-C loveseat | Quaternius `FBX/Couch_Large1.fbx` | CC0 1.0 | 1.65 x 1.00 x 1.00 | 1460 | 36 | Z3 x1 |
| `pk_love_cognac.gltf` | SOFA-C loveseat | Quaternius `FBX/Couch_Large1.fbx` | CC0 1.0 | 1.65 x 1.00 x 1.00 | 1460 | 36 | Z3 x1 |
| `pk_love_grey.gltf` | SOFA-C loveseat | Quaternius `FBX/Couch_Large2.fbx` | CC0 1.0 | 1.65 x 1.00 x 1.00 | 1332 | 44 | Z3 x1 |
| `pk_mat_adjustable.gltf` | MAT adjustable base | built in the script (`adjustable`) | project | 1.53 x 2.04 x 0.96 | 120 | 10 | Z7 x5 |
| `pk_mat_grey.gltf` | MAT mattress on foundation (queen) | built in the script (`mattress`) | project | 1.53 x 2.04 x 0.56 | 60 | 6 | Z7 x3 |
| `pk_mat_navy.gltf` | MAT mattress on foundation (queen) | built in the script (`mattress`) | project | 1.53 x 2.04 x 0.56 | 60 | 6 | Z7 x7 |
| `pk_mat_white.gltf` | MAT mattress on foundation (queen) | built in the script (`mattress`) | project | 1.53 x 2.04 x 0.56 | 60 | 6 | Z7 x2 |
| `pk_monitor.gltf` | FIX sales desk monitor | Kenney `computerScreen.glb` | CC0 1.0 | 0.55 x 0.15 x 0.42 | 72 | 6 | Z11 x2 |
| `pk_motion_brown.gltf` | SOFA-C motion sofa | Quaternius `FBX/Couch_Large1.fbx` | CC0 1.0 | 2.15 x 1.00 x 1.00 | 1460 | 36 | Z3 x1, Z4 x1 |
| `pk_motion_cognac.gltf` | SOFA-C motion sofa | Quaternius `FBX/Couch_Large1.fbx` | CC0 1.0 | 2.15 x 1.00 x 1.00 | 1460 | 36 | Z3 x1 |
| `pk_motion_grey.gltf` | SOFA-C motion sofa | Quaternius `FBX/Couch_Large2.fbx` | CC0 1.0 | 2.15 x 1.00 x 1.00 | 1332 | 44 | Z3 x1 |
| `pk_motion_taupe.gltf` | SOFA-C motion sofa | Quaternius `FBX/Couch_Large2.fbx` | CC0 1.0 | 2.15 x 1.00 x 1.00 | 1332 | 44 | Z3 x1 |
| `pk_ott_cream.gltf` | OTT cocktail ottoman | Kenney `loungeSofaOttoman.glb` | CC0 1.0 | 1.20 x 0.90 x 0.42 | 84 | 7 | Z1 x1, Z4 x1 |
| `pk_ott_grey.gltf` | OTT cocktail ottoman | Kenney `loungeSofaOttoman.glb` | CC0 1.0 | 1.20 x 0.90 x 0.42 | 84 | 7 | Z1 x1, Z4 x2, Z9 x1 |
| `pk_ott_tweed.gltf` | OTT cocktail ottoman | Kenney `loungeSofaOttoman.glb` | CC0 1.0 | 1.20 x 0.90 x 0.42 | 84 | 7 | Z1 x1, Z4 x2 |
| `pk_pillowtower.gltf` | FIX pillow tower | built in the script (`pillowtower`) | project | 0.90 x 0.50 x 1.60 | 276 | 21 | Z7 x1 |
| `pk_plant_monstera.gltf` | DECO faux plant | Quaternius `FBX/Houseplant_7.fbx` | CC0 1.0 | 1.26 x 1.31 x 0.95 | 449 | 18 | Z2 x1 |
| `pk_plant_small.gltf` | DECO faux plant | Quaternius `FBX/Houseplant_1.fbx` | CC0 1.0 | 0.59 x 0.53 x 0.55 | 245 | 10 | Z4 x1, Z8 x3 |
| `pk_plant_snake.gltf` | DECO faux plant | Quaternius `FBX/Houseplant_4.fbx` | CC0 1.0 | 0.33 x 0.33 x 0.90 | 316 | 15 | Z1 x1 |
| `pk_plant_tall.gltf` | DECO faux plant | Quaternius `FBX/Houseplant_8.fbx` | CC0 1.0 | 0.50 x 0.50 x 1.50 | 310 | 22 | Z1 x1 |
| `pk_range_steel.gltf` | APPL range | Kenney `kitchenStove.glb` | CC0 1.0 | 0.76 x 0.70 x 0.95 | 830 | 47 | Z12 x1 |
| `pk_recl_beige.gltf` | CHAIR-B recliner (footrest out) | Kenney `loungeChairRelax.glb` | CC0 1.0 | 0.95 x 1.25 x 1.05 | 188 | 13 | not placed yet |
| `pk_recl_black.gltf` | CHAIR-B recliner (footrest out) | Kenney `loungeChairRelax.glb` | CC0 1.0 | 0.95 x 1.25 x 1.05 | 188 | 13 | Z5 x2 |
| `pk_recl_brown.gltf` | CHAIR-B recliner (footrest out) | Kenney `loungeChairRelax.glb` | CC0 1.0 | 0.95 x 1.25 x 1.05 | 188 | 13 | Z5 x2 |
| `pk_recl_cognac.gltf` | CHAIR-B recliner (footrest out) | Kenney `loungeChairRelax.glb` | CC0 1.0 | 0.95 x 1.25 x 1.05 | 188 | 13 | Z5 x2 |
| `pk_recl_grey.gltf` | CHAIR-B recliner (footrest out) | Kenney `loungeChairRelax.glb` | CC0 1.0 | 0.95 x 1.25 x 1.05 | 188 | 13 | Z5 x2 |
| `pk_recl_quilt.gltf` | CHAIR-B recliner (footrest out) | Kenney `loungeChairRelax.glb` | CC0 1.0 | 0.95 x 1.25 x 1.05 | 188 | 13 | Z5 x2 |
| `pk_reclc_beige.gltf` | CHAIR-B recliner (closed) | Quaternius `FBX/Couch_Small2.fbx` | CC0 1.0 | 0.95 x 1.00 x 1.02 | 468 | 17 | Z4 x1, Z5 x10 |
| `pk_reclc_brown.gltf` | CHAIR-B recliner (closed) | Quaternius `FBX/Couch_Small2.fbx` | CC0 1.0 | 0.95 x 1.00 x 1.02 | 468 | 17 | Z4 x1, Z5 x10 |
| `pk_reclc_grey.gltf` | CHAIR-B recliner (closed) | Quaternius `FBX/Couch_Small2.fbx` | CC0 1.0 | 0.95 x 1.00 x 1.02 | 468 | 17 | Z5 x8 |
| `pk_rug_cream.gltf` | RUG | Quaternius `FBX/Carpet_2.fbx` | CC0 1.0 | 2.70 x 3.00 x 0.01 | 98 | 6 | Z1 x1, Z9 x1 |
| `pk_rug_round.gltf` | RUG | built in the script (`roundrug`) | project | 2.40 x 2.40 x 0.01 | 240 | 14 | Z1 x1, Z2 x1, Z4 x2 |
| `pk_rug_sisal.gltf` | RUG | Quaternius `FBX/Carpet_2.fbx` | CC0 1.0 | 2.70 x 3.00 x 0.01 | 98 | 6 | Z1 x1, Z4 x1 |
| `pk_rug_taupe.gltf` | RUG | Quaternius `FBX/Carpet_1.fbx` | CC0 1.0 | 2.40 x 3.00 x 0.01 | 108 | 6 | Z1 x1, Z11 x1, Z3 x1, Z4 x2 |
| `pk_rug_vintage.gltf` | RUG | Quaternius `FBX/Carpet_1.fbx` | CC0 1.0 | 2.40 x 3.00 x 0.01 | 108 | 6 | Z1 x1, Z3 x1, Z4 x1, Z9 x1 |
| `pk_sect_bluegrey.gltf` | SOFA-B sectional (L with chaise) | Quaternius `FBX/Couch_L.fbx` | CC0 1.0 | 2.90 x 2.10 x 0.88 | 1428 | 36 | Z1 x1 |
| `pk_sect_cream.gltf` | SOFA-B sectional (L with chaise) | Quaternius `FBX/Couch_L.fbx` | CC0 1.0 | 2.90 x 2.10 x 0.88 | 1428 | 36 | Z1 x1 |
| `pk_sect_creamleather.gltf` | SOFA-B sectional (L with chaise) | Quaternius `FBX/Couch_L.fbx` | CC0 1.0 | 2.90 x 2.10 x 0.88 | 1428 | 36 | Z4 x1 |
| `pk_sect_grey.gltf` | SOFA-B sectional (L with chaise) | Quaternius `FBX/Couch_L.fbx` | CC0 1.0 | 2.90 x 2.10 x 0.88 | 1428 | 36 | Z1 x1, Z9 x1 |
| `pk_sideboard_black.gltf` | STOR sideboard | Quaternius `FBX/Drawer_1.fbx` | CC0 1.0 | 1.70 x 0.45 x 0.85 | 404 | 15 | Z11 x1, Z8 x2 |
| `pk_sideboard_greywash.gltf` | STOR sideboard | Quaternius `FBX/Drawer_1.fbx` | CC0 1.0 | 1.70 x 0.45 x 0.85 | 404 | 15 | Z8 x2 |
| `pk_sideboard_white.gltf` | STOR sideboard | Quaternius `FBX/Drawer_1.fbx` | CC0 1.0 | 1.70 x 0.45 x 0.85 | 404 | 15 | Z4 x1, Z8 x2 |
| `pk_stool_black.gltf` | DIN-B counter stool | Quaternius `FBX/Stool.fbx` | CC0 1.0 | 0.44 x 0.46 x 0.68 | 500 | 21 | Z6 x6 |
| `pk_stool_oak.gltf` | DIN-B counter stool | Quaternius `FBX/Stool.fbx` | CC0 1.0 | 0.44 x 0.46 x 0.68 | 500 | 21 | Z6 x6 |
| `pk_taskchair.gltf` | FIX task chair | Kenney `chairDesk.glb` | CC0 1.0 | 0.60 x 0.60 x 0.95 | 588 | 35 | Z11 x1 |
| `pk_tcounter_oak.gltf` | DIN-B counter table | Kenney `table.glb` | CC0 1.0 | 1.50 x 0.90 x 0.92 | 120 | 8 | Z6 x2 |
| `pk_trect_black.gltf` | DIN-A rectangular dining table | Kenney `table.glb` | CC0 1.0 | 1.90 x 0.95 x 0.76 | 120 | 8 | Z8 x4 |
| `pk_trect_greyoak.gltf` | DIN-A rectangular dining table | Kenney `table.glb` | CC0 1.0 | 1.90 x 0.95 x 0.76 | 120 | 8 | Z8 x4 |
| `pk_trect_oak.gltf` | DIN-A rectangular dining table | Kenney `table.glb` | CC0 1.0 | 1.90 x 0.95 x 0.76 | 120 | 8 | Z8 x4 |
| `pk_tround_espresso.gltf` | DIN-A round pedestal table | Quaternius `FBX/Table_RoundSmall.fbx` | CC0 1.0 | 1.20 x 1.20 x 0.76 | 592 | 23 | Z8 x2 |
| `pk_tround_oak.gltf` | DIN-A round pedestal table | Quaternius `FBX/Table_RoundSmall.fbx` | CC0 1.0 | 1.20 x 1.20 x 0.76 | 592 | 23 | Z8 x1 |
| `pk_tround_white.gltf` | DIN-A round pedestal table | Quaternius `FBX/Table_RoundSmall.fbx` | CC0 1.0 | 1.20 x 1.20 x 0.76 | 592 | 23 | Z8 x1 |
| `pk_washer_white.gltf` | APPL washer | Kenney `washer.glb` | CC0 1.0 | 0.69 x 0.75 x 0.98 | 720 | 41 | Z12 x1 |

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
- `sofa_cream`: Z1 x1, Z2 x3, Z9 x2
- `sofa_leather`: Z1 x1, Z4 x1, Z9 x2
- `sofa_sage`: Z1 x1, Z4 x1, Z9 x3
- `sofa_taupe`: Z1 x1, Z4 x1, Z9 x2
<!-- /AUTO -->
