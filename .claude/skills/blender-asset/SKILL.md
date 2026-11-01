---
name: blender-asset
description: "Model a prop, inventory item or fixture for the Godot mall in Blender (headless bpy): script, build, bake, export .glb, review turntable + in-game shot, fix. Use for anything seen up close: hand/pocket items, detailed fixtures, statues, later clothing."
argument-hint: "<asset id, e.g. bl_rs_scanner> [what it is]"
user-invocable: true
---

# Blender asset workflow (Houma Mall Rewind, Godot mall)

Walls, halls and storefronts stay generated from the map data in `tools/build_mall.gd`. Blender is for
things seen up close: inventory items, detailed fixtures (finials, registers, booths, mannequins,
cabinets, statues) and later avatar clothing. Every asset is a **Python script**, built headless, looked
at, fixed and rebuilt: the same look-and-fix loop as `tools/qa/preview.sh`.

Paths below are relative to `prototypes/godot-mall/project/`. Design note: `design/godot-blender-pipeline.md`.

## 0. Setup (once per workspace, ~1 min)

```bash
python3 -m venv /home/claude/bvenv && /home/claude/bvenv/bin/pip install bpy pillow numpy
```
Blender 5.2 as a Python module; Cycles CPU renders and bakes work headless. The Godot setup in
`CLAUDE-CLOUD.md` is needed for step 9. Never commit the venv.

## 1. Before modelling

- **Reference.** Find the frames (`refs/INDEX.md`, the store's `design/storefronts/<store>.md`). Note
  which frame, what is measured from it and what is guessed. No reference = say so in the script header.
- **Period + IP (CLAUDE-CLOUD.md).** Only what existed in the year map it appears in (e.g. no FRS radios
  in 1995: they came in 1996). Brands, logos and model names on products are **invented** (`BAYOU COM`,
  `ZAP-CELL`, `TURBO DUNE`); no real product titles, cover art or third-party logos. Store signs and
  tenant wordmarks are the exception. Plain, unbranded packaging when the real one is not documented.
- **Size.** Real metres. Measure from the reference against something of known size; write the
  measurement in the header.
- **Class and budget** from `tools/blender/budgets.json` (the build reads it):
  pocket ≤ 2k tris, hand ≤ 5k, small_fixture ≤ 10k, large_fixture ≤ 25k (NPC / clothing: later).
  Build to budget. Decimation is the last resort (`META["decimate"]`) and the log says `DECIMATED`;
  sculpted assets use the hipoly bake instead (step 6).

## 2. The asset script: `tools/blender/assets_src/<id>.py`

File name = id = `bl_<store>_<thing>` (`bl_rs_pager`, `bl_cd7_corndog`, `bl_ls_lion`). Header docstring:
what it is, sources (frames), what is guessed, origin. Then **the numbers at the top** (sizes, counts,
colours) so it can be rebuilt by changing a value, then `META` and `build()`:

```python
META = {"id": "bl_rs_pager", "class": "pocket", "tex": 1024, "ao": 0.35,
        "refs": [["refs/era_1995/ads/ad_3.jpg", [x0, y0, x1, y1], "caption"]],   # crop as fractions
        "item": {"name": "Pager", "year": 1995, "store": "RADIO SHACK"}}       # only for inventory items
def build():   # make the parts in the empty scene; the driver does everything after
```
Optional META: `"uv": "keep"`, `"normal": False`, `"decimate": True`, `"hipoly": <tris>`, `"cage": m`.

## 3. Block out → modifiers → kitbash (`tools/blender/lib/`)

- **Axes.** Model in Blender's Z-up; the exporter writes Godot's +Y up. The front faces **Blender -Y =
  Godot +Z** (the player stands at +Z looking -Z). Origin: bottom centre in the resting/held pose.
- **Primitives at real size:** `parts.box / rounded_panel / cylinder / sphere / lathe (profiles) /
  tube_path (tapered tubes) / trim (moulding profiles) / fabric_fold / label_plate`.
- **Kitbash:** `parts.screw / button / keypad / grille / antenna`.
- **Modifiers:** Bevel **always** on hard edges (`core.bevel`, angle-limited; most parts get it by
  default), Subdivision only where curved (`core.subsurf`), Array/Mirror for repeats (`core.array`,
  `core.mirror`), Displace for organic lumps.
- **Materials:** `mats.M(name, base, rough, metal)` + node helpers (`noise`, `voronoi`, `ramp`, `mix`,
  `math`, `bump`), `mats.plastic`, `mats.brushed_metal` (metal 0.75 by default: the game's metals are
  0.6-0.8, full metal reads black in stores without probes), `mats.clear_plastic` (transparent, not
  baked), `mats.flat(..., bake=False)` for glowing or tintable details.
  Names come out as `bl_<asset>_<part>` (prefix convention).
- **Printed art** (labels, screens, box art): paint it with PIL (`lib/labels.py`, the project fonts) and
  place it with `mats.decal(m, png, centre, size, plane, facing=...)`. Decals map by position, not UVs;
  use `facing` on boxes so art does not project through to the opposite face; parts moved **after**
  their decals are placed need `mats.M(..., frozen=True)` + `core.freeze(parts)`.

## 4-8. Build (the driver does these): `tools/blender/run.sh <id> [--fast] [--evidence]`

4. **Apply + clean:** weld (merge by distance) first, triangulate last (keeps Bevel's hardened
   normals), join into one mesh named `<id>`; no n-gons reach the export (checked).
   **Collision:** parts named with Godot's import suffixes `-col`, `-convcol`, `-colonly` stay separate,
   without materials, for props that need physics (hand items in the inventory don't).
5. **Budget check:** fails with `OVER BUDGET: … has N triangles; the '<class>' budget is M`.
6. **Sculpts (`META["hipoly"]`):** `build()` makes the dense mesh (voxel remesh of fused forms, as in
   `bl_ls_lion.py`); the driver decimates a copy to the target and bakes the detail onto it
   (selected-to-active normal, colour, AO). Say in the script that this is how it was made.
7. **UV0 + bake:** Smart UV Project atlas; Cycles bakes every baked material into **one Principled
   BSDF with image textures** `bl_<id>_baked`: `<id>_albedo.png` (sRGB, AO folded in), `<id>_orm.png`
   (R AO, G roughness, B metal), `<id>_normal.png` (tangent, OpenGL). Power of two, 512–2048 px
   (`META["tex"]`; inventory items: "a few MB of textures is fine"). Godot cannot read Blender
   procedural nodes: everything must go through this bake.
   **UV2:** not made in Blender. Static props placed in a baked wing get it from Godot's importer:
   set `meshes/light_baking=2` (Static Lightmaps) in the `.glb.import`. Hand/pocket items are dynamic
   (probe-lit) and need no UV2.
8. **Export** `res://models/<id>/<id>.glb`; the PNGs sit beside it, referenced by URI (one copy in the
   repo; Godot imports them like any texture). Then the driver re-imports the .glb into an empty scene
   and renders the **turntable sheet** (6 angles, neutral studio light, AgX, exposure 0) beside the
   reference crops: `.scratch/blender/<id>-sheet.png`; items also get a 256 px transparent icon
   `<id>_icon.png` and an entry in `data/items/blender_props.json` (written from `META["item"]`).

## 9. In Godot: `tools/blender/godot_check.sh`

```bash
tools/blender/godot_check.sh glb .scratch/blender/<id>-godot "x,y,z,yaw,pitch;..." \
  '{"stand":[w,h,d],"glb":[{"path":"res://models/<id>/<id>.glb","at":[0,0.9,0],"colors":{"<mat>":"#hex"}}]}'
tools/blender/godot_check.sh "store:CORN DOG 7" ...   # inside a store, the hall in front
```
It runs `godot --headless --import` (commit the new `.import` files) and renders with
`tools/qa/preview.gd`'s lights through `tools/blender/godot_check.gd`. `colors` tests surface
overrides (tinting a baked atlas, recolouring a glow material) the way the game will do them.

## 10. Review, then fix (never skip)

Look at **both** the sheet and the Godot shot, and write down the fixes before calling it done:
silhouette and proportions against the reference, scale against neighbours, labels legible and facing
the right way (no projection on the back), seams or unbaked texels (pale specks), metal reading black,
glow blown out (match the store's existing emission energies), faceting from bad normals. Fix the
numbers at the top of the script and rebuild. `--fast` while iterating; a full build for the evidence.

## 11. Deliver

- Evidence: `production/qa/evidence/wsT-<id>-sheet.jpg` (`run.sh <id> --evidence`) and
  `wsT-<id>-godot.jpg` (unbaked preview shot), JPEG ≤ 1600 px.
- Commit the script, the `.glb`, its PNGs, `.import` files and the item JSON. Never `.blend` files,
  `.scratch/`, `refs/` or the venv.
- Add the asset to the table in `design/godot-blender-pipeline.md` (reference frames, what is guessed,
  tris, texture size). Placing it in the mall is the store owner's / integration session's job unless
  your brief says otherwise.
