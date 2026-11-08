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

Per-frame watcher (every frame from the first load to the end, crossings included, world skeletons only):
**282 frames, at most 1 player skeleton in any frame.**
Migration: both old records deleted, the name OLDNAME moved into `mall.player_name`, the player starts as
the default cast member.

Result: **CAST COUNT OK (42 checks)**.

**What the test found on its first run:** after the menu closed there were **6** skeletons under the player
group: the menu (a child of the Player node) kept its page, and with it the MAIN portrait's body and the four
Character-row bodies, alive while hidden. Fixed in `scripts/menu/menu.gd` (`_drop_page()` on close: the page
leaves the tree and is freed). The second run is the table above.

Pictures: `wsSTRIP-world-portrait-match-native-unbaked.jpg` (the world body after the reload, and MAIN with the
same member picked).

## Web: `tools/qa/avatar_webtest.py`
(filled in below after the web run)
