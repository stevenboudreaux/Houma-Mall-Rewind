# Session handoff: MOVE (Nov 3, 2026)

**State: published and working on Steven's iPhone.** The project now lives at
`stevenboudreaux/Houma-Mall-Rewind`; the site is https://stevenboudreaux.github.io/Houma-Mall-Rewind/
and opens the game. `main` = `integration` = `9391fdd` (then this handoff's own commit).

## What was done, in order

1. **Copy.** Full `--mirror` clone of `Southland-Mall-95` (1.7 GB, no LFS), pushed to the new repo
   with the same commit IDs: `main` first in 30-commit steps (so it became the default branch),
   then every other branch oldest first. 57 of 58 branches; `claude/funny-feynman-x6im9s` skipped
   as briefed. No tags in either repo. The old repo was never pushed to (its push URL was disabled
   in the mirror) and it is unchanged: 58 branches, same IDs as before.
2. **Verified before anything else.** `ls-remote` of both repos diffed: the only difference is the
   skipped branch. Against the new repo, `git fetch origin e2d8e4a5…` and `git fetch origin 8aa8f788…`
   both fail (`upload-pack: not our ref`, exit 128). Neither of those, nor `325ba66` or `0b8fdaf`, is
   among the 370 commits reachable from the 57 branches; none was in the mirror clone at all.
3. **Rename** (`d02ab9c`): only references to the repo, in 19 files: `guessRepo` in `index.html`,
   `web/shell.html`, `play/emu.html`, `apps-script/Code.gs` (`REPO`, `SITE`), `CLAUDE.md`,
   `CLAUDE-CLOUD.md`, `design/godot-build-hosting.md`, `tools/qa/bakecheck.sh`, `tools/convert_map.py`,
   `tools/extract_facades.py`, the `tools/stores/pocket_change/*` comments. "Southland Mall" as the
   mall's name and the past handoffs are untouched. `Code.gs` in the repo holds only placeholders
   (no token, no passphrase).
4. **The game is the front page** (`e57cb0b`): at deploy time the build's `play/` files go to the site
   root; the original game is served as `classic.html`; old `prototypes/godot-mall/play/*.html`
   addresses forward; `review.html`'s boards link points at `classic.html`. `project.godot`'s name
   is "Houma Mall Rewind" (saves are in `localStorage`, nothing lost); until the next export the
   deploy strips " - Godot Mall" from the tab title.
5. **Two sites** (`9391fdd`): the game would not load on the iPhone ("Could not start: Load failed")
   because every deploy since Demo 49 was 1.17 GB, over GitHub Pages' 1 GB (24 packs = 1.08 GB,
   plus all of `main`). Now the main site deploys only what it serves, without the computer packs
   (352 MB compressed), and `stevenboudreaux/Houma-Mall-Rewind-desktop` serves the computer packs
   (344 MB). `web/shell.html` asks for them there on github.io (`MALL_DESKTOP_SITE`); older exports
   get the same lines at deploy time (`tools/desktop_site/patch_index.py`). `publish_build.sh`
   refuses when either set reaches 0.95 GB and refreshes the desktop repo after `godot-build`.
   Details: `design/godot-build-hosting.md` "Two sites".

## Verified
- Pages runs: main #9 success, no size warning; desktop #1 success. Earlier runs #1-6 on the new
  repo failed only because Pages was not on yet during the copy.
- Local copy of both sites under a github.io hostname (HTTPS): computer run fetched its 4 packs
  from the desktop site, phone run from the main site, 0 errors, both reach the opening screen.
  Evidence: `production/qa/evidence/move-two-sites-{desktop,phone}.jpg`,
  `move-front-page-{desktop,phone}.jpg`, `move-classic-html-{desktop,phone}.jpg` (all unbaked).
- `DRY_RUN=1 tools/publish_build.sh` on the Demo 49 export: all checks passed (main 574 MB,
  desktop 534 MB; the known unbaked wing 4/5 warnings only).
- Steven: the game loads on the iPhone.

## Steven's list
1. **Apps Script needs redeploying.** New GitHub token (Contents: read and write on
   `Houma-Mall-Rewind`), `REPO:"stevenboudreaux/Houma-Mall-Rewind"`,
   `SITE:"https://stevenboudreaux.github.io/Houma-Mall-Rewind/"`, keep `ADMIN_KEY`. Deploy >
   Manage deployments > edit > Version: New > Deploy (same `/exec` URL, so `index.html` and
   `review.html` need no change).
2. **The editor's Publish token** saved in the browser must cover the new repo.
3. **Repoint the Mac's clone**, inside its folder:
   `git remote set-url origin https://github.com/stevenboudreaux/Houma-Mall-Rewind.git && git fetch --prune origin && git branch -u origin/main main`
   (renaming the folder to `Houma-Mall-Rewind` is optional; `convert_map.py` / `extract_facades.py`
   default to that name).
4. **Delete the old repo** when ready: every check passed.
5. **Next Mac publish** also pushes to `Houma-Mall-Rewind-desktop` (same login, nothing to set up).
   A cloud session that publishes needs that repo attached with push access.

## Open items carried over (unchanged)
- Mac bake list and stand-in recaptures from the Demo 49 handoff; wings 4 and 5 ship unlit.
- `tools/qa/dialogue_shots.gd` still has Q's Dillard's-locked step: not a one-liner (a 29-line
  block in `_plan_w2`, lines 157-185, plus the header comment), so left as is.
- Story text and decisions Steven owes, ws/chars-live: as in the Demo 49 handoff. ws/chars-live
  not touched.
- Steven asked to remove the old game(s) from the repo, then paused it (not what used the space).
  Nothing deleted. If it goes ahead: `make_exterior.py`, `make_layout_2026.py`, `convert_map.py` and
  `extract_facades.py` read `mall-data` from the old `index.html`, so that data moves into the
  project first; the photo boards and Apps Script go with the old game.
- "Godot" wording: player-facing only was removed (tab title, address). Internal docs, comments,
  `prototypes/godot-mall/`, `godot-build` and the sign-publish commit message still say it.
- Wing 1 is at 98.61 MB, the next ceiling; the Pages ceiling is now per site (0.95 GB each).
