# The cast: fixed people, one file each (workstream CHAR-BUILD, Nov 8 2026)

Branch `ws/char-build` (from `main` f96a04b). Specs: `design/godot-characters-research.md` §3 (pipeline B,
branch `ws/char-research`) and `design/godot-characters-sources.md` (branch `ws/char-sources`, the Rocketbox
converter). Paths are under `prototypes/godot-mall/project/` unless they start with `design/` or `production/`.

## Steven's decisions (Nov 8, in order)

1. Pipeline B; the player picks one of 3–4 cast members (no editor); short hair first; shirt words stay on the crowd.
2. "Stop painting the skin and hair by formula. Use the MakeHuman CC0 asset library … as the base and only adjust
   tone and detail in paint." → done (the MakeHuman path below, now the fallback).
3. RadioShack (MakeHuman version) "approved as a proposal, pending a side-by-side with the CHAR-SOURCES job".
   Changes for it and the Cuco's owner: eyes with a visible iris, a catchlight and slightly more open lids; hair
   with a softer silhouette than short02's block; skin warmed a touch with subtle variation (cheeks, nose).
   "Use the 1.2 system asset pack … from the makehumancommunity GitHub repos." → see "MakeHuman 1.2 pack".
4. **4 PM: switch the body source to Microsoft Rocketbox (MIT)**, using CHAR-SOURCES' converter approach; keep
   everything that isn't the mesh (one data file + one `.glb` per person, `Cast.body(id)`, LOD0/LOD1, the morph
   naming, hidden-face removal, the 1024 hair/brow atlas rule); pick the closest Rocketbox person, convert,
   repaint clothes to the uniform (no logos), build edits along normals where his line asks, then tone tweaks.
   MakeHuman path kept as a fallback module. Show 2–3 candidates per role first; add Rocketbox to the credits.
5. Picks (from `production/qa/evidence/wsCAST-rocketbox-candidates.jpg`): RadioShack **Male_Adult_08**,
   Cuco's owner **Male_Adult_07**, Great American Cookie **Female_Party_02**, Auntie Anne's **Male_Adult_16**,
   Spencer's **Female_Adult_11**.
6. TALK's `scripts/npc_look.gd`: prefer eye bones and blink morphs when a body has them, fall back to the
   iris-texture slide; keep TALK's limits and timing → done (below).

## What a cast member is (unchanged by the source)

| File | What |
|---|---|
| `tools/blender/cast/<id>.json` | the person: source (Rocketbox person + build edits, or MakeHuman macros), uniform repaint, generated pieces, tone, what Steven said, what is proposed |
| `cast/<id>.glb` | skeleton + `<id>_lod0` (+ `<id>_lod0_face` on Rocketbox people) + `<id>_lod1`; textures embedded (Rocketbox) or beside it (MakeHuman) |
| `cast/<id>.json` | the build record the loader reads: `hips`, `height_m`, `morphs`, `jaw_open_deg`, `eyes`, `lod_switch_m`, counts |

**The loader:** `scripts/cast.gd`. `Cast.body(id) -> NpcBody` is the only way any view makes a cast person;
unknown id → `null` + error, never a stand-in. `Cast.set_morph`, `Cast.set_mouth` (morph + jaw bone by the
recorded angle; 0° on Rocketbox, whose `JawOpen` already moves the jaw), `Cast.aim_eyes`, `Cast.eye_dir`,
`Cast.lod_meshes` / `Cast.lod_mesh` (the LOD's morph-carrying mesh), `Cast.ids`, `Cast.meta`.
Eye / jaw bones are composed with their rest (Rocketbox's eye rests are not identity).

**Morphs (both sources, same names):** `blink_L`, `blink_R`, `squint_L`, `squint_R`, `eyes_wide`, `smile`,
`jaw_open`, `brow_up`, `brow_down`, `brow_inner_up`, `brow_up_L`, `brow_up_R`, `mouth_pucker`, `mouth_press`,
`mouth_wide`, `mouth_funnel`, `frown`, `lip_upper_up`, `lips_part`, `sneer`. Rocketbox people also keep the 15
visemes (`viseme_Sil` … `viseme_U`) for lip sync. The raw 52 ARKit shapes are folded into the 20 names and not
shipped: Godot stores blend shapes densely, so every shape costs memory per vertex; the face mesh carries them,
the body none. (Steven: say if TALK wants the raw ARKit set back; it is one line in `rb_cast.py`.)

## Source 1 (default): Rocketbox — `tools/blender/cast/rocketbox/`

```bash
# once: Blender module (see design/godot-characters-sources.md "The converter") and the Rocketbox people
git clone --filter=blob:none --no-checkout https://github.com/microsoft/Microsoft-Rocketbox .scratch/rocketbox
cd .scratch/rocketbox && git sparse-checkout init --no-cone \
  && git sparse-checkout set '/Assets/Avatars/*/*/*.png' /LICENSE.md /Assets/Avatars/Adults/Male_Adult_08/ && git checkout
# per person (~40 s)
/home/claude/bvenv/bin/python tools/blender/cast/rocketbox/rb_cast.py radioshack_1995
godot --headless --path . --import && godot --headless --path . --script res://tools/qa/cast_test.gd
xvfb-run -a -s "-screen 0 1600x1000x24" godot --path . --rendering-driver opengl3 --resolution 480x720 \
  --script res://tools/qa/cast_turntable.gd -- --id=radioshack_1995 --out=/tmp/tt/rs        # sheet frames
xvfb-run ... --script res://tools/qa/cast_shot.gd -- --id=radioshack_1995 --wing=1 --at=8.2,32.95,180 \
  "--cams=far:8.2,28.6,1.65,8.2,1.2,32.95,50;talk:8.2,31.55,1.66,8.2,1.6,32.95,38" --look_cam --out=/tmp/rs
```
Source: `github.com/microsoft/Microsoft-Rocketbox`, commit `0943055db6ec570bcef9f2c8b41c9e5467c808f9`,
`LICENSE.md` (MIT, "Copyright (c) 2020 Microsoft"). Only the people used are checked out; nothing from
Rocketbox is committed except the converted, repainted `.glb` (allowed by MIT with the notice, which is in
`CREDITS.md`).

`rb_cast.py` order (Steven's): **convert** with `rb2glb.py` (unchanged from CHAR-SOURCES: Mixamo names, T-pose,
Ch01 rests, ARKit + visemes, `heavy` push of trunk/hips/thighs/upper arms along smoothed normals) →
**repaint the clothes** (`rb_paint.repaint_body`: garments found by colour, seeded by body region so a shirt
tail weighted to the hips stays shirt; each recoloured from its own light and folds, `*_detail` flattens e.g.
denim) → **generated pieces** on the shirt (tie, blank badge: `clothes.py`, ray-cast onto the shirt, skinned like
it, textured in a free block of the hair/lash atlas so they add no draw call) → **build edits** (`resting_face`:
ARKit shapes baked into the rest face, e.g. lids `EyeWide*` 0.3, `CheekPuff`; `face_fill_m`: jaw, cheeks and
neck pushed out along normals for heavier people) → **tone tweaks** last (`tone`: warm, cheeks, nose on the skin
only; `eyes`: iris scaled up and brightened, a catchlight) → named morphs → split face (head + hair/lash
surfaces, with morphs) from body → LOD1 (both joined, no morphs, collapse-decimated to `lod1_tris`) → export.
Eye bones are renamed `eye.L` / `eye.R`, the jaw `jaw` (the cast's contract; CastFace also accepts `*LeftEye`).

**Hidden-face removal:** Rocketbox bodies are modelled clothed (no skin under the clothes), so there is nothing
to remove; the step stays in the MakeHuman path (`delete_verts`).
**Hair / brow / lash atlas:** Rocketbox's own `opacity` texture, 1024² (the 1024 rule), alpha-scissored.

## Source 2 (fallback): MakeHuman hm08 + asset library — `tools/blender/cast/build.py`

For people Rocketbox can't cover (CHAR-SOURCES lists: Houma Nation / Native American faces, heavy bodies,
older women, children, teenagers). Data files live in `tools/blender/cast/mh_fallback/`
(`radioshack_1995_mh.json` is the superseded MakeHuman RadioShack, kept as the worked example; not built
into `cast/`). How it works, unchanged: hm08 + macros + face targets (`person.py`), Ch01-rest skeleton with
`eye.L`/`eye.R`/`jaw` (pivot fitted from the mouth-open unit), the 20 morphs from the 34 CC0 units, barycentric
LOD maps (`skinmap.py`, `assetmap.py`), MakeHuman assets fitted by MHCLO (`mhasset.py`), hidden skin removed by
the clothes' `delete_verts`, textures resampled into a face-first 2048 skin / 1024 clothes / 1024 hair atlas with
tone and detail paint only (`paint.py`). Build: `skinmap.py`, `assetmap.py <asset> <r0> <r1>`, `build.py <id>`.

### MakeHuman 1.2 pack (Steven's request, superseded the same day by Rocketbox)
Tried from the makehumancommunity GitHub org: `makehuman-assets` (the repo MakeHuman 1.2's downloader clones,
`download_assets_git.py`) answers as private / not found, as do `makehuman-system-assets`, `system-assets`,
`makehuman-data`, `mpfb2-assets`, `assets`. The org's public repos (listed with GitHub search):
`makehuman`, `mpfb2`, `makehuman2`, `makehuman-static-website` (the static.makehumancommunity.org sources,
365 MB), `communityassets-wip` and plugins. A blob-less look into `makehuman-static-website` / `makehuman2` for
the 1.2 asset packs was started and stopped when the Rocketbox decision arrived. **The fallback still uses
Ubuntu's `makehuman-data 1.1.1`** (`fetch_mhassets.sh`, sha256 881a79c3…; upstream `LICENSE.md` §C states the
assets CC0; the 1.1.1 file headers say AGPL). If the fallback is ever used for a shipped person: either finish
the search in those two repos, or Steven downloads the 1.2 system assets on the Mac and pushes them to the
`refs` branch.

## TALK: eye bones and blink morphs (`scripts/cast_face.gd`, `scripts/npc_look.gd`)

`CastFace`: `eye_bones(sk)` (`eye.L`/`eye.R`, `*LeftEye`/`*RightEye`), `turn_eyes(sk, bones, yaw, pitch)`
(head-relative degrees, applied about the head's current axes, **from the eye's rest** each time),
`blink_shapes(root)` (`blink_L/R`, ARKit `EyeBlinkLeft/Right` + `EyeSquint*` 0.3: Rocketbox's ARKit blink alone
leaves a slit), `set_blink(shapes, v)`.

`npc_look.gd` is **TALK's file from `ws/talk` (79f3377b) with a small hunk**: it uses `CastFace` for bodies with
eye bones and/or blink morphs and keeps the iris-texture slide (`spatial_npc_eye.gdshader`) for the rest; the
limits (`head_yaw/pitch`, `eye_yaw/pitch`) and timing (`head_tau`, `eye_tau`, saccades, `blink_s`, `blink_len`,
`blend_s`) are untouched. It also fixes TALK's own eye-bone branch, which multiplied onto the current pose every
frame (eye bones aren't animated, so the turn would build up). **Merge note:** both branches add this file;
merge `ws/talk` first, then take `ws/char-build`'s version (TALK's 79f3377b + the hunk) if TALK hasn't changed it
since, otherwise re-apply the hunk (search `CastFace` in the file: five places). It needs `ws/talk`'s
`NpcRig.look_weight` and shader to compile; on `ws/char-build` alone it is not loaded by anything.
Checked here: `cast_test.gd` drives `CastFace` on the cast file (eye turn exact, no build-up, blink closes).
**Not yet run:** TALK's own talk test on a merge of the two branches (that needs the merged project imported).

## Budgets (measured)

| | budget | radioshack_1995 (Rocketbox) | MakeHuman version (fallback, for reference) |
|---|---|---|---|
| LOD0 tris | ≤ 15,000 | **7,512** (body 4,022 · face + hair + tie + badge 3,490) | 14,826 |
| LOD1 tris | ≤ 6,000 | **5,599** | 4,540 |
| draw calls | 2–3 | **3** (body · head · hair/lashes/tie/badge), one LOD at a time | 3 |
| morphs | — | 35 on the face mesh (3,490 tris) only | 20 on the whole LOD0 |
| textures | head 2048, body 1024, hair 1024 | head 2048 · body 1024 · hair/lash 1024 · normals 1024 | skin 2048 · clothes 1024 · hair 1024 |
| `.glb` | — | 9.8 MB (textures embedded) | 1.2 MB + 5 MB PNGs |

## Credits
`CREDITS.md` (project root) is new: the game had no credits list. It carries the Rocketbox MIT notice in full
and lists the MakeHuman/MPFB CC0 data; the repo's other licence files are listed for their owners to fold in.
A credits screen in the menu is not built (menu is CHAR-STRIP's / M's).

## Tests and tools
* `tools/qa/cast_test.gd` (headless): every `cast/*.json` through `Cast.body`: one skeleton; every bone
  `npc_rig.gd` retargets (leaf `*_End`/`*4` bones excepted: unanimated, Rocketbox has none) with rests matching
  the clips; `eye.L`/`eye.R`/`jaw` under the head; walk_m / idle / talk move bones; morphs exist, move > 1 mm
  (`viseme_Sil` excepted: the neutral viseme) and drive 0→1→0; LOD budgets and ≤ 3 surfaces per LOD; LOD1 has no
  morphs; `aim_eyes` hits a target within 3° with the body turned; `CastFace` turn / blink; `set_mouth` matches
  the record; unknown id → null. RadioShack: **CAST TEST OK (37 checks)**.
* `tools/qa/cast_shot.gd`: a person in a wing (unbaked) or `--studio`; `tools/qa/cast_turntable.gd`
  (CHAR-SOURCES' dev sheet, plus `--id=` through `Cast.body` and the cast's morph names).

## For CHAR-STRIP (not wired here, by the brief)
Every view calls `Cast.body(id)`; the player's choice is `mall-player-2 = {"cast": "<id>"}`; attendants get
`"look": "cast", "cast": "<id>"`; `cast/` goes in the pack a wing loads (or a shared pack awaited behind the
loading card); TALK: `Cast.set_mouth`, `Cast.set_morph`, `NpcLook` (eye bones + blinks via `CastFace`).

## People

### 1. RadioShack (1995) — `radioshack_1995` — PROPOSAL (Rocketbox), waiting for Steven's okay
* **Steven:** "25-year-old overweight white man." Picked Rocketbox **Male_Adult_08**.
* **Proposed:** HEAVY 1.0 + face fill 7 mm + `CheekPuff` 0.35 in the resting face; lids `EyeWide` 0.3; his
  light-blue button shirt repainted white (worn untucked, sleeves rolled, as modelled), jeans repainted charcoal
  (denim detail at 35 %), shoes black; a plain dark navy tie and a blank black name badge on his left chest
  (invented; no words, no logo). Eyes: iris ×1.3, brighter, a catchlight. Skin warmed a touch, cheek and nose
  colour. His own hair (Rocketbox cards; a softer silhouette than MakeHuman's short02).
* **Guessed:** 1995 RadioShack staff dress (white shirt + tie, dark trousers) from general memory of the era.
* Evidence: `production/qa/evidence/wsCAST-radioshack_1995-sheet.jpg` (Godot turntable + faces beside the
  research render), `wsCAST-radioshack_1995-ingame.jpg` (wing 1, unbaked). The earlier MakeHuman sheet is in
  this branch's history (commit 09dce16).
* Known: the face is still slimmer than the pushed body (Rocketbox has no heavy faces); hair cards read darker
  under the wing's unbaked light.

### 2. Cuco's owner (1995) — Rocketbox Male_Adult_07 — not started (after RadioShack's okay)
### 3. Great American Cookie (1995) — Female_Party_02 — not started (her curly hair is long: Steven's
"long style" case; recolour/trim to be proposed)
### 4. Auntie Anne's (2026) — Male_Adult_16 — not started (hair recoloured red, freckles as tone detail)
### 5. Spencer's (2026) — Female_Adult_11 — not started (plus size by `heavy` + face fill; Medical_Female_01
shares her head)
