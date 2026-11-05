# The UBC characters: Quaternius's Universal Base Characters as the game's bodies (workstream CHARS-UBC, Nov 4 2026)

**Asked for (Steven, Nov 4, 18:00, through the director):** use Quaternius's Universal Base Characters
(Standard, free, **CC0**) for the five main characters and for the character editor. The free kit has
only the two Superhero bodies (very muscular): reshape them in Blender into the needed builds as shape
keys driven by the editor's contour sliders; use the six free hairstyles (+ eyebrows); model the outfits
for the five looks; switch the editor and the presets to the new bodies, keeping the MakeHuman (B1)
bodies behind a flag until Steven signs off. Approved with it: the five looks, the rebuild, a face pass
for the male, "closing the menu keeps changes" (`design/godot-character-editor.md` CHAR-EDITOR).
Branch `ws/chars-ubc` from `ws/char-editor` 80deb4f9.

Source: `/home/claude/assets/New Character Templates 11.4/Universal Base Characters[Standard]/` (outside
the repo). The repo ships only what the game uses: `models/ubc/` (converted glTF + .bin, the textures it
needs, **`LICENSE-UBC.txt`**: the kit's CC0 text and the credit "Quaternius, https://quaternius.com").
54 MB.

## Rebuild (headless, from the Godot project folder; one Blender / Godot at a time)
```bash
B=/path/to/python-with-bpy            # pip install bpy (5.2.x, Python 3.13)
$B tools/blender/ubc/build_body.py male female          # bodies -> models/ubc/body_<sex>.gltf (+ .scratch/ubc/*.blend)
$B tools/blender/ubc/build_pieces.py hair garments      # hair, beard, garments -> models/ubc/<piece>_<sex>.gltf, pieces.json
GODOT=godot tools/blender/ubc/reimport.sh               # forces the reimport (Godot hashes the .gltf, not its .bin) + the manifest
```
`tools/chars/ubc_manifest.gd` writes `models/ubc/ubc.json` in the shape of B1's `characters.json`, so
`CharBody`, `CharPreset`, `CharFit` and the editor run on either set.

## 1. The rig: our clips play unchanged
- The kit's skeleton is UE-mannequin style (`pelvis`, `spine_01..03`, `clavicle_l`, `upperarm_l`, ...,
  65 bones). **Renamed to our Mixamo names** in Blender (`ubc_common.mixamo_name`: `pelvis` → `mixamorig_Hips`,
  `spine_01/02/03` → `Spine/Spine1/Spine2`, `clavicle` → `Shoulder`, `upperarm` → `Arm`, `lowerarm` →
  `ForeArm`, fingers `index_01..04` → `HandIndex1..4`, `thigh/calf/foot/ball/ball_leaf` →
  `UpLeg/Leg/Foot/ToeBase/Toe_End`), and the kit's `root` bone removed (its weights go to the hips) so the
  hips are the root as in Mixamo. Every clip bone exists except `HeadTop_End` (unused by the clips' motion).
- The kit's rest is already a **T-pose** like Ch01's, so no re-posing: `NpcRig` retargets the different
  bone rolls (64 fix-ups, as it does for every Mixamo skin) and every clip in `npc/anims.res` plays.
- `NpcBody.set_skin` roots the AnimationPlayer at the skeleton's parent when the skeleton is one node down
  (Blender's glTF puts it at `Armature/Skeleton3D`); Mixamo skins and B1 bodies are unchanged.
- Glitch found and fixed: glTF splits vertices at UV seams; unmerged, every smoothing opened cracks along
  the seams (white lines down the legs). The import merges them.

## 2. Builds (shape keys) and the face pass
- **The default is toned down** (Steven: a normal default): the torso and limbs are Laplacian-smoothed with
  the broad shrink given back along the normals (90 % male, 75 % female), the normal map's broad forms
  (the painted-in abs and pecs) kept at 25 / 40 %, the albedo's painted shading at 45 / 60 %.
  `muscle+` brings the kit's superhero sculpt back; `muscle-` smooths further.
- Shape keys (each `<slider>+` / `-`), all driven by the editor's contour sliders: **height** (legs and
  torso, the head keeps its size), **weight** (build: soft volume at belly, hips, thighs, arms, neck /
  lean), **muscle**, **shoulders**, **chest**, **bust** (female), **waist**, **belly**, **hips**, **butt**
  (seat), **thigh**, **calf**, **arms**, **neck_length**, **head_size**; the face pass: **jaw**, **chin**.
  No age or youth sliders: the UBC set has **no child bodies** (CharBody drops a slider key its manifest
  doesn't have, so a youth key can't make one).
- Joints follow the flesh for the structural shapes (height, shoulders, neck length): measured per bone as
  the mean displacement of the skin around the joint (`ubc_manifest.gd`), so a tall body's knees and hips
  are where its legs bend.
- Shape presets: female **Slim / Average / Curvy / Plus**, male **Slim / Average / Athletic / Big & Tall**
  (+ QA extremes heavy-set 52, skinny 74).
- **The male face** reads as an adult man as the kit made it (strong brow and jaw), unlike the MakeHuman
  male; the face pass adds jaw width and chin length sliders. No further face sculpt was needed for the
  look; Steven to say.
- Skin: the kit's light texture divided by its own mean skin colour (near-white, so the material tint is
  the tone, as on B1); its painted underwear stays dark fabric, and the region shader's base layer paints
  chest, pelvis and crotch as fabric too (the clothed rule: nothing bare even in a bug). Eyes greyed (the
  iris tint), eyebrows greyed (the hair tint). Region ids per vertex in the second UV map.
- Evidence: `production/qa/evidence/chars-ubc-builds-unbaked.jpg` (the builds in the default tee and
  jeans, front and side, idle pose through NpcRig).

## 3. Hair
- The kit's **six** styles: **Long** (shoulder length), **Buns**, **BuzzedFemale** (short crop), **Buzzed**,
  **SimpleParted** (side part), and **Beard** (male only, an extra slot "beard"); eyebrows are on the bodies.
- Each was modelled on one kit head (Long, Buns, BuzzedFemale on the female; Buzzed, SimpleParted, Beard
  on the male). On the other body it is moved and scaled from that head onto this one (the head boxes),
  then **proxy-bound**: every hair vertex is a point on a body triangle plus an offset along its normal
  (MakeHuman's method, `ubc_common.Binding`), evaluated for every shape key, so hair follows every build,
  head size and neck length exactly; nothing sits inside the scalp (2 mm). Rigid on the Head; at load
  `scripts/chars/char_fit.gd` (CHAR-EDITOR) skins anything below the jaw onto the torso and keeps it clear
  of the shirt. Hair cards are drawn alpha-scissored and double-sided.
- **The five looks' hair** (B1 ids alias to the closest UBC style in `CharPreset.normalize`):
  shoulder → **Long**; puffs → **Buns** (closest; not puffs); crew → **Buzzed**; side part →
  **SimpleParted**; long straight → **Long** (shoulder length: **no long-straight style in the free kit**).
  No match in the free kit for: perm, braids, puffs proper, bowl, balding, elderly set, long straight
  (each aliased to the nearest: see `tools/blender/ubc/build_pieces.py` `ALIASES`).
- Evidence: `chars-ubc-hair-female-unbaked.jpg`, `chars-ubc-hair-male-unbaked.jpg` (every style on every
  build, front and 3/4: rows Buns, Buzzed, BuzzedFemale, Long, SimpleParted; columns Slim, Average,
  Curvy / Athletic, Plus / Big & Tall, heavy-set, skinny).

## 4. Outfits for the five looks
`tools/blender/ubc/garments_ubc.py`, both bodies: **tee, polo, sweatshirt, open flannel, store vest
(blank name tag), store apron (bib + skirt panel, blank tag), jeans, khakis, slacks, sneakers, watch,
backward cap, glasses**. Surface garments are cut from the body's own faces (the cut straightened and the
hem turned in), offset by their layer's gap + ease (tops worn over the bottoms, outerwear over both), and
proxy-bound like the hair (exact on every build); cylindrical fabric UVs at a real tile size (the B1
fabric maps); colour regions main / trim (the hem) / accent (tag, placket, sole). The cap and glasses are
built on the head; the apron's skirt rides the hips. No brands, no words.
- **Stand-ins** until each is made: dress shoes / boots / sandals → sneakers; button-down → polo;
  cardigan → flannel; tank / baby tee → tee; skirt → slacks; long / short shorts → khakis; wide jeans /
  overalls → jeans; forward cap → backward cap. Full outfits (cheer, waitress, football, coveralls) are not
  made: a preset asking for one gets a top and a bottom (the clothed rule).
- Evidence: `chars-ubc-five-unbaked.jpg` (the five looks, front / 3/4 / back) and
  `chars-ubc-mall-w1-presets-unbaked.jpg` / `-phone-` (every repo preset standing in wing 1, unbaked).
- Weak still: sneakers read as white socks (the foot's shape, no sole block); the flannel and vest are
  close-fitting shells (no collar); the apron's skirt doesn't swing; jeans have no seams or pockets.

## 5. The switch
- `CharBody.manifest_path()`: **UBC by default** when `models/ubc/ubc.json` and the bodies are in the
  pack; the **MakeHuman bodies** with `?chars=mh` in the address, localStorage `mall-chars-body` = `mh`,
  Engine meta `chars_body`, or `-- --chars=mh` on a native command line. Everything above it (presets,
  editor, avatar, attendants, NPC presets) follows the manifest.
- The editor (CHAR-EDITOR's flow) runs unchanged on UBC: BODY shows the shape presets and the contours,
  SKIN & HAIR the six styles, OUTFIT the new pieces and a Beard row on the male.
  Evidence: `chars-ubc-creator-*-unbaked.jpg`, `chars-ubc-menu-main-after-unbaked.jpg`,
  `chars-ubc-after-save-third-unbaked.jpg`, `chars-ubc-timetravel-third-unbaked.jpg`.
- The five presets: the three attendants (`data/characters/pocket_change.json`, `sound_shop.json`,
  `kay_bee.json`) load on UBC through the aliases (no file changed, so the MH flag still shows them as
  before); the two player looks are `tools/qa/fixtures/char_first_five.json` (proposals, not presets).

## Checks (Nov 4, native, unbaked)
- `char_clothed_test.gd`: **CHAR CLOTHED OK (838 checks)** on UBC; with `--chars=mh` **(1632)**.
  On UBC the flattening checks become "the base layer's regions are on the body", and the child checks
  become "no child body can be made".
- `char_editor_test.gd --only=unit`: **CHAR EDITOR OK (28)** on both.
- `char_avatar_test.gd` (wing 6): **CHAR AVATAR OK (40)** on UBC: one body after save, reload, year
  change and time travel, the portrait, the flow.
- Looked at: builds, hair grids, the five looks, the editor, the presets in wing 1.
- Not run: the web build. **Packs:** `tools/chars/pack_list.py` and `tools/shared_packs.py` still list
  `models/characters/` only; the integration session must ship `models/ubc/` in the shared `chars` pack
  (and exclude it from the wing packs). Until then a web pack without the UBC files falls back to the
  MakeHuman bodies by itself.

## Open questions for Steven
1. The builds and their names (Slim / Average / Curvy / Plus; Slim / Average / Athletic / Big & Tall):
   right, and how far should "Average" sit from the kit's athlete (one value, `TONE` in `build_body.py`)?
2. Hair the free kit lacks (long straight, perm, braids, puffs): buy the kit's Source version, or model
   them as cards on these heads?
3. The face pass: are jaw / chin sliders enough, or should the male face be sculpted further?
4. The stand-ins for the garments not made yet: OK until the full wardrobe, or hide those pieces?
5. When to retire the MakeHuman bodies (the flag) and their 76 MB of files.

## Steven's decisions (Nov 4, 2026, evening)
- Hair: **use the six kit styles we have.** No Source kit purchase and no new hair modelling for now; missing styles keep mapping to the nearest kit style.
- Clothes: **keep the swaps** (nearest made garment stands in until the full wardrobe exists).
- Build names, the softened "Average" body, and jaw + chin for the male face: **approved as is.**
- MakeHuman bodies: **drop at integration.** Ship only `models/ubc/` in the shared `chars` pack; remove the `?chars=mh` fallback and `models/characters/` MakeHuman bodies (76 MB) in the same integration session, after checking nothing else still loads them.

## int-52 (Nov 5, 2026): MakeHuman dropped
- Checked first: nothing outside `CharBody.manifest_path()` loads the MakeHuman files (NPC shoppers, attendants,
  the avatar and the editor all go through the manifest; the only direct loads were the skin wrinkle map and the
  piece patterns, which UBC doesn't use: `"wrinkle": false`, no patterns).
- `scripts/char_body.gd`: `manifest_path()` is always `models/ubc/ubc.json`; the `?chars=mh` / localStorage
  `mall-chars-body` / Engine meta `chars_body` / `--chars=mh` switch is gone; `is_ubc()` stays (always true).
- `models/characters/`: every body, piece and texture removed (247 files, ~66 MB); `characters.json` stays as
  `tools/chars/ubc_manifest.gd`'s source (it reads the B1 slots and regions). The B1 Blender tools
  (`tools/blender/characters/`) no longer have shipped files to work on.
- Packs: `tools/chars/pack_list.py` reads `models/ubc/ubc.json` (aliases resolved, `.gltf` images listed, no
  `.bin`: the import holds the meshes); `tools/shared_packs.py` / `tools/make_presets.py` keep `models/ubc/*.gltf,
  *.bin, *.png` out of the wing packs (`ubc.json` stays in them). chars ≈ 30 MB source.
- `char_clothed_test.gd`: the MakeHuman flattening branch removed.
