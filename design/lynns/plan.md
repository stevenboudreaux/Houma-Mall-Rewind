# Lynn's Interiors (2026): build plan — workstream LYNNS (Nov 4 2026)

Research: `inventory.md`. Floor plan: `layout.md` + `layout.png`. Wing: 4, year 2026 (`wing4_2026.tscn`,
pack `w4y26`; `design/godot-wings.md` "Wings 4-6"). The skeleton stays as built by workstream E.

## How each family is modelled

All furniture goes through the Blender pipeline (`.claude/skills/blender-asset/`,
`design/godot-blender-pipeline.md`): a Python generator per family with the numbers at the top, a thin
script per variant, headless build, baked atlas (albedo with AO, ORM, normal), `.glb`, turntable sheet,
Godot shot.

| Family | Generator | Approach | Variants by |
|---|---|---|---|
| SOFA-A/B/C, CHAIR-A/B, OTT | `_lynns_sofa.py` (+ sectional/recliner modes later) | **soft boxes** (`_lynns_common.soft_box`: a rounded, crowned box built from its own quad lattice, rows bunched at the edges so it rounds without subdivision) for every cushion, arm, deck and back; welts as tubes along the cushion seams; arms by type (track, rolled, English, flared); legs by type (tapered, turned, block) or a dressmaker skirt; throw pillows with pinched corners and patterned covers | arm, back (loose n / tight), seat count, base, fabric kind + colour, pillows |
| BED-A, BED-B | `_lynns_bedroom.py` | case goods from boxes with real drawer fronts, bevels, raised fields, crown/cove tops, bun/splayed/brass feet, lathe knobs/rosettes, bar pulls; headboards and mirrors as **2D outlines** (arch, serpentine, scallop) extruded and framed with inset rings (`outline_slab`, `ring_slab`, ear-clipped); upholstered panels as soft boxes; display bedding (mattress, duvet with drops, shams, accent pillow, folded throw) | suite: finish, bed style, feet, pulls, mirror shape, bedding colours |
| MAT | `_lynns_bedroom.py` (mattress mode) | soft-box mattress with a quilt pattern in the normal map, foundation, adjustable base | quilt pattern, size, base |
| DIN-A/B | `_lynns_dining.py` (phase 3) | tables: tops + trestle / turned / X bases (lathe, boxes); chairs: ladder-back, X-back, oval French (outline frame + cane via normal map), parsons (soft box) | table base, top, chair type, finish |
| OCC, STOR | `_lynns_case.py` (phase 4, from the case() code) | boxes, lathes, outlines; glass and marble as flat/baked materials; books as box arrays | shape, finish |
| LAMP, MIRR, DECO | small generators (lathe profiles for lamps and vases, outlines for mirrors) | lathe + flat shade material (lamps are off: no emission) | profile, glaze |
| RUG, ART | PIL-painted textures on thin slabs/frames | procedural patterns (vintage medallion, trellis, sisal, boho), abstract canvases painted from noise | pattern, colours |
| SIGN | PIL labels (`lib/labels.py`) | the Lynn's hang tag (white, the store's script mark), FINAL MARKDOWN (orange), FALL SAVINGS (red leaf), the mattress card (yellow), invented mattress brand panels (`SLUMBERWELL`, `BAYOU REST`, `MOONLIGHT`) and an invented adjustable-base placard | — |

**Finishes** (`_lynns_common.py`, all procedural, baked): `fabric(kind)` for chenille, linen, tweed,
bouclé, velvet, leather (a voronoi grain with creases); `wood()` with rings round the grain axis (lines
along the grain on every face); `paint()` for lacquer and washes; `pillow_mat()` for stripe, medallion,
ikat, solid covers; `metal()` for brass, pewter, bronze.

## Budgets for the web

| Piece | Class | Triangles | Texture (3 maps) | Phase-1 actual |
|---|---|---|---|---|
| sofa / sectional piece | large_fixture | 10–18k (≤ 25k) | 2048 | see the table in `design/godot-blender-pipeline.md` |
| bed dressed | large_fixture | 14–22k | 2048 | |
| dresser + mirror, chest | large_fixture | 4–9k | 1024 | |
| nightstand, chair | small_fixture | 2–8k | 1024 | |
| lamp, vase, decor | hand | 0.3–3k | 512 | |

**Rendering cost in the wing.** ~290 floor pieces when complete, ~60 distinct models.
- **Draw calls:** one baked material per model (mirror glass and lamp shades are a second) → about one
  draw call per instance, ~350 for the floor; repeated small decor (tags, books, vases) as MultiMeshes.
- **Triangles:** ~3 M total if every piece is at full detail; Godot generates mesh LODs on import
  (`meshes/generate_lods`, on by default), so pieces far down the 50 m aisles drop to a fraction.
  Add `visibility_range_end` 40 m for decor and 70 m for furniture (the store is 70 × 50 m).
- **Lighting:** the furniture is **dynamic** (no UV2, no lightmap texels): the wing's lightmap probes
  light it, and its own contact AO is baked into its albedo. The wing4_2026 lightmap does not grow
  (it is 1.9 Mpx today). Static furniture with UV2 would cost ~15+ Mpx of lightmap: not planned.
- **Texture memory (the real limit).** One 2048 model ≈ 10.7 MB of VRAM on desktop (BC1 albedo and
  ORM, BC5 normal, with mips); one 1024 model ≈ 2.7 MB. Phase 1 = 8 × 2048 + 12 × 1024 ≈ 118 MB. All
  ~60 models at this mix ≈ 350 MB: fine on desktop, too much for phones. **Decision for Steven**
  (picture quality rule): import Lynn's textures for the mobile pack at half size (one import setting
  per texture folder, checked with before/after shots), or keep 2048 everywhere and accept the mobile
  memory. No size is lowered without his yes.
- **Pack size:** the models live in `models/lynns/<id>/` (not `models/bl_*`), so they ship in the
  `w4y26` pack with the scene that uses them, not in the shared `items` pack every wing downloads
  (`tools/shared_packs.json`). Phase 1 adds ~60 MB of PNG source (Godot compresses on import).

## Build order and estimate

A "session" = one cloud workstream session (~6–8 h, much of it build/bake time on a 2-CPU box).

| Phase | Content | Pieces (models) | Sessions |
|---|---|---|---|
| **1 (this session)** | research, layout, SOFA-A ×4, BED-A ×4 suites (16 models), placement code + data | 20 models, 28 placed | 1 |
| 2 | SOFA-B sectionals ×4 (+ ottomans), SOFA-C motion ×4 (+ loveseat), MAT ×3 + adjustable base, BED-B iron ×3 + nailhead; remove the fridges/TVs; place Z1, Z3, Z7 | ~18 | 2 |
| 3 | DIN-A ×4 tables + 5 chairs + bench, DIN-B ×3 stools + counter table, CHAIR-A ×6, CHAIR-B recliner (tinted ×5) + lift; place Z4, Z5, Z6, Z8 | ~22 | 2–3 |
| 4 | OCC-A/B/C ×10, STOR ×7, LAMP ×6, MIRR ×3 | ~26 | 2 |
| 5 | RUG ×8, ART ×8, DECO kit, SIGN (tags on every piece), FIX (desk, pillow tower, sample racks); fill every zone to the inventory counts | ~30 + MultiMeshes | 2 |
| 6 | performance (LOD check, visibility ranges, MultiMesh), the mobile texture decision, the Mac bake of wing4_2026, before/after evidence, docs | — | 1 |
| | **total** | ~115 models, ~290 placed + decor | **10–11 sessions ≈ 1.5–2 weeks** |

Each phase ends with unbaked in-store shots and a push; the integration session bakes wing4_2026 on the
Mac (wings that need a rebake: **wing 4, 2026** only; wing 1 2026's anchor picture of the Sears mouth
`y26_from_w4` is recaptured after it).

## Risks
- The zone placement is a reading of the walk, not a measured plan (`layout.md` "Confidence").
- Soft-box upholstery reads well at 2–5 m; very close up the seams are in the normal map only.
- The 2-CPU box: a full 2048 build takes 10–25 min when other sessions are busy (the out-of-memory
  killer stopped one build in phase 1); batch builds run in the background with retries.

## Status after pass 2 (Nov 4 evening) and the plan from here

Steven's Nov 4 spec changed the order: the CC0 packs (Quaternius primary, Kenney for gaps) fill the whole floor
now, and the generator replaces pack pieces family by family where it looks better (`asset-manifest.md` "Which
source won"). Done: phase 1 (SOFA-A ×4, BED-A ×4 suites) + **pass 2: 83 pack models, 407 pieces placed in all 12
zones** (`layout.md` "Pass 2"), unbaked shots for Steven's layout review.

| Next | Content | Sessions |
|---|---|---|
| A — after Steven's layout review | move zones / groups as he says (data only); price tags on every piece (`lib/labels.py` hang tag + markdown cards as a MultiMesh); slatwall brand panels; books in the bookcases (Kenney `books`), throw pillows | 1 |
| B — generator upgrades where the pack is weakest | SOFA-B sectional mode (cloud U, L with chaise) to replace `Couch_L`; recliner / lift chair; wingback + chair-and-a-half; trestle tables + benches | 2–3 |
| C — case goods and decor | curio, hutch, carved sideboards, mirrors (try Quaternius `Bathroom_Mirror1/2`), urns / vases / trays, floor lamps, PIL-painted art and rugs with the footage's patterns | 2 |
| D — finish | the ogee and canopy beds, performance (visibility ranges, MultiMesh for tags and decor), the mobile texture decision for the generator props, Mac bake of wing4_2026 + stand-in recapture, before/after | 1–2 |
| | **remaining** | **6–8 sessions ≈ 1–1.5 weeks** |
