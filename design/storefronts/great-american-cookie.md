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
