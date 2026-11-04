# Handoff: director session, Demo 50 (Nov 3, 2026)

**State: publishing (ids filled in by the next commit).** `godot-build` = pending, desktop repo `main` = pending, `main` = `int-50`
`ba3de3e` plus this handoff. Live: https://stevenboudreaux.github.io/Houma-Mall-Rewind/. The cloud box can't reach
github.io, so the live page was not checked: **Steven, please look at the live page** (Demo 49b was never
confirmed either).

## What Demo 50 is
Round 1 merged (Nov 3): ECON, MENU2, WALK, PUSHER2, CHARS pack, RES prizes, EXT analysis. On the 49b Ultra day bakes
of wings 1, 2, 4, 5, both years. No rebake: round 1 changed no wing geometry; every stand-in was recaptured here
because the new item textures change every wing's hash.

## Packs (MB; desktop = mobile)
| Wing | 1995 | 2026 |
|---|---|---|
| 1 | 85.41 | 42.38 |
| 2 | 83.14 | 65.69 |
| 3 outside | 32.21 | 17.84 |
| 4 Sears / Lynn's | 37.94 | 32.76 |
| 5 Dillard's | 39.63 | 34.64 |
| 6 cinema lobby | 21.81 | 21.94 |
| shared: items 22.64, chars 42.23, chars_w1 0.39, chars_w2 1.88 | | |

Wing 1 fell from 98.6 to 85.4 MB: the carried items now ship once, in the shared `items` pack. Sites: main 622 MB,
desktop 582 MB.

## Checks (web export, swiftshader, one browser at a time)
- Walk test from each wing's spawn: MOVED in all 12 packs, 0 errors. (`wing.json` spawn is `[x, z, yaw, ?]`; the
  spawn is a free tile, so `WALK_CAM=x,z,yaw,0` works everywhere.)
- doortest both years: 1->3, 1->4 (Sears), 4->3, 2->5 (Dillard's): all CROSSED, 0 errors.
- Directory: `dirtest.js ONLY=jump` wing 1 -> Dillard's (wing 5), 0 errors. The 1995 -> 2026 trip from the kiosk
  (E, then Y) reloads into 2026 at the same spot in 66 s, 0 errors (`d50-directory-trip-2026.jpg`).
- Tickets: `redemption_webtest.py` REDEMPTION WEB OK, portrait and landscape (`d50-redeem-phone-popup.jpg`).
- Baked renders at the spawns: wings 1 and 2 clean (`d50-w1-spawn-baked.jpg`, `-w2-`), 4, 5 2026 too.
- Not run: the headless gd test suites, INTERACT, PRIZES, menu_webtest (round 1's own sessions ran theirs).

## Fixed here (on int-50)
- `tools/publish_build.sh`: pushes godot-build through `tmp/publish` in ~120 MB pieces (`PIECE_MB`), reads the remote
  ref back after every push (godot-build and the desktop repo's main) before saying published, lowercases the repo
  URLs. The old `| grep … || true` had hidden a failed 1 GB push. Tested against a local bare repo, then live here.
- `tools/stores/directory/dirtest.js`: the kiosk spots were 2.2 m from the kiosk; `scripts/interact.gd`'s REACH is
  1.6 m, so the prompt never showed and the jump step could not open the map. The kiosk's own `in_reach()` (2.4 m)
  is no longer consulted by anything; decide whether the shared reach should ask it (a one-line change in
  `find_target`), or leave 1.6 m.

## Lessons
- The box has 2 CPUs and 7 GB. Three swiftshader browsers at once: "Target crashed", 120 s screenshot timeouts, and
  black frames with "WebGL: too many errors" on the big wings. All of it went away one browser at a time. Never
  parallelise the web tests here.
- `pkill -f` matched its own shell again (exit 144). Use `pgrep`/`kill` with a pid.
- The container restarted once mid-session; the repo, Godot, the export and the test results survived, only the
  running tests were lost. Keep every long step in its own log under `.scratch/`.
- `signs.json` 404s in a scratch build are expected (it lives in the tracked `play/`).
- Google Fonts is unreachable from the box: `ERR_TUNNEL_CONNECTION_FAILED` in every test log is that, not the game.

## Hosting: Cloudflare R2 (decided Nov 3, 9 PM)
GitHub Pages caps a site at 1 GB; the game is past it (two sites already). Steven set up a Cloudflare R2 bucket
tonight: bucket `houma-mall-rewind`, public URL `https://pub-848b5102ea0e4d78999797a799545451.r2.dev`, an rclone
remote `r2` on the Air, upload and public read tested. The project doc "Moving the game packs to Cloudflare R2"
(Steven's Southland Mall project) has the steps. **Next director job, before merging round 2:** `PACK_BASE` /
`?packs=` in `web/shell.html`, `publish_build.sh` uploads packs to `r2:houma-mall-rewind/builds/<id>/` with rclone and
pushes a small godot-build, `pages.yml` stops copying packs, the desktop repo retires, `design/godot-build-hosting.md`
rewritten. Steven should rotate the `mall-publish` API token (its secret was shown on screen once).

## Round 2 (not merged)
Branches pushed tonight: `ws/shops`, `ws/food`, `ws/prizes`, `ws/cucos` (several commits each; cucos's first was
marked WIP). No exterior branch seen. Merge after the R2 switch; one Mac bake for every wing touched; publish to R2.

## Cleanup
- 8 `tmp/d49b-*` branches and now `tmp/publish` on GitHub: deletion from the cloud is refused (403). Steven deletes them.

## Open for Steven (carried)
- Does the LSU shirt match the lady he means (he remembered "Houma")?
- Food prices he hasn't set; SHOPS is guessing them.
- Her line after the coupon, and repeat lines after the Cuco's ending: not written.
- Virtual pets are a 1997 anachronism in 1995; kept for now.
- How money is earned: TBD.
- RadioShack prices are unverified estimates.
- M's guesses still unconfirmed; opening text, cinema locked message, cast sheet, which three 2026 NPCs.
- Store rooms next (video research via Chrome on the Air): Payless, Victoria's Secret, billiards, Spencer's (with
  facade), Aéropostale, Foot Locker both years.
