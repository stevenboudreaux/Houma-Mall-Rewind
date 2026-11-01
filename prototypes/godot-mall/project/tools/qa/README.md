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
- `packformats.py <a.pck> [b.pck …] [--files] [--json out]`: lists the textures inside web packs by how they are stored (S3TC/BPTC, ETC2/ASTC, WebP lossless/lossy, raw). A desktop pack must show no etc2/astc, a mobile pack no s3tc/bptc (design/godot-build-hosting.md, Nov 1 2026).
- `frametimes.py <url-path> <out.json> [--secs 30] [--runs N] [--size 480x270] [--noflip]`: load phases (wasm, pack, setup, card, control) and every frame interval for N s after control, in headless Chromium on SwiftShader; compare runs, not devices (design/godot-performance.md). `?warm=0` in the URL turns the NPC warm-up off for A/B.
- `avatar_test.gd` (native, unbaked), `avatar_webtest.py` (web build), `avatar_sheet.gd` (every
  avatar body, own colours vs recoloured): the avatar and the first / third person view
  (workstream V, `design/godot-avatar.md` "Checks").
