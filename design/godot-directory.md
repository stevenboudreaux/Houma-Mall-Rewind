# The mall directory kiosks (Godot mall)

Workstream A, Nov 1 2026 (branch `ws/a-directory`). Steven's top ask that day:
1. A 3D directory kiosk, modelled from the Oct 23 footage.
2. Kiosks in both years.
3. A map of every stall that jumps you to a store.
4. A 1995 / 2026 toggle, each year looking like its own real directory.
5. Mr. Silverman's jewelry island back in 1995.

## Sources
- **The 2026 kiosk** (refs pack, `refs/new/directory/`):
  - IMG_4408 t050_017–027: straight on.
  - t050_011 and t050_007: in the hall, for scale and placement.
  - IMG_4461 t008_010: the second kiosk.
  - `derived/signs/directory_IMG_4408_f031.jpg`.
  - `derived/photos/IMG_4455.jpg`: the panel, legible.
  - notes_A "Mall Directory kiosk" and notes_B §4 "Directory totems".
  - **Backs:** `derived/frames/IMG_4484/f068.jpg` (kiosk 1 from behind, with Lynn's portal) and
    `IMG_4459/f006.jpg` (kiosk 2 from behind, past the kiddie carousel).
- **Every contact sheet** (`refs/derived/sheets/`, all 56) was checked for other kiosks. There are
  only two, listed under "Where the kiosks are". Things that look like kiosks but are not
  directories:
  - Morguard leasing displays (IMG_4438 f010, IMG_4440 f005/f009)
  - the ecoATM (IMG_4492 f022)
  - a Dippin' Dots freezer and Coke vending
  - Dillard's own black wall directory (IMG_4490 f072)
- **The 1995 look:** `refs/era_1995/directory/courier_1994-03-20_merchant_list_map.jpg`, the mall's
  own "Merchant List & Map" (The Courier, Mar 20 1994, p.99). The 1991 map was also looked at.

## The kiosk (tools/stores/directory/kiosk.gd)
A single-sided totem: the backs are plain cream (IMG_4484 f068).
- **Plinth:** a 0.10 m toe under a block with a chamfered top, 1.26 × 0.52 × 0.46 m, grey.
- **Cabinet:** 1.20 × 0.30 × 1.38 m, top at 1.84 m.
  - The sides are grey and the back is cream.
  - **The red pinstripes** (Steven, Nov 1: "the sign is missing the red pinstripes"):
    - A 2 cm red cap band runs round the cabinet's top edge, above the aluminium frame, so it shows
      from the front and sides, as in t050_021 and t050_011. The first version had the stripe
      tucked behind the frame, where it could not be seen from the front.
    - At the back, a second band runs along the bottom edge (IMG_4484 f068).
  - A satin aluminium frame (0.09 m at the sides, 0.12 m top and bottom) surrounds the recessed
    lit art (1.02 × 1.14 m), with a dark gasket line and two lock barrels on the right.
- **Crown:** an arched slab 0.98 m wide, with 0.06 m shoulders and a 0.13 m segmental rise (top
  2.03 m). Grey in front, cream behind.
- **Finial:** five pleated, champagne-silver diamond blades fanned over 84°, about 0.22 m across
  with the tip near 2.10 m. They sit on a 0.036 m ball in a dark slot at the cabinet's top edge.
  This is the mall's own fan motif (the 1994 logo, the court sconces).
- **Measured** against the 12" floor tiles in t050_011 and the panel's proportions in t050_021,
  so ±10%. No person stands near a kiosk in any frame, so there was no human scale. All sizes are
  constants at the top of `kiosk.gd`.
- **Colours** (Steven: "the color is slightly off"): sampled from the footage. The raw pixels
  are dark, because the camera exposed for the bright panel, so each sample was corrected against
  the white floor and ceiling tiles in the same frame (t050_011, t050_021, IMG_4461 t008_010,
  IMG_4484 f068). The samples disagree with each other by about ±10%; the hexes below are their
  consensus:

  | Part | Hex |
  |---|---|
  | Cabinet and crown | `#a7b1b3` (a light, slightly cool grey) |
  | Plinth | `#858c8f` |
  | Aluminium frame | `#b3babc` |
  | Inner lip | `#c6cccd` |
  | Pinstripes | `#b5676d` (dusty red) |
- **Built dynamic** (probe-lit, group `directory`, like the info desk), so placing or changing a
  kiosk needs no rebake. The panel is unshaded (it shows its art as lit from behind) and throws no
  light.
- **Materials:** `dir_*` (`kiosk.gd` `fill_mat`). **Textures:** `tex/dir/panel_1995.png`,
  `panel_2026.png` (2048 × 2290) and `back.png`.
  - The panels import lossless with mipmaps (`.import`: `compress/mode=0`, `detect_3d` off), so
    the small type stays sharp in the read-up-close view.

## The panels (tools/stores/directory/paint_dir.py)
- **2026: the real directory, redrawn.**
  - **Source:** IMG_4455, the C4 kiosk's panel shot straight on. It was straightened with a
    four-corner perspective warp to 1024 × 1145 (corners in the photo rotated 90° clockwise:
    (208,292) (1170,278) (1045,1337) (287,1283)) and redrawn at 2× in vector.
  - **The lists:** every line of STORES BY CATEGORY is transcribed at its measured position,
    including the tiny "inside" in "Disney inside JCPenney".
  - **The dots:** each list line's dot colour is read off the photo. **The dots are the colour of
    the map block the store sits in** (yellow, orange, magenta, blue, green, purple; black for the
    anchors and logo blocks).
  - **The map:** traced block by block, with the black logo blocks (Lynn's Interiors, JCPenney,
    Dillard's, The Red Seal, Hypervelocity, Shoe Dept. Encore, UNITECH). Also the hall greys, the
    pictograms, the entrance triangles, the transit stops and the four road names.
  - **The rest:** the LEGEND; SECURITY 985.228.4563; "Welcome!" with the mall's web and social
    names; MALL DIRECTORY; the faint light facets in the cyan bands.
  - **Colours** were read off the photo and corrected for its white balance (the white body reads
    `#deeaf0` in the photo).
  - **Type:** Liberation Sans (Arial / Helvetica metrics, OFL; in `tools/stores/directory/fonts/`)
    squeezed horizontally to match the sign's condensed type.
  - **Not copied:** the stock portrait of a woman at top left is not ours to reproduce. There is
    no stand-in either (Steven, Nov 1: "remove the soft blue blur altogether"); the plain cyan band
    runs through there.
  - **Check:** `production/qa/evidence/wsA-panel-2026-vs-photo.jpg`, the straightened photo left,
    the redraw right.
- **1995:** Steven, "pretty similar to the current one, just less modern".
  - The same layout, with teal bands and a mauve stripe.
  - The SOUTHLAND MALL fan logo from the 1994 page.
  - "Merchant List & Map", the 1994 category boxes (grey-bar headers) with "NN - Name" lines.
  - The floor plan drawn from the game's 1995 map, with the 1994 store numbers, the A–G special
    locations and a "Special Mall Locations" key.
  - **Guessed:** the colours. The 1994 page is black and white; the teal, mauve and the category
    colours are an early-90s palette.
  - **Check:** `wsA-panel-1995-vs-1994.jpg`.
- **The click areas** (`tex/dir/hotspots.json`, written with the panels) cover every list line
  and every store's place on the map, in panel pixels, keyed by the store's unit id.
  - **1995:** the map places are the stalls themselves (the plan is drawn from the game's map).
  - **2026:** the real sign's map is a diagram of coloured blocks, not stalls. Each store gets the
    stretch of its block along the hall its front faces, in the order of the frontages
    (`map_spot_2026`). Example: the H2 west-side stores share the orange and yellow blocks top to
    bottom; Hypervelocity is its own black block.
  - **Lines that point at a parent store:** "Disney inside JCPenney", "JCPenney Beauty" and
    "JCPenney Salon" go to JCPenney; "White Barn inside Bath & Body Works" to Bath & Body Works;
    "PINK inside Victoria's Secret" to the game's PINK unit.
  - **Lines with no unit in the game's map, so not clickable:** EcoATM, Ann Scrubs & Accessories,
    MG Boutique, T-Mobile (no mall frontage in the layout), Unitech Training Academy, Bayou Soccer
    Club, Southland Soccer Fields.
- **Updating:** both panels, the click areas and the in-game data come from the same layout
  files. After a layout change, run `make_data.gd`, then `paint_dir.py`, then rebuild the wings.

## Where the kiosks are (`directory_data.json`, "kiosks")
| # | Spot | Faces | 2026 | 1995 | Evidence |
|---|---|---|---|---|---|
| 1 | H2 north end, just south of the Sears / Lynn's court: (−3.0, −82.5) | north, toward the court | filmed | guess: same spot | IMG_4408 50–72 s; IMG_4413 f010 (from inside Lynn's); back IMG_4484 f068 |
| 2 | Top of H6 where it meets the JCPenney court, behind the kiddie carousel: (−142.0, 71.5) | south, down H6 | filmed | guess: same spot | IMG_4461 8–16 s; back IMG_4459 f006 |
| 3 | H3, the main entrance hall: (26.5, 3.2) | east, toward the doors | — | guess | none |
| 4 | C3, the Dillard's court: (−15.0, 69.5) | north, up H4 | — | guess | none |

- **Wings:** kiosks 1 and 3 are in Wing 1; kiosks 2 and 4 are in Wing 2.
- **The 1995 kiosks:** the fan finial matches the 1994 logo, so the cabinets plausibly date from
  the late-80s look. In 1995 they stand at the two filmed spots plus the main entrance and the
  Dillard's court, where a shopper arriving would look for one. Spots 3 and 4 are guesses.
- **Placement:** the x of kiosk 1 is from t050_007 (it stands east of the hall's centre line,
  toward the charcoal unit). The z is from IMG_4484 f068, close to the court's threshold band.
- Benches and planters keep 7.5 m away from each kiosk (the build's `avoid` list).

## Reading the directory (scripts/directory_ui.gd)
Steven, Nov 1: "I don't want a separate UI outside the one that's posted on the sign. I want it to
look literally identical to how the sign looks at the mall but I can just click inside the stall
or the name of the store as it's shown on that directory signage."
- **Opening it:** the kiosk is a node in group `interactable` (`scripts/directory_kiosk.gd`:
  `interact_prompt()` → "Mall Directory", `interact(player)` opens it). This is the shared
  contract with workstream B+C.
  - **Fallback (remove when interact.gd lands):** within 2.4 m of a kiosk's lit side, a prompt
    "Read the Mall Directory" shows. E, a controller's X or a tap on the prompt opens the
    directory. The fallback turns itself off when `res://scripts/interact.gd` exists.
- **What you see:** the kiosk's own panel picture, the same texture as on the 3D sign. It is shown
  as large as the screen allows, inside the kiosk's aluminium frame with the red pinstripe on top.
  - **Nothing else is added** except a small 1995 / 2026 toggle and a close button on the frame,
    and the "Jump to this store?" question.
  - **Choosing a store:** hover or select a store and every place it appears on the sign lights up
    (its list line or lines and its place on the map), with its name on a small tag over the map.
  - **The 1995 / 2026 toggle** switches to the other year's sign.
- **Controls:**
  - **Mouse:** click a store's name or its place on the map, then answer "Jump to this store?".
    The wheel zooms in on the sign; drag pans once zoomed in. Clicking off the sign closes it.
  - **Touch:** the same with taps; pinch to zoom, drag to pan.
  - **Keyboard:** arrows move from store to store across the sign; Enter asks, and Enter again
    jumps. Esc backs out. Tab or Y switches the year; +/− zoom on the selected store.
  - **Controller:** d-pad or stick moves; A asks and confirms; B backs out; Y, LB or RB switch the
    year; X zooms.
- **Jump spots:** each wing build writes `gen/<wing>/directory.json` (`map_data.gd`) for both
  years from `layout_mall.json` / `layout_2026.json`. Each store's spot is 2.2 m out from the
  middle of its longest frontage, on hall floor, facing the store, in the wing whose floor that
  is. So a jump always lands where the wing was built.
- **The jump:** `player.jump_to(wing, year, x, z, yaw_deg)` (new in `scripts/player.gd`).
  - Same wing and year: you are moved at once.
  - Otherwise the other wing's or year's file loads at that spot, through `_go_to_wing`, which now
    takes an optional year.

## 1995: the 1994 list vs the game's 1995 map
**The map follows the game's 1995 map; numbers and categories follow the 1994 list.** Each number
goes with the store, not the spot. Differences:
- **In the 1994 list, not in the game's 1995 map** (not shown):
  - Everything 99 (#84)
  - Smoothie King (#60)
  - One Price Clothing (#64)
  - Kiddie Koral (#35)
  - Tracks (#81)
  - the hall kiosks: Things Remembered (#90), Vision Plaza Sunglasses (#92), Balloon Express
    (#93), Ice Cream Shop (#94), Karmelkorn Kart (#96)
  - the adjacent buildings: Sears Hardware, Sears Automotive, Goodyear, American Bank Motor
    Branch, Premier Bank
  - the second-floor merchants
- **In the game, not in the 1994 list:**
  - **Blockbuster Music:** given #81 (Tracks' number; Blockbuster Music bought the Tracks chain).
    Guess.
  - **Babbage's:** given #97 under Music / Electronic. Guess.
- **Golden Chain Gang** is a hall kiosk (#95) in 1994 but a storefront in the game's 1995 map. It
  keeps #95 and stays where the game puts it.
- **Pups & Pets** (#52) has no mall frontage in the layout (an outside-facing unit), so it is not on
  the map.
- **The 1994 numbers run in a different order** from the game's spots in places (e.g. #3/#4 by
  JCPenney). The game's spots win.
- **A–G** are placed at the game's main entrance, the Shoe Dept. court, the Dillard's court, the
  elevator (x −44), the info desk, the restroom hall and the JCPenney court.

## 2026: the directory vs the game's 2026 map
- **On the real directory, not separate units in the game:** Disney (inside JCPenney), JCPenney
  Beauty, JCPenney Salon, PINK inside Victoria's Secret (the game has its own PINK unit, which is
  kept), White Barn (inside Bath & Body Works), EcoATM, MG Boutique, Ann Scrubs & Accessories,
  Unitech Training Academy (its own building), Bayou Soccer Club and Southland Soccer Fields.
- **T-Mobile** has no mall frontage in the layout, so it is not on the map.
- **In the game, not on the directory**, given a category by guess: The Billiard Room
  (Entertainment), Fire Haus 3.0 (Other Retail), the "Feelin' Hungry?" food court unit (Food).
- **Stores in more than one category** are listed in each, as on the real panel (e.g.
  Aéropostale under Men's and Women's). The map colours each store by its first category.

## Mr. Silverman's jewelry island (1995 only)
- **Removed Oct 16:** its island under the lit ring became the info desk. The handoff note said to
  re-add him "deeper in the mall".
- **The 1994 Merchant List & Map** has jewelry #91 **"Mr. Goldman"** in the concourse immediately
  east of E = Information. That is the spot used: (−41, 54), about 10 m east of the info desk, an
  island 3.4 × 1.8 m (the old `island_kiosk()`: glass cases, corner towers, "Mr. Silverman"
  plaques).
  - Built dynamic, so it needs no rebake.
  - On the map it is #91, Jewelry, with a jump spot on its south side.
- **Open question for Steven:** which name is right for 1995, Mr. Silverman or Mr. Goldman? The
  2018 walkthrough remembered "Mr. Silverman", and the 1994 list prints "Mr. Goldman" (#91). The
  game keeps **Mr. Silverman** until Steven says otherwise; the label is in `directory_data.json`
  ("extras") and `island_kiosk()`.

## Files
- **Kiosk and data:**
  - `tools/stores/directory/kiosk.gd`: the model, materials and placement; writes
    `GEN/directory.json`.
  - `map_data.gd`: the stall shapes and jumps.
  - `directory_data.json`: names, categories, numbers, kiosks.
  - `make_data.gd`: writes `map.json` for the painter.
  - `paint_dir.py`: the panels and their click areas, and `fonts/` (Liberation Sans, OFL).
- **Tests:**
  - `ui_test.gd`: a native headless jump test, e.g. `-- wing1.tscn dil` → Dillard's in Wing 2.
  - `ui_shot.gd`: native screenshots of the directory view.
  - `dirtest.js`: the web shots and the jumps (Node Playwright).
- **Runtime:** `scripts/directory_kiosk.gd`, `scripts/directory_ui.gd`, and `tex/dir/` (the
  panels, `hotspots.json`).
- **Shared files, small hunks:**
  - `tools/build_mall.gd`: the `dir_` material branch, and the `place()` call before
    `place_fixtures`.
  - `scripts/player.gd`: `jump_to()`, and the optional `year_to` in `_go_to_wing`.
  - `tools/qa/preview.gd`: previews any module by full path that has `preview()`.
  - `export_presets.cfg`: the eight wing presets include `tex/dir/*`, so every pack carries both
    years' panels (the 1995 / 2026 toggle shows the other year's).

## Evidence (production/qa/evidence/)
- `wsA-kiosk-vs-ref.jpg`: the preview against the footage.
- `wsA-panel-2026-vs-photo.jpg`, `wsA-panel-1995-vs-1994.jpg`: the panels against their sources.
- `wsA-kiosk-<year>-<spot>-unbaked.jpg`: in game.
- `wsA-map-<year>-<desktop|phone>*.jpg`: the directory open, on desktop and at phone width.
- `wsA-jump-before/after.jpg`, `wsA-phone-jump-after.jpg`: the jumps.
