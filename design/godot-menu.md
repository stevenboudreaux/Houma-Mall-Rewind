# The menu, the time-travel transition, the opening and the player's name (Godot mall, workstream M, Nov 2 2026)

**Asked for (Steven, Nov 2):** one full-screen menu (tabs, left to right: **INVENTORY, AVATAR, CONTROLS,
YEAR**; Steven, later Nov 2: "the first thing that shows up [is] the inventory on the far left, then the
avatar builder") on a key, a
gamepad's Start and a touch button; the creator and a NAME field in AVATAR; a controls table read from
the InputMap with click-to-remap; the inventory in a tab with HELD / PUT AWAY and the TICKETS count; the
year switch in a tab, with a short time-travel effect; an opening screen whose words are data; 2026
with 3 shoppers. Ground rule: Steven writes the story; no invented characters, lines, items or text.
Every word the brief didn't give is a **PLACEHOLDER** (below).

Built on `main` at 326ed7c (Demo 47). Branch `ws/m-menu`.

## Files
| File | What |
|---|---|
| `scripts/menu/menu.gd` | The menu (a CanvasLayer at 45), its tabs, the Menu button, the input catcher, the opening's flow. Made by `player.gd` as its child `Menu`, after `Avatar`. |
| `scripts/menu/controls.gd` | The InputMap actions `mall_<id>`, remapping, `localStorage "mall-controls-1"`, the translation layer. |
| `scripts/menu/actions.json` | Every action the CONTROLS tab lists, with its **default** keys and pad buttons (data). |
| `scripts/menu/opening.gd` | The opening screen (a CanvasLayer at 50). |
| `data/story/opening.json` | The opening's words: `title`, `text`, `start`, `skip`. Ships with PLACEHOLDERs. |
| `scripts/timetravel.tscn`, `.gd`, `.gdshader` | The time-travel transition (a CanvasLayer at 60; the look is the shader). |
| `tools/qa/menu_test.gd` | Native, unbaked: opening, name, every tab at 3 sizes, keys, remap, HELD / PUT AWAY in both views, the transition, 2026's shoppers. |
| `tools/qa/menu_webtest.py` | The web build: opening, typed name, tabs, remap by keyboard and a reload, phone portrait / landscape by touch. |

Shared files, small hunks marked `M`:
- `scripts/player.gd`: `var menu`, making `Menu`; walking / running read the InputMap (`_mkey`, falls back
  to W A S D / X / Shift); the year button and **Y** open the YEAR tab (`_year_pressed`); `_switch_year`
  and a cross-year `_go_to_wing` (the directory's jump) `await _time_travel(to_year)` before the existing
  fade and reload; 2026 spawns `Shoppers` too (`_spawn_2026_shoppers`, not outside).
  **Not moved or renamed:** the jump code, `_switch_year`, `jump_to`, the interact contract.
- `scripts/inventory.gd` (`mall`): `player_name`, `player_name_changed`, `held_id()`, `clean_name()`.
- `scripts/interact.gd` `open_panel(true)` → the INVENTORY tab (3 lines). The old bag panel stays in the
  file, unused.
- `scripts/avatar.gd` `open_creator()` → the AVATAR tab (3 lines).
- `scripts/avatar_creator.gd`: `frame` (lay out inside a rect), `embedded` + `feed(e)` (input from the menu).
- `scripts/npcs.gd`, `scripts/npcs.json`, `scripts/npc_warmup.gd`: per-year density (below).
- `export_presets.cfg`: the 2026 outside no longer excludes all of `data/` (only `data/items/*`,
  `data/eras_2026.json`, as before in effect), so `data/story/opening.json` ships in every pack.

## The menu
Tabs, left to right: **INVENTORY · AVATAR · CONTROLS · YEAR**. Opening it shows INVENTORY.
| | Keyboard / mouse | Gamepad | Touch |
|---|---|---|---|
| Open / close | **Tab** (Esc closes too), the **Menu (Tab)** button top left | **Start** (B closes too) | **Menu** button, ✕ |
| Tabs | **Q / E**, a click on the tab | **LB / RB** | a sideways swipe, a tap on the tab |
| Inside a tab | ↑↓←→ (W S A D) + Enter / Space | d-pad + A | taps; drag to scroll |
Tab is Steven's call; Tab is the default and it is remappable (CONTROLS). The old ways in open their tab:
**I** / Bag → INVENTORY, **C** / Avatar → AVATAR, **Y** / the year button → YEAR. (A gamepad's Start used
to open the creator; it opens the menu now.) **Tab, Start and the Menu button always open on INVENTORY**,
the far-left tab (Steven). The player is frozen while it is open
(`player.frozen`), so nothing behind it reacts. The menu doesn't open while something else has the screen
(the prize counter's closer look, the directory), while leaving, or in VR. The Menu button sits top left
(under the owner's fps line); the owner-only HUD rules (design/godot-interaction.md) are unchanged.

**How input reaches it:** a catcher node is added last under the root, so its `_input` runs before every
other handler (later siblings get events first). While the menu or the opening is open it takes every
event and taps / clicks its own controls by hand (the project turns touch-to-mouse emulation off, and the
rest of the HUD already works this way). While closed it only passes events through the translation
layer (CONTROLS) and opens the menu.

**iPhone width:** checked at 390×844 and 844×390 (and 1280×720): every control on screen; long lists
scroll by dragging.

### AVATAR
The existing creator (workstream V), laid out inside the tab under a **NAME** field. Its own rows and
buttons work as before (Random · Skip/Back · Done). Done saves and closes the menu; closing the menu
another way also keeps what was made (the creator's Done). On the keyboard the NAME row is above the
creator's rows (↑ from its first row).

**NAME:** click (or Enter on it) to type; Enter, Tab or Esc ends (Esc discards). On a phone a tap opens the
browser's own text box (the creator's "Type" does the same), so the phone keyboard comes up. Up to 20
characters, control characters removed, trimmed.

**Contract: `mall.player_name`.** There is no autoload: `mall` is `player.mall`
(`scripts/inventory.gd`, made by `interact.gd`, the object B+C named for the 2D game's state). It now has:
- `player_name: String` — "" until typed. Assigning it cleans, saves and emits **`player_name_changed(name)`**.
- Saved in `localStorage "mall.player_name"` (one name for both years, apart from the per-year
  `mall-state-<year>`), mirrored to `window.mall.player_name`; Engine meta `mall_player_name` off the web.
- From anywhere: `get_tree().get_first_node_in_group("mall_player").mall.player_name`
  (`avatar.gd` puts the player in group `mall_player`).

### CONTROLS
A table: ACTION · KEYBOARD · GAMEPAD · TOUCH, one row per entry of `scripts/menu/actions.json`. The
keyboard and gamepad cells are read **from the InputMap** (`mall_<id>`), so they show what is bound now.
Click / Enter on a cell, then press the new key or button (Esc cancels). A key already used in the same
context is refused with a line saying by what; Esc, Enter and the arrow keys can't be bound. **Reset to
defaults** clears every change. Saved in `localStorage "mall-controls-1"` (only the changes), applied at
every start.

| Action | Keyboard | Gamepad | Touch | Remap |
|---|---|---|---|---|
| Walk forward / back / step left / right | W S A D (and the arrows) | left stick | drag on the left half | keys |
| Run (hold) | X, Shift (and the right mouse button) | — | — | keys |
| Look around | mouse drag | — | drag on the right half | — |
| Action (use / pick up / swing) | E | X | Use / Swing button | keys, pad |
| Go through (wing seam, door) | the Action key, Enter | A | tap the prompt | — |
| Menu | Tab (Esc closes) | Start (B closes) | Menu button | keys, pad |
| Menu: previous / next tab | Q / E | LB / RB | swipe, tap | keys, pad (menu only) |
| First / third person | V | right-stick click | View button | keys, pad |
| Avatar → AVATAR tab | C | — | Avatar button | keys, pad |
| Inventory → INVENTORY tab | I | Back / Select | Bag button | keys, pad |
| Year → YEAR tab | Y | — | year button | keys, pad |
| Jump to | J | Y | Jump to button | keys, pad |
| Put the held item away / Drop it | R / G | — | INVENTORY tab | keys, pad |
| Tilt (the coin pusher) | — | — | — | **not on main yet** (D48): add a row to `actions.json` |

**How a remap reaches code written for fixed keys** (so nothing else had to be rewritten, and other
workstreams' new keys can join by adding a row):
- `kind: "poll"` (walking, running): `player.gd` reads `Input.get_action_strength("mall_<id>")`.
- `kind: "event"` (E V C I Y J R G and their pad buttons): the catcher re-sends a key now bound to an
  action as that action's **default** key (`Input.parse_input_event`, deferred, the copy tagged
  `mall_synth`) and swallows the original; a default key moved off its action is swallowed, so it does
  nothing. E.g. Action on F: F does everything E did (pick up, swing, the seam prompt), E does nothing.
- `kind: "menu"`: read by `menu.gd` directly. `kind: "fixed"`: shown, not remappable.
- A new row must give the code's **default** keys (`keys`, Godot key names) and pad buttons (`pad`,
  `JOY_BUTTON_*` numbers). The table is right as long as `actions.json` matches what the code listens for.

Owner only, under the table: **Show the opening again** (clears the "skipped" mark and shows it now).

### INVENTORY
**TICKETS** (`mall.tickets`) at the top; tickets are never an item. Then the hand item and the bag, each
with its icon and name (×n), **HELD / PUT AWAY** (the lit one is the state) and **Drop**:
- HELD = `mall.hold(id)`: in the hand in first person, in the avatar's right hand in third person
  (B+C / V, unchanged); one at a time, so holding another puts the first away.
- PUT AWAY = into the pocket (`interact._put_away()`).
- A `"class": "pocket"` item (`data/items`: "too small, or too big to carry") can't be held: its HELD is
  greyed. (Guess: the item data's class decides; say if every item should be holdable.)

**Contract: `mall.held_id() -> String`**, the held item's id, `""` when nothing is held (session Q).

### YEAR
The year on show, large, and **1995 / 2026** buttons (the current one lit). The other runs the
time-travel transition, then the existing switch (`player._switch_year()`: the same spot, the fade, the
wing reload). The directory's cross-year jump plays it too.

## The time-travel transition
`scripts/timetravel.tscn`: a CanvasLayer (60) with one full-screen ColorRect and a shader over the
screen texture, driven by `progress` 0 → 1 over **`duration` (the one config value, 1.5 s, an export on
the scene's root)**: a ripple and a twist out from the middle, a chromatic split, colour washes cycling
warm / cold / magenta, scan bands, three flashes of light (at 14 %, 36 %, 62 %, the last brightest), then
a fade to black; then `player.gd`'s existing 0.35 s fade and the reload. Forward (1995 → 2026) and back
turn the other way. Re-dress it by editing the scene / shader; the script only sets `progress` and
`forward`. **Sound:** an empty `Hum` AudioStreamPlayer slot (PLACEHOLDER; give it a stream and it plays).
Reduced motion (`prefers-reduced-motion`): no flashes, only the fade. In VR it is skipped.

## The opening
At a first start a one-screen panel: the title and text from **`data/story/opening.json`**, then
**START** and **Skip**. START opens the menu on AVATAR with the NAME field focused (on a phone the field
is lit and a tap types). Shown when: no `mall.player_name` yet, not skipped before
(`localStorage "mall-opening-1" = "skipped"`), and no `?cam=` in the address (tests, shared spots and
every wing / year crossing, as the creator's first-visit rule). `?opening=1` forces it. Once a name is
set it never shows; **Skip** also stops it. START without typing a name shows it again next time
(the brief's rule: "not shown again once mall.player_name is set"). The owner's **Show the opening
again** (CONTROLS) brings it back. On a first visit it comes before the creator (which the V workstream
opened by itself); START leads to the creator.

```json
{"title": "PLACEHOLDER: title", "text": "PLACEHOLDER: Steven's opening briefing goes here.", "start": "START", "skip": "Skip"}
```
`text` may hold `\n` for paragraphs; it scrolls if long. An empty `title` hides the title line.

## NPC density by year
`scripts/npcs.json` `"years"`: `{"1995": {}, "2026": {"count": 3, "ids": [], "roles": false, "layout": "res://layout_2026.json"}}`.
- `count`: the crowd's size (still scaled by the hour, as 1995's 17 is; the mall is day-only, 1.0).
- `ids`: which characters; **empty = the first `count` of the crowd pool** (npc/skins.json order, groups
  with weight, minus `exclude`). Today that is Ch01, Ch02, Ch08 (`npcs: …` in the log names them).
- `roles: false`: no drunk, talking pairs, arcade players or salon visitors in 2026 (those are 1995's).
- `layout`: 2026's store doors, so the 2026 shoppers walk into 2026's open stores and windows.
- Only those characters are warmed up behind the loading card (`npc_warmup.gd` `only`).
- 1995 is untouched (17, all roles). The outside (wing 3) 2026 has none. No new NPCs.

## Checks (Nov 2, on `ws/m-menu`)
- `tools/qa/menu_unit_test.gd` (headless): **MENU UNIT OK (35 checks)**: the name contract, held_id(), rebinds,
  refusals, the translation routing, save / load / reset, a tampered save. `inventory_test.gd` still OK (41).
- `tools/qa/menu_test.gd` (native, unbaked, wing 2): **MENU TEST OK (64 checks)**: the opening, START → AVATAR
  with NAME focused, typing a name, every tab at 1280×720 / 390×844 / 844×390 with every control on screen,
  Tab opens on INVENTORY, Q / E, I / C / Y open their tabs, a remap (E → F; F works as E, E released; a fresh
  load keeps it; F refused for another action; reset), HELD / PUT AWAY with the dice in the first- and
  third-person hand, the owner's opening again and Esc = Skip, the transition, then 2026 with 3 shoppers
  (Ch01, Ch02, Ch08) and the name carried over. `--only=2026` shoots the three shoppers.
- `tools/qa/menu_webtest.py` (web build, wings 1–2, both years): **MENU WEB OK, 0 console errors**: desktop
  first visit (opening, Enter, typed name saved, Tab, the tabs, Action remapped to F with the keyboard,
  a reload keeps F, no opening once named), phone portrait (tap START, swipes through the tabs, ×),
  phone landscape.
- `tools/qa/movetest.py`: wing 1 1995 and 2026 **MOVED**, 0 errors; wing 2 hall / arcade and 2026 hall load
  with 0 errors.
- `tools/qa/vrtest.py` (IWER Quest 2): **ALL OK (25)**: VR enters, walks, turns, jumps, plays a machine and
  crosses the seam as before.
- Native: `xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 --script res://tools/qa/menu_test.gd -- --wing=2 --out=…`
  → `MENU TEST OK (n checks)`.
- Web: `tools/export_web.sh .scratch/builds/wsm "1 2"`, then
  `CHROMIUM=/opt/pw-browsers/chromium python3 tools/qa/menu_webtest.py "<build>/index.html?wing=2" <out>`
  and `tools/qa/movetest.py`.

## Evidence (`production/qa/evidence/wsM-*.jpg`, unbaked)
Opening (desktop, phone), every tab at 1280×720 / 390×844 / 844×390, the remap capture and result,
HELD / PUT AWAY, the dice in hand in first and third person, the transition mid-flash, 2026 with its 3
shoppers, the web build (desktop and phone), the movetest.

## PLACEHOLDERs and guesses (for Steven)
- **PLACEHOLDER:** the opening's `title` and `text` (`data/story/opening.json`).
- **PLACEHOLDER:** the transition's hum (an empty `Hum` slot).
- Words I used that the brief didn't spell out (UI only, easy to change in `menu.gd` / `actions.json`):
  the action names in CONTROLS, "Press a key…", "Reset to defaults", "Show the opening again",
  "Drop", "Skip", the Menu button's "Menu (Tab)".
- Guess: Esc and a pad's B close the menu as well as Tab / Start.
- Guess: a pocket-class item can't be HELD.
- Guess: START without a name shows the opening again next time; Skip doesn't.
- Guess: Y now opens the YEAR tab rather than switching at once (the brief: the old buttons open their tab).
- Guess: 2026's three walk as ordinary shoppers (no roles), at 2026's store doors.
- The contract says "the mall autoload"; there isn't one (above). An autoload could be added if Steven
  wants `mall` reachable without the player; it would be a project.godot change for every wing.
