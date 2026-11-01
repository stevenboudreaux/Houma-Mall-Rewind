# Wicked Wingz (2026 map, store s64: the 1995 Chick-fil-A unit)

**Steven's direction.** Oct 28: "same stall and same layout as Chick-fil-A, a little older-looking".
Nov 1, correcting the first build: "it's the literal exact layout of Chick-fil-A['s] counter and
dining room, it's the literal same stall. All that needs to change is branding and menu and
signage."

**Source for the re-skin.** Steven's Oct 23 2026 footage: IMG_4441 f003–f006 (the counter square
on), IMG_4461 f028–f034 (from the hall), the sign crop `refs/derived/signs/wingz_IMG_4441_f006.jpg`.

**How it is built.** `prototypes/godot-mall/project/tools/stores/wingz/store.gd` calls Chick-fil-A's
own builder (`tools/stores/cfa/store.gd`, untouched; `design/storefronts/chick-fil-a.md`), so the
front, counter, kitchen and dining room are the 1995 stall exactly, and any later change to the 1995
Chick-fil-A carries over. The 2026 look comes from `fill_cf()`: in the 2026 build, `build_mall.gd`'s
`mat()` asks it first for every `cf_*` material (the 2026 scene has no other Chick-fil-A). Its own
additions use `ww_*` materials; textures `tools/stores/wingz/paint.py` → `tex/ww/`. Walkable: s64 is
in `make_layout_2026.py`'s `KEEP_OPEN` (the same walk area as 1995).

## What changes from Chick-fil-A
- **Signage:** the script letters are hidden (transparent material); the Demo 43 Wicked Wingz sign
  (`y26/parts/wingz.json`: matte black panel, yellow letters) hangs on the sign panel where the
  script was. The fascia, the beam over the dining entry and the awning box take the mall's cream
  (the footage shows a cream soffit, no pink shingles, no maroon). The red A-frame with a printed menu
  stands at the front (f004–f006; the Coca-Cola branding on the real one is left off).
- **Branding:** the counter is faced in white 4" tile with a row of black accent tiles (f006), with a
  steel top; a steel-post sneeze guard along the long leg carries the four black printed panels
  (COMBO DEALS, the wordmark, GET WICKED!, the big wordmark). White walls and wainscot instead of the
  striped paper and the maroon; white booth vinyl and tables; yellow chair seats ("white seating with
  yellow chairs"); light grey floor tile instead of the red quarry (f006).
- **Menu:** the five-board Wicked Wingz menu (wings, tenders, burgers, po-boys, pasta: the dish words
  follow f006; the lines under them are painted placeholders) in Chick-fil-A's menu band.

## Kept as Chick-fil-A's (unchanged)
Layout, counter shape, kitchen line, booths, planters, condiment island, ceiling fans, sconces, framed
prints, the dark trim band, the back door.

## Guessed
- Whether the booths' wood frames, sconces and prints survive in 2026 (not seen clearly); kept.
- The earlier reading of the footage (counter across the front, dining to the east) is withdrawn per
  Steven's Nov 1 direction.

## Evidence
`production/qa/evidence/wsG-wingz-front-unbaked.jpg` (IMG_4441 f006 | game), `wsG-wingz-counter-unbaked.jpg`,
`wsG-wingz-sheet-unbaked.jpg` (front, hall, counter, dining room). Unbaked preview renders
(`MALL_YEAR=2026 tools/qa/preview.sh "store:WICKED WINGZ"`). Wing 2 2026 needs a rebake.
