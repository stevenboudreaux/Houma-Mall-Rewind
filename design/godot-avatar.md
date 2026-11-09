# The player's character and first / third person (Godot mall)

Rewritten Nov 8 2026 by **CHAR-STRIP** (branch `ws/char-strip`, from `ws/talk`). Workstream V (Nov 1) made
the avatar and the third-person view; B2 / CHAR-EDITOR (Nov 2-4) added a second avatar system and a
character editor. Both avatar systems and the editor are gone; what V built for walking, the camera and the
held item stays. The research behind it: `design/godot-characters-research.md` (branch `ws/char-research`)
§1 (why there were two bodies) and §3 (the rules below). `design/godot-character-editor.md` is superseded.

## Steven's decisions (Nov 8 2026)
- The editor goes: no sliders, no colours, no edit, for the player or the owner (K is gone too).
- The player **picks one of 3-4 cast members** from a simple row in the menu: a portrait and a name each.
- Shirt words on the crowd shoppers stay (`scripts/npc_shirt.gd`).
- Keep the rig, the clips, the crowd, the warm-up, and the third-person camera and gaits.

## The five rules (research note §3) and where each lives
1. **One person = one id + one file.** `data/cast.json` lists the cast: `name`, `sex`, `height_m`, `hips`,
   and the file. CHAR-BUILD bakes each person into `cast/<id>.glb` (`"glb"`). Until it delivers, the cast is
   **four PLACEHOLDER members on Mixamo crowd skins** (`"stub"`: Ch01, Ch37, Ch23, Ch27; not Ch02, which is
   the football lady). The stub is chosen in the data, never by asking at runtime whether a file exists.
   When a `.glb` lands, its entry gets `"glb"` and loses `"stub"`; nothing else changes.
2. **One loader.** `scripts/cast.gd` (class `Cast`): `Cast.body(id) -> NpcBody` is the only way any view
   makes a person: the world's body (`scripts/avatar.gd`), the menu's portrait and Character row
   (`scripts/menu/portrait.gd` `show_cast(id)`), and the counter attendants
   (`scripts/attendants/attendant.gd` via `Cast.attendant_body`). The talk camera frames the attendant's
   body, so it gets the loader's body too; TALK's camera and lights are untouched. The body is an
   `NpcBody` (the shoppers' clips through `NpcRig`), meta `"cast"` = its id, idle from its first frame.
3. **One saved record**: `localStorage["mall-player-2"] = {"v": 2, "cast": "<id>", "view": "first"|"third"}`
   (Engine metadata off the web). The name stays where it was, `mall.player_name`, and the money in
   `mall.money` (`scripts/inventory.gd`, `scripts/bank.gd`): the arcade pages read both
   (`play/lib/mallbank.js`), so they are not copied into the record (a second copy would be a second
   record). **Decided at integration (Nov 9 2026): name and money stay in their own keys.** On the first run `Cast.migrate()` reads the old `mall-avatar-1` and `mall-avatar-preset-1`
   once, for the name only (only the preset ever had one), sets `mall.player_name` if it is empty, and
   deletes both, and the owner's old `mall-char-*` edits.
4. **No fallback body.** The cast's files ship **in every wing pack** (`tools/make_presets.py`
   `cast_files()`: the stub skins, and `cast/*` for CHAR-BUILD's files; wing 3 2026, which shipped no skins,
   now ships the four) and are warmed behind the loading card with the shoppers (`npc_warmup.gd`
   `skin_paths()` adds `Cast.paths()`). `avatar.gd` makes the body at `_ready`, before the first frame.
   A missing file: `Cast.body` returns null and logs an error; the person is not shown (the camera, the view
   and the held item still work). The "later" character packs that the page fetched once the mall was
   running (`chars`, `chars_<map>`, `char_pack.gd`, `window.__mallLater`) are deleted; nothing about a
   person arrives after the card lifts.
5. **The counting test**: `tools/qa/cast_count_test.gd` (below).

Attendants: `data/story/attendants.json` and the Cuco's bartender (`data/story/cucos/cucos.json`) say
`"look": "mixamo"` (their Mixamo `skin`) until each has a cast member; then `"look": "cast", "cast": "<id>"`.
Any other `look` is an error (no attendant). The crowd stays Mixamo, made by `npcs.gd` as before.

## Files
| File | What |
|---|---|
| `data/cast.json` | The cast (PLACEHOLDER until Steven describes it and CHAR-BUILD bakes it). |
| `scripts/cast.gd` | `Cast`: roster, `body(id)`, `attendant_body(entry)`, the player's record, `migrate()`. |
| `scripts/avatar.gd` | The player's body (`choose(id)` remakes it), first / third person, the boom camera, gaits, the held item. Group `mall_player_body`. |
| `scripts/menu/portrait.gd` | A cast member on a small lit stage (`show_cast(id)`); turning on MAIN, still in the row. |
| `scripts/menu/menu.gd` | MAIN: portrait, NAME (tap to type), MONEY, TICKETS, the **Character row**, View, Jump to. |
| `tools/qa/cast_count_test.gd` | The counting test. |

Deleted: `scripts/chars/*` (with `char_pack.gd`: the cast does not ship as a pack), `char_body.gd`,
`avatar_creator.*`, `avatar_look.gd`, `avatar_body.gd`, `avatar_bodies.json`, `avatar_recolor.gdshader`,
`spatial_char_region.gdshader`, `data/characters/`, `models/ubc/` (54 MB), `models/characters/`,
`tools/blender/ubc/`, `tools/blender/characters/` except `mh.py` and `fetch_mh.sh` (kept for CHAR-BUILD),
`tools/avatar/`, `tools/chars/`, and the editor's QA tools (`char_*_test.gd`, `char_*` shots,
`char_webtest.js`, `avatar_sheet.gd`, `ubc_sheet.gd`).

## The Character row (menu MAIN)
Under NAME / MONEY / TICKETS: the word CHARACTER and one button per cast member (`data/cast.json`
`"player"`, 3-4), each a still portrait (the loader's body, idle, facing out) with the name under it; the
current one has an amber border. Tap, click, or d-pad + A. Picking one saves `mall-player-2`, makes the world's
body anew through the loader (the old one leaves the tree in the same call: never two), and rebuilds MAIN so
the big portrait shows the same id. Buttons are 64-120 px wide (phone-tappable at 390 px). Nothing is written
on the game screen. C (and a gamepad's Start) opens the menu on MAIN; there is no Avatar button.

## Third person
| | Keyboard / mouse | Gamepad | Touch |
|---|---|---|---|
| First / third person | **V** | right-stick click | MAIN: **View** |
| The Character row | **C** (MAIN) | Start (MAIN) | the menu icon, MAIN |

Saved in `mall-player-2` (`view`). `?view=third|first` sets it for one load (tests).

- **The body** stands at the player's position, turns (smoothly) to the way it walks, keeps its
  facing when still. It is an `NpcBody`, so it plays the shoppers' clips through the same `NpcRig`
  retargeting.
- **Walking pace** (workstream WALK, Nov 3 2026; Steven: "in third person the avatar walks slower than
  first person, it needs a faster cadence, and the run about 50 % faster"): third person walks at
  **3.0 m/s** at full stick (first person stays 4.0, untouched: `player.move_scale` is 1.0 there);
  running (X / Shift / the right mouse button, ×2.2) is **6.6 m/s**. V had 2.0 / 4.4 (a guess: "4 m/s is
  a jog"). Touch keeps the 46 px full stick and the 0.05 deadzone; a gamepad's full stick is 3.0.
- **Gaits** (WALK retune): walk below 3.4 m/s (`walk_m` / `walk_f` by the cast member's `sex` in `data/cast.json`),
  jog to 4.6, run to 6.0, sprint above, with 0.25 m/s of hysteresis (V: 2.4 / 3.6 / 5.4; a plain speed
  change alone would have made the full-stick walk a jog). **Playback = ground speed / the clip's own
  speed** from `npc/anims.json`: `walk_m` 1.616 m/s, `walk_f` 1.623, `jog` 2.512, `run` 4.555, `sprint`
  5.973 (the 1.765 m/s in the brief was the retired Demo 36 clip, still in `npc/skins.json`
  `walk_mps`), capped at ×2.0 (`GAIT_MAX`). So a full-stick walk plays `walk_m` at **×1.86** (a brisk
  walk: the walk clip's pose and arm swing at a quicker cadence, ~3.6 steps/s, the feet matching the
  ground) and a full run plays `sprint` at **×1.10**; a half stick while running (3.3 m/s) is `walk` at
  ×2.0 just under the jog threshold, then `jog` ×1.35-1.8 and `run` ×1.0-1.3 across the stick. A body
  without a clip falls to the next gait down (not to a sliding walk). The tests check the playback
  against the measured speed, walking and running.
- **Idle** (`idle`) when the ground speed drops under 0.15 m/s.
- **The camera** rides a boom from a pivot 1.5 m up and 0.35 m to the right, 2.4 m back along the
  view (the view pitches −60°…+29° in third person). Before every frame the boom is marched in 6 cm
  steps against **the same walk grid and obstacle list the player walks on** (walls, store fronts,
  the glass rects, columns, the arcade's machines, gondolas and counters, the benches when shown),
  with 14 cm clearance; it is pulled in at once and let out slowly (no pumping). **The pivot rides the
  player exactly** (WALK): V glided the pivot in world space at 6/s, which trailed the player by
  speed / 6 (1.1 m at the new 6.6 m/s run, so the avatar shrank into the frame and the clearance was
  tested from the wrong place); now only the shoulder offset glides, in the player's frame, when the
  camera changes side.
- **Hanging signs** are not in that list, and the lowest hang at 2.0 m (Kay-Bee's sale cards,
  2.0–2.6 m; department boards from 2.56 m). So the camera stays between 0.35 and **1.95 m**: the
  boom tilts only as far as that allows, and the view pitches on its own (looking down, the avatar
  moves up the frame rather than the camera rising). Found by looking: an earlier "rise over the
  machines" camera went through Kay-Bee's 20 % OFF card.
- **Tight spots** (an arcade aisle, a store's gondolas): the other shoulder and straight behind are
  tried too, and the side with the longest clear boom wins (a new side must be 0.4 m better, so it
  doesn't flip). The pivot glides to the new side.
- **Very close in** (boom under 0.75 m: backed against a wall) the avatar is hidden, so the view is
  never from inside its head.
- **The rest of the game** still asks the eye: interaction reach and facing (`interact.gd`), the
  prize counter's zones and closer look (`prizes.gd`, from `player.cam`), an arcade cabinet's Play
  (`signs.gd`, patched), the seam and door prompts. The floor reflection and the Runner's "seen"
  test use the view camera, as they should.
- **Frozen moments** (the prize counter's closer look, the menu) hide the avatar and leave the
  camera to whoever froze the player; the third-person camera takes over again after.

**The held item** (B+C `interact.gd` `hand_item`) moves into the avatar's right hand in third person
(a holder on the RightHand bone, the item's own Grip, a fixed turn onto the hand), and back to the
first-person hand in first person. The swing's turn is copied onto it. The fuzzy dice hang from the
fist (`wsV-tp-hand-unbaked.jpg`).

## Phones
- The Character row's buttons are at least 64 px wide and ~100 px tall on a 390 px-wide phone; MAIN's
  portrait takes the top 40 % of a tall screen.
- **Cost:** the player's body is one Mixamo skin (5.8k-10.5k triangles, 1-3 draw calls) while the cast is
  stubbed; the menu adds up to five small SubViewports while it is open (the game behind it is frozen).
  The 22-26k-triangle UBC bodies are gone. CHAR-BUILD's budget: a talk-close person 15k tris, 2-3 draw calls.

## VR (design/godot-vr.md)
Always first person in VR: the avatar is hidden and its camera never made current while `vr_on`;
V / the View button do nothing; the buttons hide. Leaving VR restores the saved view. The flat
`player.cam` that VR hands back to is untouched.

## The counting test (rule 5)
`tools/qa/cast_count_test.gd`, native under xvfb, unbaked: plants both old records, loads wing 6, then
counts after: the load, menu open / close twice, a pick in the Character row (by the row's own button), a
reload, a **wing crossing** (`player._go_to_wing(4, ...)`, the game's own path), a **year crossing**
(wing 4 2026) and a **time-travel trip** back to 1995 (`timetravel_trip.gd`). Each time: exactly one
`Skeleton3D` under the player group (`mall_player` + `mall_player_body`), it is the avatar's body, its
`cast` meta is the saved id, MAIN's portrait shows the same id. A per-frame watcher counts all the way
through, crossings included; a last step loads wing 1. **Not counted:** the story NPCs, which the story
machinery hangs under the Player node (Player > Story: counter attendants, the Cuco's patrons), and the
menu's portrait stages while it is open (the closed menu frees them). The web half is
`tools/qa/avatar_webtest.py` (`?debug=1` prints `CASTCOUNT` / `CASTPORTRAIT`). Results (CAST COUNT OK 48,
AVATAR WEB OK 27): `production/qa/evidence/wsSTRIP-count-test.md`.

## Not done / open (for Steven)
- **Who the cast is.** Four PLACEHOLDER members on crowd skins **for this demo** (decided Nov 9); Steven
  defines the cast later. The crowd also wears these skins, so a shopper can look like the player until then.
- `scripts/cast.gd` meets CHAR-BUILD's loader at integration: CHAR-BUILD's loader, this branch's
  placeholder data (`data/cast.json`).
- The UBC eye code in TALK's `npc_look.gd` / `talk_camera.json` "eyes_ubc" no longer finds a UBC body (none
  left); left for TALK / CHAR-BUILD to replace with the cast's eye bones.
- First person stays the default for a new player (as since ws/items).
- The arm swing doesn't hold the item differently; in a crowd the body can pass through a shopper.
