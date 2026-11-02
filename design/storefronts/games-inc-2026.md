# games, inc. (2026 map, store s52: the old Blockbuster Music box)

**Source (Oct 28, 2026).** Steven's Oct 23 2026 footage: IMG_4443 (the front from the hall, then
the whole depth of the store, 58 s), IMG_4444 (the air hockey end) and photo IMG_4445 (the
same, upright). Full-res frames cut at 1 fps: `2026 Mall/_derived/full/games/` on the Mac.
The directory (IMG_4455) lists the arcade as Pocket Change; the sign says games, inc.

**Accuracy level:** 3 for the room (walked end to end on video), 1 for the machines (the kinds
and where they stand are from the frames; the cabinets are Pocket Change's 1990s prop modules
standing in until each 2026 kind is painted).

**Frame.** The s52 rect, 8 x 40 m (4 x 20 tiles at x 89, y 130), on the Concourse's south side
between the vacant aqua-tile Pocket Change unit (s52b) and the food-court wall. The front faces
the hall (north); u runs along the frontage from the hall viewer's right, d into the store.
`tools/stores/games_inc/store.gd`, textures `paint.py` -> `tex/gi/`. Walkable: s52 is in
`layout_2026.json`'s `interiors_open` (and `KEEP_OPEN` in `tools/make_layout_2026.py`).

## The front (f003-f016)
- Mustard 6 x 12 glazed tile in a running bond over the whole front: piers each side, the
  frames round two display windows, and the head over a 3.8 m opening (u 2.1-5.9, 2.75 m tall).
  Tile returns run back through the front wall.
- A white panel over the opening carries the lit sign (`y26/parts/games.json`: green "games,
  inc." with the alien mascot). Hall-side star medallions on the piers either side are the
  mall's.
- Two display windows (dark frames, white sill at 0.45 m, white box behind) piled with Pokémon
  plush: Pikachu yellow, Charmander orange, Squirtle blue, Bulbasaur green. Built as soft
  coloured blocks (dynamic) for now.

## The room (f017-f058, g001-g006, IMG_4445)
- Wood-look vinyl plank floor, honey brown, 1.2 x 0.18 m planks, staggered.
- Walls: white slatwall to 2.45 m, then a red-orange band to the ceiling with a mustard stripe
  near its foot; a plush shelf runs along the right wall at 2.3 m, toys all along it.
- White 2 x 2 lay-in ceiling at ~3.4 m, parabolic troffers in two rows about every 3 m, a few
  black track spots. One white round pipe column mid-store (~20 m in), a thin black steel one
  further back (~29 m).
- Left, walking in: a party corner, two white folding tables with benches under a navy wall
  mural ("games, inc. CLAW MANIA", claws, a neon horizon); then the orange "GALACTIC PRIZE
  PORTAL" counter: lit glass showcases of small prizes with the big-prize plush wall behind, and
  a token changer past it. (Built with Pocket Change's `redeem` module: the counter 1.95 m off
  the wall, the prize wall on the wall, 5.4 m long, centred 8.3 m in.)
- Right wall: a long run of claw machines in LED-framed cabinets, front to back in banks with
  breathing room (five banks of four here, from 1.35 m in).
- Left wall past the counter: more claws, then four upright ticket/arcade cabinets (Crossy
  Road, a wheel game and the like in the footage; `video` uprights stand in), two more claws,
  two sit-down racers.
- The middle, front to back: a double coin pusher behind the party corner (11 m), two dome
  ticket games (the pink/blue drop domes with the "TAP" button in f045-f058; the `cyclone`
  stands in) at 15.4 and 18.2 m, two air hockey tables across the room at 24.4 and ~28 m
  (g001-g003), two kiddie rides at 33.4 m (the yellow motorbikes, g005-g006), four uprights on
  the back wall. The back door with its exit sign is on the right of the back wall.

## Guessed / to do
- Machine identities and cabinet art: paint the 2026 kinds from the frames (claws: white
  cabinets with RGB edge lighting and big plush; dome drop games; Crossy Road; the wheel game;
  the yellow kiddie motorbikes; the big "Deal or No Deal"-type ticket cabinets at the back).
  Steven asked for the games to be researched online against the frames.
- The plush windows and the shelf toys as real plush (a painted window texture would be
  cheaper and better than blocks).
- Exact counter and party-table positions (estimated from the walk; the counter's end is
  visible in f025-f027 about 10 m in).
- Whether the arcade keeps a service door to the vacant unit next door (not seen).

## Nov 2, 2026 (workstream GI): inventory from the walkthrough, before the rebuild

Steven (Nov 2): the Demo 46 room was Pocket Change's 1990s machines thrown into the box: "that's not the
setup." Games, Inc. gets its own kit. **Source:** the walkthrough IMG_4443 (f001-f058) and IMG_4444
(g001-g006), full-res 1 fps frames in the refs pack (`refs/derived/full/games/`), plus photo IMG_4445
(the air hockey end looking back to the front; shot sideways, rotate 90° clockwise). No narration after 28 s.
There is no newer games, inc. cut in `refs/new/`.

**Corrections to the Demo 46 reading.** Walking in, the **prize counter is on the left** (behind the plush
window) and the **party corner with the CLAW MANIA mural is on the right** (behind the right-hand glass
bay); Demo 46 had them the other way round. The long run of LED claws is on the **left** wall, from the
counter's end to the back; the right wall carries the coin pushers, the big cabinets and the white prize
merchandisers. The two air hockey tables stand **lengthwise**, side by side. The "kiddie rides" are two
sit-on **motorbike racers** by the back-right corner. The ceiling troffers are **2 x 2 parabolic louvres**
(nine cells), not 2 x 4.

**Frame of reference.** u = metres from the right wall (food-court side, the hall viewer's right, u 0) to
the left wall (the vacant aqua-tile unit s52b, u 8); d = metres in from the hall face. "R" = the right
wall walking in, "L" = the left wall. Sizes are estimated from the 30 cm hall floor tiles (front), the 61 cm
ceiling grid and 1.2 m floor planks (inside), standard fixture sizes (6 ft showcases, 8 ft folding
tables) and the cabinets' published footprints where known. Positions are ± 1 m in d.

### Room and fixtures

| # | Thing | Where (u, d) | Size | Colours / light | Frames |
|---|---|---|---|---|---|
| F1 | Front: mustard 6x12 glazed tile frame (stack bond) round three bays; cream mall wall above; white piers each end | front, u 0-8 | tile head to ~3.25 m | tile #cfa33a-#d7ad46 | f003-f016 |
| F2 | Right glass bay: frameless glass pair (no frame, floor track), closed; a ceiling camera dome inside | u 0.3-2.1 | 1.8 x 3.0 m | clear | f003, f014-f016 |
| F3 | Opening with the white sign panel in its top ("games, inc." green letters, alien mascot: `y26/parts/games.json`) | u 2.45-5.05 | clear 2.35 m; panel 2.35-2.95 m | white panel, green/navy letters | f011-f018 |
| F4 | Left display window piled with big plush (character plush: built as generic soft shapes) | u 5.4-7.7 | glass 0.1-2.95 m, box ~0.55 deep | plush yellow/orange/blue/cream | f003-f011 |
| F5 | A-frame poster stands, black with neon-print menus ("LEVEL UP", "WEEKDAY SAVINGS") | inside the opening, u ~2.6 d 0.9; behind F2 u ~1.6 d 0.8 | 0.6 x 1.5 m | black, cyan/green/pink print | f012-f017 |
| F6 | Inside header over F2: "CLAW MANIA" on a navy band | front wall inside, u 0.3-2.5, y 2.45-2.95 | | navy, green letters | IMG_4445 |
| F7 | Floor: wood-look vinyl plank, mid honey-brown, 1.2 x 0.18 m, random tones | whole room | | #a87a52 ±, satin | all |
| F8 | Walls: white/off-white below; a white shelf on brackets at ~2.42 m with a thin mustard band just under it; red-orange band from the shelf to the ceiling | R, L, back | band 2.42-3.4 m | #f1efea, #e0a62c, #c9472a | f021-f034, f052 |
| F9 | Beige horizontal slatwall instead of white: right wall from ~18 m back, the back wall | R d 18-39, back | | #d9cbb0 | f038-f039, f052, g004-g006 |
| F10 | Prize-counter wall: solid orange from the floor up behind the prize shelving | L d 0.6-9.4 | | #e8732a | f019, f025-f027 |
| F11 | Ceiling: white 2x2 lay-in at ~3.4 m; 2x2 nine-cell parabolic louvre troffers (some warm, most read cool/violet from the room's LEDs), square diffusers, return grilles; two runs of black track with spot heads along the room | | | | f019-f040, g001 |
| F12 | White round pipe column | u ~3.5, d ~20 | Ø 0.3 m | white | f021?, IMG_4445 |
| F13 | Thin black steel pole between the air hockey tables | u ~4.0, d ~28 | Ø 0.1 m | black | g001-g003, IMG_4445 |
| F14 | Back wall: exit door (open, into a lit back room) with a red EXIT sign over it | back, u ~1.4-2.3 | 0.9 x 2.1 m | door yellow-cream frame | g005-g006 |
| F15 | Plush on the wall shelves: character plush over the counter and the right wall's front half; big inflatable alien figures (purple, green, blue, pink) over the left-wall claws | shelf, y 2.45+ | | | f021, f028, f041-f046, g002 |

### The prize counter ("GALACTIC PRIZE PORTAL", left, walking in)

| # | Thing | Where | Size | Colours / light | Frames |
|---|---|---|---|---|---|
| P1 | Prize wall: black slatwall shelving, 6 shelves of small prizes with green price tags, plush on the top shelf | L wall, d 1.0-9.3 | 2.2 m tall | black, prize colours | f019, f025-f027 |
| P2 | "GALACTIC PRIZE PORTAL" panel: green/cyan neon lettering on a dark starfield | L wall over P1, d ~2.4-4.6 | 2.0 x 0.6 m | dark navy, cyan/green | f017-f027 |
| P3 | Two wall TVs (ticket leader board, prize menu) | L wall, d ~5.6 and ~7.2, y ~2.6 | 0.9 x 0.5 m | black screens, yellow/white text | f019, f027 |
| P4 | Glass showcases, LED-edged: two on the aisle at the front (pink and blue edge light), one at the far end (white) | counter line u ~5.7-6.3, d 1.2-3.0, 3.05-4.85, 7.75-9.55 | 1.83 x 0.56 x 0.97 m | white base, LED edges | f017-f028 |
| P5 | Black counter with the register between the showcases | u ~5.7-6.3, d 4.9-7.7 | 0.97 m tall | black laminate | f019, f027 |
| P6 | Two card kiosks (blue touch screens on black pedestals) | L wall, d ~9.9 and ~10.6 | 0.5 x 0.45 x 1.5 m | black, blue screen | f027-f028 |

### The party corner (right, walking in)

| # | Thing | Where | Size | Colours | Frames |
|---|---|---|---|---|---|
| Q1 | Mural banner "games, inc. CLAW MANIA": navy, a synthwave grid horizon in cyan/violet, small claws, UFOs and aliens (all generic shapes) | R wall, d 1.3-4.6, y 0.55-2.4 | 3.3 x 1.85 m | navy #18204a, cyan, violet, white/green letters | f015, f021-f023 |
| Q2 | Two white folding tables (8 ft) with attached benches, lengthwise, with table-tent menus | u ~0.95 and ~2.55, d 1.4-3.85 | 0.76 x 2.44 m | off-white, grey legs | f012-f013, f021-f023 |
| Q3 | Black swing-lid trash can | u ~3.2, d ~2.4 | Ø 0.45 x 0.9 m | black | f022 |

### The machines

Names are as printed on the cabinet where legible. Licensed character art (Pokémon plush on top, the
superhero pusher's topper, the dinosaur cabinet's side art, the woman's portrait cabinet, the board-game
mascot) is **not reproduced**: those areas become generic abstract translites in the cabinet's colours.

| # | Machine (as printed) | Kind | Where (u, d), facing | Size w x d x h | Colours / light | Frames |
|---|---|---|---|---|---|---|
| M1 | LED claws (white cabinets, round "pill" marquee, LED-studded edges, a colour-lit lower body with a big rounded prize door). ~28 in one continuous run, colours repeating green, white/pink, blue, red, white/violet | crane | L wall d ~11.2 to ~35.8, facing R | 0.82 x 0.86 x 2.05 each | white; green #3cff4a, pink #ff4fa8, blue #3b6bff, red #ff2a3a, violet | f020, f028-f030, f041-f046, f055-f058, g001-g002, IMG_4445 |
| M2 | First claws of the left run: a white merchandiser with plush on top and a yellow-front "locker" claw | crane / merchandiser | L wall d ~11.2-12.8 | 0.8 x 0.85 x 1.95 | white, yellow | f028-f029 |
| M3 | White claw (character plush on the shelf over it) | crane | R wall d ~5.0-5.85, facing L | 0.85 x 0.9 x 2.0 | white, cyan marquee | f012, f021-f023 |
| M4 | Two-player coin pusher with a superhero topper (topper → generic burst translite) and red LED edge strips, two stools | pusher | R wall d ~6.0-8.0, facing L | 1.95 x 1.25 x 2.4 | royal blue, red LED, chrome stools with blue seats | f012, f021-f024 |
| M5 | "MONOPOLY ROLL-N-GO"-type dice tower: tall column, 1000/10 ticket windows, a big lit die in a front bay, "SWIPE CARD" | ticket tower | middle u ~4.6, d ~12.0, facing the front | 0.9 x 0.9 x 2.6 | red/yellow/orange panels, cyan base glow | f020, f024, f028-f031 |
| M6 | Two-player cabinet with a portrait side panel (art → generic), TAP readers and red buttons on a long deck, two blue stools | pusher-style 2P | R wall d ~11.0-12.8, facing L | 1.8 x 1.1 x 2.1 | white/purple side, red/blue LEDs | f029-f034 |
| M7 | Big two-player gun cabinet, dinosaur topper, "ARCADE" side, green LED arch round the screen | gun cabinet | R wall d ~13.2-15.0, facing L | 1.8 x 1.4 x 2.6 | dark grey/jungle green, red base, green LEDs | f031-f033, f035 |
| M8 | Twin sit-down racer, red bucket seats on yellow bases | racer | R wall d ~15.4-17.6, facing L | 2.2 x 1.9 x 2.0 | red seats, yellow/black bases | f035, f037 |
| M9 | "NERF" gun upright (red cabinet) | gun upright | R wall d ~17.7-18.6, facing L | 0.9 x 1.1 x 2.1 | red, blue screen frame | f036-f038 |
| M10 | "DEAL OR NO DEAL" (tall cabinet, yellow DEAL marquee, a keypad console of lit case buttons, yellow-lit hexagonal platform with a chrome stool) | ticket game | R wall d ~18.8-20.3, facing L | 1.5 x 2.3 x 2.6 | black, yellow #ffd22a, red buttons | f036-f039 |
| M11 | "BASKETBALL PRO" (single-player hoop cabinet, short ramp) | hoops | R wall d ~20.4-21.3, facing L | 0.9 x 2.4 x 2.6 | blue/red, yellow marquee | f038-f039 |
| M12 | Prize tower with a "…ER" topper and a yellow cartoon-print base (name not legible) | prize tower | R wall d ~21.4-22.3, facing L | 0.9 x 0.9 x 2.3 | yellow/orange base, clear tower | f039, f052 |
| M13 | "DIZZY CHICKEN" (round acrylic tower, chicken-head topper, orange/yellow base) | prize tower | R wall d ~22.4-23.4, facing L | 1.0 x 1.0 x 2.5 | red-orange, yellow, blue LEDs | f052 |
| M14 | "PUSH" merchandiser (black cabinet with a blue grid print) | merchandiser | R wall d ~23.5-24.3, facing L | 0.8 x 0.85 x 2.0 | black, blue grid | f052-f053 |
| M15 | White prize merchandisers (one "SUPER STAR"-type blue marquee, the rest white), five in a row | merchandiser | R wall d ~24.5-28.8, facing L | 0.85 x 0.9 x 2.0 each | white, blue/yellow marquees | f053, IMG_4445 |
| M16 | Yellow merchandiser with a red ring door | merchandiser | R wall d ~29.0-29.8, facing L | 0.8 x 0.85 x 2.0 | yellow, red | f053 |
| M17 | "CROSSY ROAD" arcade (tall LED-framed screen, wide lime/black control deck with big buttons, blocky chicken side art → generic blocks) | video | middle u ~4.4, d ~17.6, facing the back | 1.25 x 1.2 x 2.5 | lime #b9d532, black, RGB LED frame | f036-f037, f042-f044, IMG_4445 |
| M18 | Tall black upright with a cartoon mascot cut-out (mascot → plain black panel) | upright | middle u ~4.6, d ~16.2, facing the front | 0.8 x 0.9 x 2.5 | black, red trim | f036-f037 |
| M19 | Pink drop-dome ticket game ("TAP" reader, red LED "100", neon rings under a clear dome, octagonal cabinet) | dome | middle u ~5.2, d ~19.6 | 1.15 x 1.15 x 1.65 | hot pink, yellow rim, grey sides | f040-f050 |
| M20 | Blue drop-dome ticket game (the same model in blue) | dome | middle u ~5.2, d ~22.4 | 1.15 x 1.15 x 1.65 | blue, yellow rim | f055-f058 |
| M21 | Wheel game ("…QUEST" on the base; a tall blue wheel on a blue cabinet) | wheel | middle u ~4.0, d ~21.2, facing the back | 1.1 x 0.9 x 2.6 | royal blue, multicolour wheel | f046-f051, IMG_4445 |
| M22 | Neon-arch ticket game (green "…TICKETS" column, small dome under a neon arch) | ticket game | middle u ~3.3, d ~24.6 | 1.0 x 1.0 x 2.0 | green, red, neon | g001, IMG_4445 |
| M23 | Air hockey, red/orange with a curved overhead score arch | air hockey | u ~5.0, d 26.4-28.8, lengthwise | 1.3 x 2.4 x 0.8 (arch 2.2) | red-orange, black, flame print | g001-g003, IMG_4445 |
| M24 | Air hockey, blue with a yellow rail | air hockey | u ~2.9, d 26.4-28.8, lengthwise | 1.3 x 2.4 x 0.8 | blue, yellow, pink puck | g001-g003 |
| M25 | Two blue alley-roller lanes with red LED scores and green-lit gutters (name not legible) | alley | back wall, u ~5.3-7.1, lanes along d | 0.9 x 2.7 x 2.2 each | blue, orange panels, green LED | g004 |
| M26 | Purple/pink prize cabinet beside the alleys (blurred, name not legible) | merchandiser | back wall, u ~4.3-5.1 | 0.85 x 0.9 x 2.2 | purple, pink | g004 |
| M27 | Big-eyed drop column (15 / 40 / 25 value windows) | drop game | back wall, u ~3.3-4.1, facing the front | 0.8 x 0.9 x 2.5 | blue, lime, pink | g005 |
| M28 | "QUIK DROP" (round red marquee) | drop game | back wall, u ~2.5-3.2, facing the front | 0.7 x 0.8 x 2.4 | red ring, blue cabinet | g005-g006 |
| M29 | Music game cabinet with a plush on top (guitar controllers) | upright | back-right, u ~0.2-1.1 (back wall) | 0.9 x 1.0 x 2.3 | black, red | g005-g006 |
| M30 | Two sit-on motorbike racers (yellow/black bikes, screens on the right wall) | racer | R wall d ~33.4-37.4, facing R | 1.0 x 2.2 x 1.9 each | yellow, black, chrome | g005-g006 |

**Not seen in the walkthrough:** the right wall between ~30 and ~33 m (left empty; not invented); the
back-left corner behind the alleys; what is on the counter's staff side; the front wall's inside left of
the opening (the plush window's back); the ceiling at the very back; any machine names that are blurred
(M12, M22, M25, M26). Positions in d are ± 1 m.
