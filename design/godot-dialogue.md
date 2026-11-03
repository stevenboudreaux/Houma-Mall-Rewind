# Dialogue engine, counter attendants and the book reader (Godot mall, workstream Q, Nov 2 2026)

**Asked for (Steven, Nov 2):** a Fallout 3 / New Vegas style dialogue engine on Nathan Hoad's
Dialogue Manager, kept stateless (flags in `mall.flags`, `design/godot-quests.md`); three counter
attendants (Pocket Change, Sound Shop, Kay-Bee Toys); a book reader that runs a dialogue file as
a choose-your-own-adventure book.

**Ground rule (Steven, Nov 2): Steven writes the story; this is the machinery.** No character
name, backstory, line, quest, item or fixture is invented here. Every conversation shipped is a
PLACEHOLDER: in its file name (`data/story/placeholder/PLACEHOLDER_*.dialogue`) and in its text
("PLACEHOLDER line 1"). The attendants' names are "PLACEHOLDER … attendant".

## Files
| File | What |
|---|---|
| `addons/dialogue_manager/` | Dialogue Manager **4.2.0** (Nathan Hoad, MIT, `LICENSE` inside; for Godot 4.6+, the project is 4.7.2), vendored whole except `DialogueManager.cs` (C#; this is not a .NET build). The editor plugin is **not** enabled (see "Loading"). |
| `scripts/dialogue/dialogue_runner.gd` | Loads and compiles `.dialogue` files, the shorthands, the addon node. |
| `scripts/dialogue/dialogue_state.gd` | What a file can see and do: flags, `name`, `has`, `holding`, `give`, `take`, `unlock`, `lock`. |
| `scripts/dialogue/dialogue_ui.gd` | The conversation screen: the camera, the box, the responses, input. |
| `scripts/dialogue/book_ui.gd` | The book reader. |
| `scripts/dialogue/story.gd` | Per wing: makes the screens, the gates, the attendants; `talk()`, `read_item()`. |
| `scripts/dialogue/gate.gd` | Locked places (`design/godot-quests.md`). |
| `scripts/attendants/attendant.gd` | A counter attendant. |
| `data/story/attendants.json`, `books.json`, `gates.json` | The data. |
| `data/story/placeholder/*.dialogue` | PLACEHOLDER files: the three attendants, the book, a grammar check. |
| `tools/qa/dialogue_walk.gd` | Headless: walks every PLACEHOLDER file down every branch through the real addon. |
| `tools/qa/dialogue_shots.gd` | Native, unbaked: the evidence screenshots. |

Shared files touched, in small hunks marked `Q`: `scripts/player.gd` (makes `Story` after
`Interact`; `_cross()` asks the gates), `scripts/interact.gd` (makes `mall.flags`; "Read …" for a
held book; the bag's Read button), `scripts/inventory.gd` (`var flags`), `export_presets.cfg`
(`addons/dialogue_manager/*,data/story/*` at the front of every preset's include filter).

## Grammar (what Steven can write)
A `.dialogue` file is Dialogue Manager's own language
(`addons/dialogue_manager/../docs` upstream: Basic_Dialogue, Conditions_Mutations), with the
game's state below. Indentation is tabs.

```
# a comment
~ start                                   # a cue (a label); a file starts at "start", else its first cue
Speaker Name: A line. One line = one screen.
Speaker Name: Hello, {{name}}.             # the player's name
A line with no speaker.
- A response                               # responses follow the line they answer
	Speaker Name: What this response leads to (indented under it).
	- A second-level response              # any depth
		=> END                             # end the conversation
- Another response => some_cue             # jump to a cue
- Only when carrying the Pog pack [if has pogs /]
=> END
```

| Write | Means |
|---|---|
| `~ cue_name` | a cue (jump target) |
| `=> cue_name` / `=> END` | go to a cue / end the conversation (`END!` too) |
| `- text` | a response (a line followed by responses shows them as choices; 3 fit the design, more show) |
| `- text [if condition /]` | a response that shows only when the condition holds |
| `if condition` / `elif condition` / `else` (indented block under it) | branch |
| `{{name}}` | the player's name: `mall.player_name` (session M); **"friend" until M lands** |
| `{{some_flag}}` | a flag's value in a line |

**Conditions** (in `if` / `elif` / `while` lines and `[if … /]`; join with `and`, `or`, `not`, `( )`):
| Write | True when |
|---|---|
| `some_flag` | the flag is set and truthy (never set = false) |
| `not some_flag` | it isn't |
| `some_flag == 2` | the flag's value (numbers, strings) |
| `has pogs` (or `has("pogs")`) | the item is carried: in the bag or in the hand |
| `holding pogs` (or `holding("pogs")`) | the item is **in the hand** now (Steven: holding an item while talking is a quest trigger) |

**Effects** (each on its own line):
| Write | Does |
|---|---|
| `set some_flag = true` (or `$> some_flag = true`, `false`, a number, a string) | sets the flag in `mall.flags` |
| `give pogs` (or `$> give("pogs")`) | one into the bag (`mall.add`, saved). The "You received …" pop-up is session R's; until it lands a plain "Received: …" notice shows. |
| `take pogs` | one out of the bag (or the hand when it's held there) |
| `unlock some_gate_flag` | sets a gate's flag true: the gate opens at once (`design/godot-quests.md`) |
| `lock some_gate_flag` | sets it false |

Item ids are the `id`s of `data/items/*.json` (e.g. `pogs`, `candy_neck`, `bl_bd_paperback`).
Everything else Dialogue Manager offers (random lines `%`, `match`, `while`, BBCode such as
`[b]`, `[i]`, `[color=…]`) works as upstream documents it. **Not supported here:** inline
mutations inside a line (`[$> …]`), `[wait=…]`, `[speed=…]` and `[next=…]` (the box types at one
speed and always waits for "continue"), `using` and C# states. Character portraits: none (the
camera shows the face).

The shorthands without brackets (`give pogs`, `has pogs`, `holding pogs`, `unlock x`, `lock x`,
`take x`) are rewritten to the bracket form before compiling (`dialogue_runner.gd preprocess()`);
spoken text is never touched. Flag names a file mentions read as false before they are ever set.

## Loading (stateless, no import)
The addon's editor plugin is not enabled: files are read as text and compiled at run time by the
addon's compiler (`DMCompiler.compile_string`), so they ship as plain files (the export include
filter `data/story/*`) and need no import step on the Mac or in the cloud. The addon's runtime node
is made under the root on first use and registers itself as the `DialogueManager` singleton; the
only state it is given is `dialogue_state.gd`, which reads and writes `mall.flags` and `mall`. A
compile error prints the file and line and the conversation doesn't start. If Steven enables the
plugin (Project → Plugins) to use its editor, the files get imported; loading still works (the
runner falls back to `load()`).
Web export: checked, works (see Checks).

## The conversation screen (`dialogue_ui.gd`)
Anything in groups **`"talker"`** and **`"interactable"`** whose `interact()` calls
`story.talk(self, path)`. Optional on the NPC: `talk_begin(player)`, `talk_end()`,
`face_point() -> Vector3` (the eyes).

| Step | Numbers |
|---|---|
| Interact → the player stops (`player.frozen`), the HUD hides (every other CanvasLayer), the NPC stops, turns to the player at once and plays its idle | |
| A camera of its own tweens from the current view (first or third person) to the face | **0.5 s**, cubic in-out; FOV 70 → **45°** |
| The face shot | **0.85 m** in front of the eyes on the line toward the player, aimed **0.12 m below** the eyes, so the face sits in the upper middle above the box |
| The box | bottom, 16 px from the edges, at most 900 px wide; name in gold 18 px; the line 21 px, typed at **50 characters/s**; "continue >" |
| Continue | E, Enter, Space, a gamepad's A or X, a click, a tap anywhere. A press while typing finishes the line. |
| Responses | a vertical list, rows 56 px tall (tap targets); **1–3** (1–9), ↑↓ / W S + Enter / E, d-pad or left stick + A, a click, a tap |
| END | the camera tweens back (0.5 s) to the view it came from; the HUD returns; control returns; the NPC resumes |

VR: interactions are off in VR (the shared action button is), so no conversation starts there;
VR is otherwise untouched.

### Add an NPC conversation (data only)
1. Write `data/story/<name>.dialogue` (grammar above).
2. For a counter attendant: add an entry to `data/story/attendants.json`. For any other NPC: give
   it groups `talker` + `interactable`, `interact_prompt()` returning `"TALK"`, and in `interact()`
   call `player.get_node("Story").talk(self, "res://data/story/<name>.dialogue")`.
3. Run `tools/qa/dialogue_walk.gd` style checks (copy a case) and look at it in the game.

## Attendants (`attendant.gd`, `data/story/attendants.json`)
One unique person behind each counter, 1995 only (all three stores are gone in 2026; see Open).
| Store | Wing | Skin (Steven may swap) | Behind the counter (area x0,z0 → x1,z1) | Faces | Talk spot | PLACEHOLDER file | Gives (placeholder) |
|---|---|---|---|---|---|---|---|
| Pocket Change | 2 | **Ch22** (f) | −103.2, 65.8 → −102.85, 67.8 (the north end, between the showcase and the prize wall) | −x (the room) | **−104.0, 68.9** (the counter's north end; see below) | `PLACEHOLDER_pocket_change.dialogue` | `candy_neck` (Candy necklace) |
| Sound Shop | 1 | **Ch38** (m) | −14.1, −58.9 → −11.7, −58.65 (between the register counter and the back counter) | −z | −12.9, −60.35 | `PLACEHOLDER_sound_shop.dialogue` | `rs_microcassette` |
| Kay-Bee Toys | 1 | **Ch41** (f) | −14.1, −52.85 → −12.2, −52.65 (between the cash wrap and the video case) | −z | −13.1, −54.0 | `PLACEHOLDER_kay_bee.dialogue` | `slap` (Slap bracelet) |

**Pocket Change's talk spot:** in front of both cases (the long showcase and the short case by
the door) the prize counter's closer look (`scripts/prizes.gd`, "Look at the prizes") shows its
own prompt, and while it shows the shared action button does nothing (`design/godot-interaction.md`),
so an attendant there could never be talked to. The talk spot is therefore the open north end of
the counter (outside both closer-look zones), and the attendant keeps to the north half of the space
behind it. When session R's redemption screen lands, R decides how the glass and the attendant
share the button.

Positions are read from the stores' builders and collision rects (`tools/stores/pocket_change/`,
`tools/stores/media/sound_shop.gd`, `tools/stores/kay_bee/store.gd`, `gen/w*/collide.json`). Skins
are Mixamo crowd skins every pack ships; each is marked in use for the crowd in that wing, so no
shopper wears the same person (Ch38 is an arcade player in wing 2 only; the attendants of wing 1
don't clash). Behaviour: wanders to a new spot inside its area every 4–9 s at 0.55 m/s, never
leaves it, faces the player within 3 m, otherwise faces the shop; prompt **TALK**. Nothing is
baked: no rebake needed.

The PLACEHOLDER conversations all have the shape asked for: an opening (two lines), three
responses, the second leads to a second line and three more responses, of which the second
sets the store's `placeholder_<store>_done` flag and gives the item; every other response ends.
Talking again with the flag set gives a one-line "already done" PLACEHOLDER. The given items exist
in 1995 (`data/items/`); note that an item that also lies in the world can then be had twice
(placeholder choice only).

### Contract with session R (the redemption screen)
`attendant.gd interact()` holds a commented hunk: when the attendant's entry has
`"redemption": true` (Pocket Change) and `mall.redemption` exists with `open()`, it calls
`mall.redemption.open()` and returns; otherwise the PLACEHOLDER dialogue runs. R uncomments it and
makes the counter glass (`scripts/prizes*.gd`, R's files) call the same `mall.redemption.open()`.

## Books (`book_ui.gd`, `data/story/books.json`)
A book is an item id mapped to a `.dialogue` file. **Each line is a page**; a line followed by
responses is a branch point, its responses printed as the choices at the foot of the page; flags
and effects work as in conversations. Controls: "Turn page >" (E, Enter, Space, →, A/X, a tap or
click on the page), choices 1–3 / arrows + Enter / d-pad + A / tap, Esc / B / X closes (it opens at
the start next time). The last page shows "Close the book".
Opened from: **the bag** ("Read" on the book's row) and **the hand** (the action button reads
"Read …" when a book is held and nothing else is in reach). The B. Dalton paperback ids
`bl_bd_paperback`, `_b`, `_c` (three copies, "pocket" items, so today only the bag's Read
applies; holding comes with session M's held/put-away toggle) all open
`PLACEHOLDER_book.dialogue`: two pages, a branch of two, then two or one pages, a shared ending
that sets `placeholder_book_finished`.

## Checks
- `godot --headless --path . --script res://tools/qa/dialogue_walk.gd` → `DIALOGUE WALK OK`.
- `godot --headless --path . --script res://tools/qa/flags_test.gd` → `FLAGS TEST OK`.
- Native, unbaked (no lightmap, night lighting as `interact_test.gd`):
  `xvfb-run -a -s "-screen 0 1600x1000x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 --script res://tools/qa/dialogue_shots.gd -- --wing=2 --out=/tmp/q/w2`
  → DIALOGUE SHOTS OK (26 checks); `--wing=1` → OK (18); `--resolution 390x844 … --wing=2 --phone` → OK (16).
- Web: `CHROMIUM=/opt/pw-browsers/chromium python3 tools/qa/wsq_webtest.py <build>/index.html <out>`
  (server on :8765 at the repo root). Nov 2, wings 1+2 1995 exported with this branch: **ALL OK, 0
  console errors** in each run: desktop right path (the give lands in `mall-state-1995`, the flag in
  `mall-flags-1`, both survive a reload, a second talk is the "already done" line), phone 390 × 844
  (touch continue), the Dillard's gate, the book from the bag (its ending flag saved). So Dialogue
  Manager runs in the web export, plugin off, files compiled at run time. Evidence
  `wsQ-web-unbaked-*.jpg`. Seen there and fixed after: the web font has no ▸ / ✕ glyphs (boxes);
  the box and book now say "continue >", "Turn page >", "X".
- movetest (wing 2 web, cams at the Pocket Change talk spot and the Dillard's opening): 0 errors, the
  touch-drag walk MOVED (`wsQ-web-unbaked-movetest-*.jpg`).
- Evidence `production/qa/evidence/wsQ-unbaked-*.jpg`: each attendant's approach (TALK prompt), the
  camera on its way, the face shot with a line, the three choices; Pocket Change's second level,
  the give ("Received: Candy necklace") and the bag after; the Dillard's locked messages (opening,
  outside door); the bag's Read button; the book's page, choices and end; `-phone-` at 390 × 844.

## Notices
"Received: …" (until R's pop-up) shows above the talk box or the book while they are up (the HUD
is hidden then); otherwise, and for the gates, `story.say()` prints a line bottom middle on its
own layer. Found on the way: **`player._say()`'s label lands off-screen in a native window** (at
1280 × 720 it was placed at 1080, 1350: its position is added to its bottom-centre anchors). Not
changed here (shared file; the web build may differ); `story.say()` sidesteps it.

## Open (questions for Steven)
- Names, lines, what each attendant gives and why: all PLACEHOLDER until written.
- 2026: Sound Shop and Kay-Bee are gone; the Pocket Change space is "GAMES, INC. (POCKET
  CHANGE)" in the 2026 map. Is that a counter with an attendant too (and who)? None placed now.
- Skins: Ch22, Ch38, Ch41 are picks; swap freely in `attendants.json`.
- A talking clip during lines (the rig has `talk`, `talk_2` …) instead of idle? The brief said idle.
