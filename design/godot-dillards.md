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
| Escalator position (SMALLFIX) | the directory's first-level plan, `IMG_4490_t136_023` (sharpest) and `t136_016` |
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
on x −4 to the ring's south run (since SMALLFIX; until then it ended at the escalators).

## Layout (game coordinates)
Aisles (polished beige travertine, 60 cm squares, `tex/dl/trav.png`), each edged where it meets a
department by a 12 cm black granite strip and a 30 cm brown granite band:
- main aisle x −6..−2 from the mall to the ring's south run (z 80–107);
- the ring x −30..22, z 86..110 (3 m wide);
- men's cross aisle z 96.8..99.6 from the escalators east to the ring, and on to the east entrance;
- women's cross aisle the same line from the main aisle west to the ring;
- the plaza in front of the south doors x −21..−9, z 110..114.5 (the escalators' foot faces it).

Departments (the directory's first level, turned): **east half = men's** on cherry-plank pads
(Polo/Fragrances and Dress Furnishings/Accessories north of the cross aisle, Sportswear south of
it, Shoes and Sportswear along the east wall either side of the entrance, Clothing along the mall
wall, Denim and the Cremieux-type collection along the south wall); **west half = cosmetics and
accessories**: cosmetics islands either side of the main aisle and east of the escalators, fashion jewelry west of them (counters of black bases with lit
cases round a back tower), fashion jewelry, handbags and women's accessories on grey carpet,
women's shoes along the west wall (a shoe wall) and the south-west, sunglasses/handbags along the
mall wall. The department list per block is `DEPTS` in `store.gd`.

| Element | As built | From |
|---|---|---|
| Lay-in | 2×4, 3.6 m, troffers on a 3 × 3.6 m grid off the coffers | frames t110_028–034 |
| Coffers and bulkheads | over every aisle: coffer ceiling at 4.2 m with a faint warm glow (the cove up-lights), white gypsum bulkhead edges waving in and out (0.35 ± 0.4 m) on the long sides, straight fascias at closed ends, a warm cove line at the top | IMG_4491 t000_016–031 ("wavy, curved gypsum soffit") |
| Cans | recessed downlight discs every 2.4 m down each coffer | frames |
| Columns | square 0.8 m, mirror-clad, black base; grid x −31, −22, −13, 5, 14, 25 × z 91.5, 103, 113.5 (off the aisles and the escalator well: (−13, 103) is left out since SMALLFIX) | notes_E; spacing a guess |
| Escalators | a crisscross pair side by side, x −17.6..−12.4 (centred on the south doors, x −15), each 5.2 m over a 9 m run into one white well (x −18.2..−11.8, z 98.5..112.3): the east unit goes **up** from a foot at z 111 facing the south doors, rising north; the west unit comes **down**, rising south from a foot at z 99.8 that lets out north onto the women's cross aisle. Black steps, stainless skirts and decks, white glass balustrades, black handrails; each truss clad white 1 m deep with a sloped soffit and open floor beneath. Until Nov 8 2026 (SMALLFIX) both stood at the end of the main aisle (x −6.6..−1.4) rising south | t110_097–103; position and pairing from the plan (below); Steven, Nov 8: "1 escalator is on each side … 1 side goes up the other side down" |
| Closed | chrome stanchions and a black belt across each unit's foot, an "Escalator closed" card on each (Steven: visible, not usable — the brief left it to me) | — |
| Drum column | white, 1.2 m, beside the escalators on their west side, (−19.8, 104) (SMALLFIX; was (−8.9, 103.2)) | notes_E; side a guess |
| Mall opening | open full height, glass sidelights inside the piers | IMG_4491 |
| East entrance | vestibule x 26.5..30, z 95..101.4: glass inner doors, dark-bronze outer doors (4 leaves, brass pulls), pale grey 12" tile with dark accent squares, ceiling 3.0 m, the store directory on the north wall (black lacquer, gold header strip, three pastel plans, no text) | t136_005–011, t110_058–064, t136_015–027 |
| South entrance | the same outer doors at z = 118, x −17.4..−12.6, a shallow vestibule behind a glass screen | the plan's "NORTH ENTRANCE"; not filmed (a guess) |

Fixtures (generic, dynamic meshes): round racks, four-ways and maple nesting tables with folded
stacks in men's; cosmetics islands; white cube islands with bags in handbags/jewelry; shoe wall and
risers in women's shoes. No brands, faces or product names anywhere.

## The escalators at the south end (workstream SMALLFIX, Nov 8 2026)
**Asked for:** move the bank to the south end of level 1, in front of and facing the Bayou Gardens
exterior entrance portal (the one filmed Oct 23; EXT-B put it on the south face at x ≈ −15,
`design/exterior-sequence.md` §5 #7), still visible, going up, not rideable; re-flow the pads so the
aisle from the mall entrance to the south doors stays clear; both years.

**What the directory's first-level plan shows** (`IMG_4490_t136_016`, enlarged; also `t136_023`):
the escalators are a yellow bar drawn lengthwise (pointing from the mall entrance to the far
entrance) in the row of blocks next to the plan's NORTH ENTRANCE (its top edge): Mens Fragrances,
Cosmetics, **Escalators**, Fashion Jewelry, Fashion Jewelry, left to right. The bar sits right below
the NORTH ENTRANCE label, on the same line, with the ring aisle between them; it does not reach the
mall-entrance half (the big Cosmetics block and the SOUTH MALL ENTRANCE are below it). The bar is
two strips side by side, offset: the left one sticks out at the top, the right one at the bottom,
i.e. each unit's floor landing is at the opposite end — a crisscross pair, one up and one down
(Steven, Nov 8). Turned 180° onto the game (as above: the plan's north entrance is the game's south
doors, its left side the game's east), that is x ≈ −14..−17, z ≈ 99..110: the south half, on the
south doors' axis, cosmetics to the east, fashion jewelry to the west; the east unit's foot is at
the south doors' end, the west unit's at the mall end. Which unit goes up is not on the plan: the
one facing the doors goes up because the brief asks for that (a GUESS against the real store).

**As built (both years):** the pair is centred on x −15. The up unit's foot is at z 111 with its
stanchion line at z 111.5, leaving a 2.85 m walk to the vestibule's glass screen (z 114.5); the down
unit's foot is at z 99.8, its stanchions at z 99.3 on the cross aisle's edge. The aisle from the
mall: the main aisle straight south (x −6..−2) to the ring's south run (z 107..110), west along it,
then into the plaza (x −21..−9, z 110..114.5) past the pair's south-east corner to the doors; the
ring's south run is cut by the pair (go round by the plaza or the cross aisle). Re-flowed: Fashion
Jewelry x −27..−18.6, Cosmetics x −11.4..−6 (was −15..−8), Women's Shoes (south) x −30..−21,
Cosmetics (south) x −9..−2, two carpet corners beside the vestibule; the mirror column at (−13, 103)
is left out. The walk grid is the obstacles (`block()`): each unit from its top end to its
stanchions, 0.3 m round.

**Not changed:** the mall opening is still at x −10..2 (H8), 11 m east of the doors' axis; on the
plan the mall entrance, the escalators and the north entrance are on one line. The east vestibule
(with the store directory) is unchanged.

**Open:** the design note's orientation paragraph (above) predates EXT-B: it calls the east face the
entrance Steven walked in through, but EXT-B places the filmed portal on the south (Bayou Gardens)
face, and the directory he filmed is built in the east vestibule. Which vestibule the directory
belongs in is for Steven.

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

Evidence: `production/qa/evidence/wsE-dillards-*.jpg` (unbaked); the escalator move: `wsSMALL-dillards-escalators-{before,after}.jpg` (unbaked).
