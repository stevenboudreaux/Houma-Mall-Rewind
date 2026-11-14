# Godot mall build: how it is stored and served

> **Since Demo 16 (Oct 7, 2026) the mall ships in two wings:** `w1.*.pck` and `w2.*.pck` instead of
> `index.*.pck`, lightmaps `wing<n>_{night,day}.*` instead of `main_*`, and the stand-in pictures in
> `standin/` on `godot-build`. See `design/godot-wings.md`, which supersedes the file names below.

**Asked for (Steven, Oct 6, 2026):**
- "get rid of all of the waste": the texture formats a device never uses, and the unused 8-bit front paintings;
- "get rid of all of the clones in the repository and just have the one file each time that gets replaced";
- no change for his wide-screen monitor or a later VR port (Meta Quest);
- before-and-after screenshots for anything that lowers resolution. Nothing here does.

## Two game files, one per kind of GPU
- **The files:** `tools/export_web.sh <outdir>` exports the presets "Web Desktop" and "Web Mobile" (`export_presets.cfg`) and writes:
  - `index.desktop.pck`: textures in S3TC and BPTC, for computer GPUs;
  - `index.mobile.pck`: ETC2 and ASTC, for phones, tablets and VR headsets (the Quest browser takes these);
  - the shared `index.html`, `.js` and `.wasm`.
  - The two files differ only in texture formats. Every model, texture and light bake is the same resolution in both.
- **Before:** one `index.pck` carried both sets, and every device downloaded both. That was 65.9 MB at Demo 9b; each file is now 47.8 MB.
- **Both presets leave out** the old 8-bit storefront paintings (`tex/fronts/*`, `fronts.json`; off since `USE_FRONT_ART = false`).
- **Picking the file** (`web/shell.html`, before the engine starts):
  - `?pack=desktop|mobile` wins;
  - then a choice remembered in this browser (localStorage `southland-pack`);
  - then the WebGL2 extensions: S3TC + BPTC → desktop, ETC2 + ASTC → mobile;
  - then the user agent.
  - The choice is in `window.__mallPack`.
- **Safety net** (`scripts/mall_runtime.gd` `_check_pack()`): if the engine reports that this GPU lacks the formats of the file it got, but has the other set, it remembers the other file and reloads once. A sessionStorage flag stops loops.
- **Test:** `tools/qa/packtest.py <build>/index.html <out>` hides one set of extensions to imitate a phone GPU and a computer GPU, plus a wrong remembered guess. All three passed on Oct 6, as did movetest with 0 errors for both files.
- **Wide screens and VR:** texture formats don't depend on screen size or shape. A Quest port would use the mobile file's formats either way.

## Nov 1, 2026: are the desktop and mobile packs really different? (workstream H)
**The question:** since mid-October every wing's desktop and mobile packs have come out the same size to the byte
(Demo 46 live build: `w1.*.pck` 83,655,532 both, `w2` 80,427,500, `w3` 12,638,232, `w1y26` 20,714,840,
`w2y26` 51,558,108). Do both packs carry both format sets, or neither?

**Answer: neither. The split works; the equal sizes are arithmetic.** `tools/qa/packformats.py` reads every
`.ctex` header inside a pack (evidence `production/qa/evidence/wsH-packs.md`):
- The desktop packs carry only S3TC (DXT1/DXT5) and BPTC; the mobile packs only ETC2 (RGB8/RGBA8) and ASTC 4x4.
  No pack has a single texture of the other set. Per wing, the desktop-only and mobile-only files are the same textures
  (`<name>.s3tc.ctex` vs `<name>.etc2.ctex`, and the lightmap `.bptc.ctexarray` vs `.astc.ctexarray`), with
  different bytes.
- Each pair is the same size by design of the formats: DXT1 and ETC2_RGB8 are both 4 bits per pixel, DXT5 and
  ETC2_RGBA8 both 8, BPTC and ASTC 4x4 both 8. Same dimensions and mip chains give the same byte counts, so whole
  packs match to the byte. (Why the October 6 note saw different sizes is not known from the record; a guess:
  that export still had textures in a kind whose two sets differ in size, such as uncompressed fallbacks.)
- What is identical in both packs is everything that is not a VRAM texture: meshes, scenes, scripts, JSON, and
  the textures stored as WebP. Those are shared on purpose.
- Nothing was changed in `export_presets.cfg` or the `.import` files for this: there was nothing to fix.

| Pack (Demo 46 live) | Total MB | S3TC/BPTC (desktop) or ETC2/ASTC (mobile) MB | WebP lossless MB | WebP lossy MB | Rest (meshes, scenes, scripts) MB |
|---|---|---|---|---|---|
| w1 | 83.7 | 34.2 (51 + lightmap 6.3) | 20.9 (152 files) | 0 | 28.6 |
| w2 | 80.4 | 33.2 (51 + lightmap 5.2) | 11.0 (143) | 3.0 (130) | 33.0 |
| w3 (outside) | 12.6 | 4.7 (5 + lightmap 3.1) | 3.5 (17) | 0 | 4.4 |
| w1y26 | 20.7 | 6.1 (8 + lightmap 2.1) | 6.5 (16) | 0 | 8.1 |
| w2y26 | 51.6 | 8.8 (16 + lightmap 3.1) | 12.0 (84) | 2.3 (80) | 28.4 |

**Where the real texture waste is (proposal, not done: it changes the look slightly).** 736 of the project's 927
texture `.import` files are set to *Lossless* (`compress/mode=0`, plus 130 *Lossy*), so the export stores them as
WebP. Godot's editor would normally switch textures it sees used in 3D to VRAM compression (`detect_3d`), and the
Mac bakes do flip ~206 of them, but those flips are reverted after every bake (they are editor side effects,
`tools/bake_inplace.sh`), so they never ship. WebP costs little to download but:
- it is decoded on the CPU while the wing loads (one of the load-time costs in `design/godot-performance.md`);
- it sits in GPU memory uncompressed: about 136 MB in Wing 1, 217 MB in Wing 2 and 246 MB in Wing 2 2026, against
  23, 38 and 42 MB as ETC2/S3TC. On an iPhone, where Safari kills a tab around 1-1.5 GB, that is the largest single
  memory item after the meshes.
- As VRAM textures the packs would grow by only ~2-15 MB each (WebP is already small), and then they really would
  differ between desktop and mobile.
- The cost: block compression shows on hard-edged painted text and signs (slight colour bleeding at sharp edges).
  Mipmaps would stay as they are now (off for these textures), so distance shimmer and sharpness don't change.
- To do it: set `compress/mode=2` (and leave `mipmaps/generate` alone) in the chosen `.import` files, re-import,
  export. Needs before/after shots of signs and painted fronts and Steven's yes (CLAUDE-CLOUD.md: no picture
  quality change without it). Candidate first batch: the 1024² building materials (bricks, block, concrete,
  stucco), which have no lettering.

## One copy of the build, replaced each time
- **main no longer holds the build or the lightmaps** (`.gitignore`: `prototypes/godot-mall/play/index.*` and `project/main_*.exr|.exr.import|.lmbake`).
- **They live on the `godot-build` branch:** `play/` (the export) and `lightmaps/`, as a single commit that each publish replaces with `git push --force`.
- **Serving:** `.github/workflows/pages.yml` on main deploys the site to GitHub Pages: everything on main, plus `godot-build:play/*` copied into `prototypes/godot-mall/play/`.
  - It runs on every push to main.
  - `godot-build`'s own workflow starts it when a new build is pushed.
- **Pages setting:** Settings → Pages → Source must be "GitHub Actions". The "Deploy from a branch" setting would serve main without the Godot build.
- **History (done Oct 6, ~4 pm):** the old builds and lightmaps, `play3b/` and the `godot-court` build and bakes were removed from the history of every branch with `git filter-repo`, and all ten branches force-pushed.
  - Before: 755 MiB, mostly 18 old game files (239 MB) and 36 old light bakes (353 MB).
  - After: 149 MiB for the whole repository, `godot-build` included.
  - GitHub's own size figure drops only after GitHub cleans up the unreachable objects.
  - **Backup of the old history:** `~/GodotProjects/southland-backup-2026-10-06.bundle` on Steven's MacBook Air (705 MB, all 10 branches as of Demo 9b; `git clone southland-backup-2026-10-06.bundle` restores it).
  - Commit ids changed. Any older clone must be re-cloned or reset to the new `origin/main`; never push an old clone's branches back.

## Publishing a demo now
1. **Bake on the Mac.** If the project there has no lightmaps yet, copy them from the branch first: `git fetch origin godot-build && git archive FETCH_HEAD lightmaps | tar -x`, then move `lightmaps/*` into `prototypes/godot-mall/project/`.
2. **Bring the bake back and check it:** `tools/qa/bakecheck.sh` (it now calls `export_web.sh`).
3. **Commit code changes to main** as usual. There is no build or lightmap to commit.
4. **Replace the build branch** from the project folder: `tools/publish_build.sh <builddir> "chore: Godot mall Demo N build and lightmaps"`. It takes the export and the project's six `main_*` lightmap files and force-pushes them to `godot-build` as one commit, keeping the branch's README and workflow.
5. **Wait for the deploy:** Pages redeploys in a minute or two (Actions tab: "Deploy site to Pages"; check it with `gh run list -R stevenboudreaux/Houma-Mall-Rewind -L 3`).
- **For a change that needs no rebake** (probe-lit parts only), take the lightmaps from the branch, rebuild, export and do step 4.

## Wings 4-6: the room wings' packs (workstream S, Nov 2 2026)
Sears / Lynn's (wing 4), Dillard's level 1 (wing 5) and the Southland Cinema lobby placeholder
(wing 6) ship as their own packs, `w4`, `w5`, `w6` and `w4y26`, `w5y26`, `w6y26`, each
`.desktop.pck` / `.mobile.pck` (`design/godot-wings.md` "Wings 4-6").
- **Presets:** "Wing <n> Desktop" / "Wing <n> Mobile" (+ " 2026") for n = 4, 5, 6, written into
  `export_presets.cfg` by `tools/make_presets.py` (cloned from the Wing 1 pair; never edit them by
  hand). Custom features `wing<n>` / `w<n>y26` pick `run/main_scene.<feature>` in `project.godot`.
  The script also adds each anchor's opening picture to the mall wing's includes and keeps the room
  wings' data out of the other packs.
- **What a room pack carries:** its scene and meshes, the mall wings' stand-in atlases (4, 5), the
  scripts and data every wing loads, Martin Folse's stick (`models/bl_sr_folse_*`, it can be carried
  in) and, in 1995, the avatar's bodies like the outside (`npc/skins/Ch*` minus Ch06/17/36, ~16 MB:
  most of `w6`). The 2026 presets leave `npc/*` out like the other 2026 wings.
- **Export / publish:** `tools/export_web.sh` exports wings 1-6 by default (a room wing whose scene
  isn't built is skipped) and writes all twelve sizes into `PACK_SIZES`; the shell's cache name
  covers them. `tools/publish_build.sh` copies the room packs and, once baked, `wing4_*` / `wing5_*`
  lightmaps; it warns (does not refuse) while 4 / 5 have no lightmap. `DRY_RUN=1` runs every check
  and stops before pushing.

### Pack sizes (MB, desktop = mobile to the byte), measured Nov 2 2026, unbaked room wings
| Pack | Before (Demo 48 state) | After | |
|---|---|---|---|
| w1 | 91.53 | 91.52 | Sears' meshes/textures out (−0.86), its picture in the opening in (+0.84) |
| w2 | 93.52 | 91.06 | Dillard's out (−2.83), its picture in (+0.40) |
| w1y26 | 26.27 | 25.24 | |
| w2y26 | 70.65 | 67.80 | |
| w4 / w4y26 | — | 35.64 / 13.66 | Sears / Lynn's, no lightmap yet |
| w5 / w5y26 | — | 37.59 / 15.80 | Dillard's, no lightmap yet |
| w6 / w6y26 | — | 20.57 / 3.96 | the cinema lobby; 1995 is mostly the avatar's bodies |
| w3 / w3y26 | 30.89 / 13.81 | unchanged | |

- **Why wing 1 barely moved:** E's Sears skeleton is light (0.86 MB of meshes and textures: an empty
  box by design). Wings 1 and 2 still carry their Demo 48 lightmaps, baked with the anchors inside;
  the next bake drops the anchors' texels (Sears was +0.37 Mpx of wing 1's 4.76, E's note) and the
  lightmaps should shrink. The real headroom: everything Steven adds to the Sears departments and to
  Dillard's from now on lands in wings 4 / 5 (35.6 and 37.6 MB, plus their lightmaps), not in 1 / 2.
- The brief quoted wing 2 at 94.8 MB; this branch's export of the Demo 48 state measured 93.52.

## Two sites (Nov 3 2026, after the move to Houma-Mall-Rewind)

**Why.** A GitHub Pages site may hold 1 GB. Demo 49's 24 packs are 1.08 GB on their own, and the workflow
also deployed all of main (585 MB: the project source, design notes, QA pictures). From Demo 49 on, both
repos' deploys warned "Uploaded artifact size of 1166045103 bytes exceeds the allowed size of 1 GB.
Deployment might fail", and on Steven's iPhone the game stopped at "Could not start: Load failed".

**How.** Each device downloads only its own set (above), so the sets go to two sites on one origin:
- `stevenboudreaux.github.io/Houma-Mall-Rewind/` (this repo, `.github/workflows/pages.yml`): the page,
  `index.js` / `.wasm`, the phone packs (`w*.mobile.pck`), main's tracked `play/` files, the original game
  as `classic.html` and its photo files. Nothing else from main is deployed.
- `stevenboudreaux.github.io/Houma-Mall-Rewind-desktop/` (repo `Houma-Mall-Rewind-desktop`): only the
  computer packs, copied from `godot-build` by that repo's workflow (source:
  `prototypes/godot-mall/project/tools/desktop_site/pages.yml`).

`web/shell.html` (`MALL_DESKTOP_SITE`, `MALL_PACK_BASE`) asks for computer packs on the second site when
the page is on github.io, and next to the page anywhere else (local servers, `tools/qa`). One origin, so
Cache Storage, the pack prefetch and the fetch wrapper work as before. Exports made before this change
get the same lines at deploy time (`tools/desktop_site/patch_index.py`, a no-op on newer exports).

**Publishing.** `tools/publish_build.sh` refuses when either site's set reaches 0.95 GB, then, after
replacing `godot-build`, replaces the desktop repo's single commit (its workflow, `README.md`, and
`build.txt` = the `godot-build` commit); that push deploys the computer packs. A cloud session that
publishes needs `Houma-Mall-Rewind-desktop` attached with push access as well. The two deploys finish a
minute or two apart; a computer that loads in that gap may get the previous build's pack once.

**Superseded on Nov 4 2026 by "Packs on R2"** (below). The two-site code stays for older builds and for
`R2=0` rollbacks; the desktop repo is no longer pushed and can be deleted once an R2 build is live.

## Packs on R2 (Nov 4 2026)

**Why.** The two sites only bought time: Demo 50 was 1.2 GB of packs, and round 2, the exterior and the
store rooms make it bigger. Pages has no paid tier past 1 GB. Steven chose Cloudflare R2: storage is
$0.015/GB-month past a free 10 GB, downloads are free and unmetered, and a file may be up to 5 TB, so the
100 MiB pack ceiling and the 10-minute deploy timeout go too.

**Where.** Bucket `houma-mall-rewind` on Steven's Cloudflare account (account id
`c5bce683f9f04dba760f624d1558a984`), public at `https://pub-848b5102ea0e4d78999797a799545451.r2.dev`. Each
published build is a folder `builds/<id>/` with every pack (both kinds) and the page files (`index.*`), so
a folder also plays on its own at `…/builds/<id>/index.html` (without main's `play/` extras). The id is
`<UTC yyyymmdd-hhmm>-<short commit>`, so the folders sort by date. The bucket's CORS policy allows `GET`/`HEAD`
from `https://stevenboudreaux.github.io`, `http://localhost:8765` and `http://127.0.0.1:8765`.
Steven's setup steps are the doc "Moving the game packs to Cloudflare R2" (Southland Mall project).

**The page.** `web/shell.html`: `MALL_R2` is the bucket's `builds/` address; `MALL_R2_BUILD` is the id
`publish_build.sh` writes into the published page (`const set = '<id>'; // MALL_R2_BUILD`). When it is set,
`MALL_PACK_BASE()` sends every pack there; empty (local exports, `tools/qa`) means next to the page, or the
two sites. `?packs=<id>` plays another build's packs with the live page, to try a build before publishing
it. It takes an **id only**, never an address: a pack runs as code on the page's origin, where the owner's
GitHub token lives, so no link may point the game at someone else's file (`tests/unit/hosting/`). Wing
crossings, the year switch and time travel all rebuild their URL from the current one, so `packs=` carries
through. Cache Storage keeps the cross-origin packs as before (absolute URLs; CORS responses).

**Publishing.** `tools/publish_build.sh` (R2 is the default; `R2=0` is the old two sites):
1. the usual checks (stand-in stamps, packs present, shared packs); the page files alone must stay under
   0.95 GB; the export must carry the `MALL_R2_BUILD` line (exports from before Nov 4 are refused);
2. `rclone copy` of the packs and `index.*` to `r2:houma-mall-rewind/builds/<id>/`, then every file's size on
   the bucket is compared with the export, and byte 0 of `w1.mobile.pck` is fetched from the public URL
   with the page's `Origin`, which must answer 200/206 with an `Access-Control-Allow-Origin`. Any failure
   stops the publish before GitHub changes;
3. `UPLOAD_ONLY=1` stops here and prints where to play the build;
4. otherwise `godot-build` is replaced as before, minus the packs, with the id written into
   `play/index.html` and `play/r2-build.txt` (155 MB instead of 1.2 GB), pushed in pieces and read back;
5. builds older than the newest `KEEP` (3) are deleted from the bucket. Rolling back = publishing an older
   export again, or setting the id in `play/index.html` on godot-build to a kept folder.

main's `.github/workflows/pages.yml` accepts a build with no packs when its page names an R2 build.

**Who can upload.** rclone with an `r2` remote (`rclone config`, as on Steven's Air) or
`R2_ACCESS_KEY_ID` / `R2_SECRET_ACCESS_KEY` / `R2_ENDPOINT` in the environment (a cloud session's secrets),
and a network that reaches `*.r2.cloudflarestorage.com` and `*.r2.dev`. On Nov 4 Claude's cloud box and the
Air's shell both got a 403 from their proxy for both hosts; Steven is adding them to the allowed domains.
Until then the upload runs in Steven's own Terminal (`UPLOAD_ONLY=1`, then a publish with the same
`BUILD_ID` once the folder is there).

**Tested (Nov 4, in the cloud, against stand-ins):** rclone's local backend as the bucket, a CORS file server
on another port as the public URL, a bare repo as GitHub. Dry runs: an R2 pass, an old export refused,
`R2=0` still passing, a missing bucket and a dead public URL each stopping with their message. An upload-only
run left the remote untouched; four publishes each pushed a pack-free godot-build naming its id, and pruning
kept the newest three. In Chromium (swiftshader) the page from one origin loaded every pack from the other,
across a door crossing and a reload (results in `production/session-handoff-2026-11-04-r2.md`).

## Pack contents (workstream PACKS, Nov 8 2026)

**What happened.** Demo 52 (R2 `20261106-0332-76f5ee18`) went out with every pack on R2 at its size, but 81 of
the generated meshes its wing scenes use were not inside the packs: half the 1990s signs and 3D letters
(Champs, Babbage's, Sports Avenue …), shop stock (579's clothes), Sears' and Dillard's outside views, the 2026
lease cards and sign letters, the 2026 outside's entrances. Full list: `production/qa/evidence/wsPACKS-diagnosis.md`.

**Why.** After the Nov 5 bakes the editor on Steven's Mac re-saved the twelve wing scenes and wrote
`uid="…"` on references to `gen/*.res` meshes. Those files are saved by `tools/build_mall.gd` without a UID,
so on every other machine the UIDs are unknown. The scene still loads (`ext_resource, invalid UID … using text
path instead`), but the web export's dependency walk resolves the UID, finds nothing and leaves the file out.
In the browser the MeshInstance3D is just empty: no console error, so the web tests ("0 errors") passed.

**Guards (all in the project):**
- `tools/fix_stale_uids.gd` drops a `uid=` from a wing scene's ext_resource when this project's UID cache does
  not map it to that same path (the path stays; nothing else in the scene changes; no rebake; the stand-in
  stamps do not hash the scene). `--check` reports only. Run after an import.
- `tools/export_web.sh` runs it before exporting, stops when an export log still says `invalid UID`, and at
  the end runs `tools/qa/packcontents.py refs`: every `res://` path that a scene or resource inside a wing pack
  names must ship in that pack or in a shared pack the map loads.
- `tools/qa/pack_manifest/<pack>.txt`: the files inside each pack by source path (Godot's `.godot/` copies,
  `.remap` / `.import` stubs and compiled scripts folded into the file they stand for), checked in.
  `tools/publish_build.sh` runs `packcontents.py check`: the reference check, the pack set equal to the list's,
  desktop = mobile, and each pack's files equal to its list. A build that adds or drops files is refused until
  `python3 tools/qa/packcontents.py write <builddir>` rewrites the lists (it refuses while a reference is not
  shipped); the diff, committed with the build, is that build's content change log.
- `tools/qa/packcontents_test.py`: the checks against synthetic packs (no Godot).

**For the Mac bakes:** after an editor bake, run `tools/fix_stale_uids.gd` (or just export with
`export_web.sh`, which does) before committing the scenes, so the next session's export is not surprised.

## Shared packs (workstream CHARS, Nov 3 2026)

**Asked for (brief, Nov 3):** wing 1 was 98.6 MB and wing 2 97.1 MB against GitHub's 100 MB file limit
(before the Demo 49b lightmaps), and round 2 adds Blender food, drinks, books, bar stock and attendants to
these wings. New items must not count against the wing packs. Also: the web character pack did not mount,
and `models/characters/` (~68 MB) must ship per wing and year only what the presets use.

> **CHAR-STRIP, Nov 8 2026 (branch `ws/char-strip`; design/godot-avatar.md):** the character packs
> (`chars`, `chars_<map>`) and the "later" stage are **gone**: the editor, the UBC bodies (`models/ubc/`) and
> `scripts/chars/char_pack.gd` were deleted, `web/shell.html` no longer fetches anything after the loading
> card (`mallFetchLater`, `window.__mallLater` removed) and `tools/chars/pack_list.py` is gone. The only shared
> pack is `items` ("start"). The cast's files (`data/cast.json`) ship in every wing pack
> (`tools/make_presets.py` `cast_files()`) and are warmed behind the card. Rows below about `chars` are history.

**What was built.** Files used by many maps ship once, as their own packs, instead of inside every wing pack:

| Pack | Holds | When it loads | Maps |
|---|---|---|---|
| `items.<kind>.pck` | every `models/bl_*` folder (the Blender items and fixtures: food, drinks, books, toys, the lions, the stick) | with the wing pack, before the scene loads | all 12 |
| `chars.<kind>.pck` | both character bodies, the player's wardrobe and the clothed defaults, their maps | once the mall is running | all 12 |
| `chars_<map>.<kind>.pck` | only the pieces that map's presets wear on top of `chars` | with `chars` | maps whose presets need any (today `w1`, `w2`) |

- **The list:** `tools/shared_packs.json` (non-character packs, by path glob) and `tools/chars/pack_list.py`
  (the character split, worked out from `data/story/attendants.json`, `scripts/npcs.json` "presets" and
  `data/characters/_wardrobe.json`). `python3 tools/shared_packs.py` prints the packs and their files.
- **Export:** `tools/export_web.sh` exports the wings, then each shared pack through the presets
  "Shared Desktop" / "Shared Mobile" (written by `tools/make_presets.py`; `tools/shared_packs.py --write=<name>`
  points them at one pack at a time and the script restores the file afterwards), and writes their sizes
  into `index.html`'s `SHARED_PACKS` line. `SHARED=0` skips them for a quick wing-only export.
- **Wing presets:** every "Wing …" preset excludes `models/bl_*`, `models/characters/*.glb` and
  `models/characters/*.png` (`make_presets.py` `SHARED_EXCLUDES`; an exclude also drops a scene's own
  dependencies). `models/characters/characters.json` (212 KB) stays in the wing packs.
- **The page** (`web/shell.html`): the "start" packs this map uses are added to the engine's own preload
  (one loading bar, the engine's retries), so they are in the file system when the engine starts; the
  "later" packs are fetched after the loading card lifts, one after another, and copied into the file
  system with `engine.copyToFS()`; then the other-wing prefetch runs. Shared packs go into the same Cache
  Storage as the wing packs (the cache name includes their sizes), so each downloads once for the whole mall.
- **The game:** autoload `SharedPacks` (`scripts/shared_packs.gd`) mounts the "start" packs in its
  `_init()`, before the main scene is loaded; `scripts/chars/char_pack.gd` waits for the character group
  (`window.__mallLater.chars`) and mounts it, then the attendants and the avatar put their preset bodies
  on (`chars_ready()`). Packs are mounted with `replace_files = false`, so the wing pack's copy of a file
  always wins. Off the web (native runs, tests, the editor) nothing is mounted: the files are in `res://`.
- **Hosting:** shared packs are named `<name>.desktop.pck` / `<name>.mobile.pck` like the wing packs, so
  the two-site split needs no change: the desktop site's workflow copies every `*.desktop.pck`, main's
  drops them. `tools/publish_build.sh` copies the shared packs listed in `index.html`, counts them in both
  sites' totals, and now refuses any pack of 100 MiB or more (GitHub's file limit); `export_web.sh` warns
  from 95 MB.
- **The character pack bug** (Nov 2: "doesn't mount", a page error "null function"): `char_pack.gd`
  fetched the pack with `HTTPRequest.download_file` into `user://`. The page now does the fetch (cached)
  and hands the bytes to the engine's file system; `HTTPRequest` is no longer used for packs.

### Measured (Nov 3 2026, this branch, unbaked; Demo 49 lightmaps from `godot-build`)
"Before" is an export of this branch's merge of `main` + `ws/chars-live` without the CHARS changes (the
Demo 49 live build measured w1 98.6, w2 97.0). Desktop and mobile packs are the same size to the byte, as
before; the shared packs are even byte-identical between the two (all their textures are lossless WebP).

| Pack | Before MB | After MB | Change |
|---|---|---|---|
| w1 | 98.91 | **85.21** | −13.70 |
| w2 | 97.35 | **82.91** | −14.44 |
| w3 | 31.98 | 31.98 | 0.00 |
| w4 / w5 / w6 | 36.73 / 38.68 / 21.66 | 36.65 / 38.60 / 21.58 | −0.08 each (the stick) |
| w1y26 | 43.09 | 43.09 | 0.00 |
| w2y26 | 68.10 | 66.39 | −1.71 |
| w3y26 | 14.85 | 17.81 | +2.96: `npc/anims.res`, so the player's preset body animates on the 2026 outside (the only pack that left the animations out) |
| w4y26 / w5y26 / w6y26 | 31.35 / 33.48 / 21.79 | 31.27 / 33.40 / 21.71 | −0.08 each |
| items (new, shared) | – | 22.64 | every Blender item once (was 30.3 MB spread over 9 packs) |
| chars (new, shared) | – | 42.23 | the characters were not on the web before (the bug) |
| chars_w1 / chars_w2 | – | 0.39 / 1.88 | the attendants' own pieces |
| **All packs, one kind** | **538.0** | **577.7** | +39.7: +44.5 characters, +3.0 animations on the 2026 outside, −7.7 items no longer duplicated |

- **Headroom under 100 MiB:** wing 1 has 19.6 MB (was 5.9), wing 2 21.9 MB (was 7.5), before the
  Demo 49b lightmaps. Round 2's items cost the wing packs nothing: they land in `items` (22.6 MB of 104.9).
- **Each site:** 577.7 MB of packs (+ 39.9 MB page and engine on the main site) of the 950 MB the
  publish script allows (`DRY_RUN=1 tools/publish_build.sh`: all checks pass). Both sites carry the same shared packs, so the characters cost each site 44.5 MB once.
- **A visitor's downloads:** the first wing now also downloads `items` (22.6 MB, once for the whole mall),
  so a cold start in wing 1 fetches 107.8 MB at the start (was 98.9) and the characters (42.6 MB) in the
  background; wing 2 afterwards is 82.9 MB (was 97.3). Wings 1 + 2 in 1995: 190.7 MB at start (was 196.3).

### The options compared (why shared packs)
| Option | Fixes the 100 MB file limit | Fixes the 1 GB site limit | Round 2 items | Cost / risk |
|---|---|---|---|---|
| **Shared packs (built)** | yes: items and characters leave the wing packs | helps: each item ships once, not per wing and year | land in `items`, never in a wing pack | an autoload and ~60 lines of page code; `items` itself must stay under 100 MiB (22.6 now): split it into `items2` etc. by glob in `tools/shared_packs.json` when it nears 90 |
| Split packs (one wing pack cut in two files, both mounted, or a byte split joined in the page) | yes | no: same bytes, still duplicated per year | still count against the wing | more files per wing; a byte split needs the whole pack in memory twice while joining (bad on iPhone) |
| Cloudflare R2 (or another bucket) for the packs | yes (objects up to 5 TB) | yes (no site limit; R2 egress is free, 10 GB stored free) | wherever we like | a Cloudflare account and an API token kept out of the repo (in the owner's environment only), CORS rules for `stevenboudreaux.github.io`, a second origin for Cache Storage, a publish step outside GitHub, and the game depends on two providers. Worth it when the two Pages sites together near 2 GB; not needed now. |
| GitHub Releases as the host | yes (2 GB per file) | yes | – | not usable: release downloads don't send CORS headers, so the page can't fetch them |

**Next, not done (proposal):** the Mixamo crowd skins and animations are 16.7–19.2 MB of *every* pack
(~205 MB per site). As a shared "start" pack they would ship once; but `scripts/npcs.gd` picks each map's
crowd by which skins exist in its pack (the room wings and the outside leave three out), so the crowd lists
would first have to move into data (`scripts/npcs.json`). Then wing 1 would be ~66 MB and each site ~370 MB.

## Streaming a neighbour's pack (workstream SEAMLESS, Nov 13 2026)

`design/godot-wings.md` "Seamless streaming": with `?stream=1` (or `data/stream.json` `enabled`) the page fetches the
wing pack on the other side of a border while the game runs (`window.mallStream(w)`: Cache Storage first, then the
network, kept in the cache) and the game mounts it beside the running wing's pack. Nothing about the build folder,
the pack names or the upload changes. Two new files ship in every wing pack (`scripts/wing_stream.gd`,
`data/stream.json`), so the first export after this needs `python3 tools/qa/packcontents.py write <builddir>`.

**What the packs share (measured on the Demo 54 build, R2 `20261113-1915-df378f57`, 1990s, mobile = desktop):**

| | MB |
|---|---|
| w1 + w2 + w4 + w5 + w6 as downloaded | 582.4 |
| the same files counted once | 227.0 |
| identical in all five (the cast's bodies and heads 71.7, shopper skins 3.1, animations 2.9, scripts and data) | 79.7 |
| w2 that w1 does not already have | 64.3 |
| w4 that w1 does not have / w5 that w2 does not have / w6 that w1 does not have | 11.3 / 12.5 / 0.1 |

Only `project.binary` and `.godot/uid_cache.bin` differ in bytes between packs. A streamed neighbour is mounted
whole today, so its duplicates are downloaded and held in the page's memory again (154 MB for wing 2 where 64 would
do). Stage 3 made the first part of that fix: the common pack, below.

## The common pack (workstream SEAMLESS, stage 3, Nov 13 2026)

**Decided (director, Nov 13):** split what every wing pack carries into a shared pack, so a streamed neighbour is
not downloaded and held with the same people again. No picture changes.

**Built:** `tools/shared_packs.json` has a second shared pack, `common`, beside `items`: `cast/*.glb`, `cast/*.png`
(the cast's bodies and their pictures) and `npc/anims.res` (the animation library); 62 files. `at: "start"`: fetched
with the first wing pack and mounted before its scene, because people must be in before the card lifts.
`cast/*.json` stays in the wing packs with the other data. A new cast member under `cast/` lands in `common` with
no change. `tools/make_presets.py` and `tools/shared_packs.py` leave those files out of the wing presets;
`export_presets.cfg` and `tools/qa/pack_manifest/` (`common.txt` is new) were rewritten from an export.

**Pack sizes, MB (desktop = mobile to the byte). Before = the Demo 54 build on R2; after = this branch, same lightmaps:**

| Pack | Before | After |
|---|---|---|
| `w1` / `w2` | 150.6 / 154.2 | 91.0 / 94.7 |
| `w4` / `w5` / `w6` | 98.6 / 99.4 / 80.3 | 39.0 / 39.9 / 20.7 |
| 1990s interior, the five packs | 583.1 | 285.3 |
| `w1y26` / `w2y26` | 107.8 / 138.9 | 48.3 / 79.3 |
| `w4y26` / `w5y26` / `w6y26` | 152.0 / 94.7 / 80.4 | 92.5 / 35.1 / 20.9 |
| 2026 interior, the five packs | 573.8 | 276.1 |
| `w3` / `w3y26` (the outside) | 119.4 / 104.4 | 59.9 / 44.8 |
| `items` (once) | 84.0 | 84.0 |
| `common` (once) | none | 59.6 |
| Everything, one kind of device | 1,464.7 | 809.7 |

So a first visit to wing 1 in the 1990s downloads 91.0 + 84.0 + 59.6 = 234.6 MB, as before (150.6 + 84.0: the same bytes,
in three files); each further wing costs 59.6 MB less than before, in download and in the page's memory.

**Smaller than the estimate.** The findings doc (section f, option 1A) guessed wing packs near 70, 74, 18, 19 and
under 1 MB. That counted every file two or more packs share. What moved is only what is byte-identical in **all**
of them and safe to mount first (the cast and the animations, 57 MB of the 79.7). Still duplicated: shopper skins,
scripts and data in every pack (about 20 MB: wing 6 is 20.7 MB with 0.1 MB of its own), and what wings 1 and 2
share with each other and with their room wings (wing 2 has 64 MB wing 1 lacks, and is a 94.7 MB download).
Moving those is a second pack-boundary change (a "mall" pack for the two mall wings' shared stores' textures, and
scripts and data into `common`); it needs care with `project.binary` and the uid cache, which differ per pack. Not done.

**For the director at export and upload:** nothing new to run. `tools/export_web.sh` writes every shared pack named
in `tools/shared_packs.json`; `tools/publish_build.sh` already checks that every shared pack `index.html` lists is
in the export (`common.desktop.pck`, `common.mobile.pck`), checks pack contents against `tools/qa/pack_manifest/`
(already rewritten for this branch; run `python3 tools/qa/packcontents.py write <builddir>` again only if other
branches in the same integration add files), and uploads `*.pck` to R2. Two more files in the bucket per build.
