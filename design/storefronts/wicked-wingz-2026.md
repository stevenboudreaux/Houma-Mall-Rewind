# Wicked Wingz (2026 map, store s64: the 1995 Chick-fil-A unit)

**Source (Nov 1, 2026, workstream G).** Steven's Oct 23 2026 footage: IMG_4441 f003–f006 (walking
west, then square on to the counter), IMG_4461 f028–f034 (walking east along the south side, the
dining side from the hall), the sign crop `refs/derived/signs/wingz_IMG_4441_f006.jpg`. Steven, Oct
28: "same stall and same layout as Chick-fil-A, a little older-looking". Narration (IMG_4440):
"Wicked Wingz is obviously Chick-fil-A".

**Accuracy level:** 3 for the front, the counter, the menu band and the dining room's look (read
off f006); 2 for depths; 1 for the kitchen line (only its hood, door and the menu band are seen).

**Frame.** The 1995 Chick-fil-A frontage, 8 m facing north onto the Concourse at z = 60
(x −102 to −94). u = 0 is the west end (your right facing the store), d into the store.
`prototypes/godot-mall/project/tools/stores/wingz/store.gd`, textures `wingz/paint.py` → `tex/ww/`,
materials `ww_*`. Dispatched from `build_mall.gd`'s 2026 branch of `storefront()`; walkable: s64 is
in `make_layout_2026.py`'s `KEEP_OPEN`.

## The front
- No storefront glass: the whole 8 m is open under a **cream soffit** (bottom ~3.0 m) between two
  square cream piers, as filmed. An **eggcrate grille** strip runs just inside the soffit (lit).
- The **sign**: the Demo 43 spec `y26/parts/wingz.json` (matte black panel 2.44 × 1.39 m, yellow
  cut letters), centred over the counter, its foot level with the soffit's bottom.
- A **red A-frame** with the printed menu stands in front of the counter's east end (f004–f006).
  Its printed lines are invented; the Coca-Cola branding on the real frame is left off.

## Inside
- **Floor:** light grey 12" tile from the front line back (the hall's beige tile stops at it, f006).
- **Counter:** faces the hall about 1.9 m in, 4.6 m straight run from the west wall plus a
  45° corner to the kitchen partition (the angled end in f003). White 4" glazed tile with one row of
  small black accent tiles every second tile, second course from the top; black kick; steel top with
  a copper edge. **Sneeze guard:** steel posts, glass over four black printed panels with a fire
  glow — COMBO DEALS, the wordmark, GET WICKED!, the big wordmark (in that order, f006).
- **Menu band:** five lit black boards hanging over the kitchen (wings, tenders, burgers, po-boys,
  pasta: the dish words follow f006, the lines under them are painted placeholders).
- **Kitchen:** a white wall ~3 m behind the counter with a steel swing door with a porthole (f006),
  a hood over three fryers/flat-top, a holding cabinet, squeeze bottles on a shelf, heat lamps over a
  pass table.
- **Dining room:** east of the counter (your left facing the store, f006): white walls with a white
  chair rail, white laminate two-tops on black pedestals, yellow molded chairs on chrome legs
  (IMG_4461 f032–f034), a TV on the east wall, a tan door at the back with a black wire rack and a
  trash can by it. Lay-in ceiling with Chick-fil-A's dark trim band (still there in f006).
- **"A little older-looking":** a slightly yellowed white, faint grime on the tile and floor, two
  water-stained ceiling tiles.

## Guessed
- **Layout vs Chick-fil-A.** The footage shows the counter facing the hall across the front, with the
  dining room to its east, not Chick-fil-A's counter running down the west wall. I followed the
  footage and kept the unit, the open front and the ceiling trim; Steven's "same layout" is read as
  "same unit". Say if the 1995 arrangement should be mirrored instead.
- **Depth.** Only ~7 m is built (the dining room's back wall with the door at d 7.2); the rest of the
  40 m unit is back of house, not walkable. The 1995 dining room went back 26 m.
- IMG_4461 f032–f033 show a table with yellow chairs just behind the front at what looks like the
  west end; with the camera moving fast that may be the east end seen across the counter. Not
  resolved; the tables are in the east strip.
- The TV picture, menu lines and A-frame poster are invented placeholders.

## Evidence
`production/qa/evidence/wsG-wingz-front-unbaked.jpg` (IMG_4441 f006 | game), `wsG-wingz-counter-unbaked.jpg`,
`wsG-wingz-hall-unbaked.jpg` (IMG_4461 f033 | game), `wsG-wingz-sheet-unbaked.jpg`. Unbaked preview
renders (`tools/qa/preview.sh` with `MALL_YEAR=2026`). Wing 2 2026 needs a rebake.
