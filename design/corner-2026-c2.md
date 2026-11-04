# The C2 / main-entrance corner (Zales; 1995 Franks and Orange Julius): analysis and proposal

Workstream `ws/corner-2026`, Nov 4 2026. **Status: APPROVED and APPLIED (Steven, Nov 4 ~12:55, via the
coordinator)**, on `ws/corner-2026`. His answers to the questions in section 5:
1. Restore the step in **both years**: court floor x 2..12, z 6..10; Franks fronts the court at z = 10;
   Orange Julius the corner unit with a court side.
2. The 2026 Zales is **open**, cases lit (IMG_4492).
3. 1995 Orange Julius' court side is a **plain wall**.
4. The narrow scroll-top unit by T-Mobile is **T.J.'s** (s38), so the blue-chair glass unit is **Tee Tai's**
   (s35); `data/eras_2026.json` notes corrected (s35, s36, s38).
5. The end-of-1994 directory was not resent; proceeding without it.

The rest of this note is the analysis as proposed; section 4 is what is now built.

**Asked (Steven, voice note, Nov 4):** "We need to get the corner right in 2026, with Zales by the mall
entrance and then Frank's and Orange Julius. It's still not right. Re-look at the dimensions in 2026; they
have to match. There have been no structural depth changes — it's all the same dimensions, so it needs to
look the same as with Frank's and then with Orange Julius, and the number of stalls."

Coordinates: world metres, x east, z south; map tiles `tx = x / 2 + 148`, `tz = z / 2 + 100`. The court
C2 is x -10..12, z -10..6; the entrance hall H3 is x 12..36, z -6..6; the east hall south H4 is x -10..2
from z 6. "A", "B", "C" are the three Zales openings, see below.

## 1. What the footage shows (2026)

Zales is **one store with three roll-grille openings** on the corner where H3 leaves the court, with two
building corners between them:

| Bay | Faces | Where | Opening / wall (estimate) | Frames |
|---|---|---|---|---|
| **A** | north, onto H3 | the first unit of H3's south row, flush with the glass unit east of it | ~3 m in a ~4 m wall | IMG_4432 (A beside the glass unit, Aéropostale across the court), IMG_4436, IMG_4437 f001 |
| *(convex corner)* | | a cream pier with the brown wainscot, the H3 / court corner | | IMG_4437 f001, IMG_4436, IMG_4492 t026_001 |
| **B** | **west**, onto the court | a return wall stepping south from H3's line | ~3 m in a ~4 m wall | IMG_4492 t026_001 (B square-on from the court, open, cases), IMG_4437 f001, IMG_4435 (left) |
| *(concave corner)* | | the reveal line turns at an inside corner | | IMG_4437 f001, IMG_4435, IMG_4436 |
| **C** | north, onto the court | the court's south wall, from the corner to H4's east wall; "Online Order Pick-Up" | ~8 m in a ~9.5-10 m wall | IMG_4435 (square-on), IMG_4437 f002, IMG_4424 (C, then H4 to Dillard's) |

Finish (all three): cream stack-bond tile wall, a chocolate-brown wainscot ~1.2 m on the piers, black
ZALES (deco A) over each opening, half-dome up/down sconces on the piers, a dark reveal at ~4.2 m, a
lay-in ceiling over the bays at the lane height under the taller court well. Steven at IMG_4437 0 s:
"that's the Frank's".

How the corners were read: in IMG_4437 f001 the reveal line over the bays is highest (nearest) at the pier
between A and B and lowest (farthest) between B and C: a convex corner then a concave one. A recedes
along H3 toward the entrance (the T-Mobile letters at its far end), so A is on H3's south wall; B is
square-on from the court looking east (IMG_4492 t026_001), so B faces west; C is square-on looking south
(IMG_4435), so C faces north. The only shape that does this is the court bulging south in front of C, the
mirror of the Gordon's / Claire's step on the court's north side.

Widths: no tile count was possible (the frames are too soft at the floor); the openings were scaled from
their own height (~3 m: B is about as wide as tall, C about 2.6-2.8 times; IMG_4435, IMG_4437 f001-f002,
IMG_4436) and from a shopper in IMG_4492 t026_001. **Confidence medium (±1 m).**

**H3 south row east of Zales** (IMG_4430-4432, IMG_4492 f030-f046), from the corner to the entrance:
A (Zales) | frameless-glass unit with blue chairs under a white stepped-zigzag band (two glass bays) |
the marble-pier unit (black glass, a centre grille, glass) | the scroll/"cloud"-top unit (narrow sidelight,
black brick-pattern grille) | T-Mobile's blank white mall face with magenta letters, at the lobby.

## 2. What the 1995 sources show

- **The Courier, Mar 20 1994, "Merchant List & Map"** (`refs/era_1995/directory/courier_1994-03-20_merchant_list_map.jpg`):
  57 Franks is drawn **set back** from the H3 row 56 Orange Julius - 55 Tee Tai's - 54 Optical Outlet -
  53 T.J.'s - 52 Pups & Pets; **56 Orange Julius is the corner unit**, with a face on H3 and a face on the
  court. The north side mirrors it (47 Gordon's proud, 48 Claire's with the step). Widths scaled from
  H3 = 12 m (schematic, ±1.5 m): 57 = 8.7, 56 = 5.9, 55 = 6.4, 54 = 8.2, 53 = 4.1, 52 = 11.7.
- **The game's own 1995 2D map** (`index.html` mall-data): s33 Franks 149,105 4x3 (x 2..10, z 10..16) behind
  s34 Orange Julius 153,103 3x5 (x 10..16, z 6..16): the same topology.
- **The Godot 1995 layout before Oct 8** (`tools/convert_map.py`): C2 ran to z = 10, H4 from z = 10, an
  alcove in front of Orange Julius.
- **Oct 8, 2026** (`tools/layout_oct8.py`; chat "1994 mall map updates"): the first pass put Orange
  Julius flush with Tee Tai's on H3 and Franks on the court's south wall behind it (that is this proposal,
  less Zales). Steven, 11:44: "You're incorrect about Frank's. Look at this layout." with an end-of-1994
  directory (units 53 Franks, 52 Orange Julius, 51 Tee Tai's; not in the refs pack). The session read it as
  "Franks flush in the row" and flattened the corner: everything at z = 6, C2 to z = 6, H4 from z = 6.
  **That is the one source against the bulge, and the picture itself is not in the repo.**

## 3. Mismatches found (1995 and 2026 as built, `layout_mall.json` / `layout_2026.json`)

Overhead: `production/qa/evidence/corner2026-overhead-before-after.jpg`.

| # | What | 1995 as built | 2026 as built | Footage / sources |
|---|---|---|---|---|
| 1 | Demising line Franks / OJ | x = 12 (Franks 10 m, OJ 4 m on H3) | **x = 10** (Zales 8 m, vacant s34 6 m): the 2D map's rects, which the Oct 8 re-cut never reached | lands on no 1995 wall: wrong |
| 2 | Stall count at the corner | 2 units (Franks, OJ) | Zales + a separate vacant s34 | Zales has its own bay A where s34 is: **one tenant over both 1995 stalls**, no vacant between Zales and the glass unit |
| 3 | The court's south-east corner | flush: Franks at z = 6, C2 ends at z = 6 | the same, with a guessed 1.6 m recess faked inside Zales' 8 m front (`zales()`, ws/g, Nov 1) | a ~4 m return (bay B) between H3's line and Franks' front: convex + concave corner |
| 4 | Bays | Franks one front, OJ one front | 2 bays (~3.4 m each) | 3 bays: C ~8 m, B ~3 m, A ~3 m |
| 5 | Franks' depth | 10 m (z 6..16) | Zales 8 m room | 6 m (z 10..16) if the front is at z = 10 (2D map 3 tiles; Courier 57 shallower than 56) |
| 6 | Franks' side on H4 | x = 2, z 6..16 (10 m, two framed ads) | the same wall | z 10..16 (6 m); the corner pier where C meets H4 (IMG_4424, IMG_4435 right) |
| 7 | H3 south row notes (`eras_2026.json`) | | s34 "all-glass, blue chairs, skyline molding"; s35 "cloud relief top"; s38 "mission stepped-scroll" | the glass/blue-chairs unit is **s35** (next to A); "cloud" and "mission scroll" are **one** unit, the narrow one by T-Mobile (s38 by order and width). The 2026 fronts are generic vacants, so only notes are wrong today |
| 8 | Tee Tai's depth | 8 m (z 6..14, `build_mall.gd` rect) | 10 m | not filmed; 2D map 10 m (5 tiles). Minor, 1995 only |
| 9 | T-Mobile (s38b) | Pups & Pets x 36..44, no frontage on H3 | the same rect | its blank white mall face is the last thing on H3's south side at the lobby (IMG_4431, IMG_4492 f037-f048); the Courier's 52 also fronts H3. Outside this brief (entrance / ws/exterior) |
| 10 | H3's length | 24 m from the court (x 12..36) | same | the Courier draws ~32 m (schematic). **Not changed** (shell, low confidence) |

Columns: the court's round column stands just west of the convex corner in the footage (IMG_4492
t026_001, IMG_4424); the game has a court column in the same quarter (court_s shots). Not moved.

## 4. Proposal

**The shell (both years, 1995 correction):** put back the court's 4 m bulge in front of Franks, keeping
every width the Oct 8 layout settled:

| Unit | 1995 | 2026 |
|---|---|---|
| floor patch x 2..12, z 6..10 | court floor, lay-in ceiling at the lane height (a leftover) | the same |
| s33, x 2..12, z 10..16 | **Franks**, front on the court at z = 10 (10 m), 6 m deep; side on H4 z 10..16 | **Zales bay C** (~8 m opening) |
| s34, x 12..16, z 6..16 | **Orange Julius**, front on H3 at z = 6 (4 m); its court side x = 12, z 6..10 a plain wall (unknown) | **Zales bay A** (H3) and **bay B** (the court side) |
| s35 .. s38 | unchanged | unchanged rects; notes corrected (mismatch 7) |

So in both years the corner has the same walls: Franks' 10 m front and Orange Julius' two 4 m faces; in
2026 Zales holds both stalls with an opening in each of the three walls, which is "the same as with Frank's
and then with Orange Julius, and the number of stalls".

**Storefronts and signs (2026):** `fronts26/store.gd zales_bay()`: per front a cream fascia from 3 m to the
lane ceiling, 0.6 m (C) / 0.5 m (A, B) piers with a 1.2 m brown wainscot, one ZALES (the Demo 43 spec)
centred over each opening at 3.6 m, a sconce on each pier; C's room 6 m deep, A's room 10 m deep with
its west side open for its first 4 m (that is bay B, which has no room of its own). Open, with cases (as
in IMG_4492; IMG_4437 shows it gated). The ws/g two-bay `zales()` stays for the flush layout.

**1995:** Franks keeps its builder (neon on the storefront only, Steven Oct 8), now on the z = 10 front;
Orange Julius keeps its 4 m H3 front; the two Courier ads on Franks' H4 side move to the 6 m wall.

| Item | Confidence |
|---|---|
| Zales is one tenant over Franks + Orange Julius, three bays | high (footage) |
| The corner has a return wall (convex + concave corners) | high (footage), Courier + 2D map agree |
| The return is 4 m (z 6..10), at x = 12 | medium (scaled; mirrors the north step) |
| Franks' front stays 10 m (x 2..12), depth 6 | medium (Courier 8.7 m, 2D map 8 m, footage ~9.5-10 m) |
| Orange Julius' court side was a plain wall in 1995 | low (no picture) |
| s35 = glass/blue chairs, s36 = marble piers, s38 = scroll top | medium-low (order and widths vs Steven's "definitely the Tee Tai's" for the scroll top) |

## 5. Questions only Steven can answer

1. **The Oct 8 call.** On Oct 8 you said "You're incorrect about Frank's" with an end-of-1994 directory,
   and Franks was made flush with Orange Julius and Tee Tai's. The 2026 footage shows a 4 m step at that
   corner (Zales' middle bay faces west, IMG_4437 / IMG_4492), and the March 1994 Courier map and the 2D
   game map both draw Franks set back with Orange Julius on the corner. Was your Oct 8 point the step, or
   something else (e.g. which side Franks' sign was on)? If the building didn't change, the step was there in
   1995 too. **Apply the step in both years?**
2. Did Orange Julius have a counter or window on its court side (x = 12) in 1995, or a plain wall?
3. Should the 2026 Zales be open (IMG_4492, with cases) or gated (IMG_4437/4435)? The build shows it open.
4. The H3 south row: the narrow scroll-top unit by T-Mobile — Tee Tai's (your narration) or T.J.'s (order
   and width on the Courier map)? And the glass unit with blue chairs next to Zales would then be Tee Tai's.
5. Can you send the end-of-1994 directory image again? It is not in the refs pack.

## How it was applied (Nov 4)

```bash
cd prototypes/godot-mall/project
python3 tools/layout_corner_c2.py      # layout_mall.json, data/eras_2026.json, posters.gd
python3 tools/make_layout_2026.py      # Zales gets three fronts and "bays": 3
# build every wing in both years (edges changed, so every wing's stand-in slots change), rebake 1 and 2
# (both years), capture stand-ins 1, 2, 4, 5 (both years); regenerate the directory map
# (tools/stores/directory/make_data.gd, ws/directory) so Franks / Zales sit right on the kiosk map.
```

## Applied (Nov 4, commit 2e743364 and after)

- `tools/layout_corner_c2.py` run on `layout_mall.json`, `data/eras_2026.json`, `tools/stores/posters/posters.gd`;
  `tools/make_layout_2026.py` regenerated `layout_2026.json` (Zales: three fronts, `"bays": 3`).
- OJ's court side is a plain wall in 1995 with walkable floor on both sides (the court patch and OJ's walk-up
  front), so the layout marks it `"solid": true` and `build_mall.gd` adds a collider for such walls (wing 1 1995
  `collide.json`: rect x 11.9..12.1, z 5.9..10.1). In 2026 the same edge is Zales' bay B.
- `eras_2026.json` notes: s35 = Tee Tai's (glass, blue chairs), s36 = Optical Outlet (marble piers), s38 =
  T.J.'s (scroll top), per Steven.
- Rebuilt every wing, both years: BUILD OK for wings 1-6 x 1995/2026. Wings 3 and 6 came out with node-id churn
  only (no mesh change) and were not committed; wings 1, 2, 4, 5 (both years) changed (wing 1 for real, the others
  through their stand-in halls and slots).
- Unbaked evidence: `production/qa/evidence/corner2026-applied-overhead.jpg`, `corner2026-applied-inhall.jpg`
  (footage | 2026 | 1995).

### Mac rebake and stand-ins (integration session)
`.autobake`: `wing1:night wing1:day wing1_2026:day wing2:night wing2:day wing2_2026:day wing4:day wing4_2026:day wing5:day wing5_2026:day`.
Then `tools/capture_standin.sh 4`, `4 2026`, `5`, `5 2026`, then `1`, `1 2026`, `2`, `2 2026`; export; publish.
Wings 3 and 6 need no rebake.

### For ws/directory
`tools/stores/directory/map.json` (both years) must be regenerated (`make_data.gd`) and the panels repainted
(`paint_dir.py`): Franks' rect is now x 2..12, z 10..16 behind a court patch; 2026 Zales covers Franks + OJ
(x 2..16) and the 2026 s34 entry is gone. Franks' "Jump to" spot (7, 3.8, facing south) still works but stands
6 m from the new front; (7, 7.5) would sit in front of it.

## Evidence (unbaked)

- `production/qa/evidence/corner2026-overhead-before-after.jpg`: 1995 and 2026 as built, the Courier
  source, the proposal.
- `production/qa/evidence/corner2026-frames.jpg`: the footage with A / B / C and the corners marked.
- `production/qa/evidence/corner2026-inhall-2026-before-after.jpg`, `corner2026-inhall-1995-before-after.jpg`:
  wing 1 unbaked, the current build vs the proposal applied on a scratch build (not committed).
