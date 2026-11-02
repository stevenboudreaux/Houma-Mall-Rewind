# Character bodies, hair and outfits (Godot mall, workstream B1, Nov 2 2026; B-FIX the same day)

## THE CLOTHED RULE (Steven, Nov 2, final). Read this first.
**In the live game ALL characters are clothed AT ALL TIMES.** This replaces every earlier base-layer
rule; there is no optional base layer, no "none" that shows less, and no flag or option around it.
Branch `ws/chars-live` is the only character branch the live game uses (`ws/b1-bodies` is never used).

- **Always dressed.** Every body, adult or child, wears a closed top (`top_tee`, `top_polo`,
  `top_buttondown`, `top_sweatshirt`, `top_tank`, `top_babytee`) **and** a bottom (any `bot_*`), **or** a
  full outfit (`full_football`, `full_cheer`, `full_waitress`, `full_coveralls`). An open flannel or
  cardigan, a store vest or a store apron goes *over* a top; it is never the top. A missing top / bottom
  gets the first one the pack ships of `top_tee`, `top_polo`, … / `bot_jeans`, `bot_khakis`, ….
- **Enforced in the code, not the UI**: `CharBody` (`scripts/char_body.gd`: `make`, `apply` on every
  slider change, `wear`, `wear_many`, `take_off`, `strip_to_base`, `ensure_clothed`) and
  `CharPreset.normalize()` (every preset and save file on load and save: repo files, this browser's
  owner edits, the player's saved avatar, a hand-written JSON). `take_off()` refuses the only top,
  bottom or full outfit; `strip_to_base()` (the editor's "Basics only") leaves exactly a top and a bottom
  or the full outfit, plus hair. A preset or save that tries to undress is corrected on load.
- **No base layer, no lingerie, no swimwear.** Every base-layer piece (sports bra, lace bra, camisole,
  bikini, one-piece, briefs, boyshorts, panties, boxer-briefs, boxers, swim trunks, tank undershirt,
  fitted tee) is deleted from `models/characters/`, the manifest and the generator (`garments.py`);
  `CharBody` refuses any `base_*` slot even from a hand-made entry. Swimwear was dropped rather than
  kept as an adult outfit.
- **A permanent base layer is painted into the body itself**, so a stripped pack or a bug still shows no
  bare chest or groin on any body: `tools/blender/characters/flatten.py` (numpy, on the shipped files)
  flattens the body mesh's chest (front), front pelvis and crotch (Laplacian, at most 4 mm, never
  outward, on the rest mesh and every blend shape that touches them; all four bodies), and paints
  `skin_albedo.png` flat grey (no areolae), `skin_normal.png` flat and `skin_orm.png` rough over
  chest front / back, pelvis front / back and crotch. In the game `spatial_char_region.gdshader` also
  draws those regions as untinted fabric (`base_mask`, `CharBody.BASE_REGIONS` / `BASE_COLOR`).
- **Children.** A body with `youth > 0` or `youth_small > 0` (checked on every slider change and load)
  is a child: it wears only `CharBody.CHILD_ALLOW` (tee, polo, button-down, sweatshirt, flannel,
  cardigan; jeans, wide jeans, khakis, slacks, long shorts, overalls; sneakers, boots, dress shoes,
  sandals; caps, glasses, watch; any hair), an allow-list inside `wear()` / `wear_many()` and
  `normalize()`. No short shorts, tank, baby tee, skirt, uniforms or full outfits; its bust sliders are
  held at 0. The editor labels the youth sliders "above 0 = a child".
- **Evidence**: no body sheets, no base-layer sheets, no sheets of child figures. Only fully clothed
  adults in the game scene (`tools/qa/char_clothed_shot.gd` refuses a child or an undressed body).
  `sheets.py` renders only dressed adults, into `.scratch/` (never evidence).
- **Test**: `godot --headless --path . --script res://tools/qa/char_clothed_test.gd` walks every slider
  end of both bodies (adult and child), every preset (repo, shape presets, extremes), a preset JSON that
  bypasses the editor (`tools/qa/fixtures/char_bypass_preset.json`) through every load path, the
  CharBody API and the editor's rows. It must print `CHAR CLOTHED OK`.

---

The B1 record follows, edited to the rule above (B1 originally shipped a base layer; it is gone).


**Asked for (Steven, Nov 2):** the machinery for an NPC / avatar body editor "as accurate as possible":
two base bodies with shape-key sliders and presets, a hair library, a layered 1995-first outfit library, all on the NPC skeleton so every existing clip plays; exported as
.glb with a manifest so B2's Godot editor is data-driven. **No characters, names or story**: the cast
sheet's people are only test extremes the sliders must reach (the cast sheet file was not in the repo;
the five extremes are the ones in the brief).

Everything is a script; nothing is hand-modelled. Rebuild from the project folder:

```bash
tools/blender/characters/fetch_mh.sh                          # MakeHuman CC0 data, pinned, into .scratch/mh
B=/home/claude/bvenv/bin/python; C=tools/blender/characters
$B $C/decimate.py 13200 lo_map && $B $C/decimate.py 6600 lo2_map   # the game skin and the garment skin
python3 $C/body.py && $B $C/tex.py 2048                        # bodies + skin / eye / lash textures
$B $C/hair.py && $B $C/garments.py                             # 22 hairs, 71 pieces (both bodies)
python3 $C/manifest.py                                         # models/characters/characters.json
$B $C/fitcheck.py > .scratch/chars/fitcheck.txt                # poke-through at the extremes
python3 $C/flatten.py                                          # B-FIX: the painted, flattened base layer
TT_SAMPLES=12 python3 $C/sheets.py hair tops bottoms full shoes extras   # dressed adults, .scratch only
godot --headless --path . --script res://tools/qa/char_check.gd                              # skeleton
xvfb-run -a godot --path . --rendering-driver opengl3 --script res://tools/qa/char_ingame.gd # in-game shot
```

## Sources (all CC0) and what is ours
- **Bodies and shape keys**: MakeHuman's hm08 base mesh and targets (CC0 1.0 since Sept 2020), read
  from MPFB2's repository at commit `6ff1eb35` (`src/mpfb/data` only, `LICENSE.ASSETS.md`). MPFB's and
  MakeHuman's *code* (GPL / AGPL) is not used or copied: the macro rules (how gender, age, muscle, weight,
  height, proportions, cup size and firmness weight the targets) are re-implemented in `mh.py`.
- **Rig and weights**: MPFB's `rig.mixamo.json` (bone heads/tails as hm08 vertex means) and
  `weights.mixamo.json` (CC0 data).
- **Ours**: the skeleton orientation scheme, decimation, the head/body split, eyes, every texture (painted
  procedurally, no photos), all hair, every garment, the binding, the push-out, the manifest, the loader.
- No real brands: the outfit library has no logos or brand words at all (colour regions only); the
  shirt words painter is the existing `npc_shirt.gd` system.

## Skeleton compatibility
- 65 bones named exactly as the NPC skins are in Godot (`mixamorig_Hips` … `mixamorig_RightToe_End`,
  MPFB's 52 + the 13 `_End` / `*4` bones), same hierarchy.
- **Rest = Ch01's T-pose**: every bone's global rest rotation is Ch01's (`npc/anims.json` "rest"), to
  0.04°. `NpcRig` therefore finds **0 fix-ups** at neutral (`tools/qa/char_check.gd`), and every clip in
  `npc/anims.res` plays unchanged. The walk on the new bodies is within 4.75° of Ch01's (the same
  check, bone by bone at four times; the residue is Ch01's skin rest vs the clip skeleton's).
- **Bind = the A-pose** the mesh is modelled and weighted in. The .glb is written by our own writer
  (`glb.py`): joint node TRS = the rest (T-pose), inverse bind matrices = the bind (A-pose). Limb bones
  are turned from Ch01's direction onto the mesh's own limb (shortest arc), torso bones keep Ch01's
  rotation. So in Godot the skin stands in the T-pose at rest; the editor poses the A-pose with the
  `bind_rot` values in the manifest when it wants the scan look.
- **Joints follow the flesh**: each blend shape also moves joints (MPFB's joint definitions on the
  morphed mesh). The manifest lists, per blend shape, each bone's local rest-translation offset
  (`bodies.<sex>.joints`); `CharBody._bones()` adds them, sets the new rests, recomputes the bind poses of
  every Skin (body and pieces share one skeleton and one set of inverse bind matrices; checked: the
  recomputed binds equal the imported ones to 2e-5), and gives `NpcRig` the new hips ratio.
- Hips height (rig ratio): female 0.860 m (0.866 of the clips'), male 0.969 m (0.975).

## Bodies and budgets
| | Game mesh `body_<sex>.glb` | Close-up `body_<sex>_hi.glb` |
|---|---|---|
| Skin (body + head) | 13.2k tris (10.1k body, 3.1k head) | 26.7k (18.3k + 8.5k), hm08's quads |
| Eyes, teeth, tongue, lashes | 1.65k | 1.65k |
| **Total** | **14.8k** (target ≤ 15k: met) | 28.4k |
| File | 5.1 MB (female, 63 blend shapes) / 4.5 MB (male, 59) | 8.8 / 7.8 MB |

- The game mesh is hm08 decimated once (Blender collapse, X symmetry) and stored as a barycentric map
  onto hm08 (`decimate.py`): every shape, weight and region transfers exactly, for both sexes. Surface
  error 0.06 mm mean, 0.8 mm max. The face is therefore lighter than hm08's (3.1k vs 8.5k): use the
  `_hi` body for the avatar creator, close-ups and **the face passes** (it is hm08's clean quad
  topology; Blender's glTF import "tris to quads" restores the quads).
- Real size: female 1.59 m, male 1.73 m at neutral (height slider 1.39–1.84 / 1.53–1.98 m).
- **Separate head** mesh (`head`, material `skin_face`) cut along a mid-neck plane; it shares the
  seam vertices with `body` (same positions, normals and weights: no crack, no shading line).
  A face pass replaces the `head` mesh and the `skin_face` material.
- **Eyes**: real eyeballs (sclera + iris cap, `eye_iris` tinted by the iris colour), fitted per blend
  shape to MakeHuman's eye helpers; **teeth, tongue** (MakeHuman helpers; the mouth interior is part
  of hm08's skin); **lashes** (alpha-masked strips). Fingers are rigged (all 30 finger bones).
  There is no jaw bone (Mixamo has none): mouths do not open; the face pass can add blend shapes.
- Region ids in **UV2.x** (`regions` in the manifest, 23: head, neck, chest_f/b, belly_f/b,
  pelvis_f/b, crotch, shoulder, upperarm, forearm, hand, thigh, shin, foot ×l/r). Not COLOR_0: glTF
  multiplies albedo by it.

## Sliders (`tools/blender/characters/keys.json` → manifest `sliders`)
A slider x > 0 sets blend shape `<name>+` = x, x < 0 sets `<name>-` = −x. Every side is an exact
MakeHuman evaluation (macro) or a sum of MakeHuman targets, with the feet kept on the ground.

| Slider | Range | Source | Note |
|---|---|---|---|
| height | −1..1 | macro height | MH's max-height target is +72 cm; scaled so +1 = +25 cm, −1 = −20 cm |
| weight, muscle | −1..1 | macro | + 12 exact correctives (below) |
| age | 0..1 | macro age 25 → 90 | sag, thinning; wrinkles are a normal map (`skin_wrinkle.png`) blended by age in `spatial_char_region.gdshader` |
| youth | 0..1 | macro age 25 → 11 | children: youth = 1 is 11 years |
| youth_small | 0..1 | macro age 11 → 1 | with youth = 1: a 7-year-old is youth 1 + youth_small 0.4 (one mesh, no separate child) |
| proportions | −1..1 | macro body proportions | "uncommon" ↔ "ideal" |
| shoulders, chest, waist, hips | −1..1 | torso/measure-* | |
| bust, bust_lift | −1..1 | macro cup size / firmness | female only |
| belly | −1..1 | stomach-pregnant | the belly's forward volume |
| butt, thigh, calf, arms | −1..1 | buttocks / legs / arms measure + fat | |
| neck_length, head_size | −1..1 | neck / head scale | |
| jaw, chin, cheeks, nose, eye_size, eye_spacing, lips | −1..1 | chin / cheek / nose / eyes / mouth | face shape keys, kept small: the face pass does the rest |
| posture (stoop) | 0..1 | **skeleton only** | rest rotations (Spine1 7°, Spine2 12°, Neck 14°, Head −22° about the body's X) so every clip plays stooped (NpcRig carries motion over from the new rest) |

**Correctives** (`c_weight+_muscle-` …, 12): MakeHuman's weight × muscle × age interaction terms by
inclusion–exclusion, weighted at runtime by the product of the named sides (`correctives` in the
manifest). Without them "weight +1" alone is MakeHuman's *average-muscle* heavy, which is mild; the
heavy, soft bodies of the scan references come from weight + with muscle −, which the correctives
make exact. Height, proportions and bust interact linearly (approximation).

**Presets** (`presets.json` → manifest `presets`): women Straight Petite / Missy / Plus, Curvy Petite /
Missy / Plus; men Slim / Regular / Athletic / Big & Tall. **Extremes** (QA only): skinny 74, heavy-set
52, muscular 20, curvy larger, child 7 (the child extreme is under the child rule). No body sheets (B-FIX).

## Skin
- One map set for every tone: `skin_albedo.png` (2048, near-white with *relative* colour only: lips,
  cheeks, ears, knuckles, nails, areolae, lighter palms and soles, brows) × the material tint = the tone.
  `skin_normal.png` (2048, pores), `skin_orm.png` (1024, roughness: oily T-zone, lips, nails),
  `skin_wrinkle.png` (2048, forehead, crow's feet, nasolabial folds, neck, hands; blended by age).
- **Tones**: manifest `skin_tones`, ten from porcelain `#f6e1d3` to very deep `#362016`; the slider
  interpolates along them. `skin_body` and `skin_face` are separate materials on the same maps.
- Eyes `eye_albedo.png` (512, grey iris tinted by `iris_colors`), lashes `lash_albedo.png` (alpha).

## Hair (`hair.py`, 11 styles × 2 bodies, 324–1780 tris, ≤ 2k)
Bowl cut, short fade, crew cut, side part, shoulder length, long straight, perm / curly, puffs, braids,
thinning / balding, white / grey set. Scalp-following shells (ray-cast onto the body's own head, dilated
over the ears), curtains that fall down the back and stop on the shoulders at the sides, curl
displacement, puffs, braid tubes, a bald crown. Rigid on the Head bone (as asked) but bound to the head
skin for blend shapes, so head size, age and weight move it. One strand texture, tinted
(`hair_colors`, 11, black → white); COLOR_0 darkens the roots. Sheet: `wsB1-hair-<sex>.jpg`.
**Weak:** the perm reads as a helmet; braids are tubes; a fade is a thin dark shell (no skin blend).

## Outfits (`garments.py` CATALOGUE; 1995-first, no brands)
Tops: T-shirt (keeps the shirt words: `shirt_words_at` = Spine2 + chest height), polo, button-down,
flannel (open, over a tee), baby tee (female), tank, sweatshirt, cardigan. Bottoms: straight jeans,
wide-leg jeans, slacks, khakis, long shorts (jams / cargo), short shorts, skirt (female), overalls.
Full: football uniform (jersey with pads, pants, socks), cheerleader (female), store uniform vest +
name tag, store apron + name tag, waitress (female: dress, skirt, half apron), work coveralls.
Shoes: sneakers, boots, sandals, dress shoes. Extras: cap forward / backward, glasses, watch.
Every piece exists for both bodies where it applies (fits come from each body). Colour regions
`main` / `trim` / `accent` (+ per-part colours on the uniforms), defaults in the manifest. Tris
500–4200 (manifest `tris`, `budget`). Sheets: `wsB1-outfit-<tops|bottoms|full|shoes|extras>-<sex>.jpg`.

### How a piece is made (and how to add one)
1. **Surface pieces** are *cut from the body's skin* along a signed field (`keep`, metres) built from
   `fields.py`: height, the arm / leg parameter along the bone (0 joint … 0.5 elbow / knee … 1 wrist /
   ankle), neckline azimuth, landmarks measured on the body (hip joints, narrowest waist, widest hips,
   crotch, bust line, neck base). Triangles are clipped along keep = 0, so hems are clean lines.
2. Offset by the layer gap (0: 2.5 mm, 1: 5, 2: 7.5, 3: 14 mm) + ease; fronts **drape** straight
   down from the bust / belly; trouser legs keep the knee's radius below it (straight) or flare (wide);
   smoothed (hems pinned), pushed back out; a hem lip folds every edge toward the skin.
3. **Loose pieces** (skirts, aprons, shoes, cap, glasses, watch) are generated around the body with rays
   against the torso and legs only (the hands hang at hip height in the A-pose).
4. **Bound** to the body (`pieces.write_piece`): each vertex takes the 8 nearest skin vertices
   (inverse-distance weights) for its joint weights and for a blend shape per body blend shape (same
   names), and the **push-out**: with the body fully at each blend shape, any vertex closer than ~60 % of
   its gap to the game skin is moved out along the skin normal, inside that blend shape.
5. To add a piece: one `add("top_x", "Label", slot, layer, sexes, keep, tex=…, default=…, tris=…)` line
   in `catalogue()` (or a `kind=` for loose pieces), run `garments.py <female|male> top_x`, then
   `manifest.py`, `fitcheck.py`, a sheet. Fabric textures: `fabric.py` (`fab_<name>_albedo/normal.png`,
   256 px tiles, grey, tinted; `uv_scale` in the material extras).

### Layering (what we do, and where it fails)
- Order **underlayer (1) → top / bottom (2) → outerwear (3) → shoes (4) → extras (5)** (layer 0 is
  unused: the body carries its own painted base layer); a flannel (3) over a tee (2); a cardigan (3)
  over a button-down (2).
- **Region hiding** (the main tool): each piece lists `hides`, the regions it covers completely
  (computed). The loader (`CharBody._layers()`) gives every surface a `spatial_char_region` material
  whose `hide_mask` discards the regions covered by anything on a higher layer: the body under jeans,
  an underlayer tee's torso under a polo, the tee's torso under a closed vest, while the tee's collar (neck) and anything
  outside the covered regions still show. A region is hidden only when it is *entirely* covered, so
  hiding never makes a hole.
- **Push-out by construction**: the layer gaps keep stacked pieces apart; the `fit_over` blend shape
  (+6 mm) of a piece on layer ≥ 1 is turned on when another piece of its own layer or the one below is worn.
- **Where it fails**: (a) a lower layer that is *looser* than the one above (a sweatshirt under a
  button-down) clips; swap instead. (b) Partially covered regions rely on the gaps alone (the B-FIX flattening only moves
  the body inward, so it adds no poke-through). (c) Sliders combine linearly, so the push-out (per blend shape) can miss combinations:
  `fitcheck.py` on the exported files, all 71 pieces × 6 test bodies, leaves at most a handful of
  vertices (≤ 15 of ~1000) within 4–8 mm inside the skin, almost all on "curvy larger" (bust + hips +
  weight together); glasses' temples tuck into the head by design. (d) The open flannel's fronts hang
  straight; they do not swing. **Hard-shell pieces**: none in the 1995 list is a hard shell; a future
  jacket can be layered the same way (layer 3), swap-only if it is stiff.

## Manifest (`models/characters/characters.json`)
`bodies.<sex>`: glb, glb_hi, tris, height, hips height, blend shape names, `bones` (parent, pos,
rest_rot, bind_rot), `joints` (per blend shape, per bone local offset), material roles. `sliders`
(name, group, range, kind shape / skeleton, shapes or bones, notes), `correctives`, `presets`,
`skin_tones`, `iris_colors`, `hair_colors`, `layers`, `regions`, `pieces` (id, base_id, glb, body, slot,
layer, label, tris, budget, hides, materials with labels and defaults, default_color, texture,
patterns, counts_as, shirt_words_at, fit_over, style for hair).

## In Godot (`scripts/char_body.gd`, `class_name CharBody extends NpcBody`)
`make(sex, hi)`, `apply(sliders)`, `wear(piece)` / `wear_many(list)` (refuse base-layer and, on a child,
non-allowed pieces), `take_off(piece)` (refuses the only top / bottom / full outfit), `strip_to_base()`
(the clothed minimum), `is_clothed()`, `ensure_clothed()`,
`paint(material prefix, colour)`, plus everything NpcBody does (clips, gestures, walk speed, IK, look).
`tools/qa/char_check.gd` (numbers), `tools/qa/char_ingame.gd` (the shot next to Ch01).

## For B2 (what to know)
- **Cost**: a dressed body is ~14.8k + hair ≤1.8k + pieces 2–6k ≈ 20–25k tris and 60+ blend shapes.
  Blend shapes cost per frame per vertex: for crowds, **bake** a body once its sliders are set
  (apply the blend shapes into a new ArrayMesh at load, then no blend shapes run), and use Godot's import
  LODs. The shipping NPCs are 0.9k–10k tris; this is heavier (see `production/qa/evidence/wsB1-ingame-*`).
- The web build will need the `models/characters/` pack (67.9 MB of source files for everything since
  B-FIX; ship only the pieces a year map uses: `tools/chars/pack_list.py`).
- Pieces must be on the same skeleton: always move their meshes under the body's `Skeleton3D` and call
  `_bones()` (joint offsets) and `_layers()` after any change.
- Joint offsets assume the rest is recomputed on every slider change (cheap: 65 bones).
- The face slots for Steven's face passes: replace `head` (and `skin_face`), keep the neck seam vertices.
- **The clothed rule** (top of this file) is enforced in `CharBody` itself; never add a path around it.

## Known defects (Nov 2, for the next pass)
- **Store apron**: a stray panel hangs at one side (visible from behind on every body; 2 vertices 35 mm
  inside the skin on the heavy male), from the waist ties strip. Fix in `loose.apron_part`.
  **Fixed by B2** (the bib's top-row outer vertices, not the ties: `design/godot-character-editor.md` "Apron").
- **Hair** reads grey-ish under the mall lights at a distance (sheen on a smooth shell); raise its
  roughness or add strand alpha cards. The perm is a helmet.
- Fit check (`fitcheck.py`, exported files, 71 pieces x 6 bodies): 34 pieces never touch the skin;
  the rest have at most 2 % of vertices up to 5.4 mm inside, nearly all on "curvy larger".
- `fitcheck.py` and the dressed sheets were not re-run after B-FIX (no Blender in the cloud session);
  the flattening moves the body only inward (≤ 4 mm), so fits can only gain clearance.

## Guesses (written down, to confirm)
- 1995 store uniform colours (red vest, green apron) and the football / cheer colours are placeholders;
  the colour regions take any store's colours.
- Neutral heights 1.59 m / 1.73 m (US adult means are ~1.62 / 1.76): the height slider covers it.
- B-FIX: the painted base-layer colour (`#bdbab0`, a plain undershirt / bike-short grey) and its regions
  (chest front / back, pelvis front / back, crotch; belly and shoulders stay skin) are guesses.
