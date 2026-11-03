# Pocket Change: front and arcade (1995 map, store s52b)

**Sources (Oct 5, 2026).** Steven's photos:
- **The Southland store in 2009**, taken from the hall on the Chick-fil-A side, looking toward FYE (Blockbuster Music in 1995). Steven: "that's actually at the Southland Mall in 2009, but it's exactly how it looked in the 90s."
- **Other Pocket Change arcades of the 1990s–2000s**, for the interior: a 1995 front at Granite Run Mall, a food-court front with lit glass-block columns, a blue-lit interior, and a token changer.
- **The machine types:** a basketball cage row and a pair of skee-ball alleys.

Steven's description of the interior: the ticket redemption counter on the left as you walk in, claw machines, about four skee-ball, four basketball, the sit-in dinosaur ride in the middle, and the usual video games. "It was very dark."

**Accuracy level:** 2–3. The front is from one angled photo. The room is from memory and same-chain references.

**Guessed (not from Southland photos):**
- the room's finishes (black ceiling, dark walls, blue band and neon);
- the exact layout and machine count;
- the token rate.

The machines' titles and art are original: real titles and logos are not reproduced. The cabinet shapes, sizes and layouts follow the real 1990s machine types.

**Frame.**
- **The unit:** the store is 8 m wide and 40 m deep (map tiles x 93–96, y 130–149) and faces the Concourse (H5) to the north.
- **u** runs along the frontage from x = −110 (the viewer's right, toward Blockbuster Music/FYE) to x = −102 (u = 8, toward Chick-fil-A).
- **d** runs into the store (+z); d < 0 is out in the hall.

## Front (from the 2009 photo)
- **Wall tile.** Pale blue-green (Steven: "bluish green") 12-inch glazed tile with light-grey grout. On both sides of the entrance it climbs the mall's wall in steps, one tile column per step. Next to the fascia the columns are 9, 8, 7, 6 and 5 rows tall (2.7 m down to 1.5 m). The mall's own plaster wall is above and beyond.
- **Glass-block columns.** One clear 8-inch block wide and one deep (0.2 × 0.2 m). They stand 0.2 m out from the wall on tile plinths and run from 0.15 m up to the fascia at 2.4 m, about 11 blocks. That makes the opening ~4.6 m wide and 2.4 m tall.
- **Fascia.** A tile-clad box over the opening, spanning both columns: 5.0 m long (u 1.5–6.5) and ~1.05 m tall (2.4–3.45 m). It stands 0.2 m proud of the wall, with a polished stainless underside (the bright strip in the photo).
- **Letters.** "POCKET CHANGE" in raised channel letters: a heavy grotesque in caps, near-white brushed faces with grey returns. The caps are 0.35 m, the letters 7 cm deep and 2.5 cm off the tile. They start ~0.42 m in from the fascia's left end and fill it to near the right end, with the baseline at 2.9 m. The outlines are FreeSans Bold (a Helvetica clone), from `make_letters.py`.
- **Inside the opening.** Royal-blue returns run 0.8 m back through the front wall, with a small notice sign on the right return (2009: a camera notice; 1995 wording unknown). The head is black over the returns. The arcade carpet starts at the threshold.
- **Not lit.** The letters are non-illuminated, and the hall lighting shows them.

## Inside (walkable, dark)
- **Room.**
  - Ceiling: black lay-in at 3.6 m.
  - Walls: dark charcoal-navy, with a royal-blue band at 2.45–2.6 m and a blue neon tube along both side walls at 3.3 m.
  - Floor: a plain dark charcoal cut-pile carpet, one solid colour with no pattern and no glow (Steven, Oct 6, 2026: "remove the graphics from pocket change carpet just make it solid dark color").
  - Light: black can downlights down the room, with glowing lamp faces (in Godot 4.7 the bake takes its light mostly from emission), and three brighter ones over the redemption counter. With the machines' screens, marquees and lamps, that keeps the room dark but readable (until Oct 6 the carpet also had a glowing confetti pattern; it was removed at Steven's request). The first full-quality bake without the glowing lamp faces and carpet came out nearly black.
  - Back: an employees-only door with an exit sign.
- **Layout (Steven, Oct 6).** Walking in, everything on the right stands flush against the right wall in one line, front to back:
  - three claw machines (styles 0–2), d 0.85–3.3;
  - four skee-ball alleys, played toward the wall, d 3.4–6.4;
  - four basketball games, d 6.5–10.6;
  - then video games to the back.

  On the left:
  - the token changers against the front wall;
  - the redemption counter (a 1.6 m return, then a 5 m glass showcase facing the room, d 3.1–8.1), with the 5 m prize wall behind it;
  - then video games, the two twin racers (d 14.5–18.3), more video games, three pinball machines (d 29–31.6), and video games up to the back door.

  The middle:
  - the sit-in dinosaur ride (d 11.4–14.0), its doorway toward the entrance, so you can step in;
  - an island of back-to-back uprights (d 18.6–20.7);
  - two air hockey tables end to end (d 25.6–28 and 30.8–33.3).

  The air hockey tables match Steven's photo: white and silver cabinet, blue stripe, blue playfield, a chrome arch with a lamp and score unit, clear side guards.

  Three more uprights stand on the back wall.
- **The blue band** under the neon (2.4–2.62 m) is not in the lightmap. At 15 cm it was one texel tall and broke into blocks (Steven's phone, Oct 6). It is now probe-lit with a soft glow of its own.
- **Machines.** Each is a prop module in `tools/stores/pocket_change/` (contract in its README.md): crane, skee, hoops, ride, video, driver (racers and pinball) and redeem (counter, prize wall, tokens). airhockey (from Steven's photo, Oct 6). Each module has a texture painter (`paint_<m>.py` → `tex/pc/<m>_*.png`).

## Period notes (1995)
- **No anachronisms:** CRT screens, backlit marquees, red 7-segment scores, coin doors with token slots, orange ticket strips. No LCDs, card readers or LED boards.
- **The ride.** Steven remembers the Lost World ride, but that came out in 1997. The 1995 map has the earlier (1994-era) enclosed dinosaur-safari motion ride type. A 1997+ year map can carry the Lost World style.
- **Which games.** Steven will list the actual games. Each listed game's cabinet type, colours and layout can then be matched, without copying its art or logo.

## Build notes
- `store.gd` builds:
  - the front, into the hall's (H5) mesh;
  - the room, into `pc_shell`;
  - the machines, into `pc0_mach` … `pc3_mach` (one mesh per 10 m, for culling), at a coarse lightmap texel (1.5×), with compressed vertex data for the dynamic parts.
- **Lightmap atlas.** Plush, the skee-ball rings and other tiny faces go to the dynamic meshes and are lit by probes. In the lightmap, thousands of tiny charts had doubled the atlas. The atlas is now 5 × 1024² layers (was 4); the `.exr.import`'s `slices/vertical` must come back from the Mac with each bake.
- **Sign letters.** These are dynamic, lit by probes plus a little emission standing in for the hall's light.
- **Walk grid.** `tools/open_interiors.py` opens the whole unit. Machine obstacles are padded 0.25 m so the camera stays out of the cabinets.
- **Store probe.** The store has its own interior ReflectionProbe.
- **`BUILT_RECTS`** keeps the neighbours' generic interiors out.
- **Previews.** `tools/qa/preview.sh "store:POCKET CHANGE" …` renders the store without a bake.

## Changes from Steven, Oct 6 (12:22) — Demo 9
- **The right-hand line moved back.** Claws, skee-ball, basketball and the video row now start 3 m further back (`RIGHT_BACK` in store.gd).
- **The feature game, dead centre inside the door:** a 1995 light-ring ticket game after ICE's Cyclone in Steven's video (`Go20o7LBn4c`; the pink-and-grey 1995 cabinet).
  - It ships as **WHIRLWIND**, an original name and decal; the name is owner-editable.
  - Module `cyclone.gd`, `paint_cyclone.py`; the lamps are animated at run time by `scripts/cyclone_lights.gd`:
    - the ring chase laps every 1.2 s;
    - every 10 s the ring flashes 4 times and the chase reverses;
    - the neon coils take turns green → pink → cyan, ~0.5 s each;
    - the tower lamps blink alternately.
- **A 3-player coin pusher behind it:** the Silver Skis structure, with a marquee in the style of Steven's Coin Galaxy graphic.
  - It ships as **COIN COMET**, an original name, editable, with original space art on the translites.
  - Module `pusher.gd`, `paint_pusher.py`.

## WHIRLWIND is playable (Steven, Oct 9, 2026)
Source: Steven's video of a working machine (`cyclone-ticket-redemption-game-from-ice-arcade-game-review.mp4`, a 1990s three-player cabinet with the narrator explaining the settings).
- **Page:** `play/whirlwind.html` (+ `play/whirlwind/`: `logic.js` and textures). Opened from the cabinet: stand at its console, facing it, and press Play (tap, E/Enter, or a pad's A; `scripts/signs.gd` `_near_whirlwind`). It runs in the same full-window frame as the arcade's `emu.html` and posts `emu-close` to come back. It also works on its own link.
- **What the video gives (measured):**
  - The chase laps in **1.62 s** (fitted over 20 s of play; the narrator says about 1.5 s). On the 64-lamp ring that is 25.3 ms a lamp.
  - **Difficulty** is the window in milliseconds the player has to press while the light is on the bonus, 1 (hardest) to 20. The factory setting is **3 ms**, which is what we use (Steven: keep it fixed).
  - The **bonus** starts at 100, +1 for every game that misses it, and goes back to 100 when won.
  - After a bonus win the lights flash for about **11.5 s**, then TICKETS OWED jumps to the amount and counts down while tickets feed at about **2.5 a second** (102 → 45 in 23 s), in runs with small stalls; the LED shows "Cr 00" now and then.
  - Not in the video: a small win, and the ring's numbers.
- **Steven's decisions (09:27):**
  - The view is from the console, looking down into the dome.
  - On the bonus lamp but outside the 3 ms window, the light stops on the next lamp (10 tickets).
  - There is a SKIP button for the payout.
  - The bonus keeps growing in the player's browser between visits (`localStorage` "whirlwind.bonus"); the best $1.00 total is "whirlwind.best".
  - The ring values are the cabinet's 1–10 (`ring_values`).
- **Play:** $1.00 is 4 plays. START puts the dollar in and starts play 1; after each payout the action button drops the next quarter. After play 4 it shows the total and the best.
- **Timing:** presses are judged from the input event's own timestamp, not the frame, so the 3 ms window is real on keyboard, mouse and touch. Gamepads use the pad's timestamp when it is fresh, otherwise the frame time.
- **Guessed:** a small win's flash (1.5 s before the payout), the sounds (synthesized, not the real machine's), green tickets as in the video.
- **Textures:** `tools/stores/pocket_change/paint_whirlwind_game.py` re-runs the cabinet's painters, with the playfield at 2048 px.
- **Tests:** `node tests/unit/whirlwind/logic.test.js` covers the window, the next-lamp rule, the bonus, the payout rate, and the win odds (3/1620 for random presses).
- **The START blink (Oct 11):** Steven: the button only told "stop" from "start" by how the lights spun. While a play is waiting to be started (and on the title and game-over screens) the STOP button now flashes hard, 0.3 s on and 0.3 s off, with a bright green glow; while the light chases it is steadily lit. (The touch-timing offset tried this morning was dropped at his request.)

## SKEE-BALL is playable (Steven, Oct 11, 2026)
Source: Steven's video of a restored classic ten-foot alley (`tnt-amusements-382-10-foot-classic-skeeball-arcade-machine-with-the-corner-100s.mp4`, a TNT Amusements showroom segment). The talk is mostly about the restoration, not the rules. The frames give the game.
- **Page:** `play/skeeball.html?lane=<1..4>` (+ `play/skeeball/`: `logic.js` and textures; `play/lib/three.min.js`, three.js r160, MIT). Opened from any of the four alleys: stand at its front, facing up it, and press Play (tap, E/Enter, or a pad's A; `scripts/signs.gd` `_near_skee`). It runs in the same full-window frame as `emu.html` and `whirlwind.html` and posts `emu-close` to come back.
- **Which alley you are on:** the page builds all four alleys side by side as they stand in the mall (from the player's left: 4, 3, 2, 1, `store.gd` wall_run) and stands you at the one you walked up to, so the neighbours are beside you. The others show their attract scores; the 3's WINNER beacon is lit, as in the mall.
- **What the video gives:**
  - **9 balls** a game. The LED shows the score (3 digits, multiples of 10) and the balls played; a ball counts when it drops through a hole.
  - A good roller takes about **2.4 s a ball** (0 → 250 in 9 balls, 1:32 to 1:51), often with the last ball still on the board.
  - The board: rings 10, 20, 30 round a 40 cup, a 50 cup above, and the two **corner 100s**. The mall alley's board (`paint_skee.py` RINGS/HOLES) has the same layout, so the page uses it.
  - Not in the video: price, ticket table, settings.
- **The roll (Steven: "based on clicks for accuracy, how long you hold down the ball, where you're lining it up"):**
  - Press and hold to pick up the ball; slide (or ← →, a pad's stick) to line it up across the lane.
  - While held, the meter fills in 0.95 s, then falls back and rises again. Let go to roll: the meter sets the release speed, 2.6 to 5.0 m/s.
  - A touch release is read 55 ms earlier, as WHIRLWIND's touch timing.
  - Each roll has a small imperfection (±1.2 % speed, ±0.35°), as a real lane does.
- **Physics** (`logic.js` `roll`): a ball rolling on the lane (5/7 of g's slope pull, rolling resistance), up the hump, off its lip, through the air onto the board, against the side walls, the wire cage and the back. On the board the rims are walls a ball has to hop. A ball rolling into one faster than a threshold hops it; slower, it bounces off. A ball over a hole slowly enough drops. A ball that falls short drops into the gutter, or rolls back to you, for 0. A hard roll up the side can reach a 100; up the middle, the 50.
- **Tickets (guessed):** 1 per 30 points, plus 5 for each 100 pocket. The mall alley's front says "TICKETS PAID ON SCORE" and "100 POCKETS = BONUS". They feed at 2.5 a second, as WHIRLWIND's; SKIP finishes the payout.
- **Saved in the browser:** the best score (`skeeball.best`) and sound on/off.
- **Guessed:** the ticket table and pocket bonus, the meter, every physics constant (tuned by sweeping position × power: about 50 % 10s, 16 % 20s, 10 % 30s, 2.5 % 40s, 3.4 % 50s, 3.4 % 100s, 15 % zeros over all rolls), and the sounds (synthesized).
- **Textures:** `tools/stores/pocket_change/paint_skeeball_game.py` re-encodes the mall alley's own textures (`tex/pc/skee_*.png`) as WebP.
- **Tests:** `node tests/unit/skeeball/logic.test.js` covers the meter, the speed range, the board frame, every roll ending with a real value, determinism, where soft and hard rolls go, how rare 100s are, and the ticket table.

## CLAW is playable (Steven, Oct 11, 2026)
Source: Steven's video of a crane repair (`claw-machine-repair-watch-us-diagnose-and-fix-this-claw-machine.mp4`, Galaxy Games 843, 31 min). It is a wiring repair, so it gives the machine's cycle and nothing about play settings.
- **Page:** `play/claw.html?machine=<1..3>&name=<title>` (+ `play/claw/`: `logic.js` and textures). Opened from any of the three cranes: stand at its control panel, facing it, and press Play (tap, E/Enter, or a pad's A; `scripts/signs.gd` `_near_crane`, nearest crane wins). Same frame and `emu-close` as the other games.
- **Which machine:** the page builds all three cranes side by side as in the mall (from the player's left: 3, 2, 1) and stands you at the one you walked up to. The neighbours hold their own piles.
- **The cycle (from the video):** on DROP the claw pays out string until it touches down; the slack-string switch closes it (not a timer). It winds up until the up-switch trips, the gantry runs home to the corner over the chute, and the claw opens. (The repairman's error 01, when the up-switch never trips, is a test hook only.)
- **Play (guessed; the mall's cabinet art says 1 TOKEN PER PLAY, EVERY PRIZE CAN BE WON):** 30 s on the clock, then the claw drops where it is. The joystick (touch stick, arrows/WASD, a pad's stick) moves the gantry at 0.14 m/s inside the box. The claw closes on the highest prize within 6 cm of its axis.
- **The grip (guessed, the usual operator setting):** every 7th play the claw grips at full strength; otherwise 30–55 %. The hold is grip × how centred × the prize's own `lift` (capsules 0.92, small plush 0.7–0.8, the rougarou 0.5, the stretch figure 0.6). Under 0.22 it does not lift; above 0.62 it carries all the way; between, it slips part way home and the prize lands in the pile where it slipped (or in the chute, if it was over it).
- **Prizes, all this mall's own characters:** Gator, Crawfish, Pelican, Nutria, Rougarou (grey, plaid shirt, jeans), the Bayou Bruiser stretch figure (green rubber, purple trunks), Captain Comet (white-and-orange astronaut plush). Capsules: 75, 100 and 200 tickets; POG sets Swamp Skull ×3, Gator Bite + Lightning, Eye Spy + 8-Ball; and one **Hologram Eye slammer** per fill, placed first so it is at the bottom of the pile (the rarest pull). Steven's reference dolls were licensed characters, so these replace them.
- **The pile persists** in the browser per machine (`claw.pile.<n>`): prizes you move stay moved, ones you win stay gone, and the attendant refills the machine when fewer than 9 are left. The mall's own cabinets still show their baked bears (a rebake would be needed to match).
- **Inventory (forward-looking, Steven: "these can all stay in the player's inventory to do things with in the future"):** every win is a record in `mall.inventory` ({id, kind, name, from, when, tickets?, pogs?, rare?}); `mall.tickets` totals the capsule tickets. The Prizes button lists them. WHIRLWIND and skee-ball do not feed this yet.
- **Textures:** `tools/stores/pocket_change/paint_claw_game.py` re-encodes the crane's own textures and paints the faces, POGs, the slammer's foil and the ticket rolls.
- **Tests:** `node tests/unit/claw/logic.test.js` (10): the fill, stacking, the target rule, the grip schedule, lifting and slipping, the chute, the limits, the records.
- **Guessed:** everything under Play and The grip, the prizes' lift values, the sounds (synthesized).

## COIN COMET is playable (workstream P, Nov 1, 2026)
Source: Steven's teardown video of a Silver Falls single-player quarter pusher (`refs/coin_pusher/`: `video.mp4` 16:44, `NOTES.md` with every mechanism's time, the transcript). Southland's machine was the three-player pusher played from both sides (COIN COMET, `pusher.gd`), so the page is one of its six positions with the Silver Falls mechanics and COIN COMET's look.
- **Page:** `play/pusher.html?pos=<1..6>&name=<title>&year=1995` (+ `play/pusher/`: `logic.js` the rules, `sim.js` the physics world, the textures; `play/lib/rapier3d-compat.mjs`, Rapier 0.19.3, Apache-2.0, the wasm inlined). Opened from any of the six positions: stand at the cabinet's front, facing it, and the action button says "Play COIN COMET" (`scripts/pusher_play.gd`, six B+C interactables under the wing's Signs node; E, a pad's X, or the touch Use button). Same frame and `emu-close` as the other games. Each position keeps its own machine in the browser (`pusher.machine.<pos>`: every coin's pose, the ledger, the lip).
- **What the video gives (measured):**
  - **The deck's crank:** period **4.5 s** (fits of the deck edge tracked against the fixed cabinet over 607.2–611.9 s at 30 fps, two reference frames: 4.46 ± 0.06 s and 4.62 ± 0.12 s; the motor close-up at 655–668 s shows the same slow turn), stroke **≈ 50 mm** (87–92 px peak to peak against quarters of 40–48 px ≈ 24.3 mm in the same frames; a crank-slider with an 11 cm rod in the sim, which only shapes the motion a little).
  - **The slot:** the chrome mechanism slides left and right along the top panel (330–345 s); quarters only, a bigger token won't go in, a penny or a dime goes in and is lost (404–450 s).
  - **The tilt:** a hanging weight; the alarm is "set up for three seconds" (675–700 s); the flipper gate in the chute swings to the house side with a loud clunk (150–175 s), and rests there with the power off.
  - **The lip:** adjustable with a Phillips screwdriver, the house's payout control (250–300 s). **The side holes** at both sides of the shelf, to the house's bucket (200–250 s).
  - **The heaps:** full to the lip on both tiers, mostly one layer with a second heaped behind the lip and at the wall (20–24 s, 362 s, 606 s).
- **What is not in the video:** the lip's height, how much shaking trips the tilt, the stake, the payout.
- **What makes it flow, and what doesn't (found in the sim):** a heap riding the deck comes back to the wall every cycle and never moves on its own; the coins that land in the gap that opens behind the heap while the deck is forward ratchet it forward (one coin's width per coin), and the coins that fall off the deck's front into the gap in front of the riser ratchet the shelf's heap the same way. So the slot drops the coin straight down at the wall (as the Silver Falls' chute lands its coins at the back). Mass is conserved in the steady state: what comes out is what went in, less the side holes and the tilt gate; the lip decides how much the machine stores and how far the heap spreads sideways into the holes. **But at real friction nothing flows:** a pushed coin lifts (the cost is its own weight) long before it moves a heap of hundreds (the cost is μ × their weight), so at μ ≈ 0.3 every push turned into a coin climbing onto the heap, the deck stored 1,600 coins over 1,200 drops, and not one came off the front — with no lip at all. Rumble, the drive's play, sharp or rounded edges, more solver iterations and a disordered fill did not change that. At μ 0.05–0.08 the heaps flow as a real machine's do. Shipped: **0.06** on coin and steel, written down as a tuning, not a measurement (real cupronickel is about 0.3; whatever lets a real heap creep — reeded edges, the deck's hammering, a steeper pile than a 60 fps sim can afford — is not in this model). The side holes were narrowed to 2.5 cm × 9 cm (4–13 cm behind the edge) because at low friction the spreading heap fed them ten times the cup.
- **Physics** (`sim.js`): Rapier, 120 Hz fixed steps, up to 3 a frame (a slow frame runs the machine slow rather than spiralling). Real quarters: 24.26 × 1.75 mm, 5.67 g (density 7.01), rounded cylinders (a quarter cheaper than sharp ones in the narrow phase). Friction 0.06 (tuned, see above), restitution 0.12. The deck is a kinematic block reaching down into the shelf so nothing gets under the riser; the back wall reaches down into the deck for the same reason (a 1.2 mm gap let coins squeezed against it slip half under, and the ratchet stopped). The crank's throw is 4.5 cm plus the drive's play: at each reversal the deck stands and then snaps 2.5 mm across it (the clunk), 5.0 cm of travel. A small vertical rumble (0.1 mm, 23 Hz) stands for the motor. The fill is a hex lattice deliberately jumbled (tilts to 25°, half-coin offsets), both tiers full to the lip and the wall, settled 4 s. Dropped coins have continuous collision for their first 1.5 s. Coins over the front edge, into the side holes, or (a check) through the shelf are removed and booked.
- **Money:** quarters, a count in the player's mall state (`mall-state-<year>`.quarters, beside B+C's inventory and tickets; `scripts/inventory.gd` now carries fields it doesn't know through its round trip, so the mall's own saves keep it). A new player gets **20** ($5.00). Coins into the cup are paid 350 ms later (the chute). `logic.js CONFIG.currency = 'tickets'` switches the whole thing to `mall.tickets` at `ticketsPerCoin` each. When the page closes, the mall re-reads the state (`pusher_play.gd`), so the bag sees the new count.
- **Controls:** drag anywhere (or the slot bar at the top), ← →/A D, a pad's stick or d-pad: the mechanism slides at 30 cm/s over ±23 cm. Tap, Space/Enter/E, the DROP button, a pad's A: drop. NUDGE button, N/Shift, a pad's shoulders, or a shake of the phone (`devicemotion`, iOS asks on the first tap): a bump of the cabinet — every coin gets a jolt toward the player (1.5–4 cm/s, tuned down with the friction) and the view shakes. Nudges within 6 s add up; 2.6 full nudges (or four of the button's 0.7) trip the **TILT**: the alarm for 3 s, the gate over for 4 s; the meter at the top left shows how close. A nudge within 220 ms of the last is ignored (the cabinet is still rocking).
- **Settings (owner only, ⚙):** the lip 0–6 mm in 0.5 mm steps (default **0**, see the table), the coin count (low 450 / medium 600 / high 750; phones start at medium, computers at high), a refill; the ledger and frame times.
- **Sounds (synthesized):** the motor's hum (a 58 Hz sawtooth with its octave through a low-pass; the video's is "kind of loud") with a clunk at each dead point of the crank; a coin's clink as it lands (two ringing partials, pitch a little random); the clatter down the chute into the cup; a duller, farther clink for the house's bucket; the bump; the gate's clunk; the tilt siren. A mute button, kept in `pusher.sound`.
- **The view:** from the position's front, looking down through the glass at both tiers; the slot and the sliding mechanism at the top (plus a slot bar in the HUD), the cup at the bottom. One position of the cabinet is built from `pusher.gd`'s dimensions with its textures re-encoded (`paint_pusher_game.py`; the coin faces and the brushed steel are new and generic). The neighbouring positions' heaps are the mall's painted ones, past the fins.
- **Tests:** `node tests/unit/pusher/logic.test.js` (12: the slot, the wallet in both currencies, the tilt window and timing, the ledger, the saves); `node tests/unit/pusher/sim.test.js` (7, on Rapier: the crank, the fill, a drop, save/restore, the gate, the lip); `python3 tests/unit/pusher/page_test.py` (headless Chromium: a drop that lands, a cascade into the cup, a tilt with coins to the house, a reload keeping the machine and the quarters, frame times per quality, 0 errors); `godot --headless --script res://tools/qa/pusher_play_test.gd` (the six positions); `tools/qa/wsp_webtest.py` (the web build: the prompt, the page opens, Back returns, both sides, keyboard and touch; a scratch build needs `pusher.html`, `pusher/` and `lib/` linked in from `play/`, as the published build has them); `tools/qa/inventory_test.gd` (the carried-through quarters).
- **The soak** (`tests/unit/pusher/soak.mjs`): one position, a quarter every 1.6 s at a random x, 540 coins to start, 300 drops to warm up and 400 measured, at the shipped friction (`tests/unit/pusher/soak.mjs <lip> 540 400 1 300`, ~25 min a run):

  | lip | return to player | side holes | coins on the field after | cup a minute |
  |---|---|---|---|---|
  | 0 mm | **3.8 %** | 10.5 % | 1,161 (from 540 + 700 in) | 1.4 |
  | 0.5 mm | 0.5 % | 1.0 % | 872 (150 warm, 200 measured) | 0.2 |
  | 1 mm | 0 % | 3.0 % | 866 (150 warm, 200 measured) | 0 |
  | 2.5 mm | 0 % | 15.0 % | 1,167 | 0 |
  | 5 mm | 0 % | 17.5 % | 1,147 | 0 |

  And the player's bumps (20 of the button's 0.7-power nudges, 1.5 s apart, on a fresh machine): no lip 15 to the cup and 5 to the holes; 0.5 mm 1 and 20; 1 mm 1 and 15; 2.5 mm 0 and 3–14. **So this is not yet a paying pusher.** The ratchet works (a coin in the gap moves the heap ~0.08 cm, 80 % of its area's worth, when the heap is thin) but the heaps keep storing: after 700 drops the field holds twice what it started with and the front rows have not gone over, with or without a lip. Where a real machine's return is 60–80 % after it is full, this one returns 4 % and climbs very slowly toward that steady state. Shipped as it is because every other part works (the mall hook, the money, the tilt, the saves, the look and the sounds) and the owner's settings can take a better flow when it exists; the lip default is 0 so the player sees coins fall at all. Things not tried that might fix it: a thinner machine (COIN COMET's 52 cm position holds 14 rows of coins between the riser and the lip, the Silver Falls' about 8, and the lift-versus-push ratio is the row count); a heap that starts at a deeper, jammed steady state (saved from a very long soak and shipped as the fresh fill); a 2D granular model instead of rigid bodies; a small forward creep on the shelf standing for the hammering a real deck gives its heap.
- **Guessed:** the lip default, the tilt thresholds, the stake, friction and restitution, the rod length, the chute's drop point (straight down at the wall, as the Silver Falls' chute lands its coins at the back), every sound.
- **Performance:** the physics step in Chromium's wasm on the cloud box (x86, one core; `tests/unit/pusher/page_test.py` prints the same): low 528 coins **4.0 ms** a step, medium 609 **6.1 ms**, high 711 **7.0 ms** — at 120 Hz that is 8 / 12 / 14 ms of each 16.7 ms frame before drawing, so phones start at **low** and computers at **high** (`pusher.quality`). Nearly every coin stays awake (the deck carries half of them and the shelf's heap is one contact island), so sleeping buys nothing; the cost is the narrow phase. Not measured on a real iPhone. A slow frame gets at most 3 physics steps (the machine runs slow rather than the frame spiralling). The renderer: one instanced mesh for all coins.

## Demo 48: tickets and the tuning (Nov 2, 2026)
Steven (Nov 2): **quarters to play, tickets to win**, and a return of about 8 % with a lip.
- **Payout:** a drop still spends one quarter from `mall-state-<year>`.quarters (a new player has 20, $5.00). A coin into the cup no longer comes back as a quarter: it pays **50 tickets** to `mall.tickets` (B+C's count, the prize counter's), `logic.js CONFIG.ticketsPerCoin`. The HUD shows quarters and tickets, a "+50" rises from the cup when a coin pays (it only fades with reduced motion), the chute sound is kept. The old `currency` switch is gone.
- **Get quarters:** at 0 quarters a "Get quarters" button refills to $5.00, free. **A placeholder for a change machine** (no economy yet).
- **Since Nov 3 (ECON, `design/godot-economy.md`):** the quarters stake and "Get quarters" are gone. A drop takes 25¢ (`CONFIG.priceCents`) from the wallet shared by both years (`mall.money`, a new player $100.00); a cup coin pays 50 to the year's tickets (`mall.tickets-<year>`) the moment it falls. Leftover quarters were added to the wallet once (25¢ each). WHIRLWIND ($1.00 for 4 plays), the claw and Skee-Ball (25¢, 1 token) now charge and pay the same way.
- **The tuning (soak, `tests/unit/pusher/soak.mjs <lip> <coins> 400 1 300 '<GEOM JSON>'`, P's size: 300 drops warm, 400 measured, a coin every 1.6 s; ~70 min a run four at a time on the cloud box).** Return = coins into the cup / coins dropped. Order as asked: lip, friction, stroke/speed, heap, restitution; 11 of the 12-run cap used.

  | lip | friction | other | return % | side holes % | cup coins/min |
  |---|---|---|---|---|---|
  | 1 mm | 0.06 | P's machine (stroke 4.5 cm, period 4.5 s, 540 coins) | 0.0 | 10.8 | 0 |
  | 2 mm | 0.06 | ″ | 0.0 | 13.5 | 0 |
  | 3 mm | 0.06 | ″ | 0.0 | 8.5 | 0 |
  | 1 mm | 0.10 | ″ | 0.0 | 1.3 | 0 |
  | 1 mm | 0.15 | ″ | 0.0 | 0.0 | 0 |
  | 1 mm | 0.06 | stroke 9 cm | 0.3 | 23.8 | 0.09 |
  | 1 mm | 0.06 | stroke 9 cm, 760-coin heap | 1.3 | 23.5 | 0.47 |
  | 1 mm | 0.06 | stroke 9, heap 760, period 2.5 s | 1.3 | 24.8 | 0.47 |
  | 1 mm | 0.06 | stroke 12, heap 760, period 2.5 s | 1.5 | 26.0 | 0.56 |
  | 1 mm | 0.06 | stroke 9, heap 760, period 2.5 s, restitution 0.30 | 1.5 | 18.8 | 0.56 |
  | **0.5 mm** | **0.06** | **stroke 9, heap 760, period 2.5 s** | **5.3** | 20.0 | 1.97 |

  (P's lip 0 baseline: 3.8 %.) Higher friction stops the flow entirely; a longer, faster stroke and a fuller heap are what move it.
- **Shipped: lip 0.5 mm, friction 0.06, stroke 9 cm (deck travel 9.5 cm with the drive's play), crank period 2.5 s, high quality 760 coins → 5.3 % into the cup.** **8 % with a lip was not reached within the cap.** The stroke and period are now tunings, not the Silver Falls measurement (50 mm, 4.5 s), written so in `sim.js`. Phones start at low quality (540 coins), which will pay less than 5.3 % (not soaked). The owner's lip setting (⚙, 0–6 mm) is kept.
- **Next to try:** stroke 12 cm at lip 0.5 mm (it beat 9 cm at 1 mm); narrower side holes (they take 20–26 %, four times the cup, and some of that is flow the lip turned sideways); a heap saved from a long soak as the fresh fill (the field still grows from ~730 to ~1,300 over 700 drops, so the machine is still filling, not at its steady state); P's "forward creep" on the shelf for the deck's hammering; a soak at phone quality.
- Tests: `logic.test.js` (13: the wallet pays tickets, no quarter back, refill), `sim.test.js` (7, the crank from GEOM), `page_test.py` (ALL OK: the tickets HUD, Get quarters, the counts from CONFIG). Evidence: `production/qa/evidence/d48-*`.

## Sign pass (Oct 7, 2026)
See photos/ (Steven's photos for this store) and tools/stores/signs/ (make_logos.py batch3, channel.gd sg_* materials).
Steven: "make the pocket change facade a little bigger, more similar to heights of nearby stores." Opening head 2.4 → 2.9 m, fascia top 3.45 → 4.3 m, the stepped tile two rows taller, letters 5 % bigger. (The photo's proportions were the source for the old sizes.)
