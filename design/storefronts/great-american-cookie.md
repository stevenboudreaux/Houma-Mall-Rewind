# Great American Cookie Co.: front and store (1995 map, store smuopv1vy0)

**Source (Oct 7, 2026).** The Southland facade record (from Steven's photos): "Great American Cookie Co. (from the photo): a cream sign box with maroon checkerboard corners, Great American in yellow neon script on a maroon lobe over the black pill of white capitals; under warm downlights a row of back-lit menu pictures, white tile with a red check course, the glass case of cookies, lit panels of cookie cakes and the heart-shaped specials."

**Accuracy level:** 2 to 3 for the front (the record). The inside is a period type, built on the shared kits.

**Guessed:** the depth (12 m), the layout.

**Frame.** A 6 m front facing south onto the hall at z = 48 (x −32 to −26), between Wicks 'N' Sticks and Sports Avenue. Map tiles x 132–134, y 118–123.

## Front
- A cream sign box with maroon checkerboard corners, 'Great American' in yellow script on a maroon lobe over a black pill with COOKIE COMPANY in white (painted, lit).
- White tile, and a cream soffit with downlights.

## Inside (walkable)
- White tile walls with a red check course.
- The glass case of cookies across the shop, with a register.
- The ovens' steel along the back, under a row of lit menu pictures.

## Files
`tools/stores/small/wave7.gd` (the nine Wave 7 shops, materials `w7_*`), `paint7.py` → `tex/w7/`, `make_signs.py` (letters). Hooks in `tools/build_mall.gd` and `tools/open_interiors.py`.

## The case, both years (Nov 1, 2026, workstream G)
Steven (Oct 28): "really focus on this, get it perfect", the same case in both years, only the sign
style changes. `tools/stores/gac/case.gd` (`case_run`) builds it from the 1990s photo
(`refs/great-american-cookie-case.jpg`) and the 2026 frame (IMG_4439 f013, sharp crop
`refs/derived/signs/gac_IMG_4439_f013.jpg`): a white base on a recessed kick; a sloped lower window,
leaning back, with the decorated cookie cakes on a maroon back (lit); a deck and three stepped tiers of
cookie trays under a quarter-round curved front glass up to a flat glass top; white end and section
frames cut to the profile every ~1.4 m; a lit strip under the top; price cards; sliding doors on the
staff side. Textures `gac/paint.py` → `tex/gac/` (invented cookie kinds and cake lettering).
- 1995 (`small/wave7.gd`, `cookie()`): the old box case is replaced by `case_run` at the same place
  (2.6 m in); the 1995 front, sign, tile and check course are unchanged.
- 2026 (`case.gd` `build_2026`, called from `fronts26/store.gd`): the 2026 store round the same case.
- Guessed: the case's length (the store's width less the register pedestal in 2026; the old counter's
  4.8 m in 1995), the cookie kinds.

## The work area from Steven's video, both years (Nov 4, 2026, ws/interiors)
**Asked for (Steven, voice note Nov 3):** "I have the kiosk for Great American Cookie ... pretty perfect ...
and the Great American Cookies the same in both eras." Store `smuopv1vy0`, in both maps at the same
place (tiles x 132-134, y 118-123: a 6 m front facing south at z = 48, x -32..-26, 12 m deep; wing 2).

**What the video shows** (`refs/new/cookie_co/gacc_t000_NNN.jpg`, 1 fps, NNN = seconds + 1; a food-court
counter, not Southland): 001-015 the counter from the court: **white 15 cm tile with scattered single
squares of maroon, black, yellow and green**, a row of **lit menu pictures on a white valance** with
small downlights over the back counter, a drink fountain and slush machine, the glass case on the front
with the **lit cookie-cake windows in white frames on maroon** under it (017-067, 128-132); 065, 134-138
the trays and price cards in the case; 069-126 a **sheet cookie cake being piped** on a **stainless prep
table** (rosette border, lettering), white icing buckets; 126, 150 **sheet-pan racks** on casters and a
**stainless convection oven** stack; 146 the menu pictures close up.

**Kept:** the case (`case.gd case_run`) is the one ws/g fitted to the 1990s photo and to Southland's own
2026 frame (IMG_4439 f013); the video's case is the same type (lit cake windows under curved glass), so
it is not changed, and it is still the same in both years.

**Added** (`tools/stores/gac/kitchen.gd`, textures `gac/paint.py`: `tile_sq`, `pics`, `cake_top`, `fountain`):
- **1995** (`small/wave7.gd cookie()`): the walls are now the video's tile with scattered squares (world
  triplanar; the record's red check course stays on top); the old steel box and cards at the back are
  replaced by a **tiled menu wall across the shop at 6.4 m** with the **back counter** (tile front, the
  drink fountain with an invented ICE COLD panel, cups, a cookie warmer) under **three lit menu
  pictures** (invented: FRESH BAKED, COOKIE CAKES, BROWNIES, SANDWICHES), and a doorway on the right into
  the **kitchen**: two oven stacks, two sheet-pan racks of cookies, the prep table with the cookie cake
  being piped, buckets, a hand sink. The record's "ovens' steel along the back, under a row of lit menu
  pictures" is now the menu wall and the kitchen behind it.
- **2026** (`case.gd build_2026`): the empty floor between the case and the red back counter now holds the
  video's work area along the plain right wall: an oven stack, a sheet-pan rack, and the prep table with
  the cookie cake. The Southland 2026 front (red soffit, LED box, wave wall, dipping cabinet, red back
  counter, menu screens) is unchanged.

**Guessed:** the menu wall's depth (6.4 m) and doorway, the kitchen layout, the 2026 work area's place
(not in the Southland frames), every picture, word and cookie. No drink brands (the video shows them:
not copied).

**Tile (checked against the video, Nov 4):** the scattered squares are single, never touching, mostly
black, then maroon, a few green and yellow (gacc 005, 146), 14 per 16 x 16 tiles on a 2.4 m repeat so the
scatter does not read as a pattern (`gac/paint.py tile_sq`; first pass had 4 per 8 x 8 on 1.2 m and read
as repeating maroon pairs).

**Neighbour fix (shared file, one line):** Wicks 'N' Sticks (s44) was still built 6 m wide
(`tools/stores/small/store.gd` CFG) after its front was narrowed to 5 m (27f5c378), so its right wall's
shelves stood 1 m inside this shop (seen from the case and the kitchen). `small/store.gd build()` now
clamps the width to the front's length. Wicks checked: `interiors-gac-1995-wicks-neighbour-unbaked.jpg`.

**Evidence (unbaked):** `production/qa/evidence/interiors-gac-1995-{doorway,case,menuwall,kitchen,prep}-unbaked.jpg`,
`interiors-gac-2026-{doorway,workarea,backcounter}-unbaked.jpg`.
**Rebake:** wing 2, both years (`wing2`, `wing2_2026`); the 1995 one also carries the Wicks fix.

**Shoppable (a proposal for ws/items; nothing added here):** a counter shop (`design/godot-shops.md`) in both
years, the attendant behind the case: a chocolate-chip cookie (a new Blender item; `bl_gac_sugarcookie`
already exists as a 1995 pick-up and would become stock on display), a cookie-cake slice, a brownie, a
fountain drink. Prices for Steven. The cookie cake on the prep table is a fixture, not an item.
