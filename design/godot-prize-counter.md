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
| **Boom box** | `bl_pc_boombox` | **500** | Steven (Nov 2); **the wall tags say 5,000** (prizes.json) |
| Giant fuzzy dice | `pc_big_dice` | 600 | prizes.json |
| Plush bear / bunny / dog | `bl_pc_plush_bear` / `_bunny` / `_dog` | 700 each | **guess** (between the giant dice and the alien) |
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
- **Boom box price:** 500 on the screen (Steven's number), 5,000 on the wall's tags. Which one?
- **Plush prices** (700) are a guess.
- The closer look's Back returns to walking, not to the redemption screen.
- Nothing earns tickets yet (workstream D48's coin pusher pays out).
- No sound; VR has no prompt.
