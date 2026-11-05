# The menu, the time-travel transition, the opening and the player's name (Godot mall, workstream M, Nov 2 2026)

> **MENU2, Nov 3 2026 (branch `ws/menu2`): this note is updated for Steven's Nov 3 decisions.**
> 1. Tabs, left to right: **MAIN, INVENTORY, CONTROLS** (L2 / R2 = LB / RB as before, and now the
>    triggers too). YEAR and the separate AVATAR tab are gone. Room is left for a later JOURNAL tab
>    (last); it is neither built nor shown.
> 2. **MAIN** shows the current character, their name, money and tickets. **Edit** opens the avatar
>    editing (NAME + the creator) inside MAIN.
> 3. Each mall directory, in both years, shows the current year at the top with a **toggle** beside it.
>    Pressing it starts time travel; **it is the only way to change year.** Y no longer does anything,
>    and there is no year button, YEAR tab or CONTROLS row.
> 4. The trip: the directory closes, you stand at it in your own view, the effect starts and loops
>    through the whole load with **no load screen**, and you reappear at the same directory in the
>    other year, facing the same way. Sections "MAIN" and "Time travel at the directory" below.
> The earlier text is kept where it still holds; superseded parts are struck or marked.

> **UI-OFFSCREEN, Nov 4 2026 (branch `ws/ui-offscreen`):** Steven: "no text on the game screen;
> everything goes in the menu", confirmed as **the corner buttons only**. The walk-up action prompts
> stay. Section "The game screen (UI-OFFSCREEN)" below; the tables in "The menu" and "CONTROLS" are
> updated to match. **Steven's answers, Nov 4 evening:** the year switch is the kiosk's only, no menu
> entry; the menu icon shows on **touch devices only** (desktop: Tab or Esc, pad: Start); the owner HUD,
> Enter VR and the walk hint stay on screen.

## The game screen (UI-OFFSCREEN, Nov 4)
**What a visitor sees while walking:** the mall; on a phone or tablet one small **menu icon** top left
(three white bars on a faint dark rounded square, 42 × 42 px, no words; none on a desktop); and only
when they apply: the walk-up prompts
("E · Go outside", "Read the directory", "Talk" …), the round touch **Use / Swing** button, the short
status line (`_say`: "Third person" …) and, on a first start until you move, the walk hint. Owner mode
is unchanged (below).

**What moved where:**
| Was on the game screen | Now | Key / pad (unchanged) |
|---|---|---|
| **Menu (Tab)** button, top left | touch devices: the unlabelled menu icon, same spot; desktop: nothing (Tab or Esc) | Tab, Esc, Start |
| **Jump to (J)**, top right | MAIN: **Jump to** (closes the menu, opens the jump panel) | J, pad Y |
| **Bag (I)**, top right | the **INVENTORY** tab (as the Bag already led there since M) | I, pad Back |
| **View: 1st / 3rd person (V)**, top right | MAIN: **View: 1st / 3rd person** (closes the menu so you see it) | V, right-stick click |
| **Avatar (C)**, top right | MAIN: **Edit** (as before) | C |
| ~~Visit 2026 / Back to 1995 (Y)~~ | already never shown (MENU2); tucked away with the rest | — |

MAIN's three buttons sit under NAME / MONEY / TICKETS in a row that wraps (on a phone held upright,
Jump to goes to a second line). On a keyboard or pad they are one row: ← → between them, Enter / A.
The labels show the current key, read from the InputMap (`Edit (C)`, `View: 1st person (V)`,
`Jump to (J)`, so a remap shows), and no key when the last input was a touch. Jump to is greyed when the
jump isn't available (a visitor in the Stockrooms, `jump_locked`).

**Opening the menu, one way per device (Steven, Nov 4 evening):** touch (iPhone, iPad): a tap on the
icon; desktop keyboard / mouse: **Tab** (remappable) or **Esc**, no icon; gamepad: **Start**. Why the icon
and not a gesture on touch (two-finger tap, swipe from an edge): a gesture is invisible, so nobody finds
it, and Safari takes the edge swipes for back / forward and the home bar.
- **Which devices get the icon:** `menu.touch_device`, true when `DisplayServer.is_touchscreen_available()`
  (on the web: the browser reports touch points) and from the first touch on, for the rest of the run.
  A touch laptop counts as a touch device; a mouse click on the icon still works there (an iPad with a
  trackpad). A pad on a desktop doesn't bring it.
- **A desktop mouse player still finds the menu:** the existing first-start walk hint (bottom middle
  until you first move) gains, on a desktop only, "· Tab or Esc: menu" (the key read from the InputMap,
  so a remap shows; refreshed after a remap or Reset). No new label: the same hint, the same moment.
- **Esc opens the menu** when nothing on the game screen uses Esc: the jump panel still closes with Esc
  (it is checked first); the shops, prize counter, directory and conversations freeze the player, and the
  menu doesn't open over them (`_can_open`). Esc and Tab close it, as before. In a browser, Esc with the
  mouse captured first releases the mouse (the browser's), so a second Esc opens the menu.
- The icon moves down under the owner's fps line, as the button did.

**How (small hunks, nothing renamed):** the old buttons are still made by their own scripts
(`player.gd` Jump to and the year switch, `interact.gd` the Bag, `avatar.gd` View and Avatar) and their
code still sets `.visible` and lays out round them, so `shop.gd`, `redemption.gd`, `prizes.gd`,
`stockrooms.gd` and the tests that read them are untouched. `menu.gd _tuck_corner_buttons()` moves them
into a hidden `OffscreenHud` Control beside them (deferred, after every script made its button):
nothing draws them, and every hand-made touch hit test now checks `is_visible_in_tree()` (one line each
in `interact.gd` and `player.gd`; `avatar.gd` already did), so a tap where they were does nothing.
`menu.gd corner_buttons()` lists them. `actions.json`'s TOUCH column names the new places.

**Not moved (Steven, Nov 4 evening: they stay on screen):** the owner-only HUD (fps line, Reflections, Benches &
plants, Lighting, Shirt words, the prizes' / signs' Edit and Publish words, the lighting panel), the
**Enter VR** button (bottom middle, only when a headset is offered; WebXR needs it pressed in the page
itself, a user gesture, so it can't simply move into the Godot menu), the first-start walk hint
("Drag left side to walk · drag right side to look", bottom middle until you first move), and the
full-screen moments that bring their own words (the directory, the prize counter, Pocket Change's
closer look, the jump panel, the conversation screen, the shops).

**The year jump (decided, Steven, Nov 4 evening): the kiosk only, no menu entry.** The year button has
been hidden since MENU2 (Nov 3: "the directory's toggle is the only way to change year"; ws/directory
moves the switch onto the kiosk); it is tucked away with the rest and the menu has no year entry.

### Checks (UI-OFFSCREEN, unbaked)
- `tools/qa/ui_offscreen_test.gd` (native), after Steven's answers: **UI OFFSCREEN TEST OK (35 checks)**
  on wing 6. It starts as a desktop (no touch screen natively): no icon, the walk hint reads "… · Tab or
  Esc: menu", no words on the game screen but the hint, Esc opens MAIN and closes it, Tab and Start open
  MAIN, a pad brings no icon; then a first tap makes it a touch device: the icon shows top left with no
  words, the hint is back as it was, and the checks below follow (a click on the icon now stands for an
  iPad with a trackpad; Esc on the open jump panel closes it and doesn't open the menu).
  The first run (before the answers, 28 checks, icon on every device) was on wing 6 too (the
  cinema lobby: the same player, menu and corner buttons as every wing; native runs on wings 1 and 2
  were killed for memory on the shared cloud box): the five corner buttons found and not drawn, their own
  `.visible` untouched; the icon shown with no words, top left; at 1280×720, 390×844 and 844×390 **no
  Label or Button with words on the game screen** apart from the allowed prompts (a walk over every
  CanvasLayer); a tap on the icon opens MAIN with Edit, View and Jump to all on screen; a mouse click on
  the icon, Tab and Start open MAIN; taps where the old buttons were open nothing; MAIN's View by tap,
  mouse and pad (Start, d-pad right, A) switches the view and closes the menu; V still switches it; MAIN's
  Jump to opens the jump panel, Esc closes it, J still opens it; MAIN's Edit opens the editing; C and I
  still open MAIN-Edit and INVENTORY.
  `xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 --script res://tools/qa/ui_offscreen_test.gd -- --wing=6 --out=…`
- `tools/qa/ui_offscreen_webtest.py` after Steven's answers (web build of this change, wing 2, `npcs=0`,
  desktop and phone portrait, one browser at a time): **every UI check passed.** Desktop: no menu icon top
  left (the bars' bright pixels absent), a click where it would be opens nothing, **Esc opens the menu**
  (MAIN's amber tab drawn), E to INVENTORY, Tab closes, V switches the view and saves it, J opens the jump
  panel. Phone portrait (touch): the icon drawn top left, a tap opens the menu, MAIN's View switches the
  view and saves it, the icon then the INVENTORY tab. The one red line in each part was a console
  message from the loader ("could not keep the next files for later … Cache … Request failed"): to fit
  the shared box's last 500 MB of disk I deleted the wing 1 and 2026 packs from the test build after
  exporting it, and the loader's background prefetch of wing 1 got a 404. Not a game error; a full
  build doesn't have it. The test now retries blank (all-black) swiftshader frames and turns off
  Chromium's HTTP disk cache. Phone landscape not rerun (same touch path as portrait).
  First run (before the answers, commit 4fad6bd3, icon on every device): every check passed: desktop (a click on the icon opens MAIN, E to INVENTORY, Tab closes, V still switches
  the view and saves it, J opens the jump panel, 0 console errors); phone portrait and landscape by touch
  (the icon opens MAIN, MAIN's View switches the view and saves it, the icon then the INVENTORY tab,
  0 console errors). Each screenshot is now also checked not blank: on the shared box swiftshader
  sometimes loses the WebGL context under load and screenshots come back black (the game still answers),
  so the full set of shots comes from two runs of the same build (desktop from one, phones from the
  other); `DEVICES=desktop|phone-portrait|phone-landscape` reruns one part, and swiftshader's own
  "WebGL: too many errors" notice is not counted as a game error.
- Updated for the move (they tapped the old buttons): `wsbc_webtest.py` (Bag → icon, INVENTORY tab, ✕),
  `avatar_webtest.py` (View → icon, MAIN's View), `char_webtest.js` (the Menu button's spot → the icon).
  `avatar_webtest.py` was rerun on Nov 4 evening and **did not get through**: in its first part (desktop, the
  creator opening by itself, full shoppers; nothing UI-OFFSCREEN changed) the page crashed under swiftshader
  ("Target crashed", "WebGL: too many errors") while three other sessions were rendering on the box, so its
  phone part (the icon, then MAIN's View) never ran. The same taps at the same spots pass in
  `ui_offscreen_webtest.py`. To rerun on a quiet box. `wsbc_webtest.py` and `char_webtest.js` not rerun.
- Natively, unchanged and still passing: `menu_unit_test.gd` **MENU UNIT OK (64 checks)**; `menu_test.gd
  --wing=2` 68 checks ok and none failed, including MAIN, Edit inside MAIN (`_nav[0][0]` is still Edit),
  every MAIN control on screen at the three sizes, "no year button on the HUD"; the run was stopped by its
  15-minute limit at the INVENTORY HELD step (software rendering on the shared box), not by a failure.
- Not rerun (they read the old buttons' own `.visible`, which UI-OFFSCREEN leaves untouched, and tap
  nothing in the corners): `interact_test.gd`, `avatar_test.gd`, `econ_back_test.gd`; the walk, door and
  shop web tests (`walk_webtest.py`, `doortest.py`, `shops_webtest.py`, `menu_webtest.py`,
  `menu_trip_webtest.js`) tap the game screen, the prompts or the menu's own tabs, never a corner
  button, so no selector changed.

### Evidence (`production/qa/evidence/ui-offscreen-*.jpg`, unbaked)
Native, wing 6 (`ui_offscreen_test.gd`): `ui-offscreen-native-w6-desktop-game-hint-1280x720-unbaked.jpg`
(a desktop: no icon, the first-start walk hint ending "· Tab or Esc: menu"),
`ui-offscreen-native-w6-game-{1280x720,390x844,844x390}-unbaked.jpg` (a touch device: only the icon), `…-menu-main-{…}` (MAIN with Edit / View / Jump to), `…-menu-inventory-{…}`,
`…-jump-panel-1280x720-unbaked.jpg`.
Web, wing 2 (`ui_offscreen_webtest.py`): `ui-offscreen-web-w2-desktop-{game,menu-main,menu-inventory,jump-panel}-unbaked.jpg`,
`ui-offscreen-web-w2-phone-{portrait,landscape}-{game,menu-main,after-view,menu-inventory}-unbaked.jpg`
(after-view: third person after MAIN's View, back on the clean game screen). The desktop and phone-portrait
shots are from the run after Steven's answers (desktop: no icon; its menu-main was opened with Esc); the
phone-landscape shots are from the first run (the touch path, unchanged).

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
| `scripts/menu/menu.gd` | The menu (a CanvasLayer at 45), its tabs, the menu icon (UI-OFFSCREEN; was the Menu button), the input catcher, the opening's flow. Made by `player.gd` as its child `Menu`, after `Avatar`. |
| `scripts/menu/controls.gd` | The InputMap actions `mall_<id>`, remapping, `localStorage "mall-controls-1"`, the translation layer. |
| `scripts/menu/actions.json` | Every action the CONTROLS tab lists, with its **default** keys and pad buttons (data). |
| `scripts/menu/opening.gd` | The opening screen (a CanvasLayer at 50). |
| `data/story/opening.json` | The opening's words: `title`, `text`, `start`, `skip`. Ships with PLACEHOLDERs. |
| `scripts/timetravel.tscn`, `.gd`, `.gdshader` | The time-travel transition (a CanvasLayer at 60; the look is the shader). |
| `tools/qa/menu_test.gd` | Native, unbaked: opening, name, every tab at 3 sizes, keys, remap, HELD / PUT AWAY in both views, the transition, 2026's shoppers. |
| `tools/qa/menu_webtest.py` | The web build: opening, typed name, tabs, remap by keyboard and a reload, phone portrait / landscape by touch. |
| `scripts/menu/portrait.gd` | MENU2: MAIN's turning character. |
| `scripts/timetravel_trip.gd`, `data/directory_twins.json` | MENU2: the trip from a directory's year toggle, and each kiosk's twin. |
| `tools/qa/menu_trip_webtest.js` | MENU2: the trip on the web, both ways, the load screen never shown, the landing. |

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
Tabs, left to right: **MAIN · INVENTORY · CONTROLS** (MENU2; was INVENTORY · AVATAR · CONTROLS · YEAR).
Opening it shows MAIN, the far-left tab (guess, following Steven's Nov 2 rule "the far left opens
first"). `TABS` in `menu.gd`; a JOURNAL tab would be appended after CONTROLS.
| | Keyboard / mouse | Gamepad | Touch |
|---|---|---|---|
| Open / close | **Tab** or **Esc** (UI-OFFSCREEN, Nov 4: Esc opens too; no icon on a desktop) | **Start** (B closes too) | the **menu icon** top left (touch devices only; was the "Menu (Tab)" button), ✕ |
| Tabs | **Q / E**, a click on the tab | **LB / RB** (L1 / R1), and **LT / RT** (L2 / R2) | a sideways swipe, a tap on the tab |
| Inside a tab | ↑↓←→ (W S A D) + Enter / Space | d-pad + A | taps; drag to scroll |
Tab is Steven's call; Tab is the default and it is remappable (CONTROLS). The old ways in open their tab:
**I** / Bag → INVENTORY, **C** / Avatar → MAIN with Edit open. ~~**Y** / the year button → YEAR~~
(removed, MENU2). (A gamepad's Start used to open the creator; it opens the menu now.) **Tab, Start and
the Menu button always open on the far-left tab**, MAIN since MENU2. "L2 / R2 as now" (Steven): the tab
keys were and are the shoulder buttons (LB / RB, pad buttons 9 / 10; L1 / R1 on a PlayStation pad); the
triggers (LT / RT, L2 / R2) now switch tabs as well, once per pull, so either reading works. The player is frozen while it is open
(`player.frozen`), so nothing behind it reacts. The menu doesn't open while something else has the screen
(the prize counter's closer look, the directory), while leaving, or in VR. The menu icon (UI-OFFSCREEN; was the Menu button; touch devices only) sits top left
(under the owner's fps line); the owner-only HUD rules (design/godot-interaction.md) are unchanged.

**How input reaches it:** a catcher node is added last under the root, so its `_input` runs before every
other handler (later siblings get events first). While the menu or the opening is open it takes every
event and taps / clicks its own controls by hand (the project turns touch-to-mouse emulation off, and the
rest of the HUD already works this way). While closed it only passes events through the translation
layer (CONTROLS) and opens the menu.

**iPhone width:** checked at 390×844 and 844×390 (and 1280×720): every control on screen; long lists
scroll by dragging.

### MAIN (MENU2)
The current character turning slowly on the lit stage the creator uses (`scripts/menu/portrait.gd`;
on the left, on top on a tall phone), and beside it **NAME**, **MONEY** and **TICKETS**, then **Edit**.
Edit shows the avatar editing below (the next section) inside MAIN; the creator's Done / Skip goes back to
MAIN with the menu still open (it used to close the menu). Closing the menu any other way keeps what was
made, as before. The first visit's START opens MAIN with Edit open and the NAME field focused.

**Contract with workstream ECON:** MAIN reads `mall.money` and `mall.tickets`, the current year's
balances (`mall` is per year). ECON is not merged on this branch: `mall.money` doesn't exist yet, so
`menu.gd money()` is the one accessor (returns `{value, stub}`; stub = true and $0.00 until the field
exists) and `tickets()` reads `mall.tickets`. Money is shown as `$%.2f` (guess: dollars as a number;
change `money_text()` if ECON keeps cents). MAIN redraws on `mall.changed`.

### Avatar editing (MAIN → Edit; was the AVATAR tab)
The existing creator (workstream V), laid out inside MAIN under a **NAME** field. Its own rows and
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
| Menu | Tab, Esc (opens and closes) | Start (B closes) | menu icon (top left) | keys, pad |
| Menu: previous / next tab | Q / E | LB / RB | swipe, tap | keys, pad (menu only) |
| First / third person | V | right-stick click | Menu: MAIN, View | keys, pad |
| Avatar → MAIN, Edit | C | — | Menu: MAIN, Edit | keys, pad |
| Inventory → INVENTORY tab | I | Back / Select | Menu: INVENTORY | keys, pad |
| Jump to | J | Y | Menu: MAIN, Jump to | keys, pad |
| Put the held item away / Drop it | R / G | — | INVENTORY tab | keys, pad |
| Coin pusher: nudge (tilts if overdone) | N, B, Shift (fixed, in `play/pusher.html`) | LB / RB | NUDGE button, shake | row `tilt`, kind `fixed` (INT, Demo 49) |

**How a remap reaches code written for fixed keys** (so nothing else had to be rewritten, and other
workstreams' new keys can join by adding a row):
- `kind: "poll"` (walking, running): `player.gd` reads `Input.get_action_strength("mall_<id>")`.
- `kind: "event"` (E V C I J R G and their pad buttons; Y left with MENU2): the catcher re-sends a key now bound to an
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

### ~~YEAR~~ (removed, MENU2)
~~The year on show and 1995 / 2026 buttons.~~ The year changes only at a mall directory (below).
`player._switch_year()` stays in the code for tools; nothing the player presses reaches it. The year
button is still made (other HUD code lays out round it) but never shown.

## Time travel at the directory (MENU2, Nov 3)
Steven: "you press the toggle, the directory view closes, you are in normal walking view … standing at
that directory, and the existing time-travel effect starts. It keeps looping for the whole load, with
no load screen in between, then you reappear at the same directory in the other year, same facing.
It's like I've been in this vortex."

**The toggle** (`scripts/directory_ui.gd`): on the sign's frame, top right, the year on show in a box,
and beside it a switch with both years on it, the knob on the year you are in, and the other year (with
"Y" on a keyboard or pad) on the free side. A click / tap on it, **Y** or a gamepad's **Y** travels. The
sign now shows only the year you are in (the old 1995 / 2026 buttons previewed the other year's sign;
Tab and LB / RB no longer switch anything there). Store jumps are always within your year.

**The trip** (`scripts/timetravel_trip.gd`, a node on the root so it outlives the scene):
1. The sign closes; the player is frozen and `leaving` (no prompts, no menu) in their own view, first or
   third person (the view is saved with the look, so it is the same after the load).
2. Two frames later a 480 px JPEG of the screen is taken (web only), then the effect starts in its loop
   mode (`timetravel.gd start_loop`): the original ramp and its three flashes (0.2 / 0.5 / 0.9 s), then
   the **vortex**, a tunnel of spiralling bands in the effect's three tints with the world still
   glimpsed through its eye, a soft light beat every 1.6 s. It never goes to black.
3. After 1.75 s the other year loads at the twin spot (`?wing=&cam=&year=`, the same lighting and
   toggles as every other crossing). Native (editor, tests): the scene changes under the running loop.
4. The new year's player calls `arrive()`; the vortex is picked up at the same moment of its loop and
   unwinds (1.1 s, a bright flash first): you are at the directory in the other year, facing the same way.

**Where you land:** `data/directory_twins.json` lists each kiosk in both years with its wing. Your place
relative to the kiosk (and your facing) is carried to its twin, turned if the twin faces another way
(`landing()`). Today both twins stand where they stand in the other year, facing the same way, so you
land exactly where you stood. **Open question:** kiosks 3 (H3, the main entrance) and 4 (C3, the Dillard's
court) exist only in 1995 (guesses in design/godot-directory.md); 2026 has no directory there. Their
toggle still travels, to the same spot in 2026 with no kiosk (guess, marked in the data); Steven to say
whether those two should travel, hide the toggle, or whether 2026 should get kiosks there.

### What stops the swap being seamless, and the design round it
- **The page reload.** Each wing in each year is its own game file (`w1.pck`, `w1y26.pck` …, design/
  godot-wings.md, 2026-year): the engine boots with one main pack, and the shell picks it from `?wing=` /
  `?year=`. Changing year means another main pack, so the page reloads (`window.mallGoWing`). A true
  no-reload swap would need either (a) `ProjectSettings.load_resource_pack()` of the other year's pack
  into the running engine, or (b) restarting the engine in the same page. (a) doubles the memory (two
  ~100-200 MB packs in the browser's file system plus their textures), which is exactly what the iPhone
  can't afford, and the two years' packs overlap in paths (scripts, shared textures) with no guarantee
  they match across exports. (b) Godot's web engine is not built to be started twice in one page
  (Emscripten module state), and it frees nothing a reload doesn't. **So the reload stays and is hidden.**
- **The web shell's load screen.** Every reload showed the Houma Mall Rewind / Southland card (with the
  wing name on a crossing). For a trip it doesn't: `sessionStorage "mall-tt"` (written just before the
  reload: `{start, from, to, snap}`) makes the shell, from its very first paint (a `<head>` script sets
  `html.tt`), hide the card and run **#tt-veil**: the same shader in WebGL (`TT_FRAG`, a line-for-line copy
  of `scripts/timetravel.gdshader`) on the snapshot, with the same envelope (`ttEnv` = `timetravel.gd
  env()`). Every value is a function of wall-clock time since the trip began (`start`), so the old page's
  effect, the veil and the new page's effect are all at the same moment of the loop at each hand-over.
- **The hand-back.** The veil stays up by the load screen's own rule (until the game is running and the
  shoppers are warmed up, `lift()`), then fades over 0.35 s into the game's own vortex, which is already
  running underneath at the same phase, and the game then unwinds it. A stale trip (> 120 s) is ignored,
  and a manual refresh shows the normal load screen (the key is removed when read).
- The other year's file is usually already in the cache (`mallPrefetchOther` fetches this wing's other
  year second); on a cold cache the vortex simply loops for as long as the download takes.
- **The page's main thread is blocked for seconds at a time while the engine starts** (compiling the
  wasm, opening the pack: under swiftshader the veil drew 10 frames in 17 s). WebGL only draws between
  those stalls, so the veil also has `#tt-spin`, a disc of the vortex's tints turned by a CSS animation,
  which runs on the compositor and keeps turning while the main thread is busy. The WebGL veil is drawn
  at most 360 px wide (scaled up; the vortex is soft) about 20 times a second, to leave the GPU to the
  starting game.
- **The snapshot** (`get_image()` of the frame) is a GPU read-back: a few ms on a real GPU, ~15 s under
  swiftshader in the cloud tests. It happens before the effect starts, so a slow device shows a brief
  hitch there, not a break in the vortex.
- **Reduced motion:** no ripple, flashes or vortex on either side: a dark veil that lifts. **VR:** the
  directory isn't used in the headset; a trip refuses to start in VR.

**Static geometry:** none touched. The toggle is drawn by the directory UI (a dynamic overlay); the kiosks
and panels are unchanged, so **no wing needs a rebake** for this.

## The time-travel transition
MENU2: the shader now takes envelope values (`amt`, `ph`, `flash`, `vort`, `dark`) computed in
`timetravel.gd env(t, u)` from the seconds since the trip began (`t`) and into the outro (`u`); the old
one-shot `play()` (below) is the same look with `vort` 0 and the fade to black, kept for any other caller.
Re-dressing it means changing `timetravel.gdshader` and `TT_FRAG` in `web/shell.html` together (and
`env()` with `ttEnv`). Below, the Nov 2 description of the one-shot.

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

## Checks (MENU2, Nov 3, on `ws/menu2`; unbaked)
- `tools/qa/menu_unit_test.gd` (headless): **MENU UNIT OK (64 checks)**, adding: no year action and no Y
  default anywhere, an old saved year remap dropped, the kiosk twins (both filmed kiosks have one, the
  1995-only ones don't), `landing()` (same-facing twin, and a twin turned 90°), the loop never black and
  smooth frame to frame, the outro ends clear.
- `tools/qa/menu_test.gd` (native, wing 2): **MENU TEST OK (89 checks)**: tabs MAIN / INVENTORY /
  CONTROLS; MAIN's portrait, name, money (stub), tickets; Edit inside MAIN and Done back to MAIN; every tab
  and Edit at 1280×720 / 390×844 / 844×390; Q / E, LB / RB, LT / RT; Tab opens on MAIN; Esc and B close;
  I, C; **Y does nothing**, no year row, no year button; then the JCPenney court directory: the sign shows
  1995 with the toggle, Y closes it and starts the trip, a frame every 0.15 s, the scene changes under the
  loop (no reload natively), lands in 2026 0.00 m from the twin spot, same facing, the vortex unwinds and
  the player is free; 2026's 3 shoppers as before. (Test fix: workstream R's "You received" cards hold the
  player after `take()`, so the test dismisses them before opening INVENTORY.)
- `tools/qa/menu_trip_webtest.js` (web build, Node Playwright, wing 1's H2 kiosk): **MENU TRIP WEB OK (20
  checks)**: 1995 → 2026 and back, each: the trip begins, the load screen never visible (0 of ~33 frames the
  page could sample, and 0 of 292 / 430 screencast frames look like it), the veil covers the reload, lands
  0.00 m from the twin spot with the same facing, the right year's file, 0 console errors.
  `node tools/qa/menu_trip_webtest.js "<build>/index.html" <out>` (server on :8765 at the repo root).
- `tools/qa/menu_webtest.py` (web, wing 2): **MENU WEB OK (8 checks), 0 console errors**, with MAIN first.
- Found and fixed on the way (web only): the arriving trip was added to the root while it was still
  setting up the first scene, so it never entered the tree, and in a release build the wait loop then
  spun forever on a null `get_tree()`, freezing the page; it is now added deferred and lands from `_ready`.

## Evidence (MENU2: `production/qa/evidence/wsMENU-*`, unbaked)
MAIN at 1280×720 / 390×844 / 844×390, Edit inside MAIN, INVENTORY, CONTROLS, the opening, the directory
with its year and toggle (and a close-up), the native trip as frames
(`wsMENU-trip-native-1995-2026-frames-unbaked.jpg`), the web trips both ways as screencast frame sheets
through the reload (`wsMENU-web-trip-<dir>-frames-unbaked.jpg`) with the directory before and the arrival
after, the web menu (desktop, phone), and the test logs (`wsMENU-*-test.log.txt`). The swiftshader
timeline is slow (the snapshot ~15 s, the engine start ~60 s); on a phone's GPU both are far shorter.

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
  "Drop", "Skip", the menu icon's tooltip "Menu (Tab)" (was the Menu button's words), MAIN's "View: 1st / 3rd
  person" and "Jump to".
- Guess: Esc and a pad's B close the menu as well as Tab / Start.
- Guess: a pocket-class item can't be HELD.
- Guess: START without a name shows the opening again next time; Skip doesn't.
- ~~Guess: Y now opens the YEAR tab~~ (MENU2: Y does nothing; the directory's toggle is the only year switch).
- MENU2 guesses: the menu opens on MAIN (the far-left rule); Edit's Done / Skip returns to MAIN rather than
  closing the menu; money shows as `$0.00` (dollars) until ECON's `mall.money` lands; the toggle at the two
  1995-only kiosks travels to the same spot (above). **Kept from M, checked against MENU2, no conflict:**
  Esc and B close the menu; START without a name shows the opening again next time.
- Guess: 2026's three walk as ordinary shoppers (no roles), at 2026's store doors.
- The contract says "the mall autoload"; there isn't one (above). An autoload could be added if Steven
  wants `mall` reachable without the player; it would be a project.godot change for every wing.
