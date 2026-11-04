# The character editor, presets and the player's avatar creator (Godot mall, workstream B2, Nov 2 2026)

**Asked for (Steven, Nov 2):** the character editor in Godot, driven by B1's bodies, shape keys, hair
and outfits (`design/godot-characters.md`): character **presets as data** and a loader that dresses a
B1 body on the NPC rig; the counter attendants on presets instead of Mixamo skins; an **owner-mode
NPC editor** (turntable preview, BODY / SKIN / HAIR / OUTFIT / NAME, Save + download);
the **player's avatar creator** as the same editor in the menu's AVATAR tab; baking for NPCs; per-map
packs. **Ground rule: machinery only.** No characters, names or story: the three attendant presets are
**PLACEHOLDER** test data (`"name": "PLACEHOLDER"`).

> **B-FIX (Steven, Nov 2, final): every character is clothed at all times.** The rule, its enforcement
> and its test are in `design/godot-characters.md` "THE CLOTHED RULE"; it replaces the base-layer rule B2
> shipped. This note is edited to match: no BASE tab, no A-pose view, no "none" in the top or bottom slot,
> no base-layer pieces, "Basics only" instead of "Strip to base", and children (youth > 0) get plain
> pieces only. The live branch is **`ws/chars-live`** (from `main`, character files only); B2's hooks into
> the shared files below are saved as `design/chars-live-hooks.patch` (`git diff 2552ce2 ws/b2-editor`),
> to be applied after Demo 49 once Q and M are merged.

## CHAR-EDITOR (Steven's notes, Nov 4 2026; branch `ws/char-editor` from `int-51` 4d09e18)

Asked for: (1) the "default bald avatar with the new one on top" bug; (2) hair that fits every body,
checked by looking at a grid; (3) a tighter creator flow and more body contours than one slider;
(4) five looks to perfect first (a proposal); (5) research on the pipeline
(`design/research/character-pipeline-2026-11.md`, no rebuild).

### 1. The one-body bug
- **Cause.** Two avatars were drawn from two systems. The menu's MAIN tab (where Done / Back lands)
  showed `scripts/menu/portrait.gd`, which always built **V's `AvatarBody` in V's look** (`Ch01`, bald, by
  default), never the B2 preset the player had just saved. So after saving, MAIN showed the bald default,
  while the editor's preview and the mall showed the new one. Two more defects on the same path:
  `AvatarChar.wear_look()` remade the skin without forgetting the old clip, so the new body stood in its
  **T-pose** until it walked (`play("idle")` skipped the clip "already playing"); and re-dressing freed a
  held item that hung on the old skeleton's hand.
- **Fix.** The portrait is the same body the mall shows (an `AvatarChar` wearing the player's preset when
  the pack ships the bodies, else V's body); `wear_look()` resets the clip and plays idle; `avatar.gd
  _wear_body()` moves a held item back to the first-person hand before re-dressing (`_hand_sync` returns
  it). The editor's **Save** re-dresses the avatar at once (`saved` signal → `avatar._preset_saved`).
- **Test** `tools/qa/char_avatar_test.gd` (native, unbaked; wing 6 by default: the shared cloud box
  ran out of memory on wing 1): exactly one avatar body in the world (and one skeleton under it), the
  saved hair worn, after: start, Save, Back, the menu closing, a reload, the year change (wing 6 2026)
  and a time-travel trip (`timetravel_trip.gd`). `--late=1` starts on V's body and mounts the character
  pack afterwards, as the web does. **CHAR AVATAR OK (40 checks)**, `--late=1` **(41 checks)**.
  Not run on the web build this session (no export: the box was shared by four sessions).

### 2. Hair fit (`scripts/chars/char_fit.gd`, `class_name CharFit`)
Looked at in `tools/qa/char_hair_grid.gd`: every hair (11) on every adult body (female: the six shape
presets + heavy-set 52 + skinny 74; male: the four + the same two extremes), front and 3/4, the idle pose.
**Found (before):**
- Long, shoulder and perm curtains **rigid on the Head bone**: in the idle pose (head tilted down) the
  front edges stood out as flaps beside the face and the back swung into the shoulders.
- Curtains and braids **inside the shoulders, upper back and shirt** on the broader / heavier bodies
  (up to 3.3 cm inside on the neutral body): their blend shapes come from the 8 nearest head / neck
  vertices, which don't move with the shoulders or chest sliders.
- **Puffs** had see-through gaps (back faces culled); every curtain's inside showed the background.
- (Not hair, seen on the way: a sawtooth fringe where the tee's collar meets the neck on every body; the
  neutral male reads young and androgynous; Big & Tall's grid cells were mis-framed by the test.)

**Fixes (runtime, on every body, every slider change; baked into NPCs and the avatar):**
1. **Skinning below the jaw:** hair under the Head joint takes the weights of the skin it lies on
   (neck, shoulders, back, chest and the little arm weight the shoulder blades carry; never skin that is
   mostly arm), blended in over 7 cm. The curtain moves like the shirt under it.
2. **Radial fit:** below the jaw, around the body's axis (Neck → Spine1), every hair vertex keeps at least
   the outermost radius of the torso skin **and the clothes as they hang** + 6 mm (+ up to 18 mm more
   behind the shoulder blades, because the fit is made in the bind pose and the clips' arms hang lower).
   Above the jaw the scalp shells keep 1.5 mm over the head (short styles are thin by design).
   The push is smoothed over the mesh's edges.
3. **B1's pieces use NORMALIZED blend shapes** (absolute targets), so the push goes into every target too
   (without that a heavy body's weights scaled the fix away: the first version did nothing on heavy-set).
4. **Hair is drawn double-sided** (the region shader with `cull_disabled`, made from its code).
Cost: one hair against ~10k obstacle vertices, tens of ms per change (not measured on a phone).
**Grids:** `production/qa/evidence/chars-hair-before-<sex>-<front|34>.jpg` and
`chars-hair-after-<sex>-<front|34>.jpg` (rows: balding, bowl, braids, crew, elderly, fade, long, perm,
puffs, shoulder, sidepart; columns: the bodies listed above). Close-ups (front, 3/4, side, back):
`chars-hair-closeup-before.jpg`, `chars-hair-closeup-after.jpg`.
**Still visible:** on the heaviest body the back of the upper arms shows through the sides of a long
curtain in the idle pose (arms are not obstacles: a curtain can't follow an arm swing); shells still read
as helmets (perm most); braids are tubes. Those are generator work: proxy binding and hair cards
(`design/research/character-pipeline-2026-11.md`).

### 3. The creator flow (player mode)
Was: BODY · SKIN · HAIR · OUTFIT, nine view buttons, 4 sliders until "Advanced: on", Advanced / Reset /
**Done** (Done was the only save, and closing the menu also saved). Now:
- **Three tabs: BODY · SKIN & HAIR · OUTFIT.** BODY starts with **Female / Male** (no Advanced needed),
  then "Start from a shape" (the shape presets), then the **contours** in groups: OVERALL (height, build,
  muscle, age), TORSO (shoulders, chest or bust, waist, belly), HIPS AND LEGS (hips, seat, thighs,
  calves), ARMS, NECK, HEAD (arms, neck length, head size). "▸ More sliders" opens face, proportions,
  posture, bust lift and youth in place. (Every one is a B1 slider the rig already supports.)
- **View row:** ⟲ ⟳ Front Back Face/Body (drag / pinch the preview still turns and zooms it).
- **Footer: ◀ Back · Reset · Save.** Save is amber while there is something to save ("Saved ✓" after);
  Save keeps you in the editor and the avatar, the portrait and the mall change at once. Back leaves
  without saving (asks once if there are unsaved changes); on a first visit with nothing saved it is the
  old Skip. Closing the menu (× / Esc) still keeps what was made (as before).
- Owner mode is unchanged except the slider names ("build", "seat", "thighs" …) and Save's colour.
Screens: `production/qa/evidence/chars-creator-*.jpg` (desk: body, more sliders, skin & hair, outfit,
saved; phone: body, skin & hair; MAIN before / after a save; the avatar in third person after a reload,
in 2026 and after time travel).

### 4. The first five (a proposal for Steven: looks, not characters)
Combinations of what exists, chosen to cover both bodies, every hair problem and the layering; no names,
no story (`tools/qa/fixtures/char_first_five.json`, sheet `production/qa/evidence/chars-first-five.jpg`
by `tools/qa/char_first_five.gd`):
1. The Pocket Change attendant preset: curvy female, shoulder-length curtain over the bust, polo + store
   vest, slacks, watch. (Shows: the shoulder curtain still reads as a helmet with flaps.)
2. The Sound Shop preset: slim male, side part under a backward cap, tee under an open flannel, jeans.
   (Shows: cap over hair; flannel fronts hang straight.)
3. The Kay-Bee preset: plus female, puffs, tee + store apron, khakis, glasses. (Shows: the apron reads
   as a flat board.)
4. The player's female default: neutral body, long straight hair, teal tee, jeans.
5. The player's male default on Big & Tall: crew cut, burgundy sweatshirt, khakis. (Shows: the
   sweatshirt's cuffs and collar show a light sawtooth trim.)
Perfecting them means: hair cards for 1, 3, 4; the collar / cuff seams; the apron's drape; faces (the
neutral male reads young).

### 5. NPCs on the same bodies (note)
The machinery is already shared: `CharPreset.body_for(preset, bake=true)` makes any NPC body, and
`scripts/npcs.json` `"presets": {"<Mixamo skin id>": "<preset id>"}` swaps a shopper's skin for a baked
preset body (empty today). The hair fit and skinning above run inside `CharBody.apply`, so NPCs get them
at bake time with no extra work. What NPCs need before the crowd moves over: a per-NPC cost check on a
phone (`tools/qa/char_perf.gd`, still not run), a few dozen presets (Steven's casting), and LODs.

### Shared files touched (CHAR-EDITOR)
`scripts/char_body.gd` (2 hooks: `CharFit.fit_hair`; hair double-sided), `scripts/avatar.gd`
(`_preset_saved`, held item on re-dress, the `qa_late_chars` test hook), `scripts/menu/menu.gd`
(connects `saved`, 2 lines), `scripts/menu/portrait.gd`, `scripts/chars/avatar_char.gd`,
`scripts/chars/char_editor.gd`, `scripts/chars/char_pack.gd` (test hook). New: `scripts/chars/char_fit.gd`,
`tools/qa/char_avatar_test.gd`, `tools/qa/char_hair_grid.gd`, `tools/qa/char_first_five.gd`,
`tools/qa/fixtures/char_first_five.json`. No scene, layout or bake change: **no rebake**.

Branch `ws/b2-editor` (history; superseded by `ws/chars-live`), from `ws/b1-bodies`, with `ws/m-menu` (the menu, AVATAR tab) and `ws/q-dialogue`
(the attendants) merged in, because both are unmerged and B2 builds on both (merge commits
`c2644d1`, `2552ce2`; the three small conflicts, all "keep both", are described under "Merging").

## Files
| File | What |
|---|---|
| `data/characters/<id>.json` | One preset per file (schema below). Today: `pocket_change`, `sound_shop`, `kay_bee` (PLACEHOLDER). |
| `data/characters/_wardrobe.json` | What the player's creator offers (shipped in every pack). Not a preset (leading `_`). |
| `scripts/chars/char_preset.gd` | `class_name CharPreset`: schema, `normalize()` (the clothed and child rules), `dress()`, `bake()`, `body_for()`, save / download / localStorage. |
| `scripts/chars/char_editor.gd` | The editor (CanvasLayer 47): owner and player modes, turntable, rows, input. |
| `scripts/chars/char_owner.gd` | The owner's way in (K / left-stick click / touch button near an NPC with a preset). Made by `player.gd`. |
| `scripts/chars/avatar_char.gd` | `class_name AvatarChar extends CharBody`: the player's avatar body from their preset (third person). |
| `tools/chars/pack_list.py` | Which character files each wing / year pack ships; `--write` puts them in `export_presets.cfg`. |
| `tools/blender/characters/patch_apron.py` | Stopgap fix of the store apron's stray panel in the shipped .glb (see "Apron"). |
| `tools/qa/char_editor_test.gd` | Native: the rules (unit), the attendants, the editor on every tab (desktop + phone), an edit saved, the menu's AVATAR tab, third person. |
| `tools/qa/char_perf.gd` | Frame cost: one / ten preset bodies (live, baked) vs Mixamo NPCs. |

Shared files, small hunks marked `B2`:
- `scripts/char_body.gd` (B1): the **clothed rule** (B-FIX: `CLOSED_TOPS`, `BOTTOMS`, `FULL_OUTFITS`,
  `CHILD_ALLOW`, `ensure_clothed()`, `is_clothed()`; B2's base-top rule is gone),
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
- `export_presets.cfg` (CHARS): every wing preset excludes the character models and maps; the presets
  "Shared Desktop" / "Shared Mobile" export the character packs (`tools/make_presets.py`, `tools/shared_packs.py`).
- `tools/blender/characters/loose.py` (B1): `apron_part` missed-ray fix.
- `design/godot-characters.md` (B1): THE CLOTHED RULE (B-FIX) at its top.

## Preset schema (`data/characters/<id>.json`)
```json
{
  "id": "pocket_change", "name": "PLACEHOLDER", "version": 1,
  "body": "female",                         // female | male
  "keys": {"weight": 0.1, "bust": 0.5},     // B1 sliders (characters.json "sliders"), missing = 0
  "skin": "#d7a98a", "iris": "#5a3a22",
  "hair": {"id": "hair_shoulder", "color": "#4a3020"},   // "" = no hair
  "outfit": {
    "under": "", "top": "top_polo", "bottom": "bot_slacks", "full": "",
    "outer": "full_storevest", "shoes": "shoe_sneakers",
    "extras": ["x_watch"],                                   // hat, glasses, watch
    "colors": {"top_polo": {"main": "#f2f2f0"}},             // per piece, per colour region
    "patterns": {"bot_longshorts": "stripes"}                // pieces with patterns (the jams)
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

### The clothed rule (B-FIX, Steven, Nov 2, final), enforced in the loader
- Every preset, adult or child, wears a closed top and a bottom, or a full outfit; a missing one gets
  the default (`top_tee`, `bot_jeans`, or the next one the pack ships). Base-layer ids in a file are dropped.
- A child preset (`youth > 0` or `youth_small > 0`) keeps only `CharBody.CHILD_ALLOW` pieces; its bust
  keys are dropped.
- Enforced in `CharPreset.normalize()` and again in `CharBody` (see `design/godot-characters.md`), never
  only in the UI. **Basics only** (was "Strip to base") leaves the top and bottom (or the full outfit) and hair.
- The two PLACEHOLDER attendants that had a small `youth` value ("younger": `pocket_change` 0.15,
  `sound_shop` 0.25) are set to 0, since any youth above 0 now makes a child's body; they are adult staff.

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
  a grey stage disc, **white or dark backdrop**, the idle clip (no A-pose view: B-FIX).
  Spins by itself; drag (mouse / touch), the right stick, `,` `.` or ⟲ ⟳ rotate (spin pauses 4 s);
  wheel, pinch, `-` `=` or − + zoom from the whole body to the face; **Front / Side / Back**.
  Pieces change while it spins. **In place / Turntable**: in place hides the turntable and edits the
  NPC itself where it stands (live, unbaked) through a camera that orbits it; back on the turntable,
  the NPC goes back to its saved look until Save.
- **Tabs:** BODY (Female / Male; the **shape presets** first: Straight / Curvy × Petite / Missy / Plus,
  or Slim / Regular / Athletic / Big & Tall; then every slider, grouped OVERALL / TORSO / LIMBS / HEAD /
  FACE; a shape preset sets the body and keeps head, face, age and posture), SKIN (the ten tones, eyes,
  age), HAIR (style, colour), OUTFIT
  (**Basics only**, Dress as opened, then each slot: piece, each colour region; no "none" in Top or
  Bottom, "none (top + bottom)" in Full outfit; patterns on pieces that have them
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
5. Nothing to run for the packs: `tools/export_web.sh` ships every piece the committed presets wear
   (`python3 tools/chars/pack_list.py` shows where each one lands).
A **new** NPC preset: copy an existing file to `data/characters/<new_id>.json`, point an attendant's
`"preset"` (or `npcs.json` `"presets"`) at it, then edit it in the game.

## The player's avatar creator (menu → AVATAR)
The same editor in player mode replaces V's creator inside M's AVATAR tab (same contract: `frame`,
`embedded`, `feed()`, `sel`, `closed`), under M's NAME field (`mall.player_name`, unchanged).
- **Default view:** BODY (female / male hidden until Advanced; shape presets; height, weight, muscle,
  age), SKIN, HAIR, OUTFIT. **Advanced: on** shows every slider and the body choice.
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

## Packs (CHARS, Nov 3 2026: `tools/chars/pack_list.py`, `tools/shared_packs.py`)
The wing packs ship **no** character models or maps (only `characters.json`). B2's plan was one
character pack per map (`chars_<map>`, ~42–48 MB each, 12 maps × 2 kinds ≈ 1 GB on top of the build,
more than a whole Pages site holds). Instead the character files are **shared packs**
(`design/godot-build-hosting.md` "Shared packs"):
- **`chars`**: what every map needs: both bodies, the clothed defaults, the player's wardrobe
  (`data/characters/_wardrobe.json`) and every map those pieces use. Downloaded once for the whole mall.
- **`chars_<map>`**: only the pieces that map's presets wear beyond `chars` (exported only for maps that
  have any). Today `chars_w1` (Kay-Bee, Sound Shop: `full_storeapron_female`, `x_cap_back_male`) and
  `chars_w2` (Pocket Change: `bot_slacks_female`, `full_storevest_female`, `x_watch_female`).
- Nothing else from `models/characters/` ships (no unused hair, pieces or the `_hi` bodies).
- `python3 tools/chars/pack_list.py` prints, per map, the presets and files, and the split.
- On the web the page fetches `chars` + the map's `chars_<map>` after the loading card lifts and
  `scripts/chars/char_pack.gd` mounts them; until then the attendants wear their Mixamo fallback (clothed)
  and the avatar is V's body; the owner's "Edit character" button waits for the preset body.

Sizes are measured in `design/godot-build-hosting.md` "Shared packs".

## How to add an attendant (after CHARS; the steps round 2's store sessions follow)
Only when Steven asks for that attendant (no session invents a character, name or line). Test data
is marked PLACEHOLDER.
1. **The preset:** copy an existing preset to `prototypes/godot-mall/project/data/characters/<id>.json`
   (e.g. `sound_shop.json`), set `"id": "<id>"`, `"name": "PLACEHOLDER"` (or the name Steven gives),
   and the body / pieces / colours Steven asks for (piece ids: `models/characters/characters.json`
   "pieces" `base_id`). The clothed rule applies on load (a closed top and a bottom, or a full outfit).
2. **The attendant:** add an entry to `data/story/attendants.json` "attendants": `id`, `store`, `wing`,
   `years`, `area` `[x0, z0, x1, z1]` (behind the counter), `face`, `talk_at`, `dialogue` (a PLACEHOLDER
   `.dialogue` file unless Steven wrote one), `name`, plus the Mixamo fallback `skin` / `sex`, and
   **`"look": "preset", "preset": "<id>"`**. (A shopper instead: `scripts/npcs.json` `"presets"`
   `{"<skin id>": "<id>"}`.)
3. **Check the packs:** `python3 tools/chars/pack_list.py` (run from the project folder). The new
   preset is listed under its wing and year; any piece it wears that is not in `chars` lands in that
   map's `chars_<map>`. Nothing to write by hand: `tools/export_web.sh` exports what this prints.
4. **Test natively:** `godot --headless --path . --script res://tools/qa/char_clothed_test.gd` (CHAR CLOTHED OK)
   and `... char_editor_test.gd -- --only=unit` (CHAR EDITOR OK).
5. **Test on the web:** `tools/export_web.sh .scratch/builds/<name>` (or `SHARED=1` with the wing you
   changed), serve the repo root on :8765, and run
   `node tools/qa/shared_webtest.js prototypes/godot-mall/project/.scratch/builds/<name>/index.html <out> w<n>`
   after adding the attendant's id to `DRESSED` and a camera to `CAM` in that script: it must print
   `<id> dressed from its preset` and SHARED WEB OK. Keep a screenshot in `production/qa/evidence/`.
6. Attendants are probe-lit, not baked: no rebake for the attendant itself (the counter's store may need one).

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

## Checks (Nov 3, CHARS; evidence `production/qa/evidence/wsCHARS-packs.md`)
- Native: CHAR CLOTHED OK (1608 checks), CHAR EDITOR OK (16 checks, `--only=unit`).
- Web, every map (12) on both pack kinds: the character packs mount, the three PLACEHOLDER attendants are
  dressed from their presets, the player's avatar is the preset body (third person), 0 console errors.
- Web, B2's `char_webtest.js`: K opens the owner's editor, the menu's AVATAR tab hosts the editor,
  phone portrait: CHAR WEB OK. movetest (wing 1): walks, 0 errors.

## Checks (Nov 2)
- B-FIX: `tools/qa/char_clothed_test.gd` (headless): **CHAR CLOTHED OK (1608 checks)**;
  `tools/qa/char_editor_test.gd --only=unit`: **CHAR EDITOR OK (16 checks)** (its base-rule checks replaced
  by clothed-rule ones). The B2 runs below predate B-FIX.
- `tools/qa/char_editor_test.gd --only=unit` (headless, B2): **CHAR EDITOR OK (25 checks)**: the rules in
  `normalize()` and in `CharBody`, every preset loads, bakes, keeps its size, no blend shapes
  left; save / download / forget.
- Native wing 1 (opengl3, unbaked): the attendants are baked preset bodies; K opens the editor; every
  tab at 1280×720 and 390×844; strip to base (now "Basics only"); an edit saved and worn baked by the attendant; the
  menu's AVATAR tab hosts the editor (desktop, phone); closing saves the player's preset; the avatar is
  an AvatarChar. All checks passed; the run hit its 15-min timeout after the last shot (the third-person
  shot missed the avatar: fixed in the test, not re-run).
- Native wing 2: its first run found the CharPack `ready` name clash (fixed, b05dbed); **not re-run**.
- Web (`tools/qa/char_webtest.js`, wing 1): the game loads and the attendants fall back to their
  Mixamo skins, but **the character pack did not mount** (a page error "null function", no `char_pack`
  line): open bug, below. **movetest not run.**

## Open bugs (updated Nov 3, CHARS)
- **Fixed (CHARS): web: the character pack doesn't mount.** The pack is no longer fetched by Godot
  (`HTTPRequest.download_file` into `user://`): the page fetches the shared character packs after the
  loading card lifts and copies them into the engine's file system (`web/shell.html` `mallFetchLater`),
  and `char_pack.gd` mounts them (`scripts/shared_packs.gd`). Every map mounts them with 0 console
  errors (Checks). Which of the two Nov 2 suspects caused "null function" was not isolated: the old path
  is gone.
- **Fixed (CHARS):** the owner's "Edit character" button now waits for the preset body (an attendant
  still on its Mixamo fallback is skipped, `char_owner.gd nearest()`).
- V's shirt words aren't drawn on the B1 tee.
- Perf table and the wing 2 native run still to do.

## Guesses (to confirm)
- The three attendant presets' bodies, colours and clothes: placeholders from B1's shape presets
  (no cast sheet in the repo). Pocket Change: Curvy Missy, polo, slacks, store vest. Sound Shop: Slim,
  younger, tee under an open flannel, jeans, backward cap. Kay-Bee: Straight Plus, tee, khakis, store
  apron, glasses.
- The owner key K and the left-stick click; Esc / B close; Q / E switch tabs only outside the menu.
- The player wardrobe (`_wardrobe.json`): a lean set to keep packs small.
