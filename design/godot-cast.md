# The cast: fixed people built by script (workstream CHAR-BUILD, Nov 8 2026)

Branch `ws/char-build` (from `main` f96a04b). Spec: `design/godot-characters-research.md` §3 (branch
`ws/char-research`), pipeline B. Steven's decisions (Nov 8): pipeline B; the player picks one of 3–4 cast
members (no editor); short hair first; shirt words stay on the crowd. **Mid-session (Nov 8) Steven:** *"Stop
painting the skin and hair by formula. Use the MakeHuman CC0 asset library (skins, eyebrows, eyelashes, hair
meshes, clothes) as the base and only adjust tone and detail in paint."* The build now does that (below).

Paths are under `prototypes/godot-mall/project/` unless they start with `design/` or `production/`.

## What a cast member is

One data file → one baked file. Nothing is assembled, dressed, fitted or baked at runtime.

| File | What |
|---|---|
| `tools/blender/cast/<id>.json` | the person: macro body, face targets, skin, eyes, brows, lashes, hair, garments, period, what Steven said, what is proposed |
| `cast/<id>.glb` | skeleton + `<id>_lod0` + `<id>_lod1` (each one mesh, 3 surfaces) |
| `cast/<id>_{skin,clothes,hair}_{albedo,normal,orm}.png` | the three texture sets (hair has no ORM) |
| `cast/<id>.json` | the build record the loader reads: `hips`, `height_m`, `morphs`, `jaw_open_deg`, `eyes`, `lod_switch_m`, tri/vert counts, texture sizes |

**The loader:** `scripts/cast.gd`, `Cast.body(id) -> NpcBody`, is the only way any view makes a cast person
(research §3 rule 2). Unknown/missing id → `null` + an error, never a stand-in (rule 4). Helpers:
`Cast.set_morph(body, name, v)`, `Cast.set_mouth(body, v)` (morph + jaw bone together),
`Cast.aim_eyes(body, world_point)`, `Cast.eye_dir`, `Cast.lod_mesh`, `Cast.skeleton`, `Cast.ids()`, `Cast.meta(id)`.

## The data format (`tools/blender/cast/<id>.json`)

```jsonc
{
 "id": "radioshack_1995", "store": "RADIO SHACK", "period": 1995, "status": "proposal",   // "approved" once Steven says so
 "steven": "his line, verbatim", "proposed": "what Claude proposes on top of it",
 "macro": {"sex": "male", "age_years": 25, "weight": 0.86, "muscle": 0.42, "height": 0.52, "proportions": 0.45,
           "ethnicity": {"caucasian": 1.0}},            // african / asian / caucasian, any mix (normalised)
 "face": {"head/head-fat-incr": 0.55, "...": 0},       // any hm08 target (targets/**), incl. expression units as a resting face
 "skin": {"base": "young_lightskinned_male_diffuse",    // a MakeHuman skin texture (the base)
          "tone": "#d6a487",                             // the face's mean colour after the tone match
          "stubble": 0.18, "stubble_color": "#4a3a2c", "flush": 0.3, "lips": "#b27566", "freckles": 0},
 "eyes":   {"asset": "eyes/low-poly", "texture": "brown_eye", "iris": "#5e4430"},
 "brows":  {"asset": "eyebrows/eyebrow001", "color": "#4a3424", "under": 0.35},   // under = painted tone below the card
 "lashes": {"asset": "eyelashes/eyelashes01", "color": "#3a2c22"},
 "hair":   {"asset": "hair/short02", "color": "#4a3426", "scalp": 0.6, "line_shift": -4},  // scalp = painted scalp tone under the mesh
 "shoe_sole_m": 0.004,
 "garments": [
  {"type": "mh", "asset": "clothes/male_casualsuit06", "role": "top", "color": "#f1f0ea", "bottom_color": "#3a3b40",
   "bottom_detail": 0.25, "placket": true, "paint_out": [[0.40, 0.10, 0.64, 0.215]]},   // paint_out: prints to remove (asset UV, image coords)
  {"type": "mh", "asset": "clothes/shoes03", "cell": "shoes", "color": "#1a1a1a"},
  {"type": "tie", "color": "#1f2a44", "end_y": 0.04},
  {"type": "nametag", "color": "#161616", "border": "#9a9a9a", "side": 1}      // side 1 = the person's left
 ]
}
```

Generated pieces available beside MakeHuman clothes: `collar` (automatic on a `role: top` garment unless
`"neck": "crew"`), `tie`, `nametag` (always blank), `belt`, `visor`, `cap`. The older formula garments
(`shirt`/`polo`/`tee`/`trousers`/`shoes` shells cut from the skin) and the formula hair shell are still in the
code for anything the library lacks, but per Steven's Nov 8 note the library is the base.

## Build steps

```bash
# once per workspace
python3 -m venv /home/claude/bvenv && /home/claude/bvenv/bin/pip install bpy numpy pillow
tools/blender/characters/fetch_mh.sh          # hm08 + targets + rig + weights (MPFB2 data, CC0)
tools/blender/cast/fetch_mhassets.sh          # MakeHuman 1.1.1 asset library (Ubuntu package; see Licences)
/home/claude/bvenv/bin/python tools/blender/cast/skinmap.py                 # skin LOD maps
/home/claude/bvenv/bin/python tools/blender/cast/assetmap.py clothes/male_casualsuit06 0.40 0.13 \
    clothes/shoes03 0.15 0.07 hair/short02 0.72 0.25 eyebrows/eyebrow001 1 1 eyelashes/eyelashes01 1 1 eyes/low-poly 1 1
# per person (≈ 65 s, numpy + PIL)
python3 tools/blender/cast/build.py radioshack_1995
/home/claude/bvenv/bin/python tools/blender/cast/sheet.py radioshack_1995      # -> production/qa/evidence/wsCAST-<id>-sheet.jpg
godot --headless --path . --import
godot --headless --path . --script res://tools/qa/cast_test.gd                  # CAST TEST OK
xvfb-run -a -s "-screen 0 1600x1000x24" godot --path . --rendering-driver opengl3 --resolution 1280x800 \
  --script res://tools/qa/cast_shot.gd -- --id=radioshack_1995 --wing=1 --at=8.2,32.95,180 \
  "--cams=far:8.2,28.6,1.65,8.2,1.2,32.95,50;talk:8.2,31.55,1.64,8.2,1.58,32.95,38" --look_cam --out=/tmp/rs
#   (--studio instead of --wing: a 2 s look in the game's renderer without loading a wing)
```

What `build.py` does:
1. **Body** (`person.py`): hm08 + MakeHuman's macro rules (`characters/mh.py`) + the face targets → positions;
   soles at `shoe_sole_m`, hips over x = z = 0. MPFB's Mixamo weights, **normalised per vertex** (MPFB's file
   isn't: a foot vertex is Foot 0.2 + ToeBase 0.2).
2. **Skeleton:** B1's rule (copied here; CHAR-STRIP deletes `tools/blender/characters/body.py`): glTF node TRS =
   Ch01's T-pose rotations (the clips' skeleton, `npc/anims.json` rest) so `NpcRig` finds nothing to retarget;
   inverse bind matrices = hm08's A-pose. Plus `eye.L` / `eye.R` (hm08's eye joint cubes) and `jaw` under
   `mixamorig_Head`. **The jaw pivot is fitted, not taken from `joint-jaw`** (that cube sits at the chin):
   the rigid rotation about X that best reproduces what the CC0 mouth-open unit does to the lower teeth
   (RadioShack: 26.6°, 0.8 mm error). Lower teeth (and tongue, when used) ride the jaw bone; the
   `jaw_open` morph moves lips, chin and cheeks; `Cast.set_mouth` drives both by the same 0..1.
3. **Morphs** (`person.MORPHS`, 20): `blink_L`, `blink_R`, `squint_L`, `squint_R`, `eyes_wide`, `smile`,
   `jaw_open`, `brow_up`, `brow_down`, `brow_inner_up`, `brow_up_L`, `brow_up_R`, `mouth_pucker`,
   `mouth_press`, `mouth_wide`, `mouth_funnel`, `frown`, `lip_upper_up`, `lips_part`, `sneer`: MakeHuman's 34
   CC0 expression units mixed by the person's ethnicity, on the skin and carried onto brows, lashes and hair
   through their MHCLO refs. Normal deltas on the skin. LOD0 only.
4. **Skin surface:** hm08 decimated once per LOD by zone (`skinmap.py`: face kept 85 %, head 30 %, hands
   13 %, feet 15 %, body 34 %; LOD1 17/12/5/7/15 %), every low vertex stored as barycentrics on hm08, so the
   map serves every person, weight and morph. Skin under clothes removed from MakeHuman's own `delete_verts`.
5. **MakeHuman assets** (`mhasset.py`, numpy only): compiled meshes (`.npz`), MHCLO fitting
   (w1·c1 + w2·c2 + w3·c3 + offset·scale) on this body, weights through the same refs; decimated by a per-asset
   map (`assetmap.py`, same barycentric trick). Eyes on the eye bones.
6. **Generated pieces** (`clothes.py`): the collar from the top's neckline loop, the tie and badge placed by
   ray-casting onto the top.
7. **Textures** (`paint.py`): every texel rasterised to its 3D point, its hm08 UV and its asset UV, so
   MakeHuman's textures are **resampled** into the atlases, then only tone and detail are painted:
   * skin 2048: MakeHuman's skin texture, per-channel gain so the face's mean = `tone`; painted stubble, a
     light flush, a lip tint, a soft brow tone under the brow card, the scalp's hair tone under the hair mesh;
     MakeHuman's eye texture in the eye disc (iris re-toned). **Face-first layout:** hm08's head island
     (warped so the face is magnified) fills the left half; hands/forearms/neck the top right.
   * clothes 1024: the garment textures resampled into cells (top+trousers 1024×768, shoes, collar, tie,
     badge, belt, headwear); the top re-coloured from its own light and folds; trousers re-coloured with the
     denim detail flattened (`bottom_detail`); prints painted out (high-frequency marks + `paint_out`
     rectangles, filled from the surrounding cloth in the albedo, AO and normal maps).
   * hair 1024: hair mesh, brows and lashes textures (RGBA), re-coloured to the person's colours.
8. **Write** the glTF (`gltf.py`, B1's writer: exact skeleton, sparse morphs, PNGs by URI) and `cast/<id>.json`.

## Budgets (measured, RadioShack)

| | budget (research) | radioshack_1995 |
|---|---|---|
| LOD0 tris | ≤ 15,000 | **14,826** (skin 7,402 · suit 2,866 · hair 2,406 · shoes 616 · collar 464 · lashes 368 · brows 192 · eyes 172 · teeth 192 · tie 136 · badge 12) |
| LOD1 tris | ≤ 6,000 | **4,540** (no morphs, lashes, teeth or collar) |
| draw calls | 2–3 | **3** per LOD (skin · clothes · hair), only one LOD drawn at a time (switch at 9 m) |
| textures | skin 2048, clothes 1024, hair 512 | skin 2048 · clothes 1024 · **hair 1024** (see below) |
| `.glb` | — | 1.2 MB (+ 5 MB PNGs in the repo; Godot imports them compressed) |

**Deviation: hair 1024, not 512.** With MakeHuman's hair cards and brow/lash cards in one alpha-scissored
atlas, 512 lost the brows almost completely in Godot (the cards thin out at the cut-off). 1024 keeps them.
Steven's call if 512 must hold (then the brows would move into the skin texture).

## Licences

* hm08, targets, expression units, Mixamo rig and weights: MPFB2 `src/mpfb/data`, CC0 (`LICENSE.ASSETS.md`),
  pinned commit 6ff1eb35 (`characters/fetch_mh.sh`). MPFB's GPL code is not used.
* The asset library: Ubuntu's `makehuman-data 1.1.1` (sha256 881a79c3…, `fetch_mhassets.sh`), because the
  MakeHuman asset server and the `makehuman-assets` GitHub repository are not reachable from the cloud.
  **MakeHuman's upstream `LICENSE.md` (makehumancommunity/makehuman, section C) states the bundled assets —
  base mesh and proxies, targets, textures, MHCLO clothes — are released under CC0 1.0.** The 1.1.1 files' own
  headers (2016) still say AGPLv3, and the Debian copyright file says AGPL-3 for `Files: *`. Read as: the
  copyright holders' current statement relicenses the same system assets CC0. **Steven: please confirm you're
  happy relying on that statement** (or say so and the build switches to the 1.2 asset pack once it can be
  downloaded on the Mac).
* No asset source (MakeHuman download, Blender venv) is committed: fetch scripts only. The baked person
  (`cast/`) is our output.
* MPFB's separate viseme / ARKit shape-key packs: **not used** (the 34 CC0 units cover the 20 morphs).

## Rules that keep the old bugs out (research §1, §3)

One person = one data file + one `.glb` + one id. One loader. No fallback body. The headless test
(`tools/qa/cast_test.gd`) asserts per file: loads through `Cast.body`; exactly one `Skeleton3D`; every bone
`npc_rig.gd` retargets is present and the rest matches the clips (`NpcRig._fix` empty); eye.L / eye.R / jaw under
the head; walk_m, idle and talk play and move bones; each morph exists, moves vertices > 1 mm and drives
0 → 1 → 0; LOD budgets; LOD1 has no morphs; the eyes hit a target within 3° with the body turned; `set_mouth`
turns the jaw with the morph; an unknown id gives `null`. RadioShack: **CAST TEST OK (33 checks)**.

## For CHAR-STRIP (not wired here, by the brief)

* Make every view call `Cast.body(id)`; store the player's choice as `mall-player-2 = {"cast": "<id>"}`.
* Attendants: `"look": "cast", "cast": "<id>"` in `data/story/attendants.json`; the attendant script stands
  the body where it stands today's (RadioShack: `--at=8.2,32.95,180` in the shot is that spot).
* Packs: `cast/` must be in the pack a wing loads (or a shared pack awaited behind the loading card). The
  export presets were not touched.
* TALK: `Cast.set_mouth`, `Cast.set_morph("blink_L"…)`, `Cast.aim_eyes(body, camera.global_position)` each
  frame while talking (eye bones aren't animated by the clips, so the aim stays until changed).

## People

### 1. RadioShack (1995) — `radioshack_1995` — **PROPOSAL, waiting for Steven's okay**
* **Steven:** "RadioShack (1990s): 25-year-old overweight white man."
* **Proposed:** short side-swept mid-brown hair (MakeHuman `short02`), brown eyes, light stubble, a round full
  face; a white short-sleeve top (MakeHuman `male_casualsuit06`, its print removed, a button placket painted)
  under a generated dress collar and a plain dark navy tie, its trousers re-coloured charcoal, black dress
  shoes (`shoes03`), a blank black name badge on his left chest (invented; no words, no logo). Worn untucked,
  as the asset is modelled; a tucked dress shirt would need a new garment.
* **Guessed:** 1995 RadioShack staff dress (white shirt + tie, dark trousers) from general memory of the era;
  no reference photo of Southland's RadioShack staff in `refs/` was checked by this session.
* Evidence: `production/qa/evidence/wsCAST-radioshack_1995-sheet.jpg`, `wsCAST-radioshack_1995-ingame.jpg`
  (wing 1, unbaked).
* **Steven's okay:** pending.

### 2–5
Not started: the brief stops for Steven's okay on RadioShack's face and look first.
