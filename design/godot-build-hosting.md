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
