# Blender pipeline for the Godot mall (workstream T, Nov 1 2026)

Walls, halls and storefronts stay generated from the map data (`tools/build_mall.gd`). Blender makes the
things seen up close: inventory items, detailed fixtures, statues, later avatar clothing. Each asset is
a Python script run headless with Blender-as-a-module (`bpy`, Blender 5.2), so Claude can build it,
render it, look, fix a number and rebuild. Standing instructions: `.claude/skills/blender-asset/SKILL.md`.
Paths below are under `prototypes/godot-mall/project/`.

## How it works

```
tools/blender/assets_src/<id>.py      numbers at the top, META, build()
        │  tools/blender/run.sh <id> [--fast] [--evidence]     (build.py)
        ▼
build() makes the parts ─► weld + triangulate + join ─► budget check (budgets.json)
        ─► [hipoly: decimate a copy, bake the sculpt onto it]
        ─► Smart UV atlas ─► Cycles bake: albedo (AO folded in), ORM, normal ─► one Principled material
        ─► res://models/<id>/<id>.glb + <id>_albedo/_orm/_normal.png (+ _icon.png)
        ─► re-import the .glb ─► turntable (6 angles, AgX) beside the reference ─► .scratch/blender/<id>-sheet.png
        ─► data/items/blender_props.json (items only)
tools/blender/godot_check.sh ─► godot --import ─► tools/qa/preview.gd scene with the .glb ─► PNGs
```

- **Toolkit** `tools/blender/lib/`: `core` (scene, modifiers, apply, freeze), `parts` (box, rounded
  panel, cylinder, sphere, lathe, tapered tube, screw, button, keypad, trim moulding, fabric fold, label
  plate, grille, antenna), `mats` (node-graph builder, plastic, brushed metal, clear plastic, position-
  mapped decals), `labels` (PIL printed art with the project fonts), `bake`, `clean` (weld/triangulate/
  join, budget, decimate), `render` (turntable, icon).
- **Axes.** Modelled in Blender Z-up, exported +Y up. Front = Blender -Y = Godot +Z. Origin bottom
  centre. Metres.
- **Textures.** Godot cannot read Blender's procedural nodes, so every material is baked to images:
  one Principled material `bl_<id>_baked` per asset (one draw call), PNG, power of two, 512–2048 px.
  Materials that must stay flat (transparent blister, glowing lava, plush eyes) are kept as their own
  glTF materials (`bake=False`). The PNGs sit beside the `.glb` and are referenced by URI (Blender's
  GLB export writes both a placeholder buffer and the URI; `build.py fix_glb_uris` keeps the URI), so
  each texture is in the repo once and Godot imports it like any other.
- **UV2.** Not made in Blender. A static prop placed in a baked wing gets UV2 from Godot's importer:
  set `meshes/light_baking=2` in its `.glb.import`. Hand/pocket items are dynamic (probe-lit): none needed.
- **Metals** default to metallic 0.75 (the game's own metals are 0.6–0.8 in `build_mall.gd`; stores have
  no reflection probes and full metal reads black there).
- **Collision.** Parts named `…-col`, `…-convcol`, `…-colonly` stay separate and use Godot's import
  suffixes. None of the first batch needs one.
- **Recolouring.** One model can serve several colours with a surface material override in Godot, by
  material name: the plush fur atlas is baked near-white and tinted (`albedo_color` multiplies it; eyes,
  nose and bow are separate materials and keep their colour); the lava lamp's `…_wax` and `…_liquid` are
  flat glow materials. `godot_check.gd recolor()` shows the override; the item JSON lists the palette.

## Budgets (`tools/blender/budgets.json`, read by the build)

| Class | Triangles | Texture | Examples |
|---|---|---|---|
| pocket | ≤ 2,000 | 512–1024 | pager, battery card, finger trap |
| hand | ≤ 5,000 | 512–2048 | scanner, phone, corn dog, plush, lava lamp |
| small_fixture | ≤ 10,000 | 1024–2048 | finial, register, sign parts |
| large_fixture | ≤ 25,000 | 1024–2048 | booths, cabinets, mannequins, statues |
| npc, clothing | not set yet | | the build prints `BUDGET NOT ASSESSED` |

Over budget fails the build (`OVER BUDGET: … has N triangles; the 'hand' budget is 5000`). Decimation is
a last resort (`META["decimate"]`, logged `DECIMATED`). Sculpted assets use `META["hipoly"]` instead:
the dense sculpt is decimated to the target and its detail baked back as maps (logged `HIPOLY`).

## Adding an asset

1. Write `tools/blender/assets_src/bl_<store>_<thing>.py` (copy the nearest one; the header says what
   it is based on and what is guessed).
2. `tools/blender/run.sh <id> --fast`, read `.scratch/blender/<id>-sheet.png`, fix, repeat.
3. `tools/blender/godot_check.sh glb .scratch/blender/<id>-godot "x,y,z,yaw,pitch" '{"stand":[…],"glb":[…]}'`.
4. `tools/blender/run.sh <id> --evidence`; keep `production/qa/evidence/wsT-<id>-sheet.jpg` and
   `wsT-<id>-godot.jpg`. Commit the script, `.glb`, PNGs, `.import` files, item JSON. No `.blend`.

## Inventory entries

`data/items/blender_props.json`: `{"id","name","class","scene","icon","year", …}` written from each
asset's `META["item"]`, the same shape as workstream D's Godot-built list, plus `store` and, where it
applies, `tickets`/`prize` (finger trap: 15 tickets, the same as `scripts/prizes.json` `finger_trap`),
`tint`/`recolor` palettes. No `place`: these are not put on anyone's shelves. The integration session
picks the better version of each item where D made one too.

## First batch

Triangles = the exported mesh; textures = per map (3 maps: albedo, ORM, normal).

| Asset | Class | Tris | Tex | Based on | Guessed |
|---|---|---|---|---|---|
| `bl_dir_finial` (directory kiosk fan finial) | small_fixture | 780 | 512 | `refs/new/directory/IMG_4408_t050_017–027` (straight on): five folded diamond blades fanned from a ball on a collar | the size (~0.24 × 0.22 m, scaled from a ~1.25 m cabinet face); finishes (pewter blades, warmer ball, as they read under the hall LEDs) |
| `bl_rs_scanner` | hand | 3,592 | 1024 | the 1999 video's walls of black electronics (`refs/new/radioshack_1999` 0:44–1:00) for colour and kind | the shape (period handheld scanner type), all labels (BAYOU COM SC-200, invented) |
| `bl_rs_walkie` | hand | 2,052 | 1024 | same | 49 MHz type (FRS only came in 1996); one unit of the pair |
| `bl_rs_cordless` | hand | 2,612 | 1024 | the video's phones (2:35) | the shape (off-white 1995 handset in a slanted base) |
| `bl_rs_pager` | pocket | 1,056 | 1024 | `refs/era_1995/ads/ad_3.jpg` (Radiofone, Houma: landscape pagers, wide LCD over three buttons) | the brand (invented) |
| `bl_rs_rcbox` (R/C monster truck, boxed) | hand | 120 | 2048 | the video's R/C boxes (0:20, 1:00) and `radio-shack.md` ("purple-blue with yellow flames, invented") | all the box art (TURBO DUNE, invented) |
| `bl_rs_battcard` (AA 4-pack) | pocket | 1,544 | 1024 | the battery wall (0:56–1:20); red/black like `paint_rs.py` | the brand (ZAP-CELL, invented) |
| `bl_cd7_corndog` | hand, year "both" | 4,296 | 1024 | the stand only (`refs/derived/signs/corndog_IMG_4461_f005.jpg`); no photo of the food | the whole corn dog (hand-dipped type); no packaging (none documented) |
| `bl_pc_fingertrap` | pocket | 912 | 1024 | `scripts/prizes.json` / `prizes.gd` (bin colours); no photo | weave: 2-over-2 twill, natural + red; procedural weave baked to albedo + normal (real weave geometry would be 20–40k tris for a 2k item; the trap's outline is a smooth tube, and the baked normal map shows the strips, over/under and gaps up close) |
| `bl_gb_lavalamp` (Steven, Nov 1) | hand | 1,504 | 512 | `tools/stores/gumballs/store.gd lava()` proportions and colours; `gumballs.md` | the rocket shape and blobs (no photo; Steven remembers them) |
| `bl_pc_plush_bear` / `_dog` / `_bunny` (Steven, Nov 1) | hand | 1,956 / 1,612 / 1,744 | 512 | `tools/stores/pocket_change/crane.gd plush()` body plan and FUR palette | faces, bow; generic, unbranded |
| `bl_ls_lion` (Steven, Nov 1; **rebuilt by T2, see below**) | large_fixture | 21,560 (sculpt ~400k) | 2048 | Steven's lion picture from the 2D game (`design/storefronts/refs/lions-share-lion.png`, extracted from `index.html` media "lion") | size (~0.95 m lion on a 0.32 m plinth), plinth, the back and the tail. **First pass, not yet at the reference's standard** (see below) |

Fixture (e) of the brief (register or booth) was not built: the session time went to Steven's
mid-session requests (lava lamps, claw toys, lion statues).

### What did not work / what is open

- **The lion** reads as a seated lion with a big mane on a plinth, at budget, but not yet as the
  carved statue in the picture: the face is too round (cheeks and muzzle read as balls), the mane locks
  blur into a lumpy mass at the 4 mm voxel size, and the front legs read short. Next: sculpt the face as
  its own higher-resolution piece (smaller voxel, sharper planes for brow, nose bridge and mouth line),
  make the locks fewer and larger with deeper grooves between them, longer forelegs, and a full-quality
  look in the hall beside Lion's Share.
- **Lava lamp in Blender's preview** looks pastel (AgX desaturates a bright red emitter); in Godot
  (Filmic) it glows correctly at the store's own emission energy (2.2).
- **Reflection probe in `godot_check`** streaks the walls under xvfb (compatibility renderer), so it is
  off by default (`"probe": true` to try it).
- Evidence shots are unbaked (preview lighting).

## Second batch (workstream T2, Nov 1 2026)

Steven's rule for this batch: every item can be picked up: an entry in `data/items/blender_props_2.json`
(written by `build.py` from `META["item"]` with `META["item_file"]`), a scene, a 256 px icon and a `place`
in the 1995 mall. Positions come from each store's build constants (the frame `P(u, y, d) = a + t u - n d`
of its `layout_mall.json` edge) and were checked in unbaked Godot shots of the store
(`tools/blender/godot_check.sh "store:<NAME>"`): every item sits on its surface. Evidence:
`production/qa/evidence/wsT2-<id>-sheet.jpg` (turntable) and `wsT2-<id>-ingame.jpg` (in the store, unbaked).

| Asset | Class | Tris | Tex | Where (wing, pos) | Based on | Guessed |
|---|---|---|---|---|---|---|
| `bl_bd_paperback` "Shiverwood #7 paperback" (+ copies `_b`, `_c`) | pocket | 256 | 1024 | B. Dalton's table of new titles, face-up on its front half: w2 (-105.42 / -105.62 / -105.82, 0.76, ~45.97) | Steven asked for **"a Goosebumps book"**. The IP rule (no real titles, cover art or logos) rules out the real series, so this is an **invented series in that spirit**: SHIVERWOOD #7 "The Bayou Babysitter" by an invented author, purple cover, drippy lime title (Titan One, OFL), a moonlit swamp with glowing eyes and a clawed hand, $3.99 sticker, cracked spine, blurb and bar code on the back | everything printed; size (US kids' paperback 108 x 175 x 12 mm). Three pick-up copies (the brief allowed static copies; all three can be picked up because placing static ones would mean editing B. Dalton's build code) |
| `bl_wl_rootbeer_float` | hand | 4,616 | 1024 | Woolworth lunch counter top, in front of a stool: w1 (-18.01, 1.0, -11.88) | Steven: root beer, not cola. `refs/era_1995/stores/Woolworth.jpg` (setting), `woolworth/store.gd` LC_U/LC_DP/LC_H | the fluted soda glass (one transparent shell, not baked: a second inner shell made it read opaque), foam, straw, saucer; no brand |
| `bl_tt_lomein` | hand | 4,740 | 1024 | Tee Tai's counter, right end clear of the steam table and sneeze guard: w1 (21.6, 0.95, 8.12) | `refs/era_1995/other/other_1.jpg` (Steven's 1990s photo; the counter is not readable, so the paper pail was chosen over a styrofoam plate), `tee-tais.md` menu | the pail's generic red pagoda / THANK YOU print, the vegetables |
| `bl_oj_cup` | hand | 1,216 | 1024 | Orange Julius counter, past the register: w1 (12.95, 1.0, 8.66) | `refs/era_1995/stores/Orange_Julius.jpg` (colours only) | the cup's orange swirl print (no logo), the clear lid (so the drink reads), the straw stripes |
| `bl_gac_sugarcookie` (Steven's pick) | hand | 4,075 | 1024 | Great American Cookie Co., on the case top beside the register: w2 (-26.92, 0.862, 45.02) | `great-american-cookie.md` | the cookie's crackle and sugar, the plain sleeve. **Workstream G is rebuilding that case: if its top height changes, `pos[1]` must follow** |
| `bl_kk_caramelcorn` | hand | 2,368 | 1024 | Karmelkorn's L counter, on the steel top past the register: w2 (-24.9, 1.28, 61.95) | `karmelkorn.md` | the striped bag and its generic CARAMEL CORN label (no tenant mark on the product) |
| `bl_sr_folse_stick` (item `folse_stick`) | hand | 480 | 1024 | unchanged: the Stockrooms' far room (`stockrooms.json`) | `stockrooms.gd _stick()` | the collar, the wear. Replaces the two cylinders in `scripts/items/folse_stick.tscn` (halo, light, grip and metadata kept); the paint's faint self-glow is glTF emission from the baked albedo (`META["emissive"]`) |
| `bl_ls_lion` second pass | large_fixture | 23,528 (sculpt ~1.6M) | 2048 | not placed (fixed decoration; same id, origin and facing) | Steven's lion picture; mid-session Steven: **"fill out the side and back of the lion, it's smooth and unrealistic"** with five statue references (seated lions in side view) | depth, back, plinth, tail |

### The lion, second pass: what changed

The first pass read soft and blobby. Looked at against the reference after each build (five iterations):
1. **Bake fixes (the biggest visual gain).** The voxel-remeshed sculpt was flat-shaded, so the normal map
   baked facets; it is smooth-shaded now. Smart UV on a decimated sculpt shattered it into thousands of
   confetti islands while the plain plinth took half the atlas: the low-poly is now a smooth 8 mm remesh
   of the sculpt before decimation (`META["lowpoly_voxel"]`), the plinth is kept out of the decimation
   (`META["hipoly_keep"]`) and gets 0.3 of its atlas share (`META["uv_shrink"]`).
2. **Face.** Solids (skull, wedge brows, a muzzle block under a broad flat bridge, a wide nose, cheeks,
   pads, chin) fused by a remesh with a morphological closing (grow, remesh, shrink: clay-like fillets
   where forms meet), then carved alone with boolean cutters (eye sockets, nostrils, muzzle groove, mouth
   line, frown crease). A boolean on the whole sculpt ran out of memory, so the head is its own shell.
3. **Mane.** ~240 flat tapered ribbon locks (not round tubes) in four front tiers, the ruff over the
   middle over the outer, tips lifting; five rows over the top, sides and back of the neck down to the
   withers, over a smaller core mass so the locks stand proud (the back was smooth at first because the
   core mass buried them).
4. **Side and back anatomy (Steven's mid-session ask).** The back slopes from the withers to a round
   rump; ribcage, scapula, triceps, deltoid and flank forms; the hind leg folded (thigh forward to the
   knee, shin back to the hock, foot lying forward on the plinth); longer forelegs.

Still open: the baked gold reads smoother than the sculpt (the shiny metal hides normal-map relief under
studio light); size: workstream D's procedural lions (`wave9.gd lion()`) are 1.45 m on a 0.55 m plinth,
this model is ~0.95 m on 0.32 m, so the integration session should scale the node (~1.5) or say which
size Steven wants. Unbaked comparison beside D's lion: `wsT2-bl_ls_lion-ingame.jpg`.

## The lion, third pass (workstream L, Nov 2 2026)

Steven on pass two: still soft and blobby, "a smooth blob with a vague mane and face"; he wants a carved,
polished gold statue that reads at arm's length. D's built-in lions (`wave9.gd lion()`) are being removed in
parallel (session D48), so this model is the only lion that ships. **A restart, not an extension** of the
pass-two script: pass two hung its locks on one big ellipsoid (the helmet silhouette in its sheet) and built
the face from balls, and neither could be tuned out.

| Asset | Class | Tris | Tex | Where | Based on | Guessed |
|---|---|---|---|---|---|---|
| `bl_ls_lion` third pass | large_fixture | 23,521 (sculpt ~2.1M) | 2048 (albedo, ORM, normal) | Lion's Share front, D's two spots (`P(lu, 0, -0.55)`, the left one mirrored), behind `BL_LION` in `wave9.gd` | Steven's lion picture (the only lion picture in the repo or on the `refs` branch; nothing under `refs/` is named lion), measured at 0.95 m / 300 px | depth, back, ears, tail, plinth, size (pass two's, kept) |

**Method** (`tools/blender/assets_src/bl_ls_lion.py`, header has the measurements):
1. **Big forms** (ellipsoids, tapered capsules) fused by a voxel remesh with a morphological closing, plus a
   mane core (crown, neck, a jowl each side for the 0.40 m width at the cheeks, a bib over the chest).
2. **Locks draped by ray casting.** ~140 hand-placed locks are paths in mane coordinates (arc metres round
   the axis, height; above 0.80 m the rays tilt over the crown), laid on the core by casting a ray from outside
   towards the axis, so they follow the crown, neck, shoulders and chest instead of an ellipsoid. Each lock
   is a flat ribbon with a **corrugated top** (2-3 strand ridges) that tucks in at the root, tapers to a
   point and lifts its tip off the surface. Tiers: the face ruff (rooted on the face's edge, raised above the
   next tier once it leaves the face), a middle ring, the beard and chest points, four outer rows falling
   down the sides and the back, short locks combed back over the crown. Paths and normals are smoothed along
   each lock.
3. **The face is a carved relief, not solids**: one surface whose depth is a sum of smooth terms over
   (x, z) (`relief()`): dome, snout profile (bridge sloping forward to the nose, muzzle falling back), a
   trapezoid nose leather, nostrils, whisker pads, philtrum, mouth line, chin, V brow ridges, almond
   sockets, lower lids, cheeks and carved fur strokes radiating from the nose. Closed into a solid, fused
   with the skull and ears at 1.4 mm, whisker dots and ear cups carved with booleans; eyeballs with a
   drilled pupil sit in the sockets. This was the change that made the face read: solids gave a pug or a
   teddy bear (iteration 1) however they were tuned.
4. **Bake** (build.py hipoly path): 2.4 mm remesh of body + mane, decimated to 24k; normal, AO and a new
   **curvature** bake (pointiness); `finish_maps()` in the asset builds the gold from them: hollows (AO,
   concave curvature) dark and rough, crests bright and polished (roughness 0.18 / 0.34 / 0.62 high / mid /
   hollow, metallic 0.9, a little less in the hollows), the hipoly's scratch layer (thin stretched-noise
   streaks in patches, a little brighter and rougher) on top.
5. **Steven's picture as texture:** projected orthographically from the front onto the hipoly (its
   high-pass detail only, masked to front-facing surfaces, strength `REF_DETAIL` 0.35) and baked into the
   albedo. Honest result: at 193 x 300 px it adds faint grain on the mane front; the read comes from the
   geometry, not from it. `REF_DETAIL = 0` removes it.

**Iterations** (`production/qa/evidence/wsL-lion-sheet-{1..5}.jpg`: the reference, this pass and pass two
at the same angles):
1. New silhouette, draped locks. Wrong: face from solids still a pug, locks thin and stringy, the mane
   too narrow, a hole at the crown, a tube spine, gold too orange.
2. Face rebuilt as a relief; wider, thicker, fewer locks; jowls; crown filled. Wrong: the face a round
   plate whose rim stands 5 cm proud of the ruff; plain forehead; olive, chrome-like gold; near-black gaps.
3. **Regression**: draping every lock onto the face too pulled locks across the eyes.
4. Only the ruff drapes on the face, rooted on its edge and raised above the next tier; the dome runs to
   the oval's edge (no gap), carved fur strokes; paler satin gold. Wrong: a black splotch on the chest mane.
5. The splotch was 4.8% of the normal map pointing into the surface (cage rays hitting the back of the next
   lock); build now clamps tangent normals (z >= 0.25) on hipoly bakes and the cage is 16 mm. Final.

**What worked:** the relief face; ray-cast draping; corrugated locks; the ruff above the middle tier; the
curvature-driven gold. **Still open / would change next:** the face reads a little like a mask in a ruff of
petals from straight on (more fur crossing onto the cheeks and forehead would knit it in); the back of the
mane is a curtain of hanging strips; the body is smooth (it is in the picture, too); the size (below).

**Size (settled Nov 2: Steven, "don't make the lions bigger"):** kept pass two's size (0.95 m lion on a 0.32 m plinth, 1.27 m overall); D's built-in lions were 1.45 m on 0.55 m (2.0 m overall). `BL_LION_SCALE` in `wave9.gd`
scales both (1.5 gives D's size). In the unbaked in-game shot they read small beside the 2.4 m door.

**In game:** `BL_LION := true` (one line, `tools/stores/small/wave9.gd`) instances the .glb at D's two spots
under `BlenderProps` in wing 2 (1995), the left one mirrored so both tails are on the outer side, with D's
floor obstacle; false brings back `lion()` (until D48 removes it). The .glb imports with
`meshes/light_baking=2` (static lightmaps, UV2 from Godot) at 0.05 m texels. Evidence (unbaked):
`wsL-lion-ingame.jpg`. Wing 2 (1995) needs a rebake when this ships.

### Steven's notes on the third pass (Nov 2, afternoon) and the changes
Steven: the body is good; the face needs work; a little muscle on the body; **don't make the lions bigger**;
make the plinth the same gold as the body and shrink it so the lion sits tighter on it.
- **Face, second version** (`relief()`): the outline is the picture's (a long wedge: broad forehead and cheeks
  narrowing to the chin, `face_hw()`), not an oval; calm heavy brow instead of the angry V; bigger, wider-set
  eyes under a deeper upper lid; a broad bridge to a big, flat-topped, triangular nose; big whisker pads and a
  deeper mouth line; no whisker dots (the picture shows none); fine fur strokes on the muzzle, cheeks and
  forehead, growing into deep lock grooves at the face's edge. The edge slopes gently into the mane (it was a
  cliff, which made the ruff kink into a lumpy "hood" rim) and the ruff grows flush out of the face, rising
  over its first 60%.
- **Muscle:** pectorals, deltoids, the forearm's outer muscle, the thigh over the haunch, the hamstring.
- **Plinth:** the same gold (its own material, `bl_ls_lion_plinth`, so it keeps crisp edges and a small atlas
  share; `finish_maps` gives it the same AO/curvature gold), 0.62 x 0.66 m (was 0.72 x 0.76), same 0.32 m
  height; the tail pulled in to fit. The in-game floor obstacle follows (`wave9.gd bl_lion()`).
- **Size:** unchanged (0.95 m lion), per Steven; `BL_LION_SCALE` stays 1.0.
- Result: 23,524 tris, 2048 px. Evidence: `wsL-lion-sheet-6.jpg` (the reference, this build and the morning's),
  `wsL-lion-ingame-2.jpg` (unbaked). Still visible up close: a faint line where the face shell meets the
  mane on one side.

### Pipeline additions (workstream L)
- `bake.py`: `META["curvature"]` bakes the hipoly's pointiness (kept in `.scratch/blender/<id>_curv.png`,
  not shipped); an asset's `finish_maps(maps)` gets the baked albedo, roughness, metal, AO and curvature as
  arrays and returns the final albedo / roughness / metal; hipoly normal bakes clamp inward-pointing normals
  and the log says `NORMAL CLAMP n texels`.
- `compare.py`: the review sheet for a rebuild: reference | new | previous at the same angles (front framed
  on the statue above `--zmin`, face, 3/4, side, back).

### Pipeline additions (T2)
- `build.py`: `META["item_file"]` (which `data/items/` file), `item.copies` (more pick-ups of one model),
  `META["emissive"]`, `META["icon"]` (icon without an item entry), `lowpoly_voxel` / `hipoly_keep` /
  `uv_shrink` for sculpts, a triangulate after the hipoly decimation. `run.sh`: `EV_PREFIX=wsT2`.
- Run one Blender build at a time: the session's memory limit killed a sculpt build running beside a
  small one.

## The boom box (workstream R, Nov 2 2026)

| Asset | Class | Tris | Tex | Where | Reference | Guessed |
|---|---|---|---|---|---|---|
| `bl_pc_boombox` "Boom box" | hand | 4,628 (budget 5,000) | 2048 (albedo, ORM, normal; 3.3 MB) | **not placed**: Pocket Change's redemption stock only, 500 tickets (Steven); no quest | **none**: the reference pack has no boom box (`refs/INDEX.md`) and Wikimedia is blocked from the cloud; the type from Steven's brief and Wikipedia's "Boombox" (CD players from the mid 90s) | everything: 0.54 × 0.15 × 0.24 m body plus handle; dark grey worn plastic, silver speaker rings, perforated grilles, a detachable-looking centre panel (dark seam, two release tabs) with the tuner LCD and the twin cassette doors (DECK A, DECK B REC/PLAY), a CD lid with a smoked round window on top, ten transport keys along the top front edge, two top knobs, a carry handle with a rubber grip, a telescoping antenna on a swivel at the back left, a battery label on the back. Brand **KREWE KR-95CD** (invented, IP rule) |

- **Held by the handle:** the item's scene is `models/bl_pc_boombox/bl_pc_boombox_item.tscn` (the .glb plus a
  `Grip` at the top edge under the handle, turned 30° and tipped 40° toward you so the front shows in
  first person, bottom right; a carried-at-the-side pose would be off screen), set through `META["item"]["scene"]`
  (build.py copies item keys into the entry, so the override survives a rebuild).
- Budget: the first build was 6,292 tris; grille discs lost their bevel, rings went to 28 sides and the
  ten keys to one bevel segment. Sheet: `production/qa/evidence/wsR-boombox-sheet.jpg` (no reference cell).
- Review fix: the grilles read as flat black; the perforation art got lighter metal and bigger holes.

## Food, drinks and books (workstream FOOD, Nov 3 2026)

**Asked for (brief):** very detailed hand items, because you hold them up close: Corn Dog 7's crinkle fries and
lemonade in its own packaging style; Woolworth's 1995 lunch counter hot dog, hamburger, fries and coffee;
B. Dalton books (Moby Dick with its real title; four invented titles and covers, more detailed than T2's
paperback, one book model reused); Cuco's beer, margarita, a visibly fancier top-shelf margarita, a Mardi
Gras doubloon stamped with the neon-sign logo, a coupon for one free top-shelf margarita; and Cuco's back bar
as a kit of fixtures (no prepared drinks) with a placement note for workstream CUCOS.

**Ids.** The model ids follow the pipeline's `bl_<store>_<thing>` (so they land in the shared `items` pack,
`tools/shared_packs.json` `models/bl_*`); the **item ids are the brief's**, set with `META["item"]["id"]`
(build.py copies item keys over the default). Items are in their own file, `data/items/food.json`
(`META["item_file"]`), with no `place`: the store workstreams (SHOPS, CUCOS) put them on counters.

| Item id | Model | Class | Notes |
|---|---|---|---|
| `cd7_crinkle_fries` | `bl_cd7_crinkle_fries` | hand | 18 crinkle-cut fries as geometry (the crinkle is in the cross-section), paprika specks, a printed fry cup |
| `cd7_lemonade` | `bl_cd7_lemonade` | hand | printed cup, clear lid (its own transparent material), cloudy lemonade, ice, a lemon wheel, navy-striped straw |
| `wl_hot_dog` | `bl_wl_hot_dog` | hand | grill-striped frank in a split bun (crumb on the cut faces), mustard, relish, pickle spear, chips, white plate with a thin red line |
| `wl_hamburger` | `bl_wl_hamburger` | hand | heel, patty, melting American cheese, pickle chips, tomato, leaf lettuce, sesame crown (seeds as geometry and texture), pickle spear |
| `wl_fries` | `bl_wl_fries` | hand | straight-cut fries criss-crossed in three layers, salt, a pleated soufflé cup of ketchup |
| `wl_coffee` | `bl_wl_coffee` | hand | thick diner mug of black coffee on a saucer, teaspoon, a generic SUGAR packet |
| `bd_moby_dick` | `bl_bd_moby_dick` | hand | navy book cloth (weave in the normal map), gold-foil stamping (metallic through a mask), blind-stamped back, red ribbon, B. Dalton price sticker |
| `bd_adventure_book` | `bl_bd_adventure_book` | hand | invented: THE SUNKEN COMPASS, J. R. Thibodeaux; dust-jacketed hardcover |
| `bd_chills_book` | `bl_bd_chills_book` | hand | invented: CHILL HOLLOW #4 *The Thing in the Cane Field*, Marguerite Breaux; mass-market paperback |
| `bd_mars_book` | `bl_bd_mars_book` | hand | invented: DUST OVER THARSIS, Dana Okonkwo-Hale; trade paperback |
| `bd_dark_room_book` | `bl_bd_dark_room_book` | hand | invented: SAFELIGHT, Claire Lanoux (a darkroom thriller; "The Dark Room" itself is a real 1995 title, so avoided); jacketed hardcover |
| `cu_beer` | `bl_cu_beer` | hand | glass mug of draft lager, head, condensation beads, Cuco's coaster |
| `cu_margarita` | `bl_cu_margarita` | hand | the house drink: stepped margarita glass, frozen lime, salt rim, lime wheel, green straw, coaster |
| `cu_top_shelf_margarita` | `bl_cu_top_shelf_margarita` | hand | fancier: hand-blown glass with a cobalt rim and a green saguaro stem, on the rocks (amber), coarse salt, lime and orange wheels, two black straws, coaster |
| `cu_doubloon` | `bl_cu_doubloon` | hand | 39 mm anodized-gold aluminium doubloon (`design/research/mardi-gras-doubloons.md`): the sign's cans as raised walls with tube runs inside, the MEXICAN CAFE pill with sunk letters, bead borders; reverse MARDI GRAS / 1995 and a chili pepper |
| `cu_coupon` | `bl_cu_coupon` | hand | card-stock leaf: the sign, FREE / TOP SHELF MARGARITA, papel picado, a drawn cactus-stem glass, torn perforation; no other words (CUCOS writes those) |

Back-bar fixtures (no item entries): `bl_cu_bb_bottles_a`, `bl_cu_bb_bottles_b`, `bl_cu_bb_taps`,
`bl_cu_bb_stemrack`, `bl_cu_bb_glasses`, `bl_cu_bb_service` (all small_fixture). Placement:
`design/storefronts/cucos-back-bar-kit.md`. Their `.glb.import` is set to static lightmaps (`light_baking=2`,
0.05 m texel) like the lion.

**Sources and guesses.** No photo of any of this food, drink, book or bar exists in the repo or on `refs`
(`refs/INDEX.md`); every item is a period type and says so in its script header.
- *Corn Dog 7's packaging style* comes from the store itself: the awning's taxi yellow and navy and its
  pinstripe (`paint_corn_dog_7.py`), and **the store's own traced lettering** (`tools/stores/cd7_letters.json`:
  CORN DOG 7, "seasoned fries", "fresh lemonade", with the two hand strokes the awning adds), rendered with
  cairosvg (`_food.svg_letters`). Guessed: that the stand used printed cups at all, their shapes and sizes.
  Prices from the stand's menu box (fries and lemonade .99, themselves guesses).
- *Woolworth*: white china as in the shop's own food photos (`woolworth/paint.py food()`); prices from the
  back bar's menu strip (`paint_lunch.py`: HOT DOG $1.29, COFFEE 59¢; no burger or fries price, so none).
  Guessed: the plate's thin red line, everything on the plates.
- *B. Dalton*: Moby-Dick's title and author are real (public domain); its edition, cover design and publisher
  ("BAYOU CLASSICS") are invented. The four other titles, authors, blurbs, quotes and publisher marks are
  invented and are **proposals for Steven** (constants at the top of each script). The price stickers carry
  B. Dalton's own name (the tenant's mark). Prices are guesses for 1995.
- *Cuco's*: the coaster, coupon and doubloon use the restaurant's own neon sign as traced in
  `tools/stores/signs/cu_sign.json` (cans, tube runs, MEXICAN CAFE letters, the cabinet), drawn by
  `_cucos.py`. The doubloon follows the research note's proposals; a Cuco's doubloon is a plausible
  invention (no restaurant doubloon was found). Its reverse words (MARDI GRAS / 1995) are a placeholder.

**Shared code** (`tools/blender/assets_src/`): `_food.py` (cd7 lettering, cylindrical wraps, china, paper,
crusts, the fry generator with straight or crinkle sections, plane cuts that fill the cut face with a second
material, oval plates), `_book.py` (the book model, cover helpers, B. Dalton's sticker), `_cucos.py` (the sign
as print and as a height map, coaster, salt rims, citrus wheels), `_bar.py` (bottles with invented labels,
glass profiles).

**The book model** (`_book.py build_book`): one swept cross-section for the whole case (front board, a
hinge groove, the rounded spine, back board, the boards' insides), extruded along the book and capped, with an
angle-limited bevel; the page block is its own sweep with a concave fore-edge; "hard" adds 2.6 mm boards,
3 mm squares, headbands and an optional ribbon; "paper" a 0.55 mm wrap flush with the pages and scored hinges.
Covers are painted per book (front, back, spine) and mapped by position; gold foil is a mask driving metallic
and roughness and a small inward bump. 850–1,650 tris a book (T2's paperback: 256).

**Pipeline addition:** `META["icon_view"] = (yaw, elevation)` for the 256 px icon (books, the coin and the
coupon lie flat and read from above).

**Review fixes** (each found on a sheet or the Godot shot, fixed and rebuilt):
- The printed cups' wraps faced sideways (the angle mapping's seam): `_food.wrap_mat` now centres the image on
  the front, wrapped with FRACT; the lettering was too big to read round a cup and was halved.
- The fries read as pale wooden sticks: deeper golden ramp, less fanned out.
- Hot dog: the bun closed over the frank and read as skin; the pickle crossed the plate's rim. Halves opened
  further, the frank raised, a browner crust, a bigger plate well.
- Hamburger: a 30 mm bottom bun and an oversized lettuce hid the patty; thinner heel, bigger darker patty,
  smaller lettuce, subtler veins. Over budget twice (6,030): fewer bun segments and seeds.
- The Woolworth fries' heap core showed under the plate: cut at the plate surface.
- Moby-Dick's first whale read as a banana: redrawn as a sperm whale (square head, jaw, flukes, spout).
  Page edges looked stained: the dirt layer is much fainter.
- The tap tower's frost band was a flat white sleeve: now a mottled, partly metallic frost.
- Blender's turntable shows liquids under transparent glass as washed-out pink; the baked albedo and the Godot
  shots are correct (golden beer, amber top-shelf), so this is the preview, not the asset.

**Evidence:** `production/qa/evidence/wsFOOD-<model id>-sheet.jpg` (turntables, full quality) and the unbaked
Godot shots `wsFOOD-godot-food.jpg` (Corn Dog 7 and Woolworth), `wsFOOD-godot-books.jpg`,
`wsFOOD-godot-cucos.jpg`, `wsFOOD-godot-backbar.jpg` (the kit arranged as a back bar).
