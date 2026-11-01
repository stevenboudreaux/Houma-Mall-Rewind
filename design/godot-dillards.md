# Dillard's level 1, walkable — workstream E, Nov 1 2026

**Asked for:** Dillard's level 1 as a walkable store in wing 2, from the Oct 23 footage and the
in-store 3-level directory (its level-1 plan for the department layout). 2026 is what the footage
shows; 1995 keeps the bones (Dillard's since 1989) and changes only what is clearly modern.
Generic fixtures, invented brands only.

Code: `prototypes/godot-mall/project/tools/stores/dillards/` (`store.gd`, `paint.py` → `tex/dl/`,
materials `dl_*`). Called from `build_mall.gd`'s `anchor_front()` for DILLARD'S after the mall-side
fascia and sign; it replaces the old fake interior with the whole level. Wing 2 (both years).

## Sources
| What | Source |
|---|---|
| Ceiling (2×4 lay-in, curved cove-lit gypsum bulkheads, cans), mirror columns, travertine with granite edging, cherry pads, grey carpet | `refs/new/dillards_L1/IMG_4490_t110_022–106`, `IMG_4491_t000_001–031`; notes_E IMG_4490 "Interiors", IMG_4491 |
| Escalator bank by cosmetics, drum column | `IMG_4490_t110_097–103`; notes_E |
| Department layout | the directory, `refs/new/dillards_directory/IMG_4490_t136_015–027` (first level, read from t136_016 and t136_023) |
| Exterior entrance vestibule (glass inner doors, dark-bronze outer doors, pale grey tile with dark accents) | `IMG_4490_t136_005–011`, `IMG_4490_t110_058–064`; notes_E "Entrance" |
| Mall opening: full height, glass sidelights, no grille | `IMG_4491_t000_016–031`; notes_E IMG_4491 |

## Orientation
The directory's plan is drawn with the mall entrance at the bottom ("SOUTH MALL ENTRANCE"). In the
game Dillard's is the south anchor and opens north into C3, so the plan is turned 180°: its "WEST
ENTRANCE" (beside men's) is the game's **east face** — the cast-iron gallery side, the entrance
Steven walked in through before passing men's and cosmetics — and its "NORTH ENTRANCE" is the
game's **south face** (Bayou Gardens). notes_E warns not to re-orient the game from these labels;
this only maps the plan onto the box.

## The box
Map rect s2: x 129–163, y 140–159 → world x −38..30, z 80..118 (68 × 38 m). The mall opening is
H8's width, x −10..2 at z = 80 (anchor_front's piers stand in it); the main aisle runs south from it
on x −4 to the escalators.

## Layout (game coordinates)
Aisles (polished beige travertine, 60 cm squares, `tex/dl/trav.png`), each edged where it meets a
department by a 12 cm black granite strip and a 30 cm brown granite band:
- main aisle x −6..−2 from the mall to the escalators (z 80–104);
- the ring x −30..22, z 86..110 (3 m wide);
- men's cross aisle z 96.8..99.6 from the escalators east to the ring, and on to the east entrance;
- women's cross aisle the same line west to the ring;
- the south entrance aisle x −17..−13, z 110..114.5.

Departments (the directory's first level, turned): **east half = men's** on cherry-plank pads
(Polo/Fragrances and Dress Furnishings/Accessories north of the cross aisle, Sportswear south of
it, Shoes and Sportswear along the east wall either side of the entrance, Clothing along the mall
wall, Denim and the Cremieux-type collection along the south wall); **west half = cosmetics and
accessories**: cosmetics islands either side of the main aisle (counters of black bases with lit
cases round a back tower), fashion jewelry, handbags and women's accessories on grey carpet,
women's shoes along the west wall (a shoe wall) and the south-west, sunglasses/handbags along the
mall wall. The department list per block is `DEPTS` in `store.gd`.

| Element | As built | From |
|---|---|---|
| Lay-in | 2×4, 3.6 m, troffers on a 3 × 3.6 m grid off the coffers | frames t110_028–034 |
| Coffers and bulkheads | over every aisle: coffer ceiling at 4.2 m with a faint warm glow (the cove up-lights), white gypsum bulkhead edges waving in and out (0.35 ± 0.4 m) on the long sides, straight fascias at closed ends, a warm cove line at the top | IMG_4491 t000_016–031 ("wavy, curved gypsum soffit") |
| Cans | recessed downlight discs every 2.4 m down each coffer | frames |
| Columns | square 0.8 m, mirror-clad, black base; grid x −31, −22, −13, 5, 14, 25 × z 91.5, 103, 113.5 (off the aisles) | notes_E; spacing a guess |
| Escalators | two units side by side, x −6.6..−1.4, rising south from z 104.5 at 30° (5.2 m) into a white well with level 2's edge visible; black steps, stainless skirts and decks, white glass balustrades, black handrails | t110_097–103 |
| Closed | chrome stanchions and a black belt across the bottom landing, "Escalator closed" card (Steven: visible, not usable — the brief left it to me) | — |
| Drum column | white, 1.2 m, beside the escalators | notes_E |
| Mall opening | open full height, glass sidelights inside the piers | IMG_4491 |
| East entrance | vestibule x 26.5..30, z 95..101.4: glass inner doors, dark-bronze outer doors (4 leaves, brass pulls), pale grey 12" tile with dark accent squares, ceiling 3.0 m, the store directory on the north wall (black lacquer, gold header strip, three pastel plans, no text) | t136_005–011, t110_058–064, t136_015–027 |
| South entrance | the same outer doors at z = 118, x −17.4..−12.6, a shallow vestibule behind a glass screen | the plan's "NORTH ENTRANCE"; not filmed (a guess) |

Fixtures (generic, dynamic meshes): round racks, four-ways and maple nesting tables with folded
stacks in men's; cosmetics islands; white cube islands with bags in handbags/jewelry; shoe wall and
risers in women's shoes. No brands, faces or product names anywhere.

## 1995 vs 2026
Same bones. Changed for 1995 (guesses): men's pads are a deep green-grey cut-pile carpet instead of
the cherry planks (`carpet95.png`; plank floors in men's read 2000s). Everything else — the
travertine and granite, mirror columns, curved bulkheads, escalators — is kept as plausible for a
1989 Dillard's fit-out (it may be a later remodel; replace if a period photo turns up). No
lifestyle posters were built in either year.

## Exits ("Go outside")
`tools/make_exterior.py` adds `s2e` (east entrance, out (32.5, 98.2)) and `s2s` (south entrance, out
(−15, 120.5)) to `exterior.json`: "Go outside · Dillard's east entrance / south entrance". Wing 3
has the Dillard's east gallery and entrance portal; the door spots there have no prompt geometry of
their own — **workstream F** should check the out spots line up with its portal.

## Budget (unbaked, measured on this branch)
| | Lightmap texels (static meshes) | Web pack |
|---|---|---|
| Wing 2 1995 | 3.58 → 3.79 Mpx (+0.24 Mpx `dl_*`) | 80.4 → 83.3 MB |
| Wing 2 2026 | 2.34 → 2.55 Mpx | 51.6 → 55.0 MB |
Ceilings unwrap at 2× the hall texel, floors and walls at 1.25×; 1 m floor and ceiling cells merged
into runs, meshes cut in ~17 × 19 m chunks. Lights: a warm spot every 7.2 m down the coffers, one
fill per lay-in bay off the coffers, a daylight fill in the vestibule, one in the escalator well.

## Guesses (to confirm)
- The plan-to-game turn (above) and so which half is men's.
- Column spacing; coffer widths; the exact curve of the bulkheads.
- The south entrance (not filmed).
- The 1995 men's carpet.

Evidence: `production/qa/evidence/wsE-dillards-*.jpg` (unbaked).
