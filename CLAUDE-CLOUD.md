# Cloud sessions (claude.ai/code, Cloud): how to work on the Godot mall

For parallel cloud sessions started from a workstream brief. Read this, then `CLAUDE.md`, then your brief.
All Godot work is under `prototypes/godot-mall/project` ("the project" below).

## Rules

- **Steven writes the story; Claude builds the machinery.** No session invents a character, name, dialogue,
  quest, item or fixture unless asked for that specific thing. Inferences from references are questions in the
  report, not builds. Test content is marked PLACEHOLDER.
- **Your own branch, code only.** Work on the branch your brief names (`ws/<letter>-<slug>`), push it, and stop.
  **Never push to `main` or `godot-build`, never run `tools/publish_build.sh`, never publish.** Pushing to main
  makes the site live. Merging, the Ultra rebake on Steven's Mac and the publish happen in one integration session.
- **Commits:** as Steven, with the trailers from your session's system reminder:
  `git -c user.name="Steven Boudreaux" -c user.email="steven_boudreaux@outlook.com" commit`, message in
  Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:` …), naming the design note it follows
  (`design/storefronts/<store>.md`, `design/godot-*.md`). Never commit `__pycache__`, `.scratch/`, `refs/`,
  builds or lightmaps (`*.exr`, `*.lmbake`, `play/index.*`).
- **The CLAUDE.md "ask before every write" protocol is relaxed for these sessions:** your brief is the approval.
  Do the work, then report. Ask Steven only for a decision the brief and the design notes cannot settle; when he
  is not answering, take the most reasonable reading, write it down as a guess in the design note, and carry on.
- **No anachronisms.** The 1995 map shows only what existed in 1995; the 2026 map only what is there now. Unknowns
  are written as guesses in the store's design note.
- **IP:** no real product titles, cover art, characters or third-party logos inside stores. Store signs and
  mall-tenant wordmarks are fine (Steven: Chick-fil-A "as close as possible, with discretion"). Packaged goods are
  painted as invented generic shapes (see `tools/stores/small/paint_rs.py`).
- **Don't lower picture quality** (texture size, bake quality) without before/after screenshots and Steven's yes.
- **Verify by looking.** Every visible change gets an unbaked screenshot kept in `production/qa/evidence/`
  (`<ws>-<what>.jpg`, JPEG ≤ 1600 px).
- **Both wings, both years.** The mall ships as wings (`design/godot-wings.md`); 1995 and 2026 are separate scenes
  (`wing*_2026.tscn`, `layout_2026.json`, `design/godot-2026-year.md`). Say in your report which wings need a rebake.
- **Keep files apart from other sessions.** A new store or system goes in its own folder/script
  (`tools/stores/<name>/`, `scripts/<system>.gd`). Touch shared files (`tools/build_mall.gd`, `scripts/player.gd`,
  `scripts/mall_runtime.gd`, `web/shell.html`, `layout_*.json`) with small, clearly separated hunks so merges stay
  easy.

## Fresh workspace setup (~15–25 min, mostly the import)

```bash
cd /home/claude/houma-mall-rewind            # the clone; if missing: git clone https://github.com/stevenboudreaux/houma-mall-rewind
# 1. Godot 4.7.2 and the web export templates
cd /home/claude
curl -sSLO https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
unzip -q Godot_v4.7.2-stable_linux.x86_64.zip && mv Godot_v4.7.2-stable_linux.x86_64 godot && chmod +x godot
curl -sSLO https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz
T=~/.local/share/godot/export_templates/4.7.2.stable; mkdir -p $T
unzip -q -j Godot_v4.7.2-stable_export_templates.tpz 'templates/web_*' 'templates/version.txt' -d $T
export PATH=/home/claude:$PATH
# 2. Packages
pip install --break-system-packages mapbox_earcut fonttools
which xvfb-run || (apt-get update -qq && apt-get install -y -qq xvfb)   # preview.sh needs it
# 3. Lightmaps and stand-in pictures from the build branch
cd /home/claude/houma-mall-rewind/prototypes/godot-mall/project
git fetch -q --depth=1 origin +refs/heads/godot-build:refs/remotes/origin/godot-build
git archive origin/godot-build lightmaps standin | tar -x
mv lightmaps/* . && rmdir lightmaps && mkdir -p tex/standin && mv standin/* tex/standin/ && rmdir standin
# 4. Import (long; run in the background with nohup and poll)
nohup godot --headless --path . --import > /tmp/import.log 2>&1 &
```

Playwright and Chromium are already installed (`require('playwright')`, `chromium.launch()`; don't reinstall).
GitHub release downloads work; YouTube and most other sites are blocked from the cloud.

## Build and test

- **Build a wing:** `godot --headless --path . --script res://tools/build_mall.gd -- --wing=1` (2, 3 = outside,
  4 = Sears / Lynn's, 5 = Dillard's level 1, 6 = the cinema lobby;
  add `--year=2026` for the 2026 scenes; `design/godot-2026-year.md`), then look for `BUILD OK`.
- **Other QA tools:** `tools/qa/README.md` (unbaked_shots.gd, doortest.py, signstest.py, packtest.py …).
- **Fast look, no bake:** `tools/qa/preview.sh <module|store:NAME> <out-prefix> "x,y,z,yaw,pitch;..." '{}' lit|dark`
  renders a store or prop module with the probe-lit preview scene (~10–60 s).
- **Unbaked in-game shots:** export with `tools/export_web.sh .scratch/builds/<name>` (two packs: desktop + mobile),
  serve the repo root with `python3 -m http.server 8765`, then
  `python3 tools/qa/movetest.py <url-path> <out-prefix>` with
  `CAMS='{"name":"x,z,yaw,pitch&time=night",...}'` (load + screenshots + a touch-drag walk; expect 0 errors).
  Serve builds from `.scratch/builds/`, never `prototypes/godot-mall/play/` (it is tracked).
  Playwright on swiftshader needs long timeouts (`timeout=180000`).
- **Cameras:** `?cam=x,z,yaw,pitch` in the game URL places the player.
- **Baking:** don't. Cloud bakes need a 12 GB swap file and ~10 min per wing; the integration session does one bake
  per wing on Steven's Mac (Ultra). Your shots are unbaked; say so in the evidence file names.
- **The Mac's `.autobake` list** (one line of `<scene>:<mode>` jobs, `addons/autobake`): since workstream S
  (Nov 2 2026) it also takes the room wings, **`wing4:day wing5:day wing4_2026:day wing5_2026:day`** (Sears / Lynn's, Dillard's level 1; `design/godot-wings.md` "Wings 4-6").
  Wing 6 (the cinema lobby placeholder) is never baked. After baking 4 / 5: `tools/capture_standin.sh 4` / `5`
  (and `... 2026`), then recapture 1 / 2, export, publish. Until their first bake, wings 4 and 5 ship unlit
  (`publish_build.sh` warns, does not refuse).

## Reference pictures: the `refs` branch

Footage and photos from Steven's Mac (the Oct 23, 2026 site visit, new cuts for these workstreams, 1995-era
pictures, analysis notes) live on the orphan branch `refs`, kept off `main` so main stays small (~440 MB):

```bash
cd /home/claude/houma-mall-rewind
git fetch --depth=1 origin refs && git archive FETCH_HEAD refs | tar -x     # → ./refs/ (git-ignored)
# or one folder: git archive FETCH_HEAD refs/new/sears | tar -x
```

Start with `refs/INDEX.md`: per video, where it was shot and what it shows; per workstream, which folders to read;
and the gaps (things not in the pack). Older references are in the repo: `design/storefronts/refs/`,
`design/storefronts/photos/`, and each store's `design/storefronts/<store>.md`.

## Finishing

1. Push your branch (pushes through the proxy sometimes fail with 504 / Internal Server Error: wait 20 s, retry once).
2. Update or add the design note(s) your work follows, with sources and what is guessed.
3. End with a short report: what changed (files), evidence shots, which wings/years need a rebake, open questions
   for Steven, anything another workstream must know before merging (shared files you touched).
