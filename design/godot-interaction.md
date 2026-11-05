# Interaction, pick-up items, the bag and the owner-only HUD (Godot mall, workstream B+C, Nov 1 2026)

**Asked for (Steven, Nov 1):** one shared interactable system; pick-up items in two classes (hand,
pocket) defined as data; Martin Folse's stick as a real held item that swings; a few Pocket Change
prizes; a simple inventory panel stored as `mall.inventory` / `mall.tickets` and kept across wing
loads and reloads; the fps readout and the debug/owner toggles hidden from visitors; a touch way
into owner mode at the restroom-hall dead end. No menu (not designed yet), no damage system.

## Files
| File | What |
|---|---|
| `scripts/interact.gd` | The system: finds the target, the prompt, the action button, the touch button, the hand, the swing, the Bag button and panel, world items. Made by `player.gd` as its child `Interact` (every wing, both years). |
| `scripts/inventory.gd` | `mall`: the carried state, pure data (add/remove/hold/put away/take/drop, JSON, storage). |
| `scripts/items/item_db.gd` | Reads every `data/items/*.json` at start, checks entries. |
| `scripts/items/pickup.gd` | An item lying in the world (an "interactable"). |
| `scripts/items/*.tscn` | The item scenes: `folse_stick`, `spring`, `dice`, `pogs`, `slap`, `candy_neck`. Materials `it_*`. |
| `data/items/stockrooms.json`, `data/items/pocket_change.json` | The first items. Workstream D adds `radioshack.json`. |
| `tex/items/` | Item textures (`it_*.png`) and inventory icons (`<id>.png`, rendered by `tools/items/render_icons.gd`). |
| `tools/qa/inventory_test.gd` | Headless unit checks of `mall` and the item files. |
| `tools/qa/interact_test.gd` | Native, unbaked: the prizes, the bag, drop, the HUD (`--wing=2`); the stick (`--wing=1`). |

Shared files touched, in small commented hunks marked `B+C`: `scripts/player.gd` (`var mall`,
`var interact`, making `Interact`, `owner_hud_sync()`, `is_owner()`, the fps readout gated, hidden
buttons not tappable, the touch code), `scripts/stockrooms.gd` (the stick is an item; `_hud(true)`
re-applies the owner gating) and `export_presets.cfg` (see "Export").

## Controls
| | Keyboard / mouse | Gamepad | Touch |
|---|---|---|---|
| Action (use the target; swing a held stick when nothing is in reach) | **E** | **X** | the round **Use** / **Swing** button by the right thumb (shows only when there's something to do), or tap the prompt |
| Bag (open / close) | **I** (Esc, Tab close) or the **Bag (I)** button | **Select/Back** (B closes) | **Bag** button (tap outside closes) |
| In the bag: move / first button / Drop | ↑↓ (W/S) · Enter, E, Space · G | d-pad · A · X | the row's buttons |
| Put the held item away / drop it | **R** / **G** | from the bag | from the bag |

Wing seam, doors, Pocket Change's closer look and an arcade cabinet's Play keep their own prompts
(E/A). While one of them shows, the action prompt hides and the action button does nothing, so a
press never does two things. Gamepad X used to do nothing; keyboard E is shared but never at the
same moment.

## Contract 1: interactables (other workstreams write to it; keep it exactly)
- Any **Node3D** in group **`"interactable"`** with
  - `func interact_prompt() -> String`: what the button will do ("Pick up Pog pack", "Read the
    directory"). Return `""` when not available right now.
  - `func interact(player: Node) -> void`: do it. `player` is `scripts/player.gd`.
- Optional: `func on_hit(player: Node) -> void`, called when a swing (the stick) hits it.
- **Reach:** the node's origin within **1.6 m** of the player (flat distance; height within 2.2 m),
  and roughly in front: within ~70° of where the player faces (anything closer than 0.45 m counts
  whatever the facing). Among those, the nearest and most in front wins (`distance × (2 − cos)`).
- Hidden nodes (`is_visible_in_tree()` false) are skipped, so a whole level hidden (the mall while
  in the Stockrooms) takes its interactables with it.
- Put the node's origin where the player should stand near (a kiosk: its front face, not its
  centre, if it is big).

## Contract 2: item files `data/items/*.json`
A file is `{"_": "comment", "items": [entry, ...]}` (a bare array also works). Every file is read
at start, sorted by name; a later file wins on a repeated id. Bad entries are skipped with a
warning (`item_db.gd check()`).
```json
{"id": "pogs", "name": "Pog pack", "class": "pocket",
 "scene": "res://scripts/items/pogs.tscn", "icon": "res://tex/items/pogs.png",
 "year": 1995, "tickets": 100,
 "place": {"wing": 2, "year": 1995, "pos": [-106.5, 0.0, 68.5], "yaw": 70}}
```
- `class`: `"hand"` = held in the hand, drawn in first person, one at a time (picking up another
  puts the first in the bag); `"pocket"` = straight into the bag (too small, or too big to carry).
- `year`: 1995, 2026 or `"both"`; an item of the other year doesn't exist in that year's mall.
- `tickets` (optional): the ticket price, for the redemption counter later.
- `place` (optional): where it lies at first: wing (1, 2, 3 outside), year, `pos` in metres, `yaw`
  degrees. A pos within 1 km of (2000, 0, 2000) is in the Stockrooms. No place: it can only be
  given (later: redeemed, bought).
- **The scene** (a `.tscn` whose root is a Node3D, origin on the floor at the item's foot):
  - optional child **`Grip`** (Marker3D): the hand holds the item there, its axes the hand's.
  - optional child **`WorldOnly`**: shown only while it lies in the world (the stick's glow).
  - root metadata (optional): `swing` (bool: the action button swings it), `drop_pose = "lie"`
    and `lie_y` (dropped, it lies on its side), `place_rot` (degrees: its pose at its data place).
- **The icon:** a 128 × 128 PNG with transparency. `tools/items/render_icons.gd` renders one for
  every item whose icon is under `res://tex/items/` from its scene.

## The carried state: `mall` (`scripts/inventory.gd`)
`player.mall` holds it; `mall.inventory` and `mall.tickets` are the names the 2D game's state will
join on later. Saved after every change in `localStorage` **`mall-state-1995`** /
**`mall-state-2026`** (each year carries its own things), read when a wing starts, and mirrored to
`window.mall` (`{inventory, tickets, hand, year}`) on the web. Off the web (editor, tests) it
lives in Engine metadata `mall_state_<year>` so it survives a wing change in one run.
```json
{"v": 1, "year": 1995,
 "inventory": [{"id": "pogs", "count": 1}, {"id": "spring", "count": 1}],
 "tickets": 0,
 "hand": "folse_stick",
 "moved": {"folse_stick": {}, "pogs": {},
           "dice": {"wing": 2, "year": 1995, "pos": [-106.2, 0, 66.9], "yaw": 132.0}}}
```
- `inventory`: carried, not in the hand, in pickup order. `hand`: the held item ("" none).
- `moved`: items no longer at their data place: `{}` = carried; otherwise where it was dropped.
- Nothing earns tickets yet; the balance shows in the bag.
- A change of version (`v`) makes old saves be ignored (a fresh start), never misread.

## The items so far
| id | name | class | where | notes |
|---|---|---|---|---|
| `folse_stick` | Martin Folse's stick | hand | Stockrooms, the far corner of the stick room (grid 304.55, 44.45) | Swings (E / X / Swing). Keeps its glow and little light while it lies anywhere. Dropped, it lies on the floor. The old static prop and its caption are gone; the prompt names it. |
| `spring` | Rainbow coil spring | hand | Pocket Change floor | 150 tickets |
| `dice` | Fuzzy dice | hand | Pocket Change floor | 300 tickets; held by the cord, dangling |
| `pogs` | Pog pack | pocket | Pocket Change floor | 100 tickets |
| `slap` | Slap bracelet | pocket | Pocket Change floor | 75 tickets |
| `candy_neck` | Candy necklace | pocket | Pocket Change floor | 20 tickets |

Names and prices are `scripts/prizes.json`'s. The Pocket Change prizes lie loose on the carpet in
front of the cases, as if dropped (a guess at a believable spot: not in the cases, where the closer
look owns the action button). Their models reuse the prize counter's paintings (`tex/items/it_*`,
copied from `prizes/`, generic, no marks).

**The swing:** wind-up, sweep, back (0.48 s), a generated whoosh. Halfway, the first thing in
front within 1.9 m is hit: an interactable with `on_hit(player)` gets the call; otherwise a
shopper in range plays a gesture if their rig has one and a line shows ("Hey!", "Watch it!", "Do
you mind?", "Ow! Kids these days.", "Easy with that thing."). No damage.

## Owner-only HUD
> **OWNER, Nov 4 2026:** superseded by design/godot-owner-mode.md: the owner keeps every corner button on
> screen (and the year switch), while Reflections, Benches & plants, Lighting, Edit / Publish signs, Arcade
> and Shirt words moved into the menu's OWNER tab. The table below is the Nov 1 state.

Owner mode = `localStorage "southland-editor" = "1"` (set by `?owner=1`, the mall editor, or the
secret code). `player.is_owner()`, `player.owner_hud_sync()`.

| Button / readout | Where | Visitor | Owner |
|---|---|---|---|
| Title + fps readout ("Houma Mall Rewind · Godot mall (1995)  60 fps") | top left, `player.gd` | hidden | shown |
| Reflections: on/off | top right, `player.gd` | hidden (stays on) | shown |
| Benches & plants: on/off | top right, `player.gd` | hidden (stays off) | shown |
| Lighting: day/night | top right, `player.gd` | hidden | shown when a day bake exists and not day-only |
| Shirt words | `npc_shirt.gd`, top right at 128 | hidden (already) | shown (1995) |
| Jump to (J) | top right | **shown** (moves up to the top) | shown, under Shirt words in 1995 (it used to sit on top of it) |
| Visit 2026 / Back to 1995 (Y) | top right | **shown** (under Jump to; not outside) | shown |
| Bag (I) | top right, under the year switch | **shown** | shown |
| Action prompt + touch Use/Swing button | bottom middle / right thumb | **shown** | shown |
| Wing seam / door prompt | bottom middle | **shown** | shown |
| "Drag left side to walk…" hint, the touch stick | bottom | **shown** | shown |
| Pocket Change "Look at the prizes", ◀ ▶ Back, price tips | `prizes.gd` | **shown** | shown |
| Edit words / Publish words (prizes) | `prizes.gd` | hidden (already) | shown |
| Edit signs / Publish signs / arcade games | `signs.gd` | hidden (already) | shown |
| Play (an arcade cabinet) | `signs.gd` | **shown** | shown |
| Lighting panel (hour, brightness sliders) | `web/shell.html` `mallLight` | hidden (already) | shown |
| Enter VR | `web/shell.html` | **shown** when a headset is offered | shown |
| Jump to inside the Stockrooms | `stockrooms.gd` | hidden (already) | shown |
The toggles keep working when hidden: their state still comes from the URL (`?refl=0`, `?fx=1`,
`?time=`) and carries across wing loads.

## The owner code on a phone
At the same spot (the dead end of the restroom hall, past MEN and WOMEN, `SECRET_CORNER`), with no
hint on screen: **swipe up, up, down, down, left, right, left, right, then tap twice**. A swipe
is any touch that travels over 45 px (its main direction counts), anywhere on the screen; a tap is
one that moves under 20 px. No time limits (a slow phone handles touches late; the test browser
handles each a dozen seconds late), and the walking or looking the swipes cause is harmless: the
whole sequence still has to match at that spot. Keyboard and pad keep
up up down down left right left right B A. Same result: "Editor unlocked" and a reload at the
same spot.

## Export
Most wing presets export only scenes plus listed files, and the 1995 ones excluded `data/*`. In
`export_presets.cfg`: `data/*` in the excludes became `data/eras_2026.json` (the only other file
there), and `tex/items/*` joined every scene-filtered preset's includes. Item scenes are under
`scripts/` (already included); item JSON is covered by `*.json`.

## Checks
- `godot --headless --path . --script res://tools/qa/inventory_test.gd`: INVENTORY TEST OK.
- `xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 --script res://tools/qa/interact_test.gd -- --wing=2|1 --out=...`:
  INTERACT TEST OK.
- Web: `CHROMIUM=/opt/pw-browsers/chromium python3 tools/qa/wsbc_webtest.py <build>/index.html <out>`
  (server on :8765 at the repo root; `pip install playwright` if the Python one is missing, then
  point it at the preinstalled Chromium): desktop visitor (prompt, E picks up, a reload keeps it,
  the bag), desktop owner, phone landscape (the Use button, the Bag, a touch-drag walk), phone
  portrait (the bag), and the touch owner code. ALL OK, 0 console errors.
- Evidence `production/qa/evidence/wsBC-*.jpg`: `wsBC-unbaked-*` native shots without a lightmap;
  `wsBC-web-*` the web build with the current published lightmaps (no rebake needed: nothing baked
  changed).

## Open / guesses
- Where the five prizes lie is a guess (loose on the floor). Once redemption exists they should be
  bought at the counter instead, and `place` dropped from them.
- The held item draws with the world, so it can poke into a wall you stand against.
- VR: no prompt, no hand item drawn (hidden while in VR).
- Dropped items persist per year; there is no "reset my bag" for visitors yet (clearing site data
  does it).
