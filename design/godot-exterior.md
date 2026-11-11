# Godot mall: the outside (wing 3, "Outside") — Demo 44, Oct 24, 2026

> **Since Nov 4, 2026 (Workstream EXT-B, branch `ws/exterior`) the footprint, the roads, the lot and the
> outparcels are at their real places** (design/exterior-sequence.md §5 with Steven's §9 decisions).
> Where the older sections below give other numbers, the "Workstream EXT-B" section near the end wins.
> **Since Nov 8, 2026 (Workstream LOT, branch `ws/lot`) the lot is jointed concrete with fine joints, the trees, shrubs and planters
> are `tools/exterior/flora.gd`'s and the bank pad is 7,758 SF:** see "Workstream LOT" near the end; it wins
> over "The lot" below.
> **Since Nov 11, 2026 (Workstream EXT-DOCKS, branch `ws/ext-docks`) Dillard's dock is in a court behind the wing wall
> (the wall ends at x -52) and JCPenney's docks are on its east face:** see "Workstream EXT-DOCKS" near the end.
> **Since Nov 8, 2026 (Workstream EXT-LAYOUT, branch `ws/ext-layout`) the exit s41 stands at the end of a channel,
> the cinema box's west face is x -98 and Lynn's x -84:** see "Nov 8 refinements" near the end.

**Asked for (Steven, Oct 23–24):** the exterior phase — the parking lot and the building as seen
from it, built from the Oct 23 site visit (the report's shared exterior table), with the Cucos
neon on the east entrance's outside fascia ("add the neon that you have on the inside entrance up
there").

## What it is
- A third game file, **wing 3**: the lot round the whole building, the building's shell with a
  skin per face, the entrances, the Horton tank, the palm drive, the outparcels and the
  neighbours. Since Nov 1 (Workstream F) in both years: `wing3.tscn` (1995) and
  `wing3_2026.tscn` (the outside as filmed Oct 23 2026), and the year button shows outside too.
- **Getting out and in:** every exit door of the walkable mall offers "Go outside" when you stand
  at it (the same prompt as the wing seam: E / Enter, a gamepad's A, a tap): the main entrance
  (s39), the Sears hall's east entrance (s43), the cinema-side exit (s41) and the south entrance
  (s55). Outside, each door offers "Enter the mall · …" and loads the wing it belongs to. The
  "Jump to" menu has an "Outside" entry (the main entrance's walk).
- The doors and their spots are in `exterior.json` (`doors`), read by `scripts/player.gd` for
  every wing; `gen/w1` and `gen/w2` did not change, so the stand-in stamps stay valid.

## Frame and sources
- Metres, +x east, +z south (as the whole build). West Park Ave is the east road (the main
  entrance's palm drive), Bayou Gardens Blvd the south one, Armour Dr the north one. Sears is the
  north box, Dillard's the south-east one, JCPenney the west one.
- `tools/make_exterior.py` reads the 1995 map (`index.html` mall-data) and writes `exterior.json`:
  the building's outline as wall runs with the store behind each and the side it faces
  (`segments`), the footprint rectangles (`roofs`), the standalone block n2 west of the back lot
  (Steven, 4486 @112 s: the original 1969 standalone Sears, Unitech today), the doors, and the
  lot's walk grid (every map tile outside a building). Since EXT-B the grid is grown past the map on
  three sides and carries its own `origin` (wing 3's `wing.json`; `player.gd` reads it).
- `tools/exterior/exterior.gd` builds the scene from it; `tools/exterior/paint_exterior.py` paints
  the textures in `tex/ex/` (brick, block, stucco, the 6 m concrete lot panel with its tar joint,
  asphalt, mulch, grass, chain-link).
- Build: `godot --headless --path . --script res://tools/build_mall.gd -- --wing=3` →
  `wing3.tscn`, `gen/w3/`; add `--year=2026` → `wing3_2026.tscn`, `gen/w3y26/`. Bake:
  `AUTOBAKE="wing3:fastday"` (day only, like the game), and `wing3_2026:fastday` for 2026. Export:
  presets "Wing 3 Desktop" / "Wing 3 Mobile" (`w3.desktop.pck` / `w3.mobile.pck`), `?wing=3`, and
  "Wing 3 Desktop 2026" / "Wing 3 Mobile 2026" (`w3y26.*`), `?wing=3&year=2026`.
- Since Nov 1 the outside's scripts are all in `tools/exterior/`: `exterior.gd` (the shell, the
  fronts, the lot, for both years), `exterior_2026.gd` (what only 2026 has), `monuments.gd` (the
  road signs), `wall_fixes.py` (the footprint corrections `tools/make_exterior.py` applies),
  `door_view.gd` + `capture_doors.gd` (the view out of the exits), `paint_signs.py` (sign faces,
  lace, lot paint, 2026 skins into `tex/ex/`), `exshots.gd` (unbaked views, any height, top views).

## The building (the report's table; heights are parapets)
| Face | Built as | 1995 confidence |
|---|---|---|
| Store backs north of the Concourse row (z = 20) | tan-brown brick 6.5 m, dark soldier course at 4.7 m, peach pilasters and downspouts every 8 m, beige service doors with wall packs, yellow bollards | good (unchanged) |
| Store backs south of the Concourse (z = 100), the restrooms, Wesley Austin, TGO | blank tan brick 5 m | good |
| Dillard's wing rear lane (z = 70) | back doors 3026–3029 on stoops | good |
| Woolworth block | red brick 9 m, compactor enclosure | good |
| Sears | white painted block 9 m; loading dock on the north wall (canopy on pipe columns, dock 1.2 m, yellow rail); "Sears" on three faces | dock good; walls a guess |
| Cinema box | salmon brick 9 m, peach pilasters, hooded exit doors, the ramp with its rail | good (original) |
| Cinema-wing exit (s41) | brown aggregate precast fascia, white soffit with cans, clear-anodized curtain wall, poster case on the buff return, the 3-loop bike rack | good (original) |
| East facade (x = 30 / 44, main entrance → Cucos) | cream pilasters every 4 m, tan recessed panels, white wainscot, cream stepped cornice | rhythm likely original; finishes a guess |
| K&B bay (s25) | the original folded-plate cream canopy with a can in each pleat, raked windows, tan bulkheads, cream band with the purple oval and "K&B" | canopy good; sign a guess |
| Cucos (s42) | the 2026 massing: 8 m pilaster rhythm, six tall windows in white surrounds, two glazed garage-style doors, stepped parapet at the sign bay; in Cucos's colours (warm stucco, teal band and box awnings, as its mall front), "Cucos Mexican Cafe" | massing good; colours a guess ("repainted") |
| East entrance (s43) | peach fascia, the **Cucos neon** 2.2× centred over the doors, dark-brown curved eyebrow canopy 8 m, bronze 2-tier storefront with 4 doors | Steven's decision; fan ornament era |
| Main entrance (s39) | **placeholder**: flat cream canopy on square columns, glass storefront, "SOUTHLAND MALL" once, dark bronze on the canopy fascia (SMALLFIX, Nov 8 2026: a second, bigger copy on the wall behind the canopy was removed; the canopy cut it from the lot) | 1995 form unknown (today's porte-cochère is 2000s) |
| South entrance (s55) | 10 m pavilion, thin white cornice slab, cream pilasters banded dark at the base, doors in a porch, tie-rod canopy, the drop-off bulb with a live oak | mass and position original; skin a guess |
| JCPenney | cream speckled brick (long thin units), 7.5 m west / 9.5 m rear; west customer entrance under a flat maroon fascia, roll-up receiving door, podocarpus columns; south entrance under the red arcade on square columns; north Package Pick-up (coral fascia) and docks 1–2 under a red canopy; "JCPenney" west and south | brick good; signs are 2012-era shapes with the 1995 word |
| Dillard's | 3 storeys peach EIFS scored as ashlar, two cream cornice bands, "Dillard's" east and south; the cast-iron gallery on the east face (bronze columns, lace frieze and brackets, pebble paving, bollard lights), blind panelled doors under sunburst fanlights, flagpole island | gallery as filmed (Steven wants it); 1995 D.H. Holmes-era skin unknown |

## The lot
- Jointed exposed-aggregate concrete panels ~6 × 6 m (one texture per panel, tar joint on two
  edges) over the whole lot; white stall stripes (the 1995 striping under today's yellow) in
  double rows perpendicular to the buildings, row ends ~40 m apart; yellow-curbed pill islands at
  the row ends with live oaks or shrubs; white tapered lot poles ~11 m on square yellow pedestals
  with twin period shoebox heads (sodium light at night).
- The West Park entry drive: 2 lanes, double yellow centreline, 12 sabal palms a side in yellow-
  curbed mulch medians, crape-myrtle islands at the entrance, a signal at the road.
- Bayou Gardens frontage: a long mulched island with 19 sabal palms and 4 live oaks. The pine
  island with the hydrant at JCPenney's north-west; the lawn island with a magnolia and pines.
- The Horton tank (1970, CB&I): 11 m dia × 11 m, 4 ring courses, conical roof, caged ladder,
  riser, in a chain-link yard at x −124..−96, z −18..14 with the peach utility building and the
  conduit pole on its yellow base.
- The water tower (white pedestal, blue "NORTH TERREBONNE" seal) at (−300, −140), the skyline
  landmark; the camera's far plane is 600 m outside.
- Outparcels: the drive-thru bank west of the back lot with the lattice cell tower, the 1-storey
  strip centre along the south edge, Big Lots (Kirchmann's furniture in 1995; since Nov 1 across West Park Ave), Ground
  Pat'i at the SW corner with its 4-sided cube pole sign; the charcoal apartments behind a wood
  fence and the soccer fields behind a black picket fence to the west, St. Bernadette's cream
  building with the green roof beyond.
- Kerbs round the building; a sidewalk's width of panel between them and the walls.

## Workstream F (Nov 1, 2026): monument signs, exits, fake walls, textures, the 2026 outside

Sources: refs pack (branch `refs`) notes_A (IMG_4406, 4416, 4426), notes_C (IMG_4486), notes_D
(whole), notes_E (IMG_4490, 4492, 4493), `new/monument_candidates/`, `new/dillards_exterior/`,
`era_1995/other/other_3.jpg`, `era_1995/directory/courier_1994-03-20_merchant_list_map.jpg`,
the Morguard site plan (`design/exterior/morguard-site-plan-2024.png`) and the 2026 directory map
(`refs/derived/photos/IMG_4455.jpg`, legible: Unitech north-west of Lynn's, the roads).
Evidence: `production/qa/evidence/wsF-*.jpg` (all unbaked).

### Monument signs (`tools/exterior/monuments.gd`)
Steven (Nov 1): the structure is good to build; no sign face is legible in the footage. Three
double-faced monuments, square to their road so both directions read them:
| Where | At | Notes |
|---|---|---|
| West Park Ave, the palm drive | (90, −11.5), north corner of the drive mouth | |
| Bayou Gardens Blvd | (−126, 175.5), east side of a new drive cut through the palm island in front of the south entrance (`BAYOU_DRIVE` x −150..−134) | the drive's place is a GUESS (the site plan shows drives off Bayou Gardens; this one lines up with the Corn Dog 7 entrance) |
| Armour Dr | (−20, −179), west side of the back lot's drive | |
- **Structure (GUESS, in the mall's materials):** a 5 m tan-brick plinth and two brick piers with
  cream stucco caps, a cream panel between them with a stepped cornice, liriope and mulch in a
  grey-curbed bed, a ground uplight on each face at night.
- **1995 face (GUESS):** the mall's own fan logo from its March 1994 "Merchant List & Map" (half-round
  arch, a fan of seven stepped wedges, SOUTHLAND with the big S and D, M A L L between rules). The
  print is black and white: dark bronze on cream is a guess.
- **2026 face (GUESS):** the same mark white on navy, after the navy fan banner on today's main
  entrance pier (IMG_4406 f002). Today's real monument faces are not in the footage.
- **United Artists Southland Cinema marquee** (1995 only), on Armour Dr at (−84, −179), north of
  the cinema box: two black square posts, a black-framed white cabinet, the header "UNITED
  ARTISTS ✶ Theatres / SOUTHLAND CINEMA" from `other_3.jpg`. The photo is summer 1997 (Spawn, Air
  Bud, Men in Black, Air Force One), so the letter board carries invented house lines only (NOW
  SHOWING / MATINEES DAILY / WELCOME): no film titles (IP rule; those films are not 1995). Where
  it stood is a GUESS (the photo shows grass, a bayou bridge and a road).

### Exits (Steven, Oct 28: orientation exactly as the exterior map)
Checked each door both ways (exterior.json `doors`, `out` / `inside` spots and facings), and
`tools/qa/doortest.py` crosses wing 1 → outside → wing 1 through the main entrance:
| Door | Outside you land | Facing | Fixed on the outside face |
|---|---|---|---|
| Main entrance s39 (West Park side) | (45.5, 0), 1.5 m off the doors | east, down the palm drive | 2026: today's porte-cochère (exterior_2026.gd); 1995 placeholder unchanged |
| Sears-hall east entrance s43 (Cucos / Red Seal side) | (41.5, −91), in the recess | east | the north return is now the Sears box's white painted wall with the charcoal eyebrow band (4406 f031-035), not tan brick; 2026: the gold fan and diamonds instead of the Cucos neon |
| Cinema-side exit s41 (the Sears hall's other end) | (−81.5, −91) | west, to the bike rack and lot | the north return is the Sears box's white painted brick (4416 f002) |
| South entrance s55 (Corn Dog 7, Bayou Gardens side) | (−142, 93.5), inside the porch | south | the pavilion now projects 7 m with its loggia (4489 f031-040), big banded pilasters, the thin white cornice slab; the drop-off bulb moved out past it |
"Both entrances on the Cucos/Red Seal side" is read as the Sears hall's two ends (s43 by Cucos and
s41 by the cinema): the hall that runs along the Cucos / Sears side. Coming back in lands you at
each door's inside spot facing into the mall (unchanged).

### Looking out (`tools/exterior/door_view.gd`, `capture_doors.gd`; small hunks in `build_mall.gd`)
The inside wings showed a 12 m vestibule stand-in past each exit (doors_out: a concrete floor, a
canopy, sodium lights) and then sky. Now three pictures of the real lot close that box: a front
picture at the floor's far edge (12 m) and one on each side, each captured from the outside
(wing 3) by an off-axis camera at eye height on the doorway, framed exactly on its face, so from the
doors the lot is where it is outside. The floor and canopy stay and the pictures are a dynamic,
unshaded mesh (`gen/w<n>/dyn_doorpic.res`), so **the inside wings' lightmaps are unchanged**.
- Pictures: `tex/standin/door_w<wing>_{day,night}.png` (1995) and `y26_door_w<wing>_day.png` (2026),
  one row per door, [front | left | right] 384 px each (wing 1: 1152 × 1152, wing 2: 1152 × 384).
  Not in git: they go with the stand-in pictures on `godot-build`.
- Capture: `tools/capture_standin.sh 3` (both inside wings, night and day) and `3 2026`, after the
  outside is baked. Without wing 3's lightmap it captures an unbaked sun and sky and says so (the
  cloud session's pictures are unbaked).

### Fake walls (Steven, Oct 28: "random fake walls that aren't supposed to be there")
`tools/make_exterior.py` traces the building from the 1995 map's store rectangles; where they stop
short of the real building it left notches with walls that do not exist. Every face was walked in
the unbaked build and compared with the footage, the site plan and the directory map. Fixed in
`tools/exterior/wall_fixes.py` (applied by make_exterior.py), before/after in
`production/qa/evidence/wsF-wall-*`:
| # | Wall that was not there | Real | Fix |
|---|---|---|---|
| F1 | a 16 × 14 m notch in the east facade behind Philly's / Mastercuts / Father & Son (x 30..44, z −54..−38) | the facade runs straight from Hypervelocity to The Red Seal with one roofed trash / transformer bay ~8 × 6 m (4406 f011-015, 4493 f030-032) | filled to the facade line; the bay kept (8 × 6 m, roofed, brown louvers, louvered doors, dumpster) |
| F2 | a 12 × 12 m notch behind Radio Shack / GNC (x 32..44, z 26..38) | one flush box, Shoe Dept. today (4492 f081-099; the directory's flush block) | filled |
| F3 | a 14 m west-facing wall and an 8 m step between JCPenney's south face and the south entrance (x −154, z 74..88) | JCPenney's brick runs to the pavilion past a short set-back link (4489 f001-035); site plan: JCPenney about level with the wing | JCPenney's box carried south to z 92, a cream (2026 EIFS) link beside the pavilion |
| F4 | a 4 m jog in the wing wall at the restrooms (x −58..−42) | the low wing wall runs straight to the service alley (4489 f059-069) | filled |
| F5 | the map's standalone block n2 west of JCPenney's back lot | parking there; Unitech stands north of Lynn's by Armour Dr (site plan, directory map, 4486 f010) | moved: Unitech, a long low white block at x −68..−32, z −176..−150 |
| F6 | Big Lots, a 40 × 24 m box in the north-west lot | parking there; Big Lots is the strip across West Park Ave from Lynn's (4406 f031-035, 4413 f005-008) | moved across West Park Ave (x ≈ 152); in 1995 it is **Kirchmann's**, a furniture store (Steven, Nov 1), sign letters and colours a GUESS |
| F7 | Ground Pat'i inside the south-west lot | across the road at the corner (4489 f071-083) | moved across Bayou Gardens |
| F8 | the drive-thru bank mid-west | the site plan's 870 SF drive-thru at the south-west corner by Bayou Gardens (4487 f046-053) | moved there with its cell tower |
Not changed, for Steven: the old Sears box's east face is 14 m behind Cucos's front (x 30 vs 44),
while the site plan and directory map have Lynn's about flush with the east facade. Moving it
would put a 14 m hidden slab between Workstream E's walkable Sears and its outside wall.

### Textures and details
- **Dillard's cast-iron lace gallery** (both years; was a dark band): a lace frieze of scrolled
  roundels (alpha texture `lace_frieze.png`) under a brown fascia on the front and both ends, a
  quarter-round scroll bracket each side of every column (`lace_bracket.png`), flared Corinthian-
  like caps, octagonal bases, a terracotta soffit (refs/new/dillards_exterior t056_021-031).
- **Rear service lane** behind the Dillard's wing: painted brick in three bands (salmon base,
  light-pink middle, cream top) with reveals and white downspouts (4490 f006-012). Both years; the
  paint in 1995 is a GUESS.
- **Fire lanes and curbs:** a ladder hatch 1.2 m wide past the curb on every customer face (the east
  facade, Dillard's, JCPenney, the south faces, the cinema's west wall), kept clear of the doors.
  2026: pink on red curbs (as filmed). 1995: yellow on yellow curbs, a GUESS from the yellow curb
  and ladder still on JCPenney's north side (4487).
- **ADA:** the blue wheelchair symbol in the stalls nearest each entrance (both years, the exact
  stalls a GUESS). 2026 only: the yellow truncated-dome mats at the doors' curb ramps.
- **Palm drive:** stop bars and a white ladder crosswalk at the mall end (4492 f053-066).
- **LED twin-arm poles** (2026 only, 4487 f030, 4488 f004): the same pedestals, two up-curved arms
  with flat LED heads; 1995 keeps the period shoebox heads. Stall lines yellow in 2026, white in 1995.

### The 2026 outside (`--year=2026`, `exterior_2026.gd`)
The same shell with what only today has: the main entrance's two-storey porte-cochère (tan EIFS,
cream / charcoal tile-banded columns, black beam, clerestory, "SOUTHLAND MALL" on a dark fascia,
the navy fan banner); T-Mobile's exterior entrance (unit 1029, magenta letters, grey shed awning on
tie-rods); Shoe Dept.'s white ACM front with three stainless-canopied bays and "SHOE DEPT."
(unit 1003A); Hypervelocity on K&B's original folded-plate canopy (cream letters, racing check);
The Red Seal on Cucos (white stucco, black pilasters and band, red awnings, the R seal); the gold
fan on the east entrance; Lynn's Interiors on the old Sears; Unitech's sign; the two-tone EIFS wing
wall with diamond wall-packs; the south pavilion in peach EIFS with dark tile bands and the east
bay's tie-rod canopy; JCPenney's magenta letters; pink fire lanes, LED poles, yellow stalls, tactile
mats; the navy monument faces; no United Artists marquee. The 1995 outside is unchanged apart from
the fixes above.

### Door spots for Workstream E (old Sears) — superseded by EXT-B: `door_spots` is empty, s1e / s1x are real doors
`exterior.json` `door_spots` (from `wall_fixes.DOOR_SPOTS`) holds two places on Sears's east face
(x = 30): the customer entrance at z −124..−118 (the Lynn's script sign and black awning, 4413
f033, 4406 f031-035) and the side exit with its roll shutter at z −106..−103 (4413 f001-008). The
outside draws a glass entrance at each (a black awning in 2026); `player.gd` does not read them.
To wire one up, E moves it into `doors` with its inside spot, wing and facings (as the other doors,
`tools/make_exterior.py`) and adds its name to `DOOR_NAMES` in player.gd.

### Pack size and bake
- Wing 3 (1995): ~4 more draw groups (signs, lace, paint) and 8 new small textures in `tex/ex/`
  (the largest 1024 × 1024); the lightmap grows only with the new static surfaces (monuments, porch,
  lace, bay), all at the outside's medium texel. Pack numbers: see the report.
- Wing 3 (2026): a new pack and a new bake (`wing3_2026:fastday`), the same size as the 1995 one.
- Wings 1 and 2: +1 dynamic mesh each and the door pictures (≈1.3 MB per mode in wing 1, compressed);
  no rebake needed for them (static meshes unchanged), but their stand-in stamps change.
- The bake is the same kind of job as before (one day bake per year); it still needs the 12 GB swap
  in the cloud, so bake on the Mac.

## Workstream EXT (Nov 3, 2026): the outside in walking order
`design/exterior-sequence.md`: the Oct 23 videos sliced and joined into one loop from the cinema exit,
the compass (the game's north is real south; the footage is afternoon sun from the game's N/NE), the
real footprint from the footage and the site plan, and the mismatch list with proposed numbers
(Sears 115 × 50 flush with the facade and ~10 m from the exit with the dock on its west face; the
cinema box 45 m long and flush; JCPenney 60 × 120 to z −14; Dillard's 87 × 58 with the gallery and
entrance on the south face; Big Lots / Kirschman's across Armour Dr; the lot larger on three sides).
Analysis only; nothing here changed yet. Evidence `production/qa/evidence/wsEXT-*.jpg`.

## Workstream EXT-B (Nov 4, 2026): the real outside, both years

Branch `ws/exterior` from `int-51`. Brief: the outside at the level of the interior, from the earlier
attempts. **What earlier attempts left:** `demo44-exterior` (Oct 24) and `ws/f-outside` (Nov 1) are merged
in `int-51` (the shell, the skins, the monuments, the 2026 layer); `ws/ext-sequence` (Nov 3) is the
analysis only (`design/exterior-sequence.md`, merged) with Steven's decisions (§9) and a draft brief for a
build session. No build branch was ever pushed. This is that build: §5's mismatches #1–#15 as decided.

### Footprint (`tools/exterior/wall_fixes.py` FILLS, DROP, STANDALONE, DOOR_MOVES; `make_exterior.py`)
| # | What | Now (x0, z0, x1, z1) | Note |
|---|---|---|---|
| 1 | Sears / Lynn's | −72, −146, 44, −96 (115 × 50, flush with the facade) | the dock moved to the **west** face, x −80..−72, z −126..−100: white canopy on pipe columns, raised dock, 4 dock doors with seals, the truck well with the yellow 2-rail on red curbs, a box truck (Lynn's lettering in 2026); the white painted-brick return −80..−72, −100..−96 with the 3-loop bike rack along it |
| 2 | Cinema box | −80, −86, −52, −42 | one straight 44 m salmon-brick west wall from the exit, 6 pilasters, 5 hooded exit doors, the FDC, the ramp with knee wall and rail, the poster case beside the doors |
| 3 | Back lot, Unitech | Armour Dr at z −252; Unitech −85, −236, −57, −207 | the Armour monument at (−33, −243), the UA marquee (1995) at (−90, −243), the Armour drive x −26..−14 |
| 4 | Kirschman's / Big Lots | the strip across Armour Dr, centre (−20, −288), 60 × 28, facing the mall | gable sign on the side exit's axis, 3-arch loggia, white hoods; 1995 **"Kirschman's" FURNITURE** (spelling Steven's; letters and colours a GUESS), 2026 BIG LOTS! |
| 5 | JCPenney | −214, −14, −154, 106 + the rear block −228, −6, −214, 32 | north face: docks 1–2 (red canopy, seals, numbers, rail), the compactor, the Package Pick-up recess with the coral ribbed fascia, the wordmark; west: the roll-up on the rear block, the tree-side entrance (maroon fascia) at z 42–50, the wordmark, podocarpus; south: the red arcade near the SW corner, the hedge, the wordmark; the pine island with the hydrant at the NW corner. The map's block n2 is dropped (it would have joined the rear block) |
| 6 | Horton tank | yard −141, −32, −121, −9 | the utility building, the conduit pole and the walk to the docks with it |
| 7 | Dillard's | −38, 80, 44, 138 | the gallery on the **east and south** faces; the entrance portal (two peach piers, cream entablature, "Dillard's", 4 door pairs) on the south face at x −15 = s2s; the s2e gallery doors on the east face; the flagpole island (3 poles) at the SW corner; the covered dock with a trailer and the roll-off on the west side. **Changed from §5:** the west face stays at x −38 north of z 118 (not −43), so the 4 m service lane between the wing's back (x −42) and Dillard's stays open to the south, as filmed (4490 f006-028); §5's −43 would have closed it (the built wing reaches −42). **Decided** (Steven, Nov 4) |
| 8 | Wing wall, pavilion | the wing wall z 118 from x −134 to −42; the pavilion −146..−134 solid to z 112, the loggia to z 118; the link off JCPenney −154..−146 to z 110 | Steven: "from JCPenney to the Dillard's side, at least 3/4" — 92 m of ~108 m. The doors at the loggia's back (z 112); the bike rack on the link; the drop-off bulb moved out to z 127–131 |
| — | East facade between the Shoe Dept box and Dillard's | 30, 50, 44, 80 filled flush | the plan's flush block; 2026 the blank white ACM wall (4492 f081-108) with the yellow-hatched loading lane in front; 1995 the facade's panels (**decided**, Steven, Nov 4) |
| 9 | The map | −390..130 × −270..240 (was −296..106 × −200..202) | West Park Ave x 112 (4 lanes, curb ~106), Bayou Gardens z 216, Armour z −252, the west lot to x −360; the apartments' land north-west (x < −120, z < −150) is lawn behind a wood fence with 6 charcoal blocks; the soccer fields and St. Bernadette's beyond the west edge |
| 10 | Ground Pat'i | ~~(146, 244), across both roads at the SE corner~~ **moved Nov 8 (Workstream LOT): across Bayou Gardens opposite Dillard's, (20, 242)** | see "Workstream LOT" 7 |
| 11 | Bank pad | 64, −78, 98, −50 on West Park opposite K&B / Cucos | both years, brick, a 3-lane drive-thru canopy, **no name** (Steven: "a bank in 1995, not Chase") |
| 12 | East entrance recess | not changed (4 m) | the Sears box is flush now, so the recess reads; a 10 m recess would cut into wing 1's vestibule. **Decided** (Steven, Nov 4): stays 4 m |
| 13 | Sun | wing 3's sun from the game's N / NE, ~40° up (`build_mall.gd`, `exshots.gd`) | Steven: switch to the afternoon. Only wing 3; the inside wings keep theirs |
| 14 | Water tower | (−440, 60), W of JCPenney | a far landmark |
| — | SW outparcels | the drive-thru bank and cell tower at (−346, 166), the strip centre x −321..−303, z 100..155 facing east | no tenant names (none legible) |

### Doors (`DOOR_MOVES`; the inside spots, wings and facings unchanged)
| Door | Outside face | Out spot | Facing |
|---|---|---|---|
| s55 south entrance | z 112 (loggia back), x −144..−136 | (−140, 114.5) | south |
| s1e Lynn's / Sears customer entrance | x 44, z −121..−115 | (46.5, −118) | east |
| s2e Dillard's gallery doors | x 44, z 95..101.4 | (46.5, 98.2) | east |
| s2s Dillard's portal | z 138, x −17.4..−12.6 | (−15, 140.5) | south |
s39, s43, s41 and s1x are where they were. `player.gd`'s door code needs no change (it reads `out` / `inside`).

### The lot (`exterior.gd` `lot_field`)
Stalls are laid by fields instead of hand-placed rows: the front lot (x 52..104), the back lot behind Sears
(to Armour Dr), the staff lot (between JCPenney, the tank and the cinema), the NW lot, the west lot behind
JCPenney and the south lot, each in 18 m double rows (2.7 × 5.5 m stalls), cut wherever a keep-out
(the building + 8 m, the tank yard, the drives, the pads, the dock well, the drop-off, the apartments'
land) is in the way. Every run ends in a curbed island; every other row's islands carry a lot pole
(1995 shoebox, 2026 LED), the others a live oak or a shrub; a storm grate in each aisle every ~30 m.
Stop signs at the Bayou Gardens and Armour drives; trash cans at every entrance; ADA symbols near each
door. Wing 3 now: 64 wall runs, 107 trees, 170 lights (1995) / 173 (2026), +45 % mesh data
(gen/w3 3.0 → 4.4 MB, gen/w3y26 2.4 → 3.8 MB before compression).

### Shared files touched (small, separate hunks)
- `tools/build_mall.gd`: wing 3's `wing.json` carries `origin`; wing 3's sun direction.
- `scripts/player.gd`: reads `origin` from `wing.json` when present (only wing 3 writes it).
- `exterior.json`, `gen/w3/*`, `gen/w3y26/*`, `wing3.tscn`, `wing3_2026.tscn` regenerated.

### Verification (all unbaked, cloud)
- `--wing=3` and `--wing=3 --year=2026`: BUILD OK.
- `tools/qa/ext_door_test.gd` (new, headless): every door's outside spot is on the grown grid and clear,
  2 m further out walkable, the inside spot walkable in its wing, standing outside finds the door; then
  the walk wing → "Go outside" → E → wing 3 at the out spot → "Enter the mall" → E → back at the inside
  spot. PASS for s39, s41, s43, s55, s1x, s2s (1995) and s39, s55 (2026).
- Existing: `wsS_thresholds_test.gd` (1995, 2026) WSS TEST OK, `interact_test.gd`, `int_d49_test.gd`,
  `flags_test.gd`, `menu_unit_test.gd` OK.
- Evidence: `production/qa/evidence/exterior-{1995,2026}-*-unbaked.jpg` (17 views a year: the main
  entrance, the east facade both ways, the s43 recess, Lynn's / Sears east face, the north face and the
  view across Armour Dr, the cinema exit and dock, the cinema wall, JCPenney north with the tank and west,
  the pavilion, Dillard's portal and east gallery, the front and west lots, the whole lot from above).

### For the Mac (integration)
1. Bake `wing3:fastday` and `wing3_2026:fastday` (the old wing 3 lightmaps no longer fit: every face
   moved). The day sun now comes from the game's N / NE.
2. `tools/capture_standin.sh 3` and `tools/capture_standin.sh 3 2026` after the bakes: the door pictures
   of wings 1, 2, 4, 5 look out on the new lot (s55, s1e, s2e, s2s moved).
3. Wings 1, 2, 4, 5 need no rebake (their static meshes did not change).

### Decided (Steven, Nov 4, 2026)
- Sears's north face (not filmed): plain white block, the side exit with its shutter hood, a "Sears"
  sign toward Armour Dr: right as built.
- The east entrance recess stays 4 m deep.
- The 1995 wall between the Shoe Dept box and Dillard's (z 50..80) is the facade's panels.
- Dillard's west face stays at x −38 north of z 118, keeping the service lane open.

### Still guesses
- Kirschman's sign letters and colours, the 1995 bank's look, the strip centre's tenants (none named).

## Workstream LOT (Nov 8, 2026): a real parking lot, not a toy

Branch `ws/lot` from `main` (f96a04b). Brief: Steven's six complaints about the outside, both years. Evidence
`production/qa/evidence/wsLOT-*.jpg` (all **unbaked** unless named `-baked`; the cloud does not bake).

### 1. The lot: concrete without the "tile lines" (Steven: "it looks like Roblox / Minecraft")
- **Decided (Steven, Nov 8): the lot is concrete**, both years, as filmed (4487 f034, 4492 f060): jointed
  exposed-aggregate panels. The brief first asked for asphalt and this branch built it; Steven corrected it. The
  asphalt set (`ex_asphalt_*`) now covers only the roads and the Bayou Gardens / Armour drives; the palm drive is
  the lot's concrete (4492 f060). The asphalt albedo imports at 1024 px.
- The "tile lines" were the old panel texture's thick black tar joints, imported with no mipmaps, so they aliased
  into a hard grid. `paint_lot.py concrete()` paints one 6 m panel at 2048 px (`ex_concrete_alb.png`, ~3 mm/px):
  exposed aggregate, weathering, and half a thin (~6 mm) dark-grey sealed joint on every edge, so the joint is
  ~12 mm between panels and fades with distance through the mipmaps. Roughness and a shallow-groove normal at 512.
- `lot_ground` lays one panel per 6 m cell, each turned a random quarter turn (the half joints on every edge keep
  the joints whole), tinted by a slow two-octave mottle and its own shade; about one panel in twelve is a lighter
  replacement (notes_D). 1995 is cleaner and lighter, 2026 weathered and a shade darker and warmer. No ground
  under the building.
- Stall paint: worn yellow in both years (Steven: the 1990s lot was yellow; **2026 fresh yellow over the ghost
  white grid, from the footage, confirmed by Steven Nov 8**), each line faded a little differently and laid with a
  centimetre or two of hand error (`ex_paint_worn.png`).
- Wear: sealed and alligator cracks along each face out in the lane, oil stains in ~28 % of the stalls
  (`ex_lot_decals.png`; its patch cell is no longer used on the lot).
- A 1.65 m **concrete sidewalk** (`ex_walk`, its own mesh `ex_walks` at a finer lightmap texel) runs between each
  wall and its curb and round the outside corners.
- Evidence: `wsLOT-lot-concrete.jpg` (current); `wsLOT-asphalt-before.jpg` / `-after.jpg` show the superseded
  asphalt pass.

### 2. No rainbow sheen
- The "oil slick" was **moire**, not specular: all 30 textures in `tex/ex/` were imported lossless **without
  mipmaps**, so the brick's mortar grid (and the lot's tar joints) aliased into coloured arcs at distance
  (`wsLOT-sheen-*.jpg`, the crops show the arcs). They now import VRAM-compressed with mipmaps, as the interior's
  textures do.
- Material audit (`fill_mat`): metallic 0 for everything that is paint, masonry or concrete (chain-link, dark
  coping, doors, wall packs, painted pipes and poles, lamp heads, the tank, dock steel, the black fence, roof
  metal, ACM, the lace), roughness 0.55-0.95; brick / stucco / EIFS / concrete 0.85-0.95. Real metals (mullions,
  bronze, stainless, gold leaf) and glass keep theirs. No material uses anisotropy.

### 3. Trees (`tools/exterior/flora.gd`)
- The outside borrowed the interior's potted palm (a 7 cm trunk under 2 m fronds) and the card bush whose flat
  horizontal top card was the **dark cap**. Now: **sabal palms** (a 0.45 m trunk with boot scars, a skirt of dead
  leaf bases, ~27 folded fan leaves on petioles in three tiers), **live oaks** (low limbs, a wide crown of
  randomly turned crossed clusters, no top card), pines, clipped shrubs on a dome core, grass clumps, podocarpus
  columns. One 1024 px atlas, `ex_foliage.png`; trunks are baked (`ex_props`), leaves unbaked (`ex_flora`).
- **Far crowns:** the alpha-tested cards' mipmaps averaged thin fronds below the threshold, leaving bare poles at
  60-110 m (`wsLOT-trees-far.jpg`). Fixed with solid cores in the atlas cells and **alpha-to-coverage** on the
  foliage material (needs the project's MSAA, on: `msaa_3d=1`; without MSAA it falls back to the plain alpha test
  and the cores still hold most of the crown). No impostor was needed, so no cull distance was raised.
- Cost: every plant outside together is ~18.5k triangles, one draw call for the leaves; `dyn_ex_flora.res`
  1.2 MB with compressed attributes (`build_mall.gd`, one line).
- **Tree options. Decided (Steven, Nov 8): option A**, the procedural sabals, live oaks and shrubs of flora.gd
  (as built). B (the Quaternius pack) is dropped: none of its files were committed. C (the Blender sabal sketch)
  stays in `tools/exterior/options/` as a later upgrade path. The sheet (`wsLOT-tree-options.jpg`, near and far at
  the palm drive):
  | Option | What | Licence | Cost |
  |---|---|---|---|
  | **A (chosen, built)** | flora.gd, procedural, this branch | ours | 18.5k tris all plants; atlas 1024 (~1 MB) |
  | B (dropped) | Quaternius "Ultimate Stylized Nature" PalmTree_1 (also bushes, oaks) | CC0 1.0 (quaternius.com; fetched here from the MIT-wrapped GitHub mirror walterpalladino/godot-quaternius-ultimate-stylized-nature since quaternius.com is blocked from the cloud) | 760 tris/palm; trunk texture 4096 px, must be cut to 1024; a stylised **coconut** palm, not a sabal |
  | C (later upgrade path) | a Blender-built sabal, every leaflet geometry (`tools/exterior/options/bl_sabal_option.py`, a sketch) | ours | 14.5k tris/palm, ~680k for the palms: needs an LOD or impostor first; ~1.1 MB a variant |
  Shots: `tools/exterior/options/option_shot.gd` (A and C). Poly Haven and Kenney were not reachable from the cloud.

### 4. Planters
- Every curbed island is `flora.gd planter`: a **low (10 cm), wide (30 cm)** concrete curb, mulch, 3-5 shrubs and
  grass clumps with size and tint variation. Lot row ends alternate: a pole with liriope round its pedestal, a
  live oak with shrubs and grasses, a sabal with shrubs (rows over 40 m), shrubs and grasses.
- Curb colour: **grey in 1995** (a GUESS, no period photo; accepted by Steven, Nov 8), **painted yellow in 2026** as filmed (4492 f060-066, the
  palm drive's medians; 4487 the lot's islands). The roads' islands stay grey.
- The beds are unbaked meshes (`ex_beds`, see item 6).

### 5. The bank pad stays, shrunk
- The "stray" brick box with the flat canopy north-east of the Hypervelocity face is EXT-B's bank pad (§5 #11),
  the Morguard site plan's bank pad on West Park ("#3000 CHASE BANK ... NOT A PART"). Steven first asked to remove
  it, then (Nov 8): **keep it; shrink it to that footprint, 7,758 SF; one storey; brick and nameless in both years;
  the drive-thru canopy on the lot side.**
- Built (`bank_pad`, `BANK`): a 28.0 x 25.75 m pad (721 m2 = 7,758 SF) holding a 14 x 14 m one-storey brick building
  (4.2 m, thin coping, no roof box), a lawn, and a flat white canopy over three north-south lanes on its **west** side
  (toward the mall's lot) with two kiosk islands. It was a 34 x 28 m pad, a 16 x 18 m box to 6.4 m, the canopy on
  the road side. *Read as:* 7,758 SF is the whole pad, not the building alone (a 7,758 SF building would be larger
  than the old one, not smaller). **Confirmed (Steven, Nov 8).**

### 6. Facade smears (the bake)
Read off the Demo 52 bake (`wsLOT-facade-before-baked.jpg`) and the geometry; **not yet confirmed by a bake**.
- **Walls behind base boxes:** every wainscot, base band and door laid flat on a wall had the wall face running
  on behind it. Those texels are inside geometry; the bake marks them invalid and the denoiser smeared their
  black up the visible wall at ground level. Walls are now drawn last (`wall` defers, `flush_walls` draws), cut
  behind such covers: 128 stretches in 1995, 110 in 2026.
- **Dillard's ashlar scoring** was boxes sunk flush into the face (coplanar: z-fighting, strips of invalid
  texels all up the wall): now thin lines 1 cm proud, unbaked.
- **JCPenney's black parapet band:** the taller masses' roofs overhung their faces by 5 cm and the outline
  coping ran 0.6 m back through them: roofs inset, coping 0.16 m.
- **Ground:** no ground under the building; walks with their own texel; planter beds unbaked, so the 1.6 m ground
  texels under them stop baking black squares round the islands (seen in the Demo 52 bake).
- Texel density was not the cause (the walls' 0.4 m texel is unchanged).

### 7. Ground Pat'i across Bayou Gardens (Steven, Nov 8)
- Steven: Ground Pat'i is on Bayou Gardens Blvd **directly across the street from the mall**, not across West Park at
  the intersection corner. Re-checked the frames: in 4492 f105-107 the camera walks south down the east facade past
  the Shoe Dept box and the restaurant's rust mansards and both its signs sit just past Dillard's corner, across
  the road; 4489 f078-082 zoom on the cube sign from Dillard's west end over the south lot. Both put it **opposite
  Dillard's**.
- Built (`outparcels`, `GROUND_PATI = 20.0`, x of its centre): the brown-brick restaurant with its rust mansards
  set back across Bayou Gardens at z 242, facing the mall, behind its own small asphalt lot; the cube pole sign
  at the road's edge and the low yellow monument sign beside it (4489 f079). Evidence
  `wsLOT-groundpati-moved.jpg` (unbaked).
- **Steven to confirm** opposite Dillard's (built) vs the south pavilion (x ~ -140) or JCPenney (x ~ -184): a
  one-number change.

### Pack size and bake (before = main f96a04b, exported here; after = this branch)
| | Before | After |
|---|---|---|
| `w3` pack (desktop = mobile) | 48.27 MB | 59.52 MB (+11.3) |
| `w3y26` pack | 30.93 MB | 44.71 MB (+13.8) |
| `gen/w3` / `gen/w3y26` meshes | 4.36 / 3.80 MB | 5.42 / 5.02 MB |
| wing 3 lightmap texels (sum of the static meshes' size hints) | 2.95 M | 3.15 M (+7 %) |
| wing 3 2026 lightmap texels | 2.86 M | 3.04 M (+6 %) |
Most of the pack growth is textures: the concrete and asphalt sets and the atlases (~6 MB VRAM) and the old `tex/ex/` textures
now VRAM-compressed **with mipmaps** (they were small lossless PNGs). Levers if Steven wants it smaller: the concrete
albedo at 1024 (-2.1 MB), the old outside textures lossless with mipmaps instead of VRAM. The bake is the same kind
of job (+~7 % texels).

### Files
`tools/exterior/exterior.gd`, `flora.gd` (new), `paint_lot.py` (new), `monuments.gd` (the drive's line paint, the
monument liriope), `exshots.gd` (`--sun`, `--baked`), `options/` (the tree-option sketches), `tex/ex/ex_*` (new),
`tex/ex/*.import` (mipmaps, VRAM), `gen/w3`, `gen/w3y26`, `wing3.tscn`, `wing3_2026.tscn`.
Shared: `tools/build_mall.gd` one line (the dynamic `ex_flora`, `ex_paint`, `ex_beds` meshes commit with compressed
attributes).

### Tests (cloud, unbaked)
- `--wing=3` and `--wing=3 --year=2026`: BUILD OK.
- `tools/qa/doortest.py`: wing 1's main entrance -> "Go outside" -> wing 3 at the doors -> "Enter the mall" ->
  wing 1: CROSSED, 0 errors (`wsLOT-walkout-doortest.jpg`).
- `tools/qa/movetest.py` wing 3, 1995 and 2026: loads, 3 cameras, the touch walk MOVED (from a lot spot,
  `WALK_CAM=62,30,0,0`; the default spot is inside the building). 1995 0 errors; 2026 one console line
  "could not keep the next files for later" because this local build has no 2026 wing 1/2 packs to prefetch.

### For the Mac (integration)
1. Rebake `wing3:fastday` and `wing3_2026:fastday` (every outside mesh changed; the old lightmaps no longer fit).
   Expected cost as before plus ~7 % texels (the 12 GB swap in the cloud).
2. Check the facade fixes in the bake at Dillard's, JCPenney (west fascia, south parapet) and Lynn's.
3. `tools/capture_standin.sh 3` and `3 2026` (the door pictures of wings 1, 2, 4, 5 look out on the lot).
4. Wings 1, 2, 4, 5 need no rebake.

## Nov 8 refinements (Workstream EXT-LAYOUT, branch `ws/ext-layout`): the cinema side, frame by frame

Branch `ws/ext-layout` from `ws/lot`. Brief: Steven (Nov 8), "the Dillard's side to the front entrance is good; the
cinema side is still incorrect". Every face named below was compared with the Oct 23 frames at the same viewpoint;
evidence `production/qa/evidence/wsEXTL-*.jpg` (frame | render, renders **unbaked**, `tools/exterior/exshots.gd`).
Frames: `refs/derived/frames/IMG_4416/fNNN.jpg`, `IMG_4486/fNNN.jpg`, photos `IMG_4417`, `IMG_4418`.
Plan: `design/exterior/site-plan-annotated-2026-11-08.png` (Steven's labels).

### 0. What the frames proved about the footprint (the main fix)
The exit's glass is **not** flush with the cinema's west wall. It stands at the end of a **channel 10 m wide and ~20 m
deep** between Lynn's SW corner (white, north side) and the cinema box's north face (salmon, south side):
- **4486 f014** (from the lot, looking east): the white Sears mass left, the long salmon wall right with a cream door,
  the fascia and glass small at the far end of the channel. The decisive frame.
- **4486 f016**: the cinema's NW corner, a cream single door on the north face 1.5 m from the corner, the west wall
  running south with its pilasters. **4486 f001** (from the recess, looking west): the north face with a cream
  **double** door and the single one by the corner.
- **4416 f005**: past the recess the salmon wall faces north (its red curb runs out toward the camera), i.e. it is the
  channel's side, not a wall in line with the glass.
- **Site plan** (Steven's "Southland Cinema Mall Entrance"): the hall's end sits between Lynn's (north) and the cinema
  box (south); the cinema's NW corner is ~22 m west of the storefront line, Lynn's west face ~6 m west of it (x scale
  2.9 px/m on the annotated plan, checked on the dock rectangle: 24 m = canopy 8 + truck well 16, as EXT-B).

Built (`wall_fixes.py` FILLS, `exterior.gd` `SEARS_W`, `CINEMA_W`), the glass staying at the walkable hall's end:
| | Was (EXT-B) | Now | From |
|---|---|---|---|
| Exit glass (s41) | x -80, flush | **x -78**, 2 m under the soffit; the fascia's face x -80.2 | 4416 f002-f005 |
| Lynn's / Sears west face | x -72 (box 115 x 50) | **x -84** (box 128 x 50); the dock, truck well, truck and the "Sears" / "Lynn's" west signs move with it | plan; 4486 f014 (the white mass left of the channel) |
| The white rack block ("SEARS RETURN") | -80..-71, -100..-96, 6.5 m | **-88..-84, -100..-96, 4.2 m**, painted brick, at Lynn's SW corner, its south face the channel's north side | 4486 f002-f003, f006-f008, f014 (the low white box in front of Lynn's) |
| Cinema box | -80..-52 x -86..-42, 9 m | **-98..-52 x -86..-42, 6.8 m** | 4486 f001, f014, f016 (wall 6.3-6.7 m against the 2.1 m doors) |
The walk grid opens the 2 m recess (`wall_fixes.WALK_OPEN`, read by `make_exterior.py`), so the player can walk up to
the glass; s41's outside spot is unchanged (-81.5, -91), its outside face is x -78 (`DOOR_MOVES`).
*Note for Steven:* the brief says "one flush run from the exit"; the frames above say the exit is set back in a
channel and the cinema's flush west wall starts 20 m out. Built as filmed. The channel's depth is the least certain
number (20 m; the plan says ~22, a perspective estimate off f001 / f014 14-25 m): one constant, `CINEMA_W`.

### 1. The cinema-wing exit, s41 (`exterior.gd cinema_exit`; 4416 f001-f007, 4486 f001-f003, 4417, 4418)
Proportions measured off 4416 f002 (the glass plane, ~121 px/m against the 2.1 m doors) and f005:
| Part | Built | Measured |
|---|---|---|
| Doors | two pairs, 1.8 m each (0.9 m leaves), 2.12 m high in 0.1 m clear-anodized stiles; a push bar at 1.0 m on the inside, stainless panic / pull plates at the meeting stiles | pair 1.74 m wide, bars at ~1.03 m |
| Storefront | x -78, 10 m (z -96..-86): 3 fixed bays 1.4 m (north), the two pairs, 2 sidelights 1.1 m with rails at 0.9 / 1.27 m; transom bar 2.18-2.3 m, transom glass to the soffit | transom ~2.27 m over the door head |
| Soffit | white, **4.4 m**, 2 m deep (x -79.6..-78), 2 rows of 4 recessed cans | 4.4 m (door + transom) |
| Fascia | brown exposed-aggregate precast, **1.3 m** (4.4-5.7 m), 0.6 m thick, 0.2 m proud of the walls, white metal cap | 1.2-1.4 m (perspective) |
| North side | the white painted brick of Lynn's SW corner / the rack block | f002 left, f001 |
| South side | buff brick under the soffit with the **poster case** (aluminium frame, dark glass, 1.2 x 0.9 m at 1.0-1.9 m), a rusty steel pipe post at the fascia's corner, a 0.9 m buff pier rising to 7 m, then the salmon brick | f004, f005, 4417 |
| Apron | a flush dark slab, no curb across the recess; the red curb comes along the cinema's north face and stops at the recess corner | f002, f005 |
| Behind the glass | a 5 m vestibule (dark tile, white ceiling at 3.2 m with cans, the inner pairs as dark glass): wing 3 had nothing behind the glass, so it showed the lot through the building | 4416 f002, 4418 |
The red curb runs along the cinema's north face and ends at the recess corner; the recess itself is a flush apron
(f002 / f005). **Kept as filmed** (Steven, Nov 8 follow-up; the brief had said "across the recess"), as is the rack
block's door on its west face (§3).
"No return wall on the south side": no perpendicular wall is built there; the salmon brick of the cinema's north face
runs from 0.9 m past the recess, the buff strip being the recess's own side and the pier (f005).

**The bike rack** (`tools/exterior/wave_rack.gd`, new; also used at the south pavilion): one bent 48 mm pipe swept
along its centre line: the two end legs into the slab, three inverted-U loops 0.8 m high, two low U bends between,
legs 0.36 m apart: **1.8 m long, 0.8 m tall, 736 triangles** (budget 800), black paint chipped to rust as a vertex-colour
mottle (material `ex_rack`, roughness 0.55). **Steven (Nov 8, after the first render):** it belongs on the white wall
to the **left of the entrance** (the channel's north side), not on the west face parallel to the doors. Now it runs
along the rack block's south face (z -96), 0.5 m off it, centred x -86.3 (4416 f009-f011, 4486 f002-f003). Procedural GDScript rather than Blender:
the same geometry a Blender sweep would give, no import step, baked with the outside's props.
Evidence: `wsEXTL-exit-frame.jpg`, `wsEXTL-exit-render-{1995,2026}-unbaked.jpg`, `wsEXTL-exit-sbs-{f002,f005,f014}-*`,
`wsEXTL-rack-frame.jpg`, `wsEXTL-rack-render-1995-unbaked.jpg`, `wsEXTL-rack-sbs-*`.

### 2. The cinema's west wall and north face (`exterior.gd cinema_box`, `cinema_door`; 4486 f001, f014-f040)
What each frame proved, and what changed:
| Frame | Shows | Built |
|---|---|---|
| f001, f014 | the north face (the channel's south side): a cream flush **double** door ~10 m out from the glass, red curb, no ladder | double door at x -90.5 with a wall pack; red curb (was: no north face at all) |
| f016 | the NW corner; a cream **single** door 1.5 m from it on the north face; the curb wraps the corner; the pink ladder starts on the west side | single door at x -96.4; the ladder 2026 on the west face only |
| f016-f021 | one flush west run, shallow pilasters ~8 m apart, peach, a light base course | pilasters 0.6 m wide, 0.1 m proud, peach-painted brick with a peach cap, at 6, 14, 22, 30, 38 m from the NW corner; base course 0.45 m (was 6 pilasters at ~9 m, 0.18 proud, a 0.6 m base) |
| f022-f024 | the brass FDC on its pipe left of a pilaster, the steps right past it | FDC at 12.6 m, steps from 15 m |
| f025-f030 | three steps up to a raised walk along the wall, the peach knee wall at the curb, a galvanized two-rail pipe rail, a cream single door with a light on the walk | the walk 0.45 m up, 1.45 m wide, from 15 to 33 m, the door at 26 m (was a 12 m ramp-only box with one rail) |
| f031-f037 | the knee wall dropping toward the south: the ramp down to the lot, i.e. rising toward the exit; a door at grade further south | the 1:12 ramp 33-38.4 m with its rail; a single door at 41.5 m (GUESS: f037 shows it far off) |
| all | the wall is 6.3-6.7 m (against the 2.1 m doors), the brick a dusty rose | 6.8 m (was 9); the salmon brick tinted down (`brick_salmon` albedo 0.76 / 0.8 / 0.8; it rendered orange) |
Count: the brief's "two cream flush doors (one double, one single)" are the north face's two (f001, f016); the west face
has the walk's single door and the far one. Was: five hooded doors on the west face, none on the north. Red curb both
years; the pink fire-lane hatching only in 2026 (1995 had a GUESSED yellow one: removed on the cinema).
Brick at 50 m: no swirl (LOT's mipmaps hold, `wsEXTL-cinema-wall-50m-*`), so the UV tiling was left as it is.
Evidence: `wsEXTL-cinema-wall-frame.jpg`, `wsEXTL-cinema-wall-render-{1995,2026}-unbaked.jpg`,
`wsEXTL-cinema-wall-sbs-{f016,f017,f022,f028,f034}-{1995,2026}-unbaked.jpg`.

### 3. The Sears loading dock and truck well (`exterior.gd sears_dock`, `WELL`; 4416 f012-f017, 4486 f004-f010)
| Frame | Shows | Built (was) |
|---|---|---|
| 4486 f006-f008 | the white flat canopy on thin white pipe columns at the dock's edge, overhanging the well; white roll-up doors **at the building's floor level**; the trucks stand lower | canopy 8 m at 4.6 m, 4 thin white columns at the dock edge (were 3 grey ones 7.6 m out, standing in the well); the dock floor at grade, white roll-ups 3 m high from it (was a raised 1.2 m dock box with steel doors 1.2-4.2 m) |
| 4486 f008, f010 | a **depressed** truck well in front of the dock, the yellow 2-rail on its red curb along the drop | the well sunk 1.2 m, x -107..-87, z -118..-101, concrete retaining walls, the dock face with black bumpers, then a 12 m ramp west back up to the lot (x -119..-107); the rail on the red curb along both tops, the full 32 m (was a painted dark slab at grade with a 20 m rail) |
| 4416 f012-f017 | from the rack corner, the rail runs far west along the grade drop; the lower lot beyond | the rail's 32 m; the lot itself is flat in the game, so the drop is the well and its ramp (the lower lot is not modelled: a GUESS kept simple) |
| 4486 f006-f008 | the low white block at the dock's south end, a door on its **west** face | the rack block (§0) with a beige door on its west face |
| 2026 / 1995 | the Lynn's box truck | 2026 the Lynn's truck backed into the well; 1995 a plain white trailer (brief) |
The well is an obstacle for the player (the walk grid is flat), and the lot ground is cut round it (`lot_ground` ->
`ground_minus_well`, a small separate hunk in LOT's function). Evidence: `wsEXTL-dock-frame.jpg`,
`wsEXTL-dock-render-{1995,2026}-unbaked.jpg`, `wsEXTL-dock-sbs-{4486f008,4486f010,4416f014}-*`, `wsEXTL-dock-top-*`.

### 4. The Sears north entrance, s1n (new; `exterior.gd sears_north_entrance`, `wall_fixes.NEW_DOORS`)
Steven's plan marks "Sears Entrance" on Lynn's north face, toward Armour Dr. Built centred at x -24 (the plan's bump,
x -39..-12) on z -146: dark bronze, three door pairs, sidelights, a flat dark canopy 3 m deep with cans, "Sears" (1995)
/ "Lynn's" (2026) over it; a keep-out keeps stalls off its walk. A real door in `exterior.json`: out (-24, -149.5),
inside (-24, -143.5) in its vestibule (first the north end of the main aisle; see the follow-up below) (details and the open question in
`design/godot-sears.md`). s1e and s1x unchanged. Not filmed: the form is a GUESS.
**Follow-up (Steven, Nov 8):** the door now lands in a real **vestibule inside the north wall** at x -28..-20 (inside
spot (-24, -143.5)); the appliance room R1 shrinks to x -40..-28 to make room (`tools/stores/sears/store.gd`
`north_entry`; `design/godot-sears.md`). Evidence `wsEXTL-north-entrance-vestibule-*` (inside, unbaked, the night
lights on: the cloud preview's sun comes through the box's ceiling). Evidence
`wsEXTL-north-entrance-{far,near}-{1995,2026}-unbaked.jpg`, `wsEXTL-north-entrance-top-unbaked.jpg`.

### 5. The bank pad (verify only)
In the merged tree (LOT's `bank_pad`, `BANK`): a 28.0 x 25.75 m pad (721 m2 = 7,758 SF), a 14 x 14 m one-storey brick
building 4.2 m to a thin coping, the flat white drive-thru canopy over three lanes on its west (lot) side, no name in
either year. Matches the brief; not changed. Evidence `wsEXTL-bank-verify-unbaked.jpg` (1995, 2026, both top views).

### 6. Steven's annotated plan against `exterior.json` (listed only: nothing below was changed)
Mapping: the annotated plan's Lynn's box (x 1148..1478 px) onto x -84..44, z 2.54 px/m from its south face.
| Label | Plan says | Built | Agree? |
|---|---|---|---|
| Sears Loading Dock (west) | dock on Lynn's west face, canopy + well ~24 m out | §3 | yes |
| Bike Rack / Southland Cinema Mall Entrance | at the channel between Lynn's and the cinema box | §0, §1 | yes (after this branch) |
| Sears Entrance (north) | the bump at x -39..-12 | s1n at x -28..-20 | yes (new, §4) |
| Mall Entrance / Old Cuco's (east) | the east entrance at Lynn's SE corner, Cuco's south of it | s43's recess z -96..-86 at x 40..44; Cucos (s42) south of it | yes |
| Old Sears Hardware = Unitech | a 15,600 SF box by Armour Dr at **x -122..-82, z -232..-193** (its east edge in line with Lynn's west face) | was x -85..-57, z -236..-207 (~8,700 SF), "UNITECH" in 2026. **Fixed (Steven, Nov 8 follow-up):** `STANDALONE` **x -122..-82, z -232.2..-196** (40 x 36.2 m = 15,600 SF), **unsigned in both years**; "Old Sears Hardware" per Steven's plan, what it read in the 1990s left to a historian pass. The apartments' fence (`APTS`) moved from x -120 to -128 to leave Unitech a 6 m drive (`wsEXTL-unitech-moved-unbaked.jpg`) | yes (after the fix) |
| Shoe Dept. (Encore) 20,071 SF | the flush box on the east facade, x ~1..44, z ~27..90 | box x 4..44, z 32..77; 2026 Shoe Dept.'s white ACM front with three canopied bays (decorative: not a walkable door) | yes (within the plan's z stretch). Its exterior entrance is a storefront only; making it a door is a separate job |
| Chase Bank 7,758 SF "not a part" | the West Park pad | §5 | yes |
| Building 870 SF drive-thru, "not a part" 40,000 SF | the far SW corner by Bayou Gardens | the drive-thru bank at (-346, 166), the strip centre x -321..-303, z 100..155 | yes (EXT-B) |
| PAD 1 ACRE | a vacant pad at the lot's NE corner, ~x 78..106, z -226..-199, stall rows round it | parked over (the front lot's stall field runs to z -240) | **kept as parking in both years** (Steven, Nov 8: a 2024 leasing label, not a 1995 fact) |
| Water tank | x ~-159..-140, z -32..-12 | yard x -141..-121, z -32..-9 | **roughly**: ~18 m east of the plan (EXT-B took the footage) |

### Files (EXT-LAYOUT)
`tools/exterior/exterior.gd` (`SEARS_W`, `CINEMA_W`, `WELL`; `cinema_exit`, `cinema_box`, `cinema_door`, `sears_dock`,
`sears_north_entrance`; `skin` for the rack block; the walks loop's cinema curb hunk; `lot_ground` -> `ground_minus_well`
and one keep-out line in LOT's code, both commented), `exterior_2026.gd` (Lynn's west and north signs), `wave_rack.gd`
(new), `wall_fixes.py` (FILLS, `DOOR_MOVES` s41, `WALK_OPEN`, `NEW_DOORS`), `tools/make_exterior.py` (reads `WALK_OPEN`,
`NEW_DOORS`), `exterior.json`, `gen/w3`, `gen/w3y26`, `wing3.tscn`, `wing3_2026.tscn`.
Shared: `scripts/player.gd` one hunk (the s1n name). `build_mall.gd` untouched. Follow-up: `tools/stores/sears/store.gd`
(`north_entry`, R1 / R4 partitions, one light) and `lynns.gd` (`FREED`), the apartments' fence (`APTS`).

### Tests (cloud, unbaked; export `.scratch/builds/extl`, wings 1-4, both years)
- `--wing=3` and `--wing=3 --year=2026`: BUILD OK.
- `doortest.py`: **s41** (1995 and 2026), **s43**, **s1n** (1995 and 2026: wing 4's north vestibule -> "Go outside · the
  Sears north entrance" -> wing 3 at (-24, -149.5) -> "Enter the mall" -> back in the vestibule), and s1x unchanged:
  all CROSSED, 0 errors
  (`wsEXTL-doortest-*`). (Without wing 2's packs in the export, wing 1's prefetch fails and nothing crosses: export
  wing 2 too.)
- `movetest.py` wing 3, 1995 and 2026: 0 errors; the touch walk from the channel walks into the recess (x -86 -> -80.3).
  Wing 4, 1995 and 2026, starting at s1n's inside spot in the vestibule: 0 errors, the walk goes south through the
  inner doors (z -143.5 -> -137.8). Wing 3 again after Unitech's move, both years: 0 errors.
- Packs, wing 3 (before = `ws/lot` a31aa7e's generated files, exported here): `w3` 59.52 -> 59.74 MB (+0.22),
  `w3y26` 44.71 -> 44.92 MB (+0.21), desktop = mobile. No new textures. Wing 4 (the vestibule): `w4` 42.63 -> 42.67 MB,
  `w4y26` 96.07 -> 96.07 MB.

### For the Mac (integration)
1. Rebake `wing3:fastday` and `wing3_2026:fastday` (the cinema corner, Lynn's west face and the dock moved).
2. **Wing 4 / 4_2026: rebake** (`wing4:day wing4_2026:day`): the north vestibule, R1's moved partitions and the lobby
   are new static geometry; then `tools/capture_standin.sh 4` / `4 2026` (wing 1's picture of the Sears opening).
3. `tools/capture_standin.sh 3` and `3 2026`: the door pictures of wings 1, 2, 4, 5 (s41 now looks down the channel; s1n
   adds a row at the end of wing 1's atlas, the existing rows unchanged).

## Workstream EXT-LOT (Nov 9, 2026): six lot fixes from Steven's Demo 53 walk

Branch `ws/ext-lot` from `main` (0b07b54). Both years unless said. Evidence `production/qa/evidence/wsEXTL2-*.jpg`
(all **unbaked**: the cloud does not bake). One commit per item.

### 1. Accessible stalls (`exterior.gd ada_stalls`, `ada_pair`; `lot_field` records `ROWS`)
- Steven: the wheelchair symbols "make zero sense on the outside concrete". They were placed on a 2 m search grid
  round each door, so they sat off the stall lines and out in the aisles.
- Now `lot_field` records every stall row it paints (start, direction, stall count, field, row number). For each
  customer door (and JCPenney's two entrances), the rows whose building end is within 40 m of the door are found;
  the nearest row and **every other row** of the same field after it get a pair (at most two rows a door, never
  every row). In a chosen row, on the side facing the door, **stalls 1 and 2 from the building end** carry the
  symbol (same 1.5 m size), centred and wholly inside the yellow lines, turned to read from the drive aisle.
- **Access aisle:** stall 3 beside each pair is the striped aisle: a blue frame 0.15 m inside the stall lines and
  45-degree blue hatching at 0.6 m (`ex_lot_ada_blue`), as filmed at JCPenney's west side (4488 f005, f009: blue
  hatched aisles). 1995's aisle colour is a GUESS (blue). The stall lines themselves stay the lot's yellow (today's
  blue HC lines are not drawn).

### 2. Road into the lot: the lanes carry on (`exterior.gd entry_throat`, `lot_field` calls, `lot_keepouts`)
- Steven: "when turning from the road onto the mall lot make sure the driving lanes stay intact as they should in a
  mall parking lot; only difference is pavement change from asphalt to concrete." The Armour Dr drive (and the Bayou
  Gardens one) were `MON.drive`: asphalt with a double yellow that ran 10 m into the lot and stopped at a stall
  row's end island, because one stall field's row sat right on the drive's line (back lot row x -24.5; south lot
  row x -140.5).
- Now each drive mouth (`entry_throat`): asphalt only from the road's edge to the end of two 4.5 m **curb returns**
  at the property line (`THROAT_R`), with the road's double yellow stopping there and a white stop bar across the
  outbound lane; the frontage curb is cut at the mouth; an 8 m curbed throat (`THROAT_L`) on each side; the stop
  sign on the outbound side.
- The **lanes continue in concrete** as a 12 m (Armour, `ARMOUR_DRIVE` x -26..-14) / 16 m (Bayou Gardens,
  `BAYOU_DRIVE`) drive aisle all the way to the building: the back lot and south lot are each laid as two stall
  fields either side of the aisle, so rows meet the drive with their **sides** (stalls opening onto it), not their
  ends. The Armour aisle runs straight to Lynn's north entrance (s1n, x -24); the Bayou Gardens aisle to the south
  entrance's drop-off. Cost: the back lot's westernmost row (x -120..-109, south of Unitech) is now the perimeter
  aisle along the apartments' fence.
- Walking it: the walk grid is flat; the asphalt sits 1.6 cm over the concrete (paint, not a step), so there is
  nothing to pop at the seam.

### 3. The UA marquee on West Park; one entrance sign (`monuments.gd build()`, a small hunk; the models unchanged)
- Steven: the "Southland Cinema / Now Showing" pylon at the Kirschman's end (Armour Dr) was in the wrong place. It
  now stands on **West Park Ave's far (east) verge across from the bank pad** (`UA_MARQUEE_X/Z` = 124, -64; the bank
  pad is z -76.9..-51.1), its face to the road and the mall. 1995 only: the 2026 footage shows no successor.
- The brick monument beside it (Armour Dr) is gone. "The mall keeps exactly one entrance sign, the one toward the
  front of the mall": the West Park monument at the palm drive (100, -11.5). **The Bayou Gardens monument was also
  removed** to leave exactly one (the brief's count); restoring it is one line (commented in `build()`).
  Verified in both years' builds: one `monument()`, `monuments: 1 sign` in the build log.

### 4. The small building with the mast, north of JCPenney (`exterior.gd tank`, `TANK_UTILITY`)
- What it stood for: not in `exterior.json` and not an outparcel. It was the tank yard's **peach utility building**
  (5 x 5 x 3 m) and the 8 m **conduit pole** on its yellow base beside it (read as an antenna mast), after the peach
  electrical building and the pole with two conduit risers filmed in 4486 f077-102 (notes_C, "big conduit right
  there"). Steven: "remove this building". Both are off behind `TANK_UTILITY = false`; the tank, its fence and
  shrubs stay.

### 5. Unitech's entrance (`exterior.gd unitech_box`; `make_exterior.py` writes `standalone[].entrance`)
- Steven: "Sears Hardware in 1995, Unitech(?) today"; doors where he drew the arch, the centre of the long lot-facing
  face. The box is 40 x 36.2 m: the long faces are north and south, and the south one faces the back lot and Lynn's.
- Built (both years): a **7.2 x 2.4 m recessed vestibule** centred at (-102, -196) on the south face; a white soffit
  at 3.2 m with two cans (a night light); a 0.1 m concrete step; a clear-anodized storefront on the back wall: two
  pairs of full-glass doors (0.9 m leaves, push bars), a sidelight each side, a transom bar at the 2.3 m door head and
  transom to the soffit, dark glass. Period commercial (1970s-90s), the same in 2026 (no footage of this face).
- **Visual only:** the box has no inside, so the doors are not in `doors` and the recess is not on the walk grid.
- **For EXT-SIGNS:** `exterior.json` `standalone[name=UNITECH].entrance` = `{face: "S", n: [0, 1], mid: [-102, -196],
  width: 7.2, recess: 2.4, h: 2.3, soffit: 3.2, sign_band: [3.6, 6.4], walkable: false}`; the sign goes on the wall
  face above the recess (the lintel, z -196, y 3.6-6.4).

### 6. No NPCs outside (`scripts/npcs.gd`, one commented hunk)
- Steven: no NPCs outside the mall "at this time". `npcs.gd` stays off in wing 3 unless `npcs.json` sets
  `"outside": true` (a flag, default false; `?npcs=N` does not override it). 2026 already skipped wing 3 in
  `player.gd`; 1995 now stops at the flag. The Runner is wing 2 only and no story attendant is placed in wing 3.
- From the vestibules: in every inside wing and year, the walk grid (which the shoppers' path grid copies) is closed
  1-10 m past each exit door (s39, s41, s43, s55, s1e, s1n, s1x, s2e, s2s), so no shopper can reach or spawn in a
  vestibule and none can walk in from outside.

### Files (EXT-LOT)
`tools/exterior/exterior.gd` (`ROWS`, `FIELD`, `ada_stalls`, `ada_pair`, `entry_throat`, `unitech_box`, `ARMOUR_DRIVE`,
`THROAT_R`, `THROAT_L`, `TANK_UTILITY`; the stall fields and keep-outs in `lot` / `lot_keepouts`; the `ex_lot_ada_blue`
paint), `tools/exterior/monuments.gd` (`build()` only, `UA_MARQUEE_X/Z`), `tools/make_exterior.py` (`entrance`),
`exterior.json`, `scripts/npcs.gd` (one hunk), `gen/w3`, `gen/w3y26`, `wing3.tscn`, `wing3_2026.tscn`.
Not touched: any building face but Unitech's, the sign models, the entrances, `player.gd`, `build_mall.gd`.

### Tests (cloud, unbaked; export `.scratch/builds/extl2`, wings 1-4, both years; lightmaps left out of the import)
- `--wing=3` and `--wing=3 --year=2026`: BUILD OK (`accessible stalls, 15 pairs`; `monuments: 1 sign` [+ the UA
  marquee in 1995]).
- `doortest.py` wing 1 main entrance -> outside -> back, 1995 and 2026: CROSSED, 0 errors.
- `movetest.py` wing 3 (`?npcs=12` asked for), 1995 and 2026: 0 errors at four cameras, the touch walk MOVED;
  1995 logs `npcs: off outside`.
- **Drive-in walks** (a scratch Playwright script: hold run + forward from the road's edge, read `DBG pos` every
  0.5 s of game time, then E at the door): Armour Dr road edge (-24, -249) down the drive aisle to Lynn's north
  doors, 1995 and 2026: 4.6-4.8 m per sample the whole way, no jump over 1.5 x the median, no stall, x held at
  -24 (no sideways push), across the asphalt -> concrete seam at z -243; "Enter the mall" -> wing 4 (s1n), 0
  errors. West Park road edge (102.6, -118) to Lynn's east doors (s1e), 1995: the same, -> wing 4. Note: s1n's
  prompt circle (2.8 m round its out spot, 3.5 m off the glass) does not reach the glass; walking straight up to
  the doors stops 3.1 m from the spot with no prompt, one step back shows it (EXT-LAYOUT's spot, not changed here).
- Not compared here: pack sizes (this cloud export has `w3` 98.9 MB, `w3y26` 85.7 MB; LOT measured 59.7 / 44.9 MB
  on its own branch; this branch adds a few hundred stripes, the throats and one storefront, no texture).

### For the Mac (integration)
1. Rebake `wing3:fastday` and `wing3_2026:fastday` (the lot paint, the throats, Unitech's front, the tank yard and
   the monuments changed; the old lightmaps no longer fit).
2. `tools/capture_standin.sh 3` and `3 2026` (the door pictures of the inside wings look out on the lot).
3. Wings 1, 2, 4, 5 need no rebake (`npcs.gd` is a script).
4. EXT-SIGNS: Unitech's sign position is `exterior.json standalone[0].entrance` (above). EXT-ENTRANCES: nothing here
   touches the entrances.

### Open for Steven
- The Bayou Gardens monument went too, to leave one entrance sign: say if "one" meant only the Armour one.
- The marquee's real spot is still not in any picture: on the verge across from the bank, facing the road, as asked.
- The tank-yard utility building was the filmed electrical building (4486 f077-102); removed as asked
  (`TANK_UTILITY` brings it back).
- Unitech's entrance is on the south (lot-facing, toward Lynn's) long face; the east face also faces the lot.


## Workstream EXT-SIGNS (Nov 9 2026): the department-store signs in 3D
Branch `ws/ext-signs` (merged `ws/ext-lot`). Steven (Nov 9 stills, recording `Screen_Recording_11.38.54`): "Sears"
was flat blue text painted on the wall, Dillard's a flat decal that shimmered as the camera moved, K&B a flat
purple oval on a white band; he wants "realistic 3D signage that was actually there", researched. Research,
sources and options: `design/exterior/signage-research.md`. Options sheet: `production/qa/evidence/wsEXTS-options.jpg`.

### How they are built (the Cucos sign's approach)
- **Models:** `tools/blender/assets_src/bl_exs_*.py` through the Blender pipeline (`tools/blender/run.sh`; shared
  construction in `_exsign.py`). Each sign is real channel letters: returns (sheet-metal sides), a trim cap, a closed
  back, a face of its own material, and studs across a visible gap to the wall or a raceway. A contact-shadow film
  on the wall keeps the gap readable after the bake; the sun's real shadow does the same unbaked. One atlas per
  sign (512 or 1024), all ≤ 6k tris. Letterforms are OFL fonts close to the period wordmarks (Archivo Black for
  Sears, Libre Caslon Text 600 for Dillard's; `tools/exterior/signs_src/`, a `.gdignore` keeps them out of the game).
  K&B uses the project's own trace (`tools/stores/signs/kb_letters_logo.json`). None is a traced trademark bitmap.
- **Placement and light:** `tools/exterior/signs.gd` `place(b, id, at, n)` puts the sign's origin (on the wall,
  centred on the sign) at `at` facing `n`. The mesh is saved to `gen/w3[y26]/exs_<id>.res` so the scene references it.
  The flat face materials from the .glb are swapped for `ex_sign_<sign>_<part>` with `e_day` / `e_night` emission
  (`scripts/time_of_day.gd`): Sears, Sears Hardware and K&B glow at night. Dillard's is unlit, as filmed. Lit faces do
  not receive shadows (shadow acne). The meshes are dynamic (no lightmap, like the Cucos sign).
- **exterior.gd** (small commented hunks, marked EXT-SIGNS): each flat `Label3D` and the flat K&B oval now draw only
  when the model is missing. `EXS_OFF=1` builds the old signs (before shots); `EXS_OPTIONS=B` builds the options
  sheet's B models (`models/exterior/signs/options/`, not committed).

| Sign | Year | Where | Model | Tris / atlas |
|---|---|---|---|---|
| SEARS, blue lit channel letters on a white raceway, cap 1.6 m | 1995 | east face **over the s1e doors** (z −118; it stood at z −134, beside them), west face (dock side, z −134), north face over s1n | `bl_exs_sears` | 2.6k / 1024 |
| Dillard's, black cans on 5 cm studs, bronze edge, cap 2.0 m | both | east and south faces between the cornices (y 11.6) | `bl_exs_dillards` | 5.5k / 1024 |
| Dillard's, cut-out plates on 4 cm studs, cap 0.8 m | both | the portal's entablature (s2s) | `bl_exs_dillards_portal` | 2.9k / 512 |
| K&B, lit oval cabinet (purple face, red line, white K&B, gold rim), 1.45 m | 1995 | the cream band over K&B's canopy | `bl_exs_kb` | 1.4k / 512 |
| SEARS HARDWARE, the Sears letters on a raceway, cap 1.0 m | 1995 | the Unitech box's south face, centred on EXT-LOT's recessed doors (`standalone[].entrance`, `sign_band` 3.6–6.4) | `bl_exs_sears_hw` | 4.4k / 1024 |

**Left alone:** Lynn's in 2026 (out of scope), Hypervelocity on K&B's band in 2026 (K&B was gone by 1997), the
Cucos sign. **Unitech (2026): unsigned**, Steven's Nov 8 decision. Its wordmark is not legible in any frame and
could not be looked up; the plan only names the tenant. A plain UNITECH mock is option B on the sheet.

### Picks
Steven had not answered within the session, so every sign is option A, the better-sourced one. Option B
(Sears as a cabinet, Dillard's halo-lit, K&B as an unlit panel with lit letters, Sears Hardware as a stacked
cabinet, UNITECH letters) is one rebuild away: the scripts take `EXS_VARIANT=B`.

### Still guesses
Sears's return colour and raceway; the north and west Sears signs (not filmed); whether Dillard's was halo-lit;
the 1995 Dillard's letters = 2026's; how K&B's oval was mounted and lit; everything about the Sears Hardware sign
(no photo); which box was Sears Hardware and which the "former Sears TBA" (a LoopNet flyer names both).

### Tests (cloud, unbaked; export `.scratch/builds/exts`, wings 1-3, both years)
- `doortest.py` wing 1 main entrance -> wing 3 -> back: **CROSSED, 0 errors**, 1995 and 2026.
- `movetest.py` wing 3, cameras at Sears (day and `time=night`), Dillard's portal, K&B: **0 errors** both years; the
  touch walk from the lot in front of K&B (`WALK_CAM=70,-28,90,0`) moves the player both years (the tool's default
  spot 0,14 is inside the building on wing 3).
- The web shots (`wsEXTS-*-web-stale-lightmap.jpg`) still carry the old wing-3 lightmap: the rebake fixes it.

### Pack size (wing 3, desktop = mobile here)
| | before (flat signs, `EXS_OFF=1`) | after | the signs' share |
|---|---|---|---|
| `w3` (1995) | 115,650,040 B | 118,814,720 B | +3.16 MB (+2.7 %): 8 signs, 5 models, 5 atlases |
| `w3y26` (2026) | 102,513,320 B | 103,794,736 B | +1.28 MB (+1.3 %): Dillard's ×3, 2 models |

`export_web.sh` warns that `w3y26` (103.8 MB) is near GitHub's 100 MiB file limit (104.9 MB): about 1 MB of room
left. If that bites, the Dillard's atlas can go to 512 (it is mostly flat black and bronze) with Steven's yes.

### For the Mac (integration)
- **Rebuild and rebake wing 3, both years** (`wing3:day wing3_2026:day`): the signs are dynamic meshes and need no
  lightmap themselves, but they shadow the walls (Sears's raceway, Dillard's studs) and the flat labels they
  replace are gone. Then `tools/capture_standin.sh 3` and `3 2026` if the door pictures show the signs.
- The new `gen/w3/exs_*.res`, `gen/w3y26/exs_*.res` come from the build (not committed here).

## Workstream EXT-DOCKS (Nov 11, 2026): the two loading docks, both years

Branch `ws/ext-docks` from `int-54`. Steven's Demo 53 notes; the frame study with sheets, annotated frames and
measurements is `design/exterior/docks-2026-11-11.md`. Evidence `production/qa/evidence/wsDOCK-*.jpg` (all
**unbaked**). Code: `tools/exterior/docks.gd` (new, everything below), `wall_fixes.py` (one fill), `exterior.gd`
(small hunks marked EXT-DOCKS: the `DK` preload, the `dock_green` material, `skin` / `shell` for the court's walls,
the two old docks replaced by `DK.dillards(b)` / `DK.jcpenney(b)`, no walk / curb / fire lane on the dock faces,
one keep-out). `exterior_2026.gd`, the lot markings, the signs, the entrances and Unitech are untouched.

### A. Dillard's: the dock is behind the wing wall (4490 f013-f027)
Steven: "The brick wall should have an opening around where the red line is ... Dillard's truck loading area was
behind the area where the wall is, not in front ... The truck, green rectangle on ground and the loading bay need
to push back." The frames agree: the dock stands deep in a court between the wing block and Dillard's west face.
| What | Was | Now |
|---|---|---|
| Wing wall (z 118) | ran to x -42 | **stops at x -52** (`wall_fixes.py` fill `-134, 100, -52, 118`); the opening runs from there to Dillard's west face (x -38): 14 m, as measured off f026 |
| Court | none | x -52..-42, z 100..118 (10 x 18 m) plus the 4 m service lane beside it; its walls are the wing wall's (5 m tan brick; 2026 the two-tone EIFS) |
| Dock | a raised dock, canopy and two doors on Dillard's west face at z 121..133, in front of the wall | on the court's **back wall** (z 100): a low flat canopy with a brown fascia (underside 4.3 m, 3.6 m out), two positions with roll-ups in black seals (sill 1.2 m), yellow bollards at bay 2 |
| Trailer | parked east-west in front of the wall | backed into bay 1, nose to the lot (z 100.5..113.5) |
| Green box | a teal box at (-58, 132) | the roll-off (`bl_ex_dumpster`) on a pad left of the trailer, under the canopy's edge |
| New | | the wood-plank enclosure on a red curb at the mouth's west side (4 x 4 m, chain-link gate toward the dock); a double door in the wing block's east wall; Dillard's west face from z 100 to its SW corner gets the **white base to 4.8 m**, two white man doors, the FDC and hose valves, wall packs, a chain-link panel by the dock |
The service lane (doors 3026-3029) stays open: it is reached through the court (Steven's Nov 4 decision kept).

### B. JCPenney: the dock is on the side face (4486 f102-f110)
Steven: "Move truck loading area to side of building (should be a tree in between this area and the big tank to
the left; confirm in video walkthrough)." Confirmed: f105 shows the corner with the sign face to the right and the
dock face to the left; f106-f108 the docks on the east face at the NE corner.
| What | Was | Now |
|---|---|---|
| Docks 1-2 | north face (z -14), x -172..-158, under a red canopy | **east face** (x -154), z -13..-3.4: door 2 centred 3.0 m and door 1 6.9 m south of the NE corner, white roll-ups 2.4 x 2.6 m, sill 1.2 m, black seals with yellow guides, red numerals; the red corrugated canopy (0.9 m fascia, 2.5 m out, 9.6 m long); the grey concrete pier at the corner |
| Raised dock, steps | a 2 m platform | a 1.5 m platform, the landing and five concrete steps east with pipe rails, a white man door, an electrical box |
| Compactor | a box at (-176, -17) on the north face | the head on the wall south of the steps (z -2.7..-0.1), the roll-off (`bl_ex_dumpster`) pointing east on its pad, a chain-link fence behind |
| Rail | a yellow pipe on the platform | the galvanized two-rail on a curb along the apron's north edge, 12 m |
| Tree | none | a curbed bed (x -151..-143, z -22.6..-15.4) with a **live oak** and four clipped hollies, between the apron and the tank yard |
The north face keeps the "JCPenney" letters and the Package Pick-up; nothing else is on it. No customer walk, curb
or fire lane on the east face (it had a fire lane); stalls keep out of x -156..-134, z -26..6.

### C. The green boxes (`bl_ex_dumpster`, `tools/blender/assets_src/`)
A steel roll-off compactor container, 6.4 x 2.3 x 2.1 m, **700 triangles, one 1024 atlas**: vertical channel ribs
between a top and a bottom rail, a sloped nose on legs with the hook bar, the door end with cross ribs and a ratchet
bar, skid rails on rollers, two hinged lids, chipped paint, rust low down, stains from the lid seams. Placed by
`docks.gd dumpster()` on a 6 cm concrete pad as a dynamic mesh (like the 3D signs: no lightmap of its own). Only the
baked albedo ships in the game (the model's ORM and normal maps are not referenced by the scene). No lettering.

### Calls and guesses
- **Steven's note vs the footage:** they agree at both docks. One reading to flag: "an opening in the wall" is built
  as the court's whole mouth (the wall ends at x -52 and the next 14 m to Dillard's is open), because that is what
  f026 shows; there is no second piece of wall east of the opening.
- **Steven's note wins over the footage:** the containers stay **green** in both years (he said keep them); the
  filmed ones are tan today.
- GUESS: the court's depth (18 m; 18-22 m by perspective); the court as 10 m of cut wing plus the lane (the real
  lane is north of the dock and the dock canopy closes it; here the lane stays open beside the dock, Nov 4 decision);
  the door in the wing block's wall and the enclosure's exact size; everything in 1990s form (no period picture of
  either dock: built as filmed in both years); the container's lids; JCPenney's parapet height on the dock face
  (9.5 m as the rest of the rear, the footage reads ~7.5 m: not changed, the shell is not this job's).
- Known gaps: JCPenney's truck apron is **flat** (the filmed one is a shallow well below the walk; the rail and
  curb are there, the drop is not); the apron and the court have the lot's concrete, not their own darker slab;
  the benches at Dillard's base and the dome camera at JCPenney's corner are not built; the enclosure's planks are
  the dark fence wood (the filmed ones are weathered grey).

### Tests (cloud, unbaked)
- `--wing=3` and `--wing=3 --year=2026`: BUILD OK.
- `tools/qa/ext_door_test.gd`, both years: PASS.
- `tools/qa/ext_docks_test.gd` (new, headless, both years): PASS. The wing wall cannot be walked through anywhere
  on x -134..-52; the opening x -47..-39 is clear; the court and the service lane are reached on foot from the lot;
  the old dock / trailer / box spots are open lot; JCPenney's apron is reached from the staff lot; docks, compactor,
  containers, rail, enclosure and tree bed block.
- `movetest.py` wing 3 (export `.scratch/builds/docks`, all wings so the prefetch finds its packs), 1990s and 2026:
  4 cameras, **0 errors**; the touch walk goes through the opening (z 126 -> 120). `wsDOCK-web-movetest-unbaked.jpg`.
- Packs (this box, no lightmaps): `w3` 102,116,404 -> 102,332,068 B (+0.22 MB), `w3y26` 87,074,576 -> 87,294,372 B
  (+0.22 MB). **Watch `w3y26`:** EXT-SIGNS measured it at 103.8 MB with its lightmap against GitHub's 104.9 MB
  file limit; this adds ~0.2 MB.

### For the Mac (integration)
1. Rebuild wing 3, both years (`gen/w3`, `gen/w3y26`, `wing3.tscn`, `wing3_2026.tscn` are not committed here), then
   rebake **`wing3` and `wing3_2026`**: the wing wall, the court, both dock faces and the walks changed.
2. `tools/capture_standin.sh 3` and `3 2026` as after any wing-3 change (no door moved; s2s's side picture may show the flag island and the court's mouth).
3. No other wing changes.

## Known gaps / next
- Period photos: the main entrance, the south entrance and Dillard's are all re-skinned; the
  1995 forms are placeholders until Steven finds photos (the report's open question).
- Not filmed: the Armour Dr edge (plain here). (Both docks are filmed: EXT-DOCKS.)
- JCPenney's red south arcade, maroon west fascia and coral Package Pick-up fascia are today's
  (2012-era) treatment but still stand in the 1995 build too (open question for Steven).
- Lot furniture still sparse: no wheel stops.
