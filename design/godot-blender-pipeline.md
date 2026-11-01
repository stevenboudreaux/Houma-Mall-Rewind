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
| `bl_ls_lion` (Steven, Nov 1) | large_fixture | 21,560 (sculpt ~400k) | 2048 | Steven's lion picture from the 2D game (`design/storefronts/refs/lions-share-lion.png`, extracted from `index.html` media "lion") | size (~0.95 m lion on a 0.32 m plinth), plinth, the back and the tail. **First pass, not yet at the reference's standard** (see below) |

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
