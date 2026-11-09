# Handoff: Demo 53 published (Mon Nov 9, 2026, 11:06 AM CT, director session)

Read `production/session-handoff-2026-11-08-int53.md` for what is in it and how it was integrated and tested.

## Live
- **main** `67654e7b` (fast-forward of `int-53`), **godot-build** `235ba28`, R2 build `builds/20261109-1100-67654e7b` (2914 MB, 34 files: 24 packs + page). Both Pages deploys green at 11:06 AM CT.
- Bakes: wing2, wing2_2026, wing3 (fastday), wing3_2026 (fastday), wing4, wing4_2026, wing5, wing5_2026, on the Air in `~/GodotProjects/mall-bake-53` (34 min total). Wing 1 and wing 6 kept Demo 52's lightmaps. All 12 stand-ins recaptured baked. `.exr.import` slice counts: w2 3, w2y26 2, w3 1, w3y26 1, w4 3, w4y26 3, w5 2, w5y26 2.
- Checks on the baked export: wing 1 (1995) and the outside (2026) load and walk, 0 errors; pack-content check: every reference shipped and the manifest matches (`tools/qa/pack_manifest/` rewritten for this wave, `chars*` lists gone).

## How the publish actually ran (new, keep)
- **This director session's egress proxy refuses uploads to R2** (every PUT 403 with no Cloudflare headers; reads work). The Nov 5 publish ran from a Claude Code cloud box, which does not have that block. Workaround used: the build (2.8 GB tar in 350 MB parts via SendUserFile → device_commit_files) went to the Air's `~/GodotProjects/_stage53/`, and `~/up53.py` (boto3, credentials read from `~/GodotProjects/rclone.conf`, never printed) uploaded from the Mac's shell at ~15 MB/s under the fixed id. Then `BUILD_ID=20261109-1100-67654e7b RCLONE_SIZE_ONLY=true tools/publish_build.sh` from the cloud found the files in place and did the rest. rclone here is the apt 1.60 build with a wrapper (`~/bin/rclone`: `env -u AWS_CA_BUNDLE rclone --ca-cert ~/.ccr/ca-bundle.crt`), because the proxy's `AWS_CA_BUNDLE` breaks its S3 backend.
- Next time: publish from a Claude Code cloud session (it can upload), or repeat the Mac route. Either way the Mac keeps `rclone.conf`; Steven deletes it when done.
- `tools/exterior/capture_doors.gd` now applies the time-of-day step (which loads `wing3[_2026]_day.lmbake` by path) before deciding whether the outside is baked; cloud-built scenes don't embed `light_data`. Without this the door pictures come out unbaked.
- The bake needs the `.lmbake` files back as well as the EXRs and their `.import`.

## Known / to check (Steven)
- Facade smears after the wing-3 bake: Dillard's, JCPenney west entrance and south parapet, Lynn's (LOT fixed hidden faces; diagnosed from the old lightmap).
- GAC 2026 storefront: `tex/gac/tile_sq.png` left the packs with the 1990s oak finish; FOOD3D said 2026 was unchanged. Look at the 2026 GAC front.
- MENU native suite only verified to 76 checks here (box memory); CHAR-STRIP had it green.
- iPhone: wing 1 memory, now without the 53 MB character pack.
- The three unfinished cast members (GAC, Auntie Anne's, Spencer's) are in `cast/` but not wired; CHAR-BUILD is rebuilding them (`ws/char-build`, after `407ed773`'s merge point). Demo 54.

## Cleanup for Steven
- On the Air: `~/GodotProjects/rclone.conf` (after Demo 54's publish, or now if the next publish goes through a Claude Code session), `~/GodotProjects/_stage53/` (2.9 GB + 2.8 GB of parts), `_to_delete_d52/`, old `mall-bake-51*` folders once mall-bake-53 is proven.
- On GitHub: delete `tmp/publish` (the box can't) and the merged `ws/*` branches: packs, talk, char-research, char-sources, char-strip, food3d, lot, ext-layout, smallfix, ext-layout-notes. Keep `ws/char-build` (still running) and `int-53` until Demo 54.
- In this chat: the nine `d53.tar.part-*` file cards were transport; nothing to keep.

## Open for Steven (carried)
- Cuco's owner's name and lines; the playable cast (3–4 lines); Unitech's 1990s sign (historian).
- Pick CHAR-BUILD's three rebuilt people when they land.
