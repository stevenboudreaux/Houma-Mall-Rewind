# Chick-fil-A: front and restaurant (store s64), rebuilt from the video

**Source (Oct 8, 2026).** Steven's screen recording of an Instagram reel. Steven says it shows "the precise configuration of Chick-fil-A at the Southland Mall". It is 66 s of home video in a busy sit-down mall unit, with a staff member talking in the kitchen at the end. The fashion looks mid-1980s, so the video probably predates the 1995 map. Steven chose it as the reference anyway.

This replaces the Oct 7 build. That build followed the facade record (tan diagonal tile, a red sign box with pink neon) and the Hammond 1993 commercial. The video shows a different front.

**Accuracy level:** 3. Front, counter, kitchen and dining room are all read off the video. Depth and the menu text are guessed.

**Frame.** An 8 m front facing north onto the hall at z = 60 (x −102 to −94), between Pocket Change and County Seat. The restaurant runs south 26 m (z 60–86) of the 40 m stall. Map tiles x 97–100, y 130–142. Facing the store from the hall, u = 0 is on your right.

## What the video shows (timestamps in the recording)

### Front (0–8 s)
- **Fascia:** light grey. Its sign panel drops lower than the rest of the fascia, over the open entry.
- **Sign:** the script name in white lit letters, with a red comb on the C (the logo).
- **Left of the sign panel:** a dark maroon beam set back over the dining entry.
- **Awning (right of the sign panel):** a recessed box framed in dark brown.
  - Inside: pink scalloped fish-scale shingles on a slope, lit from above by a cove light (the bright line along the top).
  - Two bays, split by a white pilaster, over the counter's front end. One bay shows the counter top; the other a dark takeout opening with a white shelf.
- **No glass:** the front is open full width, with a dark soffit and lay-in lights just inside.

### Counter (6–16 s, 40–45 s)
- Runs down the right-hand side from the front. It meets the front at the awning.
- Cream laminate top, very dark chocolate wood front.
- A row of beige registers, cup stacks and dispensers on top.

### Behind the counter (15.5 s, 47–66 s)
- **Menu band:** a long backlit band high over the counter. Dark brown panels with a food photo at each end (a sandwich; a lemonade glass with a lemon), and white text lines between.
- **Hood:** stainless, under the menu band.
- **Back wall:** maroon.
- **Kitchen:**
  - Pressure fryers with crank lids; one lid is open.
  - A bun toaster with yellow and red cartons on top.
  - A holding cabinet.
  - A steel prep table with buns and pickles.
  - Gold cone heat lamps on rods.
  - Outlets along the wall.

### Dining room (8–46 s)
- **Shape:** long and deep, to the left of the counter, and beyond the counter's end at full width.
- **Floor:** red quarry pavers in running bond, dark grout.
- **Walls:** cream wallpaper with sage stripes (paired hairlines framing a lozenge chain) over a dark wood wainscot and chair rail.
- **Booths:** button-tufted pale sage vinyl in dark wood frames, perpendicular to the walls, in a long row down each wall.
- **Furniture:**
  - Dark wood tables on black pedestals.
  - White painted spindle-back chairs.
  - Glass ashtrays, cups and sandwich bags on the tables.
- **On the walls:** brass sconces with big white globe shades, and dark-framed prints over the booths.
- **Dividers:** wooden planter boxes of leafy plants, one along the queue by the counter and others between seating.
- **Condiment island:** two dark wood cabinets with steel tops and label plates, at the end of the counter (12.5 s).
- **Ceiling:**
  - A lay-in ceiling with 2×4 troffers and a dark brown trim band round the top of the walls.
  - Dark ceiling fans down the middle.
- **Back wall:** a wood door with a green EXIT sign above it (17.5 s, 18.5 s).

## What is guessed or left out
- **Depth:** 26 m of the 40 m stall. The video's room is long; how long is unknown.
- **Width:** the stall stays 8 m (Steven: keep stall sizes). So the dining room is narrower than the video's: booths on both walls plus one middle row in the back room, and a single booth row with an open aisle in the front room.
- **Menu text and prices:** unreadable in every frame. The panel layout follows the video. The lines and prices are 1995-plausible guesses:
  - Sandwich $1.99, Deluxe $2.49, Chargrilled $2.59, Chicken Salad $2.29.
  - Nuggets 8 for $1.99, 12 for $2.89. Chick-n-Strips $2.69. Soup $1.39.
  - Waffle fries .89 / 1.09. Slaw, carrot-raisin .89. Tossed salad $1.29.
  - Lemonade .89 / 1.09 / 1.29. Tea and soft drinks .89 / 1.09. Lemon pie $1.19. Icedream .79.
- **Food pictures and framed prints:** painted, not copied.
- **The logo (Nov 1, 2026).** Steven: "as close as possible to the real 1995 mark ... quality over strict trademark caution, with discretion". The script stays the traced open face (`tools/stores/small/cfa_letters.json`, Mr Dafoe, OFL) as white lit channel letters with dark returns, and the C now carries the mark's chicken head: a three-lobed comb riding the top of the C's upper arc, red and lit (the video: "a red comb on the C"), and a short pointed white beak off the C's upper terminal. Drawn by hand onto the stand-in C (`tools/stores/cfa/make_comb.py` → `cfa_comb.json`), not traced from the trademark artwork.
  - **Guessed / discretion:** the lobe sizes and spacing (from memory of the period mark, not a drawing); the beak is short and partly hidden by the h's ascender at the stand-in script's letter spacing. The real 1990s script differs from Mr Dafoe in its letterforms; it is not copied. No "Chick-fil-A" artwork or slogan is used anywhere else in the store.
  - **Before Nov 1:** the comb and beak were left out for trademark caution.
  - Evidence: `production/qa/evidence/wsD-chick-fil-a-preview-unbaked.jpg`.
- **Cup print:** the cup print seen in the video is left out (plain cups).
- **Takeout bay:** shown as the counter's front leg with a register facing the hall.

## Built
- **Code:** `tools/stores/cfa/store.gd` (builder and `cf_*` materials) and `tools/stores/cfa/paint.py` (textures in `tex/cfa/`: wallpaper, quarry, vinyl, prints, menu, labels).
- **Routing:** `build_mall.gd` sends CHICK-FIL-A there. Its `BUILT_RECTS` entry is now z 60–86.
- **Walk grid:** `open_interiors.py` opens tiles y 130–142.
- **Baked groups:** `cfa_shell`, `cfa_fix`, `cfa_kitchen`, `cfa_small`. The old `smk_*` and `smkf_*` groups are gone.
- **Unbaked (dynamic):** `cfaf_sign`. It holds the letters (with the C's comb and beak, material `cf_comb`, Nov 1) and the awning's shingles and cove light.
- **Lights:** troffer spots, one warm omni per sconce, kitchen and menu fills, the awning's cove and the letters' wash. All baked.
