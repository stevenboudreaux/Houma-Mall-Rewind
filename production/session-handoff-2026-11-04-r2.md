# Handoff: packs on Cloudflare R2 (Nov 4, 2026, branch ws/r2-hosting)

**State: code done and tested against stand-ins; not merged, not live.** No real upload has happened: on
Nov 4 both Claude shells (the cloud box and the Air's) got a 403 from their proxy for
`*.r2.cloudflarestorage.com` and `*.r2.dev`. Steven is adding both to Claude's allowed domains and giving the
cloud environment `R2_ACCESS_KEY_ID` / `R2_SECRET_ACCESS_KEY` / `R2_ENDPOINT` (a new token: rotate
`mall-publish`, its secret was on screen once). The design is `design/godot-build-hosting.md` "Packs on R2".

## What changed
- `web/shell.html`: `MALL_R2` (the bucket's `builds/`), `MALL_R2_BUILD` (the published id, or `?packs=<id>`,
  ids only); `MALL_PACK_BASE()` sends every pack there when set.
- `tools/publish_build.sh`: R2 by default (`R2=0` = the two sites): upload with rclone, check sizes and the
  public URL's CORS, `UPLOAD_ONLY=1`, a pack-free godot-build naming the id, prune to `KEEP` (3). Test-only
  overrides: `R2_PUBLIC_TEST`, `PAGE_ORIGIN_TEST`, `PUBLISH_ORIGIN_TEST`.
- `.github/workflows/pages.yml`: accepts a build without packs when its page names an R2 build.
- `tests/unit/hosting/pack_base_test.js` (`node …`, PACK BASE OK), `tools/qa/r2_webtest.py`.

## Tests (cloud, Nov 4)
- PACK BASE OK: the published id, `?packs=`, the old two sites, and 8 hostile `?packs=` values refused.
- `publish_build.sh` with rclone's local backend as the bucket, a CORS server on :8766 as the public URL, a bare
  repo as GitHub: R2 dry run passes; a pre-R2 export refused; `R2=0` passes; a missing bucket and a dead public
  URL each stop with their message; upload-only leaves the remote untouched; four publishes each pushed a
  pack-free godot-build (155 MB) naming its id; pruning kept the newest three.
- `r2_webtest.py` on that godot-build's page (MALL_R2 pointed at :8766): wing 1 ready in 28 s, E crosses to the
  outside, a reload is ready in 14 s; every pack from the bucket folder; 0 errors
  (`production/qa/evidence/r2-packs-w1-crossorigin.jpg`, `r2-packs-w3-after-door.jpg`).
- Not tested: the real bucket, a phone, Cache Storage across sessions on the real origin.

## To go live (a director session with the R2 domains and secrets)
1. Merge `ws/r2-hosting` into the integration branch (int-51) before its export, so the export carries the
   `MALL_R2_BUILD` line.
2. `rclone` from its GitHub release (`v1.73.2` worked; rclone.org may be blocked).
3. `UPLOAD_ONLY=1 tools/publish_build.sh <export> "<msg>"`, play `…/builds/<id>/index.html` from the bucket,
   then the full publish with the same `BUILD_ID`, then main (pages.yml) as usual.
4. Once live and checked: Steven deletes the `Houma-Mall-Rewind-desktop` repo.

## Lesson
Playwright's sync API delivers page events only during its own calls: wait with `page.wait_for_timeout`,
never `time.sleep`, or every console line arrives at the end (two false "never ready" runs tonight).
