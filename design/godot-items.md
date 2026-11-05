# Items: one schema, hand by default (Godot mall)

Workstream ITEMS (`ws/items`, from int-51, Nov 4 2026). Steven's decisions, Nov 4:

1. **One item system.** One schema for every item; files split by store, not by the workstream that made them;
   every id unchanged; one loader in code.
2. **Hand by default.** Anything that can be held goes into the hand when received (bought, won, given); the
   player puts it away into the bag. Anything holdable can be both bagged and held. Root beer float and corn dog:
   hand. The Bayou Bruiser figure: hand/bag like everything else. One receive path for every source.
3. **The years' names** shown to the player are "1990s" and "2026" (see `design/godot-2026-year.md` "The years'
   names").
4. **No opening.** The placeholder intro is gone; the game just starts in the mall (`design/godot-menu.md`).

## Files

| Path | What |
|---|---|
| `data/items/<store>.json` | THE item list, one file per store (or place): `pocket_change`, `games_inc`, `b_dalton`, `woolworth`, `corn_dog_7`, `cucos`, `radio_shack`, `gumballs`, `great_american_cookie`, `karmelkorn`, `orange_julius`, `tee_tais`, `stockrooms` (Martin Folse's stick). 135 items at the split; ws/interiors (Nov 4) added `auntie_annes`, `payless`, `spencers` and 18 stand-ins (`design/godot-shops.md` "ws/interiors"). |
| `scripts/items/item_db.gd` | The one loader (`ItemDb.shared()`, read once per run), the checks, `CATEGORIES`, `holdable()`, `ids_in()`, `price()`, `in_year()`. |
| `scripts/inventory.gd` | `mall.receive(id, n, source)`: the one receive path (below). |
| `tools/items/items_io.py` | The same files from Python: `load()`, `upsert()`, `set_field()`. Every tool that writes entries uses it (`tools/blender/build.py`, `tools/prizes/make_items.py`, `tools/shops/make_standins.py`). |
| `tools/qa/items_test.gd` | ITEMS TEST OK: the schema, the ids against `tools/qa/fixtures/item_ids_int51.txt`, hand by default from every source, the years' names, no opening. |

The old files and where their entries went: `blender_props.json` (to each item's store), `blender_props_2.json`
(B. Dalton's paperbacks, the food court's Blender food), `claw_prizes.json` and `pocket_change_more.json` /
`pocket_change_stock.json` (to `pocket_change.json`), `food.json` (it held the books too: to `b_dalton`, `woolworth`,
`corn_dog_7`, `cucos`), `games_inc_stock.json` (to `games_inc.json`), `radioshack.json` and `shop_standins.json`
(to `radio_shack.json`).

## The schema

```json
{"id": "bl_wl_rootbeer_float", "name": "Root beer float",
 "category": "drink", "subcategory": "float",
 "class": "hand",
 "scene": "res://models/bl_wl_rootbeer_float/bl_wl_rootbeer_float.glb",
 "icon": "res://models/bl_wl_rootbeer_float/bl_wl_rootbeer_float_icon.png",
 "year": 1995, "store": "WOOLWORTH",
 "display": {"wing": 2, "year": 1995, "pos": [x, y, z], "yaw": 0}}
```

Required: `id`, `name`, `category`, `subcategory`, `class`, `scene`, `icon`, `year`. Everything the entries had
before is kept as it was; the optional fields:

| Field | Meaning |
|---|---|
| `store` | The layout's store name it belongs to (all but the stick). It picks the file. |
| `class` | `"hand"`: can be held, and so goes into the hand when received; can be put in the bag and held again. `"pocket"`: into the bag only (too small, or too big to carry). |
| `year` | `1995`, `2026` or `"both"` (internal ids; the player reads "1990s" / "2026"). |
| `tickets`, `prize` | A redemption prize: its ticket price and its key in `scripts/prizes.json` / `prizes_2026.json` (`"prize": "claw"` for the claw's). |
| `price` | What a store asks, whole cents (ECON). The shop lists' own `price_cents` (`data/story/shops.json`) win at a counter. |
| `place` | Lies in the world at this spot (a pick-up). |
| `display` | Shown on a counter, built into the scene (Radio Shack's, the corn dog). |
| `recolor`, `tint` | Model colours (the lava lamp's wax, the plush). |
| `standin`, `standin_for` | A labelled STAND-IN model until a real one lands (`design/godot-shops.md`). |
| `model_from` | Where the model came from (notes). |

Rules: ids never change (saves, shops, quests and tests name them); an id appears once across all the files (a
repeat is skipped with a warning and fails the test); `category` is one of the list below; `subcategory` is a
lower-case word, free, used for grouping. A new item needs both (`items_io.upsert` refuses one without).

**Where prices and catalogue live (unchanged):** a counter's list is not the item. `data/story/shops.json` (what a
shop sells, at what price, with the ready line), `scripts/redemption.json` (what a redemption counter offers,
mapping each catalogue key to an item id) and `scripts/prizes.json` / `prizes_2026.json` (the prize cases: how each
prize is drawn, its tag's name and ticket price) stay where they are: the same item can be sold at two counters at
two prices (the lollipop: 5 tickets at Pocket Change, 10 at games, inc.). They all name items by id, and the test
checks every id resolves.

## Categories

What the thing is, not where it came from (a prize is any item with `tickets`; a shop's stock is its list).

| category | label (bag heading) | subcategories in use | count |
|---|---|---|---|
| `food` | Food | meal, side, sweet, candy | 17 |
| `drink` | Drinks | soft, float, hot, alcohol | 7 |
| `book` | Books | hardcover, paperback | 8 |
| `toy` | Toys | plush, figure, pogs, novelty, squishy, fidget, ball, skill, music, water, outdoor, vehicle, light-up | 53 |
| `electronics` | Electronics | audio, game, radio, rc, phone, battery, part, accessory | 32 |
| `home` | Lamps and lights | lamp | 5 |
| `clothing` | Things to wear | bracelet, jewelry, eyewear, keychain | 6 |
| `stationery` | School supplies | pencil, eraser, stickers | 3 |
| `token` | Coupons and coins | coupon, coin, card | 3 |
| `story` | Story | prop | 1 |

Guesses (Steven to correct): candy is `food`/`candy`; the slap and jelly bracelets, the mood ring, the sunglasses and
the emoji keychain are `clothing`; the lava lamps, the plasma ball, the star projector and the LED strip are `home`;
the Cuco's coupon and doubloon and the games, inc. gift card are `token` (the coupon and the doubloon drive Cuco's
story, but they are things); Martin Folse's stick is `story`. "prize" is not a category: it is where a thing came
from (Steven's Nov 4 list named it; if he wants a "Prizes" heading in the bag, it can be the items with `tickets`).

## Hand by default

`mall.receive(id, n = 1, source = "")` (`scripts/inventory.gd`) is the one way a thing comes to the player:

| Source | Caller |
|---|---|
| bought at a counter | `scripts/shop.gd buy()` |
| bought in a dialogue (Cuco's bar) | `scripts/dialogue/dialogue_state.gd buy()` -> `give()` |
| given in a dialogue | `dialogue_state.gd give()` |
| won at a redemption counter | `scripts/redemption.gd buy()` |
| won in a game page (the claw) | `inventory.gd collect()` (the bank's inbox) |
| picked up | `interact.gd pick_up()` -> `mall.take(id)` |

A holdable (`"hand"`) thing goes into the hand and what was held goes into the bag, quietly. Already holding one of
the same: the new one goes into the bag beside it. `n` > 1: one in the hand, the rest in the bag. A `"pocket"`
thing goes into the bag. `received(id)` fires once, after the thing is where it lands; `received_to(id, where,
source)` too. Putting away (R, the menu's PUT AWAY) and holding again are quiet moves, no card. `mall.add(id)` (the
old name) is the same as `receive`; `mall.add(id, n, true)` stays a quiet move into the bag (Cuco's doubloon
travelling to 2026 keeps it: it was received in 1995).

The "You received" card (`scripts/received_popup.gd`) now says where it went: "In your hand" (with "R puts it in the
bag" on a keyboard, "put it away from the Bag" on touch and a pad) or "In your bag".

The things Steven named: the root beer float (`bl_wl_rootbeer_float`), the corn dog (`bl_cd7_corndog`) and the Bayou
Bruiser figure (`pc_claw_bruiser`) are all `"hand"`: received into the hand, bagged and held again like everything
else. No item's class changed.

## Checks

- `tools/qa/items_test.gd` (ITEMS TEST OK): every file entry has the schema and loads; ids unique; the 135 int-51
  ids all there and no others; every shop, redemption and Cuco's id resolves; the workstream files are gone; a buy
  at Corn Dog 7, a second buy, the same thing twice, three at once, the plush bear and a lollipop at the redemption
  counter, the claw's Bayou Bruiser and POGs through the inbox, Cuco's give and buy, a pick-up, put away / hold (no
  card), the travelling doubloon (quiet); the card's "In your hand" / "In your bag"; every holdable item into the
  hand, into the bag and back; the years' names; no opening.
- `tools/qa/inventory_test.gd`, `shop_test.gd`, `redemption_test.gd`, `econ_test.gd`, `cucos_test.gd` follow the new
  path (a held item is counted by `mall.count`).
