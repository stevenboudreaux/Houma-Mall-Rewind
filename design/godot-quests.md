# Quest flags and locked places (Godot mall, workstream Q, Nov 2 2026)

**Asked for (Steven, Nov 2):** quest flags the dialogue files read and write, saved beside the
carried state, surviving wing loads and reloads, with an owner-only debug list; a locked-door
helper; Dillard's locked behind a flag in both years. **Ground rule:** Steven writes the story;
this is machinery only. Every message and flag used for testing is a PLACEHOLDER.

## Files
| File | What |
|---|---|
| `scripts/flags.gd` | `mall.flags`: the flags, their signal, their storage. Pure data. |
| `scripts/dialogue/gate.gd` | A locked place: closes walk-grid tiles and refuses exterior doors while its flag is false. |
| `scripts/dialogue/story.gd` | Makes the gates (and the attendants, the dialogue screen, the book reader) in every wing. |
| `data/story/gates.json` | The gates. Today one: Dillard's. |
| `tools/qa/flags_test.gd` | Headless unit checks (set/get, signal, save round trip, Engine-meta persistence, bad input, the gate's tiles, the gates file). |

Shared files touched, in small hunks marked `Q`: `scripts/inventory.gd` (`var flags`),
`scripts/interact.gd` (makes `mall.flags`), `scripts/player.gd` (makes `Story`; `_cross()` asks the
gates before opening an exterior door).

## `mall.flags` (scripts/flags.gd)
| Call | Does |
|---|---|
| `mall.flags.has(name) -> bool` | set and truthy (`true`, a non-zero number, a non-empty string). A flag never set is false. |
| `mall.flags.get(name)` | its value; `null` when never set |
| `mall.flags.set(name, value)` | sets it (value required, see below) |
| `mall.flags.set_flag(name, value = true)` | the same with the default the brief asked for |
| `mall.flags.get_flag(name, default)` / `clear(name)` / `names()` | helpers |
| `signal changed(name, value)` | once per real change (`null` when cleared) |

- **Why `set()` needs its value:** GDScript refuses a method named `set()` whose signature differs
  from Godot's own `Object.set(name, value)`, so the default (`value = true`) can't be written on
  `set()`. `set_flag()` has it. `set()`/`get()` work from untyped code (`mall.flags.set("x", true)`,
  which is how everything here calls them); from a variable typed as `Object`/`RefCounted` the
  engine's own `set()` runs instead and nothing happens, so typed code uses `set_flag`/`get_flag`.
- Names: letters, digits, underscores (`dillards_unlocked`). Values: bool, number, string.
- Avoid flag names that are also Godot node properties (`visible`, `position`, `name`, `scale` …):
  Dialogue Manager ignores those names when a file assigns them.

### The save key
| Where | Key | Shape |
|---|---|---|
| Web | localStorage **`mall-flags-1`** (also mirrored to `window.mall.flags`) | `{"v": 1, "flags": {"dillards_unlocked": true}}` |
| Editor, tests | Engine metadata `mall_flags` (survives a wing change in one run) | same JSON |

Written after every change; read when a wing starts (`interact.gd`), so flags survive wing loads,
year switches and reloads. **One store for both years** (a guess: the inventory is per year,
`mall-state-1995` / `mall-state-2026`, but a story that unlocks Dillard's probably means both
years; Steven to confirm). A different `v` is ignored (fresh start), never misread. Clearing the
site's data resets the story.

### The owner's debug list
Owner mode only (`?owner=1`, the editor, the secret code). In the browser console:
`mallFlags()` prints the table; `mallFlags('dillards_unlocked', true)` sets one,
`mallFlags('x', null)` removes one (reload to apply). Natively the flags are printed at start.
Visitors don't get the function.

## Gates (scripts/dialogue/gate.gd, data/story/gates.json)
A gate is a node in group **`"gate"`** holding a flag name. While `mall.flags.has(flag)` is false:
- **the walk grid is closed** over `rect` (`[x0, z0, x1, z1]` world metres, snapped out to whole
  2 m tiles) in the gate's `wing`: walking stops there, the shoppers' paths avoid it (they copy the
  grid after the gates close), VR's stick walking stops too (it uses the same `_free()`);
- **walking into it shows `message`** (bottom middle, like other notices), once per approach;
- **the exterior doors listed in `doors`** (`exterior.json` door `"store"` keys) refuse to open, in
  every wing (the mall side and the parking lot): pressing E / A / tapping the "Go outside" or
  "Enter the mall" prompt shows `door_message` instead of loading the other wing.
The moment the flag is set (a dialogue's `unlock`, the console) the tiles reopen and the doors work.
Nothing is built or baked: no rebake is needed for a gate, and the store looks open (no grille).

```json
{"id": "dillards", "flag": "dillards_unlocked", "years": "both", "wing": 2,
 "rect": [-10.0, 80.0, 2.0, 82.0], "doors": ["s2e", "s2s"],
 "message": "PLACEHOLDER locked message (Dillard's mall opening)",
 "door_message": "PLACEHOLDER locked message (Dillard's outside doors)"}
```
Add a gate: one more entry. `years`: 1995, 2026, `"both"` or a list. A gate with only `doors` (no
`rect`) locks doors only.

### Dillard's (both years)
- The mall opening is H8's width, x −10..2 at z = 80 (`design/godot-dillards.md`). The gate closes
  the first row of tiles inside the store (x −10..2, z 80..82: map tiles 143–148, row 140), so the
  player stops in the opening, at about z 79.7, looking in.
- The two outside doors, `s2e` (east entrance) and `s2s` (south entrance), are locked from both sides.
- The Jump menu's "Dillard's" spot (−4, 75.5) is on the mall side, outside the gate.
- Flag: **`dillards_unlocked`**. Nothing sets it yet; Steven decides what does. To test:
  `mallFlags('dillards_unlocked', true)` as the owner, then reload.

## Checks
`godot --headless --path . --script res://tools/qa/flags_test.gd` → `FLAGS TEST OK`.

## Open
- One flag store for both years (guess above).
- The locked opening has no visible barrier (a rolled-down grille, a "closed" sign …): a fixture
  is Steven's call, not invented here.
- Messages are PLACEHOLDERs.
