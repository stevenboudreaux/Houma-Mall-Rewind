# Concepts: front and store (1995 map, store s61)

**Source (Oct 7, 2026).** The Southland facade record (level 1): "school uniforms and backpacks for kids. Instead of windows, two deep white shadow boxes either side of the door, each holding huge plain geometric solids about the height of a three-year-old: a sphere, a cone, a cube, a cylinder (the colours are a guess until a photo turns up). Through the door, racks of navy and white uniforms, plaid jumpers, khakis and a wall of backpacks." The flat front gives the cream siding, the plum sign box and the colours (red sphere, yellow cone, blue cube, green cylinder).

**Accuracy level:** 1. Stand-in type for the sign.

**Guessed:** the colours and which solid stands where, the depth (14 m of 40 m), the layout.

**Frame.** A 10 m front facing south at z = 60 (x -68 to -58), beside Golden Chain Gang, built 14 m deep. Map tiles x 114–118, y 130–136.

## Front
- Cream front; a dark plum sign box with CONCEPTS in cream capitals.
- Two deep white shadow boxes behind glass, lit from above: a red sphere and a yellow cone in one, a blue cube and a green cylinder in the other, each about 0.95 m tall.
- A wide doorway between them under a plum lintel.

## Inside (walkable)
- Vinyl floor, cream walls.
- Uniform walls down both sides (navy blazers, white polos, plaid jumpers, khakis); a wall of backpacks across the back.
- A table of folded polos, two four-ways; the cash wrap on the left at the back.

## Files
`tools/stores/small/wave9.gd`, `paint9.py` → `tex/w9/`. Hooks in `tools/build_mall.gd` and `tools/open_interiors.py`.

## Nov 1, 2026 (workstream D): more texture
Steven (Nov 1): "the shapes are right; texture them more." New source: the store's own Courier ad (`refs/era_1995/ads/ad_6.jpg`, 1990s): CONCEPTS in heavy serif capitals, Eastpak mesh backpacks, "Mesh bags — as mandated by Lafourche Parish Schools. Clear book bags also available for elementary schools", "See our display in front of Chick-fil-A".
- **Front:** the cream front is now lap siding (`w9/concepts_siding.png`, the flat front's cream siding); the sign box carries CONCEPTS in heavy serif capitals like the ad (Liberation Serif Bold stands in for the ad's face), cream on plum with a cream rule.
- **The solids:** same shapes, sizes and colours; now finished in 1990s spatter paint (black and grey flecks, `w9/concepts_spatter.png`) with a satin sheen. The finish is a guess.
- **Inside:** a cream and grey vinyl tile floor with plum feature rows (`concepts_floor.png`); the back wall is now school bags on pegs: mesh backpacks in navy, black, red, green, blue and purple, and clear book bags with binders showing (`concepts_bags.png`). No brand names or logos (IP rule: the ad's Eastpak is not shown).
- **The display in front of Chick-fil-A (the ad):** a white rolling two-tier table of mesh and clear bags with a CONCEPTS card on a stem, in the concourse about 3 m out from the Chick-fil-A front (x -98, z 56.8). Its exact spot and look are guessed. It is built by `concepts()` (group `w9c_display`), so it sits in Concepts' wing.
- **Period check (1995):** mesh and clear book bags were the Lafourche/Terrebonne school rule in the 1990s (the ad); spatter paint, vinyl tile: period. No anachronism.
- Code: `wave9.gd` `concepts()`, `display()`; materials `w9_c_*`, `w9_concepts_sign_serif`; textures `tools/stores/small/paint9_d.py`. Evidence: `production/qa/evidence/wsD-concepts-preview-unbaked.jpg`, `wsD-lions-share-concepts-closeups-unbaked.jpg`.

## Nov 2, 2026: the display in front of Chick-fil-A removed
Steven (Nov 2): remove the Concepts display kiosk in front of Chick-fil-A (workstream D's rolling table from the ad, `wave9.gd display()`). Removed; the Concepts store itself stays as built. Wing 2's day lightmap (1995) keeps its baked shadow until the next bake.

## Nov 8, 2026 (workstream PACKS): the solids smooth
Steven (Nov 8, looking at Demo 52): "the square displays have a noisy texture; they should be smooth (flat colour or
a clean fabric, not noise)". The Nov 1 spatter flecks are off the four solids: same shapes, sizes and colours,
flat satin paint (`wave9.gd` `solid_*`). Read as the solids, the only textured thing in the shadow boxes (guess:
"square displays" = the shadow-box displays). `tex/w9/concepts_spatter.png` stays on disk, unused. Wing 2 (1995)
needs its stand-in recaptured; the lightmap is unaffected (material only), a rebake refines the bounce colour.
Evidence: `production/qa/evidence/wsPACKS-concepts-before-preview-unbaked.jpg` / `-after-preview-unbaked.jpg` (probe-lit preview, front and close-up), and the live Demo 52 front `wsPACKS-concepts-before.jpg`.

