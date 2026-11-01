# Gadzooks: front and store (1995 map, store n35)

**Source (Oct 6, 2026).** The Gadzooks photo slideshow (YouTube `9dvXBZJC4sE`). Steven chose the 90s look: "the black-and-white tile + neon" front, not the later chrome capsule.
- **Front (0:02, 0:16):** black square tile with light grout on the fascia and piers, "GADZOOKS" in red neon, red and blue neon bands, glass windows with mannequins.
- **Inside (0:29, 0:36, 0:42):** a red-and-white checker floor, a red ceiling grid, red neon, black slatwall.

**Accuracy level:** 2. Photos of other Gadzooks stores, undated (the era is judged from the look). The layout is guessed.

**Guessed:** the depth (24 m of the 28 m stall), the checker aisle on dark grey carpet, the cash wrap on the left, the fitting rooms, the fixture order. Left out: the VW Beetle display in two photos, and the costumed characters in one.

**Frame.** A 12 m front on the north side of the hall (z = 48, x −62 to −50), facing the hall to the south (+z); the store runs north (−z). Map tiles x 117–122, y 112–123.

## Front
- Black tile with light grout from the opening to the lane ceiling, and black tile piers.
- "GADZOOKS" in double-traced red neon (Nunito Black outlines), between red and blue neon bands.
- Two glass windows with mannequins and a 4 m doorway.
- A black soffit with downlights.

## Inside (walkable)
- Dark grey carpet with a 2 m red-and-white checker aisle down the middle.
- Dark ceiling panels in a red grid, with troffers. A red neon line runs along the top of both walls.
- Black slatwall of face-outs on charcoal walls, and the cash wrap on the left.
- Racks, four-ways and tables, with SALE, $9.99, TEES $10 and NEW STUFF cards.
- Fitting rooms at the back.

## Files
`tools/stores/apparel/more.gd`, `paint_more.py`, `make_signs_more.py` → `gz_letters.json`.

## The Beetle and the ads (Nov 1, 2026, workstream G)
Steven (Oct 28): the interior with the clothing and ads, and the white half VW Beetle at the front.
`tools/stores/y95/extras.gd` (called from `apparel/more.gd`): `beetle()` the rear half of a white
Beetle covered in coloured handprints, lofted from body sections with rear fenders, wheels, the rear
window, engine-lid vents, taillights and a chrome bumper, cut square against the left wall of the left
window, its tail toward the doorway (refs `gadzooks-front-night-with-beetle.jpg`,
`gadzooks-beetle-handprints.png`); `gz_ads()` six poster panels on the side walls in the period ads'
manner (checker, floral, skate, surf: invented art, no brand names, IP rule). **Guessed:** where the car
stands (the night photo shows it behind the left window), its length (1.95 m, half a Beetle).
Evidence `wsG-1995-gadzooks-*.jpg`.
