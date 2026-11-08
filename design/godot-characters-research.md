# Characters: start over without the editor (research spike CHAR-RESEARCH, Nov 8 2026)

Branch `ws/char-research` (from `main` f96a04b). **No code changed.** This note, the options sheet
(`design/godot-characters-options.md`) and one test render (`production/qa/evidence/wsCHAR-*.jpg`).

## The recommendation in five lines

1. **Pipeline: a fixed cast built by script on MakeHuman's CC0 hm08 data, in headless Blender, one baked `.glb`
   per person** (option B below). No editor, no runtime shape keys, no sliders, no runtime dressing.
2. **Why this one:** it is the only option that gives realistic people with a real face rig for free and by script.
   The CC0 data already in MPFB2's repo has **34 expression units per ethnicity** (eye closure L/R, mouth open,
   smile, brows …) and eye joint cubes (MPFB's `default` rig has `eye.L`/`eye.R`/`jaw`), and it plays the Mixamo clips through the rig we already use.
3. **First five:** the RadioShack, Great American Cookie, Auntie Anne's and Spencer's attendants and the Cuco's owner.
   Steven gives one line each (age, look, build, hair, 1995 or 2026). Order: RadioShack (proves the pipeline),
   then the Cuco's owner (the TALK close-up), then the other three.
4. **Delete** the editor and both avatar systems: `scripts/chars/*` except `char_pack.gd`'s mount logic,
   `char_body.gd`, `avatar_creator.*`, `avatar_look.gd`, `avatar_body.gd`, `avatar_bodies.json`,
   `avatar_recolor.gdshader`, `models/ubc/` (54 MB) and the shape sliders.
   **Keep** `npc_rig.gd`, `npc_body.gd`, `npc/anims.res` (71 clips), the crowd (`npcs.gd`, Mixamo shoppers),
   `npc_warmup.gd`, and `avatar.gd`'s third-person camera and gaits (moved into a smaller script).
5. **The bugs can't come back if** each person is one file, one id and one save key; every view (world, menu
   portrait, talk camera) makes the body through one function; and the files arrive before the world is
   shown, so there is never a fallback body to swap.
   The test render (`wsCHAR-radioshack-before-after.jpg`) shows the jump, and also what is still unproven.

---

## 1. Root cause of the two-body and overlay bugs (read from the code, not run)

**There are two avatar systems and two saved records for one player.** V's (Nov 1): `AvatarBody`, a
Mixamo crowd body recoloured, saved as `localStorage["mall-avatar-1"]` (`scripts/avatar_look.gd` `KEY`).
B2's (Nov 2 to 4): `AvatarChar`, a MakeHuman and later UBC body dressed from a preset, saved as
`localStorage["mall-avatar-preset-1"]` (`scripts/chars/char_preset.gd` `PLAYER_KEY`). Which one a
given view shows is decided **separately in four places**, each by `AvatarChar.available()` (*are the
character pack's bodies mounted right now?*) at the moment that view is built:

| Where | When it decides | Re-decides later? |
|---|---|---|
| `scripts/avatar.gd:84`, the body in the world | `_ready`, at wing load | yes: `chars_ready()` swaps it when the pack mounts |
| `scripts/menu/portrait.gd:58`, the MAIN tab | each time MAIN is built | no hook; only on the next rebuild |
| `scripts/menu/menu.gd:590` `_make_creator`, the editor | the first time Edit opens | **never**: `_creator` is kept |
| `scripts/attendants/attendant.gd:50`, the attendants | `_ready` | yes: `chars_ready()` |

On the web the character pack (`chars`, 53 MB) is fetched **after** the mall is running
(`char_pack.gd`, `web/shell.html` "CHARS"), so for the first seconds to minutes of every load (longer on a
phone) `available()` is false and then becomes true. A wing or year crossing reloads the page, so this happens
at every crossing.

### a. The editor's save/apply path: **the main cause** of "two bodies for one player"
- **Nov 4 recording** (Demo 51, before the CHAR-EDITOR fix): `portrait.gd` *always* built V's `AvatarBody`
  in V's look. V's look names a Mixamo body (`body` = Ch01 … Remy). The dark polo, blue shorts and tattoos
  are a Mixamo cut and texture: the UBC and MakeHuman sets have no shorts and no tattoos. Meanwhile the world
  wore `AvatarChar` from the B2 preset: `AvatarChar.from_look` → `top_tee` + `bot_jeans` in V's colours, the
  purple tee and jeans. **Two records, two bodies, each view reading a different one.**
- **Demo 52's fix** (`design/godot-character-editor.md` §1) made the portrait test `available()`, but it
  is still a separate decision. If MAIN is built before the pack mounts, MAIN shows V's Mixamo body while the world
  switches to the preset a moment later. Worse, if Edit is opened before the mount, `_make_creator` makes **V's
  creator**, which saves to `mall-avatar-1` only. The world, once on `AvatarChar`, reads `preset_for(look)`, which
  **prefers the preset** (`avatar_char.gd:41`). So an edit in that window never shows in the world.
- Verdict: the bug lives in the data model, not in one line. Two save keys, two body classes and a body choice made
  per view and per moment. No patch to one view fixes it.

### b. A scene instanced twice: **not found** as a lasting duplicate
Every path frees the body it replaces: `NpcBody.set_skin` (`queue_free` of the old skin), `avatar.gd
chars_ready()` (`old.queue_free()`), `attendant.gd _make_preset_body` (`body.queue_free()`), and `menu.gd
_build` frees `_root` with the old portrait. Both bodies exist together only for the one frame before a `queue_free`
lands. `npc_warmup.gd` stands every Mixamo skin in front of the camera, but behind the loading card. One latent
fault: `chars_ready()` calls `old.get_parent().add_child(body)`, which errors if the pack mounts before the deferred
`add_child` of the first body has run. That is a crash, not an overlay. **Not verified by running.**

### c. The rig/body swap after a load screen: **the cause of the "pixelated character over the original"**
After every load screen the world avatar starts as V's `AvatarBody`: a 5.8k–10.5k-triangle Mixamo body with a
compressed photo texture, recoloured by `avatar_recolor.gdshader`'s per-island means, which looks blocky up
close. When the pack mounts, `chars_ready()` builds the `AvatarChar` in its place. On a phone the two can sit
on screen together for a frame. The new skin first stood in its bind T-pose until it walked (fixed Nov 4 by
`clip = ""`). So the player sees one character, then a different one appears where it stood. The Nov 2 report,
"the default bald avatar with the new one drawn on top", is the same pair: Ch01 (bald, V's default) and the
preset. **Confidence:** high that the swap is what is seen. Medium on "drawn on top": that wording needs a frame-by-frame
recording to tell an overlap from a quick swap. **Repro to confirm:** web build, phone throttling, third person,
cross a wing, record 2 s after the card lifts.

**What any new pipeline must rule out:** (1) more than one saved record per player; (2) any view choosing
its own body class; (3) a fallback body shown and swapped later; (4) runtime assembly (dress, fit, bake) that
can leave a body half-made for a frame.

---

## 2. Options

Measured in this repo (glTF accessors and `npc/skins.json`; nothing measured on an iPhone):
- Mixamo crowd bodies (Ch01 … Remy): **5,765–10,494 tris**, 1–3 surfaces, 1 texture each.
- Today's UBC attendant (body 14.3–15.1k + top 2–3.4k + bottom 2.1–2.2k + hair 0.8–3.3k + sneakers 1.4k +
  extras): **≈ 22–26k tris, 8–12 surfaces (draw calls), 32–34 blend-shape targets on every piece** (baked for
  NPCs, live for the avatar and the editor preview). That is 2.5–4× a Mixamo shopper, and why skinned characters
  are the phone's main cost.
- Budget proposed for every option: a **talk-close person ≤ 15k tris, 2–3 draw calls** (skin, clothes atlas,
  hair with alpha); a **crowd LOD ≤ 6k tris, 1–2 draw calls**; textures 1024² (talk heads 2048² for the head
  island only); ETC2/ASTC on phones.

### A. Keep the Mixamo bodies, rebuild heads, hair and clothes in Blender; 8–12 fixed characters, no editor
- **What:** the 19 Mixamo characters (`npc_src/`, Steven's Oct 15 downloads) as bodies. In Blender, replace
  each head and hair with our own, repaint or remodel the clothes, then bake one `.glb` per person.
- **Licence / cost:** free. Mixamo's terms allow the characters in a shipped game but not redistribution
  of the source files, so the sources stay off the repo (as today, `production/npc-sources.md`).
- **Per character on iPhone:** 6–10k tris as is, plus a new head of about 3–5k. One or two textures, 2–3 draw calls. The cheapest option.
- **Clothes / hair:** baked per character. Mixamo clothes are part of the body mesh, so a new outfit means
  remodelling the torso.
- **Face rig:** **none.** Mixamo characters ship without blend shapes or eye bones (only `mixamorig:Head`, and
  on some `HeadTop_End`). Every face shape would be sculpted by hand on 19 different topologies.
- **NPC / player:** same files and rig as the crowd. The player picks one of the cast.
- **Claude in the cloud:** feasible for repainting. A head swap means cutting at the neck seam and re-weighting on
  every body, each one different. Slow to iterate and hard to check by script.
- **Bug risk:** low (fixed files, no assembly).
- **Look:** the photo-textured Mixamo faces read as stock and can't talk. **Fails the TALK job.**

### B. MakeHuman hm08 (CC0 data) in headless Blender, a fixed cast, one baked file per person (**recommended**)
- **What:** the MakeHuman base mesh and targets (CC0, from MPFB2's repo, already fetched by
  `tools/blender/characters/fetch_mh.sh`; numpy reader `mh.py` already written). Per person: macro values
  (sex, age, weight, muscle, height, proportions, African / Asian / European mix) plus face targets
  (nose, chin, cheeks …), our own card or painted hair, garments modelled on that body, a per-person painted albedo
  in a re-unwrapped UV (face-first), **the expression units baked as named blend shapes**. Rig: MPFB's
  Mixamo-named rig and weights (CC0; B1 proved the clips play through `NpcRig`). Output: one `.glb` per person
  with LOD0 and a crowd LOD.
- **Licence / cost:** free. The data under `src/mpfb/data` is CC0 (`LICENSE.ASSETS.md`); MPFB's GPL code is
  not used (as in B1). MPFB's separate **visemes01/02 and faceunits01 (ARKit 54)** shape-key packs are
  community asset packs: check each licence before use (not done here). The 34 units in the repo are enough to
  start.
- **Per character on iPhone:** hm08 is 13,380 body vertices (≈ 26k tris whole). Deleting the faces hidden under
  clothes (torso, upper legs) and decimating away from the face gives **≈ 12–15k LOD0 and ≈ 5k crowd LOD**
  (estimate, not built). Draw calls 2–3 (skin, clothes atlas, hair). Textures: one 1024² clothes atlas,
  one 1024² or 2048² skin, one 512² hair strip.
- **Clothes / hair:** **baked per character** (no swapping at runtime). They are built in Blender on the final body,
  so there is no fitting step in the game. The proxy-binding code (`ubc_common.Binding`) still helps in the
  generator. Short styles (fade, crop, buzz) are painted scalp plus a thin shell, as in the test render.
  Long styles need hair cards (strips on guide curves, a baked strand atlas). That part is **unproven** and
  is the main risk.
- **Facial rig (TALK):** the CC0 expression units: `eye-left/right-closure` (blink), `eye-*-slit`,
  `mouth-open`, `mouth-corner-puller` (smile), `mouth-pursing`, `mouth-compression`, the brow units and more,
  per ethnicity (african / asian / caucasian), as sparse vertex offsets on hm08. Baked as named glTF morph
  targets they give blink, a smile and a simple open/close lip flap. MPFB's Mixamo rig (52 bones) has no eye
  bones, but its `default` rig (163 bones) places `eye.L`, `eye.R` and `jaw` from the mesh's joint cubes
  (`joint-l-eye`, `joint-r-eye`, `joint-jaw`). The build adds those three under `mixamorig:Head`. The clips
  don't touch them, so the eyes can follow the player. Visemes come later from the packs above, or are built from the
  mouth units.
- **NPC / player:** one file per person. Attendants, the player (one of a few cast members, or
  their own fixed character) and featured NPCs all load `res://cast/<id>.glb` through one function. The crowd
  stays Mixamo until there are enough cast LODs.
- **Claude in the cloud:** fully scripted (`pip install bpy` + numpy). Each person is a short data file plus
  the shared build script. Turntable and close-up sheets render in Cycles on the CPU in about a minute per frame,
  so the loop is "change a value, rebuild, look". This session built the test render this way.
- **Bug risk:** low if the rules in §3 hold. B1's weak points (decimated 3k face, shell hair, the "neutral" average
  male) came from the *editor's* need for one body that fits every slider. A fixed cast has none of that.
- **Look:** realistic proportions and every age, build and ethnicity Houma needs (Cajun, Black, Houma
  Nation, Vietnamese), stylised through the paint (a flat painted albedo with no pores, simplified tones).
  See the render: the face reads as a person.

### C. A CC0 stylised pack (Quaternius Universal Base Characters, Kenney), adapted
- **What:** what the game uses since Nov 4 (UBC, CC0), or Kenney's Animated Characters / Mini characters
  (CC0, very low-poly, toy-like). Quaternius's Modular Character Outfits pack fits UBC. Synty-style paid packs
  (POLYGON City, Town) only noted: they are flat-shaded low-poly and would clash with the photo-based mall.
- **Licence / cost:** CC0, free. The UBC Source tier is on Patreon. Kenney's packs are CC0.
- **Per character on iPhone:** UBC as built today is 22–26k tris and 8–12 draw calls. Baked and merged it would be
  about 20k and 2–3. Kenney's are about 1–2k.
- **Clothes / hair:** UBC has 6 free hairstyles and outfits from the paid tiers. Swappable or baked.
- **Facial rig:** **none.** UBC has rigid `eyes` and `brows` meshes on the head and no face blend shapes
  (checked: its 32 targets are our build sliders). Kenney has none either.
- **NPC / player:** works, as today.
- **Claude in the cloud:** fully scripted (done in CHARS-UBC).
- **Bug risk:** low only without the editor. The two-body bug came from the editor, not from UBC.
- **Look:** this is the set Steven just judged "not good or compelling". The kit's superhero
  base softened into normal builds, six hairstyles for every person, no faces that can talk. **Not
  recommended.**

### D. VRoid / VRM toon characters with Godot's VRM addon
- **What:** characters made in VRoid Studio (Pixiv; free; Windows / Mac GUI), exported as VRM 1.0, imported by
  **godot-vrm** (V-Sekai, MIT, Godot 4; MToon toon shader, VRM expressions as blend shapes, look-at).
- **Licence / cost:** free tool. Each model carries its own VRM licence fields (set by the maker).
  VRoid's sample and booth.pm assets vary: check each.
- **Per character on iPhone:** VRoid exports run about 20–70k tris with many materials unless reduced in the
  exporter (it has a reducer); MToon is heavier than our standard material. Achievable at 15–25k and 4–8 draw calls.
- **Clothes / hair:** baked per character (VRoid's own garment and hair-card system, good hair).
- **Facial rig:** **the best of the four**: VRM's standard expressions (blink, aa / ih / ou / ee / oh visemes,
  joy, angry …) and eye bones, which the addon maps.
- **NPC / player:** works, through a VRM → our rig name map (VRM humanoid bones map to Mixamo names).
- **Claude in the cloud:** **no.** VRoid is a GUI on Windows / Mac. Steven would make every character by hand,
  and Claude could only import them. The VRM add-on for Blender (MIT) can author VRM by script, but then the
  body still has to come from somewhere (B).
- **Bug risk:** low (fixed files). The godot-vrm addon is a dependency to keep updated (a maintained fork exists for 4.3+).
- **Look:** anime. Wrong for a realistic 1990s Houma mall. **Not recommended**, though VRM's expression set is
  a good list to copy for B's face shapes.

### Which fits "realistic-but-stylised 1990s Houma mall" best
**B.** A has no faces to talk with. C is the current look, rejected, and has no face rig. D is the wrong style and not
buildable by Claude. B is free, CC0, built by script in this cloud box, covers every age and ethnicity, ships a
face rig, uses the existing rig and clips, and its weak points (hair, clothes) are things we already know how to
script. The stylising is a matter of paint and shading, not mesh.

---

## 3. The recommendation in detail

### The pipeline (B), and the rules that keep the bugs out
1. **One person = one data file + one baked file.** `tools/blender/cast/<id>.json` (macro values, face
   targets, skin colour, hair style, garments and colours, period) → `tools/blender/cast/build.py` →
   `cast/<id>.glb` (LOD0 + LOD1, morph targets `blink_L`, `blink_R`, `smile`, `jaw_open`, `brow_up`, … , eye
   bones). No runtime dressing, fitting or baking.
2. **One loader.** `Cast.body(id) -> NpcBody` is the only way any view makes a person: the world, the
   menu portrait, the talk camera and attendants. The portrait takes the same id, never its own class.
3. **One save key for the player:** `mall-player-2 = {"cast": "<id>"}` (plus name and money, as today).
   On first run the old keys `mall-avatar-1` and `mall-avatar-preset-1` are read once for nothing but the
   name, then deleted.
4. **No fallback body.** The cast files a wing needs go in that wing's pack (or a shared pack that is
   awaited *behind the loading card*, as `npc_warmup.gd` already waits). If a file is missing, the person isn't
   shown and an error is logged. Never a stand-in that swaps later.
5. **A test that counts:** after load, menu open/close, a reload, a wing and a year crossing, a time-travel trip,
   exactly one `Skeleton3D` under the player group, and its `cast` id equals the saved one. The portrait's id matches.

### The first five (Steven's attendants)
Each needs a line from Steven: age range, build, skin, hair, what they wear, the year. Per CLAUDE-CLOUD.md
Claude doesn't invent them; the test render's man is a **PLACEHOLDER** to show the pipeline.
1. **RadioShack** (1995): first, because the store and the current attendant are the before/after.
2. **The Cuco's owner**: second, because it is the TALK close-up (face shapes, eye bones, lighting with TALK).
3. **Great American Cookie** (1995, and the 2026 one if the person is the same).
4. **Auntie Anne's** (2026).
5. **Spencer's** (2026; the Demo 52 note "the talk camera frames the face very close" makes this a good face test).

### Order of work
1. **Strip** (one session): delete the editor and both avatar systems (below). The player becomes a fixed default
   cast member, attendants their Mixamo fallback. Run the counting test from rule 5. *This alone fixes the
   two-body bug.*
2. **Build script** (one or two sessions): hm08 → per-person data → body, face UV, painted albedo, eyes,
   brows, short hair, a shirt + trousers + shoes set, expression morphs, eye bones, hidden-face removal,
   LOD1, export. Check in Godot: clips play, morphs animate, cost on the owner's fps readout on an iPhone.
3. **RadioShack**, then the Cuco's owner with TALK, then the other three.
4. **Hair cards** for the first long style a person needs (the risk item: if scripted cards stall,
   Hair Tool, $52, is the fallback named in `design/research/character-pipeline-2026-11.md`).
5. Later: featured shoppers from the same script; the crowd stays Mixamo.

### Delete
- `scripts/chars/char_editor.gd`, `char_owner.gd`, `char_fit.gd`, `char_preset.gd`, `avatar_char.gd`
  (2,500 lines), `scripts/char_body.gd` (468), `data/characters/*.json` (presets; the attendants'
  intended looks move to the cast data), `data/characters/_wardrobe.json`.
- `scripts/avatar_creator.gd` / `.tscn`, `avatar_look.gd`, `avatar_body.gd`, `avatar_bodies.json`,
  `avatar_recolor.gdshader`, `spatial_char_region.gdshader`, `tools/avatar/`, `tools/qa/avatar_sheet.gd`,
  `char_*_test.gd` that test the editor.
- `models/ubc/` (54 MB) and `tools/blender/ubc/`. The B1 tools under `tools/blender/characters/` stay
  only as far as `mh.py` (the hm08 reader) and `fetch_mh.sh`, reused by the new build. The rest goes.
- The menu's AVATAR / Edit rows and the shape sliders; the owner's NPC editor (K).
- `menu/portrait.gd` stays, rewritten to call the one loader.

### Keep
- `npc_rig.gd` (retargeting; the cast uses the same Mixamo bone names), `npc_body.gd` (`set_skin`, clips,
  gaits), `npc/anims.res` + `anims.json` (71 clips: walk, idle, talking, gestures), `npc_warmup.gd`.
- `avatar.gd`'s third-person camera, boom, gaits, view switch and held item (about 300 of its 486 lines). Its
  body choice goes.
- `npc_shirt.gd` (the shirt words on the crowd): keep if Steven still wants words on shoppers. On cast
  members, words are painted into the clothes atlas at build time instead.
- `attendants.json` and `attendant.gd`: `"look": "cast", "cast": "<id>"` instead of `"preset"`.

---

## 4. The test render

`production/qa/evidence/wsCHAR-radioshack-before-after.jpg`, laid out as **left:** the current RadioShack
attendant in game (`wsSHOPS-web-unbaked-radioshack-line.jpg`, Nov 3: the MakeHuman B1 body on the
editor's preset; today's UBC body is the same preset on the kit body, `chars-ubc-mall-w1-presets-unbaked.jpg`);
**middle:** a PLACEHOLDER attendant built with pipeline B, neutral; **right:** the same with the
CC0 expression units applied (smile + mouth open + brows), the TALK face rig working.

How it was made (headless `bpy` 5.2.3, Cycles CPU; the script is kept out of the repo per the brief, in the
session scratchpad; its method is the build step above):
- hm08 + MakeHuman macros (male, 31, African 0.85 / European 0.15, muscle 0.55, weight 0.55), body cut at the chest;
  the expression units as above.
- A cylindrical face-first UV (the default hm08 UV gives the face only ~160 px of 2048) and an albedo painted
  by rasterising a per-point colour function: skin tone variation, lips, brows, stubble, a short fade hairline.
- Eyes as glossy spheres with a painted iris, MakeHuman's eyelash helpers, the hair as a thin shell over the
  painted scalp, a white cotton shirt shell with a collar, and a blank name tag (no words, no logo).
- Lighting meant to resemble the mall: a warm overhead fluorescent key, a cool fill, a warm rim from a sign.
- **No subsurface scattering**: only albedo, normal and roughness, which Godot's Compatibility renderer can draw. The game will
  look flatter than Cycles (no path tracing); the face, proportions and paint carry over.

**What it shows:** a believable adult face and skull at talk-camera distance (proportions, nose, brows, ears,
eyelashes, eyes with irises), a clean shirt with no patchwork or sawtooth, and a face rig that works with no
sculpting: the right-hand frame is the same mesh with five CC0 units dialled in. The left frame's flaws are the
editor pipeline's (shirt panels cut from the skin, a helmet hair shell, flat dead eyes).

**What it does not show (honest limits):**
- **Not in Godot.** Cycles path tracing adds bounce light (the white shirt brightens the chin) that the
  Compatibility renderer won't. The face will look flatter in game until TALK's lighting is in.
- **Hair:** only a short fade, painted on the scalp. Long hair cards are untested in this pipeline.
- **Art direction:** the lips read a little grey and full, the eyes slightly glassy, and the skin a bit
  smooth. That is paint, tuned by numbers in the data file, about an hour per person with Steven looking.
- Not measured: tris after hidden-face removal and LOD, or the phone cost. The body was cut at the chest
  for the render.

Time: about 1 hour 10 minutes from `pip install bpy` to the final frame (mostly the download and four fix passes:
a black texture, overlapping UVs, the lip line, the collar), under the brief's 2-hour stop. Each frame renders in
about 1 minute on this box's 2 CPUs (128 samples).

## Open questions for Steven
1. B: yes or no? And does the player get one fixed character, or pick one of 3–4 cast members (no editor
   either way)?
2. One line per attendant for the first five (age, build, skin, hair, clothes, year).
3. Shirt words on shoppers: keep?
4. Hair: is it acceptable to start with short styles, painted and shelled, and do the first long style
   once one of the five needs it?

## Sources
- MPFB2 data (CC0, `LICENSE.ASSETS.md`), pinned commit `6ff1eb35`: `src/mpfb/data/targets/expression/units/*`
  (34 units × 3 ethnicities, counted in this session), `rigs/standard/rig.mixamo.json`, `3dobjs/base.obj`.
- MPFB face shape-key packs (visemes01 22 keys, visemes02 15 keys, faceunits01 54 ARKit keys):
  [MPFB 2.0.15 release notes](https://static.makehumancommunity.org/mpfb/releases/release_2015.html),
  [MPFB lip sync docs](https://static.makehumancommunity.org/mpfb/docs/lipsync.html). Licences not checked.
- godot-vrm: [github.com/V-Sekai/godot-vrm](https://github.com/V-Sekai/godot-vrm) (MIT per the Asset Library;
  VRM 1.0 import, expressions as blend shapes).
- Kenney / Quaternius licences: [cinevva guide, 2026](https://app.cinevva.com/guides/free-rigged-3d-character-models)
  (Kenney CC0), [Quaternius Universal Base Characters](https://quaternius.com/packs/universalbasecharacters.html) (CC0).
- Earlier research: `design/research/character-pipeline-2026-11.md` (Nov 4: CC5, MetaHuman, Humanizer, AI
  texturing; still valid, not repeated here).
- `npc-review-2026-10-16.md` and `npc-plan-2026-10-15.md` are not in the repo. The phone-cost point here
  comes from the brief's summary and this repo's triangle counts. **Steven: paste them if they say more.**
