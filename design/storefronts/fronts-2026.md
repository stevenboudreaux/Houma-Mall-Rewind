# The 2026 "through the glass" fronts (workstream G, step 4 of Steven's Oct 28 sprint)

**Ask.** "The first 8–10 m inside you can see from the hall, built from the frames" for Great American
Cookies, Lids, Journeys, Claire's, The Billiard Room, DJS, Spencer's, Foot Locker, Aéropostale, Rainbow,
Bath & Body Works, Cakelicious, Auntie Anne's and AT&T; Spencer's facade (brick) from step 3.

**How.** `prototypes/godot-mall/project/tools/stores/fronts26/store.gd`: one recipe per store, laid
out as seen from the hall, left to right (x = 0 at the viewer's left whichever way the store faces),
on a shared kit (front pieces, a room behind, fixtures; racks, face-outs and mannequins from the
apparel kit, shoe walls from `small/shoes.gd`). Textures `fronts26/paint.py` → `tex/f26/`, materials
`f26_*`. Dispatched from `build_mall.gd`'s 2026 `storefront()` branch. Not walk-in (the store tiles
stay shut). Signs: the Demo 43/45 specs, unchanged except Journeys (step 3). Merchandise is invented
generic shapes (IP rule): no product art, no team marks, no third-party logos.

**Accuracy.** Level 3 for each front (read off a sharp frame); level 1–2 for the insides (what shows
through the opening in the frames, else the brand's usual look, marked below).

| Store | Frame(s) | Front | Inside |
|---|---|---|---|
| Spencer's (n35, 12 m) | IMG_4440 f001–f002, IMG_4439 f034–f036 | faux red brick piers and a 3.4 m solid brick wall, concrete plinth, weathered plank lintel with a rusty steel angle, two black-framed windows, the open entry under the half-raised graffiti shutter (the Demo 43 sign on it), yellow "enter" banner, rusty bracket, two lit poster stands, a lit vending machine | black walls of printed tees, black ceiling with track heads, two novelty gondolas, coloured light |
| Great American Cookies (6 m) | IMG_4439 f013 + its sharp crop | red soffit band with downlights, the LED colour box, open front | the cookie case (`tools/stores/gac/case.gd`, see `great-american-cookie.md`), the white wave wall with "Share the Fun of Cookies", register pedestal, ice-cream dipping cabinet (generic cones), red back counter with drink/slush machines, three menu screens |
| Lids (6 m) | IMG_4439 f005, IMG_4438 | navy fascia and piers, entry left, glass window right with cap shelves, gold-tone side panel | cap walls all round, light wood floor, cap table, counter |
| Journeys (6 m) | IMG_4440 f012–f019, full/journeys | purple fascia, lime band, open front with a display window, green display tower out front | olive slatwall shoe walls, red-brick accent at the back, slate floor, black ceiling, corrugated soffit with a lit cove, oak tables of boots, galvanised stools |
| Claire's (four edges, double end cap) | IMG_4484 f007–f011, IMG_4492 f017 | white fascia, silver crumpled-metal trim, all-glass fronts in white mullions round the corner | one L-shaped room: accessory walls, earring spinners, a plush table |
| The Billiard Room (32 m) | IMG_4484 f013–f016, IMG_4492 f020 | glossy black fascia, the gold sign, frameless black-edged glass both sides of the open entry, black faux-marble square column | pool tables under pendant lights, concrete floor, black ceiling, APL banners and dart toe lines behind the left glass |
| DJS Jewelers (two edges) | IMG_4438 f014, IMG_4477 | black fascia, olive-brown tall panel pilasters on travertine, open between | warm walls, lit glass cases in a U, a lantern, portrait posters, stanchions |
| Foot Locker (6 m) | IMG_4440 f007 (front only) | brushed-metal fascia, glass both sides of the entry | **guessed (brand look):** black shoe walls, referee-stripe header, wood floor, bench |
| Aéropostale (10 m) | IMG_4476–4483, IMG_4492 f009 | black riveted-steel grid portal, red letters, glass both sides | face-out walls, tables of folded tees, a round rack, four-ways, sale poster |
| Rainbow (10 m) | IMG_4482, IMG_4492 f003 | white beadboard, blue script, sky-blue door frames at two entries, two windows with mannequins | brights on face-out walls, tables, racks |
| Bath & Body Works (8 m) | IMG_4440 f009 | the blue/white gingham surround round a white portal, sign over the opening | white tables and wall shelves of pastel bottles, bright light |
| Cakelicious (two edges incl. the clipped corner) | IMG_4459 f011, IMG_4461 | salmon fascia, white Tuscan columns, glass | lit cake case, pink menu, bistro tables |
| Auntie Anne's (4 m) | IMG_4439 f024–f025 | navy fascia, open counter front | wood-look counter, lit pretzel warmer, menu, oven and rolling table |
| AT&T (8 m) | IMG_4442 f008, notes in `y26/parts/att.json` | black graphite fascia, slate-grey pilasters, glass with the entry on the left | grey carpet, white wall bays of phones, a lit poster on the left wall, round white tables, counter, dark ceiling with track lights |

**Guessed / to check.** Depths (6–10 m, the stores' real depths are not filmed); Foot Locker's inside;
Claire's entry position (the glass runs unbroken here); the Billiard Room's table count; the
Cakelicious inside; which way Lids' window and entry sit (from f005's angle).

**Evidence.** `production/qa/evidence/wsG-front-<store>-unbaked.jpg` (frame | unbaked preview), and
`wsG-front-gac-1995-unbaked.jpg`. Wings 1 and 2 (2026) need a rebake; wing 2 (1995) for the GAC case.

## Step 5: end caps and corners (Nov 1)
- **Zales corner** (s33, the 1995 Frank's unit, Frank's/Orange Julius side of the Shoe Dept court):
  `zales()` in `fronts26/store.gd`. Two open jewellery bays either side of a tall cream corner pier
  with a dark brown base; the left bay as seen from the court is recessed 1.6 m behind the pier with
  its fascia set back with it, the right bay at the front line; a ZALES (Demo 43 spec) over each bay,
  sconces on the pier, cherry cases. Frames refs/new/woolworth_corner t026_001–009. **Guessed:** the
  recess depth (1.6 m) and which bay is recessed (read from t026_003–005, the camera moving; say if it
  is the other way). 1995 (Frank's, Orange Julius) unchanged: the frames are 2026 only, and the
  recess is not in the 1995 facade record.
- **The Billiard Room / Woolworth corner** ("still doesn't look quite right"): in 2026 the left glass
  run (toward Aéropostale) stands 1.1 m proud of the black fascia, frameless, with a glass return back
  to the entry's black column and a black roof; inside cream walls, white round columns wrapped in
  caution tape, a grey floor, a lay-in ceiling (t026_021–029). The 1995 Woolworth corner is workstream
  D's file; not touched.
- **Claire's double end cap** and **Cakelicious' corner**: built with step 4 (Claire's glass wraps
  both fronts of the L; Cakelicious' clipped corner is its own glass face with Tuscan columns).
- Evidence `wsG-corner-zales-unbaked.jpg`, `wsG-corner-billiard-unbaked.jpg`.
