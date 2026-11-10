# Session handoff: DEVICE-BAKEOFF (Nov 9-10, 2026)

Branch `claude/device-bakeoff-h8pl8l` (the session's assigned branch; the brief named `ws/device-bakeoff`).
Research only: no menu code, no HUD code, nothing wired into the game. Not merged, not baked, not published.

## Result
- **Recommendation: route A**, the device hand-built in Blender with CC0 scanned materials and a
  high-to-low bake. Free generators cannot make it. Full table and shots: `design/godot-device-bakeoff.md`.
- The picture to judge by: `production/qa/evidence/wsDEV-beauty-pocket_pal_a.jpg`.
- **Stopped for Steven's pick.** The director writes the HUD build brief from it.

## What is on the branch
- `design/godot-device-bakeoff.md`: the table, the shots, the recommendation, the wider generator question.
- `prototypes/godot-mall/project/tools/blender/assets_src/pocket_pal_a/` (model, driver, CC0 maps and their
  licences), `pocket_pal_b/` (clean-up of the AI mesh), `pocket_pal_c/` (AI-upscaled textures),
  `pocket_pal_shots/` (in-game shot script, beauty render).
- `prototypes/godot-mall/project/models/hud/pocket_pal_{a,b,c}.glb` with their three maps and `.import` files.
  Test assets: A 3,438 triangles, B 7,840, C 3,438; one 2048 atlas each.
- `production/qa/evidence/wsDEV-*`: sheets, in-game shots (Woolworth lunch counter by day, a dark hall at
  night), key close-ups, the beauty render, the corn dog generator test, 457 reference stills.

## Tests
SHOP, SHOP INTERIORS, ITEMS, INVENTORY, MENU UNIT, INTERACT, FLAGS, ECON: all OK (headless, once, at the end).

## No rebake
No wing or year needs a rebake. No shared file was touched (`scripts/`, `build_mall.gd`, `build.py`,
`budgets.json`, layouts: all unchanged).

## For whoever picks this up
- **Missing reference:** the A1 / A2 / A3 artboard screenshots never arrived; the base layout follows the
  brief's words. Positions are the numbers at the top of `pocket_pal_a/device.py`.
- **Reference stills:** 457 frames of a real branded organizer, 14 MB, in `production/qa/evidence/`. If the
  video is not Steven's own footage, move them to the `refs` branch or cut them down before any merge.
- **If A is picked:** fold `pocket_pal_a/make.py`'s "modelled low mesh + dense source" path into
  `tools/blender/build.py` as a META option; bake the atlas without the grain and add the grain as a tiling
  detail normal in the device's Godot material (16 MB down to about 5 MB, estimated); set mipmaps on.
- **Mipmaps:** the pipeline's models import with mipmaps off; fine normal detail sparkles when small. Only
  the three test models were changed.
- **In-game shots:** the first frame after a wing loads is taken before the reflection probes settle and
  looks cooler than the game. `device_shot.gd` shoots a warm-up camera first for that reason.
- **Cloud environment:** hosts added with Steven's approval for this job: ambientCG and its two file hosts,
  Poly Haven, Hugging Face and its file hosts. Remove them in the environment's settings if not wanted.
- **Box limits:** Hunyuan3D-2mini needs 12 GB; running it beside a Blender bake and Godot got the container
  killed twice. One heavy job at a time.
- The Godot setup path in `CLAUDE-CLOUD.md` (`/home/claude/houma-mall-rewind`) is now
  `/home/user/Houma-Mall-Rewind` in these sessions; `git archive` for the lightmaps must be run from the
  repo root.
