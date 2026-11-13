# Demo 54 published (Fri Nov 13, 2026, 1:40 PM CT)

- **main** `df378f57` (fast-forward of `int-54`), **godot-build** `8c4db6b`, R2 build `builds/20261113-1915-df378f57` (2969 MB, 34 files: 24 packs + page). "Redeploy site for a new Godot build" and "Deploy site to Pages" both green at 19:40 UTC.
- The live page could not be loaded from the cloud box or from the Air's sandbox shell (proxy 403), so the last check is Steven opening https://stevenboudreaux.github.io/Houma-Mall-Rewind/ . `play/r2-build.txt` on `godot-build` holds the new id.

## What shipped
Wave A + Wave B on int-54: lot fixes, 3D department-store signs, the main entrance tower and east entrance (both years), Dillard's and JCPenney docks, dumpsters, Woolworth front and lunch counter, directory kiosk to mid-corridor, floor specular fix. Detail: `claude/session-handoff-2026-11-11-int54-READ-FIRST.md` (project) and the worker handoffs under `production/session-handoff-2026-11-11-*.md`.

## How this publish ran
- Bakes on the Air in `~/GodotProjects/mall-bake-54` (a copy of mall-bake-53 with int-54 synced in through the Air's sandbox `git clone` + `rsync`): `.autobake` = `wing1:day wing3:fastday wing3_2026:fastday`, Steven opened the project in Godot, about 20 min.
- Lightmaps came back with their import cache (`.godot/imported/wing*.exr-*` as a tar), so the cloud box did not reimport them (7 s instead of ~50 min).
- The floor fix changed shared code, so every wing hash moved: all twelve stand-in pictures were recaptured (4, 5 first, then 1 and 2, both years), then export, then `packcontents.py write` for the 39 new files.
- Upload: `device_commit_files` by `fileUuid` after `SendUserFile`, one pack per call, three or four calls in parallel (a call carrying more than ~190 MB hits a wall-clock timeout; small files can go by `stagedPath`, large ones cannot). `_stage54/up54.py` (boto3, credentials read from `rclone.conf`, never printed, resumable in 110 s slices) sent 2.9 GB in about 5 minutes. Then `BUILD_ID=20261113-1915-df378f57 RCLONE_SIZE_ONLY=true KEEP=10 tools/publish_build.sh` from the cloud.
- `/mnt/user-data/outputs` rewrites PNG files: checksum from the build folder, and send images inside a tar.
- The Mac mini is not a bake machine (old October checkout, no lightmaps, no rclone.conf). A chat stays linked to whichever Mac last answered: quit the app on the other one.

## Not run
Web tests beyond a load-and-walk on wing 1 and the outside (both years, 0 errors); MENU full; CAST COUNT; stockrooms; the Rougarou suites (the Woolworth layout change's effect on its aisle route is unchecked).

## Cleanup for Steven
- Air (5.6 GB free): `_stage54/` (2.9 GB), `_stage49b` … `_stage53`, `mall-bake-49b`, `mall-bake-51*`, `mall-bake-53` once mall-bake-54 is proven, `_to_delete_d52/`, `mall-bake-54/_xfer54/`.
- GitHub: `tmp/publish` branch; merged `ws/*` branches (keep `ws/device-bakeoff`).
- R2 holds four builds (d51, d52, d53, d54); the script could not prune from the cloud.
- Chat: the 25 build-file cards were transport.
