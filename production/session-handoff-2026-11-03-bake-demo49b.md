# Handoff: Demo 49b bake and publish (Nov 3, 2026)

Demo 49b is published: `godot-build` = `f5a0488`, the desktop repo's `main` = `59aae82`. Eight Ultra day lightmaps, all ok.

## What happened
- **Air shell:** still 403 from GitHub, so the project went over as a checksummed archive to `~/GodotProjects/mall-bake-49b` (plain folder, no .git).
- **Bake on the Air:** warm, then `wing1 wing2 wing4 wing5 wing4_2026 wing5_2026 wing1_2026 wing2_2026` (day), 10:11-10:35 CT, Godot 4.7.2. No Blender needed.
- **Slices:** w1 6, w2 5, w4 4, w5 3, w1y26 2, w2y26 3, w4y26 4, w5y26 3. New counts for the 2026 wings; `.exr.import` files travelled with the EXRs.
- **Stand-ins:** recaptured in INT's order, all stamps match. `capture_doors.gd` reports the door pictures UNBAKED because built scenes carry no `light_data`; it does not load the outside's lightmap.

## Packs (MB)
| Wing | 1995 | 2026 |
|---|---|---|
| 1 | 98.58 | 41.85 |
| 2 | 97.06 | 66.87 |
| 3 | 31.68 | 14.55 |
| 4 | 37.50 | 32.30 |
| 5 | 39.18 | 34.18 |
| 6 | 21.36 | 21.49 |

## Checks
- All 12 packs loaded with 0 errors.
- doortest, both years: 1->3, 1->4, 4->3 CROSSED, 0 errors.
- Walk test MOVED in wing 1 and wing 3, both years. **Not confirmed** in wings 2, 4, 5, 6: the test's start spots were bad and the last run timed out. 49b changed no code.
- Lions look even in baked light (`d49b-baked-lions.jpg`). Sheets: `d49b-baked-sheet-a.jpg`, `-b.jpg`.
- Steven still has to look at the live page.

## Lessons
- `publish_build.sh` printed "published" after its godot-build push failed with a 502, then pushed the desktop repo anyway. Its filter hides the failure. It should check the remote ref before going on.
- A 1 GB push through the proxy fails. Pieces of 80-150 MB through temporary branches worked, ~10 min each.
- `pkill -f` matched its own shell again (exit 144).
- `device_commit_files` refused 28 MB parts (HTTP 400); 20 MB worked.
- `wing.json` spawn is `[x, z, yaw, ?]`. movetest needs `WALK_CAM` outside wing 1, on a free tile.
- `movetest.py` can run past 400 s under swiftshader.
