# QA and lighting test tools (Godot mall)

Added Oct 5, 2026 on the `godot-4.7-ultra` branch. `tools/*` is excluded from the web export.

- `movetest.py` — headless Chromium check of a web export: screenshots at fixed `?cam=` spots plus a touch-drag walk test (`?debug=1`). Needs `python3 -m http.server 8765` at the repo root.
- `lumatest.sh <name> <exr> [lmbake]` — puts a test lightmap into the project, imports, exports to `.scratch/builds/<name>`, shoots the Sears hall (W/E) and Shoe Dept. court, and prints mean luma. Use it to compare bakes by what the game shows.
- `hallglow.gd -- <outdir> <factor>` — writes `gen/H1a.res` and `gen/H1b.res` with emission scaled by `<factor>` (same effect as `HALL_GLOW` in build_mall.gd, without a full rebuild).
- `noemit.gd -- <outdir>` — writes copies of all `gen/*.res` with emission off, to measure how much of a bake comes from glowing surfaces.

Run the .gd tools with `godot --headless --path . --script res://tools/qa/<tool>.gd -- <args>`.

- `preview.sh <module|store:NAME> <out-prefix> "<x,y,z,yaw,pitch;...>" [opts-json] [lit|dark]`: renders one Pocket Change prop module, or a store with its hall, in ~30 s without building the mall or baking (xvfb + `--write-movie`, `preview.gd` reads PNGs raw). It uses realtime light, so it is for modelling and texture checks only.
- `bakecheck.sh <prefix> <night|day> [cams-json]`: after a Mac bake, puts the staged lightmap in the project, exports and shoots the cameras (see its header).

## VR (design/godot-vr.md)
- `vrtest.py <url-path> <out-prefix> <iwer.min.js> <webxr-layers-polyfill.min.js>`: the VR mode
  against an emulated Meta Quest 2 in a headless browser (`npm i iwer webxr-layers-polyfill`, the
  files are in each package's `build/`). Serve a folder holding the export together with `play/`'s
  pages on :8765. Prints ALL OK. Its in-VR screenshots are black; it checks behaviour.
- `vrboard.gd`: the VR prompt board rendered natively (hint, menu, seam prompt).
- `packcontents.py list|check|refs|write …`: what is inside the web packs. `refs <export>`: every res:// path a scene or resource in a wing pack names ships in a pack that map loads; `check <export>`: that, plus each pack's files against `pack_manifest/<pack>.txt` (desktop = mobile); `write <export>` rewrites the lists. Run by `export_web.sh` (refs) and `publish_build.sh` (check); `packcontents_test.py` tests it on synthetic packs (design/godot-build-hosting.md "Pack contents", Nov 8 2026).
- `packformats.py <a.pck> [b.pck …] [--files] [--json out]`: lists the textures inside web packs by how they are stored (S3TC/BPTC, ETC2/ASTC, WebP lossless/lossy, raw). A desktop pack must show no etc2/astc, a mobile pack no s3tc/bptc (design/godot-build-hosting.md, Nov 1 2026).
- `frametimes.py <url-path> <out.json> [--secs 30] [--runs N] [--size 480x270] [--noflip]`: load phases (wasm, pack, setup, card, control) and every frame interval for N s after control, in headless Chromium on SwiftShader; compare runs, not devices (design/godot-performance.md). `?warm=0` in the URL turns the NPC warm-up off for A/B.
- `avatar_test.gd` (native, unbaked), `avatar_webtest.py` (web build), `avatar_sheet.gd` (every
  avatar body, own colours vs recoloured): the avatar and the first / third person view
  (workstream V, `design/godot-avatar.md` "Checks").
- `walk_webtest.py <url-path> <out> "<spot>:x,z,yaw,pitch[=xmax:…];…"` (workstream WALK, Nov 3 2026):
  third-person walking and running speeds in the web build (`?debug=1` prints `DBG gait=` from
  `scripts/avatar.gd`): ground speed against TP_WALK 3.0 / run 6.6 m/s, the clip played at ground
  speed, the camera keeping up, the player always on free floor and inside a spot's bounds (a glass
  pane run at), a phone's full-stick touch walk; a 4-frame strip per walk and run.
  `avatar_test.gd` now also checks the run (sprint clip at ground speed, the camera pivot on the player).
- Workstream S (Nov 2 2026; design/godot-wings.md "Wings 4-6", the room wings 4 Sears / Lynn's, 5 Dillard's level 1, 6 the cinema lobby):
  - `wsS_thresholds_test.gd [-- 2026]` (headless): the Sears and Dillard's openings both ways (wing, position, facing), the cinema gate (locked message, the stick opens it, the flag saved, wing 6 and back, a reload keeps it open), the directory's jumps into wings 4 and 5. Prints `WSS TEST OK`.
  - `wsS_webtest.py <url-path> <out> [1995|2026] [sears,dillards,cinema,jump]`: the same on a web export, with screenshots (the opening's picture, the crossing card, inside, back; the gate down / locked / up / lobby / after a reload).
  - `doortest.py <url-path> <out> [wing cam to-wing [2026]]` now takes any wing's door or threshold, e.g. `4 -4,-144.4,180,0 3` (Sears side exit), `5 28.4,98.2,90,0 3`, `6 -60,-84.7,180,0 1`.
  - `movetest.py`, `packformats.py`, `frametimes.py` take the wing in the URL / the pack paths: `index.html?wing=4`, `w4.desktop.pck` etc.
- `corner_walk_test.gd [-- --year=2026]` (ws/corner-2026, Nov 4 2026; design/corner-2026-c2.md): headless walks at the
  C2 / main-entrance corner: the court patch to Franks' front, Orange Julius' plain court wall in 1995 (Zales' front
  in 2026), OJ's walk-up front, the patch from the east hall. Prints `CORNER WALK OK (<year>)`.

## Owner mode (design/godot-owner-mode.md, Nov 4 2026)
- `owner_test.gd -- --wing=6 --out=…` (native, xvfb): owner vs visitor screen, the OWNER tab's directory (list, question, jump, year keys) and tools, then the owner's Y year switch.
- `pictures_test.gd -- --wing=1 [--year=2026] --out=…` (native, xvfb): the owner's pictures on framed ads and poster panels, chooser and publisher mocked.
- `pictures_publish_test.js` (Node): `window.mallPictures.publish` against a mocked GitHub contents API.
- `pictures_pick_webtest.js [shot.png]` (Node + Playwright): the page's picture chooser (shrink to 1024 px JPEG, Cancel, Original picture).
- `arcade_nes_webtest.js [evidence-dir]` (Node + Playwright): NES-only cabinets, `emu.html` served locally, GitHub and the emulator CDN mocked. `arcade_nes_shot.gd -- --id=pc.video.37 --out=…`: an NES cabinet, natively.

- `stream_test.gd [-- --kind=mobile]` (SEAMLESS, Nov 13 2026; design/godot-wings.md "Seamless streaming"; headless): the
  wing 1 / wing 2 seam with streaming on: the neighbour comes in, both wings' stand-ins of each other are hidden, the
  handoff both ways (the prize counter and the Stockrooms change hands), and with `--kind=mobile` the unload far from
  the seam. Prints the streamer's timings and `STREAM TEST OK`.
- `stream_webtest.py <url-path> <out-prefix> [pack] ["wing cam"]` (web build, `?stream=1`): the same walk in the
  export: no load screen, no page load, the address bar's `?wing=` follows, timings, memory (browser processes and
  JS heap: before, neighbour in, after the handoff), 0 page errors; screenshots before / in / cross / after.
  Serve the build folder itself on :8765. Prints `STREAM WEB OK`.
