# Godot mall: the outside (wing 3, "Outside") — Demo 44, Oct 24, 2026

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
  lot's walk grid (every map tile outside a building).
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
| Main entrance (s39) | **placeholder**: flat cream canopy on square columns, glass storefront, "SOUTHLAND MALL" | 1995 form unknown (today's porte-cochère is 2000s) |
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
  strip centre along the south edge, Big Lots across the drive from the Sears side exit, Ground
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
| F6 | Big Lots, a 40 × 24 m box in the north-west lot | parking there; Big Lots is the strip across West Park Ave from Lynn's (4406 f031-035, 4413 f005-008) | moved across West Park Ave (x ≈ 152) |
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

### Door spots for Workstream E (old Sears)
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

## Known gaps / next
- Period photos: the main entrance, the south entrance and Dillard's are all re-skinned; the
  1995 forms are placeholders until Steven finds photos (the report's open question).
- Not filmed: Dillard's north dock, JCPenney's dock face, the Armour Dr edge (plain here).
- JCPenney's red south arcade, maroon west fascia and coral Package Pick-up fascia are today's
  (2012-era) treatment but still stand in the 1995 build too (open question for Steven).
- Lot furniture still sparse: no storm grates, stop signs or wheel stops.
