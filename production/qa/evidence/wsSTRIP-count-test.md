# CHAR-STRIP: the counting test (Nov 8 2026)

Rule 5 of `design/godot-characters-research.md` §3, as built in `design/godot-avatar.md` "The counting test".
Branch `ws/char-strip`. Unbaked, native under xvfb (Godot 4.7.2, opengl3 on llvmpipe).

## Native: `tools/qa/cast_count_test.gd`

```
xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
  --script res://tools/qa/cast_count_test.gd -- --out=/tmp/cc/t
```

Setup: a returning player from before CHAR-STRIP, both old records planted (`mall-avatar-1` = V's look on
Ch21, `mall-avatar-preset-1` = a B2 preset named OLDNAME), no `mall-player-2`.

| Step | Skeletons under the player group | World body (cast id) | Saved (`mall-player-2`) | MAIN portrait |
|---|---|---|---|---|
| load (wing 6, 1995) | 1 | placeholder_1 | placeholder_1 | placeholder_1 |
| menu open / close ×2 | 1 | placeholder_1 | placeholder_1 | placeholder_1 |
| pick in the Character row (button press) | 1 | placeholder_3 | placeholder_3 | placeholder_3 |
| reload (wing 6 again) | 1 | placeholder_3 | placeholder_3 | placeholder_3 |
| wing crossing (`player._go_to_wing(4)`: wing 6 → wing 4) | 1 | placeholder_3 | placeholder_3 | placeholder_3 |
| year crossing (wing 4 → wing 4 2026) | 1 | placeholder_3 | placeholder_3 | placeholder_3 |
| time-travel trip (2026 → 1995, `timetravel_trip.gd`) | 1 | placeholder_3 | placeholder_3 | placeholder_3 |
| wing 1 (5 attendants + 2 Cuco's patrons under Player/Story) | 1 | placeholder_3 | placeholder_3 | placeholder_3 |

Per-frame watcher (every frame from the first load to the end, crossings included, world skeletons only):
**323 frames, at most 1 player skeleton in any frame.**
Migration: both old records deleted, the name OLDNAME moved into `mall.player_name`, the player starts as
the default cast member.

Result: **CAST COUNT OK (48 checks)**.

**What the test found on its first run:** after the menu closed there were **6** skeletons under the player
group: the menu (a child of the Player node) kept its page, and with it the MAIN portrait's body and the four
Character-row bodies, alive while hidden. Fixed in `scripts/menu/menu.gd` (`_drop_page()` on close: the page
leaves the tree and is freed). A second finding (from the web run): the story machinery hangs its people under the Player node
(Player > Story: the counter attendants and the Cuco's patrons), so "under the player group" counted them
too (wing 1: 8). They are not the player's; both counters now skip the Player/Story subtree (a body made
the old way was added to the world, not under Story, so a stray second player body would still be counted).
The table above is the final run.

Pictures: `wsSTRIP-world-portrait-match-native-unbaked.jpg` (the world body after the reload, and MAIN with the
same member picked).

## Web: `tools/qa/avatar_webtest.py`

```
CHROMIUM=/opt/pw-browsers/chromium WING=1 OTHER=2 python3 tools/qa/avatar_webtest.py \
  prototypes/godot-mall/project/.scratch/builds/strip/index.html /tmp/web/av/t
```
Unbaked desktop export of wings 1, 2, 4, 6 (both years), swiftshader Chromium, one browser at a time,
`?debug=1` (the game prints `CASTCOUNT` once a second and `CASTPORTRAIT` when MAIN is built), `npcs=0`.

| Step | `CASTCOUNT` skeletons (last 3 reports) | Body / saved |
|---|---|---|
| load (wing 1, old records planted) | 1, 1, 1 | placeholder_1 / placeholder_1 |
| Character row by keys (Tab, down, right, Enter) | 1, 1, 1 | placeholder_2 / placeholder_2 (portrait placeholder_2) |
| reload | 1, 1, 1 | placeholder_2 |
| wing crossing 1 → 2 (`window.mallGoWing`, the game's page reload) | 1, 1, 1 | placeholder_2 |
| year crossing (wing 2, `?year=2026`) | 1, 1, 1 | placeholder_2 |
| phone 390×844 touch: tap on the third portrait | n/a | saved placeholder_3 |

Old records deleted, the name came over (OLDNAME), never more than 1 in any report, **0 console errors**.
Result: **AVATAR WEB OK (27 checks)**. The time-travel trip is covered natively (the web runs one browser
and the trip is the same scene change as the crossing, behind the trip's veil instead of the card).

Pictures (all unbaked):
- `wsSTRIP-crossing-sequence-web-unbaked.jpg`: 8 frames of the wing 1 → 2 crossing (0.5-2 s apart; frame 5
  is the loading card): the same person throughout. Frame 3 is darker across the whole frame (the store fronts
  too): swiftshader's lighting, not another body.
- `wsSTRIP-menu-character-row-web-unbaked.jpg`: MAIN with the Character row, desktop 1280×720 and phone 390×844.
- `wsSTRIP-world-portrait-match-web-unbaked.jpg`: the world body after the pick and MAIN's portrait, the same
  member (placeholder_2). The selected thumbnail is brighter: the keyboard selection's tint.
