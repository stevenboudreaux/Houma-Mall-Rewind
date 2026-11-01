# Rave: front and store (1995 map, store n9)

**Source (Oct 7, 2026).** The Southland facade record (level 1): "stacked, offset brushed-silver plates stepping out from the bulkhead, the white sign plate proud of them with heavy pink-red italics sliced by a speed line; under it a dim shop of posters and black clothes."

**Accuracy level:** 1. Stand-in type (Nunito Black Italic).

**Guessed:** the glass front, the depth (12 m of 26 m), the layout; the posters are invented (abstract shapes and plain words, no bands).

**Frame.** An 8 m front facing east at x = -10 (z -80 to -72), between Solarium and Lane Bryant, built 12 m deep. Map tiles x 137–142, y 60–63.

## Front
- Dark grey bulkhead; three brushed-metal plates stepping out, offset; the white sign plate proud of them, RAVE in pink-red italics with a white speed line through it.
- Dark-framed glass, the doorway in the middle; forms in black and in white in the windows.

## Inside (walkable)
- Dark grey walls, grey carpet, dim light.
- Posters high on both walls; black and charcoal tops and jeans below, a few accents; round racks of black down the middle; the cash wrap at the back.

## Files
`tools/stores/small/wave9.gd`, `paint9.py` → `tex/w9/`, `make_signs.py`. Hooks in `tools/build_mall.gd` and `tools/open_interiors.py`.

## Sign pass (Oct 7, 2026)
See photos/ (Steven's photos for this store) and tools/stores/signs/ (make_logos.py batch3, channel.gd sg_* materials).
A black box sign hung out over the entrance (3.4 x 1.3 m, 1.2 m deep, on a stem to the ceiling), dark glass face, RAVE in pink lit letters (Poppins Black, OFL, slanted 14 degrees). Replaces the brushed-steel panels and red letters.

## Nov 1, 2026 (workstream D): party goods
Steven (Nov 1): "mostly party stuff, a few black items."
- **Read as:** party goods and novelties, with a few black clothes. Built: wall bays of packaged party goods (Woolworth's invented party and candy stock sheets, `md/stock_party`, `stock_candy`) down the left wall and the front of the right wall, under the poster band; a low two-bay gondola of party goods down the middle; bunches of helium balloons (bright latex rounds on white strings) over the gondola and in the right window; a short wall of black tees on the right wall by the cash wrap; one black-dressed form in the left window. The posters stay high on both walls; the round racks of black clothes are gone.
- **Guessed / open:** whether "party stuff" means party supplies (built) or party and club wear. If it is clothes, the bays swap back to racks. Rave the chain sold juniors' clothing in the 1990s; Steven's memory is followed.
- **Period check (1995):** latex balloons, packaged party goods, posters with invented words: no anachronism.
- **Unchanged:** the front (the black box sign with RAVE in pink, Oct 7 sign pass).
- Code: `wave9.gd` `rave()` and `balloons()`, material `w9_balloon`. Evidence: `production/qa/evidence/wsD-rave-preview-unbaked.jpg`.
