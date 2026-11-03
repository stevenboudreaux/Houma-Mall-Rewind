# tools/blender — Blender (bpy) asset pipeline

Scripted, headless Blender models for the Godot mall. Read `.claude/skills/blender-asset/SKILL.md`
(workflow) and `design/godot-blender-pipeline.md` (budgets, assets, what is guessed).

    python3 -m venv /home/claude/bvenv && /home/claude/bvenv/bin/pip install bpy pillow numpy   # once
    tools/blender/run.sh <id> [--fast] [--no-sheet] [--evidence]    # build one asset
    tools/blender/godot_check.sh glb <out-prefix> "<x,y,z,yaw,pitch;...>" '<opts-json>'   # see it in Godot

| Path | What |
|---|---|
| `assets_src/<id>.py` | one script per asset: numbers at the top, `META`, `build()`; `_*.py` are shared helpers |
| `build.py` | the driver run.sh calls: clean, budget, bake, export, re-import, turntable, icon, item JSON |
| `budgets.json` | triangle/texture budgets per class (read by the build) |
| `lib/` | core, parts (kitbash), mats (+ decals), labels (PIL art), bake, clean, render |
| `compare.py` | review sheet for a rebuild: the reference, the new .glb and the previous .glb at the same angles |
| `godot_check.gd/.sh` | puts .glb files into `tools/qa/preview.gd`'s scene (stage or `store:<NAME>`) |

Outputs: `res://models/<id>/` (.glb, PNG maps, icon), `.scratch/blender/<id>-sheet.png`, `<id>-report.json`,
`data/items/blender_props.json`.
