# Pocket Change's prize counter and the closer look (Godot mall, Demo 34, Oct 15 2026)

**Asked for (Steven, Oct 15, 12:45):** "make a screen where you can look closer at the pocket
change ticket redemption prizes. like you can still see the correct item and orientation of it
on the case from further back inside the store but it's a new screen that looks at maybe a
subsection on one side in detail from top down or angled view at the glass. this is setting the
stage for being able to redeem tickets for these items, but we need to build the inventory
system into the game and i don't want to do that yet." His list: Chinese finger traps, jelly
finger traps, a back wall of bigger, higher-ticket items hanging, a Pog pack, rainbow coil
springs, virtual pets, big fuzzy dice, candy cigarettes, slap bracelets, candy necklaces,
chocolate chews, a lava lamp in back, green alien stuffed animals. His reference photos: acrylic
bins with price cards, glass prize cases, back walls of hanging plush.

## What is built (`scripts/prizes.gd`, made by `player.gd` in Wing 2)
- **The baked generic prizes are hidden at runtime**: surface overrides on the `pc*_mach` meshes
  for the prize materials (`pc_redeem_cards/small/toys/vinyl/plush/bead`, and the wall's
  `pc_redeem_tags`). The black trays and card backs share materials with the counter body, so
  those (`lam`, `desk`, and on the wall the boom box handles and hooks in `chrome`/`vcolor`) get a
  copy of their material that discards only inside the cases or above the wall's base cabinet.
  Nothing in the wing's bake, stand-ins or game files changes: no rebake, no stand-in recapture.
- **The prizes are 3D, in place**, so from anywhere in the store you see the right item in the
  right bin, the right way round. Built from primitives and generated textures (`prizes/*.png`
  by `tools/prizes/paint_prizes.py`; generic, no brand names or logos), batched as one MultiMesh
  per kind (33 draw calls, plus the price numbers, which only draw within 9 m).
- **The long case** (4 bays × 3 levels) and **the short case by the counter gate** hold open
  acrylic bins, each with a standing price card: finger traps (woven, 15), jelly finger traps
  (20), chocolate chews (5), candy cigarettes ("CANDY STICKS" boxes, 25), candy necklaces (20),
  slap bracelets (zebra, splatter, leopard, rainbow; 75), Pog packs ("MILK CAPS" blister cards and
  loose caps, 100), rainbow coil springs (150), fuzzy dice pairs (300), virtual pets on stands
  (1,500).
- **The back wall:** green alien plush and giant fuzzy dice hanging from hooks along the top
  (800 / 600), lava lamps with drifting glowing wax on the top shelf (2,500), sitting aliens,
  giant dice and a basketball on the middle shelf, boom boxes (5,000), basketballs (900) and big
  aliens on the cabinet top. Tags under or beside each.
- **The catalogue** is `scripts/prizes.json`: each item's name and ticket price, and which slot
  holds what (`[case, bay, level, side, item]`). The redemption system will read the same file.

## The closer look
- Standing in front of either case, facing it, a prompt shows: **"E · Look at the prizes"**
  (A on a pad, Tap on a phone). *Since Nov 2 (R) the prompt reads "Redeem tickets" and opens the
  redemption screen; the closer look is its "Look at the prizes" button.*
- The camera glides (0.55 s) to the view you were facing. Seven views, in order along the
  counter: the short case; the long case bay by bay (an angled look down through the front glass
  from just above the counter top: all three levels); the prize wall in two halves.
- **◀ ▶** (A/D, arrows, the pad's d-pad or bumpers or stick, a swipe) move along; **Back**
  (Esc/Q/B/E, the pad's B) glides back to you.
- Pointing at a prize (mouse), tapping it (phone) or picking with ▲ ▼ (keys or pad) shows
  **"Pog pack — 100 tickets"**. Nothing can be redeemed yet.
- While looking, the player is held (`player.frozen`), the HUD buttons and Jump are hidden.
- Landscape keeps the height (vertical FOV 46°, wall 52°); portrait keeps the width.

## Words on the prizes, editable by Steven (Steven, Oct 15, 13:51)
"add what the prize is, the name of it, under the ticket amount number on the white labels. and
make all of that font and all font on the packaging of the prizes be able to be edited directly
by me."
- Each price card now reads: the number, the prize's name (wraps to two lines if long), the red
  TICKETS band. One card picture per prize.
- No word is baked into any picture any more: the card, the milk-cap blister card and the
  candy-stick box are word-free art (`paint_prizes.py`), and `prizes.gd` draws the words over
  them at load time (a SubViewport per picture, shrinking a line until it fits its box).
- Where the words come from, in order: `scripts/prizes.json` "text" (defaults) and "art" (where
  each sits on its picture); the published edits, `play/prize_text.json` on main
  (`{"text": {id: {text, font, size, fill, outline}}}`, only changed fields); on the owner's
  browser, unpublished edits in localStorage "southland-prizes-draft".
- **Editing:** on the owner's browser (the mall editor unlocked, or `?owner=1`), the closer look
  has **Edit words** and **Publish words** buttons top left. With Edit words on, tap a prize: a
  form shows every word it carries: its name and ticket number (that card only), its packaging
  lines, and the styles every card shares (number, name, band). Each has the words, a font
  (sans, sans italic, serif, script), a size, a colour and an outline. Save shows the change at
  once on that browser; Publish writes `play/prize_text.json` to GitHub with the token the mall
  editor already keeps (`web/shell.html` `mallPrizeText`, the same publisher as the signs), and
  everyone sees it about a minute later. No rebuild. "Restore originals" puts a prize's words
  back to `prizes.json`.
- Text ids: `card.number`, `card.name`, `card.band`, `<item>.name`, `<item>.tickets`,
  `pogs.title`, `pogs.sub`, `candy_cig.top`, `candy_cig.mid`, `candy_cig.bottom`.
- The ticket number shown is words only for now; the redemption system will read the price from
  `prizes.json` (or adopt the edited number then).

## Period notes (for the mall historian)
- The Godot mall is 1995. **Virtual pets** reached the US in May 1997: an anachronism in 1995
  (kept because Steven listed them; flagged). **Alien plush** peaked 1996–97; plausible-to-early
  for 1995. Pogs/milk caps (peak 1993–95), slap bracelets, lava lamps (90s revival), candy
  cigarettes, candy necklaces, finger traps and boom boxes fit.
- All packaging is generic (no Tamagotchi, Slinky, Tootsie Roll or POG marks).
- Ticket prices are guesses at a 90s arcade scale; Steven tunes `prizes.json`.

## Checks
- `tools/qa/prizes_test.gd` (PRIZES TEST OK): surfaces hidden, prizes built, seen from the aisle,
  from the back of the store and from the door, the prompt, every view, a price, back to walking.
  Evidence `production/qa/evidence/d34-prizes-*.png`.

## Redemption (workstream R, Steven Nov 2 2026)
**Asked for:** ticket redemption at the counter, a "You received" pop-up, the boom box prize, and
"nothing on the ground at Pocket Change". Ground rule: Steven writes the story; this is machinery only
(no characters, lines, quests or new items beyond the boom box).

**The floor is clear.** The five Godot-built prizes (`data/items/pocket_change.json`), the Blender finger
trap and the three claw plush (`blender_props.json`) lost their `place`; the entries stay as stock.
Nothing else in the mall moved (the lava lamp `bl_gb_lavalamp` is Gumballs', wing 1; Martin Folse's
stick stays in the stockrooms). The cases keep their 3D display prizes (static, not pick-ups).

**The screen** (`scripts/redemption.gd`, made by `interact.gd` in every wing, reachable as
`mall.redemption`): `mall.redemption.open()` shows the stock as cards (icon, name, ticket price) with
**Your tickets** at the top. **BUY** when tickets ≥ price: the tickets go down, the item goes into the
bag, put away (`mall.add`), the state is saved, and the pop-up shows. What you can't afford is greyed
out and its BUY disabled. The panel fits the screen (up to 640 × 560, two columns at iPhone portrait
width, three or four on a phone in landscape and on desktop); a touch drag scrolls.

| | Keyboard / mouse | Gamepad | Touch |
|---|---|---|---|
| Choose | arrows / WASD | d-pad, left stick | tap a card |
| Buy | Enter, E, Space, or click BUY | A | tap BUY |
| Look at the prizes (the closer look) | L or the button | Y | the button |
| Back | Esc, Q, Backspace, Tab, Back, a click outside | B, Select | Back, a tap outside |

**Who opens it:** the counter glass. The prompt at either case now reads **"Redeem tickets"** (E / A /
Tap) and opens the screen; the closer look is still there, through the screen's "Look at the prizes"
(`prizes.gd redeem()`; with no screen it falls back to the closer look). The Pocket Change attendant
(workstream Q) calls `mall.redemption.open()` if it exists.

**The stock** (`scripts/redemption.json`: order, the item handed over, and where the price comes from).
Prices are `scripts/prizes.json`'s wherever the prize has one, so the card in the case and the screen
agree; Steven changes them there (or with a `tickets` in `redemption.json`).

| Prize | Item id | Tickets | Price from |
|---|---|---|---|
| Chocolate chews | `pc_chew` | 5 | prizes.json |
| Chinese finger trap | `bl_pc_fingertrap` | 15 | prizes.json |
| Jelly finger trap | `pc_jelly_trap` | 20 | prizes.json |
| Candy necklace | `candy_neck` | 20 | prizes.json |
| Candy cigarettes | `pc_candy_cig` | 25 | prizes.json |
| Slap bracelet | `slap` | 75 | prizes.json |
| Pog pack | `pogs` | 100 | prizes.json |
| Rainbow coil spring | `spring` | 150 | prizes.json |
| Fuzzy dice | `dice` | 300 | prizes.json |
| **Boom box** | `bl_pc_boombox` | **5,000** | prizes.json, the wall tags (Steven, Nov 3; was 500 on Nov 2) |
| Giant fuzzy dice | `pc_big_dice` | 600 | prizes.json |
| Plush bear / bunny / dog | `bl_pc_plush_bear` / `_bunny` / `_dog` | 700 each | Steven, Nov 3 ("700 stays") |
| Alien plush | `pc_alien` | 800 | prizes.json |
| Basketball | `pc_ball` | 900 | prizes.json |
| Virtual pet | `pc_vpet` | 1,500 | prizes.json |
| Lava lamp | `pc_lava` | 2,500 | prizes.json |

- The prizes that had no item (chews, jelly trap, candy cigarettes, virtual pet, alien, giant dice,
  basketball) got stock-only items in `data/items/pocket_change_stock.json`. Their models are the
  counter's own shapes, one unit each (`scripts/items/prize_model.gd` builds them with `prizes.gd`'s
  meshes and materials; scenes `scripts/items/pc_*.tscn`; icons `tex/items/pc_*.png`), so nothing new is
  drawn. The candy-cigarette box is the word-free art (the counter paints its words at load time).
- `pc_lava` is a second lava lamp with Gumballs' Blender model and icon, so buying one never takes the
  one at Gumballs off its shelf (an item id is one thing in the world).
- Buying the same prize again counts up in the bag. Dropping keeps the existing rule (one place per id:
  a second drop of the same id moves the first).
- Export: Wing 2 now also packs `models/bl_gb_*` (the lava lamp), Wing 1 `models/bl_pc_*` and
  `prizes/*.png`, so a bought prize carried across the seam still shows in the hand.

## The pop-up contract ("You received", `scripts/received_popup.gd`)
- `mall.received(id)` (a signal in `scripts/inventory.gd`) fires for **every item that enters the
  player's things from outside**: bought (`redemption.gd`), given (a dialogue calls `mall.add(id)`),
  picked up (`mall.take`). Moving a thing between hand and bag (`hold`, `put_away`, the hand swap on a
  pick-up) passes `quiet` and doesn't fire.
- The pop-up (made by `interact.gd`, every wing) shows a card over everything: "YOU RECEIVED", the
  item's icon (the Blender items' are 256 px renders, the Godot ones 128 px), its name, "You received
  <name>". After 0.6 s ("Press any key" / "Press any button" / "Tap to continue" appears) any key,
  button, click or tap dismisses it. Several in a row queue. While it shows the player is held and
  `mall` meta `popup_open` is true.
- To give an item from a dialogue: `player.mall.add(id); player.mall.save()`; the card follows.

## Checks (R)
- `godot --headless --path . --script res://tools/qa/redemption_test.gd`: REDEMPTION TEST OK: the floor
  is clear, the stock covers prizes.json and the Blender prizes, buying with 0 / 600 / 100 tickets, the
  ticket and bag round trip through a save, the pop-up contract and queue.
- `tools/qa/interact_test.gd --wing=2` now drops its five test prizes through a saved state (nothing
  lies there at first).
- `tools/qa/redemption_shots.gd` (native, unbaked, `--resolution 1280x720` and `390x844`): REDEMPTION SHOTS
  OK (11 checks): the empty floor, the prompt, the screen at 0 and 600 tickets, the boom box bought, its
  pop-up, the screen after (100 tickets), the boom box held in first person; in third person in the hall
  (in Pocket Change the arcade machines behind you shorten the camera boom and the avatar hides).
- `tools/qa/redemption_webtest.py` (web export, iPhone 390 × 844 and 844 × 390, touch): REDEMPTION WEB OK,
  0 console errors. The tap that opens the screen no longer reaches a card on its release.
- `tools/qa/movetest.py`, wing 2: 1995 (Pocket Change floor shot, walk from inside the store) and 2026
  (walk from the hall spawn; the 2026 Pocket Change space is a closed vacant store): 0 errors, MOVED.
- Evidence `production/qa/evidence/wsR-*.jpg`: `wsR-unbaked-desk-*`, `wsR-unbaked-iphone-*` (native),
  `wsR-web-*` (the web build with the published lightmaps), `wsR-boombox-sheet.jpg`.

## Open
- Settled Nov 3 (ECON, `design/godot-economy.md`): the boom box is 5,000, the plush 700; the closer look's Back
  returns to walking (checked by `tools/qa/econ_back_test.gd`); every ticket game now pays into the year's
  tickets, and the counter spends only 1995's (`mall.spend_tickets`).
- No sound; VR has no prompt.

## PRIZES (workstream PRIZES, Steven Nov 3 2026): fuller counters in both years, the Whirlwind at games, inc.

**Steven's decisions** (the brief): (1) Pocket Change used to look fuller and more vibrant: neat, organized bins
under the glass, not strewn; the back wall full; keep one or two of the aliens and lava lamps, fill the rest
with other common prizes; the research's shelf-by-shelf proposal, **Option B** (more prizes, a third bin width),
plus the **hook grid of carded toys**. (2) Blender for the prizes you can win where we can; simple bin filler for
the rest; everything on the redemption list exists as an item. (3) Keep the virtual pets (a known anachronism).
(4) games, inc. gets a clone of the 1995 WHIRLWIND, "literally the same machine", slightly duller and faded, $2 for
four plays, paying 2026 tickets. (5) games, inc. gets a prize counter and stock, some prizes shared with Pocket
Change, some its own, at the research's 2026 tiers; the wall as repeated primitives with a few hero pieces.
(6) No attendant at games, inc. in this job. Boom box 5,000, plush 700; every other price is a guess, marked.
Sources: `design/research/redemption-counters.md`, `design/research/redemption-items.md`.

### Pocket Change, 1995 (`scripts/prizes.gd`, `scripts/prizes.json`, `scripts/prize_units.gd`)
Still built at run time: **no static change, no 1995 rebake.**
- **Neat bins.** Every fill is a grid now: one orientation, rows and brick-stacked layers, colours in stripes by
  column. The four fills that were random heaps (finger traps, chews, candy necklaces, fuzzy dice) were rewritten
  the same way. Boxed and carded prizes stand in rows; upright ones (lollipops, rings, trolls, yo-yos) stand on
  clear stepped risers so every face shows.
- **Option B layout** (`prizes.json` "case"): a third bin width (`left3 | mid | right3`) where two bins looked
  sparse; price rises left to right by bay and upward by level; case B by the gate is candy.

| Case / bay | Deck | Lower shelf | Upper shelf |
|---|---|---|---|
| B (gate, candy) | lollipops (5) · candy rolls (5) · candy rings (20) | candy cigarettes (25) · taffy (5) · sour candy (5) | chews (5) · candy necklaces (20) · powder straws (3) |
| A bay 0 (1-25) | finger traps (15) · jelly traps (20) · spider rings (5) | pencils (10) · erasers (10) · sticker sheets (5) | sticky hands (15) · bouncy balls (10) · glow bracelets (25) |
| A bay 1 (25-100) | rubber snakes (25) · jelly bracelets (30) · army men (50) | slap bracelets (75) · slammers (60) · Pog packs (100) | Pog packs (100) · troll dolls (100) |
| A bay 2 (100-300) | coil springs (150) · paddle balls (125) · squirt pistols (150) | yo-yos (150) · harmonicas (200) · neon sunglasses (200) | mood rings (200) · toy cars (250) · rubber-strand balls (250) |
| A bay 3 (300-1,800) | fuzzy dice (300) | handheld games (1,200) · walkie-talkies (1,800), boxed | virtual pets (1,500) |

- **The wall** (`prizes.gd` WALL_CAB, WALL_MID, WALL_GRID, the hooks), bottom to top, price rising with height:
  the base cabinet top end to end (boom boxes 5,000, radio-control cars 4,500, cassette players 4,000, basketballs
  900, walkie-talkies, a handheld game, a plush dog and bunny, **one sitting alien**); the middle shelf shoulder to
  shoulder with plush bears, bunnies and dogs (700, tinted from the claw's fur colours) and giant fuzzy dice (600);
  the upper shelf with **two lava lamps** (2,500) at the ends and two plasma balls (2,000); two skateboards
  (6,000) on wall brackets above them; between them the **hook grid**: two rows of hooks, carded squirt pistols,
  paddle balls, toy cars, yo-yos, sunglasses and harmonicas hanging two deep; along the top, **one hanging alien**
  (800), giant fuzzy dice, the 3 ft plush bear (4,000) and a water blaster (450). Two aliens and two lava lamps in
  all (there were nine aliens and four lamps).
- **Kept: the virtual pets** (bay 3 upper, 1,500). **Known anachronism:** the type reached the US in May 1997
  (`design/research/redemption-items.md` §2); Steven: keep them for now.

### games, inc., 2026 (`scripts/prizes_gi.gd`, `scripts/prizes_2026.json`)
- **Static change** (`tools/stores/games_inc/machines/counter.gd`): the painted prize pictures in the three LED
  showcases and on the prize wall are gone. Each showcase has a white back panel and two glass shelves (0.59,
  0.78 m over the 0.40 m deck); the wall is black slatwall (`tex/gi/slatwall.png`) with six shelves (0.10, 0.42,
  0.76, 1.10, 1.44, 1.78 m), its top plush row as before. The build leaves markers (`GIPrizeCase0..2`,
  `GIPrizeDesk0`, `GIPrizeWall0`) where the run-time prizes go. **Wing 2 2026 needs a rebuild and a rebake.**
- **The prizes** are built at run time like Pocket Change's (prizes_gi.gd extends prizes.gd), from
  `prizes_2026.json` (keys `g_*`, so the words and prices never mix with 1995's): green shelf tags
  (`prizes/gtag.png`, words drawn at load time and owner-editable like the white cards).

| Showcase | Deck | Lower glass shelf | Upper glass shelf |
|---|---|---|---|
| Pink, by the door (1-100) | lollipops 10 · sour candy 10 · candy rings 40 · bouncy balls 25 · mini erasers 20 | finger traps 30 · sticky hands 30 · sticker sheets 15 · light-up rings 50 | popper keychains 75 · mini squishies 75 · slap bracelets 100 · fidget spinners 100 |
| Blue (100-800) | dough balls 300 · slime tubs 250 · popper boards 400 | mystery figures (blind bags) 350 · emoji keychains 250 · fidget spinners | light-up wands 600 · emoji keychains |
| White, the big prizes (1,000+) | charging cables 1,200 · phone stands 1,500 | Bluetooth speakers 6,000 · wireless earbuds 8,000 | gift cards 15,000 · mini arcades 25,000 |

- **The wall**, floor to top (`prizes_2026.json` "wall"): play balls 300, bubble wands 150, popper boards; slime,
  mini squishies, fidget spinners, dough balls; round plush 1,200 and light-up wands; capybara plush 2,000, blind
  bags, star projectors 5,000, speakers; boxed electronics: headphones 25,000, LED strip lights 4,000, handheld
  consoles 120,000, game consoles 150,000, earbuds; big round plush 8,000 and plush bears, bunnies and dogs
  (1,500); the build's top plush row tagged as jumbo plush 30,000. Two lava lamps (6,000) stand on the register
  counter (too tall for the 34 cm shelves). Repeated primitives throughout; Blender hero pieces: the round plush
  (all three sizes), the capybara, the dough ball, and the shared plush and lava lamps.
- **Shared prizes** (one item, `"year": "both"`, each year's own price): finger trap, slap bracelet, sticky hand,
  bouncy ball, lollipop, sour candy, candy ring, sticker sheet, eraser, plush bear / bunny / dog, lava lamp.
  The rest are each counter's own (no Pog packs, candy cigarettes or virtual pets in 2026; no consoles,
  poppers or squishies in 1995).
- **Redeem:** "Redeem tickets" at any showcase or the register opens the same screen (`scripts/redemption.gd`)
  with 2026's stock (`redemption.json` "stock_2026"), spending 2026's tickets only (ECON keeps them apart). The
  closer look has the three showcases and the wall in four parts.

### The redemption list (`scripts/redemption.json`)
"stock" (1995, 52 prizes) and "stock_2026" (40), by price; each entry's `prize` names the catalogue key its name
and price come from; **`"guess": true` on every price Steven hasn't given** (all but the boom box 5,000 and the
plush 700). Written by `tools/prizes/make_items.py`. Every prize is an item (`data/items/pocket_change_more.json`,
`data/items/games_inc_stock.json`, the Blender ones in `blender_props*.json`): the bin-filler ones are one unit of
what the counter shows (`scripts/items/prize_model.gd` → `prize_units.gd`), icons `tex/items/<id>.png`.

### Blender prizes (`tools/blender/assets_src/`, `models/<id>/`, the shared "items" pack)
1995: `bl_pc_troll`, `bl_pc_yoyo`, `bl_pc_koosh` (rubber-strand ball), `bl_pc_blaster` (water blaster),
`bl_pc_skateboard`, `bl_pc_plasma`. 2026: `bl_gi_squish` (round plush; the big and jumbo sizes are it scaled),
`bl_gi_capybara`, `bl_gi_doughball`. Reused: `bl_pc_boombox`, `bl_pc_fingertrap` and the three claw plush
(now `"year": "both"`), Gumballs' lava lamp. The counters show the models themselves (batched), so the bin and the
bag match. Bin fillers stay primitives: candy, rings, pencils, bracelets, cards, boxes.

### Packs
`prizes/*` (the counters' pictures, 0.3 MB) moved from the 1995 wing packs into the shared **items** pack
(`tools/shared_packs.json`, `tools/make_presets.py`, `export_presets.cfg` regenerated), because both years'
counters and the prize items use them. New models are under `models/bl_*`, so they are in the items pack too.
No texture was made smaller.

### Guessed (say if wrong)
- Every ticket price but the boom box and the plush (marked in redemption.json).
- Which prizes sit where, the shelf heights at games, inc. and its three-level showcases (the footage shows
  shelves of small prizes, not which).
- The prize names on the cards are generic descriptions ("Troll doll", "Rubber-strand ball", "Popper keychain",
  "Mystery figure"), no brand names; the boxes carry descriptive words only ("HANDHELD GAME", "RADIO CONTROL"),
  all editable in the closer look.

### WHIRLWIND at games, inc. (2026)
- **The cabinet:** Pocket Change's own `cyclone` module, placed by `tools/stores/games_inc/store.gd` (WW_U 3.5,
  WW_D 5.4: the open floor in the middle front, behind the party tables, console to the door, across the aisle
  from the showcases; **where it stands is a guess**, it is not in the Oct 23 footage). In a 2026 build every
  picture is the faded copy, `tex/gi/ww_*.png` (`tools/stores/games_inc/paint_whirlwind_faded.py`: two thirds of
  the saturation, lifted and warmed toward dusty cream, lower contrast, faint scuffs on the big panels; same
  sizes), its sign is `gi.cyclone.1` with the faded decal and the same WHIRLWIND words in faded colours, and its
  lamps and neon run at 0.8 (`scripts/cyclone_lights.gd` meta "dim"). Static: **wing 2 2026 needs a rebuild
  and a rebake.**
- **The game:** the same page, `play/whirlwind.html?year=2026&cab=gi` (`scripts/signs.gd` opens it at the
  console). `play/whirlwind/logic.js` CABINETS: "gi" is the same CONFIG at **$2.00 for four plays**, with its
  own plays left, bonus and best (`whirlwind.gi.*`) and payout ids (`whirlwind-gi:`); the 3D view is the faded
  copy (a CSS filter on the canvas). It pays into **2026's tickets** (the mall's `?year=`), which games, inc.'s
  counter spends. Pocket Change's machine is unchanged ($1.00, `whirlwind.*`).
- The "25¢" sticker on the coin door and "INSERT TOKEN(S)" on the card are the 1995 machine's; left as they are
  (the same machine). Question for Steven: should games, inc.'s show a card reader or a new price sticker?

### Checks (PRIZES)
- `node tests/unit/whirlwind/logic.test.js`: 12 passed (2 new: the cabinets).
- `node tests/unit/whirlwind/gi_page_test.js` (Chromium on the page, play/ served on 8766): WHIRLWIND GI OK (12):
  $2.00 taken, four plays, the win in 2026's tickets at once, 1995's untouched, its own plays left and payout id,
  the 1995 machine still $1.00, refused at $1.50 with "You need $2.00", 0 page errors. Against the page before
  this change it fails 8 of 12 (`production/qa/evidence/wsPRIZES-whirlwind-gi-before.txt`).
- `godot --headless --path . --script res://tools/qa/prizes_years_test.gd`: PRIZES YEARS TEST (redemption in both
  years, year separation, every prize an item with a model and an icon, shared vs own, guesses marked).
- `tools/qa/prizes_redeem_shots.gd --year=1995|2026` (native, unbaked): the prompt, the screen, a buy spending
  only that year's tickets, the card, the closer look.
- `tools/qa/redemption_test.gd`: its "no 1995 prize in the 2026 stock" check now reads "no 1995-only prize".
- Evidence `production/qa/evidence/wsPRIZES-*` (unbaked): before/after of both counters, the Whirlwind, the
  redemption screens.
