# The character editor, presets and the player's avatar creator (Godot mall, workstream B2, Nov 2 2026)

**Asked for (Steven, Nov 2):** the character editor in Godot, driven by B1's bodies, shape keys, hair
and outfits (`design/godot-characters.md`): character **presets as data** and a loader that dresses a
B1 body on the NPC rig; the counter attendants on presets instead of Mixamo skins; an **owner-mode
NPC editor** (turntable preview, BODY / SKIN / BASE LAYER / HAIR / OUTFIT / NAME, Save + download);
the **player's avatar creator** as the same editor in the menu's AVATAR tab; baking for NPCs; per-map
packs. **Ground rule: machinery only.** No characters, names or story: the three attendant presets are
**PLACEHOLDER** test data (`"name": "PLACEHOLDER"`).

Branch `ws/b2-editor`, from `ws/b1-bodies`, with `ws/m-menu` (the menu, AVATAR tab) and `ws/q-dialogue`
(the attendants) merged in, because both are unmerged and B2 builds on both (merge commits
`c2644d1`, `2552ce2`; the three small conflicts, all "keep both", are described under "Merging").

## Files
| File | What |
|---|---|
| `data/characters/<id>.json` | One preset per file (schema below). Today: `pocket_change`, `sound_shop`, `kay_bee` (PLACEHOLDER). |
| `data/characters/_wardrobe.json` | What the player's creator offers (shipped in every pack). Not a preset (leading `_`). |
| `scripts/chars/char_preset.gd` | `class_name CharPreset`: schema, `normalize()` (the base rule), `dress()`, `bake()`, `body_for()`, save / download / localStorage. |
| `scripts/chars/char_editor.gd` | The editor (CanvasLayer 47): owner and player modes, turntable, rows, input. |
| `scripts/chars/char_owner.gd` | The owner's way in (K / left-stick click / touch button near an NPC with a preset). Made by `player.gd`. |
| `scripts/chars/avatar_char.gd` | `class_name AvatarChar extends CharBody`: the player's avatar body from their preset (third person). |
| `tools/chars/pack_list.py` | Which character files each wing / year pack ships; `--write` puts them in `export_presets.cfg`. |
| `tools/blender/characters/patch_apron.py` | Stopgap fix of the store apron's stray panel in the shipped .glb (see "Apron"). |
| `tools/qa/char_editor_test.gd` | Native: the rules (unit), the attendants, the editor on every tab (desktop + phone), an edit saved, the menu's AVATAR tab, third person. |
| `tools/qa/char_perf.gd` | Frame cost: one / ten preset bodies (live, baked) vs Mixamo NPCs. |

Shared files, small hunks marked `B2`:
- `scripts/char_body.gd` (B1): the **base-top rule** (`BASE_DEFAULT`, `base_required()`, `ensure_base()`,
  `take_off()`), `CLASHES` (a full outfit vs top / bottom / underlayer), `wear_many()`,
  `strip_to_base()`, `make()` clears the old pieces, the piece owner warning.
- `scripts/attendants/attendant.gd` (Q): `"look": "preset"` builds the body from the preset; `preset_id()`,
  `wear_preset()`. The legacy Mixamo path is untouched and is the fallback.
- `data/story/attendants.json` (Q): `"look": "preset"`, `"preset": "<id>"` per attendant (2 lines each).
- `scripts/npcs.gd`, `scripts/npcs.json`: `"presets": {skin id: preset id}` (empty: every shopper keeps
  its Mixamo skin).
- `scripts/player.gd`: makes `CharOwner` after `Story` (4 lines).
- `scripts/avatar.gd` (V): `body` is an `AvatarChar` when the pack ships the B1 bodies, else V's
  `AvatarBody`; `_wear_body()`.
- `scripts/menu/menu.gd` (M): `_make_creator()` makes the character editor (player mode) when the pack
  ships the bodies, else V's creator; the mouse wheel goes to it.
- `export_presets.cfg`: the `models/characters/...` entries of each wing preset's `include_filter`
  (written by `tools/chars/pack_list.py --write`).
- `tools/blender/characters/loose.py` (B1): `apron_part` missed-ray fix.
- `design/godot-characters.md` (B1): the editor default now has a female base top (below).

## Preset schema (`data/characters/<id>.json`)
```json
{
  "id": "pocket_change", "name": "PLACEHOLDER", "version": 1,
  "body": "female",                         // female | male
  "keys": {"weight": 0.1, "bust": 0.5},     // B1 sliders (characters.json "sliders"), missing = 0
  "skin": "#d7a98a", "iris": "#5a3a22",
  "hair": {"id": "hair_shoulder", "color": "#4a3020"},   // "" = no hair
  "outfit": {
    "base_top": "base_sportsbra", "base_bottom": "base_briefs",   // the base layer (rule below)
    "under": "", "top": "top_polo", "bottom": "bot_slacks", "full": "",
    "outer": "full_storevest", "shoes": "shoe_sneakers",
    "extras": ["x_watch"],                                   // hat, glasses, watch
    "colors": {"top_polo": {"main": "#f2f2f0"}},             // per piece, per colour region
    "patterns": {"base_briefs": "stripes"}                   // base-layer pieces only
  },
  "shape_from": "Curvy Missy (B1)"          // optional note: the shape preset it started from
}
```
- Piece ids are B1's **base ids** (`top_tee`, not `top_tee_female`); the body's sex picks the file.
  Colour regions are the piece's `materials` in `characters.json` (`main` / `trim` / `accent`, or per
  part on uniforms); a missing colour is the piece's default.
- **Slots** (the OUTFIT tab, layer by layer): `under` (a tee, tank or baby tee worn as layer 1 under a
  top), `top` (layer 2), `bottom`, `full` (football, cheer, waitress, coveralls: replaces top, bottom and
  underlayer), `outer` (flannel, cardigan, store vest, store apron: layer 3), `shoes`, `extras`.
  An underlayer tee is worn with `slot: "under"`, `layer: 1`, so a polo over it hides its torso and gets
  its `fit_over` push-out (B1's layering, unchanged).
- `normalize()` (on every load and save) clamps sliders to their ranges and to the body (no `bust` on a
  male body), drops pieces that don't exist for the body or aren't in this pack, keeps unknown fields.

### The base-layer rule (Steven, Nov 2), enforced in the loader
- **Female presets always have a base top and a base bottom.** A preset missing either gets the default
  (`base_sportsbra`, `base_briefs`). The one-piece swimsuit counts as both.
- **Male presets always have a base bottom** (default `base_boxerbriefs`); the base top is optional.
- Enforced three times, none of them only in the UI: `CharPreset.normalize()`; `CharBody.ensure_base()`
  after every `make()` / `wear()` / `wear_many()` / `strip_to_base()`; `CharBody.take_off()` refuses a base
  bottom, a one-piece and a **female base top**. The editor offers no "none" in a required base slot.
  There is no flag, option or hidden path that removes a female base top.
- **Strip to base** leaves exactly that: female = base top + base bottom (or the one-piece), male = base
  bottom (+ the base top if one was chosen). Hair stays.
- This changes B1's editor default (B1's note said "no base top, female and male alike"); B1's note is
  updated to point here.

## Loader, NPCs and baking
- `CharPreset.dress(cb, p)`: (re)make the body if the sex differs, swap pieces to exactly the preset's,
  set the sliders (blend shapes + joint offsets + NpcRig), paint every colour. Incremental: only the
  pieces that changed are loaded.
- `CharPreset.body_for(p, bake)`: a new CharBody dressed as `p`. **NPCs are baked**: every blend shape at
  its weight (and `fit_over`) is applied into a new fixed ArrayMesh (positions + normals, bone weights
  kept), so no blend shapes run per frame. The bones keep the preset's joint offsets. Only the editor
  keeps live shapes. Bake time: **76–94 ms per attendant** at load (native).
- **Attendants** (`data/story/attendants.json`): `"look": "preset"` + `"preset": "<id>"`; `"legacy"` (or
  no `look`) = the Mixamo skin, which is also the fallback if the preset file is missing. All three are
  on presets now. The dialogue engine and the `.dialogue` files are untouched.
- **Shoppers**: `scripts/npcs.json` `"presets": {"Ch01": "some_id"}` swaps that skin for a baked preset
  body (empty today: the crowd keeps its Mixamo bodies).
- Which presets the game uses: **this browser's saved edit** (`localStorage "mall-char-<id>"`) if there
  is one, else the repo file. So Steven sees an edit in the mall at once, in his browser only.

## The owner's editor
- **Open:** owner mode on (`?owner=1`, the secret code), stand within 3 m of an NPC that wears a preset
  and press **K** (keyboard), the **left-stick click** (gamepad) or tap **Edit character (K)** (owner
  only, above the TALK prompt). Visitors never see the button; K does nothing for them.
- **Preview:** a turntable: the character alone in its own world, neutral white light (key, fill, rim),
  a grey stage disc, **white or dark backdrop**, **idle or A-pose** (B1's bind pose, the scan look).
  Spins by itself; drag (mouse / touch), the right stick, `,` `.` or ⟲ ⟳ rotate (spin pauses 4 s);
  wheel, pinch, `-` `=` or − + zoom from the whole body to the face; **Front / Side / Back**.
  Pieces change while it spins. **In place / Turntable**: in place hides the turntable and edits the
  NPC itself where it stands (live, unbaked) through a camera that orbits it; back on the turntable,
  the NPC goes back to its saved look until Save.
- **Tabs:** BODY (Female / Male; the **shape presets** first: Straight / Curvy × Petite / Missy / Plus,
  or Slim / Regular / Athletic / Big & Tall; then every slider, grouped OVERALL / TORSO / LIMBS / HEAD /
  FACE; a shape preset sets the body and keeps head, face, age and posture), SKIN (the ten tones, eyes,
  age), BASE (base top and bottom, their colours and pattern; always on), HAIR (style, colour), OUTFIT
  (**Strip to base**, Dress as opened, then each slot: piece, each colour region; patterns on base
  pieces), NAME (the name, PLACEHOLDER by default; the file it saves as; **Copy from** another preset;
  forget this browser's edit).
- **Colours:** a palette per row (the piece's default first) and **…** for fine steps (hue, saturation,
  dark / light).
- **Save** keeps the preset in this browser and puts it on the NPC (baked). **Download** gives the file.
  **Reset** goes back to how it was opened. **Close** with unsaved changes asks once.
- **Keys:** ↑↓ (W S) rows, ←→ (A D) change the value / cycle / rotate (on the view row), Enter / Space
  (on a slider: back to 0; on a colour: the fine steps), Q / E or [ ] or PgUp / PgDn tabs, Esc close.
  **Gamepad:** d-pad + A, LB / RB (or X / Y) tabs, B close, right stick rotate / zoom.
  **Touch:** tap; drag the list to scroll; drag on a slider to set it; drag / pinch the preview.
- **Phone width** (390×844): the preview takes the top 42 %, the rows scroll under it.

### How Steven saves a preset into the repo
1. In his browser (owner mode), edit the NPC, **Save** (it now looks that way in his browser).
2. **Download**: the browser saves `<id>.json` (e.g. `pocket_change.json`).
3. Put it in `prototypes/godot-mall/project/data/characters/` (replace the old one) and commit it
   (or hand it to a session: "commit this as data/characters/pocket_change.json").
4. After it is committed and published, **NAME → Forget this browser's edit** (optional): his browser then
   uses the repo file like everyone else.
5. If the preset uses a piece no other preset in that wing uses, run
   `python3 tools/chars/pack_list.py --write` before the export so the pack ships it.
A **new** NPC preset: copy an existing file to `data/characters/<new_id>.json`, point an attendant's
`"preset"` (or `npcs.json` `"presets"`) at it, then edit it in the game.

## The player's avatar creator (menu → AVATAR)
The same editor in player mode replaces V's creator inside M's AVATAR tab (same contract: `frame`,
`embedded`, `feed()`, `sel`, `closed`), under M's NAME field (`mall.player_name`, unchanged).
- **Default view:** BODY (female / male hidden until Advanced; shape presets; height, weight, muscle,
  age), SKIN, HAIR, OUTFIT. **Advanced: on** shows every slider, the body choice and the BASE tab.
- **Done** (or closing the menu) saves the preset in `localStorage "mall-avatar-preset-1"`; the avatar
  is rebuilt from it (baked) and stands in third person; a held item still goes in the right hand
  (`AvatarChar.hand` on `mixamorig_RightHand`, V's grip unchanged).
- Before a preset is saved, V's saved look becomes one (its body's sex, skin, hair colour, the year's
  top and bottom colours on a tee and jeans), so returning players keep their colours.
- **Not carried over:** V's shirt words (the Label3D on the chest) are not drawn on the B1 tee yet
  (B1 lists `shirt_words_at`; a follow-up).
- The creator offers what the pack ships: the wardrobe (`_wardrobe.json`, a lean default) plus the pieces
  of that map's presets.
- **VR** stays first person, avatar hidden (V's rule, unchanged); the editor and the owner button are
  off in VR.
- If a pack doesn't ship the B1 bodies, V's body and creator are used as before.

## Performance (`tools/qa/char_perf.gd`)
**Not measured yet** (the container restarted before the run): `tools/qa/char_perf.gd` is written
(1 and 10 bodies: Mixamo Ch22, preset live, preset baked; mean / p95 frame ms, triangles), not run.
Known numbers: a dressed preset body is **24.6k–25.9k triangles** (the three attendants) vs the
Mixamo NPCs' 0.9k–10k; baking costs **76–94 ms per body at load** (native) and leaves no blend shapes.
Expectation for an iPhone (a guess until measured): baked bodies cost what any skinned 25k-tri mesh
costs (skinning only); live blend shapes (60+) are for the editor's one preview body.

## Packs (`tools/chars/pack_list.py`)
The wing packs ship **no** character files: wing 2 (1995) is already 95.8 MB, and inlining the
characters measured **140.9 MB (wing 1) / 145.6 MB (wing 2)**. Instead each map has its own character
pack, `chars_<map>.<desktop|mobile>.pck`, with only that map's presets' bodies / hair / pieces and the
player wardrobe (`data/characters/_wardrobe.json`), exported by `tools/chars/export_chars.sh` (called
from `tools/export_web.sh`) and fetched + mounted at start by `scripts/chars/char_pack.gd`.

| Map | Wing pack before | Wing pack after | Character pack |
|---|---|---|---|
| wing 1 1995 | 92.54 MB | 92.54 MB | 48.3 MB |
| wing 2 1995 | 95.76 MB | 95.77 MB | 49.9 MB |
| outside 1995 | 31.89 MB | 31.89 MB | 48.0 MB |
| wing 1 2026 | 44.01 MB | 44.02 MB | 48.0 MB |
| wing 2 2026 | 88.40 MB | 88.40 MB | 48.0 MB |
| outside 2026 | 14.81 MB | 14.81 MB | 48.0 MB |
Every pack is under 100 MB. `models/characters/` is 77.8 MB in all; a character pack is mostly the
two bodies (9.5 + 8.9 MB imported), the skin maps and the wardrobe. The wardrobe is the size knob.

## Apron (B1's known defect)
The store apron's stray panel: at the bib's top row the outer rays pass beside the chest (the shoulder
regions aren't in the ray set), missed, fell to z ≈ 0; the push-out shoved those vertices sideways into
the armpit and they took the arm's weights (0.94 on the right arm on the male). Fixed in
`loose.apron_part` (a missed column takes its nearest hit in the row) for the next full rebuild, and the
two shipped files are patched now by `patch_apron.py` (top-row vertices more than 2 cm behind their row
are re-made from the vertex below, for the rest position and all 39–43 blend shapes, with its normal and
weights): female columns 0, 10, 11, male 0, 11. Not re-run through Blender here (no bpy in the cloud
session): the generator fix is untested until the next `garments.py` run.

## Merging
- `ws/m-menu` and `ws/q-dialogue` are merged into this branch. Conflicts: `scripts/player.gd` (Menu and
  Story both added after Avatar: both kept, Menu first), `scripts/inventory.gd` (both M's name contract
  and Q's flags kept), `export_presets.cfg` (Q's include filters with M's exclude filters).
- Merge order for the integration session: M, Q, B1, then this branch (it already contains them).

## Checks (Nov 2)
- `tools/qa/char_editor_test.gd --only=unit` (headless): **CHAR EDITOR OK (25 checks)**: the base rule in
  `normalize()` and in `CharBody` (female top + bottom, male bottom, one-piece, full outfits, strip to
  base, take_off refuses a female base top), every preset loads, bakes, keeps its size, no blend shapes
  left; save / download / forget.
- Native wing 1 (opengl3, unbaked): the attendants are baked preset bodies; K opens the editor; every
  tab at 1280×720 and 390×844; strip to base; an edit saved and worn baked by the attendant; the
  menu's AVATAR tab hosts the editor (desktop, phone); closing saves the player's preset; the avatar is
  an AvatarChar. All checks passed; the run hit its 15-min timeout after the last shot (the third-person
  shot missed the avatar: fixed in the test, not re-run).
- Native wing 2: its first run found the CharPack `ready` name clash (fixed, b05dbed); **not re-run**.
- Web (`tools/qa/char_webtest.js`, wing 1): the game loads and the attendants fall back to their
  Mixamo skins, but **the character pack did not mount** (a page error "null function", no `char_pack`
  line): open bug, below. **movetest not run.**

## Open bugs (Nov 2, for the next session)
- **Web: the character pack doesn't mount.** The build loads and plays, attendants show their Mixamo
  fallback, the console has one "null function" page error. Suspects: `HTTPRequest.download_file`
  into `user://` on the web, or `ProjectSettings.load_resource_pack` on a 48 MB file in the web FS. Next
  step: log each stage in `char_pack.gd`, try fetching through JavaScript into the FS instead.
  Until fixed, the web game keeps V's avatar and creator and the Mixamo attendants (no regression).
- The owner's "Edit character" button shows near an attendant whose preset body isn't loaded yet
  (it should wait for CharPack).
- V's shirt words aren't drawn on the B1 tee.
- Perf table, wing 2 native run, the third-person shot and movetest still to do.

## Guesses (to confirm)
- The three attendant presets' bodies, colours and clothes: placeholders from B1's shape presets
  (no cast sheet in the repo). Pocket Change: Curvy Missy, polo, slacks, store vest. Sound Shop: Slim,
  younger, tee under an open flannel, jeans, backward cap. Kay-Bee: Straight Plus, tee, khakis, store
  apron, glasses.
- The owner key K and the left-stick click; Esc / B close; Q / E switch tabs only outside the menu.
- The player wardrobe (`_wardrobe.json`): a lean set to keep packs small.
