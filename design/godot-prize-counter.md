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
  (A on a pad, Tap on a phone).
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

## Open
- Redemption: still deferred. A ticket balance (`mall.tickets`) and an inventory (the Bag) exist
  since Nov 1 (design/godot-interaction.md); five prizes lie loose on the floor as pick-ups.
- No sound; no selection highlight beyond the tooltip; VR has no prompt.
