# PHONE-MEMORY: phones stream seamlessly (Mon Nov 16, 2026), stage 1 of 3

Worker job for the director. Branch `ws/phone-memory` from `ws/seamless-upfront` (`74cef19e`). Not merged, not
baked, not published, nothing uploaded. Findings: `production/qa/evidence/wsPHONE-MEMORY-findings.md`. Design:
`design/godot-wings.md` "Phone memory", `design/godot-build-hosting.md` "The phone pack's texture memory".

**Stopped at the end of stage 1, as the brief says:** the director puts a phone preview on R2 and Steven reads the
numbers off his iPhone. Stage 2 (options with shots) starts from those numbers.

## The phone preview on R2 (Nov 17 2026; a one-off upload the director asked for, with Steven's OK)
A preview, not a publish: `tools/publish_build.sh` was not run; `main`, `godot-build` and every other build on R2
are untouched (none deleted or overwritten).

| | |
|---|---|
| **BUILD_ID** | `20261117-0522-6ba34fcc` (branch head `6ba34fcc`) |
| Files | **36** (12 wing packs x 2 kinds, `items` and `common` x 2, and the 8 page files `index.*`), 1,660 MB |
| One wing, streaming off (as phones ship) | https://pub-848b5102ea0e4d78999797a799545451.r2.dev/builds/20261117-0522-6ba34fcc/index.html?qa=1 |
| Streaming on (the case that crashed) | https://pub-848b5102ea0e4d78999797a799545451.r2.dev/builds/20261117-0522-6ba34fcc/index.html?qa=1&stream=1 |

- **Export:** `tools/export_web.sh /home/claude/build58` on this box: every wing of both years, both kinds, the
  outside and the cinema lobby; `packcontents` every reference shipped.
- **Upload:** boto3 to bucket `houma-mall-rewind`, `builds/20261117-0522-6ba34fcc/`, with `publish_build.sh`'s rclone
  settings (S3, Cloudflare, private ACL, no bucket check) and content types by extension (`index.wasm` as
  `application/wasm`); checksums only when required; the script refused a folder that already had objects. The
  director named `claude/session-handoff-2026-11-16-air-cleanup.md` section 1 for the settings; that is a project
  document this cloud box cannot open, so the settings came from `tools/publish_build.sh` instead. R2's listing
  afterwards: 36 objects, every size equal to the export.
- **Served:** `curl -I` of every file at the public address: 36 x 200, every `Content-Length` equal to the export,
  CORS header present for `https://stevenboudreaux.github.io`.
- **Plays:** Chromium (swiftshader) loaded `index.html?qa=1&pack=mobile` from R2: the load screen lifted at 39 s, 0
  page errors, `window.__mallMem` live (phone pack, streaming off, wing 1 1995, 812 MB of textures, 142 MB wasm heap).
- **Note for the next publish:** R2 now holds 7 builds. `publish_build.sh` keeps the newest `KEEP` (3) and deletes
  the rest, so the next publish will remove this preview with the older ones unless `KEEP` is raised for it.
- **What Steven does:** findings section c, "What Steven reads off his iPhone". The first link, open the menu, the
  QA tab; then the second link; if Safari reloads the page, the QA tab's LAST VISIT block (a screenshot is enough).
  The same two on the iPad (its "pack" and "formats" lines). Stage 2 waits for these numbers.

## Steven's iPhone, Nov 17 2026 (the preview above)
- **Both links crashed:** `index.html?qa=1` (streaming off, one wing, as phones ship) and `index.html?qa=1&stream=1`:
  Safari's "A problem repeatedly occurred" (the page's process killed and reloaded twice). Steven: "As phone ships
  stall screen first, merged wings 2nd" (read here as: the as-shipped link hung on the load screen, then crashed;
  the streaming link crashed too). Screenshots in the conversation, not in the repo.
- **So one wing does not fit either, with this build on this phone.** The brief's "with streaming off the same build
  runs" was the int-55 preview (`20261114-1715-5ba126d8`); this preview is `74cef19e` (UPFRONT) plus the readout.
- **No readout numbers came back:** the QA tab needs the game running, and the crash crumb (`mall-mem-last`) is
  first written when the game's scripts start, after the packs are in. A crash on the load screen leaves none.
- In the browser test the load screen is the page's own peak: the JavaScript heap was 457 MB (the downloaded packs,
  then their copies in the engine's file system) while the first wing's textures were already at 393 MB on their way
  to 812 MB (`.scratch` series, `s0_1995`). Not measured on the phone.

## Steven's iPhone, Nov 17 2026, second round: the cause of the load-screen crash
- int-55 `?stream=0` runs; this preview and the UPFRONT build crash. The QA tab (`?qa=1&stream=0`) says why:
  **desktop pack** on an iPhone whose Safari offers S3TC + BPTC (and ASTC hdr+ldr, ETC2). The page picks the pack by
  texture formats, and the streamer's kind follows the pack, so this phone got the computer path: UPFRONT's whole
  interior behind the load screen.
- One wing runs on either pack: 832 MB of textures, 0.9 GB of video memory, a 142 MB wasm heap. The phone pack with
  streaming on (`?qa=1&pack=mobile&stream=1`) crashes: two mall wings do not fit.
- The ASTC HDR lightmap point of the findings is withdrawn for the iPhone (both packs report the same memory).
- **For the director, before UPFRONT goes anywhere public:** phones must take the phone path whatever formats they
  offer (decide the kind by device, e.g. touch + small screen or the user agent, and keep the pack choice by formats;
  an iPhone could then take desktop-format textures with phone streaming). Not changed in this branch (stage 1);
  ready to do as the first stage 3 item or a small job of its own.
- Still wanted from the phone: open `…/index.html?qa=1&pack=mobile` once more and screenshot the QA tab. Its LAST
  VISIT block is the streaming crash's last sample and events (the crash crumb).

## A. Device detection fixed (Nov 17 2026, director's call: now, not stage 3)
- `web/shell.html` `mallDeviceKind` → `window.__mallDevice`; `MALL_UPFRONT` is looked up by device, not pack.
  `scripts/wing_stream.gd` takes its `kind` from `window.__mallDevice` (then the pack, as before). The pack is still
  chosen by formats. Overrides: `?device=`, an explicit `?pack=`, `?stream=0|1`. Design: `design/godot-wings.md`
  "Phone memory", "Device, not pack".
- **Steven's iPhone now:** desktop pack, phone behaviour (streaming off, a load at each border, as Demo 54).
- QA tab: "pack: …" and "streaming behaviour: …" on separate lines.
- **TEST-DEBT F1 fixed** in the same file: `_resync()` waits while the player is in the Stockrooms and runs in the
  existing "_was_away and not away_now" branch. `tools/qa/stream_f1_test.gd`: STREAM F1 TEST OK.
- Tests: `tools/qa/device_webtest.py` DEVICE WEB OK (a fake iPhone on a GPU with S3TC + BPTC: desktop pack, phone
  behaviour, no wing asked for up front or streamed, wing 1 alone 60 s after the lift; a computer: up front 2, 4, 5);
  the 8 suites OK; `stream_test.gd` desktop / mobile / `--fail` OK; `stream_upfront_test.gd` desktop and mobile OK.
  `stream_natural_walk_webtest.py` (computers, desktop pack, build59 = this fix): **NATURAL WALK OK (1995)**: lift
  after 1395 s, 560 m in 1996 s, no load screen, no prompt, no stop at a border (both department stores, Corn Dog 7);
  **NATURAL WALK OK (2026)**: lift after 1122 s, 550 m in 2260 s. Two earlier 1995 tries failed while Godot shot
  renders shared the box: one timed out focusing the canvas after the lift (the test now waits as long as for a
  screenshot), one ended its "back in wing 1" leg still inside Sears; run alone it passed.
- Evidence: `production/qa/evidence/wsPHONE-MEMORY-device-fake-iphone-qa-unbaked.jpg`.

## B. Stage 2 preview on R2 (Nov 18 2026; the director's one upload for stage 2, same rules as Nov 17)
A preview, not a publish: `tools/publish_build.sh` not run; `main`, `godot-build` and every other build on R2
untouched (none deleted or overwritten).

| | |
|---|---|
| **BUILD_ID** | `20261118-0119-74012533` (branch head `74012533` plus option **4b**: groups 1 + 2 as S3TC / ETC2) |
| Files | **36**, 1.9 GB (both kinds); one kind's packs 975 MB (as shipped: 810) |
| Links, and what Steven does | `production/qa/evidence/wsPHONE-MEMORY-options.md`, "What Steven can try on the phone" (five links, link 4 on the Nov 17 preview) |

- **4b is not in the branch.** It came from a copy of the project (`/home/claude/pv`) with
  `.scratch/doc/vram_switch.py --apply` (914 `.import` files set to `compress/mode=2`; 319 kept lossless: signs,
  directory, ads, posters, stand-ins, UI). Reimport, then `tools/export_web.sh /home/claude/build60`: packcontents
  every reference shipped. The branch's import settings are unchanged.
- **Upload:** the same boto3 script and settings as Nov 17 (refuses a folder with objects): 36 objects listed, every
  size equal. **Served:** `curl -I` of all 36 at the public address: 200, `Content-Length` equal; `index.wasm` as
  `application/wasm`; the CORS header for the game's site present.
- **Download, measured:** the 1990s phone path (wings 1 + 2, items, common) 329 → 428 MB (+99 MB; the estimate was
  +32: it missed the items pack, 84 → 176 MB). 2026: 271 → 347 MB.
- **R2 now holds 8 builds.** The next `publish_build.sh` (KEEP 3) would delete both previews unless KEEP is raised.

## Steven's iPhone on the 4b preview, Nov 18 2026 (link 1: `?qa=1&stream=1`, desktop pack, 1990s)
- **First try:** wing 1 ran for a minute or more; at the wing 2 border the load screen came (no tap): the streamer's
  "could not be streamed: loading it the old way" fallback (`_fallback`, wing 2's state "failed"). Wing 2 then
  loaded by itself and the page crashed soon after. Why wing 2 failed (a slow first download of the 108 MB pack, or
  memory) is not known: the crash crumb was overwritten by later visits before it was read.
- **Second try (packs now in the cache), QA tab at 22.5 s, standing in wing 1 near the start:** **wings in [1, 2]**,
  streamed {2: in}, **textures 655 MB, all video memory 747 MB (peak 751)**, meshes 92 MB, **fps 24**, wasm heap
  150 MB, streamed pack bytes 104 MB. **Two 1990s wings fit and run with 4b** (estimated 0.71 GB; as shipped two
  wings ≈ 1.34 GB crashed). fps is down from 45 (one wing, as shipped) to 24.
- **Link 5 (`?qa=1`, 4b, streaming off, a load at each border), walked to Dillard's:** inside Dillard's (wing 5
  alone) textures 341 MB, video 382 MB, fps 55, wasm heap 115 MB. Its LAST VISIT (the wing 2 page on the way, left
  normally): **wing 2 alone, textures 536 MB, video 724 MB**, wasm heap 166 MB. So wing 2 alone with 4b is nearly what
  the streamed pair [1, 2] showed (747 MB): the pair's figure was taken 22 s in and may not have had all of wing 2's
  textures yet, or the two wings share many textures. Not settled; a QA reading of [1, 2] after a minute would say.
- **Link 1 again (Nov 23), the full walk.** LAST VISIT of the crashed try: **did NOT end normally**; the last
  sample at 101.2 s: wings [1, 2] {2: in}, textures 655 MB, **video 747 MB**, wasm heap 150 MB, packs 104 MB; events
  only up to 19.6 s (wing 2 in). So **two wings sat at 747 MB for about 80 s and the page died within a second of
  the next sample**: a peak while something changed (the walk across: a handoff, or wing 5's 40 MB pack fetched,
  copied and loaded), not the steady load. The try after it, QA tab at 82 s in Dillard's: **wings in [5, 1, 2]**
  (home 5; 1 and 2 streamed), textures 668 MB (peak 687), meshes 203 MB, **video 870 MB (peak 892)**, **wasm heap
  216 MB**, **fps 9**. Three 1990s wings stayed up with 4b, at 9 fps.
- **What this says:** with 4b the steady memory is not the limit (three wings, 0.87 GB video + 0.22 GB heap, ran);
  the crash came at a change. And wing 1 stays in while the player is in Dillard's (`far_m` mobile 110 m reaches
  it), which costs memory and fps (24 with two wings, 9 with three). For stage 3, beyond 4b: drop the wing behind
  sooner (or never hold three), and lower the peak at a change (option 2, one held copy of each pack; the page held
  104 MB of packs at the crash).
- **Link 4 (Nov 23): 2026 as shipped, phone pack, streaming on.** Crashed. LAST VISIT: did NOT end normally; the
  page started in wing 2 (home 2), wing 1 streamed in by 20.7 s, wing 5 (Dillard's) started to enter at 20.7 s and
  the page died: textures 870 MB, **video 1033 MB**, wasm heap 234 MB, packs 80 MB. The next try reached the same
  state at 18 s (video 1037 MB, **fps 5**). **The 2026 estimate (0.80 GB for two wings) was low; 2026 as shipped
  does not stream on the iPhone.** The 2026 combination in the options doc is struck out.
- Not yet seen: links 2 (phone pack, 1990s) and 3 (2026 with 4b).

## Done / partly / not started
| Item | State |
|---|---|
| Baseline: the 8 headless suites on `74cef19e` | **Done.** All OK (SHOP 200, CUCOS 89, FLAGS 31, INVENTORY 45, REDEMPTION 32, ECON 52, MENU UNIT 64, INT D49). Same on this branch. |
| 1a. Every texture and lightmap per mobile pack and common pack, both years, with totals by kind | **Done.** Findings section a; every file in `wsPHONE-MEMORY-textures.md`; `tools/qa/packmemory.py`. |
| 1b. Where one wing's memory goes, then two | **Done** (native engine counters plus the browser; the split of about 300 MB of engine-side texture memory is estimated). |
| 1c. `?qa=1` readout in the menu, `window.__mallMem` | **Done.** The QA tab; crash crumb in localStorage. Looked at in Chromium at phone width (shots in evidence). |
| 1d. Is it memory | **Done as a method:** what differs 4 s in, how to tell from the readout, Web Inspector and the iPhone's `JetsamEvent` logs. Not proven: needs the phone. |
| 1e. iPhone / iPad Safari formats and Godot | **Done** (from documentation and Godot's source; the readout's formats line checks it on the devices). |
| Stage 2: options with shots and numbers | **Done; stopped for Steven's choice.** `wsPHONE-MEMORY-options.md`: numbers against the iPhone's 0.9 GB, matched shots from real exports (as shipped against 4b, both packs, both years), preview `20261118-0119-74012533` with five links. |
| Stage 3: build Steven's choice | Not started. |

## The findings in five lines
1. One 1990s mall wing on the phone pack: about 0.8 to 0.9 GB of textures; with the neighbour about 1.2 to 1.4 GB.
   Plus a wasm heap of 142 MB going to 204 MB, and the neighbour's pack held twice in the page. 2026 is about half.
2. The mobile lightmaps (ASTC HDR) are decompressed on every phone to 8 times their size (Godot's web renderer never
   uses ASTC HDR): 100.7 MB per 1990s mall wing instead of 12.6.
3. Most of the rest is lossless WebP decoded to 4 bytes a pixel: surface pictures, the Blender items' 2048 maps (up
   to 50 MB for one item), the cast's 2048 heads.
4. The department stores are cheap (30 to 40 MB each); the second mall wing is the cost.
5. An iPad with S3TC + BPTC would take the desktop pack and the desktop path (everything up front).

## For the director
- **The phone preview:** export this branch as usual (`tools/export_web.sh`; nothing in export or publish changed) and
  upload it. Steven's steps: findings section c, "What Steven reads off his iPhone" (`?qa=1`, then
  `?qa=1&stream=1`, the QA tab, LAST VISIT after a crash, the same on the iPad).
- **Export:** a test export is at `/home/claude/build57` on this box (wings 1, 2, 4, 5, both years, both kinds,
  shared packs; no outside, no cinema lobby). Make your own full export for R2.
- **Rebake:** none. No scene, mesh, lightmap or texture changed; the stand-ins are not stale.
- **Shared files touched** (small hunks): `scripts/wing_stream.gd` (`_init` makes `MallMem` with `?qa=1`),
  `scripts/menu/menu.gd` (a QA tab only while `MallMem` exists). New: `scripts/mall_mem.gd`,
  `tools/qa/packmemory.py`, `tools/qa/mem_native.gd`, `tools/qa/mem_webtest.py`. `data/stream.json`,
  `web/shell.html`, `export_presets.cfg`, `tools/export_web.sh`, desktop packs: unchanged.
- `CLAUDE-CLOUD.md` setup step 3 fails as written when run from the project folder (`git archive` paths are
  relative to the current folder): run `git archive origin/godot-build lightmaps standin` from the repository root
  and untar into the project. Not changed here.
- Python Playwright was not installed on this box (only Node's); `pip install playwright` and the pre-installed
  Chromium (`/opt/pw-browsers/chromium`, which `mem_webtest.py` uses) were enough.

## Not verified
- Anything on an iPhone, an iPad or a real GPU. Whether the crash is memory.
- `stream_natural_walk_webtest.py`, packtest, seamtest: not rerun (stage 1 changed no behaviour; the readout is made
  only with `?qa=1`). They are stage 3's gates.
