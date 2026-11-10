# Device bake-off: the best free way to make the Pocket Pal (Nov 9-10, 2026)

Workstream DEVICE-BAKEOFF. Steven, Nov 9: the menu becomes a real object, a "Pocket Pal" organizer the
player lifts into view, lit by the mall around it; "make it look lifelike and textured and not cheap old 3D
video game"; do we need a better asset generator? Paid tools are off the table. This note answers with
three test builds of the same device. **Nothing here is wired into the game**: no menu code, no HUD code.
Steven picks; the director writes the HUD build brief from the pick.

## Recommendation

1. **Build the device by hand in Blender (route A).** It is the only route that gives crisp legends, real
   key wells and a believable grained plastic, and it is 3,438 triangles, well inside budget.
2. **No free generator can make this device.** The best open one (Hunyuan3D-2mini) copies the reference
   organizer as a melted slab with no texture; its licence and its likeness to a real product both rule it out.
3. **The lifelike look comes from scanned CC0 materials and a high-to-low bake, not from a generator.** Adopt
   those two steps in the Blender pipeline for anything seen up close.

The picture to judge by: `production/qa/evidence/wsDEV-beauty-pocket_pal_a.jpg` (Cycles, 1920 x 1080, the
in-game mesh and atlas, not the dense source).

## The three routes

| | A. Hand-built in Blender | B. Free AI image-to-3D | C. Hybrid (A's shapes, AI textures) |
|---|---|---|---|
| **Look** | Grained charcoal case, rubber keys sunk in wells, light bezel, hinge barrel. Reads as a real object | A lumpy slab: keys and screen are soft bumps, edges melted, back is noise. One plain colour | A's shapes, but every surface is smooth. Reads as a toy |
| **Small parts crisp?** | Yes: pictograms, MAIN / BAG / JUMP TO / CONTROLS, LIGHT, BACK, ENTER, POCKET PAL, PP-95 all sharp in the close-up | No legends at all (the open model makes shape only) | Legends as sharp as A (they are painted, not AI-made) |
| **Effort** | About 3 hours: one script, three builds of 4 minutes each | About 2 hours, nearly all setup; 22 minutes to generate, 3 minutes of automatic clean-up, no hand work | 30 minutes on top of A |
| **Cost** | Free | Free, but needs 12 GB of memory and 22 minutes per try on a CPU | Free |
| **Licence** | Ours. Materials are CC0 (ambientCG) | Tencent Hunyuan community licence: not valid in the EU, UK or South Korea, and it bars showing outputs there. A public web game cannot honour that | Real-ESRGAN is BSD-3; the pixels come from someone's video of a real product |
| **Risk** | Low. Each look change is a number in the script | High: it reproduces the real organizer's shape and layout, which the brief forbids; the result changes with every run | Medium: no gain over A, and a worse look |
| **Triangles** | 3,438 (budget 8,000) | 7,840, decimated from 297,138 | 3,438 |
| **Atlas** | one 2048: albedo, normal, packed AO/roughness/metal | one 2048, same three maps | one 2048, same three maps |
| **Pack size if shipped** | +16.0 MB as built; about +5 MB (estimate) with the fix below | +9.5 MB | +7.4 MB |
| **LCD slot** | Yes, `bl_pocket_pal_a_lcd`, UV 0-1 across the screen | No (one fused surface) | Yes |
| **Verdict** | **Use** | Reject | Reject |

Hours are this session's working time per route, estimated; the cloud box paused between steps, so no
wall-clock figure is exact.

### The device, as built for A and C

Clamshell, open 150 degrees, about 166 x 72 mm per half. Lid: a full-width olive LCD in a light bezel,
POCKET PAL and PP-95 printed above it. Base, left to right: four tab keys with white pictograms (person,
bag, arrow, game pad) and the printed labels MAIN, BAG, JUMP TO, CONTROLS; a four-way direction pad in a
round well; a teal LIGHT key, a red BACK key, a wide ENTER key. No other keys. A thumb notch in the front
edge, a parting line round each half, feet, a battery door and a blank rating plate underneath.

- **Taken from the reference video:** charcoal grained plastic, rubber keys in recessed wells, a light bezel
  round an olive LCD, a hinge barrel, a teal backlight key.
- **Not taken:** the wordmark, the model number, the proportions, the key layout. The name, the model
  number and every legend are invented.
- **Guessed:** every dimension; the underside; the small POCKET PAL on the outside of the lid.
- **Missing reference:** the A1 / A2 / A3 artboard screenshots did not arrive in this session (only the
  video did). The layout follows the brief's words. If the artboards differ, the positions are numbers at the
  top of `device.py`.

## Shots

All in `production/qa/evidence/`. In-game shots are native Godot under xvfb in wing 1 with its published
lightmaps; the device is a child of the camera and is lit only by the scene (lightmap probes, reflection
probes, the wing's lights). The LCD shows a flat test card with no text.

| What | A | B | C |
|---|---|---|---|
| Turntable beside the reference | `wsDEV-pocket_pal_a-sheet.jpg` | `wsDEV-pocket_pal_b-sheet.jpg`, raw mesh `wsDEV-pocket_pal_b-raw.jpg` | `wsDEV-pocket_pal_c-sheet.jpg` |
| Held up at Woolworth's lunch counter, day (1990s) | `wsDEV-pocket_pal_a-court.jpg` | `wsDEV-pocket_pal_b-court.jpg` | `wsDEV-pocket_pal_c-court.jpg` |
| Keys and legends, close | `wsDEV-pocket_pal_a-court-keys.jpg` | `wsDEV-pocket_pal_b-court-keys.jpg` | `wsDEV-pocket_pal_c-court-keys.jpg` |
| Dark hall at night | `wsDEV-pocket_pal_a-hall.jpg`, `-hall-keys.jpg` | `wsDEV-pocket_pal_b-hall.jpg` | `wsDEV-pocket_pal_c-hall.jpg` |

- All three key close-ups side by side: `wsDEV-keys-compare.jpg` (A top left, C top right, B below).
- The hall without a device: `wsDEV-hall-night-empty.jpg`.
- Beauty render of A: `wsDEV-beauty-pocket_pal_a.jpg`.
- Reference stills, 1 fps: `wsDEV-ref-001.jpg` to `-457.jpg`. They show a real branded product and are
  reference only.

What the shots show:

- **A, held:** the device takes the warm light of the lunch counter and goes dim but readable in the dark
  hall. At arm's length on a 1080p screen the tab labels are about 7 pixels tall: legible, small. The HUD
  brief should hold the device closer than this test pose, or the labels should be printed larger.
- **A, close:** every legend is sharp; the wells and key bevels catch light; the grain is visible without
  sparkling.
- **C against A:** the same mesh looks cheaper purely because the surfaces have no grain or gloss variation.
  That is the "old 3D video game" look, and it shows that the materials carry the realism.
- **B:** recognisable from a distance, wrong up close, and it is the real organizer's layout.

## Route A: how it was made

Files: `tools/blender/assets_src/pocket_pal_a/` (`device.py` the model, `make.py` the driver, `cc0/` the
scans), output `models/hud/pocket_pal_a.glb` + `_albedo.png`, `_normal.png`, `_orm.png`.

    /home/claude/bvenv/bin/python tools/blender/assets_src/pocket_pal_a/make.py [--fast] [--route=c]

- It follows `design/godot-blender-pipeline.md` (the same `lib/` parts, materials, decals, bake, export and
  turntable) with one difference: the pipeline's sculpt path decimates a dense mesh, which ruins hard edges,
  so here the in-game mesh is **modelled** and a dense source (17,332 triangles: wider bevels, a dished pad,
  parting lines, feet, battery door) is baked onto it. `make.py` is a small driver beside the shared
  `build.py`, which is untouched. If Steven picks A, this should become a `META` option in `build.py`.
- **Materials, all CC0 from ambientCG** (`cc0/LICENCES.md`): Plastic 004 (case grain), Plastic 012 A (bezel),
  Rubber 004 (keys, feet), Fingerprints 009 (faint smudges in the roughness). Only height and roughness maps
  are used; every colour is set in the script. Poly Haven was checked and has no moulded plastic or key
  rubber.
- **Legends** are painted with the project fonts at 24 pixels per millimetre and baked into the atlas.
- **Edge wear** comes from the baked curvature: edges 3.5 % lighter and slightly glossier. Kept subtle.
- **Atlas share:** the underside and the outside of the lid get 42 % of the texel density, so the keys and
  legends get more.
- **LCD:** its own material slot (`bl_pocket_pal_a_lcd`, a flat olive), UV 0-1 left to right and bottom to
  top as the player sees it, for the game to draw on.

Two things found on the way:

- **Mipmaps.** The pipeline's models import with mipmaps off. A fine grain then sparkles when the device is
  held small. The three test textures have `mipmaps/generate=true` set in their `.import` files. Other
  close-up models with fine normal detail may want the same; that is a pipeline question, not changed here.
- **Pack size.** The grain is noise, which lossless storage cannot shrink: the normal map alone is 9.3 MB
  imported. For the real build, bake the atlas without the grain (albedo stays 2048 for the legends, about
  2.5 MB; normal and ORM compress to under 2 MB together) and add the grain as a small tiling detail normal
  in the Godot material. Estimated total about 5 MB. Not done here: it needs a material written for the
  device, which is HUD work.

## Route B: can a free generator do it?

**What ran on this box** (4 CPUs, 15 GB, no GPU; the brief said 2 CPUs and 7 GB, the box is larger):

| Model | Result |
|---|---|
| Microsoft TRELLIS / TRELLIS.2 (MIT) | Cannot run. Needs an NVIDIA GPU with 16 to 24 GB and CUDA-only parts; its setup refuses any other machine |
| Tencent Hunyuan3D-2mini, turbo, shape only | **Ran on CPU.** 22 minutes, 11.9 GB peak memory, 297,138 triangles from one cut-out still (`wsDEV-ref-064.jpg`) |
| Hunyuan3D texture stage | Cannot run: needs a 16 GB GPU. So no colour, no legends |

- **Clean-up:** all automatic through the pipeline's sculpt path (`pocket_pal_b/pocket_pal_b.py`): keep the
  largest piece, lay it flat, scale it to A's width, remesh, decimate to 7,840 triangles, bake normal and
  AO. Three minutes, no hand modelling. To be usable it would need the opposite: every key, well, hinge and
  edge rebuilt by hand, which is route A with extra steps.
- **Why it fails here:** a single top-down still gives the model no side or back, so it invents them. It
  cannot open the lid to 150 degrees, cannot make legends, and it copies the real product. The video has no
  clean side view (every close frame has hands in it).
- **The raw mesh is not in the repo** (it is a copy of the reference organizer's shape). The cleaned,
  plain-coloured `models/hud/pocket_pal_b.glb` is, as evidence. To make the raw mesh again: `pip install
  hy3dgen torch "transformers==4.48.3" "diffusers==0.32.2" pymeshlab`, then
  `Hunyuan3DDiTFlowMatchingPipeline.from_pretrained('tencent/Hunyuan3D-2mini',
  subfolder='hunyuan3d-dit-v2-mini-turbo')` on the cut-out, 5 steps, octree 192, CPU.
- **Network:** the weights needed `huggingface.co` and its file hosts allowed in this cloud environment;
  Steven approved those hosts during the session.

**Hosted free tiers.** No account was made and no email entered. Their sites are blocked from this box, so
the terms below come from search results and each tool's help pages, **not read at source**; check before
relying on any of them.

| Tool | Free allowance (reported) | Free-tier output terms (reported) | Sign-up Steven would need |
|---|---|---|---|
| Hugging Face Spaces (Hunyuan3D-2.1, TRELLIS.2, Stable Fast 3D, InstantMesh demos) | 2 GPU-minutes a day with no account, 5 with a free account | Each model's own licence | None, or a Hugging Face account (email) |
| Meshy | about 100 credits a month | CC BY 4.0: credit required, assets public | Account (email or Google) |
| Tripo | about 300 credits a month | Public; commercial use needs a paid plan | Account |
| Hunyuan3D web | about 20 a day | Not found | Account, method not verified |
| Rodin (Hyper3D) | a few credits | Sources conflict | Account |
| Google Colab / Kaggle (to run open models on a free GPU) | a T4 GPU, limits unpublished / 30 hours a week | Each model's own licence | Google account / Kaggle account |

Stopped there, as the brief says. A GPU run with texture would look better than B's plain slab, but it
would still be the real organizer, still without readable legends, and Tencent's territory clause would
still apply.

**Open-model licences** (read from the licence files where reachable):

| Model | Licence | Usable in this game? |
|---|---|---|
| TRELLIS, TRELLIS.2 | MIT (some dependencies carry NVIDIA's own licences) | Yes, if a 16 to 24 GB GPU is found |
| Hunyuan3D-2 family | Tencent community licence; excludes the EU, UK and South Korea | Doubtful for a public web game. A legal reading, not settled here |
| TripoSR | MIT | Yes; older and coarser |
| Stable Fast 3D, SPAR3D | Stability community licence, free under US$1M revenue; gated behind a Hugging Face account | Yes, after sign-up |
| InstantMesh | Apache-2.0 | Yes |

## Route C: A's shapes with AI textures

B turned up one usable free tool, **Real-ESRGAN** (BSD-3, runs on this CPU in seconds), so C was built:
surface patches cut from the video stills, enlarged four times, tiled, and used on route A's mesh in place
of the scans (`tools/blender/assets_src/pocket_pal_c/`, `make.py --route=c`).

- **Result:** nothing to enlarge. A 640 x 360 video holds no plastic grain; the enlarged patches are flat
  grey (`wsDEV-pocket_pal_c-tiles.jpg`). C is A without its surface.
- **On print it is worse than nothing:** it sharpens big shapes and turns small text into invented glyphs
  (`wsDEV-esrgan-vs-bicubic.jpg`, where "ELECTRONIC ORGANIZER" becomes nonsense).
- An upscaler could still help with Steven's own low-resolution photos of large shapes (signs, fronts). Not
  for fine surfaces or text.

## The wider question: a free generator for other mall assets?

**Not for anything with flat faces, hard edges or print. Possibly, later, for soft lumpy things, and only
with a GPU.**

Proof: one quick test, a corn dog (`wsDEV-generator-corndog.jpg`). Hunyuan3D-2mini was fed the icon of the
project's own hand-built corn dog. Top row: the input and the generated mesh. Bottom row: the hand-built one.

- The generated shape is good: the batter, the mustard squiggle and the stick are all there. Organic shapes
  suit it.
- It took 18 minutes and 11.9 GB on CPU, came out at 51,888 triangles with no colour, and the input was a
  clean render of a model we already had. A real photo on a counter would be harder.
- The hand-built corn dog is 4,296 triangles, textured, and took the pipeline a few minutes.

By kind of asset:

| Asset | Generator worth it? | Why |
|---|---|---|
| Devices, fixtures, signs, packaging | No | Hard edges and print: the device result above |
| Food | Not yet | Shape is fine, but there is no texture without a GPU, and the pipeline's food is already quick |
| Trees, plants | Not this way | Thin leaves become blobs. Free CC0 scanned plants (Poly Haven) are the better source |
| Statues, plush, lumpy props | Maybe | The one case where a generated shape could save real time. Needs a GPU for texture and a licence check first |

What would change the answer: a machine with a 16 GB or larger NVIDIA GPU (or Steven choosing to sign up
for a free GPU notebook), to run TRELLIS.2 (MIT) with textures. That is the one open model whose licence
fits a public web game. Until then the gain is in materials: **CC0 scans plus a high-to-low bake** lifted the
device from "toy" (C) to "object" (A) at no cost, and the same two steps would lift the existing fixtures.

## Budgets and files

| | Triangles | Repo size (.glb + 3 PNG) | Imported size (what a pack would carry) |
|---|---|---|---|
| `models/hud/pocket_pal_a.*` | 3,438 | 16.8 MB | 16.0 MB |
| `models/hud/pocket_pal_b.*` | 7,840 | 10.1 MB | 9.5 MB |
| `models/hud/pocket_pal_c.*` | 3,438 | 9.1 MB | 7.4 MB |

The wing packs carry only what a scene names and the shared items pack globs `models/bl_*`, so
`models/hud/` is in no shipped pack and the build does not change. (The old whole-mall presets "Web" and
"Web Mobile" export every resource and would pick it up; they are not used by `tools/export_web.sh`.)
Nothing was exported, baked or published. The sizes above are the price if the model were shipped as is.

- `tools/blender/assets_src/pocket_pal_shots/device_shot.gd`: the in-game test shots (one launch, several
  models and cameras). `beauty.py`: the Cycles beauty render.
- No change to `scripts/`, the menu, the inventory, shops or any wing. No rebake needed.

## Open questions for Steven

1. Pick a route. A is recommended.
2. The artboards A1 to A3 did not arrive. Does the base layout in the beauty render match them (one row:
   four tabs, pad, LIGHT and BACK over ENTER)?
3. The reference stills show a real branded product and are now on this branch (14 MB, 457 files). Is the
   video your own footage? If not, they are better kept on the `refs` branch, or cut to a handful, before
   anything merges.
4. Hunyuan's licence excludes the EU and UK. If a generator is ever wanted, is TRELLIS.2 on a rented or
   borrowed GPU acceptable, or does "free" rule that out?

## Tests

Eight headless suites, run once at the end on this branch, all green: SHOP (200 checks), SHOP INTERIORS
(178), ITEMS (49), INVENTORY (45), MENU UNIT (64), INTERACT (19), FLAGS (31), ECON (52). None touches the
test assets; the run shows the branch changed nothing they cover.
