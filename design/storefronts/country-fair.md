# Country Fair: front and store (1995 map, store n42)

**Source (Oct 7, 2026).** The Southland facade record (level 1, from descriptions only, not yet a photo): "a green fascia with the name in cream serif, a white picket fence running across the front under the windows, and a shop full of country gifts: a quilt, baskets, candles, wooden hearts and dried flowers, with a gingham valance over the door."

**Accuracy level:** 1. Stand-in type: DejaVu Serif Bold, **upright** (Steven, Nov 1: "upright letters"; Bold Italic until Nov 1).

**Guessed:** all the details, the depth (10 m of 32 m), the layout.

**Frame.** A 6 m front facing south at z = 60 (x -124 to -118), beside Babbage's, built 10 m deep. Map tiles x 86–88, y 130–134.

## Front
- Green fascia, the name in cream serif between two fine cream rules.
- Green piers; a window each side over a white bulkhead with a white picket fence in front; a shelf of gifts in each window.
- A gingham valance over the open door.

## Inside (walkable)
- Wood floor, warm cream walls.
- Pine shelves down both walls of baskets, jar candles, wooden hearts, dried flowers and little signs; a quilt hung on the wall.
- A pine table of baskets and candles; the counter at the back.

## Files
`tools/stores/small/wave9.gd`, `paint9.py` → `tex/w9/`, `make_signs.py`. Hooks in `tools/build_mall.gd` and `tools/open_interiors.py`.

## Nov 1, 2026 (workstream D)
- Steven: "upright letters." `cf_letters.json` regenerated from DejaVu Serif Bold (was Bold Italic), same size (0.30 m caps, 2.89 m long); `make_signs.py` updated. Nothing else changed. Evidence: `production/qa/evidence/wsD-country-fair-preview-unbaked.jpg`.
