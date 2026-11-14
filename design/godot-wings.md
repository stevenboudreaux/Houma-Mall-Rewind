# Godot mall: two wings (since Demo 16, Oct 7, 2026)

**Asked for (Steven, Oct 7):** split the game file by wing instead of by storefront, so it stays
under GitHub's 100 MB file limit as stores are added. The seam is the floor change where the east
hall meets the Dillard's court. Walk up to it and a Fallout-style prompt offers the other wing
(a key, the controller's button, a click or a tap). Gumballs belongs to Wing 1 and its court
door is a crossing too. Looking across the seam must show the other wing exactly as it is now,
and must stay current as facades change.

## The wings
- **Wing 1** (`wing1.tscn`): Sears, the Sears halls, the east hall, the Shoe Dept. court, the main
  entrance hall, and the east hall south to the seam, with Gumballs.
- **Wing 2** (`wing2.tscn`): the Dillard's court, the Dillard's entry, the Concourse, the JCPenney
  court, the south exit hall and the restroom hall.
- **Where it's set:** `tools/build_mall.gd`.
  - `WING2_ZONES` lists the zones; every other zone is Wing 1.
  - `STORE_WING` lists stores whose wing is not the zone their front faces (Gumballs).
  - `SEAM` is the line on the floor: z = 48, from x = -20 (Gumballs' court door) to x = 2.
  - A frontage belongs to the zone it faces. A walkable tile belongs to its zone, else to the
    store built over it (`BUILT_RECTS`), else to its side of the seam.
- **Building:** `godot --headless --path . --script res://tools/build_mall.gd -- --wing=1`, then
  `--wing=2`. Each writes its scene plus `gen/w<n>/`: meshes, `signs.json`, `collide.json`,
  `wing.json` (this wing's walk grid, the seam, the default spawn) and `standin.json`.
  `--wing=0` still builds the whole mall into `main.tscn`, for checks only.

## The stand-in: the other wing, seen across the seam
- **What it is:** each wing also builds the other wing's halls and courts as usual (floors, vaults,
  ribs, ceiling lights, walls, exits), with a coarser lightmap. Every one of the other wing's
  storefronts is a picture on its frontage plane.
- **Where the pictures come from:** the other wing's own baked build.
  - `tools/capture_standin.sh <n>` runs `tools/capture_standin.gd` for night and day.
  - The capture stands an orthographic camera 1.25 m out in the hall facing each front, framing
    floor to lane ceiling. The pictures fill fixed slots of a 4096 x 2048 atlas:
    `tex/standin/from_w<n>_{night,day}.png`.
  - The slots come from the layout alone (`standin.json`), so a new capture never needs a rebuild
    or a rebake of the wing showing it. Only the atlas image changes.
- **How they're shown:**
  - Captured with a linear tone curve at half exposure, with no glow or colour grading.
  - Drawn unshaded at twice the brightness (`standin_mat`), so the game's own tone mapping and
    glow apply once, as they do to the real shops.
  - The day pictures swap in with the day lighting (`scripts/time_of_day.gd`, `tex_day`/`tex_night`).
  - The stand-in's lit shops also throw their light into the hall for that wing's bake.
- **Keeping it current: the rule.** Whenever a wing changes (a facade, a sign, a texture, a
  rebake), recapture that wing before publishing.
  - `tools/capture_standin.sh <n>` stamps the pictures with `tools/wing_hash.sh <n>`: a fingerprint
    of `gen/w<n>/`, the wing's lightmaps and every texture.
  - `tools/publish_build.sh` refuses to publish if either wing's fingerprint no longer matches its
    stamp, or if the export is older than the pictures.
  - So when, say, Payless's interior changes, Wing 2's view of it updates with the next publish.

## Crossing
- **Walls:** each wing's walk grid closes the other wing's tiles, so the seam is a wall
  (`scripts/player.gd`).
- **The prompt:** within 2.6 m of the seam on this wing's side, a prompt appears at the bottom
  middle: "Enter Wing 2 · Dillard's & JCPenney" with a key cap.
  - The key cap shows **E** (keyboard), **A** (controller) or **Tap** (touch).
  - E, Enter, the controller's A, a click or a tap on the prompt crosses.
- **The crossing:** a 0.35 s fade to black, then the page reloads into the other wing's file with
  `?wing=`, `cam=` (the same x, 1.3 m past the seam, the same facing), the lighting and the
  toggles.
  - The shell shows a dark "Wing 2" loading card instead of the cream one.
  - The game fades in from black.
- **Speed:** six seconds after a wing starts, `web/shell.html` fetches the files you are likely to
  need next into Cache Storage, one after another: the other wing, then this wing in the other
  year, then the other wing in the other year (`mallPrefetchOther`). The crossing, and the Y key's
  year switch, then load from there instead of the network. One cache per build for both years
  (`mall-wings-<the five pack sizes>`; older caches are deleted). Until Oct 28 the cache was per
  year and switching years emptied it, so every 1995 ↔ 2026 switch downloaded its wing again. A
  line the browser marks "save data" only gets the other wing.
- **Memory:** only one wing is ever in memory, which matters on the iPhone.
- **Test:** `tools/qa/seamtest.py <build>/index.html <out>` crosses 1 → 2 by key and 2 → 1 by
  clicking the prompt.

## Files and publishing
- **The export:** `tools/export_web.sh <out>` writes `w1.desktop.pck`, `w1.mobile.pck`,
  `w2.desktop.pck`, `w2.mobile.pck` and the shared `index.*`.
  - Presets: "Wing 1 Desktop", "Wing 1 Mobile", "Wing 2 Desktop", "Wing 2 Mobile".
  - Each preset exports its scene and the files it depends on, plus include filters for what the
    scripts load by path.
  - The `wing2` custom feature selects `run/main_scene.wing2`.
  - **Since CHARS (Nov 3 2026) no wing pack carries the Blender items (`models/bl_*`) or the character
    models:** they ship once in the shared packs `items.*.pck` and `chars*.pck`, mounted at runtime
    (`design/godot-build-hosting.md` "Shared packs"). A new item under `models/bl_<store>_<item>/` costs
    the wing packs nothing; a wing scene may still place it (the items pack is mounted before the scene loads).
- **Baking:** the Mac bake plugin (`addons/autobake`) takes several jobs in one launch:
  `echo "wing1:night wing1:day wing2:night wing2:day" > .autobake`. It writes `.autobake_done`.
  About 7 minutes per bake on the MacBook Air.
- **What lives on `godot-build`:** `play/` (the four packs), `lightmaps/` (`wing<n>_{night,day}.*`)
  and `standin/` (the atlases and stamps). None of these are on `main` (`.gitignore`).
- **Bring back only the lightmaps** from the Mac: `wing<n>_{night,day}.{exr,exr.import,lmbake}`.
  - Keep the cloud-built `wing<n>.tscn` and `gen/`.
  - The Mac editor re-saves the generated meshes with its own resource IDs. A scene saved there
    points at IDs the cloud files don't have, and the web export then silently leaves out more
    than 100 meshes. That happened in Demo 16's first export: half the mall was invisible.
  - The lightmaps match either way: same meshes, same UV2.
- **Order for a demo:**
  1. Build both wings.
  2. Bake on the Mac.
  3. Bring the lightmaps back (not the scenes), and import.
  4. Capture both wings' stand-ins.
  5. Export.
  6. Run `seamtest.py` and the bake check shots.
  7. Commit to main.
  8. Run `publish_build.sh`.

## Wings 4-6: rooms that are wings of their own (workstream S, Nov 2 2026)
**Asked for (Steven, Nov 2):** Sears (Lynn's in 2026) and Dillard's level 1 as their own wings, with
their own packs and load screens, for headroom under GitHub's 100 MB file limit (wing 2 was at
94.8 MB and wing 1 at 91.5, and both anchors will only grow); plus a placeholder Southland Cinema
wing ("just make it a very small room; I want to see if the logic works", 12:38).

| Wing | What | Scenes | Packs | Lightmap slots | Mall wing |
|---|---|---|---|---|---|
| 4 | the Sears box (1995), Lynn's Interiors (2026): workstream E's build, `tools/stores/sears/` | `wing4.tscn`, `wing4_2026.tscn` | `w4`, `w4y26` | `wing4_day`, `wing4_2026_day` | 1 |
| 5 | Dillard's level 1, both years: `tools/stores/dillards/` | `wing5.tscn`, `wing5_2026.tscn` | `w5`, `w5y26` | `wing5_day`, `wing5_2026_day` | 2 |
| 6 | the Southland Cinema lobby: a 12 x 8 m dark box, three lights (`tools/stores/cinema/lobby.gd`) | `wing6.tscn`, `wing6_2026.tscn` | `w6`, `w6y26` | none (never baked) | 1 |

- **Where it's set:** `tools/build_mall.gd` `ROOM_WINGS`: per wing the layout store, the box it owns
  (`tile_wing()` gives its tiles to the room wing, so the mall wing's walk grid is closed there), the
  threshold line and the mall wing. Build: `--wing=4|5|6` (and `--year=2026`), like the others.
- **What a room wing contains:** the anchor's own frontage built for real (fascia, sign, E's whole
  box) and, like any wing, every hall and court of the mall at the coarse stand-in texel, with every
  other storefront as a picture. Those pictures are the mall wings' own atlases (`from_w1_*` for
  wing 1's fronts, `from_w2_*` for wing 2's): `room_standin()` packs the slots exactly as wing 2 and
  wing 1 pack them, so they need no capture of their own. Wing 6 holds only its room.
- **What the mall wing shows of it:** the anchor's front (fascia, sign, piers, soffit) stays in
  wing 1 / 2; the opening is filled by one picture of the inside (`anchor_standin()`,
  `tex/standin/[y26_]from_w<4|5>_{day,night}.png`), taken by `tools/capture_anchor.gd` from a camera
  8 m out in the mall at eye height, its frustum framed exactly on the opening, its near plane on it
  (so the mall-side copy in the room wing is clipped). It lines up from there and reads right from
  the court. `tools/capture_standin.sh 4` / `5` (and `... 2026`) takes it and stamps it with
  `tools/wing_hash.sh 4` / `5`. Wing 1's fingerprint counts the Sears picture and wing 2's the
  Dillard's one (the other mall wing's stand-in shows them through the opening), so after a new
  anchor picture recapture 1 / 2 as well; `publish_build.sh` says so.
- **The cinema in wing 1** keeps its front (`tools/stores/cinema/front.gd`) and its dim lobby behind
  the glass; a closed roll gate now stands behind the two door arches (1995; dynamic mesh
  `dyn_cin_gate`). In 2026 the unit is vacant in `layout_2026.json` and its existing full-width
  grille is that gate: moved out of the H1a hall mesh into a static mesh of its own (`cin_gate`, still
  lightmapped), with a plain dark 3 m recess behind it (`cin_back26`, hidden while the gate is down),
  so an open gate shows a dark space instead of the lot. **Visible until wing 1 (2026) is rebaked:**
  the unbaked grille reads lighter and H1a's old lightmap is misaligned on the bulkhead above it
  (H1a's mesh changed); before/after `production/qa/evidence/wsS-cinema-2026-grille-before-after.jpg`.
- **No shoppers in wing 6** (the lobby is one empty room). Wings 4 and 5 keep the shoppers that walked
  Sears and Dillard's inside wings 1 and 2 (the crowd spawns round the player, so it is the same as
  before); the Runner stays in wing 2 only.

### Thresholds (crossed like the seam)
Each mall wing's `wing.json` gains `thresholds` ({to, line [x0, z, x1], side}); a room wing's has
one, back to its mall wing. Within 2.6 m of the line on this side, the prompt reads "Enter Sears"
("Enter Lynn's" in 2026), "Enter Dillard's", "Enter Southland Cinema", and back "Enter Wing 1 ·
Sears & the main entrance" / "Enter Wing 2 · Dillard's & JCPenney"; E / A / a tap fades out and loads
the other wing 1.3 m past the line at the same x (clamped 0.5 m inside the opening), facing the same
way (`scripts/player.gd` `_thr_here`, `_cross`). The web shell shows the dark crossing card titled
"Sears" / "Lynn's" / "Dillard's" / "Southland Cinema" (2026 adds " · 2026"), no sub-line.

Map tiles are `tx = x / 2 + 148`, `ty = z / 2 + 100` (2 m tiles; layout origin 148, 100):

| Threshold | Line | Mall side (tiles) | Room side (tiles) |
|---|---|---|---|
| Sears / Lynn's (1 ↔ 4) | z = −96, x −16..8 | row 52, tx 140–151 (C1) | row 51, tx 140–151 |
| Dillard's (2 ↔ 5) | z = 80, x −10..2 | row 139, tx 143–148 (H8) | row 140, tx 143–148 |
| Southland Cinema (1 ↔ 6) | z = −86, x −66..−54 | row 56, tx 115–120 (H1a) | row 57, tx 115–120 |

**For workstream Q:** the Dillard's opening stays one walkable threshold: in wing 2 the tiles up to
row 139 are open and row 140 is wing 5's; in wing 5 row 140 is open and row 139 is wing 2's. A gate
node there sits on the line z = 80, x −10..2 (cells above). Q's `dillards_unlocked` gate is not kept
(Steven, Nov 2: Dillard's stays open): `data/story/gates.json` on this branch has only the cinema.

### The cinema gate (`scripts/cinema_gate.gd`, `data/story/gates.json`)
Built against Q's documented contract (`design/godot-quests.md` on `origin/ws/q-dialogue`, read, not
merged): a node in group `"gate"` with `flag` = `cinema_unlocked`, made in wing 1 (both years) from
the gates file's entry with `"threshold": 6`. While the flag is false the cinema threshold's prompt
still shows, but the press runs `try_open()`: holding `folse_stick` (M's
`mall.inventory.held_id()`, until M lands B+C's `mall.hand`, the same fallback Q uses) sets the flag
and rolls the gate up (1.1 s, then hidden); otherwise the PLACEHOLDER message from the gates file
(Q's `Story.say` once Q lands; until then the gate's own notice just above the prompt, where
`player._say` would be hidden under it).
The next press goes in. The flag is kept in Q's store (`mall.flags`; until Q lands, the same
localStorage key `mall-flags-1` / Engine meta `mall_flags`, `{"v": 1, "flags": {...}}`), so it
survives wing loads and reloads, one store for both years. Martin Folse's stick is a 1995 item, so
in 2026 the gate opens only once it was opened in 1995.

### Exterior doors and jumps
- `exterior.json` (`tools/make_exterior.py`): the anchors' own doors now belong to their wings
  (`s1x`, `s1e` → 4; `s2e`, `s2s` → 5), so "Go outside" from inside Sears / Dillard's goes to wing 3
  and "Enter the mall" there comes back into wing 4 / 5. Their rows in the door-picture atlases stay
  in wing 1's / 2's (`door_view.gd ROW_WING`), so the captured atlases are unchanged.
- The mall directory's "Jump to this store?" for Sears / Lynn's and Dillard's lands in wings 4 / 5,
  2.2 m inside the opening, facing in (`tools/stores/directory/map_data.gd ROOM_JUMPS`). The J menu's
  "Sears" and "Dillard's" keep Steven's spots in the mall (Oct 9: back to the entrance, looking out).

## Seamless streaming (workstream SEAMLESS, Nov 13 2026; stages 1 to 3)
**Asked for (Steven, Nov 13):** "walk from the inside of Dillard's to the inside of Sears, and then all the way to
Corn Dog 7, all without a load screen." No load screens between wings or at the department stores; the facades at the
wing borders "kill the exploratory experience". The wings were split for GitHub's 100 MB file limit; the packs have
been on R2 since Demo 51, where that limit does not exist.

**Decided (director, Nov 13):** no merged interior pack or scene: packs stay one per wing, year and device format,
wings stay separate scenes and bake separately. Every device streams; the only difference is how far ahead
(desktop: the whole interior after the first load screen; phones and tablets: the wing you are in plus its
neighbours, far ones unloaded). Inside ↔ outside, the year switch, the mini-games, conversations and the menu keep
their own transitions. The Stockrooms may keep a load (they are a level inside wing 1 today and are unchanged).

**State (stage 3, Nov 13):** built for **every interior border in both years** and **on by default** for desktop
and mobile (`data/stream.json` `"enabled": true`; `?stream=0` turns it off for a session, `?stream=1` on).

| Border | Kind | Years | Notes |
|---|---|---|---|
| wing 1 ↔ wing 2 | the seam | 1990s, 2026 | plain floor while both are in |
| wing 1 ↔ wing 4 (Sears / Lynn's) | threshold | 1990s, 2026 | room wing: waits for its probes (below) |
| wing 2 ↔ wing 5 (Dillard's) | threshold | 1990s, 2026 | room wing: waits for its probes |
| wing 1 ↔ wing 6 (cinema lobby) | threshold, gated | 1990s, 2026 | brought in only once the cinema's gate is open (`scripts/cinema_gate.gd`) |

Still a load, on purpose: inside ↔ outside (wing 3), the year switch, the mini-games, conversations, the menu, and
the **Stockrooms** (a level inside wing 1, unchanged; the walk grid of the wings that are in is put back on return).
Director's calls (Nov 13): the common pack (`design/godot-build-hosting.md` "The common pack"); a wordless cue and no
prompt on a slow line; on by default once every border streams; the stand-in stays as the fallback and as the
bake's lit context. Findings, numbers and evidence: `production/qa/evidence/wsSEAMLESS-findings.md`.

### How it works (`scripts/wing_stream.gd`, one node under `/root` for the whole run)
1. **Fetch.** The game asks the page for the neighbour's pack (`web/shell.html` `window.mallStream(w)`): from the
   Cache Storage the prefetch already fills, else the network (and kept), then copied into the engine's file
   system (`/mall/w<n>[y26].pck`). Off the web the files are in `res://` already.
2. **Mount.** `SharedPacks.mount()` with `replace_files = false`: the running wing's copies win. The two packs'
   shared files are byte-identical (measured; only `project.binary` and `.godot/uid_cache.bin` differ, and the
   running wing's are the ones in force; a wing scene names its meshes by path).
3. **Load.** Every resource the neighbour's scene names is loaded `load_budget_ms` per frame (more on a slow
   frame), then the scene is instanced **without** its `Player`, `Runtime`, `Signs`, `Env` and `Sun`, and its
   `Static` / `Dynamic` meshes enter the tree `nodes_per_frame` at a time; its lightmap is set last, then
   `Runtime.adopt()` gives its floors the floor shader. The neighbour is a sibling of the scene under `/root`
   (`Wing<n>`), in the same world coordinates.
4. **Swap.** Each wing's build carries the other wing as a stand-in: its halls and courts (meshes named by zone,
   `H5`, `C3`, `C3_fl` …) and pictures of its storefronts (`Dynamic/dyn_standin`, material `standin_w<n>`). With
   the real wing in, both wings hide their copy of the other's zones and those picture surfaces. The parts of the
   whole mall that are not in a zone mesh are in both scenes too (`outside`, `dyn_glass_frames`, `lanterns`,
   `dyn_info`, most of `misc`; labels and reflection probes): same name, same box and the same vertex count per
   material = the same geometry, so one copy is hidden (`_dedupe`). `dyn_glass` differs (each wing adds its own
   shop glass) and is left in both: the shared skylight panes are drawn twice until the builder stops duplicating
   them (stage 2; since stage 3 the later copy is trimmed and they are drawn once). The player's walk grid and obstacles become the two wings' union and the seam prompt
   goes. "Benches & plants" shows or hides every wing's fixtures.
5. **Handoff.** Shops, attendants, items, shoppers, signs, the prize counter, the Stockrooms … are made per wing at
   start (`player.wing`). When the player stands on the neighbour's own floor, `handoff_past_m` past the border,
   those systems are remade for that wing in one frame, exactly as a page load into it would make them: the old
   wing's runtime nodes (everything not in its scene file) and its Player / Runtime / Signs are freed, the sky and
   sun move over, the neighbour becomes `current_scene` and gets a new Player (same spot, view, HUD toggles and
   walking finger), Runtime and Signs. Both wings' geometry stays as it is. State already lives outside the scene
   (the old crossing reloaded the page). The address bar's `?wing=` follows (`window.mallStreamHome`), so a reload,
   the year switch and the old prefetch start from the right wing. `player._go_to_wing()` (the J menu, a directory
   jump) into a wing that is in is the same handoff, with no fade or load.
6. **Not in yet, or failed:** the stand-in pictures and the seam's wall stay. (Stage 2 kept the old prompt; since
   stage 3 there is no prompt: a wordless cue, and the old load only by itself after a failed fetch. See below.)
7. **Unload** (phones and tablets, `far_m`): the neighbour's scene and held resources are freed and the home
   wing's stand-in, seam and walk grid come back. The pack stays mounted (its bytes stay in the page's memory).

### Stage 3: what was added to the above
- **Borders are a list** (`data/stream.json` `borders`): wings chain, one at a time, nearest border first.
  **Desktop** (`near_m` / `far_m` 100000) brings in the whole interior of the year after the first load screen.
  **Phones and tablets** bring in a wing when the player is within `near_m` (60 m) of its border and unload one
  whose every border is further than `far_m` (110 m).
- **Who draws what** is worked out afresh for the set of wings that are in (`_resync`): zones, storefront pictures,
  the shared parts once. The skylight glass both mall wings carried is drawn once (`trim`: the later copy loses the
  triangles an earlier one draws). Wing 1's dim copy of the cinema lobby is hidden while the real lobby is in (`hide`).
- **People and things before the border.** Attendants, pick-up items and shop stock are made for every wing that is
  in (`player.has_wing`), within `people_m` of its border or once nothing else is loading; the player's systems are
  remade when the set of wings changes and the player is not in a screen. The crowd (`scripts/npcs.gd` rebind) is
  one node that outlives every remake, so it does not respawn at a crossing. `no_crowd`: wings the crowd skips.
- **A room wing waits for its reflection probes** (`settle_frames` 480). Its probes are UPDATE_ONCE and enter the
  tree after its meshes; they finish their pictures 360 to 400 frames later (about 7 s at 60 frames a second, 13 s
  at 30). Until then a polished floor would mirror the sky (a cool, bluish cast), so the wing stays "coming": the
  border holds and the storefront picture covers the opening. **The player sees the store appear a few seconds
  late, never tinted.** On desktop this happens during the background load after the first card. Mall wings do not
  wait (their hall floors take no probe reflection since FLOOR-FIX).
- **Slow line** (the wing is not ready at the border): the border holds (its floor is not walkable), the stand-in
  picture stays, and a wordless cue shows within `cue_m`: a soft pulse along the floor line. No prompt, no words.
- **Failed fetch** (the pack could not be had): the old crossing starts by itself when the player is within
  `fallback_m` of the line (the old load screen, a page load into that wing). `?stream=0` is the old game throughout.

### Settings (`data/stream.json`)
`enabled` (true / false, or one per kind `{"desktop": …, "mobile": …}`), `borders` (a, b, kind, years, gate),
`wing2_zones` (must equal `tools/build_mall.gd` `WING2_ZONES`), `near_m` / `far_m` / `start_delay_s` per kind,
`load_budget_ms`, `nodes_per_frame`, `handoff_past_m`, `settle_frames`, `people_m`, `cue_m`, `fallback_m`,
`no_crowd`, `trim`, `hide`. URL: `?stream=1|0`; `?qa=1` lets a web test place the player
(`window.__mallTeleport`). Tests: Engine meta `mall_stream`, `mall_stream_kind`.

### Not done, and guesses
- Nothing has run on a real phone or GPU. `near_m` 60 m and `far_m` 110 m for phones, `handoff_past_m` 1 m,
  `people_m` 45 m and `cue_m` 14 m are guesses.
- The stand-in pictures and `tools/capture_standin.sh` are still needed and still stamped: they are the fallback
  (slow line, failed fetch, `?stream=0`) and the bake uses the lit stand-in shops. **Nothing in the bake or publish
  steps changes.**
- The packs still overlap pairwise (`design/godot-build-hosting.md` "The common pack": what was and was not moved).

### Tests
- `tools/qa/stream_test.gd [-- --kind=mobile] [-- --fail]` (headless): the neighbour comes in, the stand-ins are
  hidden, both handoffs, the phone unload; `--fail`: a pack that cannot be fetched (no prompt, the old crossing
  starts by itself at the line). `STREAM TEST OK`.
- `tools/qa/stream_walk_test.gd [-- --year=2026] [-- --kind=mobile]` (headless): every border, both directions,
  the cue, and that the floor past a held border is not walkable. `STREAM WALK OK`.
- `tools/qa/stream_walk_webtest.py <url> <out> [pack] [year]` (web): Dillard's → the court → wing 1 → Sears →
  back → wing 2 → Corn Dog 7 in one page: no load screen, no page load, no prompt, 0 page errors, memory.
  `STREAM WALK WEB OK`. About 25 minutes a run on the cloud box (the 480-frame wait at under a frame a second).
- `tools/qa/stream_webtest.py` (web, stage 2): the seam alone.
- `tools/qa/stream_shots.gd` (native, xvfb): pictures at named cameras with the wings in `--need` in.
- `doortest.py`, `seamtest.py`, `wsS_webtest.py`: an inside border is checked as the old crossing with `?stream=0`;
  doors to and from the outside run as before.
