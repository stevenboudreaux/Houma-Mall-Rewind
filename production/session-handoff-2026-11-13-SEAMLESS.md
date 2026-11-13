# Worker handoff: SEAMLESS (Fri Nov 13, 2026)

Branch `ws/seamless` from main `81cb3ba9` (Demo 54). Brief: `claude/briefs-2026-11-13-seamless.md` (project doc), with
the director's change for this run: stage 1, then stage 2, stop, report to the director; stage 3 not started.
Not merged, not baked, not published, nothing uploaded.

## Done / partly / not started
| Stage | State |
|---|---|
| 1. Measure and report | **Done**, with gaps named in the doc: `production/qa/evidence/wsSEAMLESS-findings.md`. Not measured: anything on a real phone or GPU; memory with all interior wings in (only one border streams); browser memory for wings 4 to 6 and 2026. |
| 2. Wing 1 ↔ wing 2, 1990s | **Built and tested, off by default.** `?stream=1` turns it on. Geometry, lighting, floors, walking, the handoff of every per-wing system, phone unload: done. **Partly:** the neighbour's people and loose items appear at the handoff, not before; the crowd respawns at the border. |
| 3. The rest | Not started: thresholds (Sears, Dillard's, cinema), 2026, desktop "everything", per-wing systems spanning wings, the common pack, retiring interior stand-in capture. |

## What changed (files)
- New: `prototypes/godot-mall/project/scripts/wing_stream.gd`, `data/stream.json`, `tools/qa/stream_test.gd`,
  `tools/qa/stream_webtest.py`.
- Small hunks, marked SEAMLESS: `scripts/player.gd` (attach to the streamer; arrive from a handoff; `_go_to_wing`
  into a wing that is in), `scripts/mall_runtime.gd` (`adopt(root)`, the floor loop moved into it),
  `web/shell.html` (`window.mallStream`, `window.mallStreamHome`).
- Docs: `design/godot-wings.md` "Seamless streaming", `design/godot-build-hosting.md` "Streaming a neighbour's
  pack" (with the pack overlap table), `tools/qa/README.md`.
- Not touched: `tools/build_mall.gd`, stores, exterior, characters, story data, the HUD, `tools/publish_build.sh`,
  `export_presets.cfg`.

## Evidence (`production/qa/evidence/`, web build, baked with the Demo 54 lightmaps, swiftshader)
- `wsSEAMLESS-seam-from-wing1-before-after.jpg`, `wsSEAMLESS-seam-from-wing2-before-after.jpg`
- `wsSEAMLESS-crossing-1to2-sequence.jpg`, `wsSEAMLESS-crossing-2to1-sequence.jpg`
- `wsSEAMLESS-findings.md`

## Tests
- `tools/qa/stream_test.gd`: `STREAM TEST OK (desktop)`, `STREAM TEST OK (mobile)`.
- `tools/qa/stream_webtest.py` (export of wings 1 and 2, 1990s, served locally): `STREAM WEB OK` wing 1 into wing 2
  (mobile pack) and wing 2 into wing 1 (mobile and desktop packs): no load screen, no page load, `?wing=` follows,
  0 page errors.
- The 8 headless suites all OK: SHOP 200, CUCOS 89, FLAGS 31, INVENTORY 45, REDEMPTION 32, ECON 52, MENU UNIT 64, INT D49.
- `stockrooms_test.gd`: 3 of 12 checks fail, **the same 3 with main's scripts put back** (not from this branch).
- `rougarou_test.gd`, `rougarou_stalk_test.gd`: never finish, here or on main: they wait for `RougarouAI`, which the
  game no longer makes. `rougarou_story_test.gd` not run.
- `pack_base_test.js`, `packcontents_test.py`: OK.
- Not run: the other web suites (walk, doors, seam, directory jump, redemption, shops). Streaming is off by default
  and those paths are unchanged; `seamtest.py` and `doortest.py` need no update until it is turned on.
- New web test for Dillard's → Sears → Corn Dog 7: not written (needs the thresholds, stage 3); `stream_webtest.py`
  covers the one border that streams.

## Rebake
None. No wing's geometry or lighting changed (`gen/` is untouched, so the stand-in stamps stay valid).

## For the director at integration
- The first export needs `python3 tools/qa/packcontents.py write <builddir>`: two new files in every wing pack.
- Bake and publish steps: unchanged at this stage. The stand-ins are still captured and stamped.
- To try it on any build of this branch: add `?stream=1` to the address. To turn it on: `data/stream.json`
  `"enabled"` (true, or `{"desktop": true, "mobile": false}`).
- `data/stream.json` `wing2_zones` repeats `tools/build_mall.gd` `WING2_ZONES`; keep them equal.
- The four choices are in the findings doc, section f, with my pick for each: the phone's memory (the common
  pack), a slow line at the border, when to turn it on, the stand-in after stage 3.

## Differences between the brief and the repo
- The brief's file paths are under `prototypes/godot-mall/project/`.
- Wing 6 is interior: the Southland Cinema lobby, off wing 1, never baked (the director's record was unsure).
- The stand-in storefront pictures are `Dynamic/dyn_standin`, and each wing also carries the other wing's halls as
  real meshes, plus a copy of the whole mall's shared parts: more than "panels at the border".
- The crossing today is a page reload into another pack, not a scene change, which is why streaming needed the
  page's help and a handoff of the per-wing systems.

## Open questions for Steven (through the director)
- On your iPhone, does `?stream=1` survive a walk from the east hall into the Dillard's court and back?
- Is a short stall (a fraction of a second) at the border acceptable for now, until the shoppers live across it?

## Unverified
Real-device memory and frame times; the look on a real GPU (z-fighting between the two wings' skylight glass was
not seen on swiftshader); VR with streaming; a lighting change (night) while a neighbour is in.
