# Shops: buy from an attendant (Godot mall, workstream SHOPS, Nov 3 2026)

**Asked for (Steven, Nov 3):** "Like Fallout. You don't take things off shelves. You talk to the attendant at the
counter, a list opens, you pick, the money deducts, and they hand it to you (it goes in your bag)." Any item not won
at a game shop is bought with money. Picking things up off the shelves in these stores goes away. The first four
stores, 1995 only: Woolworth (s13), Corn Dog 7 (s54), RadioShack (s21b), B. Dalton (s48). A data-driven shop
system, `mall.shop.open(shop_id)`, the redemption screen's look, greyed out when you can't afford it, ECON's
`mall.can_afford` / `mall.spend`. No basket, no leaving-the-store check yet (later).

## Files
| File | What |
|---|---|
| `data/story/shops.json` | the shops: one entry per shop (below) |
| `scripts/shop.gd` | the screen and the API; also shows the stock on display (items with `"display": {"runtime": true}`) |
| `data/story/attendants.json` | four new attendants, `"shop": <id>`, `"name": "PLACEHOLDER"`, a preset each |
| `data/characters/woolworth.json`, `corn_dog_7.json`, `radioshack.json`, `b_dalton.json` | PLACEHOLDER presets, clothed |
| `data/items/shop_standins.json`, `models/bl_standin_*/` | 20 labelled STAND-INs (`tools/shops/make_standins.py`) |
| `tools/qa/shop_test.gd` | headless checks |
| `tools/qa/shops_webtest.py` | the web check at each counter |

Shared files, small hunks marked `SHOPS`: `scripts/inventory.gd` (`var shop`), `scripts/interact.gd` (makes the shop
node beside the redemption screen), `scripts/attendants/attendant.gd` (`interact()`: an attendant with `"shop"`
opens its list instead of a dialogue), `tools/qa/dialogue_walk.gd` (skips shop attendants: they have no dialogue),
`tools/stores/small/radio_shack.gd` (reads `"display"`), `tools/stores/small/store2.gd` (B. Dalton's counter),
`data/items/radioshack.json`, `blender_props.json`, `blender_props_2.json` and the three Blender `assets_src` METAs
(`"place"` becomes `"display"`).

## shops.json
```
{"shops": [{"id": "woolworth", "store": "WOOLWORTH", "title": "Woolworth", "attendant": "woolworth", "years": [1995],
  "greeting": "...", "greeting_by": "Steven (brief, Nov 3)",
  "items": [{"item": "bl_wl_rootbeer_float", "price_cents": 200, "price_note": "Steven (brief, Nov 3)",
             "ready_line": "One root beer float coming right up.", "ready_line_by": "Steven (brief, Nov 3)"},
            {"item": "standin_wl_hotdog", "price_cents": 129, "price_note": "guess, ...", "ready_line": "...",
             "ready_line_by": "PLACEHOLDER (Steven's pattern)", "standin": true}, ...]}]}
```
- `item`: an id in `data/items/*.json` that exists in the shop's year. `price_cents`: whole cents.
- `price_note`: where the price comes from: **Steven**, **guess** (a 1995-feeling guess), or **estimate** (RadioShack,
  from `design/research/radioshack-1995-prices.md`, itself mostly guesses and unopened leads).
- `ready_line`: what the attendant says when it's bought. `ready_line_by`: Steven, or **PLACEHOLDER** when the line
  follows his pattern ("One … coming right up.") for an item he gave no line for.
- `standin: true`: a labelled stand-in model until the real one lands. **To swap one in:** change `item` to the new
  id here and delete the stand-in from `tools/shops/make_standins.py` (then rerun it).

## The API (`scripts/shop.gd`, reachable as `mall.shop`)
| | |
|---|---|
| `mall.shop.open(shop_id, attendant = null) -> bool` | opens the list when the shop is open this year; with the attendant, the camera turns to their face as in a conversation |
| `mall.shop.buy(i) -> bool` | one purchase of entry i: false, and nothing changes, when the wallet doesn't cover it; else `mall.spend(price, "Shop <id>: <item>")`, `mall.add(item)` (the "You received" card), `mall.save()`, and the ready line |
| `mall.shop.close()` | |
| `Shop.read_shops()`, `Shop.read_stock(shop, item_db, year)` | the data, pure |

## How it plays
1. Walk up to the counter: the action button reads **TALK** (the attendant's interactable stands on the shop side).
2. E (a pad's X, the round touch button): the attendant stops and turns to you, the camera glides to their face (0.5 s,
   as a conversation: `dialogue_ui.gd face_shot`, turned a little so the face sits beside the list), and the list
   opens: the store's name, **Your money: $100.00**, the attendant (PLACEHOLDER, in gold) saying the greeting, and a
   card per thing (icon, name, price, BUY). What you can't afford is greyed out and its BUY is off.
3. BUY (Enter / E / Space, a pad's A, a click or tap on BUY): the money comes off once, the thing goes into the bag
   (never the hand), the "You received" card shows, and the attendant's line becomes the ready line. The list stays
   open for another purchase; each BUY is one purchase.
4. Back (Esc / Q / Backspace, a pad's B, the Back button, a click outside the list): the list closes, the camera glides
   back, you walk again. No line on leaving.
Wide screens: the list on the right, the face on the left. A phone (tall): the list on the lower part, the face above.

## The shops (1995)
| Shop | Wing | Attendant stands (x0, z0 → x1, z1), faces | TALK spot | Sells |
|---|---|---|---|---|
| Woolworth | 1 | the lunch counter's clerks' side −19, −12.85 → −16.2, −12.6, faces +z (the stools) | −17.5, −10.75 | root beer float **$2.00** (Steven), hot dog $1.29, hamburger $1.99, French fries $0.99, coffee $0.59 |
| Corn Dog 7 | 2 | right behind the counter −134.06, 74.2 → −134.0, 77.4, faces −x (the queue) | −135.7, 75.6 | corn dog **$2.00** (Steven), crinkle-cut fries $0.99, lemonade $0.99 |
| RadioShack | 1 | the clerks' aisle 6.4, 32.75 → 10.2, 33.15, faces −z | 8.2, 30.9 | the 8 standalone items + 10 shelf kinds (estimates, below) |
| B. Dalton | 2 | behind the counter −109.22, 43.9 → −108.98, 45.7, faces +x | −107.6, 44.35 | five books at **$10** (Steven) |

**Lines (Steven's, word for word):** Woolworth "Welcome to Woolworth, sha! What can I get for you?"; "One root beer
float coming right up."; "Order of fries coming up." Corn Dog 7 "Hi, welcome to Corn Dog 7. What can I get for
you?"; "One corn dog coming right up." RadioShack "Welcome to RadioShack. What can I get for you?" B. Dalton (same
pattern, **PLACEHOLDER**): "Welcome to B. Dalton. What can I get for you?" Every other ready line is PLACEHOLDER in
Steven's pattern (Corn Dog 7's fries reuse Woolworth's "Order of fries coming up.").

**Prices Steven didn't give (guesses, marked in shops.json):** Woolworth's hot dog 129¢ and coffee 59¢ follow the
lunch counter's own painted menu strip (itself invented, `tools/stores/woolworth/paint_lunch.py`); hamburger $1.99 and
fries 99¢ are guesses (not on the strip). Corn Dog 7's fries and lemonade (.99) follow its painted menu box.
**The boards now say $2.00 (Steven, Nov 4: "repaint the menu boards to $2.00"):** Woolworth's strip said ROOT BEER
FLOAT $1.49 and Corn Dog 7's box Corn Dog 1.29; both repainted (`paint_lunch.py price_strip()`,
`paint_corn_dog_7.py menu_board()`; only the price changed, `production/qa/evidence/wsSHOPS-menu-boards-before-after.jpg`).
Corn Dog 7's COMBO (corn dog, fries & lemonade 2.99) is unchanged and not sold (Steven, Nov 4: "leave the combo").

**RadioShack (estimates, `design/research/radioshack-1995-prices.md`):** scanner $199.99, walkie-talkies $49.99 a
pair, R/C truck $89.99, 900 MHz cordless $149.99, AA 4-pack $3.49, pager $79.99, CB $99.99, micro-cassette $49.99;
shelf kinds as STAND-INs: corded phone $19.99, answering machine $59.99, clock radio $29.99, cellular phone $199.99
(no activation contract in the game), 9 V $2.79, C 2-pack $3.29, timer IC card $1.29, plug adapter $2.99, AC adapter
$14.99, speaker wire spool $3.99. **Not sold:** the DSS dish (did RadioShack sell DSS in 1995?), the Computers header
(Tandy had sold its PC maker in 1993), the display monster truck (a display), the vague "boxed generic electronics",
and the basic 46/49 MHz cordless (the counter's cordless is the 900 MHz one).

**Books (B. Dalton):** Moby-Dick (real title, public domain; a STAND-IN with a painted cover), the existing
**Shiverwood #7 "The Bayou Babysitter"** paperback for the Goosebumps-type book (its Blender model; its cover sticker
says $3.99, Steven's price is $10), and three invented stand-ins: **Which Way Now? #12: Lost on Bayou Noir**
(Choose Your Own Adventure-type), **Husbands Are from Jupiter, Wives Are from Saturn** by an invented Dr. Leonard
Marchand (Men Are from Mars-type), **Down a Long, Long Hall and Other Shivery Stories**, "retold by" an invented
Nell Bristow (In a Dark, Dark Room-type). Invented titles and covers, clearly not the real books.

## Nothing off the shelves
- Every item of the four stores that lay about to be picked up ("place") is now stock on show ("display"): the root
  beer float on Woolworth's counter, the corn dog on Corn Dog 7's (1995; in 2026, where no shop is built, it stays a
  pick-up: Steven, Nov 4), the three Shiverwood paperbacks on
  B. Dalton's table, RadioShack's eight items on the counter's glass. They look the same and can't be taken.
- RadioShack's eight are built into wing 1 by `radio_shack.gd items()` (unchanged spots, so the built scene is the
  same); the others are placed at run time by `shop.gd` (`"runtime": true`).
- The Blender METAs (`tools/blender/assets_src/bl_wl_rootbeer_float.py`, `bl_cd7_corndog.py`, `bl_bd_paperback.py`)
  carry `"display"` too, so a Blender rebuild keeps it.
- Saved games: a float, corn dog or paperback a player already picked up stays in their bag.

## Stand-ins (workstream FOOD's models weren't in `data/items/` when this was built)
Labelled: a "STAND-IN" tag over the model (billboard, always on top) and a yellow STAND-IN band on the icon. Primitive
shapes of the right size and colour (`tools/shops/make_standins.py`), in `models/bl_standin_*` so they ship in the
shared `items` pack. Still stand-ins:
- **Woolworth:** hot dog `standin_wl_hotdog`, hamburger `standin_wl_hamburger`, French fries `standin_wl_fries`, coffee `standin_wl_coffee`.
- **Corn Dog 7:** crinkle-cut fries `standin_cd7_fries`, lemonade `standin_cd7_lemonade`.
- **B. Dalton:** `standin_bd_moby_dick`, `standin_bd_which_way`, `standin_bd_jupiter`, `standin_bd_long_hall`.
- **RadioShack:** the ten shelf kinds `standin_rs_*`.
Real models: the root beer float, the corn dog, the Shiverwood paperback, RadioShack's eight.

## The attendants
Following `design/godot-character-editor.md` "How to add an attendant": a preset each, `"name": "PLACEHOLDER"`, a
Mixamo fallback skin (Ch26, Ch06, Ch13, Ch28: picks). Clothes are guesses: Woolworth's (a woman, Steven) wears the
waitress uniform; Corn Dog 7's a red polo and cap (the store note's "red-shirted crew"); RadioShack's a white
button-down and slacks; B. Dalton's a cardigan and glasses. The sexes other than Woolworth's are guesses. Probe-lit,
not baked; placed at run time.

## Geometry and bakes
- **B. Dalton (wing 2, 1995): rebake.** Its counter stood against the left wall's bays with no room behind it. It now
  stands 1.1 m off the wall (was 0.5) and 2.0 m in from the front (was 2.5, so it clears the first gondola's end);
  the clerks' aisle behind it is an obstacle. `store2.gd` `BD_COUNTER_U`, `BD_COUNTER_D`; wing 2 rebuilt here
  (`wing2.tscn`, `gen/w2/`), unbaked.
- Woolworth, RadioShack, Corn Dog 7: no geometry change, no rebake. (Corn Dog 7's back worktop meets the attendant's
  back below 0.9 m; the 1.0 m counter hides it from the shop.)

## Checks (Nov 4, this branch; unbaked)
- `godot --headless --path . --script res://tools/qa/shop_test.gd`: **SHOP TEST OK (210 checks)**: the data (four shops,
  attendants with PLACEHOLDER clothed presets, wing and year, whole-cent prices, models and icons load, stand-ins and
  RadioShack estimates marked, Steven's lines word for word, five books at $10, RadioShack sells all eight standalone
  items); a buy ($100.00 to $98.00 once, one ledger entry, one card, in the bag not the hand, the ready line, saved:
  a fresh load has the float and $98.00; 2026 shares the wallet, not the bag); can't afford ($1.50 can't buy a $2.00
  corn dog, nothing changes; exactly $2.00 can); nothing in the four stores has a pick-up "place" any more (13 on
  display); the screen (greyed-out cards, BUY, the line and the money update, Back; no shop opens in 2026).
- Unchanged and still OK: DIALOGUE WALK 67, ECON TEST 52, INVENTORY 45, REDEMPTION 32, FLAGS 31, CHAR CLOTHED 1632
  (the new presets included), CHAR EDITOR 28 (`--only=unit`).
- Wing 2 rebuilt (`build_mall.gd --wing=2`, BUILD OK): the only collision change is B. Dalton's counter rect moved and
  the clerks' aisle added.
- Web (`tools/export_web.sh`, wings 1 and 2, 1995; w1 85.45 MB, w2 83.19 MB, items 22.6 MB + the stand-ins):
  `CHROMIUM=/opt/pw-browsers/chromium python3 tools/qa/shops_webtest.py <build>/index.html <out> both` → **SHOPS WEB OK**,
  0 console errors (12 404s for site files a scratch build doesn't have: `roms.json`, `signs.json`, `shirt_text.json`).
  At each counter, a new player: E opens the list beside the attendant's face; Enter buys the first thing the wallet
  covers (RadioShack: Enter on the $199.99 scanner at $98.00 takes and gives nothing, then the $49.99 walkie-talkies);
  the wallet drops by exactly the price once; the item is in `mall-state-1995`; closing takes nothing more; after a
  reload both hold. Run: float $2.00, walkie-talkies $49.99, corn dog $2.00, Moby-Dick $10.00 ($100.00 → $36.01).
- Evidence (`production/qa/evidence/`): `wsSHOPS-web-unbaked-<shop>-approach / -open / -bought / -line.jpg` for the four
  counters, `wsSHOPS-standin-icons.jpg`, `wsSHOPS-menu-boards-before-after.jpg`. On the web the attendant wears the
  Mixamo fallback until the character pack mounts (the approach shots); from then on, the preset (the open shots).
- Phone, 390 x 844 (`shops_webtest.py … both phone`): **SHOPS WEB OK**, 0 console errors, the same buys; the list on the
  lower part, the face above (`wsSHOPS-web-unbaked-phone-*.jpg`). Seen there: the face shot is tight on a phone (the
  conversation camera's 0.85 m); the mouth falls behind the list. Not changed (a camera tweak if Steven wants it).
- Not run: native shots.

## Steven's answers (Nov 4)
- "repaint the menu boards to $2.00": done (above).
- "leave the combo": left as painted, not sold.
- "keep the corn dog pickup in 2026": `bl_cd7_corndog` has `"display"` for 1995 and `"place"` for 2026 (data and
  its Blender META); `shop_test.gd` checks it.

## Open (for Steven)
- The attendants' names, looks and sexes (Woolworth's is a woman; the rest are guesses).
- The ready lines for things you gave no line for (PLACEHOLDER in your pattern).
- RadioShack: sell the DSS dish, a computer, the display truck? The cellular phone without activation at $199.99?
- Should a bought hand item (a float, a corn dog) go into the hand rather than the bag? Built as asked: the bag.
