# Session handoff: WOOL-FRONT (Nov 11, 2026)

Branch `ws/wool-front`, from `int-54` (cc2191b9). Worker session, run unattended; every call below was
made without Steven. Not merged, not baked, not published. Design notes: `design/storefronts/woolworth.md`
("Front end", "WOOL-FRONT", "WOOL-FRONT checks") and `design/godot-directory.md` (kiosk 3).

## What shipped (Steven's four notes from the Demo 53 walk)
1. **Store front.** The customer service desk and its CUSTOMER SERVICE sign are gone. The four checkouts
   stand at the left front where the desk was (u 26.4-34.35), lane lights **1, 2, 3, 4**. The right front
   is open floor from the hall to the first gondola.
2. **Lunch counter.** The straight run is 1.6 m shorter, so the curved end and its stools stand clear of
   the window booths: a walkway about 1.4 m wide between the counter's end and the first booth, to the
   wall. 14 stools (was 18).
3. **Back wall.** A closed kitchen door; between it and the back bar a pass-through (stainless frame,
   shelf on brackets, three heat lamps) onto a small kitchen (range, hood, pot shelf, refrigerator); a
   fourth booth on the left wall before the door.
4. **Directory kiosk** in the main entrance hall by Mitchell's Formal Wear and Laser Copies: moved from
   the south storefront line (26.5, 3.2) to the corridor's centre (26.5, 0.0), still facing east down the
   corridor. It opens, jumps and starts the time trip as before.

## Wings and years that changed
- **Wing 1, 1990s only.** Needs a rebuild and **one rebake** (Woolworth's static geometry changed and the
  kitchen adds one light; the kiosk itself is probe-lit).
- **2026: nothing.** Woolworth is The Billiard Room there and kiosk 3 does not exist in 2026.
- Every wing's `gen/<wing>/directory.json` lists the 1990s kiosks, so that file changes in all of them on
  the next rebuild (kiosk 3's z). The game does not read that field.
- No `gen/` file and no `wing*.tscn` is committed. A new mesh group appears on rebuild: `gen/w1/wl_kitchen.res`.

## Files
- `tools/stores/woolworth/store.gd`: `CHECKOUT_U` / `CHECKOUT_D`, `checkout()` in the left-front groups,
  `service()` removed, `LC_D0` 3.6 -> 5.2, `kitchen_wall()` and its constants, the fourth booth.
- `tools/stores/directory/directory_data.json`, `data/directory_twins.json`: kiosk 3 at z 0.
- Tests: `tools/qa/wool_front_walk_test.gd` (new), `tools/stores/directory/ui_test.gd` (a third argument
  opens the kiosk at x,z), `tools/qa/menu_unit_test.gd` (kiosk 3's new position).
- Shared files touched: none of `build_mall.gd`, `player.gd`, `mall_runtime.gd`, `shell.html`, `layout_*.json`.
  `data/directory_twins.json` and `menu_unit_test.gd` belong to the menu's time trip: one line each.

## Calls I made
- **Kiosk 3 is the one meant.** It is the only kiosk in that hall; it stood toward the left storefronts
  as you look to the Woolworth court. It keeps facing east (toward the main doors).
- **The counter's curve is moved back, not cut off.** It keeps the Oct 20 curved end from Steven's photo.
  The brief's wording ("the curved end comes off") could also mean a square end; that is a small change
  in `counter_path()` if he wants it.
- **Pass-through behind the counter's back end, door just left of the counter**, so the order from the
  right wall is back bar, pass-through, door, as the note says.
- **The kitchen takes 1 m of the store's floor** behind the restaurant (a white box in that corner from
  the store side); one wall bay of party goods gave way to it.
- **Door leaf:** plain walnut laminate, after the period-art-director's review found the wood texture too loud.
- **The carts stay** by the right edge of the main aisle.
- Nothing in the shop or attendant code referred to the checkouts or the desk; none of it changed.

## GUESS (no Southland source)
- The lane numbers' order (1 at the far left from the hall).
- Every size and position on the back wall, the door's look, the whole kitchen, the fourth booth's exact spot.
- Kiosk 3's spot along the hall (only "the centre" is Steven's).

## Tests (wing 1, 1990s, rebuilt locally)
- SHOP TEST OK (200), SHOP INTERIORS TEST OK (178), INVENTORY TEST OK (45), INTERACT TEST OK (wing 1: 8,
  wing 2: 19), MENU UNIT OK (64).
- Directory: `ui_test.gd -- wing1.tscn mitch 26.5,0` UI TEST OK (the moved kiosk: in place, free floor in
  front, in reach, opens, jumps to Mitchell's); `-- wing1.tscn dil` UI TEST OK (jump into wing 5);
  `kiosk_test.gd` KIOSK TEST OK (25) for 1995 and 2026. `dirtest.js` was not run: the design note marks it
  out of date since the Nov 4 reader.
- `wool_front_walk_test.gd`: WOOL FRONT WALK OK (court straight into the right side to d 5.5; main aisle;
  through a checkout lane; between the counter's end and the booths to the wall; the kitchen holds).
- Web export of wings 1 and 2 (1990s), `movetest.py` on wing 1: 5 cameras, **0 errors**, MOVED; the touch
  walk went from the court through where the checkouts stood, and from the restaurant door to the wall
  between the counter's end and the booths.

## Known gaps
- `stockrooms_test`: the same three failures the int-52 handoff lists as pre-existing (lock, caption,
  buttons). Not looked into.
- `rougarou_test` and `rougarou_stalk_test --fast` did not finish in this box (stopped at 9 and 15 min
  with no result). I did not run them on `int-54` to compare, so whether the Woolworth changes affect the
  Rougarou's aisle-ducking is **not checked**.
- The local export's last step (`packcontents.py refs`) fails on the stand-in pictures only: `standin/` on
  `godot-build` is empty and CLAUDE-CLOUD.md's `git archive` line fails when run from the project folder.
  The export itself loaded and ran. Shots are unbaked, without lightmaps.
- `wsWOOL-web-*` shots were taken before the door's leaf changed to plain walnut, so
  `wsWOOL-web-backwall-after-unbaked.jpg` shows the earlier wood-texture door (the native one is current).
- Period-art-director notes not acted on (all optional): give the heat-lamp bulbs a warm glow after the
  bake; lane 1's box sits in front of the APPAREL band from the hall; the dark slab beside each register
  (the shared kit's register, not new) could read as a modern screen.
- From the store side the kitchen is a bare white box; nothing dresses it.

## Evidence (`production/qa/evidence/`, all unbaked)
- Front from the court: `wsWOOL-front-{before,after}`, `-front-left-`, `-front-right-`, `-front-checkouts-close-after`.
- Counter end by the booths: `wsWOOL-counter-end-{before,after}`, `-counter-end-2-`, `-counter-end-walkway-after`.
- Back wall: `wsWOOL-backwall-{before,after}`, `-backwall-2-`, `-backwall-door-passthrough-close-after`,
  `-kitchen-from-store-after`.
- Kiosk: `wsWOOL-kiosk-{before,after}`, `-kiosk-from-court-`.
- In the web build: `wsWOOL-web-{front,front-left,counter-end,backwall,kiosk}-after`.

## Open for Steven
1. Curve moved back, or cut off square?
2. Lane 1 on the far left, or nearest the main aisle?
3. Is the door / pass-through order right, and is the kitchen behind the back wall?
4. Should the carts move to the left with the checkouts?
