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

## Nov 1, 2026 (workstream D): going-out clothes
Steven (Nov 1): "mostly party stuff, a few black items", then: "rave is a clothing store, just 'party' type clothes for women going out." (A first pass the same day read "party stuff" as party supplies and balloons; superseded.)
- **Built:** going-out clothes for women: slip dresses, sequin minis, satin tops over short skirts or slim pants, in jewel colours (red, purple, teal, navy, gold), silver and white, and some black (`w9/rave_dresses.png`, painted by `paint9_d.py`, invented, no labels). Hung face-out on chrome wall rails in two tiers down both walls (dresses below, tops above), and on three round racks down the middle. Forms in the windows: a red dress, and a silver top over black. The posters stay high on both walls; the cash wrap stays at the back.
- **Guessed:** the mix of colours and garments, the fixtures.
- **Period check (1995):** slip dresses, sequins and satin going-out tops are mid-1990s juniors' and women's fashion; no anachronism.
- **Unchanged:** the front (the black box sign with RAVE in pink, Oct 7 sign pass).
- Code: `wave9.gd` `rave()`, materials `w9_rave_dresses`, `w9_rave_rack`. Evidence: `production/qa/evidence/wsD-rave-preview-unbaked.jpg`, `wsD-rave-ingame-unbaked.jpg`.

## Nov 2, 2026: confirmed (Steven)
Rave is **women's going-out clothes, with a few black items**: what the Nov 1 build shows. No geometry change.
