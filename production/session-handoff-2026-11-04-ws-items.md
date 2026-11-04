# Handoff: one item system, hand by default, "1990s", no opening (Nov 4, 2026, branch ws/items)

From int-51 (4d09e18). Steven's four decisions of Nov 4; the design note is `design/godot-items.md`.

## What changed
- **Items, one schema** (`design/godot-items.md`): every entry has `category` + `subcategory` (food, drink, book, toy,
  electronics, home, clothing, stationery, token, story); `data/items/` is one file per store (`pocket_change`,
  `games_inc`, `b_dalton`, `woolworth`, `corn_dog_7`, `cucos`, `radio_shack`, `gumballs`, `great_american_cookie`,
  `karmelkorn`, `orange_julius`, `tee_tais`, `stockrooms`). The nine workstream files are gone. All 135 ids are
  unchanged (`tools/qa/fixtures/item_ids_int51.txt`). One loader: `ItemDb.shared()`; a repeated id is an error.
  Python writers (`tools/blender/build.py`, `tools/prizes/make_items.py`, `tools/shops/make_standins.py`) go through
  `tools/items/items_io.py`. `tools/stores/small/radio_shack.gd` and `scripts/stockrooms.gd` ask the loader instead
  of reading a file by name.
- **Hand by default**: `mall.receive(id, n, source)` in `scripts/inventory.gd`, used by `shop.gd`, `redemption.gd`,
  `dialogue_state.gd` (give, buy), `collect()` (the claw's inbox) and `take()` (pick-ups). A `"hand"` item goes into
  the hand, the held one into the bag; a `"pocket"` item into the bag. The card says "In your hand" (+ how to put it
  away) / "In your bag". `mall.add()` = receive; `add(id, n, true)` stays a quiet bag move (Cuco's travelling doubloon).
- **"1990s" / "2026"**: `scripts/years.gd`; the directory's year button and toggle, "Loads Wing n, 1990s", the old
  year button, the creator's title, the owner HUD, the shell's loading title. Internal 1995 ids unchanged.
- **No opening**: `scripts/menu/opening.gd`, `data/story/opening.json`, the owner's "Show the opening again" removed;
  the creator no longer opens by itself on a first visit (`scripts/avatar.gd`).

## Shared files touched (small hunks)
`scripts/player.gd` (2 lines + a const), `scripts/interact.gd` (the db, pick_up), `scripts/inventory.gd`,
`scripts/menu/menu.gd` (opening removed), `scripts/avatar.gd`, `scripts/directory_ui.gd`, `scripts/received_popup.gd`,
`scripts/shop.gd`, `scripts/redemption.gd`, `scripts/stockrooms.gd`, `scripts/dialogue/dialogue_state.gd`,
`web/shell.html` (one line, the loading title), `tools/stores/small/radio_shack.gd`, `play/claw.html` (a comment).
**Merge note:** any branch that adds or edits a `data/items/*.json` entry must move it into its store's file and give
it a category / subcategory (or run its tool again: the tools write through `items_io.py`); `items_test.gd` fails on
a new id until it is added to the fixture.

## Rebake
None: no scene or wing build input changed (radio_shack.gd builds the same nodes from the same entries).

## Tests (cloud, Nov 4)
See the report in the session; evidence `production/qa/evidence/items-*-unbaked.jpg` (wing 6 with wing 2's directory:
the box had no memory to load wing 2 natively while other sessions ran).
