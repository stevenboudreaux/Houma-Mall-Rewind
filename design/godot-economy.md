# Money and tickets (Godot mall, workstream ECON, Nov 3 2026)

**Asked for (Steven, Nov 3):**
1. Tickets won never arrived: WHIRLWIND, the claw and Skee-Ball only posted `emu-close` when you left; nothing
   reached `mall.tickets`. Every game must credit what it paid out, once, even if the player leaves mid-game or
   reloads. Check the pusher too. No double credit.
2. A new player starts with **$100**. **One wallet for both years**: it goes back and forth.
3. **Tickets stay in their own year**: Pocket Change tickets spend only in 1995, Games, Inc. tickets only in
   2026. This replaces the Nov 2 "one ticket set across both years". Migrate saved data safely.
4. Every paid game takes its real price from the wallet before play; no money, no play, with a clear message.
   Keep each game's 1995 price. Reconcile the pusher's "quarters" stake with the wallet.
5. Boom box **5,000** tickets (the wall tags' number); plush 700 stays.
6. The buying API for round 2: `mall.money` (cents, integer), `mall.can_afford(cents)`,
   `mall.spend(cents, reason)`, a data-driven price field for items. No store, no attendant.
7. What "Back" from "Look at the prizes" does (Steven believes: back to walking).

Machinery only: no story, no new words a player reads beyond the money readouts and the "you need" line.

## Why tickets never arrived (the bug)
- **WHIRLWIND** and **Skee-Ball** counted tickets only on their own screen (`S.total`, `S.tickets`); nothing was
  written anywhere.
- **The claw** wrote its capsules' tickets to its own key, `localStorage "mall.tickets"`, which nothing else
  reads (the mall's tickets were in `mall-state-<year>.tickets`).
- **COIN COMET** wrote `mall-state-<year>.tickets` itself, but 350 ms after the coin fell (leaving inside that
  window lost it), and into the same record the mall keeps in memory and saves whole: the mall re-read it only
  when the pusher's frame closed, so any mall save meanwhile could put the old count back. And a coin credited
  but not yet saved off the machine could fall again after a reload (a double credit).

## How it works now
**One bank, two implementations, one set of rules.** `scripts/bank.gd` (the mall) and `play/lib/mallbank.js`
(the game pages) read and write the same `localStorage` keys at the moment of use; nothing is cached, so the mall
and a game in its frame never overwrite each other. `tests/unit/econ/cases.json` runs both against the same cases.

| Key | What |
|---|---|
| `mall.money` | the wallet, whole cents, **one for both years**. A new player: `10000` ($100.00) |
| `mall.tickets-1995` | Pocket Change tickets (the 1995 counter spends them) |
| `mall.tickets-2026` | Games, Inc. tickets (for a 2026 counter; none is built) |
| `mall.ledger` | `{"log": the last 40 changes, "ids": the last 200 payout ids}` |
| `mall.econ` | `"1"` once older saves are folded in |

- **A payout counts once.** Each credit names itself (`whirlwind:<visit>:<play>`, `pusher:<pos>:<visit>:<n>`,
  `claw:<machine>:<visit>:<play>`, `skee:<visit>:<game>:<total>`); a second credit with an id already in the
  ledger is refused.
- **Credited when won, not when the strip finishes.** The ticket strip and the counters are the picture of it:
  - **WHIRLWIND:** the moment the light stops (each of the 4 plays).
  - **Skee-Ball:** as each ball scores, the difference between `SK.tickets(score)` and what this game already
    paid, so leaving mid-game or a reload keeps what the score has earned; a full game ends with exactly
    `SK.tickets(score, pockets)`. *(A real alley pays at the end; this is a guess at "even if the player leaves
    mid-game": you keep what you scored.)*
  - **The claw:** when the capsule drops in the chute. A prize still in the claw when you leave isn't won.
  - **COIN COMET:** the moment a coin falls into the cup; the machine is saved after that physics step, so the
    coin can't fall again after a reload.
- **The year:** the pages read `?year=` (default 1995). `scripts/signs.gd` now passes it to the claw, Skee-Ball and
  WHIRLWIND (the pusher already had it). In 2026 nothing at Games, Inc. is playable yet (workstream GI), so 2026
  tickets can only come from a future game.

## Prices (1995, as they were)
| Game | Price | Where it's set | Before |
|---|---|---|---|
| COIN COMET | 25¢ a drop | `play/pusher/logic.js` `CONFIG.priceCents` | a free stake of 20 quarters ($5.00), "Get quarters" refilled it free |
| WHIRLWIND | $1.00 for 4 plays (25¢ a play, the cabinet's "25¢") | `play/whirlwind/logic.js` `priceCents`, `plays` | "$1.00 = 4 plays", nothing taken |
| Claw | 1 token = 25¢ a play (cabinet: "1 TOKEN PER PLAY"; the changer: "$1 BILL = 4 TOKENS") | `play/claw/logic.js` `priceCents` | free |
| Skee-Ball | 1 token = 25¢ a game of 9 balls (coin door: "1 TOKEN") | `play/skeeball/logic.js` `priceCents` | free |

- The money comes off **before** the play: WHIRLWIND at START, the claw at INSERT TOKEN, Skee-Ball at INSERT
  TOKEN, the pusher at each drop. Pocket Change took tokens; the game takes the token's 25¢ straight from the
  wallet (there is no token item or changer; a guess, say if tokens should be a thing you carry).
- **No money, no play:** the start button greys out and the card says "You need $1.00 to play. You have $0.10."
  (the claw and Skee-Ball "$0.25"); the pusher flashes "NO MONEY · a drop is $0.25; you have $0.10" (it has no
  card between drops). Nothing is taken.
- **WHIRLWIND's plays stay on the machine.** Leaving after play 1 of 4 keeps the 3 paid plays
  (`localStorage "whirlwind.credits"`); coming back shows "START play 2 (3 left)" without a second dollar.
- **Money readouts** (the only visual change): the pusher's QUARTERS chip reads MONEY `$97.75`; WHIRLWIND,
  Skee-Ball and the claw add the money to the small line of their existing chip; the cards say what you have.
  The pusher's "Get quarters" button is gone.

## The pusher's quarters, reconciled
The quarters stake (`mall-state-<year>.quarters`, 20 for a new player, a free "Get quarters" refill) was a
placeholder for money. It is gone: a drop takes 25¢ from the wallet. Whatever quarters a player still had are
**added to the wallet once** (25¢ each, from both years' records), so nothing they had is lost; "Get quarters"
is removed (it was free money). In `play/pusher.html` / `play/pusher/` only the wallet and ticket hooks changed
(workstream PUSHER2 is rebuilding the sim; see the report for the exact lines).

## Migration (older saves)
Run once by whichever side starts first (the mall's `load_saved()`, or any game page), additive, so the order
doesn't matter; each old field is removed as it is read; marked done with `mall.econ = "1"`:
- `mall.money` = what is there, or $100.00, **plus** 25¢ for every quarter left in `mall-state-1995.quarters`
  and `mall-state-2026.quarters`;
- `mall-state-1995.tickets` → `mall.tickets-1995`, `mall-state-2026.tickets` → `mall.tickets-2026` (they were
  already per year in the saves: the Nov 2 "one set" had not been built);
- the claw's `mall.tickets` (1995 capsules) → added to `mall.tickets-1995`, then removed.
Junk values are dropped, not counted. A stray old field written after migration (an old cached page) is ignored.
The per-year record `mall-state-<year>` keeps everything else (inventory, hand, moved, other systems' fields).

## The API for round 2 (`scripts/inventory.gd`, "mall")
| | |
|---|---|
| `mall.money -> int` | the wallet in cents (read-only) |
| `mall.can_afford(cents) -> bool` | |
| `mall.spend(cents, reason) -> bool` | false, and nothing changes, when it doesn't cover it; `reason` goes in the ledger |
| `mall.add_money(cents, reason) -> bool` | change, a refund |
| `mall.tickets -> int` | **this year's** tickets (MENU's Main tab reads it); setting it saves it |
| `mall.add_tickets(n, reason, id = "") -> bool` | a payout; with an id it counts once |
| `mall.spend_tickets(n, reason) -> bool` | the redemption counter uses it |
| `Inventory.money_text(cents)` | `"$12.34"` |
| `ItemDB.price(item) -> int` | the item's `"price"` in whole cents (`data/items/*.json`), `-1` when it has none |

Each change emits `mall.changed`. A store would do:
`var p := ItemDB.price(db.get_item(id)); if p >= 0 and player.mall.spend(p, "Store: " + id): player.mall.add(id); player.mall.save()`.
No item has a `price` yet (no store is built). `ItemDB.check()` refuses a price that isn't whole cents ≥ 0.

## "Back" from "Look at the prizes" (item 7)
Checked in the build (`tools/qa/econ_back_test.gd`, natively in wing 2, unbaked): from the counter's screen,
"Look at the prizes" shuts the screen and glides to the closer look. **Back returns to walking** — not to the
redemption screen — by every way the look offers: its Back button, Esc, Q, B, Backspace, E and a pad's B.
After each: the look and the screen are shut, the menu didn't open, the player is free on their own camera, the
HUD buttons are back, and walking moves the player. That is what Steven believed, and it already worked; no code
change was needed. (If Back should go back to the screen instead, it is one line in `prizes.gd close_look()`.)

## Checks (all on this branch)
- `node tests/unit/econ/bank.test.js`: ECON BANK OK (13: the shared cases, the money format, a throwing
  localStorage, the ledger's caps, the four game prices).
- `godot --headless --path . --script res://tools/qa/econ_test.gd`: ECON TEST OK (44: the same cases on
  `bank.gd`, the API, year separation, migration through a real `load_saved()`, the counter at 4,999 / 5,100
  tickets, the price field).
- `tests/unit/econ/pages_test.py` (Chromium on the three pages): ECON PAGES OK, 0 page errors. Run against
  `main`'s pages it fails 21 checks (the claw "wins 200" and the bank stays at 0; a 160-point Skee-Ball game pays
  0): `production/qa/evidence/wsECON-pages-before.txt`.
- `tests/unit/pusher/page_test.py` (money instead of quarters, NO MONEY instead of Get quarters): ALL OK;
  `logic.test.js` 10 ok.
- `tools/qa/econ_back_test.gd` (native, unbaked, 1280 x 720): ECON BACK OK (50).
- `tools/qa/econ_webtest.py` (web export of wing 2, 1995, swiftshader): ECON WEB OK, 0 console errors. E at Skee-Ball
  alley 1 opens `skeeball.html?year=1995&lane=1`; Skee-Ball 5, WHIRLWIND 13 (4 plays), the claw 200, COIN COMET 150
  (3 coins) = 368 in `mall.tickets-1995`, 0 in 2026; the wallet $98.25; after a reload the counter reads "Your
  tickets: 368". (Evidence pictures from the run before, identical but for WHIRLWIND's 9: 364.)
- Unchanged and still OK: INVENTORY 45, REDEMPTION 32, MENU UNIT 35, FLAGS 31, PUSHER PLAY 20, INT D49 18.
- `tools/qa/menu_test.gd` fails 4 checks, **the same 4 on `main`** (a hard-coded `_nav[0][1]` row; stale since
  the menu merge), not ECON's.
- Evidence: `production/qa/evidence/wsECON-*`.

## Open (for Steven)
- **Tokens:** should Pocket Change sell tokens you carry (a changer at $1 = 4), or is "the game takes 25¢" fine?
- **Skee-Ball mid-game:** tickets are paid ball by ball (you keep what you scored if you walk off). Real alleys
  pay at the end; say if leaving should forfeit.
- **Claw prizes** (plush, POGs) still go only to the claw page's own list (`mall.inventory` key), not into the
  bag. Not in this brief; say if they should arrive in the bag like the counter's prizes.
- **How does a player get more money** once the $100 is gone? Nothing earns money yet (by design: no store).
- **Games, Inc. 2026 prices:** unknown (card kiosks); nothing there is playable yet.
